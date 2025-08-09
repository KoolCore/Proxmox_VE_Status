#!/bin/bash

set -e

INTERVAL=1
counter=0
log_file="sensors_log.txt"

# 自动安装必要的软件包
install_if_missing() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" &> /dev/null; then
        echo "安装缺失的软件包: $pkg"
        apt install -y "$pkg"
    fi
}

install_if_missing sensors lm-sensors
install_if_missing cpupower linux-cpupower
install_if_missing dmidecode dmidecode

# 获取系统信息
get_system_info() {
    kernel_version=$(uname -r)
    os_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    cpu_info=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2- | xargs)

    system_info=$(sudo dmidecode -t system 2>/dev/null)
    product_name=$(echo "$system_info" | grep "Product Name" | cut -d':' -f2- | xargs)
    serial_number=$(echo "$system_info" | grep "Serial Number" | cut -d':' -f2- | xargs)
    uuid=$(echo "$system_info" | grep "UUID" | cut -d':' -f2- | xargs)
}

# 获取内存信息
get_memory_info() {
    memory_info=$(sudo dmidecode -t memory 2>/dev/null | grep -A16 "Memory Device")
    total_capacity=0
    dimm_count=0
    memory_details=""

    while read -r line; do
        if [[ "$line" == *"Size:"* && "$line" != *"No Module Installed"* ]]; then
            size=$(echo "$line" | grep -o '[0-9]\+')
            total_capacity=$((total_capacity + size))
            dimm_count=$((dimm_count + 1))
            memory_details+="容量: ${size} GB, "
        elif [[ "$line" == *"Manufacturer:"* ]]; then
            manufacturer=$(echo "$line" | cut -d':' -f2- | xargs)
            memory_details+="品牌: $manufacturer, "
        elif [[ "$line" == *"Type:"* && "$line" != *"Unknown"* ]]; then
            type=$(echo "$line" | cut -d':' -f2- | xargs)
            memory_details+="类型: $type\n"
        fi
    done <<< "$memory_info"

    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_usage_percent=$((100 * mem_used / mem_total))

    echo "内存条数量: $dimm_count"
    echo -e "$memory_details"
    echo "总容量: ${total_capacity} GB"
    echo "平均使用率: ${mem_usage_percent}%"
}

# 读取初始 CPU 状态
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
    else
        energy_file=$(find /sys/class/hwmon -name "energy*_input" | head -n 1)
    fi

    if [ -z "$energy_file" ]; then
        echo "N/A"
        return
    fi

    energy_uj_start=$(cat "$energy_file")
    sleep $INTERVAL
    energy_uj_end=$(cat "$energy_file")
    energy_diff=$((energy_uj_end - energy_uj_start))
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
        while read -r line; do
            fan_name=$(echo "$line" | awk '{print $1}')
            fan_speed=$(echo "$line" | awk '{print $2}')
            if [[ "$fan_speed" == "0" || -z "$fan_speed" ]]; then
                printf "%s: 风扇暂停\n" "$fan_name"
            else
                printf "%s\n" "$line"
            fi
        done <<< "$fan_speeds"
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

# 获取一次性系统信息
get_system_info

while true; do
    counter=$((counter + 1))
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    uptime_seconds=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
    uptime_days=$((uptime_seconds / 86400))
    uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
    uptime_minutes=$(( (uptime_seconds % 3600) / 60 ))
    uptime_seconds_rem=$((uptime_seconds % 60))
    uptime_info="${uptime_days}天 ${uptime_hours}小时 ${uptime_minutes}分钟 ${uptime_seconds_rem}秒"

    curr_stat=$(read_cpu_stat)
    curr_idle=$(echo "$curr_stat" | awk '{print $4}')
    curr_total=$(echo "$curr_stat" | awk '{print $1+$2+$3+$4+$5+$6+$7+$8}')
    idle_diff=$((curr_idle - prev_idle))
    total_diff=$((curr_total - prev_total))
    cpu_usage=0
    if [ $total_diff -ne 0 ]; then
        cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
    fi
    prev_idle=$curr_idle
    prev_total=$curr_total

    cpu_freq=$(cpufreq-info -fm 2>/dev/null || grep "cpu MHz" /proc/cpuinfo | awk '{printf "%.2fMHz ", $4}')
    power=$(get_processor_power)
    sensors_output=$(sensors)
    proc_temps=$(echo "$sensors_output" | grep -i 'core' | awk '{print $1, $2, $3, $4}')
    fan_speeds=$(get_fan_speeds)
    net_temps=$(get_net_temp)

    echo -e "\033[H\033[J"
    echo "第 $counter 次测试结果，时间：$timestamp (开机时长: $uptime_info)" 
    echo "=============================================="
    echo "操作系统版本: $os_version"
    echo "内核版本: $kernel_version"
    echo "CPU信息: $cpu_info"
    echo "主机设备名: $product_name"
    echo "主机序列号: $serial_number"
    echo "主机UUID: $uuid"
    echo "----------------------------------------------"
    echo "内存信息:"
    get_memory_info
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
    echo "$fan_speeds"
    echo "=============================================="

    sleep $INTERVAL
done
