#!/usr/bin/env bash
# Setup disk to be readonly

# Following files will have symlinks to /tmp created for them
MODIFIABLE="
/home/pi/show/show.log
/home/pi/show/lcd/lcd_media.txt
/home/pi/show/lcd/index.css
"
IFS=$'\n'

if grep -q '/dev/mmcblk0p2.*ro' /etc/fstab ; then
    echo "# disk_readonly: Already setup"
    # Setup modifiable files
    for f in "$MODIFIABLE" ; do
        tmpf=/tmp/$(basename $f)
        touch "$tmpf"
    done
else
    sudo sed -i '/^\/dev\/mmcblk0p2\s\+/s/\(defaults,noatime\)/\1,ro/' /etc/fstab
    sudo mount -o rmount,ro /dev/mmcblk0p2
    for f in "$MODIFIABLE" ; do
        tmpf=/tmp/$(basename $f)
        ln -sf "$f" "$tmpf"
    done
fi