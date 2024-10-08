#!/bin/bash

# 初始化日志文件
if [ -e ./deploy_kafka.log ]; then
    rm -f ./deploy_kafka.log
fi

set -e

exec 1>>./deploy_kafka.log 2>&1

# 初始化变量
HOST_LIST="192.168.1.109"
LOCAL_DIR="/opt/tmp"
PACKAGE_DIR="/opt/package"
APP_DIR="/opt/source"
JDK_NAME="jdk-8u261-linux-x64.tar.gz"
ZK_NAME="apache-zookeeper-3.9.2-bin.tar.gz"
SCALA_NAME="scala3-3.4.2.tar.gz"
KAFKA_NAME="kafka_2.13-3.8.0.tgz"

# 多主机执行指令函数封装
function remote_execute {
    for host in $HOST_LIST; do
        echo "cmd($@) host($host)"

        ssh -o StrictHostKeyChecking=no root@$host $@
        if [ $? -eq 0 ]; then
            echo "cmd($@) success"
        else
            echo "cmd($@) failed"
        fi
    done

    echo
}

# 多主机传输文件函数封装
function remote_transfer {
    SRC_FILE=$1
    DST_DIR=$2

    # 函数必须有 2 个参数，第一个参数是本地文件或目录，第二个参数为远端主机目录
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <file|dir> <dst_dir>"
        exit 1
    fi

    # 判断第 1 个参数是否存在，如果不存在则直接退出并提示给用户
    if [ ! -e $SRC_FILE ]; then
        echo "$SRC_FILE is not exist."
        exit 2
    fi

    for host in $HOST_LIST; do
        echo "transfer file to host($host)"

        # 判断第 2 个参数，远程主机目录是否存在，如果不存在，则创建
        ssh -o StrictHostKeyChecking=no root@$host "if [ ! -e $DST_DIR ]; then mkdir $DST_DIR -p; fi"

        # scp 传输文件
        scp -r -o StrictHostKeyChecking=no $SRC_FILE root@$host:$DST_DIR/
        if [ $? -eq 0 ]; then
            echo "host($host) scp src_file($SRC_FILE) dst_dir($DST_DIR) success"
        else
            echo "host($host) scp src_file($SRC_FILE) dst_dir($DST_DIR) failed"
        fi
    done
}

# 关闭 firewalld 和 setlinux
remote_execute "systemctl stop firewalld"
remote_execute "systemctl disable firewalld"
remote_execute "setenforce 0"
remote_execute "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"

# 安装配置 jdk
remote_transfer $LOCAL_DIR/$JDK_NAME $PACKAGE_DIR
remote_execute "if [ ! -d $APP_DIR ]; then mkdir -p $APP_DIR; fi"
remote_execute "tar zxf $PACKAGE_DIR/$JDK_NAME -C $APP_DIR"

cat >$LOCAL_DIR/java.sh <<EOF
export JAVA_HOME=/opt/source/jdk1.8.0_261
export PATH=\$PATH:\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin
export JAVA_HOME PATH
EOF

remote_transfer $LOCAL_DIR/java.sh /etc/profile.d/
remote_execute "source /etc/profile.d/java.sh"
remote_execute "java -version"

# 安装配置 zookeeper ，并启动服务
remote_transfer $LOCAL_DIR/$ZK_NAME $PACKAGE_DIR
remote_execute "tar zxf $PACKAGE_DIR/$ZK_NAME -C $APP_DIR"

remote_execute "if [ -e $APP_DIR/zookeeper ]; then rm -f $APP_DIR/zookeeper; fi"
remote_execute "ln -sv $APP_DIR/apache-zookeeper-3.9.2-bin $APP_DIR/zookeeper"

remote_execute "cp $APP_DIR/zookeeper/conf/zoo_sample.cfg $APP_DIR/zookeeper/conf/zoo.cfg"

cat >$LOCAL_DIR/zoo_tmp.conf <<EOF
server.1=192.168.1.109:2888:3888
EOF

remote_transfer $LOCAL_DIR/zoo_tmp.conf /tmp
remote_execute "cat /tmp/zoo_tmp.conf >> $APP_DIR/zookeeper/conf/zoo.cfg"

remote_execute "if [ -e /data/zk ]; then rm -rf /data/zk; fi"
remote_execute "mkdir /data/zk -p"
remote_execute "sed -i 's/dataDir=\/tmp\/zookeeper/dataDir=\/data\/zk/g' $APP_DIR/zookeeper/conf/zoo.cfg"

remote_execute 'if [ $(hostname) == "node01" ]; then echo 1 > /data/zk/myid; fi'
remote_execute 'if [ $(hostname) == "node02" ]; then echo 2 > /data/zk/myid; fi'
remote_execute 'if [ $(hostname) == "node03" ]; then echo 3 > /data/zk/myid; fi'

remote_execute "jps | grep QuorumPeerMain | grep -v grep | awk '{print \$1}' > /tmp/zk.pid"
remote_execute 'if [ -s /tmp/zk.pid ]; then kill -9 `cat /tmp/zk.pid`; fi'
remote_execute "$APP_DIR/zookeeper/bin/zkServer.sh start"

# 安装配置 scala 环境
remote_transfer $LOCAL_DIR/$SCALA_NAME $PACKAGE_DIR
remote_execute "tar zxf $PACKAGE_DIR/$SCALA_NAME -C $APP_DIR"

cat >$LOCAL_DIR/scala.sh <<EOF
export SCALA_HOME=$APP_DIR/scala3-3.4.2
export PATH=\$PATH:\$SCALA_HOME/bin
export SCALA_HOME PATH
EOF

remote_transfer $LOCAL_DIR/scala.sh /etc/profile.d/
remote_execute "source /etc/profile.d/scala.sh"
remote_execute "scala -version"

# 安装配置 kafka ，并启动服务
remote_transfer $LOCAL_DIR/$KAFKA_NAME $PACKAGE_DIR
remote_execute "tar zxf $PACKAGE_DIR/$KAFKA_NAME -C $APP_DIR"

remote_execute "if [ -e $APP_DIR/kafka ]; then rm -rf $APP_DIR/kafka; fi"
remote_execute "ln -sv $APP_DIR/kafka_2.13-3.8.0 $APP_DIR/kafka"

remote_execute "if [ -e /data/kafka/log ]; then rm -rf /data/kafka/log; fi"
remote_execute "mkdir -p /data/kafka/log"

remote_execute "sed -i '/zookeeper.connect=localhost:2181/d' $APP_DIR/kafka/config/server.properties"
remote_execute "sed -i '\$azookeeper.connect=192.168.1.109:2181' $APP_DIR/kafka/config/server.properties"

remote_execute "if [ \`hostname\` == "node01" ]; then sed -i 's/broker.id=0/broker.id=100/g' $APP_DIR/kafka/config/server.properties; fi"
remote_execute "if [ \`hostname\` == "node02" ]; then sed -i 's/broker.id=0/broker.id=101/g' $APP_DIR/kafka/config/server.properties; fi"
remote_execute "if [ \`hostname\` == "node03" ]; then sed -i 's/broker.id=0/broker.id=102/g' $APP_DIR/kafka/config/server.properties; fi"

remote_execute "if [ \`hostname\` == "node01" ]; then sed -i '\$alisteners=PLAINTEXT://192.168.1.109:9092' $APP_DIR/kafka/config/server.properties; fi"
remote_execute "if [ \`hostname\` == "node02" ]; then sed -i '\$alisteners=PLAINTEXT://192.168.1.110:9092' $APP_DIR/kafka/config/server.properties; fi"
remote_execute "if [ \`hostname\` == "node03" ]; then sed -i '\$alisteners=PLAINTEXT://192.168.1.111:9092' $APP_DIR/kafka/config/server.properties; fi"

remote_execute "sed -i 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/data\/kafka\/log/g' $APP_DIR/kafka/config/server.properties"

remote_execute "jps | grep Kafka | grep -v grep | awk '{print \$1}' > /tmp/kafka.pid"
remote_execute "if [ -s /tmp/kafka.pid ]; then kill -9 \`cat /tmp/kafka.pid\`; fi"

remote_execute "$APP_DIR/kafka/bin/kafka-server-start.sh -daemon $APP_DIR/kafka/config/server.properties"

sleep 5

remote_execute "if [ \`hostname\` == "node01" ]; then $APP_DIR/kafka/bin/kafka-topics.sh --bootstrap-server 192.168.1.109:9092 --create --topic test --partitions 5 --replication-factor 1; fi"

sleep 5

remote_execute "if [ \`hostname\` == "node01" ]; then $APP_DIR/kafka/bin/kafka-topics.sh --bootstrap-server 192.168.1.109:9092 --describe --topic test; fi"
