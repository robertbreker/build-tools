#!/bin/bash

set -eux

if [ "$#" -ne 4 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 XENSERVER_HOST XENSERVER_PASSWORD INSTALL_PASSWORD INSTALL_REPOSITORY"
        exit 1
fi

XENSERVER_HOST="$1"
XENSERVER_PASSWORD="$2"
INSTALL_PASSWORD="$3"
INSTALL_REPOSITORY="$4"

XENSERVER_USERNAME="root"
vm_name="MyCentOs"
template_name="CentOS 6 (64-bit)"
kickstart_file="anaconda-ks.cfg"
bridge="xenbr0"

. ./functions.sh

vm_uuid=$(xecommand vm-install new-name-label="$vm_name" template="$template_name" --minimal)
vbd_uuid=$(xecommand vbd-list vm-uuid="$vm_uuid" --minimal)
vdi_uuid=$(xecommand vbd-param-get param-name=vdi-uuid uuid="$vbd_uuid" --minimal)
xecommand vdi-resize uuid="$vdi_uuid" disk-size=15GiB

old_pv_args=$(xecommand vm-param-get uuid="$vm_uuid" param-name=PV-args --minimal)
temp_kickstart_path=$(mktemp)
temp_kickstart_filename=$(basename "$temp_kickstart_path")
cp "$kickstart_file" "$temp_kickstart_path"
escaped_install_repository=$(echo "$INSTALL_REPOSITORY" | sed -e 's/[\/&]/\\&/g')
sed -i  -e "s/<install_repository>/$escaped_install_repository/g" \
        -e "s/<install_password>/$INSTALL_PASSWORD/g" \
        "$temp_kickstart_path"
sshpass -p "$XENSERVER_PASSWORD" scp -o StrictHostKeyChecking=no "$temp_kickstart_path" "$XENSERVER_USERNAME"@"$XENSERVER_HOST":/opt/xensource/www/
rm -f "$temp_kickstart_path"
new_pv_args="$old_pv_args ks=http://$XENSERVER_HOST/$temp_kickstart_filename"
xecommand vm-param-set uuid="$vm_uuid"\
    other-config:install-methods=http \
    other-config:install-repository="$INSTALL_REPOSITORY" \
    PV-args="$new_pv_args"
network_uuid=$(xecommand network-list bridge="$bridge" --minimal)
xecommand vif-create vm-uuid="$vm_uuid" network-uuid="$network_uuid" device="0"
xecommand vm-cd-add uuid="$vm_uuid" device=1 cd-name="xs-tools.iso"
xecommand vm-start vm="$vm_uuid"

while [[ "$vm_uuid" == $(xecommand vm-list uuid="$vm_uuid" power-state=running --minimal) ]]; do
    sleep 10 
done

sshcommand "rm /opt/xensource/www/$temp_kickstart_filename"
xecommand vm-cd-eject vm="$vm_uuid"

echo $vm_uuid
exit 0
