#!/bin/bash

# OPTIONAL PASS
# $2: DB_PASS for database
# $3: ADMIN_PASS for user admin
# $4: NOVA_PASS for service nova
# $5: METADATA_PASS for service metadata
# $6: NEUTRON_PASS for service neutron
# $7: GLANCE_PASS for service glance

if [ $# -lt 1 ]
then
	echo "Usage: $0 NODES"
	echo
	echo "NODES contains controllers & computers, use ' to quote, like '10.38.250.141 yf-bce-host09.yf01.baidu.com'"
	exit
fi

[ -n "$2" ] && DB_PASS="$2" || DB_PASS=DB_PASS
[ -n "$3" ] && ADMIN_PASS="$3" || ADMIN_PASS=ADMIN_PASS
[ -n "$4" ] && NOVA_PASS="$4" || NOVA_PASS=NOVA_PASS
[ -n "$5" ] && METADATA_PASS="$5" || METADATA_PASS=METADATA_PASS
[ -n "$6" ] && NEUTRON_PASS="$6" || NEUTRON_PASS=NEUTRON_PASS
[ -n "$7" ] && GLANCE_PASS="$7" || GLANCE_PASS=GLANCE_PASS

MYIP=`ifconfig -a | grep "inet addr:10\." | head -1 | sed -e "s/.* addr:\([^ ]*\).*/\1/g"`

NODES_STR="$1"
CTRLIP="$MYIP"

# PREPARE DIRs
mkdir -p /home/epc/{logs,locks,src,images,mysql,run}

# COPY BASE SRC PKGS
cd /home/epc/src
wget http://m1-bce-42-102-24.m1/h/base.tar -O base.tar -o /dev/null
tar xvf base.tar

# PREPARE SOURCE FOR easy_install & pip
cat > ~/.pydistutils.cfg << EOF
[easy_install]
index-url = http://m1-bce-42-102-24.m1/pypi-for-havana/
EOF

mkdir -p ~/.pip

cat > ~/.pip/pip.conf << EOF
[global]
index-url = http://m1-bce-42-102-24.m1/pypi-for-havana/
EOF

# UPGRADE pip
#yum -y erase `rpm -qa | grep python | egrep -v "^rpm-python-|^python-pycurl-|^python-2|^python-libs-2|^python-iniparse-|^python-urlgrabber-"`
yum -y install python-setuptools python-pip
yum -y reinstall python-setuptools python-pip
easy_install -U pip
pip install -U -I distribute
pip install -U -I setuptools
pip install -U -I pip

yum -y install python-devel
yum -y install libxslt-devel # needed by keystone

# avoid GMP warnings
if [ ! -e /usr/local/lib/libgmp.so ]
then
	yum -y install gcc make
	wget -O gmp-5.1.3.tar.gz http://m1-bce-42-102-24.m1/h/gmp-5.1.3.tar.gz
	tar zxvf gmp-5.1.3.tar.gz
	cd gmp-5.1.3
	./configure && make install
	cd ..
	rm -rf gmp-5.1.3*
fi

# INSTALL MODULES
while read MODULE
do
	echo y | pip uninstall $MODULE
	rm -rf $MODULE
	tar zxf $MODULE.tar.gz
	pip install -U -I -e $MODULE

	if [ $? -ne 0 ]
	then
		echo "ERROR: $MODULE install failed"
		exit
	fi
done << EOF
keystone
nova
neutron
glance
python-novaclient
EOF

# INSTALL SCRIPTS & CONFS
cd /home/epc
wget http://m1-bce-42-102-24.m1/h/etc.tar -O etc.tar -o /dev/null
wget http://m1-bce-42-102-24.m1/h/bin.tar -O bin.tar -o /dev/null
wget http://m1-bce-42-102-24.m1/h/services.tar -O services.tar -o /dev/null
tar xvf etc.tar
tar xvf bin.tar
tar xvf services.tar
rm -f bin/start_comp.sh
rm -f etc.tar bin.tar services.tar

# INSTALL SERVICES
for SERVICE in `chkconfig --list | egrep "^keystone|^nova|^neutron|^glance|^cinder" | awk '{print $1}'`
do
	service $SERVICE stop
	chkconfig --del $SERVICE
	rm -rf /etc/init.d/$SERVICE
done

while read SERVICE
do
	rm -rf /etc/init.d/$SERVICE
	ln -s /home/epc/services/$SERVICE /etc/init.d/
	chkconfig --add $SERVICE
	chkconfig $SERVICE on
done << EOF
keystone-all
glance-api
glance-registry
nova-api
nova-scheduler
nova-conductor
neutron-server
EOF

# REPLACE VARS IN SCRIPTS & CONFS
find etc bin -type f | while read F
do
	sed -i "s/NODES_STR/$NODES_STR/g" "$F"
	sed -i "s/CTRLIP/$CTRLIP/g" "$F"

	sed -i "s/DB_PASS/$DB_PASS/g" "$F"
	sed -i "s/ADMIN_PASS/$ADMIN_PASS/g" "$F"
	sed -i "s/NOVA_PASS/$NOVA_PASS/g" "$F"
	sed -i "s/METADATA_PASS/$METADATA_PASS/g" "$F"
	sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" "$F"
	sed -i "s/GLANCE_PASS/$GLANCE_PASS/g" "$F"
done

# MAKE SYMBOL LINK OF CONF DIR
rm -rf /etc/nova ; ln -s /home/epc/etc/nova /etc/nova
rm -rf /etc/keystone ; ln -s /home/epc/etc/keystone /etc/keystone
rm -rf /etc/neutron ; ln -s /home/epc/etc/neutron /etc/neutron
rm -rf /etc/glance ; ln -s /home/epc/etc/glance /etc/glance

# PREPARE MYSQL
yum -y install mysql-server
service mysqld stop
chkconfig mysqld on
[ ! -f /etc/my.cnf.org ] && cp /etc/my.cnf /etc/my.cnf.org
rm -rf /etc/my.cnf ; ln -s /home/epc/etc/my.cnf /etc/my.cnf

yum -y install mysql-devel
pip install MySQL-python

# PREPARE qpid
yum -y install qpid-cpp-server
pip install qpid-python
[ ! -f /etc/qpidd.conf.org ] && cp /etc/qpidd.conf /etc/qpidd.conf.org
rm -rf /etc/qpidd.conf ; ln -s /home/epc/etc/qpidd.conf /etc/qpidd.conf
service qpidd restart
chkconfig qpidd on

# ADD epc.rc TO profile
[ -z "`grep /home/epc/etc/epc.rc /etc/profile`" ] && echo ". /home/epc/etc/epc.rc" >> /etc/profile

# FINISHING
cat << EOF
almost done
need to execute following in sequence:
	init_db.sh
	start_ctrl.sh
	create_flavor.sh
	import_image.sh
EOF
