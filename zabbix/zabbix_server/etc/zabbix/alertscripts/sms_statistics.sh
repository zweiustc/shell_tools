#!/bin/bash
#第一个参数为要查询的目标号码，后面跟着一个或者多个目标log文件
#例如： 统计文件 params.log.2014-12-29 params.log.2014-12-30 params.log.2014-12-31 params.log.2015-01-04 params.log
#		中号码13381369454发送情况
#
#    ./statistics.sh 13381369454 params.log.2014-12-29 params.log.2014-12-30 params.log.2014-12-31 params.log.2015-01-04 params.log
#       params.log.2014-12-29 send: 0 succ: 0 fail: 0
#       params.log.2014-12-30 send: 0 succ: 0 fail: 0
#       params.log.2014-12-31 send: 0 succ: 0 fail: 0
#		params.log.2015-01-04 send: 1 succ: 1 fail: 0
#		params.log send: 31 succ: 31 fail: 0
#		total : send 32  succ 32 faild 0





declare -a array
phone=$1
total=0;
error=0;
succ=0;
shift #移开第一个参数
i=0
while(($#!=0))
do
	array[$i]=$(grep -o $phone $1 |wc -l)
	total=$(($total+array[$i]))
	i=$(($i+1))
	array[$i]=$(grep  $phone $1 |egrep '<string xmlns=\\"http://tempuri.org/\\">[0-9]{0,18}</string>'|wc -l)
	succ=$(($succ+array[$i]))
	array[$i+1]=$((array[$i-1]-array[$i]))
	i=$(($i+1))
	error=$(($error+array[$i]))
	echo "$1 send: ${array[$i-2]} succ: ${array[$i-1]} fail: ${array[$i]}"
	i=$(($i+1))
	shift
done
echo "total : send $total  succ $succ faild $error"
