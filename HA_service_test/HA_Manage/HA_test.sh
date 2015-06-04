#Test the openstack env to make sure every modules is ready
#author: zhangwei18
#!/bin/sh

imageid='31f8012c-7623-4b51-96e2-29efb020dd2f'
netid='9f07ae46-13e9-46b6-8e67-89b05c061a8a'
for((i=0;i<100;i++))
do
    #echo `date` ': keystone token-get' >> ha_test.log
    #keystone token-get >> ha_test.log
    #sleep 2
    vmname='zhangwei'$RANDOM
    echo "vm name: "$vmname

    cmd='keystone tenant-list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='keystone token-get'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='nova list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='glance image-list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='neutron net-list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='cinder list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    #cmd='nova get-vnc-console bd943494-a3e8-45ac-8ea5-dd26b453a1eb novnc'
    #echo `date` ': ' $cmd >> ha_test.log
    #$cmd >> ha_test.log
    #sleep 2
    #echo '      ' >>  ha_test.log

    cmd="cinder create --image-id $imageid --name $vmname 20"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 6
    echo '      ' >>  ha_test.log

    cmd='cinder list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 160
    echo '      ' >>  ha_test.log

    cmd='cinder list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 6
    echo '      ' >>  ha_test.log


    volumeid=`cinder list | grep $vmname | awk  '{print $2}'`

    cmd="nova boot --boot-volume $volumeid --flavor 2 --nic net-id=9f07ae46-13e9-46b6-8e67-89b05c061a8a $vmname"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 60
    echo '      ' >>  ha_test.log

    cmd='nova list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd="nova get-vnc-console $vmname novnc"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd="nova floating-ip-associate $vmname 10.160.60.104"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 2
    echo '      ' >>  ha_test.log

    cmd='nova list'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 10
    echo '      ' >>  ha_test.log

    cmd='ping -c 10 10.160.60.104'
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 10
    echo '      ' >>  ha_test.log

    cmd="nova delete $vmname"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 10
    echo '      ' >>  ha_test.log

    cmd="cinder delete $volumeid"
    echo `date` ': ' $cmd >> ha_test.log
    $cmd >> ha_test.log
    sleep 10
    echo '      ' >>  ha_test.log

    echo "-------------------------------------------------------"
    echo "----------                               --------------"
    echo "----------                               --------------"
    echo "----------    One round arrived the end  --------------"
    echo "----------                               --------------"
    echo "-------------------------------------------------------"
done
