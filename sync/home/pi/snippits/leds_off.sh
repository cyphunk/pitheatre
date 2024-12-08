#!/usr/bin/env bash
# wait 120 seconds and then turn off
echo "### leds_off.sh (in 120 seconds)"
sleep 120
echo 0 > /sys/class/leds/led1/brightness
echo 0 > /sys/class/leds/led0/brightness
