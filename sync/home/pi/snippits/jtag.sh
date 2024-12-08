#!/usr/bin/env bash
# script that sets pi up as a JTAG target
# see https://github.com/cyphunk/JTAGenum/issues/21

PIVERSION=$( case `awk '/^Revision/ {print $3}'  /proc/cpuinfo` in
  #https://elinux.org/RPi_HardwareHistory
  a02082|a22082|a32082) echo "3B" ;;
  a020d3) echo "3B+" ;;
  9020e0) echo "3A+" ;;
  a03111|b03111|b03112|b03114|b03115|c03111|c03112|c03114|c03115|d03114|d03115) echo "4B" ;;
  902120) echo "Zero2W" ;;
  esac )
  
echo "setup pi as jtag target"

# yes config can have multiple dtoverlay lines or several options on one line with comma-no-space seperation
grep -q "enable_jtag_gpio" /boot/config.txt \
|| echo "enable_jtag_gpio=1" >> /boot/config.txt

test "$PIVERSION" = "4B" && (
  grep -q "gpio=22-27=np" /boot/config.txt \
  || echo "gpio=22-27=np" >> /boot/config.txt )

echo "JTAG on ALT4 pins:"
echo "                       rTCK TDO   TCK"
echo " 5v 5v  g  8 10 12   g  16  18  g 22 24 26 28 30 32  g 36 38 40"
echo " 3v  3  5  7  9 11  13  15  3v 19 21 23 25 27 29 31 33 35 37  g"
echo "          TDI      TMS TRST                               TDI"
