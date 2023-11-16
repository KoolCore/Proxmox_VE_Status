#!/bin/bash

# 获取 CPU 型号
cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')

# 判断 CPU 型号并设置相应的参数
cpu_platform="$(lscpu | grep 'Model name' | grep -E 'Intel|AMD')"
case $cpu_platform in
    *Intel*)
    # 如果是 Intel CPU
          CPU="Intel"
          echo "侦测到本平台为 Intel 平台,正在修改IOMMU参数..."
          sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"/' /etc/default/grub
          ;;
    *AMD*)
     # 如果是 AMD CPU
          CPU="AMD"
          echo "侦测到本平台为 AMD 平台,正在修改IOMMU参数..."   
          sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"/' /etc/default/grub
          ;;
    *)
          echo -e "抱歉,暂不支持当前CPU平台!"
          ;;
esac

# 更新 grub
echo "正在更新 GRUB 内核参数..."
update-grub

# 加载内核模块
echo "正在加载内核模块..."
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# 更新内核参数
echo "正在更新内核参数..."
update-initramfs -k all -u

echo "脚本运行完成，已成功开启硬件直通功能."

echo "正在执行重启...请等待1-3分钟..."
reboot