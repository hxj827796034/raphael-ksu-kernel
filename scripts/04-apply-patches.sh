#!/usr/bin/env bash
# 04 — Apply KSU + optional SUSFS / TrickyStore patches and merge defconfig
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
source ./env.sh

cd "$KERNEL_DIR"

# -------- 1) Apply KSU --------
bold "==> Applying KSU patch (SukiSU-Ultra driver)"
if [ -d "./KernelSU" ]; then
  bold "    KernelSU/ already present, removing"
  rm -rf ./KernelSU
fi
cp -a "$KSU_DIR" ./KernelSU
# SukiSU driver lives in KernelSU/kernel; legacy uses drivers/kernelsu
if [ -d "KernelSU/kernel" ]; then
  bold "    Found KernelSU/kernel — will be auto-included by KSU build hook"
fi
# Some KSU variants ship a one-shot patch script:
if [ -x "./KernelSU/scripts/gen_patch.sh" ]; then
  bash ./KernelSU/scripts/gen_patch.sh > ./ksu.patch || true
  if [ -s ./ksu.patch ]; then
    patch -p1 --dry-run < ./ksu.patch >/dev/null 2>&1 && patch -p1 < ./ksu.patch || true
  fi
fi
# SukiSU-Ultra autoload: it injects itself via Makefile hooks; no manual patch needed
bold "    SukiSU-Ultra is self-injecting — its presence under ./KernelSU is enough"

# -------- 2) SUSFS --------
if [ "$ENABLE_SUSFS" = "1" ]; then
  bold "==> Cloning SUSFS"
  if [ ! -d "$PWD/susfs" ]; then
    git clone --depth=1 -b "$SUSFS_BRANCH" "$SUSFS_REPO" "$PWD/susfs" || \
      warn "SUSFS clone failed — disabling"
  fi
  if [ -d "$PWD/susfs" ] && [ -f "$PWD/susfs/kernel_patches/4.14/susfs.patch" ]; then
    bold "    Applying susfs patch"
    patch -p1 --dry-run < "$PWD/susfs/kernel_patches/4.14/susfs.patch" >/dev/null 2>&1 \
      && patch -p1 < "$PWD/susfs/kernel_patches/4.14/susfs.patch" \
      || warn "SUSFS patch did not apply cleanly; will still try compile"
  fi
fi

# -------- 3) TrickyStore --------
if [ "$ENABLE_TRICKY" = "1" ]; then
  bold "==> Cloning TrickyStore"
  if [ ! -d "$PWD/TrickyStore" ]; then
    git clone --depth=1 -b "$TRICKY_BRANCH" "$TRICKY_REPO" "$PWD/TrickyStore" || warn "TrickyStore clone failed"
  fi
  if [ -f "$PWD/TrickyStore/patches/4.14.patch" ]; then
    patch -p1 --dry-run < "$PWD/TrickyStore/patches/4.14.patch" >/dev/null 2>&1 \
      && patch -p1 < "$PWD/TrickyStore/patches/4.14.patch" || true
  fi
fi

# -------- 4) Merge KSU defconfig --------
bold "==> Merging KSU defconfig fragment into $DEFCONFIG"
DC_PATH="arch/arm64/configs/${DEFCONFIG}"
[ -f "$DC_PATH" ] || die "defconfig not found: $DC_PATH"

# Append fragment (idempotent: skip lines already present)
MERGE_FILE="$OLDPWD/defconfig/raphael_ksu_defconfig"
[ -f "$MERGE_FILE" ] || die "merge file missing: $MERGE_FILE"
{
  echo ""
  echo "# --- KSU auto-merged $(date -u +%FT%TZ) ---"
  cat "$MERGE_FILE"
} >> "$DC_PATH.tmp"

# Filter duplicates
awk -F'=' '
  !($1 in seen) { print; seen[$1]=1 }
' "$DC_PATH" "$DC_PATH.tmp" > "$DC_PATH.new" || cp "$DC_PATH.tmp" "$DC_PATH.new"
mv "$DC_PATH.new" "$DC_PATH"
rm -f "$DC_PATH.tmp"
rm -f "$DC_PATH.tmp"

bold "==> defconfig head after merge:"
head -n 5 "$DC_PATH"
echo "..."
grep -E '^CONFIG_KSU|^CONFIG_SUSFS|^CONFIG_TRICKY|^CONFIG_KPM' "$DC_PATH" || warn "no KSU symbols in defconfig — check merge file"

bold "==> 04 done"
