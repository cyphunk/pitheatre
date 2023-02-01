#!/usr/bin/env bash
# Based on https://github.com/dhruvvyas90/qemu-rpi-kernel
# Find qemu-rpi-kernel there as well

sudo qemu-system-arm -kernel ./qemu-rpi-kernel/kernel-qemu-4.4.13-jessie -cpu arm1176 -m 256 -M versatilepb -no-reboot -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw init=/bin/bash console=ttyAMA0" -net nic,model=rtl8139 -net user -redir tcp:22000::22 -cdrom /dev/mmcblk0 -nographic
