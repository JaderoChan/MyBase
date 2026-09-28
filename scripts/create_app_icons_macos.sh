#!/usr/bin/env bash

# PAIGC

set -eu

usage() {
  echo "Usage:"
  echo "  $(basename "$0") <input.png> <output_folder> [output_name]"
  echo "Example:"
  echo "  $(basename "$0") \"/path/to/logo_1024.png\" \"/path/to/out\" \"myicon\""
  exit 2
}

# Usage check
[ "${1-}" = "" ] && usage
[ "${2-}" = "" ] && usage

SRC="$1"
OUT_DIR="$2"
OUT_NAME="${3-}"
[ -z "$OUT_NAME" ] && OUT_NAME="app"

# Check source file
if [ ! -f "$SRC" ]; then
  echo "[ERROR] Input image does not exist: \"$SRC\""
  exit 1
fi

# Check magick
if ! command -v magick >/dev/null 2>&1; then
  echo "[ERROR] ImageMagick command \"magick\" not found. Please install it and add to PATH."
  exit 1
fi

# Check iconutil
if ! command -v iconutil >/dev/null 2>&1; then
  echo "[ERROR] \"iconutil\" not found. This script requires macOS."
  exit 1
fi

# Create output directory
if ! mkdir -p "$OUT_DIR"; then
  echo "[ERROR] Failed to create output directory: \"$OUT_DIR\""
  exit 1
fi

echo "[INFO] Output name prefix: \"$OUT_NAME\""
echo "[INFO] Generating PNG sizes: 16,32,64,128,256,512,1024"
for S in 16 32 64 128 256 512 1024; do
  if ! magick "$SRC" -resize "${S}x${S}" -filter Lanczos -alpha on -depth 8 -define png:color-type=6 -strip "$OUT_DIR/${OUT_NAME}_${S}.png"; then
    echo "[ERROR] Failed to generate ${OUT_NAME}_${S}.png"
    exit 1
  fi
done

echo "[INFO] Generating ICO (16,24,32,48,64,128,256)"
if ! magick "$SRC" -define icon:auto-resize=16,24,32,48,64,128,256 "$OUT_DIR/${OUT_NAME}.ico"; then
  echo "[ERROR] Failed to generate ${OUT_NAME}.ico"
  exit 1
fi

echo "[INFO] Generating ICNS (16,32,64,128,256,512,1024)"
# Build a proper .iconset and hand it to Apple's own iconutil converter,
# since only iconutil produces an icns that fully conforms to Apple's spec.
ICONSET_DIR="$OUT_DIR/${OUT_NAME}.iconset"
if ! mkdir -p "$ICONSET_DIR"; then
  echo "[ERROR] Failed to create iconset directory: \"$ICONSET_DIR\""
  exit 1
fi
cp "$OUT_DIR/${OUT_NAME}_16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$OUT_DIR/${OUT_NAME}_32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$OUT_DIR/${OUT_NAME}_32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$OUT_DIR/${OUT_NAME}_64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$OUT_DIR/${OUT_NAME}_128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$OUT_DIR/${OUT_NAME}_256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$OUT_DIR/${OUT_NAME}_256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$OUT_DIR/${OUT_NAME}_512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$OUT_DIR/${OUT_NAME}_512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$OUT_DIR/${OUT_NAME}_1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
if ! iconutil --convert icns --output "$OUT_DIR/${OUT_NAME}.icns" "$ICONSET_DIR"; then
  echo "[ERROR] Failed to generate ${OUT_NAME}.icns"
  rm -rf "$ICONSET_DIR"
  exit 1
fi
rm -rf "$ICONSET_DIR"

echo "[OK] Done"
echo "[OK] Output directory: \"$OUT_DIR\""
exit 0
