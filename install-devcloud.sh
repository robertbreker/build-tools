#!/bin/bash

set -eux

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

./configure-nfs.sh
./configure-mysql.sh

cat >/etc/sysconfig/networking/devices/ifcfg-eth1 <<EOL
# Please read /usr/share/doc/initscripts-*/sysconfig.txt
# for the documentation of these parameters.
DEVICE=eth1
BOOTPROTO=none
NETMASK=255.255.255.0
TYPE=Ethernet
HWADDR=da:dd:8b:c1:24:9e
IPADDR=192.168.56.1
EOL

yum -y groupinstall "Development Tools"
yum -y install java-1.7.0-openjdk-devel genisoimage ws-commons-util MySQL-python tomcat6 createrepo
cd ~
wget http://apache.mirror.anlx.net/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz
cd /usr/local
tar zxf ~/apache-maven-3.1.1-bin.tar.gz
export PATH=/usr/local/apache-maven-3.1.1/bin/:$PATH
export JAVA_HOME=/usr/lib/jvm/jre-1.7.0-openjdk.x86_64/

yum -y install git
cd /opt
git clone https://github.com/apache/cloudstack.git -b 4.3
cd cloudstack

"$DIR"/configure-vhdutil.sh
mv vhd-util /opt/cloudstack/scripts/vm/hypervisor/xenserver/

yum -y install python-setuptools
mvn -P developer,systemvm clean install
mvn -P developer -pl developer,tools/devcloud -Ddeploydb
mvn -pl :cloud-client-ui jetty:run &

sleep 120

/opt/cloudstack/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u http://d21ifhcun6b1t2.cloudfront.net/templates/4.2/systemvmtemplate-2013-07-12-master-xen.vhd.bz2 -h xenserver -o "localhost" -r root

sed -i "s/nfs:\/\/192.168.56.10\/opt\/storage\//nfs:\/\/192.168.56.1\/external\//g" tools/devcloud/devcloud.cfg
rpm -i http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
yum -y install  python-requests mysql-connector-python python-devel
cd tools/marvin
python setup.py install
cd ../..
mvn -P developer -pl tools/devcloud -Ddeploysvr

echo 1 > /proc/sys/net/ipv4/ip_forward


