#!/bin/bash

declare -a db_ip="localhost"
declare -a db_name="zabbix"
declare -a db_user="zabbix"
declare -a db_pwd="ABC123"

yum -y install zlib zlib-devel glibc glibc-devel libxml2 libxml2-devel freetype freetype-devel gcc unixODBC-devel libssh2-devel OpenIPMI-devel openldap-devel
yum -y install mysql mysql-server php php-mysql mysql-devel php-xmlrpc  php-xml php-odbc php-gd php-bcmath  php-mbstring httpd
yum -y install net-snmp net-snmp-devel curl curl-devel perl-DBI

groupadd zabbix
useradd -g zabbix  zabbix

cp etc/zabbix/ /etc/ -r
cp sbin/* /usr/sbin/
cp init.d/zabbix_server /etc/init.d/
mkdir /var/log/zabbix/
touch /var/log/zabbix/zabbix_server.log
touch /var/log/zabbix/zabbix_mysql_partition.log
chmod a+wr /var/log/zabbix/zabbix_server.log
chmod a+wr /var/log/zabbix/zabbix_mysql_partition.log
chown zabbix.zabbix /var/log/zabbix/zabbix_server.log
cp frontends/php/ /var/www/html/zabbix -r
chown -R apache.apache /var/www/html/zabbix/

sed -i "s#DBHost=#DBHost=${db_ip}#g" /etc/zabbix/zabbix_server.conf
sed -i "s#DBName=#DBName=${db_name}#g" /etc/zabbix/zabbix_server.conf
sed -i "s#DBUser=#DBUser=${db_user}#g" /etc/zabbix/zabbix_server.conf
sed -i "s#DBPassword=#DBPassword=${db_pwd}#g" /etc/zabbix/zabbix_server.conf

mysql -u${db_user} -p${db_pwd} -h${db_ip} -e "create database ${db_name} character set utf8;"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/schema.sql
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/images.sql
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/data.sql
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} < database/mysql/auto-partition.sql
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "Alter table history_log drop primary key, add index (id), drop index history_log_2, add index history_log_2 (itemid, id);"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "Alter table history_text drop primary key, add index (id), drop index history_text_2, add index history_text_2 (itemid, id);"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'history', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'history_uint', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'history_log', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'history_text', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'history_str', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'trends', 1, 24, 7)"
mysql -u${db_user} -p${db_pwd} -h${db_ip} ${db_name} -e "CALL partition_maintenance('zabbix', 'trends_uint', 1, 24, 7)"

crontab ./crontab.conf

/etc/rc.d/init.d/httpd start
/etc/rc.d/init.d/mysqld start

chkconfig zabbix_server on
service zabbix_server start
