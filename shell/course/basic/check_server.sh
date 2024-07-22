#! /bin/bash

# 通过进程判断 nginx
# 通过请求本地的 80 端口

check_nginx() {
    ps -ef | grep "/usr/sbin/nginx" | grep -v grep > /dev/null
    return $?
}

sleep_time=10
while ls > /dev/null
do
    sleep ${sleep_time}
    if check_nginx; then
        echo "nginx 存在，休息 ${sleep_time}s"
        continue
    fi

    echo "启动 nginx ... "
    systemctl start nginx
    sleep ${sleep_time}
    if check_nginx; then
        echo "重新启动 nginx 成功"
        continue
    fi

    echo "nginx 无法启动，请检查配置"
    break
done