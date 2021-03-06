FROM centos:7.2.1511

MAINTAINER thijs.schnitger@container-solutions.com

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum clean all
RUN yum -y install epel-release
RUN yum -y install cobbler cobbler-web dhcp bind syslinux pykickstart curl xinetd

RUN systemctl enable cobblerd httpd dhcpd xinetd

# enable tftp
RUN sed -i -e 's/\(^.*disable.*=\) yes/\1 no/' /etc/xinetd.d/tftp

# create rsync file, make sure the rsync file exists, or else Cobbler will fail to start.
RUN touch /etc/xinetd.d/rsync

# disalbe SSL requirements
RUN sed -i -e 's/\(SSLRequireSSL\)/# \1/' -e 's/\(NSSRequireSSL\)/# \1/' /etc/httpd/conf.d/cobbler_web.conf

EXPOSE 69
EXPOSE 80
EXPOSE 443
EXPOSE 25151

CMD ["/sbin/init"]
