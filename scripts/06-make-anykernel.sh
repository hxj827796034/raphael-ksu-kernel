#!/usr/bin/env bash
# 06 — Package AnyKernel3 zip
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

WORK="$OUT_DIR/anykernel3-work"
rm -rf "$WORK"
cp -a "$ANYKERNEL3_DIR" "$WORK"

# Fetch real ak3-core.sh if missing
if [ ! -s "$WORK/tools/ak3-core.sh" ]; then
  bold "==> Fetching ak3-core.sh from upstream AnyKernel3"
  curl -L --fail -o "$WORK/tools/ak3-core.sh" \
    https://raw.githubusercontent.com/osm0sis/AnyKernel3/master/tools/ak3-core.sh \
    || warn "Failed to fetch ak3-core.sh — pack will likely fail in TWRP"
  chmod 0755 "$WORK/tools/ak3-core.sh" 2>/dev/null || true
fi

# Place kernel image in the standard AnyKernel3 location
if [ -f "$OUT_DIR/Image.gz-dtb" ]; then
  IMG="$OUT_DIR/Image.gz-dtb"
elif [ -f "$OUT_DIR/Image.gz" ]; then
  IMG="$OUT_DIR/Image.gz"
elif [ -f "$OUT_DIR/Image" ]; then
  IMG="$OUT_DIR/Image"
else
  die "no kernel image in $OUT_DIR"
fi

# Compress to Image.gz if needed
case "$IMG" in
  *.gz) ;;
  *) gzip -9 -c "$IMG" > "$WORK/Image.gz" ;;
esac
[ -f "$WORK/Image.gz" ] || cp "$IMG" "$WORK/Image.gz"

# Update module.prop with timestamp
TS=$(date +%Y%m%d-%H%M)
sed -i "s|^version=.*|version=${KSU_VERSION}-${TS}|" "$WORK/module.prop" || true
sed -i "s|^date=.*|date=$(date +%Y-%m-%d)|" "$WORK/module.prop" || true

ZIP="$OUT_DIR/${ZIPNAME_BASE}-${TS}.zip"
bold "==> Zipping -> $ZIP"
which zip >/dev/null || { warn "zip not found, installing"; sudo apt-get install -y zip; }
( cd "$WORK" && zip -r9 "$ZIP" . -x "*.bak" "*.swp" ) >/dev/null
ls -la "$ZIP"
echo "Done. Flash with: adb push $ZIP /sdcard/ && TWRP install"
bold "==> 06 done"
