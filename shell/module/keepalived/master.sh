ip=$(hostname -I | awk '{print $1}')
dt=$(date +'%Y%m%d %H:%M:%S')
echo "$0--${ip}--${dt}" >> /tmp/kp.log