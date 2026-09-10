# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# yazhu kernel v2 — OnePlus 11R (udon / CPH2487)
# Ships: kernel Image (boot) + dtb (vendor_boot) + dtbo.img (dtbo)
#        + vendor_boot ramdisk modules + vendor_dlkm modules (systemless KSU module)

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
# write_boot flashes: boot (Image) + dtbo (dtbo.img) and, with dtb + vendor_ramdisk
# present at zip root (hdr v4 auto-setup), vendor_boot (dtb + ramdisk module overwrite).
dump_boot;

write_boot;   # flashes boot (Image), vendor_boot (dtb + ramdisk modules) and dtbo (dtbo.img)

## vendor_dlkm modules -> systemless KernelSU/Magisk module
# vendor_dlkm is EROFS (read-only) so modules are overlaid; overlay applies at
# post-fs-data, before vendor modprobe runs. Auto-removed if kernel is reflashed.
if [ "$DO_MODULES" == 1 ] && [ -d "$HOME/modules/vendor_dlkm" ]; then
  ui_print "   Installing vendor_dlkm modules (systemless)";
  MODDIR=/data/adb/modules/udon_yazhu_kmod;
  rm -rf $MODDIR;
  mkdir -p $MODDIR/system/vendor_dlkm/lib/modules;
  cp -rf $HOME/modules/vendor_dlkm/. $MODDIR/system/vendor_dlkm/lib/modules/;
  KO=$(ls $MODDIR/system/vendor_dlkm/lib/modules/*.ko 2>/dev/null | head -1);
  KV=$(strings "$KO" 2>/dev/null | grep -m1 "Linux version [0-9]*\.[0-9]*\.[0-9]*" | cut -d' ' -f3);
  [ -n "$KV" ] || KV="5.10.246";
  cat > $MODDIR/module.prop <<MEOF
id=udon_yazhu_kmod
name=yazhu kernel modules (udon)
version=${KV:-5.10.246}
versionCode=$(date +%Y%m%d)
author=Gokulgethu
description=Kernel-matched vendor_dlkm modules for the yazhu kernel. Installed by AnyKernel3; safe to remove after flashing a different kernel.
MEOF
  set_perm_recursive $MODDIR 0 0 755 644;
  ui_print "   modules: $(ls $MODDIR/system/vendor_dlkm/lib/modules/*.ko 2>/dev/null | wc -l) installed systemless";
fi

ui_print "   yazhu kernel installed - reboot to apply";
## end install
