serverid=$1
token_id=`keystone token-get | grep "id" | head -1 | awk -F\| '{print $3}'`
compute_endpoint=`keystone  endpoint-get  --service compute | tail -2 | head -1 | awk -F\| '{print $3}' | tr -d ' '`
print ${compute_endpoint}

curl -i "${compute_endpoint}/servers/${serverid}/action" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d '{"CreateTemplate": {"root_only":false,"name": "RDS_template-1"}}'
#curl -i "${compute_endpoint}/servers/b30e72ba-a7f0-46ba-b885-3d03dafd9490/action" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d '{"CreateTemplate": {"root_only":"ROOT_ONLY","name": "template_based_instance_cuncurrent"}}'
#curl -i "${compute_endpoint}/servers/b30e72ba-a7f0-46ba-b885-3d03dafd9490/action" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d '{"CreateTemplate": {"root_only":"ROOT_ONLY","name": "template_based_instance_cuncurrent"}}'
#curl -i "${compute_endpoint}/servers/b30e72ba-a7f0-46ba-b885-3d03dafd9490/action" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token:${token_id}" -d '{"CreateTemplate": {"root_only":"ROOT_ONLY","name": "template_based_instance_cuncurrent"}}'
#for i in `nova list | grep "vnet-demo" | awk -F\| '{print $2}' | xargs`
#do
#    echo $i
#    curl -i "http://10.224.72.37:8774/v2/549aa9e1010546d0baff7bd8823a09b8/servers/${i}/snapshots" -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${token_id}" -d '{"snapshot": {"disk": "all", "name": "snapshot17", "metadata": {"key1": "value1"}}}'
#    break
#done 
