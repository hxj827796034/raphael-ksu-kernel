#!/usr/bin/env bash
# =============================================================
#  KernelSU-Kernel for raphael - one-shot build entry
#  Usage: ./build.sh all            # full pipeline
#         ./build.sh env            # check env
#         ./build.sh clean          # cleanup
#         ./build.sh 02             # run single step
# =============================================================
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
source ./env.sh

bold() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

[ -f /proc/version ] && grep -qi 'microsoft' /proc/version && {
  warn "Detected WSL1 — strongly recommend WSL2 for build perf."
}

run_step() {
  local s="$1"
  local f="scripts/${s}-*.sh"
  local file
  file=$(ls $f 2>/dev/null | head -1 || true)
  [ -z "$file" ] && die "no script matching $f"
  bold "Running $file"
  bash "$file"
}

case "${1:-help}" in
  all)
    for s in 01 02 03 04 05 06; do run_step "$s"; done
    bold "Done. Artifacts: $OUT_DIR"
    ls -la "$OUT_DIR" || true
    ;;
  env)    run_step 01 ;;
  clone)  run_step 02; run_step 03 ;;
  patch)  run_step 04 ;;
  build)  run_step 05 ;;
  pack)   run_step 06 ;;
  clean)  run_step 99 ;;
  [0-9][0-9]) run_step "$1" ;;
  help|--help|-h)
    cat <<EOF
Usage: $0 <command>
Commands:
  all     Full pipeline (env -> clone -> patch -> build -> pack)
  env     Prepare/check build environment
  clone   Clone kernel + KSU sources
  patch   Apply KSU / SUSFS / TrickyStore patches
  build   Compile the kernel
  pack    Package into AnyKernel3 zip
  clean   Remove cloned sources and build artifacts
  NN      Run a single step (e.g. 02, 04, ...)
EOF
    ;;
  *) die "unknown command: $1 (try '$0 help')" ;;
esac
