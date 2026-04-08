#!/usr/bin/env python3
"""
Train a tiny CNN to classify the mana cost from the top-left diamond region
of Riftbound trading cards.

Input:  48x48 grayscale crop of the mana diamond region
Output: mana class (0-12, no 11)

Training data comes from reference card images in assets/.
Augmentation simulates camera conditions (blur, noise, brightness, downscale).

Usage:
    python3 scripts/train_mana_classifier.py

Output:
    assets/mana_classifier.tflite
"""

import json
import os
import random

import numpy as np
from PIL import Image, ImageFilter

# Suppress TF info logs
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf

# ── Config ──
CARDS_JSON = "assets/cards.json"
OUTPUT_TFLITE = "assets/mana_classifier.tflite"
INPUT_SIZE = 48

# Mana crop coordinates (fraction of card dimensions)
# Top-left diamond region — must match ManaClassifierService exactly.
CROP_X = 0.02
CROP_Y = 0.00
CROP_W = 0.18
CROP_H = 0.12

# Classes: all mana values that exist in the card pool
CLASSES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12]
CLASS_TO_IDX = {c: i for i, c in enumerate(CLASSES)}

# Oversampling: classes with fewer than this many source images
# get an augmentation multiplier proportional to how rare they are.
OVERSAMPLE_THRESHOLD = 50  # images
MAX_OVERSAMPLE = 30        # cap

# Augmentation
JITTER_CROPS = 8       # additional jittered crops per image
JITTER_RANGE = 0.05    # ±5% position jitter (wider for camera noise)
AUGMENT_PER_CROP = 3   # augmented versions per crop

# Training
EPOCHS = 30
BATCH_SIZE = 32
LEARNING_RATE = 1e-3
VAL_SPLIT = 0.20
EARLY_STOP_PATIENCE = 5


# ── Image Loading ──

def load_image(url: str, base_dir: str):
    """Load image from local asset path."""
    if url.startswith("asset:"):
        local_path = os.path.join(base_dir, url.replace("asset:", "assets/"))
        if os.path.exists(local_path):
            return Image.open(local_path).convert("L")  # grayscale
    return None


# ── Mana Crop ──

def crop_mana(img, jitter_x=0.0, jitter_y=0.0):
    """Crop the mana diamond region from a card image with optional jitter."""
    w, h = img.size
    x0 = int((CROP_X + jitter_x) * w)
    y0 = int((CROP_Y + jitter_y) * h)
    x1 = int((CROP_X + CROP_W + jitter_x) * w)
    y1 = int((CROP_Y + CROP_H + jitter_y) * h)

    # Clamp to image bounds
    x0 = max(0, min(x0, w - 1))
    y0 = max(0, min(y0, h - 1))
    x1 = max(x0 + 1, min(x1, w))
    y1 = max(y0 + 1, min(y1, h))

    crop = img.crop((x0, y0, x1, y1))
    return crop.resize((INPUT_SIZE, INPUT_SIZE), Image.Resampling.LANCZOS)


# ── Augmentation ──

def augment(img_array):
    """Apply random augmentation to simulate camera conditions."""
    aug = img_array.copy().astype(np.float64)

    # 1. Brightness jitter (±30 out of 255)
    aug += random.uniform(-30, 30)

    # 2. Contrast jitter (0.7-1.3)
    mean = aug.mean()
    factor = random.uniform(0.7, 1.3)
    aug = mean + (aug - mean) * factor

    # 3. Gaussian noise (σ 0-10)
    noise_sigma = random.uniform(0, 10)
    aug += np.random.normal(0, noise_sigma, aug.shape)

    # 4. Clamp
    aug = np.clip(aug, 0, 255).astype(np.uint8)

    # 5. Blur (σ 0-1.5) via PIL
    pil_img = Image.fromarray(aug)
    blur_radius = random.uniform(0, 1.5)
    if blur_radius > 0.3:
        pil_img = pil_img.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # 6. Downscale-upscale (simulate camera resolution)
    if random.random() < 0.5:
        scale = random.uniform(0.5, 0.75)
        small_w = max(8, int(INPUT_SIZE * scale))
        small_h = max(8, int(INPUT_SIZE * scale))
        pil_img = pil_img.resize((small_w, small_h), Image.Resampling.BILINEAR)
        pil_img = pil_img.resize((INPUT_SIZE, INPUT_SIZE), Image.Resampling.BILINEAR)

    return np.array(pil_img)


# ── Dataset ──

def build_dataset(base_dir):
    """Build training dataset from reference images."""
    with open(os.path.join(base_dir, CARDS_JSON)) as f:
        cards = json.load(f)

    # Count source images per class for oversampling calculation
    class_counts = {c: 0 for c in CLASSES}

    # Collect cards with mana and local images
    valid_cards = []
    for c in cards:
        energy = c.get("attributes", {}).get("energy")
        if energy is None or energy not in CLASS_TO_IDX:
            continue

        url = c.get("media", {}).get("image_url", "")
        if not url.startswith("asset:"):
            continue

        path = os.path.join(base_dir, url.replace("asset:", "assets/"))
        if not os.path.exists(path):
            continue

        try:
            with Image.open(path) as test:
                w, h = test.size
                if w == h:  # square = metal card (different layout)
                    continue
                if w < 200 or h < 200:
                    continue
        except Exception:
            continue

        valid_cards.append({"path": path, "mana": energy, "name": c.get("name", "")})
        class_counts[energy] += 1

    print(f"Found {len(valid_cards)} cards with mana + local image")
    for mana in CLASSES:
        print(f"  Mana {mana:2d}: {class_counts[mana]:3d} source images")

    # Calculate oversampling multipliers
    max_count = max(class_counts.values())
    oversample = {}
    for mana in CLASSES:
        count = class_counts[mana]
        if count <= 0:
            oversample[mana] = 1
        elif count < OVERSAMPLE_THRESHOLD:
            # Scale inversely: fewer images → more oversampling
            oversample[mana] = min(MAX_OVERSAMPLE, max(1, max_count // count))
        else:
            oversample[mana] = 1

    print("\nOversampling multipliers:")
    for mana in CLASSES:
        if oversample[mana] > 1:
            print(f"  Mana {mana:2d}: {oversample[mana]}×")

    # Build samples
    samples = []  # list of (pixels_48x48, label_idx)

    for card in valid_cards:
        try:
            img = Image.open(card["path"]).convert("L")
        except Exception:
            continue

        mana = card["mana"]
        label = CLASS_TO_IDX[mana]
        extra = oversample[mana]

        # Center crop
        center = crop_mana(img)
        center_arr = np.array(center)
        samples.append((center_arr, label))

        # Augmented center crops
        for _ in range(AUGMENT_PER_CROP * extra):
            samples.append((augment(center_arr), label))

        # Jittered crops + augmentations
        for _ in range(JITTER_CROPS * extra):
            jx = random.uniform(-JITTER_RANGE, JITTER_RANGE)
            jy = random.uniform(-JITTER_RANGE, JITTER_RANGE)
            jittered = crop_mana(img, jx, jy)
            jittered_arr = np.array(jittered)
            samples.append((jittered_arr, label))

            for _ in range(AUGMENT_PER_CROP):
                samples.append((augment(jittered_arr), label))

    random.shuffle(samples)

    X = np.array([s[0] for s in samples], dtype=np.float32) / 255.0  # normalize [0,1]
    y = np.array([s[1] for s in samples], dtype=np.int32)

    # Reshape for CNN: (N, 48, 48, 1)
    X = X.reshape(-1, INPUT_SIZE, INPUT_SIZE, 1)

    # Print class distribution
    print(f"\nDataset: {len(X)} total samples")
    for i, mana in enumerate(CLASSES):
        count = int((y == i).sum())
        print(f"  Mana {mana:2d}: {count:5d} samples (class {i})")

    return X, y


# ── Model ──

def build_model():
    """Build tiny CNN for mana classification."""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_SIZE, INPUT_SIZE, 1)),
        tf.keras.layers.Conv2D(16, 3, activation="relu", padding="same"),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(32, 3, activation="relu", padding="same"),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(32, 3, activation="relu", padding="same"),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(len(CLASSES), activation="softmax"),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss="sparse_categorical_crossentropy",
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
    """Print per-class accuracy and confusion details."""
    probs = model.predict(X_val, verbose=0)
    preds = np.argmax(probs, axis=1)
    y_true = y_val.astype(int)

    correct = (preds == y_true).sum()
    total = len(y_true)
    accuracy = correct / total if total > 0 else 0

    print(f"\n{'='*60}")
    print(f"Overall Accuracy: {accuracy:.4f} ({correct}/{total})")
    print(f"{'='*60}")

    print(f"\nPer-class accuracy:")
    for i, mana in enumerate(CLASSES):
        mask = y_true == i
        if mask.sum() == 0:
            print(f"  Mana {mana:2d}: no samples")
            continue
        cls_correct = (preds[mask] == i).sum()
        cls_total = mask.sum()
        cls_acc = cls_correct / cls_total
        print(f"  Mana {mana:2d}: {cls_acc:.3f} ({cls_correct}/{cls_total})")

    # Show misclassifications
    wrong = preds != y_true
    if wrong.sum() > 0:
        print(f"\nMisclassifications ({wrong.sum()}):")
        for i in range(len(y_true)):
            if preds[i] != y_true[i]:
                true_mana = CLASSES[y_true[i]]
                pred_mana = CLASSES[preds[i]]
                conf = probs[i][preds[i]]
                print(f"  True={true_mana}, Pred={pred_mana} (conf={conf:.3f})")


# ── Main ──

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)
    print(f"Working directory: {base_dir}")

    # Build dataset
    X, y = build_dataset(base_dir)

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
