#!/bin/bash
LOG_PATH="/usr/local/nginx/logs"
RECORD_TIME=$(date -d "yesterday" +%Y-%m-%d+%H:%M)
PID=/usr/local/nginx/logs/nginx.pid
mv ${LOG_PATH}/access.log ${LOG_PATH}/access.${RECORD_TIME}.log
mv ${LOG_PATH}/error.log ${LOG_PATH}/error.${RECORD_TIME}.log
#向nginx主进程发送信号，用于重新打开日志文件
#普通用户如果要运行这条命令，需要输入密码，只有root用户才能自动化运行
kill -USR1 `cat $PID`
