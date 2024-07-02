"""
运维常用模块之-request
"""

# 关于 urllib3 的一个简单使用
# python3 和 python2 写法有区别
from urllib.parse import urlparse
import urllib3

test_url = "http://192.168.1.107/"

# parsed = urlparse(test_url)
# pool_manager = urllib3.PoolManager()
# req_url = parsed.geturl()
# conn = pool_manager.connection_from_url(req_url)
# resp = conn.urlopen('GET', test_url)
# print('请求状态码={}，请求结果={}'.format(resp.status, resp.data))

# request 模块
import requests
response = requests.get(test_url)
print('requests 请求结果：{}, {}'.format(response.status_code, response.text))