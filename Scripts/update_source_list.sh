#!/bin/bash

# Step 1: 设置软件包仓库国内源
echo "Setting up software repository..."

# 备份原始 sources.list 文件
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 编辑 sources.list 文件
cat <<EOL > /etc/apt/sources.list
# debian aliyun source
deb https://mirrors.aliyun.com/debian buster main contrib non-free
deb https://mirrors.aliyun.com/debian buster-updates main contrib non-free
deb https://mirrors.aliyun.com/debian-security buster/updates main contrib non-free

# proxmox source
deb https://mirrors.ustc.edu.cn/proxmox/debian/pve buster pve-no-subscription
EOL

# 更新软件包信息
apt-get update

# Step 2: 去除 Proxmox 企业版更新源
echo "Removing Proxmox enterprise repository..."

# 备份原始 pve-enterprise.list 文件
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak

# 或者直接删除 pve-enterprise.list 文件
# rm -rf /etc/apt/sources.list.d/pve-enterprise.list

echo "Script completed successfully."

# 更新软件包
apt update