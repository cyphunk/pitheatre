#!/bin/bash
# systemd calls rc.local very early
# so we added this to system d at end
# ./systemd/system/userstartup.service
# it is called as ROOT user


if test ! -e /etc/systemd/system/userstartup.service ; then 
cat <<EOF > /etc/systemd/system/userstartup.service
[Unit]
Description=~pi/startup.sh as root because systemd starts rc.local too early
ConditionPathExists=/home/pi/startup.sh
[Service]
Type=forking
ExecStart=/home/pi/startup.sh
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
# Log Output:
StandardOutput=syslog+console
StandardError=syslog+console
[Install]
WantedBy=multi-user.target
EOF
systemctl enable userstartup.service 
fi

touch /home/pi/startup.sh.worked

# Log to file and stdout
# cleanup old logfiles. keep first 10
ls -t startup_*.log | tail --lines=+10 | xargs rm
exec 2>&1 > >(tee -a -i $(dirname $(readlink -f $0))/startup_`date +%Y%m%d`.log)

# often used in my projects, a configuration.sh
if [ -e $(dirname $(readlink -f $0))/configuration.sh ]; then
  source $(dirname $(readlink -f $0))/configuration.sh
  echo "## startup.sh: Sourced configuration.sh"
else
  echo "## startup.sh: no configuration.sh"
fi

# later rasbian images do not start ssh unless /boot/ssh file exists
# we start manually
echo "## startup.sh: SSH"
/etc/init.d/ssh start &

# don't wait for network on boot
test -e /etc/systemd/system/dhcpcd.service.d/wait.conf \
  && rm /etc/systemd/system/dhcpcd.service.d/wait.conf

# just in case dhcp not working
echo "## startup.sh: 10.0.0.1"
ifconfig eth0:1 10.0.0.1 &
# ping something for 2 minutes so engineer can find the ip by networking sniffing
ping -c 60 -i 2 -w 2 10.0.0.2 &

# Wifi (set IP for static, else dhcp is assumed)
# NOTE: system dhcpcd calls wpa. debug: jounalctl -f -u dhcpcd; systemctl restart dhcpcd
# to disable that:
echo "## startup.sh: WIFI - Disable dhcpcd calling wpa_supplicatn"
grep -q  "nohook wpa_supplicant" /etc/dhcpcd.conf \
|| (echo "nohook wpa_supplicant" >> /etc/dhcpcd.conf && systemctl restart dhcpcd)
echo "## startup.sh: WIFI - start wifi_client.sh"
#IP="" CLIENT_SSID="<SSID>" CLIENT_PASSWORD="<PASSWORD>" /home/pi/snippits/wifi_client.sh &
#IP="" CLIENT_SSID="Bsein" CLIENT_PASSWORD=`cat /home/pi/wifipass` /home/pi/snippits/wifi_client.sh &
IP="" CLIENT_SSID="PengMi" CLIENT_PASSWORD="<PASSWORD>" /home/pi/snippits/wifi_client.sh &
#-D nl80211,wext

# Hotspot
#HOTSPOT_USENAT=1 HOTSPOT_SSID=Blau HOTSPOT_DEV=wlan0 bash /home/pi/snippits/wifi_hotspot.sh &
# Hotspot on second wlan
#HOTSPOT_USENAT=1 HOTSPOT_SSID=Blau HOTSPOT_DEV=wlan1 bash /home/pi/snippits/wifi_hotspot.sh &
# Debugging
#DEBUG=1 HOTSPOT_USENAT=1 HOTSPOT_SSID=Blau  HOTSPOT_DEV=wlan1 bash /home/pi/snippits/wifi_hotspot.sh &

### Following method can be used to claim a primary IP if other device not already claiming it
# echo "## startup.sh: Try To claim ${MAIN_IP}"
### regarldess if we get main, also take static secondary:
# ifconfig wlan0:1 ${MODEL_IP} #on PengMi
# (sleep 10; 
#   if ping -c 2 -w 2 ${MAIN_IP} ; then 
#     echo ${MAIN_IP} exists on network already; 
#   else 
#     echo claiming ${MAIN_IP} && ifconfig wlan0:2 ${MAIN_IP}; 
#   fi 
# ) &

# echo "## startup.sh : LEDS off"
bash /home/pi/snippits/leds_off.sh &

# echo "## startup.sh : ENABLE THINGS - power save"
# bash /home/pi/snippits/power_save.sh

# echo "## startup.sh: ENABLE THINGS - usb gadget serial (pi0)"
#bash /home/pi/snippits/pi0_gadget_serial.sh
# echo "userstartup: ENABLE THINGS - usb gadget ethernet (pi0)"
# bash /home/pi/snippits/pi0_gadget_ether.sh

#echo "## startup.sh: ENABLE THINGS - spi"
#bash /home/pi/snippits/spi.sh

# rasbian now auto enlarges partition. pull back down so we can create fat
# for op1sync
# on workstation:
# s resize2fs /dev/mmcblk0p2 3G
# or use gparted


#/home/pi/sync/sync.sh &

echo "## startup.sh: EXIT"

exit 0
