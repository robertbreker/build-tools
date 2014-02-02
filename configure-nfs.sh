#!/bin/bash

set -eux

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

# ToDo: this is a bit much
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
