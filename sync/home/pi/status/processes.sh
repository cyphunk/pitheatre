#!/usr/bin/env bash
echo "# $0 (args: $*)"

# prefix all stderr with '#':
exec 2> >(sed 's/^/#error: /')

test "$1" = "" \
&& >&2 echo "error: $0 wasn't given process list"

declare -i PROCCOUNT=0
declare -i RUNNINGCOUNT=0
MASK=""
RUNNINGCOUNT=0
PS=$(env ps aux)
for proc in "$@"; do
    PROCCOUNT=$((PROCCOUNT+1))
    declare "PROCESS_${PROCCOUNT}"="$proc";

    RUNNING=$(echo "$PS" | grep -v grep | grep -v $0 | grep "$proc" | wc -l)
    declare "PROCESS_${PROCCOUNT}_RUNNING"=$RUNNING
    test "$RUNNING" -gt 0 \
    && { MASK="${MASK}1";
         RUNNINGCOUNT=$(($RUNNINGCOUNT+1)); } \
    || MASK="${MASK}0"
    echo "PROCESS_${PROCCOUNT}=\"$proc\""
    var="PROCESS_${PROCCOUNT}_RUNNING"
    echo "PROCESS_${PROCCOUNT}_RUNNING=${!var}"
done

cat <<EOM
PROCESS_TOTAL_CHECKED=$PROCCOUNT
PROCESS_TOTAL_RUNNING=$RUNNINGCOUNT
PROCESS_RUNNING_MASK=$MASK
# Documentation:
# PROCESS_1 = "search string for ps list"
# PROCESS_1_RUNNING = Number of entries/pids found 
# PROCESS_TOTAL_CHECKED = Number of processes looked for, len(arguments)
# PROCESS_TOTAL_RUNNING = Of total, how many were running
# PROCESS_RUNNING_MASK = mask is another way to indicate which processes were/were-not running
EOM
