# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# yazhu kernel v4 all-in-one — OnePlus 11R (udon / CPH2487)
# Ships: kernel Image (boot) + dtb (vendor_boot) + dtbo.img (dtbo)
#        + vendor_boot ramdisk modules + vendor_dlkm modules (ak3-helper systemless module)
#        + bundled integrity stack (ksud, KSU manager APK, susfs/ZygiskNext/PIF/TrickyStore)

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

### bundled integrity stack (stack/ in zip root)
STACK=$AKHOME/stack;
if [ -d "$STACK" ]; then
  ui_print " ";
  ui_print "   bundled integrity stack found - installing";

  # --- ensure /data is available ---
  DATAOK=0;
  if [ -d /data/adb ] || [ -d /data/media ]; then
    DATAOK=1;
  else
    mount /data 2>/dev/null;
    for DEV in /dev/block/by-name/userdata /dev/block/bootdevice/by-name/userdata; do
      [ -e "$DEV" ] && mount -t ext4 $DEV /data 2>/dev/null;
    done;
    [ -d /data/adb ] && DATAOK=1;
  fi;

  if [ "$DATAOK" != "1" ]; then
    ui_print "   ! /data not accessible (locked?) - stack NOT installed";
    ui_print "   ! after boot, flash this same zip via KernelSU app";
  else
    mkdir -p /data/adb /data/adb/ksu /data/adb/modules_update /data/media/0/Download;

    # --- ksud: the module engine (kernel spawns it on every boot) ---
    if cp -f $STACK/ksud-aarch64 /data/adb/ksud; then
      chmod 755 /data/adb/ksud;
      /system/bin/chcon -h u:object_r:adb_data_file:s0 /data/adb/ksud 2>/dev/null;
      ui_print "   ksud installed (modules apply on next boot)";
    fi;

    # --- booted system? (KernelSU-app flash path) ---
    BOOTED=0;
    command -v getprop >/dev/null 2>&1 && [ "$(getprop sys.boot_completed)" = "1" ] && BOOTED=1;

    # --- manager APK ---
    if [ "$BOOTED" = "1" ] && command -v pm >/dev/null 2>&1 && pm install -r $STACK/ksu_manager_v1.0.5.apk >/dev/null 2>&1; then
      ui_print "   KernelSU manager app installed";
    else
      cp -f $STACK/ksu_manager_v1.0.5.apk /data/media/0/Download/ 2>/dev/null;
      /system/bin/chcon -h u:object_r:media_rw_data_file:s0 /data/media/0/Download/ksu_manager_v1.0.5.apk 2>/dev/null;
      ui_print "   manager APK at /sdcard/Download - install it";
    fi;

    # --- modules, in dependency order ---
    i=0;
    for M in susfs_module zygisknext playintegrityfork trickystore; do
      i=$((i+1));
      Z=$STACK/$M.zip;
      [ -f "$Z" ] || continue;
      ID=$(unzip -p $Z module.prop 2>/dev/null | grep '^id=' | cut -d= -f2);
      DONE=0;
      if [ -x /data/adb/ksud ]; then
        if /data/adb/ksud module install $Z >/dev/null 2>&1; then
          if { [ -d /data/adb/modules/$ID ] || [ -d /data/adb/modules_update/$ID ]; }; then
            DONE=1;
            ui_print "   [$i/4] $M installed";
          fi;
        fi;
      fi;
      if [ "$DONE" != "1" ]; then
        # fallback: stage raw into modules_update (applied by ksud on boot)
        # + keep the zip in Download for a clean install via KSU manager
        if [ -n "$ID" ]; then
          mkdir -p /data/adb/modules_update/$ID;
          unzip -oq $Z -d /data/adb/modules_update/$ID 2>/dev/null;
          /system/bin/chcon -hR u:object_r:adb_data_file:s0 /data/adb/modules_update/$ID 2>/dev/null;
        fi;
        cp -f $Z /data/media/0/Download/ 2>/dev/null;
        /system/bin/chcon -h u:object_r:media_rw_data_file:s0 /data/media/0/Download/$M.zip 2>/dev/null;
        ui_print "   [$i/4] $M staged - if it shows uninstalled,";
        ui_print "         install it from /sdcard/Download in KSU app";
      fi;
    done;
    /system/bin/chcon -hR u:object_r:adb_data_file:s0 /data/adb/modules_update /data/adb/modules 2>/dev/null;
    ui_print " ";
    ui_print "   after reboot: open KernelSU app, verify 4 modules,";
    ui_print "   open susfs WebUI - enable Spoof kernel version";
  fi;
fi;
### end stack

ui_print "   yazhu kernel installed - reboot to apply";
## end install
