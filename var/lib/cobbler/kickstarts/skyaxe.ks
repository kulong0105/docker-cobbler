#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted $1$aMQS/WDI$TDquBIF76vITK/GJqMhjf1
# System timezone
timezone Asia/Shanghai --isUtc
# Use network installation
url --url=$tree
# System language
lang en_US
# Firewall configuration
firewall --disabled
firstboot --disabled
selinux --disabled
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
# Do not configure the X Window System
skipx

# Network information
$SNIPPET('network_config')
network --hostname=$getVar('hostname', 'localhost.localdomain')
# Reboot after installation
reboot

#set $disk=$getVar('disk', 'sda')
ignoredisk --only-use=$disk

# Partition clearing information
clearpart --all --initlabel
#autopart --type=lvm

partition /boot --asprimary --size=1024 --label="BOOT"
partition pv.01 --asprimary --size=61440 --grow --maxsize=204800

volgroup skyaxe pv.01
logvol swap --vgname=skyaxe --name=swap --size=8192
logvol / --fstype="xfs" --size=51200 --name=root --vgname=skyaxe

# System bootloader configuration
bootloader --location=mbr

# Clear the Master Boot Record
zerombr

%packages
@^minimal
@core

httpd
nmap
bzip2
gcc
make
logrotate
rsync
libX11
pciutils
mailx

libnl
libxml2-python
lsof
unzip
%end

services --disabled=NetworkManager,firewalld
services --enabled=sshd

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')

$SNIPPET('openssh_disable_key_check')

#set $install_private_key = $getVar('install_private_key', None)
#if $install_private_key and $install_private_key in ('1', 'true', 'True')
$SNIPPET('post_install_private_key')
#end if

#set $install_public_key = $getVar('install_public_key', None)
#if $install_public_key and $install_public_key in ('1', 'true', 'True')
$SNIPPET('post_install_public_key')
#end if

$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('post_install_etc_hosts')

$SNIPPET('kickstart_done')
# End final steps
%end
