#!/bin/bash

# 更新系统
echo "Updating system packages..."
sudo yum update -y

# 安装必要的软件包
echo "Installing gcc, make, and epel-release..."
sudo yum install -y gcc make epel-release

# 下载并解压SoftEther VPN Server
SOFTETHER_VERSION="4.43-9799-beta-2023.08.31"
FILE_NAME="softether-vpnserver-v${SOFTETHER_VERSION}-linux-x64-64bit.tar.gz"

wget https://www.softether-download.com/files/softether/v${SOFTETHER_VERSION}-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/${FILE_NAME}

tar xzvf ${FILE_NAME}

# 编译VPN Server
cd vpnserver
make

# 移动并设置权限
cd ..
sudo mv vpnserver /usr/local
cd /usr/local/vpnserver

sudo chmod 600 *
sudo chmod 700 vpncmd vpnserver

# 安装nano
sudo yum install -y nano

# 创建vpnserver.service文件
echo "Creating vpnserver.service..."
sudo tee /etc/systemd/system/vpnserver.service > /dev/null <<EOL
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
ExecReload=/usr/local/vpnserver/vpnserver restart
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
sudo systemctl status vpnserver
sudo /usr/local/vpnserver/vpnserver start

# 安装OpenSSL并生成证书
sudo yum install -y openssl

openssl genrsa -out /usr/local/vpnserver/key.pem 2048

# 生成CSR文件，等待用户输入
openssl req -new -key /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/request.csr

# 提示用户输入内容
echo "Country Name (2 letter code) [AU]: CN"
echo "State or Province Name (full name) [Some-State]: Beijing"
echo "Locality Name (eg, city) []: Beijing"
echo "Organization Name (eg, company) [Internet Widgits Pty Ltd]: ss"
echo "Organizational Unit Name (eg, section) []: IT Department"
echo "Common Name (e.g. server FQDN or YOUR name) []: vpn.example.com"
echo "Email Address []: admin@163.com"
echo "A challenge password []: lcc666"
echo "An optional company name []: ss"

# 签署证书
openssl x509 -req -days 365 -in /usr/local/vpnserver/request.csr -signkey /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/chain.pem

cat /usr/local/vpnserver/chain.pem /usr/local/vpnserver/key.pem > /usr/local/vpnserver/server.pem

# 运行SoftEther配置工具
{
    echo 1
    echo 47.238.102.11
    echo "ServerPasswordSet"
    echo a8852217
    echo a8852217
    echo "HubCreate VPN"
    echo a8852217
    echo a8852217
    echo "Hub VPN"
    echo "UserCreate q"
    echo ""
    echo q
    echo ""
    echo "UserPasswordSet q"
    echo 123
    echo 123
    echo "SecureNatEnable"
    echo "SstpEnable"
    echo yes
    echo "HubDelete DEFAULT"
} | sudo /usr/local/vpnserver/vpncmd

echo "SoftEther VPN Server installation and configuration completed successfully."
