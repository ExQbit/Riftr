#!/usr/bin/env python3
"""
Train a tiny CNN to classify the set code printed on trading cards.

Input:  64x32 grayscale crop of the set code region (bottom-left of card)
Output: set code class (OGN, SFD, OGS)

The printed set code is always the base set — even promo cards (OGNX, SFDX,
OGSX) print the base set code (OGN, SFD, OGS).

Usage:
    python3 scripts/train_set_classifier.py

Output:
    assets/set_code_classifier.tflite
"""

import json
import os
import random
from io import BytesIO

import numpy as np
import requests
from PIL import Image, ImageFilter

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf

# ── Config ──
CARDS_JSON = "assets/cards.json"
OUTPUT_TFLITE = "assets/set_code_classifier.tflite"
INPUT_W = 64  # wider than tall (set code is horizontal text)
INPUT_H = 32

# Set code crop coordinates (fraction of card dimensions)
# Bottom-left: captures "SFD", "OGN", "OGS" text
CROP_X = 0.02
CROP_Y = 0.94
CROP_W = 0.18
CROP_H = 0.06

# Classes — the printed base set codes
CLASSES = ["OGN", "SFD", "OGS", "UNL"]
# Map internal set IDs to printed set code
SET_TO_PRINTED = {
    "OGN": "OGN", "OGNX": "OGN",
    "SFD": "SFD", "SFDX": "SFD",
    "OGS": "OGS", "OGSX": "OGS",
    "UNL": "UNL",
}
CACHE_DIR = ".phash_cache"

JITTER_CROPS = 8
JITTER_RANGE = 0.03
AUGMENT_PER_CROP = 3
# Extra augmentation multiplier for small classes (<50 source images)
SMALL_CLASS_EXTRA = 10
EPOCHS = 30
BATCH_SIZE = 32
LEARNING_RATE = 1e-3
VAL_SPLIT = 0.20
EARLY_STOP_PATIENCE = 5


def crop_set_code(img, jitter_x=0.0, jitter_y=0.0):
    w, h = img.size
    x0 = int((CROP_X + jitter_x) * w)
    y0 = int((CROP_Y + jitter_y) * h)
    x1 = int((CROP_X + CROP_W + jitter_x) * w)
    y1 = int((CROP_Y + CROP_H + jitter_y) * h)
    x0 = max(0, min(x0, w - 1))
    y0 = max(0, min(y0, h - 1))
    x1 = max(x0 + 1, min(x1, w))
    y1 = max(y0 + 1, min(y1, h))
    crop = img.crop((x0, y0, x1, y1))
    return crop.resize((INPUT_W, INPUT_H), Image.Resampling.LANCZOS)


def augment(img_array):
    aug = img_array.copy().astype(np.float64)
    aug += random.uniform(-30, 30)
    mean = aug.mean()
    factor = random.uniform(0.7, 1.3)
    aug = mean + (aug - mean) * factor
    noise_sigma = random.uniform(0, 10)
    aug += np.random.normal(0, noise_sigma, aug.shape)
    aug = np.clip(aug, 0, 255).astype(np.uint8)
    pil_img = Image.fromarray(aug)
    blur_radius = random.uniform(0, 1.5)
    if blur_radius > 0.3:
        pil_img = pil_img.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    if random.random() < 0.5:
        scale = random.uniform(0.5, 0.75)
        small_w = max(8, int(INPUT_W * scale))
        small_h = max(8, int(INPUT_H * scale))
        pil_img = pil_img.resize((small_w, small_h), Image.Resampling.BILINEAR)
        pil_img = pil_img.resize((INPUT_W, INPUT_H), Image.Resampling.BILINEAR)
    return np.array(pil_img)


def build_dataset(base_dir):
    with open(os.path.join(base_dir, CARDS_JSON)) as f:
        cards = json.load(f)

    samples = []
    class_counts = {c: 0 for c in CLASSES}

    for c in cards:
        sid = c.get("set", {}).get("set_id", "")
        printed = SET_TO_PRINTED.get(sid)
        if printed is None:
            continue

        url = c.get("media", {}).get("image_url", "")
        if not url:
            continue

        # Load from local asset or download from URL
        path = None
        if url.startswith("asset:"):
            path = os.path.join(base_dir, url.replace("asset:", "assets/"))
            if not os.path.exists(path):
                continue
        else:
            # Download and cache remote images
            cache_dir = os.path.join(base_dir, CACHE_DIR)
            os.makedirs(cache_dir, exist_ok=True)
            cache_name = url.split("/")[-1].split("?")[0] or f"{sid}_{c.get('collector_number','')}.jpg"
            path = os.path.join(cache_dir, cache_name)
            if not os.path.exists(path):
                try:
                    resp = requests.get(url, timeout=15)
                    resp.raise_for_status()
                    with open(path, "wb") as f:
                        f.write(resp.content)
                except Exception:
                    continue

        # Skip square/tiny images
        try:
            with Image.open(path) as test:
                w, h = test.size
                if w == h or w < 200 or h < 200:
                    continue
        except Exception:
            continue

        label = CLASSES.index(printed)

        try:
            img = Image.open(path).convert("L")
        except Exception:
            continue

        class_counts[printed] += 1

        # Determine augmentation multiplier (more for small classes)
        extra = SMALL_CLASS_EXTRA if class_counts[printed] <= 50 else 1

        # Center crop + augmentations
        center = crop_set_code(img)
        center_arr = np.array(center)
        samples.append((center_arr, label))
        for _ in range(AUGMENT_PER_CROP * extra):
            samples.append((augment(center_arr), label))

        # Jittered crops
        for _ in range(JITTER_CROPS * extra):
            jx = random.uniform(-JITTER_RANGE, JITTER_RANGE)
            jy = random.uniform(-JITTER_RANGE, JITTER_RANGE)
            jittered = crop_set_code(img, jx, jy)
            jittered_arr = np.array(jittered)
            samples.append((jittered_arr, label))
            for _ in range(AUGMENT_PER_CROP):
                samples.append((augment(jittered_arr), label))

    random.shuffle(samples)

    X = np.array([s[0] for s in samples], dtype=np.float32) / 255.0
    y = np.array([s[1] for s in samples], dtype=np.int32)
    X = X.reshape(-1, INPUT_H, INPUT_W, 1)

    print(f"Source images per set: {class_counts}")
    print(f"Dataset: {len(X)} samples")
    for i, cls in enumerate(CLASSES):
        print(f"  {cls}: {(y == i).sum()}")
    return X, y


def build_model():
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_H, INPUT_W, 1)),
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


def export_tflite(model, output_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()
    with open(output_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite model saved: {output_path} ({len(tflite_model) / 1024:.1f} KB)")


def evaluate(model, X_val, y_val):
    probs = model.predict(X_val, verbose=0)
    preds = np.argmax(probs, axis=1)
    y_true = y_val

    accuracy = (preds == y_true).mean()
    print(f"\n{'='*50}")
    print(f"Validation Accuracy: {accuracy:.4f}")
    print(f"\nPer-class:")
    for i, cls in enumerate(CLASSES):
        mask = y_true == i
        if mask.sum() > 0:
            cls_acc = (preds[mask] == i).mean()
            print(f"  {cls}: {cls_acc:.4f} ({mask.sum()} samples)")
    print(f"\nConfusion Matrix:")
    for i, cls_true in enumerate(CLASSES):
        row = []
        for j, cls_pred in enumerate(CLASSES):
            count = ((y_true == i) & (preds == j)).sum()
            row.append(f"{count:5d}")
        print(f"  {cls_true}: {' '.join(row)}")
    print(f"         {'  '.join(f'{c:>3}' for c in CLASSES)}")
    print(f"{'='*50}")


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)
    print(f"Working directory: {base_dir}")

    X, y = build_dataset(base_dir)

    from sklearn.model_selection import train_test_split
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=VAL_SPLIT, stratify=y, random_state=42
    )
    print(f"Train: {len(X_train)}, Val: {len(X_val)}")

    model = build_model()
    model.summary()

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=EARLY_STOP_PATIENCE, restore_best_weights=True
        ),
    ]

    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1,
    )

    evaluate(model, X_val, y_val)
    export_tflite(model, OUTPUT_TFLITE)

    # Save class labels for reference
    labels_path = OUTPUT_TFLITE.replace('.tflite', '_labels.json')
    with open(labels_path, 'w') as f:
        json.dump(CLASSES, f)
    print(f"Labels saved: {labels_path}")
    print("\nDone!")


if __name__ == "__main__":
    main()
