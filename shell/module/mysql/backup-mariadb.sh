#!/bin/bash

# 这个地方一定要用绝对路径
backup_dir='/home/yangxin/Downloads/mysql-backup'
time=$(date +%Y%m%d-%H%M%S)
echo $backup_dir
echo $time
mysqldump --opt -uroot -p123456 --all-databases | gzip > $backup_dir/all-databases_$time.sql.gz
