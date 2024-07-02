"""
运维常用模块 pymysql
"""

from pymysql.connections import Connection

# 安装 pip install pymysql

# 创建连接
conn = Connection(host = '127.0.0.1', port = 3306, user = 'root', password = '123456', database = 'myblog')

# 获取游标
cursor = conn.cursor()
print('cursor object = {}'.format(cursor))

# 执行操作（SQL）
res = cursor.execute('select * from blog')
print('受影响行数：', res)
print('获取全部结果：{}'.format(cursor._rows))

# 关闭连接
cursor.close()
conn.close()