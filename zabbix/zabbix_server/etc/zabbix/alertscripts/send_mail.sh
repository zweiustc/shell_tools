#!/bin/bash

#echo "中文邮件内容" | mail -s "=?UTF-8?B?`echo 中文测试test|base64`?=" -r shenoubang@kingsoft.com smb_test_1@163.com
#mail -s "haha" -r shenoubang@kingsoft.com shenoubang@163.com^
#$1: the mail address of reciever
#$2: subject of mail
#$3: content of mail
#=?UTF-8?B?`echo $2|base64`?=: code the Chinese subject base64 to utf-8 so that can solve messy code
#(echo "$3" | mail -s "=?UTF-8?B?`echo $2|base64`?=" -r zabbix_monitor@baidu.com $1)&
#export LANG=en_US.UTF-8
log="/var/log/zabbix/zabbix_mail.log"
dt=`date | tr '\n' ' '`
object=`echo $1 | tr '\n' ' '`
subject="$2-[yz]"
content=`echo $3`
str=${dt}${object}${content}
echo $str >> $log
#date | tr -d '\n' >> $log; echo $1 | tr  '\n' ' ' >> $log; echo $3 >> $log
(curl -s -X POST -H "Content-Type: application/json" -d "{\"sendTo\":\"$1\", \"subject\":\"$subject\", \"msg\":\"`echo "$3" | sed ':a;N;s/\n/\\\\n/;ta'`\"}" http://10.161.0.76:8765/smss/open/sendMail)&
#eval "curl -X POST -H \"Content-Type: application/json\" -d '{\"sendTo\":\"$MOBILE_NUMBER\", \"subject\":\"$SUBJECT\", \"msg\":\"'`echo "$3"`'\"}' http://10.161.0.76:8765/smss/open/sendMail "
