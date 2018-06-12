#!/bin/bash

export PATH=/opt/dell/srvadmin/sbin:$PATH

shopt -s -o pipefail

usage()
{
    cat >&2 <<-EOD
Usage:
	$0 -h <host_ip> -u <user_name> -p <password> <hdd | nic | cd>

	nic: set os boot from Network Card (PXE mode)
	hdd: set os boot from Disk
	cd:  set os boot from CD

Example:
    $0 -h 192.168.50.135 -u root -p calvin nic
    $0 -h 192.168.50.135 -u root -p calvin hdd
EOD

    exit 1
}

while getopts "h:u:p:" OPT; do
	case $OPT in
		h) DRAC_IP=$OPTARG;;
		u) DRAC_USER=$OPTARG;;
		p) DRAC_PASS=$OPTARG;;
		?) echo "unknown option" >&2; exit 1;;
	esac
done

shift $((OPTIND-1))

[[ -z $DRAC_IP || -z $DRAC_USER || -z $DRAC_PASS ]] && usage

if [[ ! $1 =~ ^(hdd|nic|cd)$ ]]; then
	echo "ERROR: Invalid boot device." >&2
	exit 1
fi

cobbler_src=$(dirname $(dirname $(readlink -e -v $BASH_SOURCE)))

command -v racadm &>/dev/null || {
	echo "INFO: install racadm command ..."

	sudo yum install -y $cobbler_src/rpm/srvadmin-* || {
		# check distro and releasever
		distro=$(sed -n 's/^distroverpkg=//p' /etc/yum.conf)
		releasever=$(rpm -q --qf "%{version}" -f /etc/$distro)
		if [[ $releasever -eq 6 || $releasever -eq 7 ]]; then
			# add a new yum source
			wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | sudo bash
			sudo yum install -y srvadmin-all
		else
			echo "ERROR: racadm only support CentOS 6/7" >&2
			exit 1
		fi
	}

	command -v racadm &>/dev/null || {
		echo "ERROR: failed to install racadm command" >&2
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
HDD_DEFAULT="HardDisk.List.1-1"
NIC_DEFAULT="NIC.Integrated.1-1-1"
CD_DEFAULT="Optical.SATAEmbedded.J-1"

OLDSEQ=$($RACADM get BIOS.BiosBootSettings.BootSeq | tr -d '\r' | grep ^BootSeq | cut -d= -f2) || {
	echo "ERROR: failed to run racadm command" >&2
	exit 1
}
echo OLDSEQ: $OLDSEQ
OLDIFS=$IFS; IFS=,; OLDSEQ=$(echo $OLDSEQ); IFS=$OLDIFS
for b in $OLDSEQ; do
	case $b in
		Optical.*) CD="${CD:+$CD,}$b";;
		NIC.*) NIC="${NIC:+$NIC,}$b";;
		HardDisk.*) HDD="${HDD:$+HDD,}$b";;
		*) UNKOWN="${UNKOWN:+$UNKOWN,}$b";;
	esac
done

case $1 in
	hdd) FIRST=${HDD:-$HDD_DEFAULT};;
	nic) FIRST=${NIC:-$NIC_DEFAULT};;
	cd) FIRST=${CD:-$CD_DEFAULT};;
esac

NEWSEQ=$FIRST
for b in $OLDSEQ; do
	if ! grep -q $b <<<$FIRST; then
		NEWSEQ=${NEWSEQ},$b
	fi
done

echo NEWSEQ: $NEWSEQ
if $RACADM set BIOS.BiosBootSettings.BootSeq $NEWSEQ; then
	$RACADM jobqueue create BIOS.Setup.1-1 && $RACADM serveraction powercycle
fi
