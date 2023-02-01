mkfifo fifo.out fifo.in
sudo qemu-system-arm -M versatilepb -cpu arm1136-r2 -m 256 -nographic -no-reboot -kernel ./qemu-rpi-kernel/kernel-qemu-4.4.13-jessie -hda /dev/mmcblk0 -append "root=/dev/sda2 rw panic=1 PATH=/bin:/sbin console=ttyAMA0" -net nic,model=rtl8139 -net user -redir tcp:22000::22 -serial pipe:fifo  &

cat fifo.out


