<hr>


![](https://github.com/KoolCore/Proxmox_VE_Status/blob/main/Proxmox_VE_Status.png)



### 一、安装方法：
> 注意:需要使用root身份执行下面代码，以下代码在Proxmox VE网页后台的Shell下运行（默认是root用户了）


1. 更新当前Proxmox VE软件包：
```
export LC_ALL=en_US.UTF-8
apt update && apt upgrade -y
```

2. 安装git和wget服务：
```
apt install git wget 
```

3. git拉取脚本：
```
git clone https://github.com/KoolCore/Proxmox_VE_Status.git
```

4. 进入脚本命令行所在目录：
```
cd Proxmox_VE_Status
```

5. 执行脚本
```
bash ./Proxmox_VE_Status_zh.sh
```

6. 执行硬件直通脚本：
```
bash ./passthrough.sh
```

大概1-3分钟后，按下`CTRL+F5`强制刷新本页面即可。如果发现 `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused` 这种错误，年轻人，你的网络运营商屏蔽了 GitHub。请自行处理网络环境问题。


#### 二、还原方法：

运行以下四条命令（适用于已经改过概要信息，还原成默认的概要信息）：
```shell
sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy
```





<hr>

#### Installation
> Note: You need to run the following codes as root. The codes below are run in the Shell of Proxmox VE web UI (root user by default).

1. Update the current Proxmox VE packages:
```
export LC_ALL=en_US.UTF-8
apt update && apt upgrade -y
```

2. Install git and wget services:
```
apt install git wget
```

3. Clone the script with git:
```
git clone https://github.com/KoolCore/Proxmox_VE_Status.git
```

4. Go to the directory where the script is located:

```
cd Proxmox_VE_Status
```

5. Run the script:
```
bash ./Proxmox_VE_Status_en.sh
```

6. Run the passthrough script:

```
bash ./passthrough.sh
```

After about 1-3 minutes, press CTRL+F5 to force refresh the page. If you encounter an error like `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused`, Please resolve network environment issues yourself.

#### Restore
Run the following four commands (applicable to the summary information that has been changed, restore to the default summary information):

```
Shell
sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy
```
