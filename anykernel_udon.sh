# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# Modified for Yazhu Kernel - OnePlus 11R (udon)

## AnyKernel setup
# begin properties
properties() { '
kernel.string=yazhu by Gokulgethu
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=1
device.name1=udon
device.name2=OP535DL1
device.name3=CPH2487
device.name4=CPH2423
device.name5=OnePlus 11R
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=auto;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel install
dump_boot;

# begin ramdisk changes
# Preserve the original ramdisk from the ROM
# No modifications needed - kernel-only flash
ui_print "   Yazhu kernel - preserving ROM ramdisk";
# end ramdisk changes

write_boot;
## end install
