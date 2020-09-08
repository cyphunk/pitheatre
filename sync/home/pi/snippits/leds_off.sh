#!/usr/bin/env bash
# wait 120 seconds and then turn off
echo "### leds_off.sh (every 120 seconds)"
# actually it appears somewhere else some other process may re-enable so lets put in a loop
# lord have mercy on us
while [ 1 ]; do
sleep 120
echo 0 > /sys/class/leds/led1/brightness
echo 0 > /sys/class/leds/led0/brightness
done