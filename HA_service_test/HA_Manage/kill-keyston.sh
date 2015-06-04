
while [ 3 -ne 1 ]
do
    ps aux | grep keystone- | awk  '{print "kill -9 " $2}' | sh 2> /dev/null 
    echo "fdsfd"
done
