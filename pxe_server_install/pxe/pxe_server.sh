# zhangwei18@kingsoft.com
# install pxe server for physical host management

#!/bin/bash

source env_config

mkdir -p /var/www/html
mv yum.tar.gz /var/www/html
tar -xzvf /var/www/html/yum.tar.gz -C /var/www/html/
cp ../repos/yum-repo/openstack/kilo/rhel7/x86_64/boost* /var/www/html/centos/

mkdir -p /etc/yum.repos.d
rm -rf /etc/yum.repos.d/*.repo
cp -r yum.conf /etc/
cp -r localyum.repo /etc/yum.repos.d/
yum clean all

yum -y install createrepo
createrepo /var/www/html/centos/
yum clean all

service firewalld stop
systemctl disable firewalld
yum install -y net-tools iptables-services

yum install -y httpd
chkconfig httpd on
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sed -i '/Listen/d' /etc/httpd/conf/httpd.conf
echo 'Listen 8080'>>/etc/httpd/conf/httpd.conf
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
setenforce 0
service httpd restart

yum -y install dhcp
cp -f dhcpd.conf /etc/dhcp/dhcpd.conf
sed -i "s/PXE_SERVER_IP/${PXE_SERVER_IP}/g" /etc/dhcp/dhcpd.conf
sed -i "s/DHCP_SUBNET/${DHCP_SUBNET}/g" /etc/dhcp/dhcpd.conf
sed -i "s/DHCP_MASK/${DHCP_MASK}/g" /etc/dhcp/dhcpd.conf
sed -i "s/DHCP_GATEWAY/${DHCP_GATEWAY}/g" /etc/dhcp/dhcpd.conf
chkconfig dhcpd on
iptables -I INPUT -p udp --dport 67 -j ACCEPT
service dhcpd restart
netstat -tulnp | grep :67

yum -y install xinetd 
yum -y install tftp-server 
yum -y install tftp 
cp -f tftp /etc/xinetd.d/tftp
chkconfig xinetd on
iptables -I INPUT -p udp --dport 69 -j ACCEPT
yum -y install syslinux
mkdir -p /tftpboot/mount
mkdir /tftpboot/pxelinux.cfg
cp -f /usr/share/syslinux/pxelinux.0  /tftpboot/
mount -o loop -t iso9660 ${ISO_FILE} /tftpboot/mount
cp /tftpboot/mount/isolinux/initrd.img /tftpboot
cp /tftpboot/mount/isolinux/vmlinuz /tftpboot
cp default /tftpboot/pxelinux.cfg/default
sed -i "s/PXE_SERVER_IP/${PXE_SERVER_IP}/g" /tftpboot/pxelinux.cfg/default
mkdir -p /var/www/html/ksczq/centos7
cp -rf /tftpboot/mount/* /var/www/html/ksczq/centos7
cp -f ksczq.cfg /var/www/html/ksczq/
sed -i "s/KS_ROOT_PWD/${KS_ROOT_PWD}/g" /var/www/html/ksczq/ksczq.cfg
sed -i "s/PXE_SERVER_IP/${PXE_SERVER_IP}/g" /var/www/html/ksczq/ksczq.cfg
umount /tftpboot/mount
rm -rf /tftpboot/mount
service xinetd restart
netstat -tulnp | grep :69

yum -y install ntp
sed -i '/server/d' /etc/ntp.conf
echo 'server 127.127.1.0'>>/etc/ntp.conf
echo 'fudge 127.127.1.0 stratum 8'>>/etc/ntp.conf
iptables -I INPUT -p udp --dport 123 -j ACCEPT
chkconfig ntpd on
service ntpd restart
netstat -tulnp | grep :123

service iptables save
service iptables restart
service httpd restart
service dhcpd restart
service xinetd restart
service ntpd restart
