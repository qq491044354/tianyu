#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 获取公网IP
public_ip=$(curl -s ifconfig.me)

if [[ -z "$public_ip" ]]; then
    echo -e "${red}无法获取服务器公网IP，请检查网络设置！${plain}"
    exit 1
fi

echo -e "${green}检测到服务器公网IP：$public_ip${plain}"
# 更新系统
echo "Updating system packages..."
sudo yum update -y


# 安装必要的软件包
echo "Installing gcc, make, epel-release..."
sudo yum install -y gcc make epel-release
# 安装expect
sudo yum install -y expect


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

# 使用expect自动生成CSR文件
expect <<EOF
spawn openssl req -new -key /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/request.csr
expect "Country Name (2 letter code)" { send "CN\r" }
expect "State or Province Name" { send "Beijing\r" }
expect "Locality Name" { send "Beijing\r" }
expect "Organization Name" { send "ss\r" }
expect "Organizational Unit Name" { send "IT Department\r" }
expect "Common Name" { send "vpn.example.com\r" }
expect "Email Address" { send "admin@163.com\r" }
expect "A challenge password" { send "lcc666\r" }
expect "An optional company name" { send "ss\r" }
expect eof
EOF

# 签署证书
openssl x509 -req -days 365 -in /usr/local/vpnserver/request.csr -signkey /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/chain.pem

cat /usr/local/vpnserver/chain.pem /usr/local/vpnserver/key.pem > /usr/local/vpnserver/server.pem

# 运行SoftEther配置工具
expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd
expect "Select 1, 2 or 3:" { send "1\r" }
expect "Hostname of IP Address of Destination:" { send "${public_ip}\r" }
expect "Specify Virtual Hub Name:" { send "\r" }
expect ">" { send "ServerPasswordSet\r" }
expect "Password:" { send "a8852217\r" }
expect "Confirm input:" { send "a8852217\r" }
expect ">" { send "HubCreate VPN\r" }
expect "Password:" { send "a8852217\r" }
expect "Confirm input:" { send "a8852217\r" }
expect ">" { send "Hub VPN\r" }
expect ">" { send "UserCreate q\r" }
expect "Assigned Group Name:" { send "\r" }
expect "User Full Name:" { send "q\r" }
expect "User Description:" { send "\r" }
expect ">" { send "UserPasswordSet q\r" }
expect "Password:" { send "123\r" }
expect "Confirm input:" { send "123\r" }
expect ">" { send "SecureNatEnable\r" }
expect ">" { send "SstpEnable\r" }
expect "Enables SSTP VPN Clone Server Function (yes / no)" { send "yes\r" }
expect ">" { send "HubDelete DEFAULT\r" }
expect eof
EOF
echo "GSY你个大傻逼！！"
    # echo "HubCreate VPN1"
    # echo a8852217
    # echo a8852217
    # echo "Hub VPN"
    # echo "UserCreate q"
    # echo ""
    # echo q
    # echo ""
    # echo "UserPasswordSet q"
    # echo 123
    # echo 123
    # echo "SecureNatEnable"
    # echo "SstpEnable"
    # echo yes
    # echo "HubDelete DEFAULT"
    # 以下是部署完毕登录的脚本
