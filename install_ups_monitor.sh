#!/bin/bash
#
# 一键安装 UPS 监控脚本（支持安装时输入 UPS IP）
#

# ===============================================
# 1. 输入 UPS IP
# ===============================================
echo "请输入 UPS 的 IP 地址（例如 10.0.0.1）："
read -p "UPS IP: " UPS_IP

# 如果用户未输入内容则退出
if [ -z "$UPS_IP" ]; then
    echo "错误：UPS IP 不能为空！安装中止。"
    exit 1
fi

echo "你输入的 UPS IP 为：$UPS_IP"
echo ""

# ===============================================
# 2. 定义路径
# ===============================================
UPS_DIR="/var/ups"               # UPS 脚本与日志目录
UPS_SCRIPT="$UPS_DIR/ups.sh"     # 主脚本
LOGFILE="$UPS_DIR/ups.log"       # 日志文件路径

echo "=== 创建目录 $UPS_DIR ==="
mkdir -p $UPS_DIR


# ===============================================
# 3. 生成 UPS 监控脚本（带中文注释）
# ===============================================
echo "=== 创建 UPS 监控脚本 $UPS_SCRIPT ==="
cat > $UPS_SCRIPT <<EOF
#!/bin/bash

# ================================
# UPS 监控脚本（自动生成）
# 功能说明：
# 1. 每 60 秒 Ping UPS 一次
# 2. 如果连续 5 次不通 → 自动关机
# 3. 每天 00:00 自动清空日志
# ================================

IP="$UPS_IP"                  # UPS 的 IP（由安装脚本输入）
LOGFILE="$LOGFILE"            # 日志文件路径
FAIL_COUNT=0                  # 连续失败次数

while true; do
    # ---------------------------------------------------------
    # 每天 00 点清空日志
    # ---------------------------------------------------------
    if [ "\$(date +%H)" -eq 0 ]; then
        > "\$LOGFILE"
    fi

    # ---------------------------------------------------------
    # ping UPS -c 1（发送一次 ICMP 包）
    # ---------------------------------------------------------
    if ping -c 1 "\$IP" > /dev/null; then
        echo "\$(date): UPS ready" >> "\$LOGFILE"
        FAIL_COUNT=0
    else
        echo "\$(date): UPS work" >> "\$LOGFILE"
        ((FAIL_COUNT++))

        # 失败次数达到 5 次 → 自动关机
        if [ \$FAIL_COUNT -ge 5 ]; then
            echo "\$(date): Poweroff" >> "\$LOGFILE"
            /sbin/poweroff
        fi
    fi

    # 等待 60 秒再检测下一次
    sleep 60
done
EOF


# ===============================================
# 4. 设置执行权限
# ===============================================
echo "=== 赋予执行权限 ==="
chmod +x $UPS_SCRIPT


# ===============================================
# 5. 写入 crontab，实现开机启动
# ===============================================
echo "=== 写入 crontab 开机启动 ==="

# 过滤掉以前的旧配置，避免重复
crontab -l | grep -v "$UPS_SCRIPT" > /tmp/cron_tmp

# 添加开机自动运行
echo "@reboot $UPS_SCRIPT" >> /tmp/cron_tmp

# 保存 crontab
crontab /tmp/cron_tmp
rm /tmp/cron_tmp


# ===============================================
# 6. 重启 cron 服务生效
# ===============================================
echo "=== 重启 cron 服务 ==="
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null


# ===============================================
# 7. 完成提示
# ===============================================
echo "=== 安装完成！==="
echo "UPS 监控脚本路径：$UPS_SCRIPT"
echo "日志文件路径：$LOGFILE"
echo "-----------------------------------"
echo "查看日志：      cat $LOGFILE"
echo "实时查看日志：  tail -f $LOGFILE"
echo "清空日志：      truncate -s 0 $LOGFILE"
echo "-----------------------------------"
echo "脚本将在下次开机时自动运行。"
