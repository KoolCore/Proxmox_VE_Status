<hr>


![](https://github.com/KoolCore/Proxmox_VE_Status/blob/main/Proxmox_VE_Status.png)




#### 一、安装方法：

> 注意:需要使用`root`身份执行下面代码，以下代码在Proxmox VE网页后台的Shell下运行（默认是root用户了）

1. 更新当前Proxmox VE软件包；

   ```shell
   export LC_ALL=en_US.UTF-8
   apt update && apt upgrade -y
   ```

   

2. 安装git和wget服务；

   ```shell
   apt install -y wget git
   ```

3. 执行脚本，开始添加信息面板；

   ```shell
   git clone https://github.com/KoolCore/Proxmox_VE_Status.git
   ```

4. 进入脚本命令行所在目录并执行脚本;

   ```shell
   cd Proxmox_VE_Status
   bash ./Proxmox_VE_Status_zh.sh
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

#### Section 1: Installation Instructions:

> Note: Execute the following code with `root` privileges. The code below should be run in the Shell of the Proxmox VE web interface (default user is root).

1. Update the current Proxmox VE packages;

   ```shell
   export LC_ALL=en_US.UTF-8
   apt update && apt upgrade -y

2. Install the git and wget services;

   ```shell
   apt install -y wget git
   ```

3. Execute the script to begin adding the information panel;

   ```shell
   git clone https://github.com/KoolCore/Proxmox_VE_Status.git
   ```

4. Navigate to the directory containing the script and execute it;

   ```shell
   cd Proxmox_VE_Status
   bash ./Proxmox_VE_Status_en.sh
   ```

After approximately 1-3 minutes, press `CTRL+F5` to force-refresh this page. If you encounter an error like `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused`, your network service provider might be blocking GitHub. Please resolve any network environment issues on your own.



#### Section 2: Restoration Method:

Run the following four commands (applicable if you have modified the summary information and want to restore it to the default):

```shell
sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy
```

