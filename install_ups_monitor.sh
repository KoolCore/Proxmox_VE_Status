#!/bin/bash
#
# 一键安装 UPS 监控脚本（交互式菜单版本）
#

clear
echo "=============================================="
echo "         UPS 监控脚本安装工具（交互版）"
echo "=============================================="
echo "此工具将帮助你自动创建 UPS 检测脚本并实现开机自启。"
echo ""

# ===============================================
# 1. UPS IP 输入（带菜单）
# ===============================================
echo "请选择内网中未连接至UPS的任一设备的 IP 地址："
echo "  1) 使用默认值：10.0.0.1"
echo "  2) 手动输入 IP"
echo ""

read -p "请输入选项（1-2）： " ip_choice

if [ "$ip_choice" = "1" ]; then
    UPS_IP="10.0.0.1"
elif [ "$ip_choice" = "2" ]; then
    read -p "请输入 UPS IP 地址： " UPS_IP
    if [ -z "$UPS_IP" ]; then
        echo "错误：IP 不能为空！安装中止。"
        exit 1
    fi
else
    echo "错误：无效选项，安装中止。"
    exit 1
fi

echo ""
echo "✔ 请选择内网中未连接至UPS的任一设备的 IP 地址已设置为：$UPS_IP"
echo ""


# ===============================================
# 2. 设置检测间隔（默认 60 秒）
# ===============================================
read -p "请输入检测间隔（秒），按回车使用默认值 60： " INTERVAL
INTERVAL=${INTERVAL:-60}

echo "✔ 检测间隔：$INTERVAL 秒"
echo ""


# ===============================================
# 3. 设置连续失败次数（默认 5 次）
# ===============================================
read -p "请输入连续失败次数，按回车使用默认值 5： " FAIL_LIMIT
FAIL_LIMIT=${FAIL_LIMIT:-5}

echo "✔ 连续失败次数：$FAIL_LIMIT"
echo ""


# ===============================================
# 4. 确认配置
# ===============================================
echo "================= 配置确认 ================="
echo " 检测内网中未连接至UPS的任一设备的 IP 地址：         $UPS_IP"
echo " 检测间隔：            $INTERVAL 秒"
echo " 连续失败关机阈值：    $FAIL_LIMIT 次"
echo "============================================"
echo ""
read -p "确认安装？ (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "安装已取消。"
    exit 0
fi


# ===============================================
# 5. 定义路径
# ===============================================
UPS_DIR="/var/ups"
UPS_SCRIPT="$UPS_DIR/ups.sh"
LOGFILE="$UPS_DIR/ups.log"

echo ""
echo "=== 创建目录 $UPS_DIR ==="
mkdir -p $UPS_DIR


# ===============================================
# 6. 创建 ups.sh 主脚本（带中文注释）
# ===============================================
echo "=== 生成 UPS 监控脚本 ==="

cat > $UPS_SCRIPT <<EOF
#!/bin/bash
#
# UPS 监控脚本（自动生成）
#

IP="$UPS_IP"                   # UPS 的 IP 地址
LOGFILE="$LOGFILE"             # 日志文件
INTERVAL=$INTERVAL             # 检测间隔（秒）
FAIL_LIMIT=$FAIL_LIMIT         # 连续失败次数达到此值 → 关机
FAIL_COUNT=0                   # 当前连续失败次数计数器

while true; do
    # 每天 00:00 自动清空日志
    if [ "\$(date +%H)" -eq 0 ]; then
        > "\$LOGFILE"
    fi

    # 尝试 ping UPS 一次
    if ping -c 1 "\$IP" > /dev/null; then
        echo "\$(date): UPS ready" >> "\$LOGFILE"
        FAIL_COUNT=0
    else
        echo "\$(date): UPS unreachable" >> "\$LOGFILE"
        ((FAIL_COUNT++))

        # 如果连续失败次数达到限制则关机
        if [ \$FAIL_COUNT -ge \$FAIL_LIMIT ]; then
            echo "\$(date): UPS offline too long, system poweroff" >> "\$LOGFILE"
            /sbin/poweroff
        fi
    fi

    # 等待设定的时间再检测
    sleep \$INTERVAL
done
EOF


# ===============================================
# 7. 设置权限
# ===============================================
echo "=== 设置执行权限 ==="
chmod +x $UPS_SCRIPT


# ===============================================
# 8. 写入 crontab
# ===============================================
echo "=== 写入 crontab 开机启动 ==="

crontab -l | grep -v "$UPS_SCRIPT" > /tmp/cron_tmp
echo "@reboot $UPS_SCRIPT" >> /tmp/cron_tmp
crontab /tmp/cron_tmp
rm /tmp/cron_tmp


# ===============================================
# 9. 重启 cron
# ===============================================
echo "=== 重启 cron 服务 ==="
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null


# ===============================================
# 10. 完成提示
# ===============================================
echo "=============================================="
echo "           ✔ 安装完成！"
echo "=============================================="
echo "UPS 监控脚本路径：$UPS_SCRIPT"
echo "日志文件路径：    $LOGFILE"
echo ""
echo "查看日志：        cat $LOGFILE"
echo "实时日志：        tail -f $LOGFILE"
echo "清空日志：        truncate -s 0 $LOGFILE"
echo ""
echo "脚本将在下次开机时自动运行。"
echo "=============================================="
