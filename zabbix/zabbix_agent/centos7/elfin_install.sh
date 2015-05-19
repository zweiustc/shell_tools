#!/bin/bash

declare -a server_ip=""

rpm -i elfin-2.2.6-1.7.el7.centos.x86_64.rpm
sed -i "s/^Server=.*$/Server=${server_ip}/g" /usr/local/elfin/etc/elfin.conf
/etc/init.d/elfin restart
