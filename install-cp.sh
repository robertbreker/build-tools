#!/bin/bash

set -eux

if [ "$#" -ne 2 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 CPP_URL SYSTEMVM_URL"
        exit 1
fi

CPP_URL=$1
SYSTEMVM_URL=$2

yum -y upgrade
yum -y install ntp

wget -q "$CPP_URL"
CPP_URL_filename=${CPP_URL##*/}
tar zxf $CPP_URL_filename
CPP_URL_dirname=${CPP_URL_filename%.tar.gz}
cd $CPP_URL_dirname
./install.sh -m

./configure-vhdutil.sh
mv vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/
./configure-nfs.sh
./configure-mysql.sh

cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root
cloudstack-setup-management

/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u $SYSTEMVM_URL -h xenserver
