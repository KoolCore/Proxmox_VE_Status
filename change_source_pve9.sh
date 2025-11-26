#!/bin/bash

# ============================
# 一键替换 PVE9 / Debian13 源
# 支持：清华 / 中科大 / 阿里
# 自动备份 + 自动检测
# ============================

set -e

echo "=============================="
echo "  PVE9 / Debian13 镜像源替换脚本"
echo "=============================="
echo

# 选择镜像源
echo "请选择镜像源："
echo "1) 清华"
echo "2) 中科大"
echo "3) 阿里"
read -p "请输入数字 [1-3]：" choice

case $choice in
    1)
        DEBIAN_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian/"
        PVE_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve"
        ;;
    2)
        DEBIAN_MIRROR="https://mirrors.ustc.edu.cn/debian/"
        PVE_MIRROR="https://mirrors.ustc.edu.cn/proxmox/debian/pve"
        ;;
    3)
        DEBIAN_MIRROR="http://mirrors.aliyun.com/debian/"
        PVE_MIRROR="http://mirrors.aliyun.com/proxmox/debian/pve"
        ;;
    *)
        echo "输入无效，退出。"
        exit 1
        ;;
esac

echo "你选择的镜像源："
echo "Debian: $DEBIAN_MIRROR"
echo "PVE: $PVE_MIRROR"
echo

# -----------------------------
# 备份原有源
# -----------------------------
echo "备份原有源..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak
mkdir -p /etc/apt/sources.list.d.bak
cp -r /etc/apt/sources.list.d/* /etc/apt/sources.list.d.bak/ 2>/dev/null || true

# -----------------------------
# 替换 Debian 13 sources.list
# -----------------------------
cat >/etc/apt/sources.list <<EOF
deb $DEBIAN_MIRROR trixie main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR trixie-updates main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR trixie-backports main contrib non-free non-free-firmware
deb ${DEBIAN_MIRROR//http:/https:}trixie-security main contrib non-free non-free-firmware
EOF

# -----------------------------
# 替换 PVE 无订阅源
# -----------------------------
cat >/etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb $PVE_MIRROR trixie pve-no-subscription
EOF

# 禁用 PVE 企业源
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
    sed -i 's/^deb/# deb/' /etc/apt/sources.list.d/pve-enterprise.list
fi

# -----------------------------
# 更新缓存
# -----------------------------
echo
echo "更新软件包缓存..."
apt update

# -----------------------------
# 自动检测源是否可用
# -----------------------------
echo
echo "检查镜像源可访问性..."
sources=(
"$DEBIAN_MIRROR"
"$PVE_MIRROR"
)

for url in "${sources[@]}"; do
    echo -n "测试 $url ... "
    if curl -s --head --request GET $url | grep -E "200|301|302" > /dev/null; then
        echo "OK"
    else
        echo "FAILED"
    fi
done

echo
echo "=============================="
echo "  镜像源替换完成！"
echo "  原始源已备份在 sources.list.bak 和 sources.list.d.bak/"
echo "=============================="
