#!/usr/bin/env bash
test -z "$DEBUG" || set -x
# e.g.
# DEBUG=1 HOTSPOT_USENAT=1 HOTSPOT_DEV=wlan1 bash ~pi/snippits/wifi_hotspot.sh
touch $HOME/.wifi_hotspot_startup_begin
echo "### `basename $0`: begin"


        HOTSPOT_IP=${HOTSPOT_IP:-192.168.99.1} 
       HOTSPOT_DEV=${HOTSPOT_DEV:-wlan0}
      HOTSPOT_SSID=${HOTSPOT_SSID:-Blau}
   HOTSPOT_CHANNEL=${HOTSPOT_CHANNEL:-8}
  HOTSPOT_PASSWORD=${HOTSPOT_PASSWORD} # empty for no password
    # If NAT set to 1 = NAT hotspot clients
    # makes sense if have another upstream network
    HOTSPOT_USENAT=${HOTSPOT_USENAT:-0}
    # IPTABLE rule to force http requests to localhost
 HOTSPOT_FORCEHTTP=${HOTSPOT_FORCEHTTP:-0}
#   HOTSPOT_DRIVER=${HOTSPOT_DRIVER:-"-D nl80211,wext"} # leave blank for RPi2, nl80211 for RPi3
    HOTSPOT_DRIVER=${HOTSPOT_DRIVER:-""} 
    # leave blank for RPi2, nl80211 for RPi3


command -v hostapd || echo "### `basename $0`: missing hostapd"
command -v dnsmasq || echo "### `basename $0`: missing dnsmasq"
command -v hostapd || exit
command -v dnsmasq || exit

echo ""
cat <<EOM
### `basename $0` config:
       HOTSPOT_IP="${HOTSPOT_IP}"
      HOTSPOT_DEV="${HOTSPOT_DEV}"
     HOTSPOT_SSID="${HOTSPOT_SSID}"
   HOTSPOT_USENAT="${HOTSPOT_USENAT}"
  HOTSPOT_CHANNEL="${HOTSPOT_CHANNEL}"
 HOTSPOT_PASSWORD="${HOTSPOT_PASSWORD}"
HOTSPOT_FORCEHTTP="${HOTSPOT_FORCEHTTP}"
EOM

ip addr add ${HOTSPOT_IP}/24 dev ${HOTSPOT_DEV} 

# Intercept and server http address for
# connectivitycheck.gstatic.com 
# detectportal.firefox.com/success.txt
# captive.apple.com

#
# HOSTAPD
#
cat <<EOF > /etc/hostapd/hostapd.conf
interface=${HOTSPOT_DEV}
ssid=${HOTSPOT_SSID}
hw_mode=g
channel=${HOTSPOT_CHANNEL}
wmm_enabled=0
macaddr_acl=0
auth_algs=1
EOF
test "$HOTSPOT_PASSWORD" != "" \
&& cat <<EOF >> /etc/hostapd/hostapd.conf
wpa=1
wpa_passphrase=${HOTSPOT_PASSWORD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
wpa_ptk_rekey=600
EOF

ps ax | grep hostapd | grep -v grep
killall hostapd && sleep 1
test -e "/home/pi/`basename $0`_hostapd.log" && rm "/home/pi/`basename $0`_hostapd.log"
hostapd -B \
  -P /var/run/hostapd.pid \
  -f /home/pi/`basename $0`_hostapd.log \
  /etc/hostapd/hostapd.conf
# -d to add debug messages


#
# NAT?
#
shopt -s extglob
NETPREFIX=${HOTSPOT_IP/%.+([0-9])/} # all but last ip octect
if [ "$HOTSPOT_USENAT" = "1" ]; then
  sysctl -w net.ipv4.ip_forward=1
  iptables -A FORWARD -i ${HOTSPOT_DEV} -s ${NETPREFIX}.0/24 -m conntrack --ctstate NEW -j ACCEPT
  iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -t nat -A POSTROUTING  -j MASQUERADE
  # Force all HTTP to local server always
  # iptables -t nat -A PREROUTING -p tcp --sport 53 -j DNAT --to-destination 127.0.0.1:53
  # iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination ${MASTERHTTP}:80
fi
if [ "$HOTSPOT_FORCEHTTP" = "1" ]; then
  iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${HOTSPOT_IP}:80
fi



#
# DNSMASQ
#

# Disable system running of dnsmasq, we run it on our own
if grep -q 'ENABLED=1' /etc/default/dnsmasq  ; then
  sed -i -e "s/ENABLED=1/ENABLED=0/" /etc/default/dnsmasq
  systemctl disable dnsmasq
  systemctl stop dnsmasq
fi

ps ax | grep dnsmasq | grep -v grep
killall dnsmasq && sleep 1
test "$HOTSPOT_FORCEHTTP" = "1" && FORCE_DNS_PARAM=--address="/#/${HOTSPOT_IP}"

test -e "/home/pi/`basename $0`_dnsmasq.log" && rm "/home/pi/`basename $0`_dnsmasq.log"
dnsmasq \
--interface=${HOTSPOT_DEV} \
--dhcp-range=${NETPREFIX}.40,${NETPREFIX}.250,255.255.255.0,24h \
--dhcp-authoritative \
--no-ping  $FORCE_DNS_PARAM \
--log-queries \
--log-facility=/home/pi/`basename $0`_dnsmasq.log


#DNSMASQ_OPTS=
#sed -i -e "s/denyintefaces.*/denyinterfaces $APDEV/" -e 's/^static routers=/#static routers=/' /etc/dhcpcd.conf


echo "### `basename $0`: done"

rm $HOME/.wifi_hotspot_startup_begin
touch $HOME/.wifi_hotspot_startup_completed

test -z "$DEBUG" || tail -f /home/pi/`basename $0`_hostapd.log /home/pi/`basename $0`_dnsmasq.log
