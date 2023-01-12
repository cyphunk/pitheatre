#!/bin/bash
PIVERSION=$( case `awk '/^Revision/ {print $3}'  /proc/cpuinfo` in
  #https://elinux.org/RPi_HardwareHistory
  a02082|a22082|a32082) echo "3B" ;;
  a020d3) echo "3B+" ;;
  9020e0) echo "3A+" ;;
  a03111|b03111|b03112|b03114|b03115|c03111|c03112|c03114|c03115|d03114|d03115) echo "4B" ;;
  902120) echo "Zero2W" ;;
  esac )
  
echo "power savings setup"

echo "> hdmi off"
/opt/vc/bin/tvservice -o &

echo "> disable bt (requires reboot first time)"
# yes config can have multiple dtoverlay lines or several options on one line with comma-no-space seperation
test "$PIVERSION" = "3B" && (
  grep -q "pi3-disable-bt" /boot/config.txt \
  || echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt )
test "$PIVERSION" = "4B" && (
  grep -q "disable-bt" /boot/config.txt \
  || echo "dtoverlay=disable-bt" >> /boot/config.txt )
sudo systemctl disable hciuart.service
sudo systemctl disable bluealsa.service
sudo systemctl disable bluetooth.service


echo "> disable wifi power management"
iwconfig wlan0 power off

# echo "> disable wifi entirely"
# test "$PIVERSION" = "3B" -o "$PIVERSION" = "3B+" -o "$PIVERSION" = "3A+"&& (
#   grep -q "pi3-disable-bt" /boot/config.txt \
#   || echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt )
