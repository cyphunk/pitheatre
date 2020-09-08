#!/usr/bin/env bash
test -z "$DEBUG" || set -x

# Check /boot/config.txt configured properly
# handle both conditions where the line just doesnt exist, or when it is commented
egrep 'dtparam=spi=on' /boot/config.txt || echo "dtparam=spi=on" >> /boot/config.txt
egrep '#dtparam=spi=on' /boot/config.txt && sed -i 's/#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt

# find /lib -name \*spi\* | grep `uname -r`
# RPi3:
SPI_MODULE="spi-bcm2835"


modprobe $SPI_MODULE # If that fails you may wanna try the older spi_bcm2708 module instead
modprobe spidev

echo "SPI: to run flashrom: flashrom -p linux_spi:dev=/dev/spidev0.0"

exit 0
