#!/usr/bin/env bash
# 02 — Clone Xiaomi OSS kernel (raphael)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

if [ -d "$KERNEL_DIR/.git" ]; then
  bold "==> Kernel already cloned, fetching"
  git -C "$KERNEL_DIR" fetch --depth=1 origin "$KERNEL_BRANCH" || true
else
  bold "==> Cloning $KERNEL_REPO (branch $KERNEL_BRANCH) -> $KERNEL_DIR"
  mkdir -p "$(dirname "$KERNEL_DIR")"
  git clone --depth=1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_DIR"
fi

cd "$KERNEL_DIR"

# Sanity: must contain arch/arm64/configs/raphael_defconfig (or vendor/)
if ! ls arch/arm64/configs/*raphael*defconfig >/dev/null 2>&1; then
  warn "raphael_defconfig not found in $KERNEL_DIR/arch/arm64/configs/"
  warn "Available raphael* defconfigs:"
  ls arch/arm64/configs/ | grep -i raphael || true
  warn "If using a different layout, set DEFCONFIG in env.sh accordingly."
fi

bold "==> Available defconfigs matching *raphael*:"
ls arch/arm64/configs/ | grep -i raphael || ls arch/arm64/configs/ | head -20

bold "==> 02 done"
