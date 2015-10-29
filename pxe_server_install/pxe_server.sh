# zhangwei18@kingsoft.com
# install pxe server for physical host management

#!/bin/bash

if [ $# -ne 2 ];then
    echo "parameters: webserver_ip, iso_file"
    exit
fi
declare -a server_ip=$1
declare -a iso_file=$2

umount /tftpboot/mount
yum install -y httpd vsftpd mysql mysql-server php php-mysql
chkconfig httpd on
chkconfig vsftpd on
chkconfig mysqld on
service httpd on
service vsftpd on
service mysqld on
groupadd webftp
useradd -g webftp -M -d /var/www -s /sbin/nologin wwwer
useradd -g webftp -M -d /var/www/html -s /sbin/nologin htmler
chown -R wwwer.webftp /var/www
chown -R htmler.webftp /var/www/html
set -i "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf
setsebool allow_ftpd_full_access on
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 21 -j ACCEPT
modprobe ip_conntrack_ftp

yum -y install dhcp
cp -f dhcpd.conf /etc/dhcp/dhcpd.conf
sed -i "s#10.160.60.5#${server_ip}#g" /etc/dhcp/dhcpd.conf
chkconfig dhcpd on
service dhcpd restart
netstat -tulnp | grep :67

yum -y install xinetd 
yum -y install tftp-server 
yum -y install tftp 
cp -f tftp /etc/xinetd.d/tftp
chkconfig xinetd on
netstat -tulnp | grep :69

yum -y install syslinux
mkdir -p /tftpboot/mount
mkdir /tftpboot/pxelinux.cfg
cp -f /usr/share/syslinux/pxelinux.0  /tftpboot/
mount -o loop -t iso9660 ${iso_file} /tftpboot/mount
cp /tftpboot/mount/isolinux/initrd.img /tftpboot
cp /tftpboot/mount/isolinux/vmlinuz /tftpboot
cp default /tftpboot/pxelinux.cfg/default
sed -i "s#10.160.60.5#${server_ip}#g" /tftpboot/pxelinux.cfg/default
service xinetd restart

mkdir -p /var/www/html/ksczq/centos7
cp -rf /tftpboot/mount/* /var/www/html/ksczq/centos7
cp -f ksczq.cfg /var/www/html/ksczq/
umount /tftpboot/mount
rm -rf /tftpboot/mount
sed -i "s#10.160.60.5#${server_ip}#g" /var/www/html/ksczq/ksczq.cfg

service httpd restart
