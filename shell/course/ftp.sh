#!/bin/bash

FTP_USER="ftpuser"
FTP_PASS="ftpuser1007"
CONF_FILE="/etc/vsftpd/vsftpd.conf"
FTP_LOCAL_ROOT="/data/ftp_sources"

# 防火墙、setlinux 关闭
systemctl stop firewalld 2> /dev/null
# setenforce 0 2> /dev/null

cp ${CONF_FILE} ${CONF_FILE}_bak

echo_conf() {
    check_conf=${1}
    grep "${check_conf}" ${CONF_FILE} || echo "${check_conf}" >> ${CONF_FILE}
}

# 安装 vsftpd 服务
yum install vsftpd -y

# 创建 FTP 登录用户
useradd -s /sbin/nologin ${FTP_USER}
echo "${FTP_PASS}" | passwd --stdin ${FTP_USER}

[[ -d "${FTP_LOCAL_ROOT}" ]] || mkdir -p ${FTP_LOCAL_ROOT}
chown -R ${FTP_USER}.${FTP_USER} ${FTP_LOCAL_ROOT}

# /etc/shells /sbin/nologin
grep "/sbin/nologin" /etc/shells || echo "/sbin/nologin" >> /etc/shells

# 更新 /etc/vsftpd/vsftpd.conf 配置
echo_conf "listen_port=8090"
echo_conf "chroot_local_user=YES"
echo_conf "chroot_list_enable=NO"
echo_conf "allow_writeable_chroot=YES"
echo_conf "userlist_deny=NO"
echo_conf "userlist_file=/etc/vsftpd/user_list"
echo_conf "local_root=/data/ftp_sources"
echo_conf "vsftpd_log_file=/var/log/vsftpd.log"

sed -i 's/^listen=NO/#listen=NO/' ${CONF_FILE}
sed -i 's/^listen_ipv6=/#listen_ipv6=/' ${CONF_FILE}

cp /etc/vsftpd/user_list /etc/vsftpd/user_list_bak
echo "ftpuser" > /etc/vsftpd/user_list

systemctl start vsftpd
