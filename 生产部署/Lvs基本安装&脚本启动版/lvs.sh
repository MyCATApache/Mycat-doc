#!/bin/bash
source /etc/profile

VIP=10.47.7.77
RIP1=10.47.7.211
RIP2=10.47.7.212

bond_name='bond0'
key=8066

/bin/chmod 755 /etc/rc.d/init.d/functions

. /etc/rc.d/init.d/functions

logger $0 called with $1
case "$1" in
start)
        echo " start LVS of DirectorServer"

        echo "1" > /proc/sys/net/ipv4/ip_forward

        sysctl -p > /dev/null 2>&1

        /sbin/ifconfig ${bond_name}:${key} $VIP broadcast $VIP netmask 255.255.255.255 up
        /sbin/route add -host $VIP dev ${bond_name}:${key}

        #Clear IPVS table
        /sbin/ipvsadm -C
        #set LVS
        /sbin/ipvsadm -A -t $VIP:8066 -s wrr
        /sbin/ipvsadm -a -t $VIP:8066 -r $RIP1 -g
        /sbin/ipvsadm -a -t $VIP:8066 -r $RIP2 -g

        /sbin/ipvsadm -A -t $VIP:9066 -s wrr
        /sbin/ipvsadm -a -t $VIP:9066 -r $RIP1 -g
        /sbin/ipvsadm -a -t $VIP:9066 -r $RIP2 -g

        #Run LVS
        /sbin/ipvsadm

        echo " start LVS of DirectorServer [OK]"
        ;;
stop)
        echo "close LVS Directorserver"

        echo "0" > /proc/sys/net/ipv4/ip_forward

        /sbin/ipvsadm -C
        /sbin/ifconfig ${bond_name}:${key} down

        echo "close LVS Directorserver [OK]"
        ;;
status)
        isLoOn=`/sbin/ifconfig ${bond_name}:${key} | grep "${VIP}"`
        isRoOn=`/bin/netstat -rn | grep "${VIP}"`
        if [ "$isLoOn" == "" -a "$isRoOn" == "" ]; then
                echo "LVS-DR has to run yet."
        else
                echo "LVS-DR is running."
        fi
        exit 3
        ;;
*)

        echo "Usage: $0 {start|stop|status}"
        exit 1
esac

exit 0