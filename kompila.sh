#!/bin/bash
set -e

if [ ! -r .config ]; then
  echo "Cannot access .config (are you in /usr/src/linux?)"
  exit 1
fi

if [ `id -u` != "0" ]; then
  echo "You must be superuser to run this script"
  exit 1
fi

ESPDIR="/boot/efi/EFI/Slackware"
OLDVER=`uname -r`
VERSION=`cat .config|grep "Linux"|cut -c 13-17`

incorrectVersion() {
  echo "Invalid kernel version: $VERSION"
  exit 1;
}

if [ -z $VERSION ]; then
  echo -n "Type the kernel version you wish to compile: "
else
  echo -n "Type the kernel version you wish to compile [${VERSION}]: "
fi

read INPUT
if [ ! $INPUT ]; then
  if [ -z $VERSION ]; then
    incorrectVersion
  fi
else
  VERSION=$INPUT
fi

make bzImage && make modules && make modules_install

mkdir /boot/efi/EFI/Linux-$OLDVER
mv $ESPDIR/*-$OLDVER* /boot/efi/EFI/Linux-$OLDVER
cp -v $ESPDIR/linux.conf /boot/efi/EFI/Linux-$OLDVER

cp -v .config $ESPDIR/config-$VERSION
cp -v System.map $ESPDIR/System.map-$VERSION
cp -v arch/x86_64/boot/bzImage $ESPDIR/vmlinuz-$VERSION.efi

mkinitrd -l it -c -k $VERSION -f ext4 -r /dev/cryptvg/rootlv \
-m ehci-hcd:uhci-hcd:usb-storage:hid:usbhid:fat:nls_cp437:nls_iso8859-15:msdos:vfat\
:mbcache:jdb2:crc16:ext4::drm:i915 -C /dev/sda5 \
-L -u -h /dev/cryptvg/swaplv -o $ESPDIR/initrd-$VERSION.gz
#-K LABEL=TNM:/keys/keyfile00

ls $ESPDIR
ls /boot/efi/EFI/Linux-$OLDVER

