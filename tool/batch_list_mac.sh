#!/bin/bash

usage()
{
    cat >&2 <<-EOD
Usage:
	$0 -g <group> -u <user_name> -p <password>

Example:
    $0 -g skyaxe1 -u root -p calvin
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

[[ -z $DRAC_USER || -z $DRAC_PASS ]] && usage

cobbler_src=$(dirname $(dirname $(readlink -e -v $BASH_SOURCE)))
skyaxe_ip_list=$cobbler_src/tool/${GROUP}_ip_list

[[ -s $skyaxe_ip_list ]] || {
	echo "ERROR: cannot find file: $skyaxe_ip_list" >&2
	exit 1
}

while read ip
do
	echo "ip: $ip"
	$cobbler_src/tool/racadm-list-mac-address.sh -h $ip -u $DRAC_USER -p $DRAC_PASS || echo -e "\\x1b[1;31mERROR: failed to list mac addressin $ip \\x1b[0m" >&2
done  < $skyaxe_ip_list
