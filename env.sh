#!/usr/bin/env bash
# =============================================================
#  KernelSU-Kernel for raphael - environment variables
#  Edit this file to switch kernel source, KSU variant, tools.
# =============================================================

# ---- Kernel source -------------------------------------------------
# Default: MiCode (Xiaomi official OSS) raphael branch (4.14.x)
KERNEL_REPO="${KERNEL_REPO:-https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git}"
KERNEL_BRANCH="${KERNEL_BRANCH:-raphael}"
KERNEL_DIR="${KERNEL_DIR:-$PWD/raphael}"

# ---- KernelSU variant ----------------------------------------------
# Default: SukiSU-Ultra (best 4.14 compat)
# User is using OFFICIAL KernelSU Manager v3.2.5 (tiann/KernelSU).
# SukiSU kernel-side is 100% ABI-compatible with the official Manager.
# Switch to tiann/KernelSU ONLY if you need a feature SukiSU lacks.
#   KSU_REPO="https://github.com/tiann/KernelSU.git"
#   KSU_BRANCH="v0.9.5"   # last 4.14-friendly official release
KSU_REPO="${KSU_REPO:-https://github.com/SukiSU-Ultra/KernelSU.git}"
KSU_BRANCH="${KSU_BRANCH:-main}"
KSU_DIR="${KSU_DIR:-$PWD/KernelSU}"

# Target KernelSU Manager APK info (recorded for future reference)
KSU_MANAGER_VERSION="3.2.5"
KSU_MANAGER_BUILD="32525"
KSU_MANAGER_SHA256="1417081413bf7ab1de8e440ecbcb62685037c8f28f048f0f8b79e305b31ab916"

# ---- Optional modules ----------------------------------------------
ENABLE_SUSFS="${ENABLE_SUSFS:-1}"        # 1=on, 0=off
SUSFS_REPO="${SUSFS_REPO:-https://github.com/sidex15/susfs4ksu.git}"
SUSFS_BRANCH="${SUSFS_BRANCH:-gki-4.14-stable}"

ENABLE_TRICKY="${ENABLE_TRICKY:-0}"      # 1=on, 0=off
TRICKY_REPO="${TRICKY_REPO:-https://github.com/5ec1cff/TrickyStore.git}"
TRICKY_BRANCH="${TRICKY_BRANCH:-main}"

ENABLE_HMA="${ENABLE_HMA:-0}"            # 1=on, 0=off

# ---- Toolchain ------------------------------------------------------
# Recommend Linaro GCC 9.2 for 4.14. If you prefer AOSP clang, set CLANG_BIN instead.
AARCH64_GCC_DIR="${AARCH64_GCC_DIR:-$HOME/toolchains/aarch64-linux-gnu}"
AARCH64_GCC_BIN="${AARCH64_GCC_BIN:-$AARCH64_GCC_DIR/bin/aarch64-none-linux-gnu-}"
GCC_VER="9.2.2019.12"

# Optional AOSP Clang
USE_CLANG="${USE_CLANG:-0}"              # 0=GCC, 1=AOSP clang
CLANG_DIR="${CLANG_DIR:-$HOME/toolchains/clang-r377417}"
CLANG_BIN="${CLANG_BIN:-$CLANG_DIR/bin/clang}"

# ---- Build settings ------------------------------------------------
DEFCONFIG="${DEFCONFIG:-raphael_defconfig}"
KERNEL_IMAGE_NAME="${KERNEL_IMAGE_NAME:-Image.gz-dtb}"
ANYKERNEL3_DIR="${ANYKERNEL3_DIR:-$PWD/anykernel3-raphael}"
OUT_DIR="${OUT_DIR:-$PWD/out}"
JOBS="${JOBS:-$(nproc)}"
ARCH="arm64"
SUBARCH="arm64"

# ---- Cosmetic -------------------------------------------------------
KSU_VERSION="${KSU_VERSION:-$(date +%Y%m%d)}"
ZIPNAME_BASE="KSU-raphael-AnyKernel3-${KSU_VERSION}"
