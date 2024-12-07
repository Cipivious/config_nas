#!/bin/bash

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 用户运行此脚本。"
   exit 1
fi

# 关闭防火墙
echo "正在安装并禁用 UFW 防火墙..."
apt update
apt install -y ufw
ufw disable

# 安装 ddns-go
echo "正在安装 ddns-go..."
if [[ -f "./ddns-go.tar.gz" ]]; then
   echo "检测到 ddns-go 安装包，正在使用本地文件..."
   tar -zxvf ./ddns-go.tar.gz -C /usr/local/bin
   /usr/local/bin/ddns-go -s install
   echo "ddns-go 已安装。请访问 http://127.0.0.1:9876 配置域名服务商。"
else
   echo "未找到 ddns-go 安装包，请将 ddns-go 的压缩包（ddns-go.tar.gz）放在脚本所在目录后重新运行。"
   exit 1
fi

# 安装 SSH 服务器
echo "正在安装 OpenSSH 服务器..."
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
echo "OpenSSH 服务器已启动。"

# 配置 Samba
echo "正在安装和配置 Samba..."
apt install -y samba
USER_HOME=$(eval echo "~$SUDO_USER")

cat <<EOL >> /etc/samba/smb.conf

[SharedHome]
path = $USER_HOME
browseable = yes
read only = no
guest ok = no
valid users = $SUDO_USER
EOL

# 设置用户主目录的访问权限
chmod 755 $USER_HOME
systemctl restart smbd
echo "Samba 已配置，共享目录为用户的主目录 $USER_HOME。"

# 提示用户配置 Windows 网络硬盘
echo "在 Windows 中，可以通过 \\<你的域名或IP地址>\SharedHome 访问共享文件夹。"

# 让用户手动输入 Samba 密码
echo "为用户 $SUDO_USER 配置 Samba 密码..."
smbpasswd -a "$SUDO_USER"

echo "配置完成！你现在可以在 Windows 上访问共享文件夹，使用用户名 '$SUDO_USER' 和密码进行登录。"
