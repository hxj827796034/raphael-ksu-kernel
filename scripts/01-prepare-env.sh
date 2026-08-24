#!/usr/bin/env bash
# 01 — Prepare environment
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

bold "==> Checking host environment"

if ! command -v git >/dev/null; then
  die "git not found. apt install git"
fi
if ! command -v make >/dev/null; then
  die "make not found. apt install build-essential"
fi
for pkg in bc flex bison libssl-dev libelf-dev cpio python3 rsync curl xz-utils unzip; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    warn "missing pkg: $pkg — installing"
    sudo apt-get update -y
    sudo apt-get install -y "$pkg"
  fi
done
# Optional but recommended
for pkg in u-boot-tools dosfstools; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    warn "missing pkg: $pkg — installing (optional)"
    sudo apt-get install -y "$pkg" || true
  fi
done

# Disk check
avail=$(df -BG "$PWD" | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "${avail:-0}" -lt 80 ]; then
  warn "Available disk: ${avail}G — recommend >= 80G"
fi

# Toolchain
if [ "$USE_CLANG" = "1" ]; then
  if [ ! -x "$CLANG_BIN" ]; then
    warn "clang not found at $CLANG_BIN"
    warn "Download: https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master/clang-r377417/"
    warn "Or set CLANG_DIR=... in env.sh"
  fi
else
  if [ ! -x "${AARCH64_GCC_BIN}gcc" ]; then
    warn "Linaro GCC not found at ${AARCH64_GCC_BIN}gcc"
    warn "Download aarch64-linux-gnu 9.2 from:"
    warn "  https://releases.linaro.org/components/toolchain/binaries/9.2-2019.12/aarch64-linux-gnu/gcc-linaro-9.2.1-2019.12-x86_64_aarch64-linux-gnu.tar.xz"
    warn "Extract to: $AARCH64_GCC_DIR"
  fi
fi

bold "==> Environment summary"
echo "Kernel source: $KERNEL_REPO @ $KERNEL_BRANCH"
echo "KSU:           $KSU_REPO @ $KSU_BRANCH"
echo "SUSFS:         $ENABLE_SUSFS   TRICKY: $ENABLE_TRICKY   HMA: $ENABLE_HMA"
echo "Toolchain:     $([ "$USE_CLANG" = "1" ] && echo "clang" || echo "gcc")"
echo "Defconfig:     $DEFCONFIG"
echo "Jobs:          $JOBS"
echo "Out dir:       $OUT_DIR"

bold "==> 01 done"
