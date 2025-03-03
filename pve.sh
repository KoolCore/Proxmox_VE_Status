#!/bin/bash

# 检查是否以 root 身份运行
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 权限运行此脚本。"
    exit 1
fi

# 获取 CPU 信息
cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')
cpu_model=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)

# 判断 CPU 平台并设置对应的 IOMMU 参数
if echo "$cpu_model" | grep -q "Intel"; then
    CPU="Intel"
    echo "侦测到本平台为 Intel 平台，正在修改 IOMMU 参数..."
    sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 intel_iommu=on iommu=pt"/' /etc/default/grub
elif echo "$cpu_model" | grep -q "AMD"; then
    CPU="AMD"
    echo "侦测到本平台为 AMD 平台，正在修改 IOMMU 参数..."
    sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 amd_iommu=on iommu=pt"/' /etc/default/grub
else
    echo "抱歉，暂不支持当前 CPU 平台：$cpu_model"
    exit 1
fi

# 更新 GRUB 配置
echo "正在更新 GRUB 配置..."
if ! update-grub; then
    echo "更新 GRUB 配置失败，请检查系统日志。"
    exit 1
fi

# 添加内核模块到加载列表
modules=(vfio vfio_iommu_type1 vfio_pci vfio_virqfd)
for module in "${modules[@]}"; do
    if ! grep -q "^$module" /etc/modules; then
        echo "$module" >> /etc/modules
    fi
done

# 更新内核初始内存盘
echo "正在更新内核初始内存盘..."
if ! update-initramfs -k all -u; then
    echo "更新内核初始内存盘失败，请检查系统日志。"
    exit 1
fi

# 完成提示
echo "脚本运行完成，硬件直通功能已成功启用。"

# 提示用户重启
read -p "是否现在重启系统以应用更改？(y/N): " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "正在重启系统，请稍候..."
    reboot
else
    echo "请手动重启系统以应用更改。"
fi
