#!/bin/bash

# 初始化变量
ROOT_PASS="123456"
USER_NAME="root"
USER_PASS="123456"
HOST_LIST="192.168.1.107"

# 管理主机针对已创建的用户生成密钥对
if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
PUB_KEY=$(cat /root/.ssh/id_rsa.pub)

# 实现拷贝管理主机的公钥内容到对端主机
for host in $HOST_LIST; do
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "echo $PUB_KEY > /root/.ssh/authorized_keys"
done
