#!/bin/bash

set -eux

if [ "$#" -ne 2 ]; then
        echo "Invalid parameters"
        echo "Usage: $0 ccp systemvm"
        exit 1
fi

ccp=$1
systemvm=$2

vhd_util="http://download.cloud.com.s3.amazonaws.com/tools/vhd-util"

yum -y upgrade
yum -y install ntp

wget "$ccp"
ccp_filename=${ccp##*/}
tar zxf $ccp_filename
ccp_dirname=${ccp_filename%.tar.gz}
cd $ccp_dirname
./install.sh -m

wget -q "$vhd_util"
mv vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/

yum -y install mysql-server mysql
sed -i "s/\[mysqld\]/\[mysqld\]\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=350\nlog-bin=mysql-bin\nbinlog-format = \'ROW\'/g" /etc/my.cnf
chkconfig mysqld on
service mysqld restart
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('cloud') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', 'localhost.localnet', '127.0.0.1', '::1');
DROP DATABASE test;
FLUSH PRIVILEGES;
EOF
setenforce Permissive

yum -y install nfs-utils
chkconfig rpcbind on
mkdir -p /export/primary
mkdir -p /export/secondary
echo "/export  *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a
sed -i -e "/LOCKD_TCPPORT=32803/ s/# *//"\
       -e "/LOCKD_UDPPORT=32769/ s/# *//"\
       -e "/MOUNTD_PORT=892/ s/# *//"\
       -e "/RQUOTAD_PORT/ s/# *//"\
       -e "/STATD_PORT/ s/# *//"\
       -e "/STATD_OUTGOING_PORT/ s/# *//"\
       /etc/sysconfig/nfs

iptables -A INPUT -m state --state NEW -p udp --dport 111 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 111 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 32803 -j ACCEPT
iptables -A INPUT -m state --state NEW -p udp --dport 32769 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 892 -j ACCEPT
iptables -A INPUT -m state --state NEW -p udp --dport 892 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 875 -j ACCEPT
iptables -A INPUT -m state --state NEW -p udp --dport 875 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 662 -j ACCEPT
iptables -A INPUT -m state --state NEW -p udp --dport 662 -j ACCEPT
service iptables save

cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:cloud
cloudstack-setup-management

/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u $systemvm -h xenserver
