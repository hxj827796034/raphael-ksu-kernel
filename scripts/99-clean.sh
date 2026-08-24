#!/usr/bin/env bash
# 99 — Clean all artifacts and clones
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

warn "This will DELETE:"
echo "  - $KERNEL_DIR"
echo "  - $KSU_DIR"
echo "  - $OUT_DIR (incl. .zip outputs)"
read -p "Type 'YES' to continue: " ans
[ "$ans" = "YES" ] || { echo "aborted"; exit 0; }

rm -rf "$KERNEL_DIR" "$KSU_DIR" "$OUT_DIR"
echo "cleaned"
