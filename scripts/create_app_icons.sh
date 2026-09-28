#!/usr/bin/env bash

# PAIGC

set -eu

usage() {
  echo "Usage:"
  echo "  $(basename "$0") <input.png> <output_folder> [output_name] [margin_percent]"
  echo "Example:"
  echo "  $(basename "$0") \"/path/to/logo_1024.png\" \"/path/to/out\" \"myicon\" 9"
  exit 2
}

# Usage check
[ "${1-}" = "" ] && usage
[ "${2-}" = "" ] && usage

SRC="$1"
OUT_DIR="$2"
OUT_NAME="${3-}"
[ -z "$OUT_NAME" ] && OUT_NAME="app"
MARGIN="${4-}"
[ -z "$MARGIN" ] && MARGIN=0

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

# Validate margin
case "$MARGIN" in
  *[!0-9]*|'') echo "[ERROR] Margin must be a non-negative integer percentage: \"$MARGIN\""; exit 1 ;;
esac
if [ "$MARGIN" -ge 50 ]; then
  echo "[ERROR] Margin percentage must be within [0, 50): \"$MARGIN\""
  exit 1
fi

# Create output directory
if ! mkdir -p "$OUT_DIR"; then
  echo "[ERROR] Failed to create output directory: \"$OUT_DIR\""
  exit 1
fi

# Apply safe-zone margin (macOS auto-masks edge-to-edge icons; padding avoids that)
WORK_SRC="$SRC"
TMP_PADDED=""
if [ "$MARGIN" -gt 0 ]; then
  CANVAS=$(magick identify -format "%w" "$SRC")
  CONTENT=$(( CANVAS * (100 - 2 * MARGIN) / 100 ))
  TMP_PADDED="$OUT_DIR/.${OUT_NAME}_padded_src.png"
  echo "[INFO] Applying ${MARGIN}% safe-zone margin (content ${CONTENT}px of ${CANVAS}px canvas)"
  if ! magick "$SRC" -resize "${CONTENT}x${CONTENT}" -background none -gravity center -extent "${CANVAS}x${CANVAS}" "$TMP_PADDED"; then
    echo "[ERROR] Failed to apply margin padding"
    exit 1
  fi
  WORK_SRC="$TMP_PADDED"
fi

echo "[INFO] Output name prefix: \"$OUT_NAME\""
echo "[INFO] Generating PNG sizes: 16,32,64,128,256,512,1024"
for S in 16 32 64 128 256 512 1024; do
  if ! magick "$WORK_SRC" -resize "${S}x${S}" -filter Lanczos -strip "$OUT_DIR/${OUT_NAME}_${S}.png"; then
    echo "[ERROR] Failed to generate ${OUT_NAME}_${S}.png"
    exit 1
  fi
done

echo "[INFO] Generating ICO (16,24,32,48,64,128,256)"
if ! magick "$WORK_SRC" -define icon:auto-resize=16,24,32,48,64,128,256 "$OUT_DIR/${OUT_NAME}.ico"; then
  echo "[ERROR] Failed to generate ${OUT_NAME}.ico"
  exit 1
fi

echo "[INFO] Generating ICNS (16,32,64,128,256,512,1024)"
if ! magick "$WORK_SRC" -define icon:auto-resize=16,32,64,128,256,512,1024 "$OUT_DIR/${OUT_NAME}.icns"; then
  echo "[ERROR] Failed to generate ${OUT_NAME}.icns"
  exit 1
fi

[ -n "$TMP_PADDED" ] && rm -f "$TMP_PADDED"

echo "[OK] Done"
echo "[OK] Output directory: \"$OUT_DIR\""
exit 0
