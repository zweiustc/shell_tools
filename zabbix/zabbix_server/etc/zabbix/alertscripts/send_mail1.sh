#!/bin/bash

#echo "中文邮件内容" | mail -s "=?UTF-8?B?`echo 中文测试test|base64`?=" -r shenoubang@kingsoft.com smb_test_1@163.com
#mail -s "haha" -r shenoubang@kingsoft.com shenoubang@163.com^
#$1: the mail address of reciever
#$2: subject of mail
#$3: content of mail
#=?UTF-8?B?`echo $2|base64`?=: code the Chinese subject base64 to utf-8 so that can solve messy code
#(echo "$3" | mail -s "=?UTF-8?B?`echo $2|base64`?=" -r zabbix_monitor@baidu.com $1)&
#export LANG=en_US.UTF-8
MOBILE_NUMBER=$1
SUBJECT=$2
MESSAGE_UTF8=$3 
echo "$3"
#(echo "$3" | mail -s "$2" -r ksc_cloudmonitor@kingsoft.com $1)&
(curl -X POST -H "Content-Type: application/json" -d "{\"sendTo\":\"$1\", \"subject\":\"$2\", \"msg\":\"$3\"}" http://10.161.0.76:8765/smss/open/sendMail)&
#eval "curl -X POST -H \"Content-Type: application/json\" -d '{\"sendTo\":\"$MOBILE_NUMBER\", \"subject\":\"$SUBJECT\", \"msg\":\"'`echo "$3"`'\"}' http://10.161.0.76:8765/smss/open/sendMail "
