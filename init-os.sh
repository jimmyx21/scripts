#/bin/bash
# auther: jimmyx
# Date: 2019-09-12

IP_DEVICE=`ifconfig |head -n 1|awk -F ":" '{print $1}'`
IPP_GATEWAY=`echo $1 | awk -F '.' '{print $1"."$2"."$3}'`
IP_ADDR=$1
HOSTNAME=$2

yum -y install wget

# 配置ip
ip_env(){
	cd  /etc/sysconfig/network-scripts/
	if [ ${IP_DEVICE} != "eht0" ];then
	   mv ifcfg-${IP_DEVICE} igcfg-eth0
	fi

cat >  /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eth0                  
DEVICE=eth0               
ONBOOT=yes
IPADDR=${IP_ADDR}
PREFIX=24
#GATEWAY=${IPP_GATEWAY}.1
GATEWAY=192.168.1.1
DNS1=223.5.5.5
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_PRIVACY=no
EOF

cp -a /etc/sysconfig/grub /etc/sysconfig/grub.bak
cat >/etc/sysconfig/grub <<  EOF
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="\$(sed 's, release .*\$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto net.ifnames=0 biosdevname=0 rhgb quiet" 
GRUB_DISABLE_RECOVERY="true"
EOF

/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg


echo "\033[32m Set IP--- ok\! \033[0m"
}


# 配置yum源

yum_env(){
   mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
   wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
   sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
   wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
   yum clean all && yum makecache
 
}


install_package(){
    yum -y install mlocate screen ntp unzip zip parted rsync tree vim lrzsz tcpdump telnet sysstat lsof strace iptraf iotop hdparm nc mtr lrzsz nmap telnet tree ntpdate bash-completion chrony net-tools  wget 
   yum -y install gcc gcc-c++ autoconf automake make cmake libevent libtool libXaw expat-devel libxml2-devel libevent-devel asciidoc cyrus-sasl-devel cyrus-sasl-gssapi krb5-devel libtidy libxslt-devel python-devel openssl-devel gmp-devel snappy snappy-devel libcurl libcurl-devel git
}


system_env(){
/usr/bin/hostnamectl set-hostname ${HOSTNAME}
chmod +x /etc/rc.d/rc.local 

sed -i.bak 's@#UseDNS yes@UseDNS no@g;s@^GSSAPIAuthentication yes@GSSAPIAuthentication no@g'  /etc/ssh/sshd_config
systemctl stop firewalld   && systemctl disable firewalld  && systemctl mask firewalld 	

echo "* soft nofile 65536" >> /etc/security/limits.conf     
echo "* hard nofile 65536" >> /etc/security/limits.conf

cat >/var/spool/cron/root<<-EOF
*/30 * * * * /usr/sbin/ntpdate time1.aliyun.com >> /dev/null
0 2  * * * /bin/sh /data/scripts/mem_cache.sh >> /dev/null
EOF


echo "* hard nofile 65536" >> /etc/security/limits.conf
echo -e "vm.swappiness = 0\n" >> /etc/sysctl.conf
echo -e "net.ipv4.neigh.default.gc_stale_time=120\n" >> /etc/sysctl.conf
echo -e "net.ipv4.conf.all.rp_filter=0\n" >> /etc/sysctl.conf
echo -e "net.ipv4.conf.default.rp_filter=0\n" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.arp_announce = 2" >> /etc/sysctl.conf
echo "net.ipv4.conf.lo.arp_announce=2" >> /etc/sysctl.conf
echo -e "net.ipv4.conf.all.arp_announce=2\n" >> /etc/sysctl.conf
echo -e "net.ipv4.tcp_max_tw_buckets = 100000\n" >> /etc/sysctl.conf
echo -e "net.ipv4.tcp_syncookies = 1\n" >> /etc/sysctl.conf
echo -e "net.ipv4.tcp_max_syn_backlog = 1024\n" >> /etc/sysctl.conf
echo -e "net.ipv4.tcp_synack_retries = 2\n" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "vm.dirty_expire_centisecs = 3000" >> /etc/sysctl.conf
echo "vm.dirty_writeback_centisecs = 500" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" >> /etc/sysctl.conf
echo "vm.dirty_ratio = 30 " >> /etc/sysctl.conf
echo "vm.dirty_bytes = 0">> /etc/sysctl.conf
echo "vm.dirty_background_bytes = 0">> /etc/sysctl.conf
}

main (){
        echo -e "\033[32m 1.配置ip地址... \033[0m"
	ip_env        
       
        echo -e "\033[32m 2.内核参数配置... \033[0m"
        yum_env

 	echo -e "\033[32m 3. 创建用户...  \033[0m"
	install_package	

        echo -e "\033[32m 4. 系统配置...\033[0m"
        system_env
}
main
