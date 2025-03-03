#!/bin/bash

set -e

# 设置间隔时间（秒）
INTERVAL=1

# 检查并安装必要的软件包
check_and_install_package() {
    local package_name=$1
    if ! dpkg -l | grep -q "$package_name"; then
        echo "$package_name 未安装，正在安装..."
        sudo apt-get update
        sudo apt-get install -y "$package_name"
    else
        echo "$package_name 已安装"
    fi
}

# 检查并安装 cpupower 和 lm-sensors
check_and_install_package "cpupower"
check_and_install_package "lm-sensors"
check_and_install_package "linux-cpupower"

counter=0
log_file="sensors_log.txt"

# 获取系统信息
kernel_version=$(uname -r)
os_version=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
cpu_info=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2-)

# 读取初始的 /proc/stat 值
read -r cpu user nice system idle iowait irq softirq steal guest < /proc/stat
prev_idle=$idle
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

# 获取处理器功耗
get_processor_power() {
    # 获取初始功耗（单位：微焦耳）
    energy_uj_start=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

    # 等待一段时间（间隔）
    sleep $INTERVAL

    # 获取第二次功耗（单位：微焦耳）
    energy_uj_end=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

    # 计算功耗差值（单位：微焦耳）
    energy_diff=$((energy_uj_end - energy_uj_start))

    # 转换为瓦特（功耗单位为瓦特，1瓦特 = 1焦耳/秒）
    power_W=$(echo "scale=4; $energy_diff / 1000000" | bc)

    echo "$power_W W"
}

# 获取处理器功耗
get_intel_power() {
    if [ -d /sys/class/powercap/intel-rapl ]; then
        # 获取处理器功耗
        power=$(get_processor_power)
        echo "$power"
    else
        echo "无法获取功耗数据（Intel RAPL）"
    fi
}

while true; do
    # 每次输出结果前，保持之前的输出并覆盖更新部分
    counter=$((counter + 1))
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 获取开机时长
    uptime_seconds=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
    uptime_days=$((uptime_seconds / 86400))
    uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
    uptime_minutes=$(( (uptime_seconds % 3600) / 60 ))
    uptime_info="${uptime_days}天 ${uptime_hours}小时 ${uptime_minutes}分钟"
    
    # 获取当前的 /proc/stat 值
    read -r cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    idle_diff=$((idle - prev_idle))
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    total_diff=$((total - prev_total))
    
    # 防止除零错误
    if [ $total_diff -ne 0 ]; then
        cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
    else
        cpu_usage=0
    fi
    
    # 更新 prev_idle 和 prev_total
    prev_idle=$idle
    prev_total=$total
    
    # 获取处理器温度和网卡温度
    sensors_output=$(sensors)
    
    # 提取处理器核心温度
    proc_temps=$(echo "$sensors_output" | grep -i 'core' | awk '{print $1, $2, $3, $4}')
    
    # 提取网卡温度，排除包含 'temp1' 的行
    net_temps=$(echo "$sensors_output" | grep -i 'temp' | grep -v 'core' | grep -v 'temp1' | awk '{print $1, $2, $3, $4}')
    
    # 获取处理器实时频率
    cpu_freq=$(grep "cpu MHz" /proc/cpuinfo | awk '{printf "%.2fMHz ", $4}')
    
    # 获取处理器功耗（Intel RAPL）
    power=$(get_intel_power)

    # 使用光标控制进行局部更新，避免闪烁
    echo -e "\033[H\033[J"  # 清空终端屏幕并将光标移动到最上面
    echo "第 $counter 秒测试结果，时间：$timestamp (开机时长: $uptime_info)"
    echo "=============================================="
    echo "操作系统版本: $os_version"
    echo "内核版本: $kernel_version"
    echo "CPU信息: $cpu_info"
    echo "----------------------------------------------"
    echo "处理器实时频率: $cpu_freq  "
    echo "----------------------------------------------"
    echo "处理器实时负载: $cpu_usage%  "
    echo "----------------------------------------------"
    echo "处理器功耗: $power"
    echo "----------------------------------------------"
    echo "处理器核心温度:"
    echo "$proc_temps"
    echo "----------------------------------------------"
    echo "网卡温度:"
    echo "$net_temps"
    echo "=============================================="
    
    # 注释掉将结果写入日志文件的代码
    # {
    #     echo "第 $counter 秒测试结果，时间：$timestamp (开机时长: $uptime_info)"
    #     echo "=============================================="
    #     echo "操作系统版本: $os_version"
    #     echo "内核版本: $kernel_version"
    #     echo "CPU信息: $cpu_info"
    #     echo "----------------------------------------------"
    #     echo "处理器实时频率: $cpu_freq  "
    #     echo "处理器实时负载: $cpu_usage%  "
    #     echo "----------------------------------------------"
    #     echo "处理器功耗: $power"
    #     echo "----------------------------------------------"
    #     echo "处理器核心温度:"
    #     echo "$proc_temps"
    #     echo "----------------------------------------------"
    #     echo "网卡温度:"
    #     echo "$net_temps"
    #     echo "=============================================="
    #     echo ""
    # } >> "$log_file"
    
    sleep $INTERVAL
done
