#!/bin/bash
source /etc/profile


/bin/chmod 755 /etc/rc.d/init.d/functions

. /etc/rc.d/init.d/functions


VIP=10.47.7.77

case "$1" in
start)
        echo " start LVS of REALServer"
        /sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up
        /sbin/route add -host $VIP dev lo:0

        echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
        echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
        echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
        echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce

        sysctl -p >/dev/null 2>&1
        echo " start LVS of REALServer [OK]"
;;
stop)
        /sbin/ifconfig lo:0 down

        echo "close LVS Directorserver"
        echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
        echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
        echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
        echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
        echo "close LVS Directorserver [OK]"
;;
*)

        echo "Usage: $0 {start|stop}"
        exit 1
esac

exit 0
