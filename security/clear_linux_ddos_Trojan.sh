# Linux DDoS Trojan hiding itself with an embedded rootkit
# we need to clear it with such a way
# first we use "top" and sort with CPU(shift+p) to find the
# process name and pid. The process name and pid are the
# two parameters.

if [ $# -ne 2 ];then
    echo "parameters: name pid"
    exit
fi

declare -a name=$1
declare -a pid_number=$2

sed -i "/gcc.sh/d" /etc/crontab
rm -f /etc/cron.hourly/gcc.sh ; chattr +i /etc/crontab

kill -STOP  ${pid_number}
find /etc -name '*${name}*' | xargs rm -f
rm -f /usr/bin/${name}
#ls -lt /usr/bin | head
pkill ${name}
rm -f /lib/libudev.so
# chattr +i make the ctrontab readonly, -i make it writable.
chattr -i /etc/crontab

