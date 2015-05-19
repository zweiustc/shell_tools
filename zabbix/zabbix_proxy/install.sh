#!/bin/bash

declare -a db_ip="localhost"
declare -a db_name="zabbix_proxy"
declare -a db_user="zabbix"
declare -a db_pwd="ABC123"
#modified it with proxy ip
declare -a proxy_ip="192.168.18.18"

yum -y install zlib zlib-devel glibc glibc-devel libxml2 libxml2-devel freetype freetype-devel gcc unixODBC-devel libssh2-devel OpenIPMI-devel openldap-devel
yum -y install mysql mysql-server php php-mysql mysql-devel php-xmlrpc  php-xml php-odbc php-gd php-bcmath  php-mbstring httpd
yum -y install net-snmp net-snmp-devel curl curl-devel perl-DBI

groupadd zabbix
useradd -g zabbix  zabbix

cp etc/zabbix/ /etc/ -r
cp sbin/* /usr/sbin/
cp init.d/zabbix_proxy /etc/init.d/

mkdir /var/log/zabbix/
touch /var/log/zabbix/zabbix_proxy.log
touch /var/log/zabbix/zabbix_mysql_partition.log
chmod a+wr /var/log/zabbix/zabbix_proxy.log
chmod a+wr /var/log/zabbix/zabbix_mysql_partition.log
chown zabbix.zabbix /var/log/zabbix/zabbix_proxy.log

sed -i "s#Hostname=#Hostname=proxy-${proxy_ip}#g" /etc/zabbix/zabbix_proxy.conf
sed -i "s#DBHost=#DBHost=${db_ip}#g" /etc/zabbix/zabbix_proxy.conf
sed -i "s#DBName=#DBName=${db_name}#g" /etc/zabbix/zabbix_proxy.conf
sed -i "s#DBUser=#DBUser=${db_user}#g" /etc/zabbix/zabbix_proxy.conf
sed -i "s#DBPassword=#DBPassword=${db_pwd}#g" /etc/zabbix/zabbix_proxy.conf

mysql -uzabbix -pABC123 -e "create database ${db_name} character set utf8;"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/schema.sql
mysql -u${db_uer} -p${db_pwd} -h${db_ip} ${db_name} -e "Alter table proxy_history drop primary key, add index (id);"   
mysql -u${db_uer} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/auto-partition.sql
mysql -u${db_uer} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix_proxy', 'proxy_history', 2, 24, 2)"

crontab crontab.conf
chkconfig zabbix_proxy on
/etc/init.d/zabbix_proxy start

