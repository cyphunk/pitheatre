#!/bin/bash

echo "power savings setup"
echo "> hdmi off"
/opt/vc/bin/tvservice -o &
echo "> disable bt (requires reboot first time)"
# yes config can have multiple dtoverlay lines or several options on one line with comma-no-space seperation
grep -q "pi3-disable-bt" /boot/config.txt \
|| echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt
