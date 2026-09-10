# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# yazhu kernel v3 — OnePlus 11R (udon / CPH2487)
# Ships: kernel Image (boot) + dtb (vendor_boot) + dtbo.img (dtbo)
#        + vendor_boot ramdisk modules + vendor_dlkm modules (ak3-helper systemless module)

## AnyKernel setup
# begin properties
properties() { '
kernel.string=yazhu (rocko5498-proven sm8450) by Gokulgethu
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=1
device.name1=udon
device.name2=OP5961L1
device.name3=CPH2487
device.name4=OnePlus 11R
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=auto;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
. tools/ak3-core.sh;

## AnyKernel install
# Pre-flash safety: back up the images being replaced (one-time; existing backups never
# overwritten). Restore with fastboot flash boot|vendor_boot|dtbo <img> if needed.
BACKUP_DIR=/data/media/0/yazhu_backup;
mkdir -p $BACKUP_DIR;
for PART in boot vendor_boot dtbo; do
  SRC=/dev/block/by-name/${PART}${SLOT};
  [ -e "$SRC" ] || SRC=/dev/block/bootdevice/by-name/${PART}${SLOT};
  DST=$BACKUP_DIR/${PART}${SLOT}.img;
  if [ -e "$SRC" ] && [ ! -f "$DST" ]; then
    dd if=$SRC of=$DST bs=4194304 2>/dev/null && ui_print "   backed up ${PART}${SLOT} to /sdcard/yazhu_backup";
  fi;
done;

dump_boot;

# flashes boot (Image) + vendor_boot (dtb + ramdisk modules) + dtbo (dtbo.img);
# vendor_dlkm/system_dlkm/dtbo are auto-flashed only if present at zip root
write_boot;

# vendor_dlkm modules install via AK3's built-in "ak3-helper" systemless module
# (do.modules=1 + do.systemless=1): KernelSU natively overlays <module>/vendor_dlkm
# onto /vendor_dlkm, and the helper self-removes if a different kernel is booted.
ui_print "   vendor_dlkm modules installed systemless (ak3-helper)";
ui_print "   remove anytime: delete /data/adb/modules/ak3-helper";
ui_print "   yazhu kernel installed - reboot to apply";
## end install
