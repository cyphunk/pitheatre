#!/bin/bash
# This script attempts to download deb packages and their dependencies
# so that they can be installed on the RPi without internet. 
#
# See PACKAGES variable definition for specifying which packages 
# you want downloaded.
#
# They are downloaded to the sync directory which is optionally
# copied to the RPi SD card when creating an image with the included
# make_image.sh script

#DISTRO="stretch"
DISTRO="buster"
BASE="http://archive.raspbian.org/raspbian"
PACKAGE="${BASE}/dists/${DISTRO}/main/binary-armhf/Packages.xz"
PACKAGE_CONTRIB="${BASE}/dists/${DISTRO}/contrib/binary-armhf/Packages.xz"
PACKAGE_NONFREE="${BASE}/dists/${DISTRO}/non-free/binary-armhf/Packages.xz"
PACKAGE_RPI="${BASE}/dists/${DISTRO}/rpi/binary-armhf/Packages.xz"
IGNORE="libc6 base-files adduser lsb-base lsb-core passwd libaudit1 libaudit-common libpam0g debconf | debconf-2.0 libselinux1 libsemanage1 libsemanage-common libsepol1 libgcc1 gcc-4.9-base
ignore gcc-4.9-base libstdc++6 libsystemd-daemon0 libsystemd-login0 libburn4 zlib1g dpkg install-info libtinfo5 coreutils fonts-freefont python:any libc6-dev pkg-config libc-dev libthai0 libz-dev libdbus-glib-1-2 libsystemd0 libudev1 libjack-0.116 init-system-helpers kmod python2.7 python2.6 initscripts"


PACKAGES=""
# basics:
PACKAGES="$PACKAGES rsync tcpdump apt-file"
#PACKAGES="$PACKAGES mplayer2 python-serial"
# pulse audio
#PACKAGES="$PACKAGES pulseaudio"
#PACKAGES="$PACKAGES pulseaudio-module-bluetooth libbluetooth3 bluez"
#PACKAGES="$PACKAGES pulseaudio-utils libtdb1"
# OSC
PACKAGES="$PACKAGES python-liblo python-pyinotify"
# WEB
PACKAGES="$PACKAGES python-webpy"
# WIFI
PACKAGES="$PACKAGES hostapd"
PACKAGES="$PACKAGES dnsmasq"
# For OP1 sync
#PACKAGES="$PACKAGES ffmpeg" #ffmpeg not available as pkg in raspbian
#PACKAGES="$PACKAGES libav-tools" #avconv
# For X11
PACKAGES="$PACKAGES xserver-xorg x11-apps xterm fvwm"
# For playing media to FB or X11
PACKAGES="$PACKAGES mplayer ffmpeg vlc mencoder xawtv"
# For THKWT
PACKAGES="$PACKAGES cmake git screen python-serial python3-serial python3-webpy python-pip x11-apps stm32flash wiringpi git"


read -p "get new Packages.xz (main, contrib, nonfree, rpi)? y/[n] " YN
if [ "$YN" == "y" ] ; then
	rm Packages_${DISTRO}*.xz Packages_${DISTRO}*
	wget $PACKAGE -O Packages_${DISTRO}.xz
	wget $PACKAGE_CONTRIB -O Packages_${DISTRO}_contrib.xz
	wget $PACKAGE_NONFREE -O Packages_${DISTRO}_nonfree.xz
	wget $PACKAGE_RPI -O Packages_${DISTRO}_rpi.xz
  xz -d Packages_${DISTRO}.xz
  xz -d Packages_${DISTRO}_contrib.xz
  xz -d Packages_${DISTRO}_nonfree.xz
  xz -d Packages_${DISTRO}_rpi.xz
fi
[ ! -f Packages_${DISTRO} ] && echo "cant find Packages_${DISTRO} file" && exit
mkdir -p sync/home/pi/packages/$DISTRO
mv Packages_${DISTRO} sync/home/pi/packages/${DISTRO}/Packages
mv Packages_${DISTRO}_contrib sync/home/pi/packages/${DISTRO}/Packages_contrib
mv Packages_${DISTRO}_nonfree sync/home/pi/packages/${DISTRO}/Packages_nonfree
mv Packages_${DISTRO}_rpi sync/home/pi/packages/$DISTRO/Packages_rpi

PWD=$(pwd)
cd sync/home/pi/packages/$DISTRO

function downloadnamed () {
	p=$1
	depth=$2
	ALLY=$3

	# get indent based on depth
	# pad with spaces before echo:
	test "$depth" = "" && depth=0
	test "$depth" != "" && pad=`printf "%-10s" "$depth:"`
	echo "$IGNORE" | grep -q $p && echo "${pad}ignore $p" && return 1
	path=$(grep "Package: ${p}$" Packages* -A 50 | grep 'Filename:' | awk '{print $2}' | head -1)
	echo -e "\n${pad}### $p"
	DEPENDS=$(grep "Package: ${p}$" Packages* -A 50 | grep '^Depends:' | head -1 | sed 's/Depends: //' | sed -e 's/([^)]*)//g' -e 's/,//g')
	echo "${pad}deps:  $DEPENDS"
	if [ -f "$(basename "$path")" ]; then
		echo "${pad}have $path already"
		# avoid recersive loops at cost of failing to recover some dep trees?
		return 1
	else
		grep "Package: ${p}$" Packages* -A 50 | grep '^Description:' | head -1
		[ "$ALLY" == "1" ] && YN="y" || read -p "download \"$path\"? [y]/n/a (a=only sub) " YN
		[ "$YN" == "a" ] && ALLY=1

		if [ "$YN" != "n" ]; then
			 wget  --quiet $BASE/$path
		else
			echo "${pad}adding $p to ignore list:"
			IGNORE="$IGNORE $p"
			echo "${pad}IGNORE=\"$IGNORE\""
			return 1
		fi
	fi
	for dep in $DEPENDS; do
		downloadnamed $dep $(($depth+1)) $ALLY
	done
}

echo "DOWNLOADING PACKAGES:"
echo "$PACKAGES"
for p in $PACKAGES; do
	downloadnamed $p 0

	continue
	# doesn't work because some packages are grouped into one directory (ie pulseaudio)
	#path=$(grep "Filename:.*/${p}/" Packages | awk '{print $2}' | head -1)
	path=$(grep "Package: ${p}$" Packages -A 50 | grep 'Filename:' | awk '{print $2}' | head -1)
	echo -e "\n### $p"
	DEPENDS=$(grep "Package: ${p}$" Packages -A 50 | grep '^Depends:' | head -1)
	echo "$DEPENDS"
	if [ -f "$(basename "$path")" ]; then
		echo "have $path already"
	else
		read -p "download \"$path\"? [y]/n " YN
		[ "$YN" != "n" ] && wget  --quiet $BASE/$path
	fi

done
#ls -l
cd $PWD
# make backup copy of this script
cp $0 sync/home/pi/packages/.
