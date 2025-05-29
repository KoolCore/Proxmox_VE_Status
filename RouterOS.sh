#!/bin/bash
#官方脚本 https://help.mikrotik.com/docs/display/ROS/CHR+ProxMox+installation
#执行 vim install_ros.sh , 复制粘贴下列信息后，:wq 退出并保存
#chmod +x install_ros.sh & bash install_ros.sh

# 默认配置参数
DEFAULT_MEMORY=2048       # 默认内存大小(MB)
DEFAULT_DISK_EXPAND=5     # 默认增加的磁盘空间(GB)
DEFAULT_CPU_SOCKETS=1     # 默认CPU插槽数
DEFAULT_CPU_CORES=4       # 默认CPU核心数
DEFAULT_ONBOOT="yes"      # 默认开机启动设置

# 检查是否安装了unzip，如果没有则安装
if ! command -v unzip &> /dev/null
then
    echo "未找到unzip，正在安装..."
    apt-get update
    apt-get install unzip -y
fi

echo "############## 开始脚本 ##############"

#获取最新RouterOS稳定版下载地址
download_link=$(curl -s https://download.mikrotik.com/routeros/latest-stable.rss | \
    awk '/<item>/{p=1;next} p&&/<link>/{gsub(/^[ \t]+/,"");print;exit}' | \
    sed 's/<link>\(.*\)<\/link>/\1/')
echo "最新RouterOS稳定版下载链接: $download_link"

#获取RouterOS新版版本号
last_version=$(echo "$download_link" | sed -n 's/.*v=\([0-9.]*\).*/\1/p')
echo "最新RouterOS稳定版版本: $last_version"

## 检查TEMP目录是否可用..."
if [ -d /root/temp ]
then
    echo "-- TEMP下载目录已存在！"
else
    echo "-- 建立TEMP下载目录！"
    mkdir /root/temp
fi

echo "## 准备ROS_CHR image文件下载和VM虚拟机创建！"
# 询问用户版本，默认使用新版本号
version=$last_version
read -p "是否下载最新版本RouterOS Chr？ (Y=最新版/n=指定版本): " confirm
if [[ ${confirm,,} == "n" ]]; then
    read -p "请输入Chr版本以部署（6.38.2,6.40.1等）： " user_version
    version=$user_version
fi
echo "选择的RouterOS Chr版本为: $version"

# 配置虚拟机资源参数
echo ""
echo "## 配置虚拟机资源参数"
read -p "内存大小(MB) [$DEFAULT_MEMORY]: " memory
memory=${memory:-$DEFAULT_MEMORY}

read -p "除RouterOS系统外的磁盘空间(GB) [$DEFAULT_DISK_EXPAND]: " disk_expand
disk_expand=${disk_expand:-$DEFAULT_DISK_EXPAND}

read -p "CPU插槽数 [$DEFAULT_CPU_SOCKETS]: " cpu_sockets
cpu_sockets=${cpu_sockets:-$DEFAULT_CPU_SOCKETS}

read -p "每个插槽的CPU核心数 [$DEFAULT_CPU_CORES]: " cpu_cores
cpu_cores=${cpu_cores:-$DEFAULT_CPU_CORES}

read -p "开机自动启动 (yes/no) [$DEFAULT_ONBOOT]: " onboot
onboot=${onboot:-$DEFAULT_ONBOOT}

echo "-- 配置参数确认:"
echo "   内存: $memory MB"
echo "   增加磁盘空间: $disk_expand GB"
echo "   CPU插槽数: $cpu_sockets"
echo "   CPU核心数: $cpu_cores"
echo "   开机启动: $onboot"
echo ""

# 检查image文件是否需要下载
if [ -f /root/temp/chr-$version.img ]
then
    echo "-- CHR $version image文件已存在."
else
    echo "-- 下载CHR $version image文件."
    cd /root/temp
    echo "---------------------------------------------------------------------------"
    wget https://download.mikrotik.com/routeros/$version/chr-$version.img.zip
    unzip chr-$version.img.zip
    echo "---------------------------------------------------------------------------"
fi

# 列出已存在的VM虚拟机
vmID="nil"
echo "== 列出已存在的VM虚拟机列表！"
qm list
echo ""

# 反复请求输入直到得到有效的VM ID
while true; do
    read -p "请输入未使用的VM ID（例如：101）：" vmID
    
    # 检查输入是否为空
    if [ -z "$vmID" ]; then
        echo "错误：VM ID不能为空，请重新输入"
        continue
    fi
    
    # 检查输入是否为数字
    if ! [[ "$vmID" =~ ^[0-9]+$ ]]; then
        echo "错误：VM ID必须是数字，请重新输入"
        continue
    fi
    
    # 为VM创建存储目录
    if [ -d /var/lib/vz/images/$vmID ]; then
        echo "错误：VM ID $vmID 已存在，请选择其他ID"
        continue
    else
        echo "-- 建立VM虚拟机文件夹! "
        mkdir /var/lib/vz/images/$vmID
        break
    fi
done

# 转换映像重命名
echo "-- 将image转换为qcow2格式 "
qemu-img convert \
    -f raw \
    -O qcow2 \
    /root/temp/chr-$version.img \
    /var/lib/vz/images/$vmID/vm-$vmID-disk-0.qcow2

echo "-- 增加加映像容量"
# 增加映像大小 根据用户配置调整
qemu-img resize -f qcow2 /var/lib/vz/images/$vmID/vm-$vmID-disk-0.qcow2 +${disk_expand}G

echo "-- 查看映像信息"
# 查看映像信息
qemu-img info /var/lib/vz/images/$vmID/vm-$vmID-disk-0.qcow2

# 先确认系统中可用的存储区域
echo "-- 检查可用的存储区域"
pvesm status

# 询问用户选择支持images的存储区域
read -p "请输入支持VM磁盘映像的存储区域名称(通常为local-lvm): " storage_name
if [ -z "$storage_name" ]; then
    storage_name="local-lvm"  # 默认使用local-lvm
    echo "未输入，使用默认存储区域：$storage_name"
fi

# 创建虚拟机（不包含磁盘）
echo "-- 建立新的CHR虚拟机"
qm create $vmID \
  --name ROS-chr-$version \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26 \
  --memory $memory \
  --onboot $onboot \
  --sockets $cpu_sockets \
  --cores $cpu_cores

# 导入磁盘到选择的存储
echo "-- 导入磁盘到存储 $storage_name"
IMPORT_RESULT=$(qm importdisk $vmID /var/lib/vz/images/$vmID/vm-$vmID-disk-0.qcow2 $storage_name)
echo "$IMPORT_RESULT"

# 从导入结果获取磁盘ID
DISK_ID=$(echo "$IMPORT_RESULT" | grep -oP 'unused\d+' | head -1 | sed 's/unused//')
if [ -z "$DISK_ID" ]; then
    # 如果无法从输出中获取，则使用默认值
    echo "-- 无法从导入结果获取磁盘ID，将使用默认值"
    DISK_ID="0"
fi
echo "-- 导入的磁盘ID: $DISK_ID"

# 配置虚拟机使用导入的磁盘
echo "-- 将磁盘附加到虚拟机并设置为启动盘"
qm set $vmID --virtio0 $storage_name:vm-$vmID-disk-$DISK_ID
qm set $vmID --bootdisk virtio0

# 设置正确的启动顺序，确保从磁盘启动而非网络启动
echo "-- 配置虚拟机启动设置"
qm set $vmID --boot c --bootdisk virtio0
qm set $vmID --serial0 socket --vga serial0

# 关闭网络引导以防止iPXE启动问题
qm set $vmID --boot order=virtio0

# 检查虚拟机是否建立成功
if [ $? -eq 0 ]; then
    echo "虚拟机创建成功！"
else
    echo "虚拟机创建失败！请检查设置并手动进行调整。"
fi

echo "############## 脚本结束 ##############"
