![](https://github.com/KoolCore/Proxmox_VE_Status/blob/main/pve_status.png)



### 一、使用方法：
> 注意:需要使用root身份执行下面代码，以下代码在Proxmox VE网页后台的Shell下运行（默认是root用户了）

#### 修改PVE状态栏
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/pve.sh)"
```
大概1-3分钟后，按下`CTRL+F5`强制刷新本页面即可。如果发现 `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused` 这种错误，年轻人，你的网络运营商屏蔽了 GitHub。请自行处理网络环境问题。

#### 开启硬件直通：
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/passthrough.sh)"
```



#### 还原状态栏：

运行以下四条命令（适用于已经改过概要信息，还原成默认的概要信息）：
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/KoolCore/Proxmox_VE_Status/refs/heads/main/restore.sh)"
```

