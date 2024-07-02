"""
paramiko 模块实战2 远程执行命令并获取结果
"""

import paramiko
import sys
import traceback

hostname = 'hadoop000'
port = 22
username = 'root'
password = '123456'

try:
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.WarningPolicy)

    print('*** Connecting...')
    ssh.connect(hostname, port, username, password)
    # channel 对象
    chan = ssh.get_transport().open_session()

    cmd = "cat /etc/hosts | grep `hostname` | awk '{print $1}'"
    chan.exec_command(cmd)

    # 192.168.126.140
    stdout = "".join(chan.makefile('r'))
    stderr = "".join(chan.makefile_stderr('r'))

    print('返回状态码：{}'.format(chan.recv_exit_status()))
    print('正确输出：{}'.format(stdout))
    print('错误输出：{}'.format(stderr))
except Exception as e:
    print('*** Caught exception: %s: %s' % (e.__class__, e))
    traceback.print_exc()
    try:
        ssh.close()
    except:
        pass
    sys.exit(1)