#!/bin/bash

exec 1>> ./deploy_kafka.log 2>&1

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

remote_execute "df -h"
remote_execute "ls"

# 关闭 firewalld 和 setlinux
# 安装配置 jdk
# 安装配置 zookeeper ，并启动服务
# 安装配置 kafka ，并启动服务
