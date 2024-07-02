"""
自动化运维实战
1 采集数据 psutil
2 下发脚本、远程执行 paramiko
3 数据检查并入库 pymysql

"""

from http import client
import json
import sys
import paramiko
import traceback


THRESHOLD = 80.0
color_mapping = {
    'red': 31,
    'green': 32,
    'yellow': 33
}


def print_color(msg, color='red'):
    print('\033[%dm%s\033[0m' % (color_mapping[color], msg))


def check_threshold(host, key, val):
    if key.endswith('percent') and val > THRESHOLD:
        print_color('节点 %s 上 %s 告警，超过告警 %.2f, 实际值为：%.2f' % (host, key, THRESHOLD, val))


def judge_data(data):
    host = data['host']

    for key in data:
        if isinstance(data[key], list):
            for i in range(len(data[key])):
                for inner_key in data[key][i]:
                    # 比较和阈值的大小
                    check_threshold(host, inner_key, data[key][i][inner_key])
        else:
            check_threshold(host, key, data[key])


class Connection:

    def __init__(self, host, port, user, password) -> None:
        self.host = host
        self.port = int(port) if port else 22
        self.user = user
        self.password = password

        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.WarningPolicy)
        self.ssh = ssh

        # 远程连接
        self.connected = False
        self.connect()


    def connect(self):
        if self.connected:
            return
        
        try:
            self.ssh.connect(self.host, self.port, self.user, self.password)

            sftp = self.ssh.open_sftp()
            self.sftp = sftp

            self.connected = True    
        except Exception as e:
            print('Caught exception: %s:%s' % (e.__class__, e))
            traceback.print_exc()
            try:
                client.close()
            except:
                pass
            sys.exit()


    def run(self, cmd):
        chan = self.ssh.get_transport().open_session()
        chan.exec_command(cmd)

        stdout = "".join(chan.makefile('r'))
        stderr = "".join(chan.makefile_stderr('r'))

        return chan.recv_exit_status(), stdout, stderr
    

    def put(self, src_path, dest_path):
        return self.sftp.put(src_path, dest_path)


hosts = ['hadoop000']
# hosts = ['hadoop000', 'hadoop001', 'hadoop002']
port = 22
user = 'root'
password = '123456'
script_name = 'collect_data.py'

for host in hosts:
    conn = Connection(host, port, user, password)
    print('与节点{}的连接情况：{}'.format(host, conn.connected))
    if conn.connected:
        conn.run('rm -f /tmp/{}'.format(script_name))
        print('上传文件 %s 到节点 %s ...' % (script_name, host))
        conn.put(script_name, '/tmp/{}'.format(script_name))

        run_cmd = 'python /tmp/{}'.format(script_name)
        print('远程执行命令： %s' % run_cmd)

        ret, out, err = conn.run(run_cmd)
        if not ret:
            collect_data = json.loads(out.strip())
            collect_data['host'] = host
            print('在节点 {} 上执行采集脚本，输出：{}'.format(host, json.dumps(collect_data)))

            judge_data(collect_data)
