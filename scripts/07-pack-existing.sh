#!/usr/bin/env bash
# 07 — Package an EXISTING Image into AnyKernel3 zip
# Use this when you already have a kernel Image from somewhere else
# and just need to wrap it into a flashable zip.
#
# Usage:
#   ./scripts/07-pack-existing.sh /path/to/Image.gz-dtb
#   ./scripts/07-pack-existing.sh /path/to/Image.gz
#   ./scripts/07-pack-existing.sh /path/to/Image      # auto-gzipped
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

SRC="${1:-}"
[ -z "$SRC" ] && die "usage: $0 /path/to/Image[.gz|.gz-dtb]"
[ -f "$SRC" ] || die "not a file: $SRC"

WORK="$OUT_DIR/anykernel3-pack-$(date +%s)"
rm -rf "$WORK"
cp -a "$ANYKERNEL3_DIR" "$WORK"

# Fetch real ak3-core.sh if missing
if [ ! -s "$WORK/tools/ak3-core.sh" ]; then
  echo "==> Fetching ak3-core.sh"
  curl -L --fail -o "$WORK/tools/ak3-core.sh" \
    https://raw.githubusercontent.com/osm0sis/AnyKernel3/master/tools/ak3-core.sh \
    || die "ak3-core.sh fetch failed"
  chmod 0755 "$WORK/tools/ak3-core.sh" || true
fi

# Normalize: final file is always Image.gz
case "$SRC" in
  *.gz)        cp -v "$SRC" "$WORK/Image.gz" ;;
  *.gz-dtb)    cp -v "$SRC" "$WORK/Image.gz" ;;
  *)           gzip -9 -c "$SRC" > "$WORK/Image.gz" ;;
esac

# Sanity
[ -s "$WORK/Image.gz" ] || die "Image.gz is empty"
file "$WORK/Image.gz" | grep -qi gzip || die "Image.gz is not a valid gzip"

# Update module.prop
TS=$(date +%Y%m%d-%H%M)
sed -i "s|^version=.*|version=${KSU_VERSION}-${TS}|" "$WORK/module.prop" || true
sed -i "s|^date=.*|date=$(date +%Y-%m-%d)|" "$WORK/module.prop" || true

ZIP="$OUT_DIR/${ZIPNAME_BASE}-pack-${TS}.zip"
which zip >/dev/null || { sudo apt-get install -y zip; }
( cd "$WORK" && zip -r9 "$ZIP" . -x "*.bak" "*.swp" ) >/dev/null
echo ""
echo "============================================================"
echo "  Built: $ZIP"
echo "  Size:  $(du -h "$ZIP" | awk '{print $1}')"
echo "============================================================"
echo "  Flash:"
echo "    adb push $ZIP /sdcard/"
echo "    adb reboot recovery"
echo "    (TWRP) Install -> $ZIP"
echo "============================================================"
