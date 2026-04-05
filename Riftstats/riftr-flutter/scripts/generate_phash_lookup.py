#!/usr/bin/env python3
"""
Generate dual pHash lookup JSON for Riftr Scanner variant detection.

Two hashes per card:
  - fullHash: 64-bit DCT pHash of the full card image (artwork detection)
  - gemHash:  64-bit DCT pHash of the gem/rarity crop (promo detection)

Reads cards.json, downloads/loads all card images, computes both hashes,
and writes phash_lookup.json as an app asset.

Usage:
    python3 scripts/generate_phash_lookup.py

Output:
    assets/phash_lookup.json — { "card_id": {"f":"hex16","g":"hex16"}, ... }
"""

import json
import math
import os
import time
from io import BytesIO

import numpy as np
import requests
from PIL import Image

# ── Config ──
CARDS_JSON = "assets/cards.json"
OUTPUT_JSON = "assets/phash_lookup.json"
HASH_SIZE = 8          # 8×8 = 64-bit hash
IMG_SIZE = 32          # resize to 32×32 before DCT
CACHE_DIR = ".phash_cache"

# Gem crop: must match _gemCrop* in phash_service.dart.
GEM_CROP = (0.44, 0.91, 0.12, 0.06)  # (x%, y%, w%, h%) — small crop, max discriminative power

# ── DCT-based Perceptual Hash ──

def _dct_matrix(n: int) -> np.ndarray:
    """Precompute the NxN DCT-II matrix."""
    mat = np.zeros((n, n), dtype=np.float64)
    for k in range(n):
        for i in range(n):
            mat[k, i] = math.cos(math.pi * k * (2 * i + 1) / (2 * n))
    mat[0, :] *= 1.0 / math.sqrt(n)
    mat[1:, :] *= math.sqrt(2.0 / n)
    return mat


_DCT = _dct_matrix(IMG_SIZE)
_DCT_T = _DCT.T


def compute_phash(img: Image.Image) -> int:
    """Compute 64-bit DCT perceptual hash from a PIL Image."""
    img = img.resize((IMG_SIZE, IMG_SIZE), Image.Resampling.LANCZOS).convert("L")
    pixels = np.array(img, dtype=np.float64)

    dct = _DCT @ pixels @ _DCT_T

    low_freq = dct[:HASH_SIZE, :HASH_SIZE]
    flat = low_freq.flatten()
    median = np.median(flat[1:])

    bits = (flat > median).astype(np.uint8)
    hash_val = 0
    for bit in bits:
        hash_val = (hash_val << 1) | int(bit)
    return hash_val


def compute_gem_hash(img: Image.Image) -> int:
    """Compute 64-bit DCT pHash of the gem/rarity crop area."""
    w, h = img.size
    x_pct, y_pct, w_pct, h_pct = GEM_CROP
    x0 = int(w * x_pct)
    y0 = int(h * y_pct)
    x1 = int(w * (x_pct + w_pct))
    y1 = int(h * (y_pct + h_pct))

    # Ensure valid crop
    x1 = min(x1, w)
    y1 = min(y1, h)
    if x1 - x0 < 4 or y1 - y0 < 4:
        return 0  # image too small for gem crop

    crop = img.crop((x0, y0, x1, y1))
    return compute_phash(crop)


def hamming_distance(h1: int, h2: int) -> int:
    """Hamming distance between two 64-bit hashes."""
    return bin(h1 ^ h2).count("1")


# ── Image loading ──

def load_image(url: str, base_dir: str) -> Image.Image | None:
    """Load image from local asset or remote URL."""
    if url.startswith("asset:"):
        local_path = os.path.join(base_dir, url.replace("asset:", "assets/"))
        if os.path.exists(local_path):
            return Image.open(local_path)
        print(f"  MISSING local: {local_path}")
        return None

    cache_path = os.path.join(base_dir, CACHE_DIR, url.split("/")[-1])
    if os.path.exists(cache_path):
        return Image.open(cache_path)

    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        with open(cache_path, "wb") as f:
            f.write(resp.content)
        return Image.open(BytesIO(resp.content))
    except Exception as e:
        print(f"  DOWNLOAD FAILED: {url} → {e}")
        return None


# ── Main ──

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)

    print(f"Loading {CARDS_JSON}...")
    with open(CARDS_JSON) as f:
        cards = json.load(f)

    print(f"Processing {len(cards)} cards (dual hash: full + gem)...")
    lookup = {}
    errors = []
    t0 = time.time()

    for i, card in enumerate(cards):
        card_id = card.get("id", "")
        name = card.get("name", "?")
        url = card.get("media", {}).get("image_url", "")
        set_id = card.get("set", {}).get("set_id", "?")
        cn = card.get("collector_number", "?")

        if not card_id or not url:
            continue

        img = load_image(url, base_dir)
        if img is None:
            errors.append(f"{name} ({set_id} #{cn})")
            continue

        full_hash = compute_phash(img)
        gem_hash = compute_gem_hash(img)
        lookup[card_id] = {
            "f": f"{full_hash:016x}",
            "g": f"{gem_hash:016x}",
        }

        if (i + 1) % 100 == 0:
            elapsed = time.time() - t0
            print(f"  {i+1}/{len(cards)} ({elapsed:.1f}s)")

    elapsed = time.time() - t0
    print(f"\nDone: {len(lookup)} dual hashes in {elapsed:.1f}s")

    if errors:
        print(f"\n{len(errors)} ERRORS:")
        for e in errors[:10]:
            print(f"  {e}")

    # Verify
    print("\n── Variant Verification (full + gem) ──")
    _verify_variants(cards, lookup)

    # Write output
    with open(OUTPUT_JSON, "w") as f:
        json.dump(lookup, f, separators=(",", ":"))

    size_kb = os.path.getsize(OUTPUT_JSON) / 1024
    print(f"\nWritten: {OUTPUT_JSON} ({size_kb:.1f} KB, {len(lookup)} entries)")


def _verify_variants(cards, lookup):
    """Check Hamming distances between known variant pairs."""
    by_name = {}
    for c in cards:
        name = c.get("name", "")
        if not name:
            continue
        by_name.setdefault(name, []).append(c)

    checks = 0
    for name, variants in sorted(by_name.items()):
        if len(variants) < 2:
            continue

        ids = [v["id"] for v in variants if v["id"] in lookup]
        if len(ids) < 2:
            continue

        for j in range(len(ids)):
            for k in range(j + 1, len(ids)):
                e1, e2 = lookup[ids[j]], lookup[ids[k]]
                full_dist = hamming_distance(int(e1["f"], 16), int(e2["f"], 16))
                gem_dist = hamming_distance(int(e1["g"], 16), int(e2["g"], 16))

                v1 = next(v for v in variants if v["id"] == ids[j])
                v2 = next(v for v in variants if v["id"] == ids[k])
                s1 = v1.get("set", {}).get("set_id", "?")
                s2 = v2.get("set", {}).get("set_id", "?")
                cn1 = v1.get("collector_number", "?")
                cn2 = v2.get("collector_number", "?")
                m1 = v1.get("metadata", {})
                m2 = v2.get("metadata", {})

                def _label(m, s):
                    if m.get("signature"):
                        return "sig"
                    if m.get("alternate_art"):
                        return "alt"
                    if m.get("overnumbered"):
                        return "over"
                    if m.get("metal"):
                        return "metal"
                    if s in ("OGNX", "SFDX", "OGSX"):
                        return "promo"
                    return "base"

                l1 = _label(m1, s1)
                l2 = _label(m2, s2)

                if l1 != l2 and (full_dist > 0 or gem_dist > 0):
                    same_art = "same-art" if full_dist <= 10 else "diff-art"
                    promo_tag = f"gem={gem_dist}" if full_dist <= 10 else ""
                    tag = "✅" if full_dist > 10 or gem_dist > 12 else "⚠️" if full_dist > 5 or gem_dist > 6 else "❌"
                    print(f"  {tag} {name}: {s1}#{cn1}({l1}) vs {s2}#{cn2}({l2}) → full={full_dist} {same_art} {promo_tag}")
                    checks += 1
                    if checks >= 25:
                        print(f"  ... (showing 25/{checks}+)")
                        return


if __name__ == "__main__":
    main()
