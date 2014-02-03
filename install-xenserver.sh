#!/bin/bash

set -eux

if [ "$#" -ne 3 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 XENSERVER_HOST XENSERVER_PASSWORD INSTALL_PASSWORD INSTALL_ISO"
        exit 1
fi

. ./functions.sh

XENSERVER_HOST=$1
XENSERVER_PASSWORD=$2
INSTALL_PASSWORD=$3
INSTALL_ISO=$4

NETWORK_NAME="internal-network"

networkuuid=$(xecommand network-list name-label="$NETWORK_NAME" --minimal)
if [[ "$networkuuid" == "" ]]; then
    networkuuid=$(xecommand network-create name-label="$NETWORK_NAME")
fi

git clone https://github.com/robertbreker/virtual-hypervisor.git -b minorbugfixes
cd virtual-hypervisor/scripts
./generate_answerfile.sh static -h HvmXenServer -i 192.168.56.10 -m 255.255.255.0 -p "$INSTALL_PASSWORD" > answerfile.xml
wget -q "$INSTALL_ISO" -O main.iso
./create_customxs_iso.sh main.iso customxs.iso answerfile.xml
sshpass -p "$XENSERVER_PASSWORD" ./xs_start_create_vm_with_cdrom.sh customxs.iso "$XENSERVER_HOST" "$NETWORK_NAME" xenserver
cd ../..
rm -rf virtual-hypervisor
