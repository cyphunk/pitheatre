#!/usr/bin/env bash
echo "# $0"

# prefix all stderr with '#':
exec 2> >(sed 's/^/#error: /')

# stop if a command is missing
err=0
for cmd in ifconfig iwconfig ; do
    command -v $cmd >/dev/null && continue || { >&2 echo "# $cmd command not found."; err=1; }
done
test $err -eq 1 && exit 1


ifconfig eth0 2>/dev/null | grep -q eth0 \
&& ETH0_ON=1 \
|| ETH0_ON=0

# some ifconfig's give 'inet x.x.x.x' others 'inet addr: x.x.x.x'
# so we get all the ip addrs, including those on wlan0:1 wlan0:2 etc
ETH0_IP=$(ip addr show dev eth0 2>/dev/null | grep 'inet ' | sed 's/.* inet \([0-9\.]*\).*/\1/' | xargs)

ifconfig wlan0 2>/dev/null  | grep -q wlan0 \
&& WLAN0_ON=1 \
|| WLAN0_ON=0

WLAN0_SSID=$(iwconfig wlan0 2>/dev/null | grep SSID: | sed 's/.*SSID:"\([^"]*\)".*/\1/')
WLAN0_IP=$(ip addr show dev wlan0 2>/dev/null  | grep 'inet ' | sed 's/.* inet \([0-9\.]*\).*/\1/' | xargs)

ROUTER=$(route -n | grep ^0.0.0.0 | awk '{print $2}')
ROUTER_PINGTIME=$(ping -n -W 1 -c 1 $ROUTER 2>/dev/null | grep "time=" | sed 's/.*time=\(.*\)/\1/')
test -n "$ROUTER_PINGTIME" \
&& ROUTER_REACHABLE=1 \
|| ROUTER_REACHABLE=0

cat <<EOM
NETWORK_ETH0_ON=${ETH0_ON}
NETWORK_ETH0_IP="${ETH0_IP}"
NETWORK_WLAN0_ON=${WLAN0_ON}
NETWORK_WLAN0_SSID="${WLAN0_SSID}"
NETWORK_WLAN0_IP="${WLAN0_IP}"
NETWORK_ROUTER=${ROUTER}
NETWORK_ROUTER_REACHABLE=${ROUTER_REACHABLE}
NETWORK_ROUTER_PINGTIME="${ROUTER_PINGTIME}"
EOM


#/sys/class/net/eth0/statistics/rx_bytes
#/sys/class/net/eth0/statistics/tx_bytes