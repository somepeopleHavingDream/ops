"""
paramiko 模块实战3 远程文件操作
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
   
    sftp = ssh.open_sftp()
    dirlist = sftp.listdir('/root')
    print('Dirlist: %s' % dirlist)
except Exception as e:
    print('*** Caught exception: %s: %s' % (e.__class__, e))
    traceback.print_exc()
    try:
        ssh.close()
    except:
        pass
    sys.exit(1)