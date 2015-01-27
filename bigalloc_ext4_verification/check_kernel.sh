#!/bin/sh
#read host
#echo "read success"
for a in `cat $1`
do
echo $a
echo "==============================begin===================="
sleep 1
echo "                          ====core==="
sshpass -p "SYSserverpasswd1999@baidu.com" ssh -o StrictHostKeyChecking=no $a "uname -r"
echo "success $a"
echo "==============================end======================"
done
