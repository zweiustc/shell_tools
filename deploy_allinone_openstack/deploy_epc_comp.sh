#!/bin/bash

if [ $# -lt 2 ]
then
	echo "Usage: $0 CTRL-IP VMNET"
	echo
	echo "VMNET like '10.38.247', do not contain the 4th digit"
	exit
fi

CTRLIP="$1"
VMNET_STR="$2"

# OPTIONAL PASS
# $3: DB_PASS for database
# $4: ADMIN_PASS for user admin
# $5: NOVA_PASS for service nova
# $6: METADATA_PASS for service metadata
# $7: NEUTRON_PASS for service neutron
# $8: GLANCE_PASS for service glance

[ -n "$3" ] && DB_PASS="$3" || DB_PASS=DB_PASS
[ -n "$4" ] && ADMIN_PASS="$4" || ADMIN_PASS=ADMIN_PASS
[ -n "$5" ] && NOVA_PASS="$5" || NOVA_PASS=NOVA_PASS
[ -n "$6" ] && METADATA_PASS="$6" || METADATA_PASS=METADATA_PASS
[ -n "$7" ] && NEUTRON_PASS="$7" || NEUTRON_PASS=NEUTRON_PASS
[ -n "$8" ] && GLANCE_PASS="$8" || GLANCE_PASS=GLANCE_PASS

# PREPARE DIRs
mkdir -p /home/epc/{instances,logs,locks,src,run}

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

yum -y install python-devel # needed by nova
yum -y install libxslt-devel # needed by keystone

# INSTALL latest gmp TO avoid GMP warnings
if [ ! -e /usr/local/lib/libgmp.so ]
then
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
	pip install -e $MODULE

	if [ $? -ne 0 ]
	then
		echo "ERROR: $MODULE install failed"
		exit
	fi
done << EOF
nova
neutron
python-novaclient
EOF
#python-keystoneclient
#python-neutronclient
#python-glanceclient
#python-swiftclient

#pip install -U -I pbr jinja2

yum -y install python-qpid

# INSTALL SCRIPTS & CONFS
cd /home/epc
wget http://m1-bce-42-102-24.m1/h/etc.tar -O etc.tar -o /dev/null
wget http://m1-bce-42-102-24.m1/h/bin.tar -O bin.tar -o /dev/null
wget http://m1-bce-42-102-24.m1/h/services.tar -O services.tar -o /dev/null
tar xvf etc.tar
tar xvf bin.tar
tar xvf services.tar
rm -f bin/start_ctrl.sh
rm -f etc.tar bin.tar services.tar

# INSTALL SERVICES
for SERVICE in `chkconfig --list | egrep "^keystone|^nova|^neutron|^glance|^cinder"`
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
neutron-openvswitch-agent
neutron-dhcp-agent
neutron-metadata-agent
nova-compute
EOF

# REPLACE VARS IN SCRIPTS & CONFS
find etc bin -type f | while read F
do
	sed -i "s/VMNET_STR/$VMNET_STR/g" "$F"
	sed -i "s/CTRLIP/$CTRLIP/g" "$F"

	sed -i "s/DB_PASS/$DB_PASS/g" "$F"
	sed -i "s/ADMIN_PASS/$ADMIN_PASS/g" "$F"
	sed -i "s/NOVA_PASS/$NOVA_PASS/g" "$F"
	sed -i "s/METADATA_PASS/$METADATA_PASS/g" "$F"
	sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" "$F"
	sed -i "s/GLANCE_PASS/$GLANCE_PASS/g" "$F"
done

# SET IDC
IDC=`hostname | cut -f1 -d-`
sed -i "s/^epc_idc=.*/epc_idc=$IDC/g" /home/epc/etc/nova/nova.conf

# MAKE SYMBOL LINK OF CONF DIR
rm -rf /etc/nova ; ln -s /home/epc/etc/nova /etc/nova
rm -rf /etc/neutron ; ln -s /home/epc/etc/neutron /etc/neutron

# INSTALL openvswitch

if [ -z "`rpm -qa | grep openvswitch`" ]
then
	wget http://m1-bce-42-102-24.m1/h/openvswitch-1.11.0-1.x86_64.rpm
	wget http://m1-bce-42-102-24.m1/h/kmod-openvswitch-1.11.0-1.el6.x86_64.rpm
	rpm -i openvswitch-1.11.0-1.x86_64.rpm kmod-openvswitch-1.11.0-1.el6.x86_64.rpm
	rm -f openvswitch-1.11.0-1.x86_64.rpm kmod-openvswitch-1.11.0-1.el6.x86_64.rpm
	service openvswitch start
fi

# CONFIG BRIDGES
MYIP=`ifconfig -a | grep "inet addr:" | grep -v 127.0.0.1 | grep -v 192.168.122. | sed -e "s/.* addr:\([^ ]*\).*/\1/g"`

if [ -n "$MYIP" ]
then
	ovs-vsctl list-br | awk '{print "ovs-vsctl del-br "$1}' | sh
	ovs-vsctl add-br br-int
	ovs-vsctl add-br br-ex
	ovs-vsctl add-port br-ex eth1
	ifconfig eth1 0 up
	ifconfig br-ex $MYIP netmask 255.255.255.0 up
	ifconfig br-int up
	route add default gw `echo "$MYIP" | cut -f1-3 -d.`.1
fi

# INSTALL iproute

if [ -z "`rpm -qa | grep iproute-2.6.32-23.el6.netns.1.x86_64`" ]
then
	wget http://m1-bce-42-102-24.m1/h/iproute-2.6.32-23.el6.netns.1.x86_64.rpm
	rpm -iU iproute-2.6.32-23.el6.netns.1.x86_64.rpm
	rm -f iproute-2.6.32-23.el6.netns.1.x86_64.rpm
fi

# INSTALL libvirt

yum -y install libvirt libvirt-python libvirt-devel qemu-kvm libguestfs libguestfs-tools python-libguestfs tunctl dnsmasq dnsmasq-utils

# MODIFY qemu.conf
[ ! -f /etc/libvirt/qemu.conf.org ] && cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.org
rm -rf /etc/libvirt/qemu.conf ; ln -s /home/epc/etc/qemu.conf /etc/libvirt/qemu.conf

modprobe kvm-intel
service libvirtd restart

# ADD OVS SCRIPT
[ -z "`grep /home/epc/bin/create_ovs.sh /etc/rc.local`" ] && echo /home/epc/bin/create_ovs.sh >> /etc/rc.local

# ADD epc.rc TO profile
[ -z "`grep /home/epc/etc/epc.rc /etc/profile`" ] && echo ". /home/epc/etc/epc.rc" >> /etc/profile

# DISABLE requiretty for sudo
sed -i "s/.*Defaults *requiretty.*/#Defaults requiretty/g" /etc/sudoers

# FINISHING
cat << EOF
almost done
need to execute following in sequence:
	create_ovs.sh
	start_comp.sh
	add_me.sh
EOF
