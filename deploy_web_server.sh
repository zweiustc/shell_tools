#!/bin/bash
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
passwd wwwer
passwd htmler
chown -R wwwer.webftp /var/www
chown -R htmler.webftp /var/www/html
set -i "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf
setsebool allow_ftpd_full_access on
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 21 -j ACCEPT
modprobe ip_conntrack_ftp
#we may need to add configuration below in httpd.conf for centos7
#ServerName localhost

