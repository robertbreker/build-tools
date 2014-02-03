#!/bin/bash

set -eux

yum -y install git
cd /opt
git clone https://github.com/apache/cloudstack.git

cd cloudstack
cd packaging/centos63
wget http://repo1.maven.org/maven2/org/apache/axis2/mex/1.5.4/mex-1.5.4-impl.jar -O /root/.m2/repository/org/apache/axis2/mex/1.5.4/mex-1.5.4-impl.jar
wget http://repo1.maven.org/maven2/org/apache/axis2/axis2-mtompolicy/1.5.4/axis2-mtompolicy-1.5.4.jar -O /root/.m2/repository/org/apache/axis2/axis2-mtompolicy/1.5.4/axis2-mtompolicy-1.5.4.jar
wget http://repo1.maven.org/maven2/org/apache/ws/commons/axiom/axiom-dom/1.2.10/axiom-dom-1.2.10.jar -O /root/.m2/repository/org/apache/ws/commons/axiom/axiom-dom/1.2.10/axiom-dom-1.2.10.jar
wget http://mirrors.ibiblio.org/maven2/commons-lang/commons-lang/2.3/commons-lang-2.3.jar -O /root/.m2/repository/commons-lang/commons-lang/2.3/commons-lang-2.3.jar
wget http://mirrors.ibiblio.org/maven2/bouncycastle/bcprov-jdk14/140/bcprov-jdk14-140.jar -O /root/.m2/repository/bouncycastle/bcprov-jdk14/140/bcprov-jdk14-140.jar
./package.sh
mkdir -p ~/repo
cd ../..
cp dist/rpmbuild/RPMS/x86_64/*rpm ~/repo/
createrepo ~/repo
cat <<EOF >> /etc/yum.repos.d/cloudstack.repo
[apache-cloudstack]
name=Apache CloudStack
baseurl=file:///root/repo/
enabled=1
gpgcheck=0
EOF
yum -y install cloudstack-management
