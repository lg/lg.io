#!/bin/sh

DEFAULT_INTERFACE=`/sbin/route get 0.0.0.0 2>/dev/null | awk '/interface: / {print $2}'`
TAP_INTERFACE=$1

bash -c "tshark -i $DEFAULT_INTERFACE -T fields -e data -l 'udp and dst port 27036' | script -q /dev/null xxd -r -p | nc -b $1 -u 10.8.0.1 27036 > /dev/null" &
echo $! > /var/run/openvpnup.pid
