#!/bin/bash

#check the input parameter
#if [ $# != 1 ]
#then
#    echo "input the mysql server ip, exit"
#    exit
#fi
########configure of cds
EVM_CLIENT="/home/bcc/bin/evm-client"

zksvr='10.224.69.42:2181'
zkpath='/bec/new-sandbox/master'
timeout=6000000

#global var for function return value
g_volume_id=0
g_device_name=''

droot_debug=true
function debug() {
    if [ x"$droot_debug" == 'xtrue' ] ; then
        echo $1
    fi
}


#######configure of database
HOSTNAME="hostname"
MYSQL_SERVER="10.99.20.40"
PORT=""
USERNAME="root"
DBNAME="nova"
TABLE_INSTANCES="instances"
TABLE_INSTANCE_METADATA="instance_metadata"
INSTANCE_PATH="/home/bcc/instances/"

#get the instance of the current compute node
read_instances_sql="select uuid from $TABLE_INSTANCES where node='`$HOSTNAME`' and deleted=0"
uuids=`mysql -u $USERNAME $DBNAME -h $MYSQL_SERVER -e "$read_instances_sql" | tail -n +2`
echo $uuids

######function of attach and mount cds
function create_volume() {
    size=$1
    debug "volume size:$size"

    result=`$EVM_CLIENT create $size --token=aaa --zkpath=$zkpath --zkserver=$zksvr --timeout=$timeout 2>&1`

    if [ $? != 0 ]; then
        echo 'OOps. EBS volume Create failed'
        exit -1
    fi

    g_volume_id=`echo $result | grep CINDER_TEXT | awk -F':' '{print $NF}'`
    echo "volume_id:$g_volume_id"
}

function attach() {
    iqn_prefix='iqn.droot_volume'
    volume_id=$1
    backing_store="${volume_id}:fake_user_id:fake_vol_id"
    #my_ip=`ifconfig | grep 'inet addr' | grep -v '127.0.0.1' | awk -F' ' '{print $2}' | awk -F':' '{print $2}'`
    my_ip='127.0.0.1'
    #my_ip=`hostname -i`

    TID=0
    target_num=`tgt-admin -s | grep 'Target' | wc -l`
    let TID="${target_num}+1"
    debug "current target count: "$TID

    VOLUME_ID=$volume_id
    target_name=${iqn_prefix}.${VOLUME_ID}

    /home/bcc/tgtd/sbin/tgtadm --lld iscsi --op new --mode target --tid ${TID} -T ${target_name}
    /home/bcc/tgtd/sbin/tgtadm --lld iscsi --op new --mode logicalunit --tid ${TID} --lun 1 --bstype bec_ebs --backing-store ${backing_store}
    /home/bcc/tgtd/sbin/tgtadm --lld iscsi --op bind --mode target --tid ${TID} -I ALL

}

function mount_volume() {
    mountpoint=$1
    device=$2

    mount -t ext4 $device $mountpoint
}


######get cds device infomation of every instance
for uuid in $uuids
do
    read_metadata_sql="select value from $TABLE_INSTANCE_METADATA where instance_uuid='$uuid' and \`key\`='volume_id'"
    volumn_id=`mysql -u $USERNAME $DBNAME -h $MYSQL_SERVER -e "$read_metadata_sql" | tail -n +2`
    if [ ! $volumn_id ]; then
        continue
    fi
    echo $uuid

    #create_volume $1
    echo "attach volumn_id  $volumn_id"
    attach $volumn_id
done
