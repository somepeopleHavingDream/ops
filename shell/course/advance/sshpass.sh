#!/bin/bash

host_list="192.168.1.109"
user_name=root
user_pass=redhat

for host in $host_list; do
    sshpass -p $user_pass ssh -o StrictHostKeyChecking=no $user_name@$host "$1"
done