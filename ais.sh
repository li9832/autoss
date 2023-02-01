#!/bin/env bash
# 2022/10/30.ver1
# 
source /etc/os-release

function whatOS(){
        case $ID in
    debian|ubuntu|devuan)
        apt update -y
        apt install wget vim firewalld net-tools tar -y 
        ;;
    centos|fedora|rhel)
        rm -rf /etc/yum.repos.d/*
        if [ $VERSION_ID == '8' ]; then
            sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
            sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        elif [ $VERSION_ID == '7' ]; then
            rpm -Uvh --force http://mirror.centos.org/centos-7/7/os/x86_64/Packages/centos-release-7-9.2009.0.el7.centos.x86_64.rpm
        else 
            exit 1:wq
        fi
        yum clean all && yum makecache
        yum update -y && yum upgrade -y
        yum install wget vim firewalld net-tools tar gzip git -y 
        ;;
    *)
        exit 1
        ;;
    esac
}
#检查更新
whatOS
#安装&启动ss-kcp
cd ~/ && git clone https://github.com/li9832/autoss.git
cd / && tar -zxvf /root/autoss/ss-kcpv3.tar.gz
systemctl enable shadowsocks2.service
systemctl start shadowsocks2.service
systemctl enable kcptun.service
systemctl start kcptun.service
sh ~/autoss/newPort.sh

# 修改SSH端口及使用密钥登陆
mkdir -m 644 ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKA5KEx9IFpLhhR4H5QU03L6jegijeS928F4dakD6R1lSYrsYi7WeR42ir86Omq1rs15DaGnKx1DhJkyUHD2hzp/pLyikfPZvbMyUionV0MfWGOil9ioRe+GN11R7W7U+jMTUwGZddaUAwIoNRett7/aJI22HraGtpyikIjUp2hrQtwUvthGbMSZBRuqUnxSQOUIDhnJhxB2U6YwOT1dR/FoL7q6CV/pb5hMStw/zpP/cSfvBXaxATPfhLQJ4GBUSU4f1gXbkPersCv0NJLLaIWZjxs6od0YCfxthVg23QCOK7wy117kARhKmlEOWUSZsVQsLbuvA12QqpxZbfw8ZV  ${USER}@${HOSTNAME}" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
sed -i 's/#Port\ 22/Port\ 8881/g' /etc/ssh/sshd_config
echo 'RSAAuthentication yes' >> /etc/ssh/sshd_config
echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication\ yes/PasswordAuthentication\ no/g' /etc/ssh/sshd_config
systemctl restart sshd
# 防火墙放行&关闭端口
CurrentPort=`netstat -lup | grep kcptun | awk '{print $4}' | awk -F : '{print $4}'`
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=8881/tcp --add-port=${CurrentPort}/udp 
firewall-cmd --permanent --remove-service=ssh 
firewall-cmd --permanent --remove-service=cockpit
firewall-cmd --permanent --remove-service=dhcpv6-client
firewall-cmd --reload
firewall-cmd --list-all
netstat -lntup

