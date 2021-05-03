#!/usr/bin/env bash
# Based on https://github.com/dhruvvyas90/qemu-rpi-kernel
# Find qemu-rpi-kernel there as well

test ! -e "$1" \
&& echo "usage: $0 <image.zip|.xz|.img>" \
&& exit 1

IMG="$1"

#######
# Download qemu kernels and ask user to choose correct one
#
test -e qemu-rpi-kernel \
&& (cd qemu-rpi-kernel && git pull) \
|| git clone https://github.com/dhruvvyas90/qemu-rpi-kernel

cat <<EOM
## Pick kernel that matches your Rasbian image type ##

kernel-qemu-4.*.*-buster    For Raspbian Buster and Stretch
                            Use versatile-pb-buster.dtb for Buster
                            Use versatile-pb.dtb for Stretch
kernel-qemu-4.*.*-stretch   For Raspbian Stretch and Jessie
                            Use versatile-pb.dtb
kernel-qemu-4.4.*-jessie    For Raspbian Jessie and Wheezy
kernel-qemu-3.10.25-wheezy  For Raspbian Wheezy only

EOM
select KERNEL in `cd qemu-rpi-kernel && ls -r kernel*`; do
  break
done

echo "## Pick DTB or none"
select DTB in "none" `cd qemu-rpi-kernel && ls -r *.dtb`; do
  break
done
test "$DTB" != "none" \
&& ARGDTB="-dtb ./qemu-rpi-kernel/$DTB"


#######
# Network and other startup options
#


cat <<EOM
## Choose startup options
# Use AUTOMATE first time to setup ssh on system
# Use NET_FORWARD thereafter

AUTOMATE      Use Fifo for i/o so script can login
              Script attempts to start ssh and resize disk
              localhost:2222 will forward to target ssh
FIFO          Just illustrates using fifo files for console
NET_FORWARD   localhost:2222 will forward to target ssh
NET_NOSCRIPT  tbd
NET_SCRIPT    attempts to setup local interface
              still requires login to configure target host ip
EOM
OPTFLAGS="-serial stdio"
select OPT in AUTOMATE FIFO NET_FORWARD NET_NOSCRIPT NET_SCRIPT none; do
  case $OPT in
    AUTOMATE)
      echo ">> Combing FIFO, NETFORWARD, to start SSH"
      test -e fifo.out || mkfifo fifo.out fifo.in
      OPTFLAGS="-serial pipe:fifo"
      OPTFLAGS="$OPTFLAGS -net nic -net user,hostfwd=tcp::2222-:22"
      # wait for `raspberrypi login:`
      waitforthensetup () {
        #cat fifo.out | tee -a .fifo.out.tmp &
        cat fifo.out > .fifo.out.tmp &
        echo "to monitor the output"
        echo "tail -f .fifo.out.tmp"
        CATPID=$!
        rm .foundlogin 2>/dev/null
        while [ 1 ]; do
          test -e .foundlogin && kill $CATPID && break
          echo -n "."
          echo "" > fifo.in && sleep 1
          # remove -q to debug
          grep -q "login:" .fifo.out.tmp \
            && echo "found login" \
            && touch .foundlogin \
            && echo "pi" > fifo.in \
            && sleep 2 \
            && echo "raspberry" > fifo.in \
            && sleep 20 \
            && echo "sudo systemctl start ssh; sudo systemctl enable ssh; sudo raspi-config --expand-rootfs" > fifo.in 
          sleep 5
        done
        echo "waiting for ssh to start on localhost:2222. could take time"
        while [ 1 ]; do 
          echo -n "+"
          nc localhost 2222 && break
          sleep 5
        done
      }
      ;;
    FIFO)
      echo ">> On local after boot: cat fifo.out, echo to fifo.in"
      test -e fifo.out || mkfifo fifo.out fifo.in
      OPTFLAGS="-serial pipe:fifo"
      ;;
    NET_FORWARD)
      echo ">> On target after boot: systemctl ssh start"
      OPTFLAGS="$OPTFLAGS -net nic -net user,hostfwd=tcp::2222-:22"
      ;;
    NET_NOSCRIPT) # this is the same as NET_SCRIPT done manually
      echo ">> On target after boot: dhclient -i eth0 || ifconfig eth0 192.168.100.2"
      tunctl -u user -t tap0
      ifconfig tap0 192.168.100.1
      OPTFLAGS="$OPTFLAGS -net nic -net tap,ifname=tap0,script=no"
      ;;
    NET_SCRIPT)
      echo ">> On target after boot: dhclient -i eth0 || ifconfig eth0 192.168.100.2"
      cat <<EOF | sed 's/^ *//' > /tmp/qemu-ifup
      #!/bin/sh
      echo "Bringing up $1 for tap mode..."
      tunctl -u user -t tap0
      ifconfig tap0 192.168.100.1
      sleep 2
EOF
      OPTFLAGS="$OPTFLAGS -net nic -net tap,ifname=tap0,script=/tmp/qemu-ifup"
      ;;    
    none|*)
      echo ">> login after boot, from this console"
      OPTFLAGS="-serial stdio"
      ;;
  esac
  break
done


#######
# Image file
#

echo "## Preparing image file"
# IMG arg was not a .img file, or
# IMG arg is zip and  
if [ "${IMG: -4}" = ".img" ] || [ -e "${IMG:: -4}.img" ]; then
  echo "Image file exists and ready"
  IMG="${IMG:: -4}.img"
else
  echo "Unzipping image file"
  	unzip $1 || xz -k -d $1
    IMG="${IMG:: -4}.img"
fi 

read -p "Should we add 500mb to image size? y/[n] " YNN
test "$YNN" = "y" \
&& ls -lh $IMG \
&& qemu-img resize $IMG +500M \
&& ls -lh $IMG \
&& echo ">> after first boot run on target: sudo raspi-config --expand-rootfs"
#&& truncate -s +500MB $IMG \

#######
# Start
#

cat <<EOM
## Starting ##
EOM
set -x
sudo qemu-system-arm \
  -kernel ./qemu-rpi-kernel/$KERNEL  \
  $ARGDTB \
  -cpu arm1176 \
  -m 256 \
  -M versatilepb \
  -no-reboot \
  $OPTFLAGS \
  -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
  -hda $IMG &
set +x

test "$OPT" = "AUTOMATE" \
&& echo "Waiting for login" \
&& waitforthensetup

# read -p "Remove .img? y/[n] " YN
# test "$YN" = "y" \
# && rm $IMG
echo "If you need to save space remove image manually with:"
echo "rm $IMG"