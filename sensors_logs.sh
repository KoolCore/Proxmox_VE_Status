#!/bin/bash

set -e

# 设置间隔时间（秒）
INTERVAL=1

# 安装必要的软件包（如已安装则跳过）
which sensors &> /dev/null || apt install -y lm-sensors
which cpupower &> /dev/null || apt install -y linux-cpupower

counter=0
log_file="sensors_log.txt"

# 获取系统信息
kernel_version=$(uname -r)
os_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
cpu_info=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2-)

# 读取初始的 /proc/stat 值
read_cpu_stat() {
    read -r cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    echo "$user $nice $system $idle $iowait $irq $softirq $steal"
}

prev_stat=$(read_cpu_stat)
prev_idle=$(echo "$prev_stat" | awk '{print $4}')
prev_total=$(echo "$prev_stat" | awk '{print $1+$2+$3+$4+$5+$6+$7+$8}')

# 获取处理器功耗
get_processor_power() {
    local energy_file
    if [ -d /sys/class/powercap/intel-rapl ]; then
        energy_file="/sys/class/powercap/intel-rapl:0/energy_uj"
    elif [ -d /sys/class/hwmon ]; then
        energy_file=$(find /sys/class/hwmon -name "energy*_input" | head -n 1)
    else
        echo "N/A"
        return
    fi

    # 获取初始功耗（微焦耳）
    energy_uj_start=$(cat "$energy_file")

    # 等待一段时间
    sleep $INTERVAL

    # 获取第二次功耗
    energy_uj_end=$(cat "$energy_file")
    energy_diff=$((energy_uj_end - energy_uj_start))

    # 计算功耗（瓦特）
    power_W=$(echo "scale=4; $energy_diff / 1000000 / $INTERVAL" | bc)
    echo "$power_W W"
}

# 获取风扇转速
get_fan_speeds() {
    sensors_output=$(sensors)
    fan_speeds=$(echo "$sensors_output" | grep -i 'fan' | awk '{print $1, $2, $3, $4}')

    if [ -z "$fan_speeds" ]; then
        echo "风扇转速: 无风扇信息或传感器不支持"
    else
        local output=""
        while read -r line; do
            fan_name=$(echo "$line" | awk '{print $1}')
            fan_speed=$(echo "$line" | awk '{print $2}')

            # 如果检测到风扇转速为 0 或无数据，则显示 "风扇暂停"
            if [[ "$fan_speed" == "0" || -z "$fan_speed" ]]; then
                output="${output}${fan_name}: 风扇暂停\n"
            else
                output="${output}${line}\n"
            fi
        done <<< "$fan_speeds"

        if [ -z "$output" ]; then
            echo "风扇转速: 无风扇信息或传感器不支持"
        else
            echo -e "$output"
        fi
    fi
}

# 获取网卡温度
get_net_temp() {
    sensors_output=$(sensors)
    net_temps=$(echo "$sensors_output" | grep -i 'temp' | grep -v 'core' | grep -v 'temp1' | awk '{print $1, $2, $3, $4}')

    if [ -z "$net_temps" ]; then
        echo "网卡温度: 此网卡无sensor功能，不支持温度读取"
    else
        echo "$net_temps"
    fi
}

while true; do
    # 更新计数器
    counter=$((counter + 1))
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 获取开机时长
    uptime_seconds=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
    uptime_days=$((uptime_seconds / 86400))
    uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
    uptime_minutes=$(( (uptime_seconds % 3600) / 60 ))
    uptime_seconds_rem=$((uptime_seconds % 60))
    uptime_info="${uptime_days}天 ${uptime_hours}小时 ${uptime_minutes}分钟 ${uptime_seconds_rem}秒"
    
    # 计算 CPU 使用率
    curr_stat=$(read_cpu_stat)
    curr_idle=$(echo "$curr_stat" | awk '{print $4}')
    curr_total=$(echo "$curr_stat" | awk '{print $1+$2+$3+$4+$5+$6+$7+$8}')

    idle_diff=$((curr_idle - prev_idle))
    total_diff=$((curr_total - prev_total))
    cpu_usage=0
    if [ $total_diff -ne 0 ]; then
        cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
    fi

    # 更新上次数据
    prev_idle=$curr_idle
    prev_total=$curr_total
    
    # 获取处理器频率
    cpu_freq=$(cpufreq-info -fm 2>/dev/null || grep "cpu MHz" /proc/cpuinfo | awk '{printf "%.2fMHz ", $4}')

    # 获取处理器功耗
    power=$(get_processor_power)

    # 获取温度信息
    sensors_output=$(sensors)
    proc_temps=$(echo "$sensors_output" | grep -i 'core' | awk '{print $1, $2, $3, $4}')

    # 获取风扇转速
    fan_speeds=$(get_fan_speeds)

    # 获取网卡温度
    net_temps=$(get_net_temp)

    # 优化屏幕刷新，减少闪烁
    echo -e "\033[H\033[J"
    echo "第 $counter 秒测试结果，时间：$timestamp (开机时长: $uptime_info)"
    echo "=============================================="
    echo "操作系统版本: $os_version"
    echo "内核版本: $kernel_version"
    echo "CPU信息: $cpu_info"
    echo "----------------------------------------------"
    echo "处理器实时频率: $cpu_freq"
    echo "处理器实时负载: $cpu_usage%"
    echo "----------------------------------------------"
    echo "处理器功耗: $power"
    echo "----------------------------------------------"
    echo "处理器核心温度:"
    echo "$proc_temps"
    echo "----------------------------------------------"
    echo "网卡温度:"
    echo "$net_temps"
    echo "----------------------------------------------"
    echo "风扇转速:"
    echo -e "$fan_speeds"
    echo "=============================================="

    sleep $INTERVAL
done
