#!/usr/bin/env bash
# turn off systemd naming and.
# Assign "wlan0" to specific mac addr or port location
# currently configured to assume "wlan0" as internal wlan
# and any usb attached card to be "wlan1"
#
# https://www.raspberrypi.org/forums/viewtopic.php?p=1240395&sid=72d90edf6478b3ce30cc87738dd04626#p1240395
#


function set_udev () {
  # turn off systemd style naming:
  ln -nfs /dev/null /etc/systemd/network/99-default.link
  # value echoed to 72-wlan.rules is defined below this function
  test ! -e /etc/udev/rules.d/72-wlan.rules && \
  \
  echo "$usbwlan1only" > /etc/udev/rules.d/72-wlan.rules \
  \
  && udevadm control --reload-rules && udevadm trigger --attr-match=subsystem=net
}


#
# Defined here are different methods to anchor names.

wlanbymac=$(cat <<EOM
# CHANGE THESE IF YOU USE MACADDR BASED
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="b8:27:eb:cd:f5:98", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="b8:27:eb:98:a0:cd", NAME="wlan1"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="60:e3:27:17:55:85", NAME="wlan0"
EOM
)

usbwlan1to4=$(cat <<EOM
# +---------------+
# | wlan1 | wlan2 |
# +-------+-------+
# | wlan3 | wlan4 |
# +---------------+ (RPI USB ports with position dependent device names for up to 4 optional wifi dongles)
# 
# | wlan0 | (onboard wifi)
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="sdio", KERNELS=="mmc1:0001:1", NAME="wlan0"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.2",       NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.3",       NAME="wlan2"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.4",       NAME="wlan3"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.5",       NAME="wlan4"
EOM
)

usbwlan1only=$(cat <<EOM
# +---------------+
# | wlan1 | wlan1 |
# +-------+-------+
# | wlan1 | wlan1 |
# +---------------+ (RPI USB ports with position independent device names for a maximum of 1 optional wifi dongle)
# 
# | wlan0 | (onboard wifi)
#
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="sdio", KERNELS=="mmc1:0001:1", NAME="wlan0"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.2",       NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.4",       NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.3",       NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="usb",  KERNELS=="1-1.5",       NAME="wlan1"
EOM
)

driverbased=$(cat <<EOM
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="brcmfmac", NAME="wlan0"
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="8192cu", NAME="wlan1"
EOM
)
#You can learn which driver your usb wifi is using by plugging it and learning it's name and driver:
# lsmod;  ifconfig; iwconfig; ip a l
#Once you know the interface name, examine it with udevadm:
# udevadm test /sys/class/net/wifi1
# udevadm info -a /sys/class/net/wlan0


set_udev

