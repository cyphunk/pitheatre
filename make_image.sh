#!/usr/bin/env bash
# Install/dd a raspberry pi os image to SD card
# copy ovdr files in sync
# optionally create /boot/ssh and wpa_supplicatn files
#
# You need to download a raspberry pi os image first


# sudo call integrity check: only root should be able to change script
l=($(ls -l `readlink -f $0`))
[ ${l[0]:2:1} != "-" ] && [ "${l[2]}" != "root" ] ||
[ ${l[0]:5:1} != "-" ] && [ "${l[3]}" != "root" ] ||
[ ${l[0]:8:1} != "-" ] && { echo -e "only root should be able to modify\n${l[@]}"; exit 1;}


OS=$(uname)

if [ $# -lt 2 ]; then
	echo "attached drives:"
	[ $OS == "Darwin" ] \
		&& diskutil list \
		|| (mount | grep -e sda -e mmcblk && ls /dev/sd* /dev/mmcblk* | sort)
	echo
	echo "downloaded images:"
	ls -t *.zip *.xz 2>/dev/null
	echo
	echo "usage: $0 <image.zip|xz> <rdiskpath>"
	exit
fi
zip="$1"
rdisk="$2"

sudo -v

read -p "dd $1 contents to $2 drive? ([y]/n) " YN
####
if [ "$YN" != "n" ]; then

	test -s "$zip" 							|| exit
	#test -b "$rdisk"		 				|| exit
	test -e "$rdisk" 						|| exit
	if [ $OS == "Darwin" ]; then
		diskutil unmountDisk "$rdisk"
	else
		sudo umount $rdisk
	fi
	unzip $1 || xz -k -d $1					|| exit
	image="$(ls -t *.img | head -1)"
	test -s "$image"		 				|| exit
	set +x
	read -p "dd over $image? (ctrl+c for no)"
	if [ $OS == "Darwin" ]; then
		BS="4m"
	else
		BS="4M"
	fi
	echo "send 'killall -USR1 dd' for progress"
	set -x
	sudo dd if="$image" of="$2" bs=$BS conv=fsync status=progress || exit
	rm -rf "$image"
	set +x
	echo "done dd'ing image"
fi
#####

rdiskpartroot=$(sudo fdisk -l $rdisk | tail -1 | awk '{print $1}' )
rdiskpartboot=$(sudo fdisk -l $rdisk | tail -2 | head -1 | awk '{print $1}' )
if [ $OS == "Linux" ]; then
	read -p "Prepare ${rdiskpartroot} with ~pi copy, our keys,etc? ([y]/n) " YN
	if [ "$YN" != "n" ]; then
    mkdir -p /mnt/root
		sudo mount ${rdiskpartroot} /mnt/root || exit

		cd sync

		test -f home/pi/.ssh/authorized_keys || (echo "didn't find authorized_keys in sync" && exit )
		/usr/bin/find .
		sudo rsync -rva ./ /mnt/root/

		sudo chown -R 1000:1000 /mnt/root/home/pi/.ssh
		sudo chmod 700 /mnt/root/home/pi/
		sudo chmod 700 /mnt/root/home/pi/.ssh
		sudo chmod 600 /mnt/root/home/pi/.ssh/authorized_keys

		sudo umount ${rdiskpartroot}
		echo "to double check:"
		echo "sudo mount ${rdiskpartroot} /mnt/root && ls -a /mnt/root/home/pi"
	fi

	echo "Prepare ${rdiskpartboot} with wpa_supplicant.conf,ssh start? (y/[n]) "
	read -p "Note: if you plan to use startup.sh from pitheater you should skip this " YNN
	if [ "$YNN" = "y" ]; then
    mkdir -p /mnt/boot
		read -p "Touch /boot/ssh on '$rdiskpartboot'? (y/[n]) " SSH
		if [ "$SSH" = "y" ]; then
      sudo mount ${rdiskpartboot} /mnt/boot \
      && sudo touch /mnt/boot/ssh && sudo umount /mnt/boot
    fi
		read -p "Setup wifi client at  /boot/wpa_supplicant.conf on '$rdiskpartboot'? (y/[n]) " WIFI
		if [ "$WIFI" = "y" ]; then
      read -p "Wifi ssid: " SSID
      read -p "Wifi password: " PASSWORD
      echo "Genrating config for SSID '$SSID' PASSWORD '$PASSWORD'"
      sudo mount ${rdiskpartboot} /mnt/boot
			sudo tee /mnt/boot/wpa_supplicant.conf <<EOM
country=BE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="$SSID"
    psk="$PASSWORD"
}
EOM
      sudo umount /mnt/boot
    fi


		echo "to double check:"
		echo "sudo mount ${rdiskpartboot} /mnt/boot && ls /mnt/boot"
	fi
fi
