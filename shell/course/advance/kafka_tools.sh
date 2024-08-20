#!/bin/bash

HOST_LIST="192.168.1.109"

function service_start {
    for host in $HOST_LIST; do
        echo "service_start host($host)"

        service_status $host
        if [ $? -eq 0 ]; then
            echo "Kafka broker in $host is already RUNNING"
        else
            ssh -o StrictHostKeyChecking=no $host "/opt/source/kafka/bin/kafka-server-start.sh -daemon /opt/source/kafka/config/server.properties" &>/dev/null
            index=0
            while [ $index -le 10 ]; do
                service_status $host
                if [ $? -ne 0 ]; then
                    sleep 3
                    index=$(expr $index + 1)
                    continue
                else
                    echo "ok, kafka broker in $host is RUNNING"
                    break
                fi
            done
        fi
    done
}

# function service_stop {

# }

function service_status {
    ssh -o StrictHostKeyChecking=no $1 "jps | grep -w Kafka" &>/dev/null
    if [ $? -eq 0 ]; then
        return
    fi
    return 99
}

case $1 in
start)
    service_start
    ;;
stop) ;;
status)
    for host in $HOST_LIST; do
        service_status $host
        if [ $? -eq 0 ]; then
            echo "Kafka broker in $host is RUNNING"
        else
            echo "Kafka broker in $host is STOPPED"
        fi
    done
    ;;
*) ;;
esac
