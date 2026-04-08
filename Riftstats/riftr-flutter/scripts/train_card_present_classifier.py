#!/usr/bin/env python3
"""
Train a binary CNN to classify whether a camera frame contains a card.

Input:  96×128 grayscale frame (low-res camera capture)
Output: probability of card present (0.0 = no card, 1.0 = card)

Training data:
  - Positive: *_pos_*.png files (frames where a card was successfully scanned)
  - Negative: *_neg*.png files (frames with no card / random objects)

The model will be used as a Native Rect validator:
  1. Native rects give candidate card regions
  2. Each candidate is cropped and resized to 96×128
  3. Card-Present CNN scores each candidate
  4. Highest score = most likely the actual card

Usage:
    python3 scripts/train_card_present_classifier.py

Output:
    assets/card_present_classifier.tflite
"""

import os
import random

import numpy as np
from PIL import Image, ImageFilter

# Suppress TF info logs
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf

# ── Config ──
FRAMES_DIR = "trainingsframes"
OUTPUT_TFLITE = "assets/card_present_classifier.tflite"
INPUT_W = 96
INPUT_H = 128

# Training
EPOCHS = 30
BATCH_SIZE = 32
LEARNING_RATE = 1e-3
VAL_SPLIT = 0.20
EARLY_STOP_PATIENCE = 5

# Augmentation
AUGMENT_PER_IMAGE = 4  # augmented copies per original


# ── Image Loading ──

def load_frames(frames_dir):
    """Load positive and negative frames, filtering AirDrop duplicates."""
    pos_files = []
    neg_files = []

    for f in os.listdir(frames_dir):
        if not f.endswith('.png'):
            continue
        # Skip AirDrop duplicates (" 2.png", " 3.png", etc.)
        if any(f.endswith(f' {i}.png') for i in range(2, 10)):
            continue
        # Skip crop files (full-res card crops, not camera frames)
        if '_crop_' in f:
            continue

        path = os.path.join(frames_dir, f)
        if '_pos_' in f:
            pos_files.append(path)
        elif '_neg' in f:
            neg_files.append(path)

    return pos_files, neg_files


def load_image(path):
    """Load a frame as grayscale numpy array normalized to [0,1]."""
    img = Image.open(path).convert('L')
    # Ensure correct size
    if img.size != (INPUT_W, INPUT_H):
        img = img.resize((INPUT_W, INPUT_H), Image.Resampling.LANCZOS)
    return np.array(img, dtype=np.float32) / 255.0


# ── Augmentation ──

def augment(img_array):
    """Apply random augmentation to simulate varying camera conditions."""
    aug = img_array.copy()

    # 1. Brightness jitter (±40 out of 255 range, so ±0.16 in [0,1])
    aug += random.uniform(-0.16, 0.16)

    # 2. Contrast jitter (0.6-1.4)
    mean = aug.mean()
    factor = random.uniform(0.6, 1.4)
    aug = mean + (aug - mean) * factor

    # 3. Gaussian noise (σ 0-0.04 in [0,1] range)
    noise_sigma = random.uniform(0, 0.04)
    aug += np.random.normal(0, noise_sigma, aug.shape).astype(np.float32)

    # 4. Clamp
    aug = np.clip(aug, 0, 1)

    # 5. Blur (via PIL, σ 0-1.5)
    pil_img = Image.fromarray((aug * 255).astype(np.uint8))
    blur_radius = random.uniform(0, 1.5)
    if blur_radius > 0.3:
        pil_img = pil_img.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # 6. Random horizontal flip (camera can be either orientation)
    if random.random() < 0.5:
        pil_img = pil_img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    # 7. Small random crop + resize (simulate slight position variation)
    if random.random() < 0.4:
        w, h = pil_img.size
        crop_pct = random.uniform(0.85, 0.95)
        cw, ch = int(w * crop_pct), int(h * crop_pct)
        cx = random.randint(0, w - cw)
        cy = random.randint(0, h - ch)
        pil_img = pil_img.crop((cx, cy, cx + cw, cy + ch))
        pil_img = pil_img.resize((INPUT_W, INPUT_H), Image.Resampling.BILINEAR)

    return np.array(pil_img, dtype=np.float32) / 255.0


# ── Dataset ──

def build_dataset(frames_dir):
    """Build training dataset from collected frames."""
    pos_files, neg_files = load_frames(frames_dir)
    print(f"Found {len(pos_files)} positive, {len(neg_files)} negative frames")

    if len(pos_files) == 0 or len(neg_files) == 0:
        raise ValueError("Need both positive and negative frames!")

    samples = []  # (pixels, label)

    # Balance classes: oversample the smaller class
    max_class = max(len(pos_files), len(neg_files))
    pos_oversample = max(1, max_class // len(pos_files))
    neg_oversample = max(1, max_class // len(neg_files))

    print(f"Oversampling: pos={pos_oversample}×, neg={neg_oversample}×")

    # Positive frames (label=1)
    for path in pos_files:
        try:
            img = load_image(path)
        except Exception:
            continue
        for _ in range(pos_oversample):
            samples.append((img, 1))
            for _ in range(AUGMENT_PER_IMAGE):
                samples.append((augment(img), 1))

    # Negative frames (label=0)
    for path in neg_files:
        try:
            img = load_image(path)
        except Exception:
            continue
        for _ in range(neg_oversample):
            samples.append((img, 0))
            for _ in range(AUGMENT_PER_IMAGE):
                samples.append((augment(img), 0))

    random.shuffle(samples)

    X = np.array([s[0] for s in samples], dtype=np.float32)
    y = np.array([s[1] for s in samples], dtype=np.int32)

    # Reshape for CNN: (N, 128, 96, 1)
    X = X.reshape(-1, INPUT_H, INPUT_W, 1)

    pos_count = (y == 1).sum()
    neg_count = (y == 0).sum()
    print(f"\nDataset: {len(X)} total samples")
    print(f"  Positive (card): {pos_count}")
    print(f"  Negative (no card): {neg_count}")

    return X, y


# ── Model ──

def build_model():
    """Build tiny binary CNN for card-present detection."""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_H, INPUT_W, 1)),
        tf.keras.layers.Conv2D(16, 3, activation="relu", padding="same"),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(32, 3, activation="relu", padding="same"),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(32, 3, activation="relu", padding="same"),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(1, activation="sigmoid"),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss="binary_crossentropy",
        metrics=["accuracy"],
    )

    return model


# ── Export ──

def export_tflite(model, output_path):
    """Export model as float16 quantized TFLite."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    with open(output_path, "wb") as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"\nTFLite model saved: {output_path} ({size_kb:.1f} KB)")


# ── Evaluation ──

def evaluate(model, X_val, y_val):
    """Print accuracy and confusion matrix."""
    probs = model.predict(X_val, verbose=0).flatten()
    preds = (probs >= 0.5).astype(int)
    y_true = y_val.astype(int)

    correct = (preds == y_true).sum()
    total = len(y_true)
    accuracy = correct / total

    # Confusion matrix
    tp = ((preds == 1) & (y_true == 1)).sum()
    tn = ((preds == 0) & (y_true == 0)).sum()
    fp = ((preds == 1) & (y_true == 0)).sum()
    fn = ((preds == 0) & (y_true == 1)).sum()

    print(f"\n{'='*50}")
    print(f"Accuracy: {accuracy:.4f} ({correct}/{total})")
    print(f"{'='*50}")
    print(f"\nConfusion Matrix:")
    print(f"  TP (card→card):     {tp}")
    print(f"  TN (no card→no):    {tn}")
    print(f"  FP (no card→card):  {fp}")
    print(f"  FN (card→no card):  {fn}")

    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
    print(f"\nPrecision: {precision:.4f}")
    print(f"Recall:    {recall:.4f}")
    print(f"F1 Score:  {f1:.4f}")

    # Confidence distribution
    pos_probs = probs[y_true == 1]
    neg_probs = probs[y_true == 0]
    print(f"\nConfidence distribution:")
    print(f"  Positive: mean={pos_probs.mean():.3f} min={pos_probs.min():.3f} max={pos_probs.max():.3f}")
    print(f"  Negative: mean={neg_probs.mean():.3f} min={neg_probs.min():.3f} max={neg_probs.max():.3f}")


# ── Main ──

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)
    frames_dir = os.path.join(base_dir, FRAMES_DIR)
    print(f"Working directory: {base_dir}")
    print(f"Frames directory: {frames_dir}")

    # Build dataset
    X, y = build_dataset(frames_dir)

    # Split train/val (stratified)
    from sklearn.model_selection import train_test_split
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=VAL_SPLIT, stratify=y, random_state=42
    )
    print(f"\nTrain: {len(X_train)}")
    print(f"Val:   {len(X_val)}")

    # Build model
    model = build_model()
    model.summary()

    # Train
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=EARLY_STOP_PATIENCE, restore_best_weights=True
        ),
    ]

    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1,
    )

    # Evaluate
    evaluate(model, X_val, y_val)

    # Export
    export_tflite(model, OUTPUT_TFLITE)

    print("\nDone!")


if __name__ == "__main__":
    main()
