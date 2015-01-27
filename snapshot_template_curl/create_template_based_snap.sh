#curl -i 'http://10.224.72.37:8774/v2/549aa9e1010546d0baff7bd8823a09b8/servers/df816e2a-deac-438d-8837-b60feb761f88/snapshots/fe47e8cc-3678-496c-9eaf-54bf0ea5a397/action' -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: 09c37cd2fc10483a8a080b92a29adb22" -d '{"CreateTemplate": {"name": "template1", "metadata": {"key": "value"}}}'
if [ $# -ne 3 ] ;then
    echo "need server_id ,snapshot_id,template_name"
    exit
fi
server_id=$1
snapshot_id=$2
template_name=$3
token_id=`keystone token-get | grep "id" | head -1 | awk -F\| '{print $3}'`
compute_endpoint=`keystone  endpoint-get  --service compute | tail -2 | head -1 | awk -F\| '{print $3}' | tr -d ' '`
echo $compute_endpoint

curl -i "${compute_endpoint}/servers/${server_id}/snapshots/${snapshot_id}/action" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d "{\"CreateTemplate\": {\"name\": \"${template_name}\", \"metadata\": {\"key\": \"value\"}}}"
#for i in `nova list | grep "vnet-demo" | awk -F\| '{print $2}' | xargs`
#do
#    echo $i
#    curl -i "http://10.224.72.37:8774/v2/549aa9e1010546d0baff7bd8823a09b8/servers/${i}/snapshots" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${token_id}" -d '{"snapshot": {"disk": "all", "name": "snapshot17", "metadata": {"key1": "value1"}}}'
#    break
#done 
