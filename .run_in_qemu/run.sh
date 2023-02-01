#!/usr/bin/env bash
sudo qemu-system-arm     -kernel ./qemu-rpi-kernel/kernel-qemu-4.4.13-jessie  -cpu arm1176     -m 256     -M versatilepb     -no-reboot     -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw "  -net user -redir tcp:22000::22 -serial stdio -hda /dev/mmcblk0
sudo qemu-system-arm -M versatilepb -cpu arm1136-r2 -m 256 -nographic -no-reboot -kernel ./qemu-rpi-kernel/kernel-qemu-4.4.13-jessie -hda /dev/mmcblk0 -append "root=/dev/sda2 rw panic=1 PATH=/bin:/sbin console=ttyAMA0" -net nic,model=rtl8139 -net user -redir tcp:22000::22 -serial pipe:fifo 
