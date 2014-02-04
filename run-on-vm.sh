#!/bin/bash

set -eux

if [ "$#" -le 4 ]; then
    echo "Invalid parameters"
    echo "Usage: $0 VMUUID VMPASSWORD XENSERVER_HOST XENSERVER_USERNAME SCRIPT [PARAMETERS]"
    exit 1
fi

. ./functions.sh

VMUUID=$1
VMPASSWORD=$2
XENSERVER_HOST=$3
XENSERVER_PASSWORD=$4
SCRIPT=$5

XENSERVER_USERNAME="root"

# Make sure that the VM exists
xecommand vm-list uuid="$VMUUID" || exit 1

# Make sure that the VM is running
xecommand vm-start uuid="$VMUUID" || true

# Wait for SSH
ip=""
while [[ $ip == "" ]]; do
    sleep 1
    ip=$(xecommand vm-param-get uuid="$VMUUID" param-name=networks | sed -ne 's,^.*0/ip: \([0-9.]*\).*$,\1,p')
    if [[ $ip != "" ]]; then
        if [[ $(sshpass -p "$VMPASSWORD" ssh -o StrictHostKeyChecking=no root@"$ip" "echo ok") != "ok" ]]; then
            ip=""
        fi
    fi
done

# Copy over the scripts and execute
tmpdir=$(sshcommand mktemp -d)
sshpass -p "$VMPASSWORD" scp -o StrictHostKeyChecking=no -r ./ root@"$ip":"$tmpdir"
basename=$(basename "$SCRIPT")
sshpass -p "$VMPASSWORD" ssh -o StrictHostKeyChecking=no root@"$ip" "$tmpdir/$basename" "${@:6}"
