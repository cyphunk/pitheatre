#!/usr/bin/env bash
echo "# $0"
# Option: arg1=/dev/tty to monitor writes
#         arg2=Number of seconds to monitor for writes

# prefix all stderr with '#':
exec 2> >(sed 's/^/#error: /')

[ $# -gt 1 ] \
&& test -e $1 \
&& MONITOR_PORT=$1 \
&& MONITOR_SECONDS=$2

# TTY's we check
TTYS="ttyS0 ttyUSB0 ttyUSB1 ttyACM0 ttyACM1"

cd $(dirname $(readlink -f $0))

TTYSAVAILABLE=""
for TTY in $TTYS ; do
    test -e /dev/$TTY \
    && TTYSAVAILABLE="${TTYSAVAILABLE}$TTY "
done

DRIVER_DETAILS=""
for driver in `ls /proc/tty/driver/` ; do
    details=$(cat /proc/tty/driver/$driver |xargs)
    DRIVER_DETAILS="${DRIVER_DETAILS}$driver: $details. "
    # example output:
    #cat /proc/tty/driver/ttyAMA
    #serinfo:1.0 driver revision:
    #0: uart:PL011 rev2 mmio:0x3F201000 irq:83 tx:25895 rx:0 RTS|CTS|DTR
done

cat <<EOM
SERIAL_AVAILABLE="${TTYSAVAILABLE}"
#SERIAL_DRIVER_DETAILS="${DRIVER_DETAILS}"
EOM


PORT_ACTIVE=0
PORT_ACTIVITY_COUNT=0
if test -n "${MONITOR_PORT}" ; then
    # Get pid attached to device
    if command -v lsof > /dev/null ; then
        PORTPID=$(lsof -t ${MONITOR_PORT})
    else
        for pid in `ls /proc/ | egrep '[0-9]'`; do 
            test -e /proc/$pid/fd \
            && ls -l /proc/$pid/fd | grep -q ${MONITOR_PORT} \
            && PORTPID=$pid ; 
        done
        #e.g.: -p 658 -p 659 -p 692 -p 701 -p 702 -p 703
        # old way:
        #env ps aux | grep osc_server.py | grep -v grep | awk '{print "-p " $2}' |xargs)
    fi
    echo "# check activity on '${MONITOR_PORT}' for '${MONITOR_SECONDS}' seconds (strace pid '${MONITOR_PORT}' PID)"
    # Cant trace on port on rpi:
    #timeout 10 -o .${0}.strace strace -f -s 9999 -x -P $PORT -p $PORTPID
    # Can trace the write calls though:
    test -n "$PORTPID" \
    && PORT_ACTIVITY_RAW=$(
        timeout ${MONITOR_SECONDS} strace -q -x -e trace=write -f -p $PORTPID 2>&1 | tr -d \"
        )
    test -n "$PORT_ACTIVITY_RAW" \
    && PORT_ACTIVE=1 \
    || PORT_ACTIVE=0
    test -n "$PORT_ACTIVITY_RAW" \
    && PORT_ACTIVITY_COUNT=$(echo "$PORT_ACTIVITY_RAW" | wc -l) \
    || PORT_ACTIVITY_COUNT=0

    PORT_ACTIVITY_RAW_ONELINE=$(echo "$PORT_ACTIVITY_RAW" | xargs)

cat <<EOM
SERIAL_ACTIVE_CHECK_PORT=${MONITOR_PORT}
SERIAL_ACTIVE_CHECK_ACTIVITY_DETECTED=${PORT_ACTIVE}
SERIAL_ACTIVE_CHECK_ACTIVITY_WRITE_COUNT=${PORT_ACTIVITY_COUNT}
SERIAL_ACTIVE_CHECK_ACTIVITY_RAW="${PORT_ACTIVITY_RAW_ONELINE}"
EOM

fi


exit 0
