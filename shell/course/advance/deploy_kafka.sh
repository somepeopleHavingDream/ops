#!/bin/bash

# 初始化日志文件
if [ -e ./deploy_kafka.log ]; then
    rm -f ./deploy_kafka.log
fi

exec 1>>./deploy_kafka.log 2>&1

# 初始化变量
HOST_LIST="192.168.1.104"
LOCAL_DIR="/root/disks/disk1/compressfiles"
PACKAGE_DIR="/opt/package"
APP_DIR="/opt/source"
JDK_NAME="jdk-8u261-linux-x64.tar.gz"

# 多主机执行指令函数封装
function remote_execute {
    for host in $HOST_LIST; do
        echo "$cmd($@) host($host)"

        ssh -o StrictHostKeyChecking=no root@$host $@
        if [ $? -eq 0 ]; then
            echo "$cmd($@) success"
        else
            echo "$cmd($@) failed"
        fi
    done

    echo
}

# 多主机传输文件函数封装
function remote_transfer {
    SRC_FILE=$1
    DST_DIR=$2

    # 函数必须有 2 个参数，第一个参数是本地文件或目录，第二个参数为远端主机目录
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <file|dir> <dst_dir>"
        exit 1
    fi

    # 判断第 1 个参数是否存在，如果不存在则直接退出并提示给用户
    if [ ! -e $SRC_FILE ]; then
        echo "$SRC_FILE is not exist."
        exit 2
    fi

    for host in $HOST_LIST; do
        echo "transfer file to host($host)"

        # 判断第 2 个参数，远程主机目录是否存在，如果不存在，则创建
        ssh -o StrictHostKeyChecking=no root@$host "if [ ! -e $DST_DIR ]; then mkdir $DST_DIR -p; fi"

        # scp 传输文件
        scp -r -o StrictHostKeyChecking=no $SRC_FILE root@$host:$DST_DIR/
        if [ $? -eq 0 ]; then
            echo "host($host) scp src_file($SRC_FILE) dst_dir($DST_DIR) success"
        else
            echo "host($host) scp src_file($SRC_FILE) dst_dir($DST_DIR) failed"
        fi
    done
}

# 关闭 firewalld 和 setlinux
remote_execute "systemctl stop firewalld"
remote_execute "systemctl disable firewalld"
remote_execute "setenforce 0"
remote_execute "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"

# 安装配置 jdk
remote_transfer $LOCAL_DIR/$JDK_NAME $PACKAGE_DIR

# 安装配置 zookeeper ，并启动服务
# 安装配置 kafka ，并启动服务
