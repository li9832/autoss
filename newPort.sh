#!/bin/env bash
# 生成并修改为随机端口，防火墙放通。2023年2月1日，v1

function rand(){
    min=$1
    max=$(($2 - $min + 1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num % $max + $min))
}

rnd=$(rand 10000 65500)

CurrentPort=`netstat -lup | grep kcptun | awk '{print $4}' | awk -F : '{print $4}'`
echo "The current port is ${CurrentPort}"
echo "The new port is ${rnd}"

sed -i "2c\    \"listen\": \":${rnd}\"," /usr/local/ss_kcp/kcptun.json
firewall-cmd --permanent --remove-port=${CurrentPort}/udp
firewall-cmd --permanent --add-port=${rnd}/udp
firewall-cmd --reload
systemctl restart kcptun

cat /usr/local/ss_kcp/kcptun.json
firewall-cmd --list-all
