#!/system/bin/sh
# =============================================================
#  AnyKernel3 flashable — raphael (Redmi K20 Pro / Mi 9T Pro)
#  Replace stock boot Image with KSU-enabled kernel
# =============================================================
# kernel_patch=<patch level>
# cmdline=<cmdline to append>
# device.name1=raphael
# device.name2=
# device.name3=
# supported.versions=10-15
# supported.patchlevels=
# ==============<DON'T CHANGE>============================
properties() {
  kernel.string=KSU-SukiSU-for-raphael
  do.devicecheck=1
  do.modules=0
  do.systemless=0
  do.cleanup=1
  do.cleanuponabort=0
  device.name1=raphael
  device.name2=
  device.name3=
  supported.versions=10-15
  supported.patchlevels=
  supported.vendorpatchlevels=
}
# =============</DON'T CHANGE>============================
# Author: ksu-builder
# Credit: osm0sis, topjohnwu, SukiSU-Ultra team

block=/dev/block/bootdevice/by-name/boot
is_slot_device=0
ramdisk_compression=auto
patch_vbmeta_flag=0
no_magisk_check=1

. tools/ak3-core.sh

# Extra safety: verify image is non-zero and is a real Image
if [ ! -s "$WORKING_DIR/Image.gz" ]; then
  abort "Image.gz is empty — bad build"
fi

# Detect gzip type
file_test=$(file -b "$WORKING_DIR/Image.gz")
if ! echo "$file_test" | grep -qi 'gzip'; then
  abort "Image.gz is not gzip: $file_test"
fi

# Flash
dump_boot | replace_boot

ui_print "✅ KSU kernel installed."
ui_print "👉 Install 'KernelSU' (official) or 'SukiSU Manager' to manage root."

exit 0
