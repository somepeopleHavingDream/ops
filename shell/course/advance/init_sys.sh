#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: sh $0 user_name user_pass"
    exit 1
fi

# 初始化变量
ROOT_PASS="123456"
USER_NAME=$1
USER_PASS=$2
HOST_LIST="192.168.1.107"

# 管理主机本地创建用户、设置密码
useradd $USER_NAME
echo $USER_PASS | passwd --stdin $USER_NAME

# 管理主机针对已创建的用户生成密钥对
su - $USER_NAME -c "echo "" | ssh-keygen -t rsa"
PUB_KEY="$(cat /home/$USER_NAME/.ssh/id_rsa.pub)"

# 利用 ssh 非免密在所有需管理主机上创建用户、设置密码
# 实现拷贝管理主机的公钥内容到对端主机
for host in $HOST_LIST; do
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "useradd $USER_NAME"
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "echo $USER_PASS | passwd --stdin $USER_NAME"
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "mkdir /home/$USER_NAME/.ssh -pv"
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "echo $PUB_KEY > /home/$USER_NAME/.ssh/authorized_keys"
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "chmod 600 /home/$USER_NAME/.ssh/authorized_keys"
    sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh"
done
