ip=$(ip addr | grep 192.168 | awk '{print $2}')
dt=$(date +'%Y%m%d %H:%M:%S')
echo "$0--${ip}--${dt}" >> /tmp/kp.log