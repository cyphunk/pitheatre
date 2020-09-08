#!/usr/bin/env bash

# Setup the 4ich waveshar HDMI lcd
# https://www.waveshare.com/wiki/4inch_HDMI_LCD#Driver

if ! grep -q 'dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000,keep_vref_on=0,swapxy=0,pmax=255,xohms=150,xmin=200,xmax=3900,ymin=200,ymax=3900' /boot/config.txt ; then

cat >> /boot/config <<EOF
hdmi_group=2
hdmi_mode=87
hdmi_cvt 480 800 60 6 0 0 0
dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000,keep_vref_on=0,swapxy=0,pmax=255,xohms=150,xmin=200,xmax=3900,ymin=200,ymax=3900
display_rotate=3
EOF
touch $HOME/.lcd_4inchhdmi_setup_completed

# that should be enough

# wget http://www.waveshare.com/w/upload/4/4b/LCD-show-161112.tar.gz
#
#cd /boot/LCD-show/
#chmod +x LCD4-800x480-show
#./LCD4-800x480-show &
#touch /home/pi/.triedtosetuplcd

fi
