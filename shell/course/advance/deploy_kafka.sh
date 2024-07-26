#!/bin/bash

# 初始化日志文件
if [ -e ./deploy_kafka.log ]; then
    rm -f ./deploy_kafka.log
fi

exec 1>>./deploy_kafka.log 2>&1

# 初始化变量
HOST_LIST="192.168.1.107"
CMD_NUM=0

# 多主机执行指令函数封装
function remote_execute {
    for host in $HOST_LIST; do
        CMD_NUM=$((CMD_NUM + 1))
        CMD_STR="cmd-num($CMD_NUM)"

        echo "$CMD_STR cmd($@) host($host)"
        ssh -o StrictHostKeyChecking=no root@$host $@
        if [ $? -eq 0 ]; then
            echo "$CMD_STR cmd($@) success"
        else
            echo "$CMD_STR cmd($@) failed"
        fi
    done

    echo
}

# 关闭 firewalld 和 setlinux 函数封装
function turn_off_firewalld {
    remote_execute "systemctl stop firewalld"
    remote_execute "systemctl disable firewalld"
    remote_execute "setenforce 0"
    remote_execute "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
}

# 关闭 firewalld 和 setlinux
turn_off_firewalld

# 安装配置 jdk
# 安装配置 zookeeper ，并启动服务
# 安装配置 kafka ，并启动服务
