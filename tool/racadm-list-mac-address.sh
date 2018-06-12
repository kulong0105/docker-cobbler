#!/bin/bash

set -o pipefail

export PATH=/opt/dell/srvadmin/sbin:$PATH

usage() 
{
	cat >&2 <<-EOD
Usage:
	$0 -h <host_ip> -u <user_name> -p <password>

Example:
	$0 -h 192.168.50.135 -u root -p calvin
EOD

	exit 1
}

while getopts "h:u:p:" OPT; do
	case $OPT in
		h) DRAC_IP=$OPTARG;;
		u) DRAC_USER=$OPTARG;;
		p) DRAC_PASS=$OPTARG;;
		?) usage;;
	esac
done

[[ -z $DRAC_IP || -z $DRAC_USER || -z $DRAC_PASS ]] && usage

cobbler_src=$(dirname $(dirname $(readlink -e -v $BASH_SOURCE)))

command -v racadm &>/dev/null || {
	echo "INFO: install racadm command ..."

	sudo yum install -y $cobbler_src/rpm/srvadmin-* || {
		# add a new yum source
		wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash
		sudo yum install -y srvadmin-all
	}

	command -v racadm &>/dev/null || {
		echo "ERROR: failed to install racadm command" >&3
		echo
		echo "Please check below URL to find the suitable rpm package:" >&2
		echo "http://linux.dell.com/repo/hardware/DSU_17.06.00/os_dependent/RHEL7_64/srvadmin/" >&2
		exit 1
	}
}

[[ -f /opt/dell/srvadmin/sbin/racadm ]] || {
	echo "ERROR: cannot find executable racadm command" >&2
	exit 1
}

RACADM="/opt/dell/srvadmin/sbin/racadm -r $DRAC_IP -u $DRAC_USER -p $DRAC_PASS"

if $RACADM getsysinfo | grep Ethernet | sort; then
	echo 
	echo "INFO: run success"
else
	echo 
	echo "ERROR: run fail"
fi

