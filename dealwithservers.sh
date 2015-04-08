#!/bin/bash

if [ $# -lt 2 ]
then
	echo "Usage: $0 server-list-file action"
	exit 1
fi

SSH="ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=3 -n"

getlatestversion() {
	if [ $# -lt 1 ]
	then
		echo ERROR
		return
	fi

	VER=`curl http://cq01-bec-backend.epc/pypi-for-icehouse/$1/ 2> /dev/null | tail -1 | cut -f2 -d\> | cut -f1 -d\< | sed -e "s/.tar.gz$//g" | sed -e "s/^$1-//g"`

	if [ -n "$VER" ]
	then
		echo $VER
	else
		echo NONE
	fi
}

checkversion() {
	# $1 = component name
	# $2 = pip freeze output

	if [ $# -lt 2 ]
	then
		return
	fi

	LATESTVER=`getlatestversion $1`
	REMOTEVER=`echo "$2" | grep ^$1== | cut -f3- -d=`
                        
	if [ "$LATESTVER" != "$REMOTEVER" ]
	then
		echo "version of $1 should be $LATESTVER, not $REMOTEVER"
	fi
}

for H in `sort "$1"`
do
	#H="$H.baidu.com"
	echo "$H================================================"

	case $2 in
		epcexist)
			$SSH $H "lsof -n | grep /home/epc"
			;;
		mountcephfs)
			mkdir -p /cephfs/online/_base
			mkdir -p /cephfs/online/logs/$H.baidu.com
			$SSH $H "umount /home/epc/logs ; umount /home/epc/instances/_base ; pkill ceph-fuse ; mkdir -p /home/epc/logs /home/epc/instances/_base ; ceph-fuse -o nonempty -r /online/logs/$H.baidu.com /home/epc/logs ; ceph-fuse -o nonempty -r /online/_base /home/epc/instances/_base"
			;;
		unmountcephfs)
			$SSH $H "umount /home/epc/logs ; umount /home/epc/instances/_base ; pkill ceph-fuse"
			;;
		installceph)
			scp -r /tmp/cephpkgs $H:/tmp/
			$SSH $H "yum -y install python-sphinx python-babel python-markupsafe xfsprogs fuse-libs && rpm -Uvh /tmp/cephpkgs/*"
			scp -r /etc/ceph $H:/etc/
			$SSH $H "ceph -s"
			;;
		copykey)
			ssh-copy-id $H
			scp ~/.ssh/id_rsa $H:/root/.ssh/
			;;
		enablework)
			$SSH $H "(echo BCE@baidu.com ; echo BCE@baidu.com) | passwd work"
			;;
		passwd)
			if [ -n "$3" ]
			then
				$SSH $H "(echo $3 ; echo $3) | passwd root"
			else
				$SSH $H "(echo Welc2EPC ; echo Welc2EPC) | passwd root"
			fi
			;;
		vmlist)
			$SSH $H "virsh list --all"
			;;
		cephfs)
			$SSH $H "df -h | grep ceph-fuse"
			$SSH $H "ps axf | grep ceph-fuse | grep -v grep"
			;;
		ovs)
			$SSH $H "rpm -qa | grep openvswitch && wget http://m1-bce-42-102-24.m1/h/openvswitch-1.11.0-1.x86_64.rpm && wget http://m1-bce-42-102-24.m1/h/kmod-openvswitch-1.11.0-1.el6.x86_64.rpm &&  yum -y erase openvswitch && rpm -Uvh openvswitch-1.11.0-1.x86_64.rpm kmod-openvswitch-1.11.0-1.el6.x86_64.rpm && reboot"
			;;
		mountcephfs)
			$SSH $H "ceph-fuse -r /preonline/instances /home/epc/instances"
			$SSH $H "ceph-fuse -r /preonline/logs/\`hostname\` /home/epc/logs"
			;;
		quota)
			$SSH $H "sed -i "s/.*quota_instances.*/quota_instances=-1/g" /etc/nova/nova.conf ; service nova-compute restart"
			;;
		epctoken)
			#$SSH $H "sed -i "s/^epc_token=.*/epc_token=Z9uqb0XPBObxf1bbA0j0/g" /etc/nova/nova.conf ; service nova-compute restart"
			$SSH $H "grep epc /etc/nova/nova.conf"
			;;
		ramratio)
			$SSH $H "sed -i "s/^ram_allocation_ratio=.*/ram_allocation_ratio=1.0/g" /etc/nova/nova.conf ; service nova-compute restart"
			;;
		getquotaconf)
			$SSH $H "grep quota /etc/nova/nova.conf"
			;;
		changeconf)
			$SSH $H "sed -i \"s/.*resync_interval.*/resync_interval = 60/g\" /etc/neutron/dhcp_agent.ini; sed -i \"s/.*polling_interval.*/polling_interval = 60/g\" /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ; /home/epc/bin/stopall.sh ; /home/epc/bin/start_comp.sh"
			;;
		df)
			$SSH $H "free -m ; df -h"
			;;
		ls)
			#$SSH $H "ls -l /home/epc/src/nova/nova/scheduler/filters/affinity_filter.py"
			$SSH $H "ls -ls /home/epc/instances/_base ; du -hs /home/epc/instances/_base ; df -h"
			;;
		lsof)
			$SSH $H "lsof -n | grep /home/epc/instances/_base"
			;;
		cpall)
			scp bios_check.tar.gz $H:/tmp/
			$SSH $H "cd /tmp ; tar zxf bios_check.tar.gz"
			;;
		cpsac)
			scp bcc-sac.tar.gz $H:/tmp/
			;;
		scp)
			if [ -n "$3" ] && [ -n "$4" ]
			then
				scp "$3" $H:"$4"
			fi
			;;
		delnetns)
			$SSH $H "ip netns | awk '{print \"ip netns del \"\$1}' | bash -x ; ovs-ofctl del-flows br-int"
			;;
		ntfs)
			$SSH $H "sed -i \"s/enabled=0/enabled=1/g\" /etc/yum.repos.d/epel.repo ; yum -y install ntfsprogs"
			;;
		mkfs.ntfs)
			$SSH $H "sed -i \"s/#virt_mkfs=windows=/virt_mkfs=windows=/g\" /etc/nova/nova.conf ; service nova-compute restart"
			;;
		interval)
			$SSH $H "sed -i \"s/.*polling_interval.*/polling_interval=10/g\" /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ; service neutron-openvswitch-agent restart"
			;;
		dhcp)
			$SSH $H "sed -i \"s/.*dhcp_lease_duration.*/dhcp_lease_duration=8640000/g\" /etc/neutron/neutron.conf ; /home/epc/bin/stopall.sh ; /home/epc/bin/start_comp.sh"
			;;
		info)
			$SSH bcc@$H "grep processor /proc/cpuinfo | tail -1 ; uname -a ; lsb_release -a ; free -g ; df -h"
			;;
		kernel)
			$SSH $H "[ \`uname -r\` != \"2.6.32-358.111.3.openstack.el6.x86_64\" ] && rm -rf /tmp/bce-kernel && mkdir -p /tmp/bce-kernel && cd /tmp/bce-kernel && wget http://cq01-bec-backend.epc/bec/kernels/358+10G/kernel-2.6.32-358.111.3.openstack.el6.x86_64.rpm && wget http://cq01-bec-backend.epc/bec/kernels/358+10G/kernel-firmware-2.6.32-358.111.3.openstack.el6.x86_64.rpm && yum -y erase bfa-firmware && rpm -Uvh kernel-2.6.32-358.111.3.openstack.el6.x86_64.rpm kernel-firmware-2.6.32-358.111.3.openstack.el6.x86_64.rpm && reboot && echo Done" &
			;;
		getht)
			$SSH $H "/tmp/bios_check/bioscfg.py -g ht"
			;;
		setht)
			$SSH $H "/tmp/bios_check/bioscfg.py -s ht=on; echo $?"
			;;
		grub0)
			$SSH $H "sed -i \"s/default=1/default=0/g\" /boot/grub/grub.conf && reboot"
			;;
		grub1)
			$SSH $H "sed -i \"s/default=0/default=1/g\" /boot/grub/grub.conf && reboot"
			;;
		startnew)
			$SSH $H "/home/epc/bin/start_comp.sh"
			sleep `cat sleeptime`

#            while (true)
#            do
#                sleep 1
#
#                if [ `top -b -n 1 | grep neutron-server | awk '{print $9}' | cut -f1 -d.` -lt `cat max-cpu-neutron-server` ]
#                then
#                    break
#                fi
#            done

			;;
		addme)
			$SSH $H "/home/epc/bin/add_me.sh"
			;;
		poweroff)
			ssh -o StrictHostKeyChecking=no $H "poweroff"
			;;
		execfile)
			if [ -n "$3" ] && [ -f "$3" ]
			then
				F=`basename "$3"`
				scp "$3" $H:/tmp/
				ssh $H "su - bcc -c \"bash /tmp/$3\" ; rm /tmp/$3" &
			fi

			;;
		cmd)
			if [ -n "$3" ]
			then
				$SSH $H "$3"
			fi

			;;
		allcmd)
			if [ -n "$3" ]
			then
				$SSH $H "$3" &
			fi

			;;
		checkctrl)
			PIP=`$SSH bcc@$H /home/bcc/pythonforbcc/bin/pip freeze`

			if [ -z "$PIP" ]
			then
				continue
			fi

			checkversion nova "$PIP"
			checkversion neutron "$PIP"
			checkversion cinder "$PIP"
			checkversion glance "$PIP"

			checkversion python-keystoneclient "$PIP"
			checkversion python-novaclient "$PIP"
			checkversion python-neutronclient "$PIP"
			checkversion python-cinderclient "$PIP"
			checkversion python-glanceclient "$PIP"
			;;
		checknet)
			PIP=`$SSH bcc@$H /home/bcc/pythonforbcc/bin/pip freeze`

			if [ -z "$PIP" ]
			then
				continue
			fi

			checkversion neutron "$PIP"

			checkversion python-keystoneclient "$PIP"
			checkversion python-novaclient "$PIP"
			checkversion python-neutronclient "$PIP"
			;;
		checkcomp)
			PIP=`$SSH bcc@$H /home/bcc/pythonforbcc/bin/pip freeze`

			if [ -z "$PIP" ]
			then
				continue
			fi

			checkversion nova "$PIP"
			checkversion neutron "$PIP"
			checkversion cinder "$PIP"

			checkversion python-keystoneclient "$PIP"
			checkversion python-novaclient "$PIP"
			checkversion python-neutronclient "$PIP"
			checkversion python-cinderclient "$PIP"
			checkversion python-glanceclient "$PIP"
			;;
	esac
done
