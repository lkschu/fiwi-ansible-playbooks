#!/bin/bash


# $3 to show actual free ram, $7 to show all available ram
RAMPERCENT=$(free -m | grep Mem: | awk '{print (( $3 / $2 * 100))}')
RAMLOAD=$(free -h | grep Mem: | awk '{print $3 "/" $2}')
RAMUSAGE="$RAMPERCENT%   ($RAMLOAD)"



# cpu %usage is always tricky
CPUUSAGE=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' <(grep 'cpu ' /proc/stat) <(sleep 0.5;grep 'cpu ' /proc/stat) )

CPUUSAGE=$[100-$(vmstat 1 2|tail -1|awk '{print $15}')]


#printf  "RAM: \t%s \nCPU: \t%s\n" "$RAMUSAGE" "$CPUUSAGE"
printf "%s\n" "$CPUUSAGE"
