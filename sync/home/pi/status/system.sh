#!/usr/bin/env bash
echo "# $0"

# prefix all stderr with '#':
exec 2> >(sed 's/^/#error: /')

# for useful stats to add see https://github.com/XavierBerger/RPi-Monitor/blob/develop/src/etc/rpimonitor/template

STATUSDIR=$(dirname $(readlink -f $0))

cd $STATUSDIR

read PARTITION SIZE USED AVAILMB USEPERC MOUNT <<<$(df -m .| tail -1)
# Convert MB to GB float notation
AVAILGB=$(awk "BEGIN {print $AVAILMB / 1000}")


test -e /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq \
&& CPUFREQUENCY=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq) \
&& CPUFREQUENCY=$(awk "BEGIN {print $CPUFREQUENCY / 1000}" )
test -e /sys/devices/virtual/thermal/thermal_zone0/temp \
&& CPUTEMP=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp) \
&& CPUTEMP=$(awk "BEGIN {print $CPUTEMP / 1000}" )
CPUVOLTAGE=$(vcgencmd measure_volts core)


# Get version of pitheatre
# instead of manual updates we use a git hash-object of certain files
# this can then be used by developer to figure out pitheatre git commit
# Note: git hash-object is not just sha1sum, it is:
function git-hash-objects () {
    for f in $@; do
        test -e $f && \
        (echo -ne "blob $(wc -c < $f)\0"; cat $f) | sha1sum | sed "s|-|$f|"
    done
}
cd .. # in ~pi directory
HASHES="$(git-hash-objects startup.sh snippits/wifi_client.sh status/ui/server.py)"
HASHESSHORT=$(echo "$HASHES" | sed 's/\(.......\)[^ ]*/\1/' )
HASHESSIGNATURE=$(echo "$HASHES" | sed 's/\(.......\)[^ ]*.*/\1/' |xargs)
# Turns:
#   4b0d9a1  startup.sh
#   396f781  snippits/wifi_client.sh
#   cdafaec  status/ui/server.py
# Into: 4b0d9a1 396f781 cdafaec
# Find commit based on hash:
# git log --date=short --pretty="format:%H %ad" --find-object=HASH

cat <<EOM
SYSTEM_DISK_USE_PERCENT=$USEPERC
SYSTEM_DISK_AVAILABLE=${AVAILGB}GB
SYSTEM_CPU_FREQUENCY=$CPUFREQUENCY
SYSTEM_CPU_VOLTAGE=$CPUVOLTAGE
SYSTEM_CPU_TEMPURATURE=$CPUTEMP
SYSTEM_PITHEATRE_SIGNATURE="$HASHESSIGNATURE"
EOM

# startup.sh increments STARTUP_COINT=N in this file
test -e startup_count \
&& cat startup_count | sed 's/^/SYSTEM_/' 


echo "$HASHESSHORT" | sed 's/^/# /'


#/sys/class/net/eth0/statistics/rx_bytes
#/sys/class/net/eth0/statistics/tx_bytes