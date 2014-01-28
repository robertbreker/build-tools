#!/bin/bash
set -eux

if [ "$#" -ne 3 ]; then
    echo "Invalid parameters"
    echo "Usage: $0 vmuuid password script"
    exit 1
fi

VMUUID=$1
PASSWORD=$2
SCRIPT=$3

ip=""
while [[ $ip == "" ]]; do
    sleep 1
    ip=$(xe vm-param-get uuid="$VMUUID" param-name=networks | sed -ne 's,^.*0/ip: \([0-9.]*\).*$,\1,p')
    if [[ $ip != "" ]]; then
        if [[ $(ping -c 1 "$ip" | grep bytes | wc -l) -le 1 ]]; then
            ip=""
        fi
    fi
done

sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no $SCRIPT root@"$HOST":~/
$basename=$(basename "$SCRIPT")
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@"$HOST" "$basename $CCP $SYSTEMVM" 
