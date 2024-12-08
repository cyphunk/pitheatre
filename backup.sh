#!/usr/bin/env bash

l=($(ls -l `readlink -f $0`))
[ ${l[0]:2:1} != "-" ] && [ "${l[2]}" != "root" ] ||
[ ${l[0]:5:1} != "-" ] && [ "${l[3]}" != "root" ] ||
[ ${l[0]:8:1} != "-" ] && { echo -e "only root should be able to modify\n${l[@]}"; }

OS=$(uname)
BACKUPDIR=images/


if [ $# -lt 2 ]; then
	echo "attached drives:"
	[ $OS == "Darwin" ] \
		&& diskutil list \
		|| (mount | grep -e sda -e mmcblk && ls /dev/sd* /dev/mmcblk* | sort)
	echo
	echo "usage: $0 <rdiskpath> [project [hardware-type [image-version]]]"
    echo
    echo "to image back to sd:"
    echo "gzip -c -d images/imagename.img.gz | dd bs=4m conv=fsync status=progress of=/dev/rdiskpath"
	exit
fi
rdisk="$1"
test -n "$2" \
&& project="${2}_"
test -n "$3" \
&& hardware="${3}_"
test -n "$4" \
&& imageversion="${4}_"

sudo -v
DATESLUG=`date +%Y%m%d`

if [ $OS == "Darwin" ]; then
    BS="4m"
else
    BS="4M"
fi

TARGET="$project$hardware$version$DATESLUG.img.gz"

read -p "dd from $rdisk drive to $TARGET? ([y]/n) " YN
####
if [ "$YN" != "n" ]; then
    sudo dd if=$rdisk bs=$BS conv=fsync status=progress | gzip -9 > $BACKUPDIR/$TARGET
    ls -lh $BACKUPDIR/$TARGET

fi
