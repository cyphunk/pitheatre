#!/usr/bin/env bash
test -z "$DEBUG" || set -x

touch $HOME/.wifi_client_startup_begin

             IP=${IP}
             # If IP is blank we assume DHCP is used
    CLIENT_SSID=${CLIENT_SSID:-PengMi}
CLIENT_PASSWORD=${CLIENT_PASSWORD:-jahacuckoo}
#  CLIENT_DRIVER=${CLIENT_DRIVER:-"-D nl80211,wext"} # leave blank for RPi2, nl80211 for RPi3
  CLIENT_DRIVER=${CLIENT_DRIVER:-""} # leave blank for RPi2, nl80211 for RPi3


echo none > /sys/class/leds/led0/trigger
function blink () {
for ((i=0;i<9;i++)); do
    echo $(($i%2))>/sys/class/leds/led0/brightness; sleep 0.1
done
}
blink

killall wpa_supplicant
# For issues with wpa_supplicant being started by system without request
#grep -q "nohook wpa_supplicant" /etc/dhcpcd.conf \
#|| (echo "nohook wpa_supplicant" >> /etc/dhcpcd.conf && systemctl restart dhcpcd)
# check dhcpcd.conf, add either `denyinterfaces wlan0` which will 
# no longer send dhcp requests on the interface, or
# add `interface wlan0\nnohook wpa_supplicant` which will avoid calling
# wpa_sup on that interface
# TODO: Editing central files is ugly. Find a better way


cat <<EOF > /etc/wpa_supplicant/wpa_supplicant-client.conf
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
EOF
wpa_passphrase "$CLIENT_SSID" "$CLIENT_PASSWORD" >> /etc/wpa_supplicant/wpa_supplicant-client.conf || exit

ifconfig wlan0 down
ifconfig wlan0 up
# if main wpa-supplicatn.conf file does not have country the wlan0 will be soft off (rfkil list) so
rfkill unblock all
sleep 3
# try iwlist 10 times
for ((n=0;n<10;n++)); do test `iwlist wlan0 scan | wc -l` -gt 4 && break; sleep 0.2; done

sleep 1
wpa_supplicant -B -i wlan0 $CLIENT_DRIVER -c /etc/wpa_supplicant/wpa_supplicant-client.conf &

sleep 2
if [[ "x$IP" != "x" ]]; then
    ifconfig wlan0 $IP netmask 255.255.255.0 || exit
else
    echo "### wifi_client.sh: No IP set. Assume DHCP is in use? Process list:"
    /bin/ps aux | grep dhcp | grep -v grep
fi

echo "### wifi_client.sh: Wifi startup done"

rm $HOME/.wifi_client_startup_begin
touch $HOME/.wifi_client_startup_completed

for ((n=0;n<10;n++)); do blink; done
