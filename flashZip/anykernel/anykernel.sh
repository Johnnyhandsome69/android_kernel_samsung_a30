# Ubport GSI installer Script
# erfanoabdi @ xda-developers
OUTFD=/proc/self/fd/$1;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

## GSI install

cp -fpr /external_sd/data/* /data/;

mkdir /s;
mkdir /r;

mount /data/system.img /s;
ui_print "Setting udev rules";
cat /s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /data/70-ubport.rules;
umount /s;

mount /data/rootfs.img /r;
mv /data/70-ubport.rules /r/etc/udev/rules.d/70-ubport.rules;
echo "FORM_FACTOR=handset" >> /r/etc/ubuntu-touch-session.d/android.conf;
if grep -q ro.sf.lcd_density /vendor/build.prop; then
    PX=`grep ro.sf.lcd_density /vendor/build.prop | cut -d "=" -f 2 | awk '{$1=int($1/20);printf $1}'`;
    DPR=`grep ro.sf.lcd_density /vendor/build.prop | cut -d "=" -f 2 | awk '{$1=int($1/20);$1=$1/10.0;printf $1}'`;
    ui_print "Setting phone DPI";
    echo "GRID_UNIT_PX=$PX" >> /r/etc/ubuntu-touch-session.d/android.conf;
    echo "QTWEBKIT_DPR=$DPR" >> /r/etc/ubuntu-touch-session.d/android.conf;
fi

ui_print "Updating ubuntu usb tethering for samsung";
cp -fpr /external_sd/data/usb-tethering /r/usr/bin/;
chmod 0755 /r/usr/bin/usb-tethering;

umount /r;

mv /data/system.img /data/android-rootfs.img

ui_print "Resizing rootfs to 8GB";
e2fsck -fy /data/rootfs.img
resize2fs /data/rootfs.img 8G

## end install

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

