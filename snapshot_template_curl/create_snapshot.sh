if [ $# -ne 2 ];then
    echo "params need server_id .snapshpt_name"
fi
server_id=$1
snapshot_name=$2
token_id=`keystone token-get | grep "id" | head -1 | awk -F\| '{print $3}'`
compute_endpoint=`keystone  endpoint-get  --service compute | tail -2 | head -1 | awk -F\| '{print $3}' | tr -d ' '`
echo $compute_endpoint
curl -i "${compute_endpoint}/servers/${server_id}/snapshots" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${token_id}" -d "{\"snapshot\": {\"disk\": \"all\", \"name\": \"${snapshot_name}\", \"metadata\": {\"key1\": \"value1\"}}}"
