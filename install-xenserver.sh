#!/bin/bash

set -eux

if [ "$#" -le 3 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 XENSERVER_HOST XENSERVER_PASSWORD INSTALL_PASSWORD INSTALL_ISO"
        exit 1
fi

. ./functions.sh

XENSERVER_HOST=$1
XENSERVER_PASSWORD=$2
INSTALL_PASSWORD=$3
INSTALL_ISO=$4

VM_NAME="xenservervm"
NETWORK_NAME="internal-network"

NETWORK_UUID=$(./configure-internal-network.sh)

fetch_git_repo https://github.com/robertbreker/virtual-hypervisor.git -b minorbugfixes

cd virtual-hypervisor/scripts
./generate_answerfile.sh static -h "$VM_NAME" -i 192.168.56.10 -m 255.255.255.0 -g 192.168.56.1 -p "$INSTALL_PASSWORD" > answerfile.xml
wget -q "$INSTALL_ISO" -O main.iso
./create_customxs_iso.sh main.iso customxs.iso answerfile.xml
sshpass -p "$XENSERVER_PASSWORD" ./xs_start_create_vm_with_cdrom.sh customxs.iso "$XENSERVER_HOST" "$NETWORK_NAME" "$VM_NAME"
cd ../..
rm -rf virtual-hypervisor
xecommand vm-list name-label="$VM_NAME" --minimal
exit 0
