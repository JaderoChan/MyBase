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

# Create output directory
if ! mkdir -p "$OUT_DIR"; then
  echo "[ERROR] Failed to create output directory: \"$OUT_DIR\""
  exit 1
fi

echo "[INFO] Output name prefix: \"$OUT_NAME\""
echo "[INFO] Generating PNG sizes: 16,32,64,128,256,512,1024"
for S in 16 32 64 128 256 512 1024; do
  if ! magick "$SRC" -resize "${S}x${S}" -filter Lanczos -strip "$OUT_DIR/${OUT_NAME}_${S}.png"; then
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
if ! magick "$SRC" -define icon:auto-resize=16,32,64,128,256,512,1024 "$OUT_DIR/${OUT_NAME}.icns"; then
  echo "[ERROR] Failed to generate ${OUT_NAME}.icns"
  exit 1
fi

echo "[OK] Done"
echo "[OK] Output directory: \"$OUT_DIR\""
exit 0
