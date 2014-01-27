#!/bin/bash

set -eux

if [ "$#" -ne 4 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 xenserver_host xenserver_password install_password install_repository"
        exit 1
fi

xenserver_host="$1"
xenserver_password="$2"
install_password="$3"
install_repository="$4"

function sshcommand() {
    sshpass -p "$xenserver_password" ssh -o StrictHostKeyChecking=no "$xenserver_username"@"$xenserver_host" "$@"
}

function xecommand() {
    sshcommand xe "$@"
}

xenserver_username="root"
vm_name="MyCentOs"
template_name="'CentOS 6 (64-bit)'"
kickstart_file="anaconda-ks.cfg"
bridge="xenbr0"

vm_uuid=$(xecommand vm-install new-name-label="$vm_name" template="$template_name" --minimal)
vbd_uuid=$(xecommand vbd-list vm-uuid="$vm_uuid" --minimal)
vdi_uuid=$(xecommand vbd-param-get param-name=vdi-uuid uuid="$vbd_uuid" --minimal)
xecommand vdi-resize uuid="$vdi_uuid" disk-size=15GiB

old_pv_args=$(xecommand vm-param-get uuid="$vm_uuid" param-name=PV-args --minimal)
temp_kickstart_path=$(mktemp)
temp_kickstart_filename=$(basename "$temp_kickstart_path")
cp "$kickstart_file" "$temp_kickstart_path"
escaped_install_repository=$(echo "$install_repository" | sed -e 's/[\/&]/\\&/g')
sed -i  -e "s/<install_repository>/$escaped_install_repository/g" \
        -e "s/<install_password>/$install_password/g" \
        "$temp_kickstart_path"
sshpass -p "$xenserver_password" scp -o StrictHostKeyChecking=no "$temp_kickstart_path" "$xenserver_username"@"$xenserver_host":/opt/xensource/www/
rm -f "$temp_kickstart_path"
new_pv_args="'$old_pv_args ks=http://$xenserver_host/$temp_kickstart_filename'"
xecommand vm-param-set uuid="$vm_uuid"\
    other-config:install-methods=http \
    other-config:install-repository="$install_repository" \
    PV-args="$new_pv_args"
network_uuid=$(xecommand network-list bridge="$bridge" --minimal)
xecommand vif-create vm-uuid="$vm_uuid" network-uuid="$network_uuid" device="0"
xecommand vm-cd-add uuid="$vm_uuid" device=1 cd-name="xs-tools.iso"
xecommand vm-start vm="$vm_uuid"

while [[ "$vm_uuid" == $(xecommand vm-list uuid="$vm_uuid" power-state=running --minimal) ]]; do
    sleep 3
done

sshcommand "rm /opt/xensource/www/$temp_kickstart_filename"
xecommand vm-cd-eject vm="$vm_uuid"

echo $vm_uuid
exit 0
