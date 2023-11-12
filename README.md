<hr>

#### 一、安装方法：

> 注意:需要使用`root`身份执行下面代码，以下代码在Proxmox VE网页后台的Shell下运行（默认是root用户了）

1. 更新当前Proxmox VE软件包；

   ```
   export LC_ALL=en_US.UTF-8
   apt update && apt upgrade -y
   ```

   

2. 安装git和wget服务；

   ```
   apt install -y wget git
   ```

3. 执行脚本，开始添加信息面板；

   ```
   git clone https://github.com/iKoolCore/Proxmox_VE_Status.git
   ```

   或<br>

   ```
   wget https://github.com/iKoolCore/Proxmox_VE_Status
   ```

4. 进入脚本命令行所在目录并执行脚本;

   ```
   cd Proxmox_VE_Status
   bash ./Proxmox_VE_Status.sh
   ```

大概1-3分钟后，按下`CTRL+F5`强制刷新本页面即可。如果发现 `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused` 这种错误，年轻人，你的网络运营商屏蔽了 GitHub。请自行处理网络环境问题。

#### 二、还原方法：

运行以下四条命令（适用于已经改过概要信息，还原成默认的概要信息）：
```
sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy
```

