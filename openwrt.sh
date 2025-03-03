#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
#         Jon Spriggs (jontheniceguy)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Based on work from https://i12bretro.github.io/tutorials/0405.html
# Based on work form https://community-scripts.github.io/ProxmoxVE/scripts?id=openwrt

source /dev/stdin <<< $(wget -qLO - https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)

function header_info {
  clear
  cat <<"EOF"
   ____                 _       __     __
  / __ \____  ___  ____| |     / /____/ /_
 / / / / __ \/ _ \/ __ \ | /| / / ___/ __/
/ /_/ / /_/ /  __/ / / / |/ |/ / /  / /_
\____/ .___/\___/_/ /_/|__/|__/_/   \__/
    /_/ W I R E L E S S   F R E E D O M

EOF
}
header_info
echo -e "加载中..."
#API VARIABLES
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
NSAPP="OpenWRT - VM "
var_os="OpenWRT"
var_version=" "
DISK_SIZE="1.0G"
#
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
GEN_MAC_LAN=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
NEXTID=$(pvesh get /cluster/nextid)
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
HA=$(echo "\033[1;34m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
set -Eeo pipefail
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "INTERRUPTED"' SIGINT 
trap 'post_update_to_api "failed" "TERMINATED"' SIGTERM
function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  post_update_to_api "failed" "$command"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function cleanup_vmid() {
  if qm status $VMID &>/dev/null; then
    qm stop $VMID &>/dev/null
    qm destroy $VMID &>/dev/null
  fi
}

function cleanup() {
  popd >/dev/null
  rm -rf $TEMP_DIR
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null
function send_line_to_vm() {
  echo -e "${DGN}发送代码: ${YW}$1${CL}"
  for ((i = 0; i < ${#1}; i++)); do
    character=${1:i:1}
    case $character in
    " ") character="spc" ;;
    "-") character="minus" ;;
    "=") character="equal" ;;
    ",") character="comma" ;;
    ".") character="dot" ;;
    "/") character="slash" ;;
    "'") character="apostrophe" ;;
    ";") character="semicolon" ;;
    '\') character="backslash" ;;
    '`') character="grave_accent" ;;
    "[") character="bracket_left" ;;
    "]") character="bracket_right" ;;
    "_") character="shift-minus" ;;
    "+") character="shift-equal" ;;
    "?") character="shift-slash" ;;
    "<") character="shift-comma" ;;
    ">") character="shift-dot" ;;
    '"') character="shift-apostrophe" ;;
    ":") character="shift-semicolon" ;;
    "|") character="shift-backslash" ;;
    "~") character="shift-grave_accent" ;;
    "{") character="shift-bracket_left" ;;
    "}") character="shift-bracket_right" ;;
    "A") character="shift-a" ;;
    "B") character="shift-b" ;;
    "C") character="shift-c" ;;
    "D") character="shift-d" ;;
    "E") character="shift-e" ;;
    "F") character="shift-f" ;;
    "G") character="shift-g" ;;
    "H") character="shift-h" ;;
    "I") character="shift-i" ;;
    "J") character="shift-j" ;;
    "K") character="shift-k" ;;
    "L") character="shift-l" ;;
    "M") character="shift-m" ;;
    "N") character="shift-n" ;;
    "O") character="shift-o" ;;
    "P") character="shift-p" ;;
    "Q") character="shift-q" ;;
    "R") character="shift-r" ;;
    "S") character="shift-s" ;;
    "T") character="shift-t" ;;
    "U") character="shift-u" ;;
    "V") character="shift-v" ;;
    "W") character="shift-w" ;;
    "X") character="shift=x" ;;
    "Y") character="shift-y" ;;
    "Z") character="shift-z" ;;
    "!") character="shift-1" ;;
    "@") character="shift-2" ;;
    "#") character="shift-3" ;;
    '$') character="shift-4" ;;
    "%") character="shift-5" ;;
    "^") character="shift-6" ;;
    "&") character="shift-7" ;;
    "*") character="shift-8" ;;
    "(") character="shift-9" ;;
    ")") character="shift-0" ;;
    esac
    qm sendkey $VMID "$character"
  done
  qm sendkey $VMID ret
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

if (whiptail --title "OpenWrt 虚拟机" --yesno "这将会进行 OpenWRT 创建工作. 开始?" 10 58); then
  :
else
  header_info && echo -e "⚠ 用户退出脚本 \n" && exit
fi

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

function pve_check() {
  if ! pveversion | grep -Eq "pve-manager/8\.[1-3](\.[0-9]+)*"; then
    msg_error "PVE 版本不支持"
    echo -e "需要PVE版本在8.1以上."
    echo -e "退出..."
    sleep 2
    exit
fi
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${CROSS} 脚本无法与 PiMox 兼容! \n"
    echo -e "退出..."
    sleep 2
    exit
  fi
}

function ssh_check() {
  if command -v pveversion >/dev/null 2>&1; then
    if [ -n "${SSH_CLIENT:+x}" ]; then
      if whiptail --defaultno --title "侦测到 SSH 连接" --yesno "建议在网页端的 PVE 后台 Shell 下运行，不建议通过 SSH 连接后进行代码运行。继续使用 SSH 运行代码?" 10 62; then
        echo "已警告和提醒用户"
      else
        clear
        exit
      fi
    fi
  fi
}

function exit-script() {
  clear
  echo -e "⚠  用户退出脚本 \n"
  exit
}

function default_settings() {
  VMID=$NEXTID
  HN= OpenWRT
  CORE_COUNT="1"
  RAM_SIZE="1024"
  BRG="vmbr0"
  VLAN=""
  MAC=$GEN_MAC
  LAN_MAC=$GEN_MAC_LAN
  LAN_BRG="vmbr0"
  LAN_IP_ADDR="192.168.1.1"
  LAN_NETMASK="255.255.255.0"
  LAN_VLAN=",tag=999"
  MTU=""
  START_VM="yes"
  METHOD="default"
  echo -e "${DGN}虚拟机 ID: ${BGN}${VMID}${CL}"
  echo -e "${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${DGN}设置核心数: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${DGN}分配内存: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${DGN}WAN Bridge: ${BGN}${BRG}${CL}"
  echo -e "${DGN}WAN VLAN: ${BGN}Default${CL}"
  echo -e "${DGN}WAN MAC 地址: ${BGN}${MAC}${CL}"
  echo -e "${DGN}LAN MAC 地址: ${BGN}${LAN_MAC}${CL}"
  echo -e "${DGN}LAN Bridge: ${BGN}${LAN_BRG}${CL}"
  echo -e "${DGN}LAN VLAN: ${BGN}999${CL}"
  echo -e "${DGN}设置LAN IP 后台管理地址: ${BGN}${LAN_IP_ADDR}${CL}"
  echo -e "${DGN}设置LAN 子网掩码: ${BGN}${LAN_NETMASK}${CL}"
  echo -e "${DGN}设置 MTU: ${BGN}Default${CL}"
  echo -e "${DGN}部署完毕后开启虚拟机: ${BGN}yes${CL}"
  echo -e "${BL}使用上述配置创建OpenWRT虚拟机${CL}"
}

function advanced_settings() {
  METHOD="高级配置"
  while true; do
    if VMID=$(whiptail --inputbox "设置虚拟机 ID" 8 58 $NEXTID --title "虚拟机 ID" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
      if [ -z "$VMID" ]; then
        VMID="$NEXTID"
      fi
      if pct status "$VMID" &>/dev/null || qm status "$VMID" &>/dev/null; then
        echo -e "${CROSS}${RD} ID $VMID 已被使用，请更换${CL}"
        sleep 2
        continue
      fi
      echo -e "${DGN}虚拟机 ID: ${BGN}$VMID${CL}"
      break
    else
      exit-script
    fi
  done

  if VM_NAME=$(whiptail --inputbox "设置 Hostname" 8 58 openwrt --title "HOSTNAME" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $VM_NAME ]; then
      HN="OpenWRT"
    else
      HN=$(echo ${VM_NAME,,} | tr -d ' ')
    fi
    echo -e "${DGN}Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --inputbox "分配 CPU 核心数" 8 58 1 --title "核心数" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $CORE_COUNT ]; then
      CORE_COUNT="1"
    fi
    echo -e "${DGN}设置核心数: ${BGN}$CORE_COUNT${CL}"
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --inputbox "分配 RAM（MiB）" 8 58 256 --title "内存大小" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $RAM_SIZE ]; then
      RAM_SIZE="1024"
    fi
    echo -e "${DGN}分配内存: ${BGN}$RAM_SIZE${CL}"
  else
    exit-script
  fi

  if BRG=$(whiptail --inputbox "设置 WAN Bridge" 8 58 vmbr0 --title "WAN BRIDGE" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $BRG ]; then
      BRG="vmbr0"
    fi
    echo -e "${DGN}WAN Bridge: ${BGN}$BRG${CL}"
  else
    exit-script
  fi

  if LAN_BRG=$(whiptail --inputbox "设置 LAN Bridge" 8 58 vmbr0 --title "LAN BRIDGE" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $LAN_BRG ]; then
      LAN_BRG="vmbr0"
    fi
    echo -e "${DGN}LAN Bridge: ${BGN}$LAN_BRG${CL}"
  else
    exit-script
  fi

  if LAN_IP_ADDR=$(whiptail --inputbox "设置 OpenWRT 的后台管理 IP 地址" 8 58 $LAN_IP_ADDR --title "LAN IP ADDRESS" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $LAN_IP_ADDR ]; then
      LAN_IP_ADDR="192.168.1.1"
    fi
    echo -e "${DGN}设置LAN IP 后台管理地址: ${BGN}$LAN_IP_ADDR${CL}"
  else
    exit-script
  fi

  if LAN_NETMASK=$(whiptail --inputbox "设置子网掩码" 8 58 $LAN_NETMASK --title "LAN NETMASK" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $LAN_NETMASK ]; then
      LAN_NETMASK="255.255.255.0"
    fi
    echo -e "${DGN}设置LAN 子网掩码: ${BGN}$LAN_NETMASK${CL}"
  else
    exit-script
  fi

  if MAC1=$(whiptail --inputbox "设置 WAN MAC 地址" 8 58 $GEN_MAC --title "WAN MAC 地址" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $MAC1 ]; then
      MAC="$GEN_MAC"
    else
      MAC="$MAC1"
    fi
    echo -e "${DGN}Using WAN MAC 地址: ${BGN}$MAC${CL}"
  else
    exit-script
  fi

  if MAC2=$(whiptail --inputbox "设置 LAN MAC 地址" 8 58 $GEN_MAC_LAN --title "LAN MAC 地址" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $MAC2 ]; then
      LAN_MAC="$GEN_MAC_LAN"
    else
      LAN_MAC="$MAC2"
    fi
    echo -e "${DGN}设置 LAN MAC 地址: ${BGN}$LAN_MAC${CL}"
  else
    exit-script
  fi

  if VLAN1=$(whiptail --inputbox "设置 WAN Vlan（建议留空以默认配置进行）" 8 58 --title "WAN VLAN" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $VLAN1 ]; then
      VLAN1="Default"
      VLAN=""
    else
      VLAN=",tag=$VLAN1"
    fi
    echo -e "${DGN}设置 WAN Vlan: ${BGN}$VLAN1${CL}"
  else
    exit-script
  fi

  if VLAN2=$(whiptail --inputbox "设置 LAN Vlan" 8 58 999 --title "LAN VLAN" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $VLAN2 ]; then
      VLAN2="999"
      LAN_VLAN=",tag=$VLAN2"
    else
      LAN_VLAN=",tag=$VLAN2"
    fi
    echo -e "${DGN}设置LAN Vlan: ${BGN}$VLAN2${CL}"
  else
    exit-script
  fi

  if MTU1=$(whiptail --inputbox "设置MTU (建议留空以默认配置进行)" 8 58 --title "MTU 大小" --cancel-button 退出脚本 3>&1 1>&2 2>&3); then
    if [ -z $MTU1 ]; then
      MTU1="Default"
      MTU=""
    else
      MTU=",mtu=$MTU1"
    fi
    echo -e "${DGN}设置 MTU: ${BGN}$MTU1${CL}"
  else
    exit-script
  fi

  if (whiptail --title "开启虚拟机" --yesno "完成后启动虚拟机?" 10 58); then
    START_VM="yes"
  else
    START_VM="no"
  fi
  echo -e "${DGN}完成后启动虚拟机: ${BGN}$START_VM${CL}"

  if (whiptail --title "高阶设置" --yesno "开始创建 OpenWRT 虚拟机?" --no-button 从新配置 10 58); then
    echo -e "${RD}使用上述配置创建OpenWRT虚拟机${CL}"
  else
    header_info
    echo -e "${RD}使用高级设置项${CL}"
    advanced_settings
  fi
}

function start_script() {
  if (whiptail --title "设置" --yesno "使用默认设置?" --no-button Advanced 10 58); then
    header_info
    echo -e "${BL}使用默认配置${CL}"
    default_settings
  else
    header_info
    echo -e "${RD}使用高级配置${CL}"
    advanced_settings
  fi
}

arch_check
pve_check
ssh_check
start_script
post_to_api_vm

msg_info "检查存储"
while read -r line; do
  TAG=$(echo $line | awk '{print $1}')
  TYPE=$(echo $line | awk '{printf "%-10s", $2}')
  FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
  ITEM="  Type: $TYPE Free: $FREE "
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  STORAGE_MENU+=("$TAG" "$ITEM" "OFF")
done < <(pvesm status -content images | awk 'NR>1')
VALID=$(pvesm status -content images | awk 'NR>1')
if [ -z "$VALID" ]; then
  echo -e "\n${RD}⚠ 未侦测到有效存储.${CL}"
  echo -e "退出..."
  exit
elif [ $((${#STORAGE_MENU[@]} / 3)) -eq 1 ]; then
  STORAGE=${STORAGE_MENU[0]}
else
  while [ -z "${STORAGE:+x}" ]; do
    STORAGE=$(whiptail --title "存储池" --radiolist \
      "你想在哪个存储池创建OpenWRT虚拟机?\n\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3) || exit
  done
fi
msg_ok "使用 ${CL}${BL}$STORAGE${CL} ${GN}作为存储位置."
msg_ok "虚拟机 ID： ${CL}${BL}$VMID${CL}."
msg_info "从 iKOOLCORE 处获取最新的 OpenWRT 镜像文件（你可修改代码中的相关URL）..."

response=$(curl -s https://dl.ikoolcore.com)
URL="https://dl.ikoolcore.com/dl/OpenWrt%20Firmware/R2Max/QWRT-R25.01.23-x86-64-generic-squashfs-combined-efi.img.gz"

sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
wget -q --show-progress $URL
echo -en "\e[1A\e[0K"
FILE=$(basename $URL)
msg_ok "下载 ${CL}${BL}$FILE${CL}"
gunzip -f $FILE >/dev/null 2>/dev/null || true
NEWFILE="${FILE%.*}"
FILE="$NEWFILE"
mv $FILE ${FILE%.*}
qemu-img resize -f raw ${FILE%.*} 2048M >/dev/null 2>/dev/null
msg_ok "解压和重新设置 OpenWRT 镜像 ${CL}${BL}$FILE${CL}"
STORAGE_TYPE=$(pvesm status -storage $STORAGE | awk 'NR>1 {print $2}')
case $STORAGE_TYPE in
nfs | dir)
  DISK_EXT=".qcow2"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format qcow2"
  ;;
btrfs)
  DISK_EXT=".raw"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format raw"
  ;;
esac
for i in {0,1}; do
  disk="DISK$i"
  eval DISK${i}=vm-${VMID}-disk-${i}${DISK_EXT:-}
  eval DISK${i}_REF=${STORAGE}:${DISK_REF:-}${!disk}
done

msg_info "正在创建 OpenWRT 虚拟机..."
qm create $VMID -cores $CORE_COUNT -memory $RAM_SIZE -name $HN \
  -onboot 1 -ostype l26 -scsihw virtio-scsi-pci --tablet 0
pvesm alloc $STORAGE $VMID $DISK0 4M 1>&/dev/null
qm importdisk $VMID ${FILE%.*} $STORAGE ${DISK_IMPORT:-} 1>&/dev/null
qm set $VMID \
  -efidisk0 ${DISK0_REF},efitype=4m,size=4M \
  -scsi0 ${DISK1_REF},size=2048M \
  -boot order=scsi0 \
  
msg_ok "OpenWRT 虚拟机已创建！ ${CL}${BL}(${HN})"
msg_info "OpenWRT 正在重启..."
qm start $VMID
sleep 15
msg_ok "即将开始配置网络接口："
send_line_to_vm ""
send_line_to_vm "uci delete network.@device[0]"
send_line_to_vm "uci set network.wan=interface"
send_line_to_vm "uci set network.wan.device=eth1"
send_line_to_vm "uci set network.wan.proto=dhcp"
send_line_to_vm "uci delete network.lan"
send_line_to_vm "uci set network.lan=interface"
send_line_to_vm "uci set network.lan.device=eth0"
send_line_to_vm "uci set network.lan.proto=static"
send_line_to_vm "uci set network.lan.ipaddr=${LAN_IP_ADDR}"
send_line_to_vm "uci set network.lan.netmask=${LAN_NETMASK}"
send_line_to_vm "uci commit"
send_line_to_vm "halt"
msg_ok "网络接口配置信息已成功配置"
until qm status $VMID | grep -q "stopped"; do
  sleep 2
done
msg_info "尝试添加网桥设置"
qm set $VMID \
  -net0 virtio,bridge=${LAN_BRG},macaddr=${LAN_MAC}${LAN_VLAN}${MTU} \
  -net1 virtio,bridge=${BRG},macaddr=${MAC}${VLAN}${MTU} >/dev/null 2>/dev/null
msg_ok "网桥接口已成功设置."
if [ "$START_VM" == "yes" ]; then
  msg_info "尝试开启 OpenWrt 虚拟机"
  qm start $VMID
  msg_ok "OpenWrt 虚拟机已成功开启"
fi
VLAN_FINISH=""
if [ "$VLAN" == "" ] && [ "$VLAN2" != "999" ]; then
  VLAN_FINISH=" 请适当修正 VLAN 设置以符合你的家庭局域网设置."
fi
post_update_to_api "完成" "none"
msg_ok "已成功创建 OpenWRT虚拟机!\n${VLAN_FINISH}"
