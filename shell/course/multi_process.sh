#!/bin/bash

pipe_path=/tmp/pipe1
# 建了一个管道
mkfifo ${pipe_path}
exec 6<>${pipe_path}

max_processes=10
if [ $# -eq 1 ]; then
    max_processes=$1
fi

for i in `seq 1 ${max_processes}`
do
    echo "hello" >&6
done

# 多进程实战，以 ping 为例
check_host() {
    local host_prefix=$1
    local i=$2
    local host=${host_prefix}.${i}
    if ping $host -c1 -W1 > /dev/null 2>&1; then
        echo "$host 可达"
    else
        echo "$host 不可达"
    fi

    echo "hello" >&6
}

host_prefix=192.168.1
for i in `seq 2 254`
do
    read -u6 name
    check_host ${host_prefix} ${i} &
done

wait

# 关闭文件描述符6并删除管道
exec 6>&-
rm ${pipe_path}