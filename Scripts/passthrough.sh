#!/bin/bash

# 获取 CPU 型号
cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')

# 判断 CPU 型号并设置相应的参数
if [ "$cpu_vendor" == "GenuineIntel" ]; then
    echo "Detected Intel CPU."
    # 如果是 Intel CPU
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"/' /etc/default/grub
elif [ "$cpu_vendor" == "AuthenticAMD" ]; then
    echo "Detected AMD CPU."
    # 如果是 AMD CPU
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"/' /etc/default/grub
    # 如果需要显卡直通，添加额外的参数
    # sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt video=vesafb:off video=efifb:off video=simplefb:off"/' /etc/default/grub
else
    echo "Unsupported CPU vendor: $cpu_vendor"
    exit 1
fi

# 更新 grub
echo "Updating GRUB..."
update-grub

# 加载内核模块
echo "Loading kernel modules..."
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# 更新内核参数
echo "Updating kernel parameters..."
update-initramfs -k all -u

echo "Script completed successfully."
