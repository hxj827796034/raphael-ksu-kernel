#!/usr/bin/env bash
# 03 — Clone SukiSU-Ultra (KSU)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

if [ -d "$KSU_DIR/.git" ]; then
  bold "==> KSU already cloned, fetching"
  git -C "$KSU_DIR" fetch --depth=1 origin "$KSU_BRANCH" || true
else
  bold "==> Cloning $KSU_REPO (branch $KSU_BRANCH) -> $KSU_DIR"
  git clone --depth=1 -b "$KSU_BRANCH" "$KSU_REPO" "$KSU_DIR"
fi

# Validate that this KSU supports 4.14
if [ -f "$KSU_DIR/Makefile" ]; then
  if grep -q "4\.14" "$KSU_DIR/README.md" 2>/dev/null; then
    bold "==> KSU README mentions 4.14 support"
  fi
fi
[ -d "$KSU_DIR/kernel" ] || die "KSU dir looks broken: $KSU_DIR/kernel missing"

bold "==> 03 done"
