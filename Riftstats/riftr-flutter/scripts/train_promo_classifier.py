#!/usr/bin/env python3
"""
Train a tiny CNN to classify promo badge presence on trading cards.

Input:  48x48 grayscale crop of the badge region
Output: promo probability (0.0 = base, 1.0 = promo)

Training data comes from reference card images in assets/ognx_images/.
Augmentation simulates camera conditions (blur, noise, brightness, downscale).

Usage:
    python3 scripts/train_promo_classifier.py

Output:
    assets/promo_badge_classifier.tflite
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
OUTPUT_TFLITE = "assets/promo_badge_classifier.tflite"
INPUT_SIZE = 48

# Badge crop coordinates (fraction of card dimensions)
# Wider than gem crop to capture full badge context
BADGE_X = 0.38
BADGE_Y = 0.88
BADGE_W = 0.24
BADGE_H = 0.10

# Augmentation
JITTER_CROPS = 8       # additional jittered crops per image
JITTER_RANGE = 0.05    # ±5% position jitter
AUGMENT_PER_CROP = 3   # augmented versions per crop

# Training
EPOCHS = 30
BATCH_SIZE = 32
LEARNING_RATE = 1e-3
VAL_SPLIT = 0.20
EARLY_STOP_PATIENCE = 5
PROMO_THRESHOLD = 0.70


# ── Image Loading ──

def load_image(url: str, base_dir: str):
    """Load image from local asset path."""
    if url.startswith("asset:"):
        local_path = os.path.join(base_dir, url.replace("asset:", "assets/"))
        if os.path.exists(local_path):
            return Image.open(local_path).convert("L")  # grayscale
    return None


# ── Badge Crop ──

def crop_badge(img, jitter_x=0.0, jitter_y=0.0):
    """Crop the badge region from a card image with optional position jitter."""
    w, h = img.size
    x0 = int((BADGE_X + jitter_x) * w)
    y0 = int((BADGE_Y + jitter_y) * h)
    x1 = int((BADGE_X + BADGE_W + jitter_x) * w)
    y1 = int((BADGE_Y + BADGE_H + jitter_y) * h)

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

    # Separate promo and base cards with local images
    promo_cards = []
    base_cards = []

    for c in cards:
        sid = c.get("set", {}).get("set_id", "")
        url = c.get("media", {}).get("image_url", "")
        if not url.startswith("asset:"):
            continue

        # Skip 300x300 metal cards (different layout)
        path = os.path.join(base_dir, url.replace("asset:", "assets/"))
        if not os.path.exists(path):
            continue
        try:
            with Image.open(path) as test:
                w, h = test.size
                if w == h:  # square = metal card
                    continue
                if w < 200 or h < 200:  # too small
                    continue
        except Exception:
            continue

        is_promo = sid in ("SFDX", "OGNX", "OGSX")
        cn = str(c.get("collector_number", ""))

        # Golden frame promos (Top-8/Championship) — need extra oversampling
        # because there are only ~8 of them vs ~134 text badge promos
        golden_frame_keys = {
            ("OGNX", "34"), ("OGNX", "67"), ("OGNX", "193"),
            ("SFDX", "178"), ("SFDX", "22"), ("SFDX", "86"), ("SFDX", "139"),
        }
        is_golden = (sid, cn) in golden_frame_keys

        entry = {"path": path, "name": c.get("name", ""), "set": sid, "golden": is_golden}

        if is_promo:
            promo_cards.append(entry)
        elif sid in ("SFD", "OGN", "OGS"):
            base_cards.append(entry)

    print(f"Found {len(promo_cards)} promo, {len(base_cards)} base cards")

    samples = []  # list of (pixels_48x48, label)

    for cards_list, label in [(promo_cards, 1), (base_cards, 0)]:
        for card in cards_list:
            try:
                img = Image.open(card["path"]).convert("L")
            except Exception:
                continue

            # Golden frame promos get 15x oversampling (8 cards vs 134 text badge)
            extra = 15 if card.get("golden", False) else 1

            # Center crop
            center = crop_badge(img)
            center_arr = np.array(center)
            samples.append((center_arr, label))

            # Augmented center crops
            for _ in range(AUGMENT_PER_CROP * extra):
                samples.append((augment(center_arr), label))

            # Jittered crops + augmentations
            for _ in range(JITTER_CROPS * extra):
                jx = random.uniform(-JITTER_RANGE, JITTER_RANGE)
                jy = random.uniform(-JITTER_RANGE, JITTER_RANGE)
                jittered = crop_badge(img, jx, jy)
                jittered_arr = np.array(jittered)
                samples.append((jittered_arr, label))

                for _ in range(AUGMENT_PER_CROP):
                    samples.append((augment(jittered_arr), label))

    random.shuffle(samples)

    X = np.array([s[0] for s in samples], dtype=np.float32) / 255.0  # normalize [0,1]
    y = np.array([s[1] for s in samples], dtype=np.float32)

    # Reshape for CNN: (N, 48, 48, 1)
    X = X.reshape(-1, INPUT_SIZE, INPUT_SIZE, 1)

    print(f"Dataset: {len(X)} samples ({int(y.sum())} promo, {int(len(y) - y.sum())} base)")
    return X, y


# ── Model ──

def build_model():
    """Build tiny CNN for binary classification."""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_SIZE, INPUT_SIZE, 1)),
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
    print(f"TFLite model saved: {output_path} ({size_kb:.1f} KB)")


# ── Evaluation ──

def evaluate(model, X_val, y_val):
    """Print confusion matrix and metrics."""
    probs = model.predict(X_val, verbose=0).flatten()
    preds = (probs >= PROMO_THRESHOLD).astype(int)
    y_true = y_val.astype(int)

    tp = int(((preds == 1) & (y_true == 1)).sum())
    fp = int(((preds == 1) & (y_true == 0)).sum())
    tn = int(((preds == 0) & (y_true == 0)).sum())
    fn = int(((preds == 0) & (y_true == 1)).sum())

    accuracy = (tp + tn) / len(y_true) if len(y_true) > 0 else 0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0

    print(f"\n{'='*50}")
    print(f"Confusion Matrix (threshold={PROMO_THRESHOLD}):")
    print(f"  TP={tp:4d}  FP={fp:4d}")
    print(f"  FN={fn:4d}  TN={tn:4d}")
    print(f"  Accuracy:  {accuracy:.4f}")
    print(f"  Precision: {precision:.4f}")
    print(f"  Recall:    {recall:.4f}")
    print(f"  FPR:       {fpr:.4f} (target: <0.03)")
    print(f"{'='*50}")

    # Show probability distribution
    promo_probs = probs[y_true == 1]
    base_probs = probs[y_true == 0]
    print(f"\nPromo probs: mean={promo_probs.mean():.3f}, min={promo_probs.min():.3f}, max={promo_probs.max():.3f}")
    print(f"Base probs:  mean={base_probs.mean():.3f}, min={base_probs.min():.3f}, max={base_probs.max():.3f}")


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
    print(f"Train: {len(X_train)} ({int(y_train.sum())} promo)")
    print(f"Val:   {len(X_val)} ({int(y_val.sum())} promo)")

    # Build model
    model = build_model()
    model.summary()

    # Class weights: penalize false positives
    n_base = int((y_train == 0).sum())
    n_promo = int((y_train == 1).sum())
    weight_base = 1.0
    weight_promo = 0.75  # down-weight promo to reduce false positives
    class_weight = {0: weight_base, 1: weight_promo}
    print(f"Class weights: base={weight_base}, promo={weight_promo}")

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
        class_weight=class_weight,
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
