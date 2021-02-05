
# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
'; } # end properties

# shell variables
block=/dev/block/platform/13500000.dwmmc0/by-name/boot;
dtboblock=/dev/block/platform/13500000.dwmmc0/by-name/dtbo;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
if [ ! -f "$ramdisk/ramdisk.cpio" ]; then
	set_perm_recursive 0 0 755 644 $ramdisk/*;
	set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
fi;

## AnyKernel install
dump_boot;

# begin ramdisk changes

# end ramdisk changes

write_boot;
## end install

