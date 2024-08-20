#!/bin/bash

HOST_LIST="192.168.1.109"

# function service_start {

# }

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
start) ;;
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
