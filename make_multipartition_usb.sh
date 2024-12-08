#!/usr/bin/env bash
# based on https://unix.stackexchange.com/questions/382817/uefi-bios-bootable-live-debian-stretch-amd64-with-persistence


test "${2}" = "" && echo "$0 <iso> </dev/..>" && exit 1
test "`id -u`" != "0" && echo "requires root permissions to run" && exit 1

# required commands
err=0
for cmd in parted mkfs.vfat mkfs.ext4 grub-install dd sed /usr/lib/syslinux/bios/gptmbr.bin; do
  command -v $cmd >/dev/null && continue || { echo "$cmd command not found."; err=1; }
done
test $err -eq 1 && exit 1

set -e # exit on any error
set -x # show commands

# Create partitions
parted ${2} --script mktable gpt
parted ${2} --script mkpart EFI fat16 1MiB 10MiB
parted ${2} --script mkpart live fat16 10MiB 3GiB
parted ${2} --script mkpart persistence ext4 3GiB 100%
parted ${2} --script set 1 msftdata on
parted ${2} --script set 2 legacy_boot on
parted ${2} --script set 2 msftdata on

# Create Filesystems
mkfs.vfat -n EFI ${2}1
mkfs.vfat -n LIVE ${2}2
mkfs.ext4 -F -L persistence ${2}3

# Mounting the resources
mkdir /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso
mount ${2}1 /tmp/usb-efi
mount ${2}2 /tmp/usb-live
mount ${2}3 /tmp/usb-persistence
mount -oro ${1} /tmp/live-iso

# Install live system
cp -ar /tmp/live-iso/* /tmp/usb-live

# persistence.conf
echo "/ union" > /tmp/usb-persistence/persistence.conf

# Grub for UEFI support
grub-install --no-uefi-secure-boot --removable --target=x86_64-efi --boot-directory=/tmp/usb-live/boot/ --efi-directory=/tmp/usb-efi ${2}

# Syslinux for legacy BIOS support
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/gptmbr.bin of=${2}
syslinux --install ${2}2

# Isolinux fixup
mv /tmp/usb-live/isolinux /tmp/usb-live/syslinux
mv /tmp/usb-live/syslinux/isolinux.bin /tmp/usb-live/syslinux/syslinux.bin
mv /tmp/usb-live/syslinux/isolinux.cfg /tmp/usb-live/syslinux/syslinux.cfg

# Kernel parameters
sed --in-place '0,/boot=live/{s/\(boot=live .*\)$/\1 persistence/}' /tmp/usb-live/boot/grub/grub.cfg /tmp/usb-live/syslinux/menu.cfg

# Grub splash (optional)
#sed --in-place 's#isolinux/splash#syslinux/splash#' /tmp/usb-live/boot/grub/grub.cfg

# Unmounting and Cleanup
umount /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso
rmdir /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso
