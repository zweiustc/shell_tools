#!/bin/bash

# 部署整个环境的脚本，在控制节点运行
# 部署的前提条件：控制节点能直接ssh计算节点，可以用ssh-copy-id的方式部署私钥，预先在同路径准备好list.comp list.comp+vip两个文件

# 相关文件
# passwds，存储随机密码，不存在时重新生成
# list.comp，每个计算节点一行
# list.comp+vip，每个计算节点和对应的虚拟网段一行，字段间用tab分隔

PASSWDFILE=passwds

./stopall.sh

if [ ! -f $PASSWDFILE ]
then
	echo "DB_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" > $PASSWDFILE
	echo "ADMIN_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" >> $PASSWDFILE
	echo "NOVA_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" >> $PASSWDFILE
	echo "METADATA_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" >> $PASSWDFILE
	echo "NEUTRON_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" >> $PASSWDFILE
	echo "GLANCE_PASS=`tr -dc A-Za-z0-9 < /dev/urandom | head -c20`" >> $PASSWDFILE
fi

DB_PASS=`grep ^DB_PASS= $PASSWDFILE | cut -f2- -d=`
ADMIN_PASS=`grep ^ADMIN_PASS= $PASSWDFILE | cut -f2- -d=`
NOVA_PASS=`grep ^NOVA_PASS= $PASSWDFILE | cut -f2- -d=`
METADATA_PASS=`grep ^METADATA_PASS= $PASSWDFILE | cut -f2- -d=`
NEUTRON_PASS=`grep ^NEUTRON_PASS= $PASSWDFILE | cut -f2- -d=`
GLANCE_PASS=`grep ^GLANCE_PASS= $PASSWDFILE | cut -f2- -d=`

SSH="ssh -n -o PasswordAuthentication=no -o StrictHostKeyChecking=no"

NODES="`hostname` `sed -e s/$/.baidu.com/g list.comp | xargs` cq01-bce-46-176-33.cq01.baidu.com"
MYIP=`ifconfig -a | grep "inet addr:10\." | sed -e "s/.*inet addr:\(10\.[^ ]*\).*/\1/g"`

wget http://m1-bce-42-102-24.m1/h/deploy_epc_ctrl.sh -O deploy_epc_ctrl.sh && bash -x deploy_epc_ctrl.sh "$NODES" "$DB_PASS" "$ADMIN_PASS" "$NOVA_PASS" "$METADATA_PASS" "$NEUTRON_PASS" "$GLANCE_PASS" && /home/epc/bin/init_db.sh && /home/epc/bin/start_ctrl.sh && sleep 30 && /home/epc/bin/create_flavor.sh && /home/epc/bin/import_image.sh

while read LINE
do
        HOST=`echo "$LINE" | cut -f1`
        VIP=`echo "$LINE" | cut -f2 | cut -f1-3 -d.`
        $SSH $HOST "/home/epc/bin/stopall.sh ; wget http://m1-bce-42-102-24.m1/h/deploy_epc_comp.sh -O deploy_epc_comp.sh ; bash -x deploy_epc_comp.sh $MYIP $VIP \"$DB_PASS\" \"$ADMIN_PASS\" \"$NOVA_PASS\" \"$METADATA_PASS\" \"$NEUTRON_PASS\" \"$GLANCE_PASS\"; /home/epc/bin/create_ovs.sh ; /home/epc/bin/start_comp.sh ; sleep 30 ; /home/epc/bin/add_me.sh"
done < list.comp+vip
