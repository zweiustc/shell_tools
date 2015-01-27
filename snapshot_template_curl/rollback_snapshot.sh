
if [ $# != 2 ]
then
    sh rollback_snapshot.sh vm_id snapsot_id 
    echo "exit"
    exit
fi
token_id=`keystone token-get | grep "id" | head -1 | awk -F\| '{print $3}'`
echo $token_id
compute_endpoint=`keystone  endpoint-get  --service compute | tail -2 | head -1 | awk -F\| '{print $3}' | tr -d ' '`
compute_endpoint=`echo $compute_endpoint | tr -d ' '`
echo $compute_endpoint
#server_id=`nova list | grep "instance-pywc80l5" | awk -F\| '{print $2}' | tr -d ' '`
#echo $server_id
url="$compute_endpoint/servers/$1/snapshots/$2/action"
echo $url
curl -i "$url" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d "{\"RollbackSnapshot\":null}"
