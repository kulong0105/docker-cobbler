#!/bin/bash

usage()
{
    cat >&2 <<-EOD
Usage:
	$0 -g <group> -u <user_name> -p <password> <hdd | nic | cd>

	nic: set os boot from Network Card (PXE mode)
	hdd: set os boot from Disk
	cd:  set os boot from CD

Example:
    $0 -g skyaxe1 -u root -p calvin nic
    $0 -g skyaxe2 -u root -p calvin hdd
EOD

    exit 1
}

while getopts "g:u:p:h" OPT; do
	case $OPT in
		g) GROUP=$OPTARG;;
		u) DRAC_USER=$OPTARG;;
		p) DRAC_PASS=$OPTARG;;
		h | ?) usage;;
	esac
done

shift $((OPTIND-1))

[[ -z $DRAC_USER || -z $DRAC_PASS || -z $GROUP ]] && usage

boot="$1"
case $boot in
	hdd | nic | cd)
		:
		;;
	*)
		usage
		;;
esac

cobbler_src=$(dirname $(dirname $(readlink -e -v $BASH_SOURCE)))
skyaxe_ip_list=$cobbler_src/tool/${GROUP}_ip_list

[[ -s $skyaxe_ip_list ]] || {
	echo "ERROR: cannot find file: $skyaxe_ip_list" >&2
	exit 1
}

while read ip
do
	echo "ip: $ip"
	$cobbler_src/tool/racadm-change-boot-seq.sh -h $ip -u $DRAC_USER -p $DRAC_PASS $boot || echo -e "\\x1b[1;31mERROR: failed to set OS boot option in $ip \\x1b[0m" >&2
done  < $skyaxe_ip_list
