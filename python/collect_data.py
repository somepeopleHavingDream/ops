import psutil
import json

# 1 内存使用率 90%
# 2 磁盘使用率 90%
# 3 系统负载 5 分钟的系统负载

def get_data():
    mem = psutil.virtual_memory()
    mem_percent = mem.percent

    disks_info = []
    for part in psutil.disk_partitions():
        device = part.device
        mountpoint = part.mountpoint
        disk_percent = psutil.disk_usage(part.mountpoint).percent
        
        disks_info.append({
            'device': device,
            'mountpoint': mountpoint,
            'disk_percent': disk_percent
        })

    cpu_loadavg = psutil.getloadavg()[1] / psutil.cpu_count()

    return {
        'mem_percent': mem_percent,
        'disks_info': disks_info,
        'cpu_loadavg': cpu_loadavg
    }

data = get_data()
print(json.dumps(data))