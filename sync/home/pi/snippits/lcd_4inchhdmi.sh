#!/usr/bin/env bash

# Setup the 4inch waveshar HDMI lcd
# https://www.waveshare.com/wiki/4inch_HDMI_LCD#Driver
# Also tested with APKLVSR 3.5inch
# https://www.amazon.de/-/en/APKLVSR-Touch-Screen-Display-Monitor/dp/B0CWGR1M8M

if ! grep -q 'dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000,keep_vref_on=0,swapxy=0,pmax=255,xohms=150,xmin=200,xmax=3900,ymin=200,ymax=3900' /boot/config.txt ; then

cat >> /boot/config <<EOF
hdmi_group=2
hdmi_mode=87
hdmi_cvt 480 800 60 6 0 0 0
dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000,keep_vref_on=0,swapxy=0,pmax=255,xohms=150,xmin=200,xmax=3900,ymin=200,ymax=3900
display_rotate=3
EOF
touch $HOME/.lcd_4inchhdmi_setup_completed

# HDMI rotation:
#display_rotate=0 Normal
#display_rotate=1 90 degrees
#display_rotate=2 180 degrees
#NOTE: You can rotate both the image and touch interface 180º by entering lcd_rotate=2 instead
#display_rotate=3 270 degrees
#display_rotate=0x10000 horizontal flip
#display_rotate=0x20000 vertical flip

# Rotate 180 (for APKLVSR 3.5", not Waveshare 4")
#dtoverlay=waveshare35a,rotate=270,invertx=1,swapxy=1
# No rotation:
#dtoverlay=waveshare35a


# that should be enough

# wget http://www.waveshare.com/w/upload/4/4b/LCD-show-161112.tar.gz
#
# Test
#cd /boot/LCD-show/
#chmod +x LCD4-800x480-show
#./LCD4-800x480-show &
#touch /home/pi/.triedtosetuplcd

fi
