#!/usr/bin/env bash
# 05 — Build the kernel
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

cd "$KERNEL_DIR"
mkdir -p "$OUT_DIR"

export ARCH SUBARCH
# Headers + compiler
if [ "$USE_CLANG" = "1" ]; then
  export PATH="$CLANG_DIR/bin:$PATH"
  CC="clang"
  CROSS_COMPILE="aarch64-linux-gnu-"
  CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
else
  export PATH="$AARCH64_GCC_DIR/bin:$PATH"
  CC="${AARCH64_GCC_BIN}gcc"
  CROSS_COMPILE="$AARCH64_GCC_BIN"
  CROSS_COMPILE_ARM32="arm-none-eabi-"
fi

bold "==> make clean"
make clean 2>/dev/null || true

bold "==> make $DEFCONFIG"
make "$DEFCONFIG"

bold "==> make -j$JOBS (this may take 30-90 min)"
make -j"$JOBS" \
  CC="$CC" \
  CROSS_COMPILE="$CROSS_COMPILE" \
  CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" \
  2>&1 | tee "$OUT_DIR/build.log"

# Find produced images
shopt -s nullglob
for img in arch/arm64/boot/Image arch/arm64/boot/Image.gz arch/arm64/boot/Image.gz-dtb arch/arm64/boot/dtb.img; do
  [ -f "$img" ] && cp -v "$img" "$OUT_DIR/"
done
shopt -u nullglob

bold "==> Build artifacts:"
ls -la "$OUT_DIR"/Image* "$OUT_DIR"/dtb.img 2>/dev/null || die "no Image produced"

bold "==> 05 done"
