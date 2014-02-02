#!/bin/bash

set -eux

if [ "$#" -ne 2 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 ccp systemvm"
        exit 1
fi

ccp=$1
systemvm=$2

yum -y upgrade
yum -y install ntp

wget -q "$ccp"
ccp_filename=${ccp##*/}
tar zxf $ccp_filename
ccp_dirname=${ccp_filename%.tar.gz}
cd $ccp_dirname
./install.sh -m

./configure-vhdutil.sh
mv vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/
./configure-nfs.sh
./configure-mysql.sh

cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:cloud
cloudstack-setup-management

/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u $systemvm -h xenserver
