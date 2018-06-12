# Docker-Cobbler 使用方法

## 环境准备

### IP地址设置
配置本机的静态IP地址为`10.0.0.1`

NOTE: 该地址将作为PXE服务器地址和DHCP服务器地址

### 端口设置
由于docker需要监听 69/80/443/25151 端口，如果开启了iptables/firewalld，需要确保这几个端口的数据包能够通过。

### SELinux设置
使用`getenforce`查看本机的SELinux的状态，如果是enforcing/permissive状态，需要使用`setenforce 0`临时关闭SELinux服务。

### 磁盘空间
Docker-Cobbler将要使用var目录存储OS镜像，需要至少`5-10GB`磁盘空间。


## Docker-Cobbler配置

### 准备CentOS的安装镜像
```
$ ln -sf $path_centos dist/centos.iso
```
NOTE:替换path_centos变量为实际的CentOS安装镜像路径

### 挂载镜像
```
$ make mount
```

### 构建docker镜像
```
$ make build
```

### 运行docker镜像
```
$ make run
```

### 同步配置
```
$ make sync
```
NOTE: 这个同步操作非常重要，在针对配置文件做了任何修改之后，都需要执行该命令同步一下。
      从同步配置开始，所有操作皆需要在10.0.0.1环境下进行，否则会出现非预期错误。

### 导入CentOS镜像
```
$ make import
```

## 环境检查
```
$ make check
```

### 确认IP配置的地址为10.0.0.1
```
$ ip addr | grep 10.0.0.1
    inet 10.0.0.1/24 brd 10.0.0.255 scope global br-private
```

### 确认cobblerd服务的状态为active(running)
```
$ docker exec -it cobbler systemctl status cobblerd
● cobblerd.service - Cobbler Helper Daemon
   Loaded: loaded (/usr/lib/systemd/system/cobblerd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2017-10-18 01:39:54 UTC; 6h ago
 Main PID: 352 (cobblerd)
   CGroup: /docker/411ce0b430bf984aa7bbb12c7c85df766f3c2d55ead50a1d197d36551d156a11/system.slice/cobblerd.service
           └─352 /usr/bin/python2 -s /usr/bin/cobblerd -F
...
$
```

### 确认httpd服务的状态为active(running)
```
$ docker exec -it cobbler systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2017-10-17 09:35:34 UTC; 59min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 349 (httpd)
   Status: "Total requests: 1807; Current requests/sec: 0.5; Current traffic: 307 B/sec"
   CGroup: /docker/46eeb4bfad0cad23db203b972ef7dd01da26ad1efbddec629bb77a960a36b662/system.slice/httpd.service
           ├─349 /usr/sbin/httpd -DFOREGROUND
           ├─357 (wsgi:cobbler_w -DFOREGROUND
           ├─358 /usr/sbin/httpd -DFOREGROUND
           ├─360 /usr/sbin/httpd -DFOREGROUND
           ├─361 /usr/sbin/httpd -DFOREGROUND
           ├─362 /usr/sbin/httpd -DFOREGROUND
           ├─364 /usr/sbin/httpd -DFOREGROUND
           ├─383 /usr/sbin/httpd -DFOREGROUND
           └─554 /usr/sbin/httpd -DFOREGROUND

Oct 17 09:35:33 sd002021.skydata.com systemd[1]: Starting The Apache HTTP Server...
Oct 17 09:35:34 sd002021.skydata.com systemd[1]: Started The Apache HTTP Server.
$
```

### 确认dhcpd服务的状态为active(running)
```
$ docker exec cobbler systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2017-10-17 10:40:52 UTC; 44s ago
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
 Main PID: 536 (dhcpd)
   Status: "Dispatching packets..."
   CGroup: /docker/46eeb4bfad0cad23db203b972ef7dd01da26ad1efbddec629bb77a960a36b662/system.slice/dhcpd.service
           └─536 /usr/sbin/dhcpd -f -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid br-private

Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Copyright 2004-2013 Internet Systems Consortium.
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: All rights reserved.
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: For info, please visit https://www.isc.org/software/dhcp/
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Not searching LDAP since ldap-server, ldap-port and ldap-base-dn were not specified in the config file
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Wrote 0 class decls to leases file.
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Wrote 0 leases to leases file.
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Listening on LPF/br-private/fe:54:00:12:d6:e1/10.0.0.0/24
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Sending on   LPF/br-private/fe:54:00:12:d6:e1/10.0.0.0/24
Oct 17 10:40:52 sd002021.skydata.com systemd[1]: Started DHCPv4 Server Daemon.
Oct 17 10:40:52 sd002021.skydata.com dhcpd[536]: Sending on   Socket/fallback/fallback-net
$
```

如果出现下面的信息，则表明dhcpd服务器可能无法正常工作:

```
$ docker exec cobbler systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2017-10-11 02:48:15 UTC; 35s ago
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
 Main PID: 318 (dhcpd)
   Status: "Dispatching packets..."
   CGroup: /system.slice/docker-fe4b6dd19228192dbfb8776730085a5afae90f00560e617c733af06754427e68.scope/system.slice/dhcpd.service
           └─318 /usr/sbin/dhcpd -f -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid

Oct 11 02:48:15 localhost.localdomain dhcpd[318]:    to which interface wlp3s0 is attached. **
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:
Oct 11 02:48:15 localhost.localdomain dhcpd[318]: No subnet declaration for enp0s25 (192.168.50.28).
Oct 11 02:48:15 localhost.localdomain dhcpd[318]: ** Ignoring requests on enp0s25.  If this is not what
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:    you want, please write a subnet declaration
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:    in your dhcpd.conf file for the network segment
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:    to which interface enp0s25 is attached. **
Oct 11 02:48:15 localhost.localdomain dhcpd[318]:
Oct 11 02:48:15 localhost.localdomain dhcpd[318]: Sending on   Socket/fallback/fallback-net
$ 
```

为了让dhcpd服务器可以正常工作，可以强制设置固定的监听网卡（或网桥），如：
```
$ docker exec cobbler sed -i "s#--no-pid#--no-pid br-private#"  /usr/lib/systemd/system/dhcpd.service
$ docker exec cobbler systemctl daemon-reload
$ docker exec cobbler systemctl restart dhcpd
$ docker exec cobbler systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2017-10-11 03:02:40 UTC; 3s ago
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
 Main PID: 452 (dhcpd)
   Status: "Dispatching packets..."
   CGroup: /system.slice/docker-fe4b6dd19228192dbfb8776730085a5afae90f00560e617c733af06754427e68.scope/system.slice/dhcpd.service
           └─452 /usr/sbin/dhcpd -f -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid br-private

Oct 11 03:02:40 localhost.localdomain dhcpd[452]: For info, please visit https://www.isc.org/software/dhcp/
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Not searching LDAP since ldap-server, ldap-port and ldap-base-dn were not specified in the config file
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Wrote 0 class decls to leases file.
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Wrote 0 leases to leases file.
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Multiple interfaces match the same subnet: virbr0 br-private
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Multiple interfaces match the same shared network: virbr0 br-private
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Listening on LPF/br-private/1e:a8:e7:58:b9:a4/10.0.0.0/24
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Sending on   LPF/br-private/1e:a8:e7:58:b9:a4/10.0.0.0/24
Oct 11 03:02:40 localhost.localdomain systemd[1]: Started DHCPv4 Server Daemon.
Oct 11 03:02:40 localhost.localdomain dhcpd[452]: Sending on   Socket/fallback/fallback-net
$
```
此时，能够看到dhcpd服务正常地工作了。

NOTE: `br-private`为配置10.0.0.1 IP地址的网卡或网桥名。


## 开始安装

cobbler使用如下三级概念：  
1) distro: 即“操作系统”, 如上用cobbler import导入iso时，会自动生成一个distro  
2) profile: 即“操作系统” + “具体的系统安装参数”；系统安装参数，通常就是指ks文件  
3) system: 即具体的实例，除了default外，还可以具体指定到某一台服务器  


* distro 检查
```
$ docker exec cobbler cobbler distro list
   centos7-x86_64
$ docker exec cobbler cobbler distro report --name centos7-x86_64
Name                           : centos7-x86_64
Architecture                   : x86_64
TFTP Boot Files                : {}
Breed                          : redhat
Comment                        : 
Fetchable Files                : {}
Initrd                         : /var/www/cobbler/ks_mirror/centos7-x86_64/images/pxeboot/initrd.img
Kernel                         : /var/www/cobbler/ks_mirror/centos7-x86_64/images/pxeboot/vmlinuz
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart Metadata             : {'tree': 'http://@@http_server@@/cblr/links/centos7-x86_64'}
Management Classes             : []
OS Version                     : rhel7
Owners                         : ['admin']
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Template Files                 : {}
$ 
```

* profile检查
```
$ docker exec cobbler cobbler profile list
   centos7-x86_64
$ docker exec cobbler cobbler profile report --name centos7-x86_64
Name                           : centos7-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : centos7-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm
$
```

* system检查
```
$ docker exec cobbler cobbler system list
$
```

NOTE： 初始情况下，不存在任何system，可以使用`docker exec cobbler cobbler system add --name=default --profile=skyaxe` 添加一个默认的system。


### Command-line方式安装

#### 配置被安装机器的信息

根据实际情况，对每台被安装机器的信息进行配置, 如下所示：
```
$ cat config/skyaxe1/skyaxe-app-0
# hostname config
hostname="skyaxe-app-0.localdomain"

# network config
boot_nic="eth0"
netmask="255.255.255.0"
mac_addr=""
ip_addr=""

boot_nic_1="eth1"
netmask_1="255.255.255.0"
mac_addr_1=""
ip_addr_1=""

gateway=""
name_server=""

# disk config
### please not double quote `sda` ###
boot_disk=sda
$
```
NOTE：  
1) 每个参数都必须要配置  
2) app节点需要访问外网，所以需要配置两卡网卡信息  
3) 当前默认采取static protocal设置IP地址，不支持dhcp  
4) 每一套的所有配置须存放在config下的自定义目录下，该目录名即自动化脚本的group参数  

#### 执行脚本配置cobbler system
```
$ ./tool/cobbler-system-config -g skyaxe1
```

#### 设置被安装机器PXE启动

* 自动化脚本修改

1) 配置被安装机器的`后台`IP地址, 如下所示：
```
$ cat tool/skyaxe1_ip_list
192.168.50.237
192.168.50.234
192.168.50.235
192.168.50.236
192.168.50.231
192.168.50.232
192.168.50.233
$
```
NOTE：  skyaxe1即group参数，须和config下的目录名一致

2) 执行自动修改脚本
```
$ tool/batch_change_boot.sh -g skyaxe1 -u root -p calvin nic
```

* 手工修改  
对每台机器的BIOS进行设置

#### 重启被安装机器
重启机器，使得机器通过PXE方式进行OS安装。

#### 恢复被安装机器从硬盘启动

PXE方式启动会导致机器在重启之后需要检测网卡，当机器具有多块网卡时，需要较长时间检测，导致启动机器较慢。
同样，有两种方式来修改机器启动的方式：  
* 手工修改BIOS
* 自动化脚本 `tool/batch_change_boot.sh -g skyaxe1 -u root -p calvin hdd`


### WEB UI方式安装

- 浏览器访问`http://localhost/cobbler_web`
- 登录帐号 cobbler/cobbler
- 根据需要创建profile和system

关于如何创建 profile 和 system, 请参考`doc/Manual.docx`



## FAQ

### cobbler 常用命令
* cobbler check    检查cobbler配置
* cobbler list     列出所有的cobbler元素
* cobbler report   列出元素的详细信息
* cobbler distro   查看导入的发行版系统信息 
* cobbler system   查看添加的系统信息 
* cobbler profile  查看配置信息
* cobbler sync     同步Cobbler配置
* cobbler reposync 同步yum仓库


### 使用非10.0.0.1网段 

如果需要使用非10.0.0.1网段来安装操作系统，需要如下2步修改：

* 修改settings配置文件

```
$ cat etc/cobbler/settings
...
270 # if using cobbler with manage_dhcp, put the IP address
271 # of the cobbler server here so that PXE booting guests can find it
272 # if you do not set this correctly, this will be manifested in TFTP open timeouts.
273 next_server: 10.0.0.1                 <======

379 # this is the address of the cobbler server -- as it is used
380 # by systems during the install process, it must be the address
381 # or hostname of the system as those systems can see the server.
382 # if you have a server that appears differently to different subnets
383 # (dual homed, etc), you need to read the --server-override section
384 # of the manpage for how that works.
385 server: 10.0.0.1                      <=======
...
```

* 修改dhcp.template配置文件

```
$cat etc/cobbler/dhcp.template
...

 21 subnet 10.0.0.0 netmask 255.255.255.0 {                     <======
 22      option routers             10.0.0.1;                   <======
 23      option domain-name-servers 10.0.0.1;                   <======
 24      option subnet-mask         255.255.255.0;
 25      range dynamic-bootp        10.0.0.100 10.0.0.254;      <======
 26      default-lease-time         21600;
 27      max-lease-time             43200;
...
```

### 针对VM进行部署

推荐在Host上创建一个单独的网桥来给PXE/DHCP服务器使用，步骤如下：
```
$ sudo brctl addbr br-private
$ sudo brctl stp br-private on
$ sudo ifconfig br-private 10.0.0.1 netmask 255.255.255.0
$ sudo brctl show
```

同时，如果使用virtio模式配置磁盘，需要修改config下的配置文件的boot_disk选项，修改为`vda`

### 磁盘空间

cobbler-docker对安装操作系统盘要求至少`60GB`空间。如果安装磁盘没有足够的空间，修改如下配置文件：
```
$ cat var/lib/cobbler/kickstarts/skyaxe.ks
...
39	partition /boot --asprimary --size=1024 --label="BOOT"
40	partition pv.01 --asprimary --size=61440 --grow --maxsize=204800     <======
41
42	volgroup skyaxe pv.01
43	logvol swap --vgname=skyaxe --name=swap --size=8192
44	logvol / --fstype="xfs" --size=51200 --name=root --vgname=skyaxe     <======
...
```

NOTE:  
1) 40行表示创建一个60GB的LVM逻辑组  
2) 43行表示创建跟分区大小为50GB  


### 更改默认的root密码

默认的root密码为SkyAXE@1229, 如果需要修改，例如修改密码为"123456", 进行如下2步：

* 生成密码的加密字符串

```
$ openssl passwd -1 "123456"
$1$poleAmKQ$/zjUaWP91LUiA4BKK1T3G1
$
```

NOTE: 同样的密码，每次运行生成的加密字符串不一样。


* 替换加密字符串

```
$ cat var/lib/cobbler/kickstarts/skyaxe.ks
...
7	# Root password
8	rootpw --iscrypted $1$aMQS/WDI$TDquBIF76vITK/GJqMhjf1              <======
9	# System timezone
...
```

### 执行make import出错

这个可能是由于signature错出导致，使用如下命令进行修复：
```
$ docker exec cobbler cobbler signature update
```

### cobblerd服务启动失败

可以尝试使用`docker exec cobbler cobbler check`命令检查环境，并根据输出的信息逐一修复。


### no-disks-selected

当cobbler-docker配置OS安装到sda磁盘时，需要确保其他磁盘没有装OS，否则可能出现如下错误：
![no-disks-selected] (./doc/no-disks-selected.png)


### 操作系统启动失败

当cobbler-docker成功安装操作系统后，如果无法启动，可能的原因是由于服务器没有设置好可启动磁盘，从而导致启动失败。
如：设置了sda为可启动设备，OS被安装到sdc盘，那么启动就会失败。


### 无法通过PXE再次进行安装

Cobbler-Docker在一个system通过PXE安装操作系统后, `Netboot-Enabled`选项会自动变为`false`（为了防止进入PXE安装系统的循环）  
如果需要再次对该system使用PXE安装系统, 需要编辑该system的配置，将netboot_enabled设置为1.
```
$ docker exec cobbler cobbler system report skyaxe-app-0 | grep Netboot
Netboot Enabled                : False
$ docker exec cobbler cobbler system edit --name=skyaxe-app-0 --netboot-enabled=1
$
```

### mac地址获取
使用tool目录下的batch_list_mac.sh可以批量获取MAC地址，使用前需要更新对应的$group_ip_list。以skyaxe1为group举例：
```
$ tool/batch_list_mac.sh -g skyaxe1 -u root -p calvin
```

## Supported Distributions
* CentOS6.x and CentOS7.x


## Refers
- https://container-solutions.com/cobbler-in-a-docker-container/
- https://www.linuxtechi.com/install-and-configure-cobbler-on-centos-7/
- https://cobbler.github.io/manuals/quickstart/
- https://ieevee.com/tech/2017/03/17/pxe-default.html
