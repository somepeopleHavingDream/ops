#!/bin/bash

# 日志压缩
LOG_DIR=logs
[[ -d "${LOG_DIR}" ]] || mkdir "${LOG_DIR}"
cd "${LOG_DIR}"

log_out() {
    log_path="compress.log"
    echo $1 >> ${log_path}
}

# 按照“时分秒”，每 10 秒生成日志文件
produce_log_files() {
    while ls > /dev/null
    do
        # 2-8
        let "host_count=${RANDOM} % 7 + 2"

        now_time=$(date "+%H%M%S")
        declare -a host_arr
        for i in `seq 0 ${host_count}`
        do
            host_arr[${i}]="10.83.26.`expr ${i} + 10`"
        done
        
        for host in "${host_arr[@]}"
        do
            log_out "生成日志文件：${host}_${now_time}.access.log"
            touch ${host}_${now_time}.access.log
        done

        sleep 10
    done
}

compress_log_files() {
    while ls > /dev/null
    do
        sleep 1
        compress_time=$(find . -name "*.access.log" -exec basename {} \; | awk -F_ '{print $2}' | awk -F. '{print $1}' | sort -r | uniq | awk 'NR==1{print}')
        if [ -z "${compress_time}" ]; then
            log_out "当前没有日志文件要压缩"
            continue
        fi

        log_out "压缩 ${compress_time} 文件"
        find . -name "*${compress_time}.access.log" | xargs tar -czPf "log_compress_${compress_time}.tar.gz"
        if [ $? -eq 0 ] && [ -e "log_compress_${compress_time}.tar.gz" ]; then
            find . -name "*${compress_time}.access.log" -exec rm -rf {} \;
        fi
        log_out "压缩 ${compress_time} 文件完成"
    done
}

produce_log_files &
compress_log_files &