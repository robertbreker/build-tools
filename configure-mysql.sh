#!/bin/bash

set -eux

yum -y install mysql-server mysql
sed -i "s/\[mysqld\]/\[mysqld\]\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=350\nlog-bin=mysql-bin\nbinlog-format = \'ROW\'/g" /etc/my.cnf
chkconfig mysqld on
service mysqld restart
mysql -u root <<EOF
#UPDATE mysql.user SET Password=PASSWORD('cloud') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', 'localhost.localnet', '127.0.0.1', '::1');
DROP DATABASE test;
FLUSH PRIVILEGES;
EOF
setenforce Permissive
