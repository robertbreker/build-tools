#!/bin/bash
set -eux

if [ "$#" -ne 5 ]; then
    echo "Invalid parameters"
    echo "Usage: $0 vmuuid password script xenserver_host xenserver_password"
    exit 1
fi

. ./function.sh

VMUUID=$1
PASSWORD=$2
SCRIPT=$3
XENSERVER_HOST=$4
XENSERVER_PASSWORD=$5

ip=""
while [[ $ip == "" ]]; do
    sleep 1
    ip=$(xecommand vm-param-get uuid="$VMUUID" param-name=networks | sed -ne 's,^.*0/ip: \([0-9.]*\).*$,\1,p')
    if [[ $ip != "" ]]; then
        if [[ $(ping -c 1 "$ip" | grep bytes | wc -l) -le 1 ]]; then
            ip=""
        fi
    fi
done

tmpdir=$(sshcommand mktemp -d)
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -r ./ root@"$ip":"$tmpdir"
$basename=$(basename "$SCRIPT")
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@"$ip" "$tmpdir/$basename $CCP $SYSTEMVM" 
