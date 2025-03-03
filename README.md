![](https://github.com/KoolCore/Proxmox_VE_Status/blob/main/pve_status.png)




> 注意:以下代码需要PVE宿主机能流畅访问Github，否则你会遇到各种问题；以下代码推荐在Proxmox VE网页后台的Shell下运行。

#### 修改 PVE 信息栏
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/pve.sh)"
```
***如果发现 `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused` 这种错误，年轻人，你的网络运营商屏蔽了 GitHub。请自行处理网络环境问题。***
大概1-3分钟后，按下`CTRL+F5`强制刷新本页面即可。
代码运行过程会执行软件包更新，可能需要你多次输入`y`以继续执行代码，请保持关注代码执行过程。

#### 开启硬件直通：
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/passthrough.sh)"
```
完成后，PVE 宿主机会自动重启，请耐心等待1~3分钟再通过网页从新进入PVE后台


#### 还原默认信息栏：

```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/restore.sh)"
```

#### 虚拟机

##### 安装 OpenWrt 虚拟机
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/openwrt.sh)"
```
固件为自托管在dl.ikoolcore.com，针对R2 Max适配万兆 AQC113C-B1-C 网卡。理论上 X86 所有设备通用。

##### 安装 Debian 12 虚拟机
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/debian.sh)"
```




#### 其他工具代码（自用性质）

##### 性能测试时，处理器温度，负载，功耗，网卡温度等性能监控工具
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/sensors_logs.sh)"
```
