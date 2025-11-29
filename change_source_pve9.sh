#!/bin/bash

# ============================
# 一键替换 PVE9 / Debian13 源
# 支持：清华 / 中科大 / 阿里 / 官方
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
echo "4) 官方源"
echo "5) 退出"
read -p "请输入数字 [1-5]：" choice

case $choice in
    1)
        DEBIAN_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian/"
        DEBIAN_SEC_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian-security/"
        PVE_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve"
        CEPH_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/ceph-squid"
        ;;
    2)
        DEBIAN_MIRROR="https://mirrors.ustc.edu.cn/debian/"
        DEBIAN_SEC_MIRROR="https://mirrors.ustc.edu.cn/debian-security/"
        PVE_MIRROR="https://mirrors.ustc.edu.cn/proxmox/debian/pve"
        CEPH_MIRROR="https://mirrors.ustc.edu.cn/proxmox/debian/ceph-squid"
        ;;
    3)
        DEBIAN_MIRROR="https://mirrors.aliyun.com/debian/"
        DEBIAN_SEC_MIRROR="https://mirrors.aliyun.com/debian-security/"
        PVE_MIRROR="http://mirrors.aliyun.com/proxmox/debian/pve"
        CEPH_MIRROR="http://mirrors.aliyun.com/proxmox/debian/ceph-squid"
        ;;
    4)
        DEBIAN_MIRROR="https://deb.debian.org/debian/"
        DEBIAN_SEC_MIRROR="https://deb.debian.org/debian-security/"
        PVE_MIRROR="http://download.proxmox.com/debian/pve"
        CEPH_MIRROR="http://download.proxmox.com/debian/ceph-squid"
        ;;
    5)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "输入无效，退出。"
        exit 1
        ;;
esac

echo "你选择的镜像源："
echo "Debian: $DEBIAN_MIRROR"
echo "Debian-Security: $DEBIAN_SEC_MIRROR"
echo "PVE: $PVE_MIRROR"
echo "Ceph: $CEPH_MIRROR"
echo

# -----------------------------
# 备份原有源
# -----------------------------
echo "备份原有源..."
timestamp=$(date "+%Y%m%dT%H%M%S")
[ -f /etc/apt/sources.list ] && mv -f /etc/apt/sources.list /etc/apt/sources.list.$timestamp.bak
mkdir -p /etc/apt/sources.list.d.$timestamp.bak 2>/dev/null
mv -f /etc/apt/sources.list.d/* /etc/apt/sources.list.d.$timestamp.bak/ 2>/dev/null || true

# -----------------------------
# 替换 Debian 13 源
# -----------------------------
cat > /etc/apt/sources.list.d/debian.sources <<- EOF
Types: deb
URIs: $DEBIAN_MIRROR
Suites: trixie
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $DEBIAN_MIRROR
Suites: trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb
# URIs: $DEBIAN_MIRROR
# Suites: trixie-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $DEBIAN_SEC_MIRROR
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# -----------------------------
# 替换 PVE 无订阅源
# -----------------------------
cat > /etc/apt/sources.list.d/proxmox.sources <<- EOF
Types: deb
URIs: $PVE_MIRROR
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# 禁用 PVE 企业源
cat > /etc/apt/sources.list.d/pve-enterprise.sources <<- EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
[ -f /etc/apt/sources.list.d/pve-enterprise.sources ] && mv -f /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.bak

# -----------------------------
# 替换 Ceph 无订阅源
# -----------------------------
cat > /etc/apt/sources.list.d/ceph.sources <<- EOF
Types: deb
URIs: $CEPH_MIRROR
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# 禁用 Ceph 企业源
cat > /etc/apt/sources.list.d/ceph-enterprise.sources <<- EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
[ -f /etc/apt/sources.list.d/ceph-enterprise.sources ] && mv -f /etc/apt/sources.list.d/ceph-enterprise.sources /etc/apt/sources.list.d/ceph-enterprise.sources.bak

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
"$DEBIAN_SEC_MIRROR"
"$PVE_MIRROR"
"$CEPH_MIRROR"
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
echo "  原始源已备份在 sources.list.$timestamp.bak"
echo "  和 sources.list.d.$timestamp.bak/"
echo "=============================="
