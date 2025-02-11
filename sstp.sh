#!/bin/bash


# 更新系统
sudo yum update -y

# 安装必要的软件包
sudo yum install -y gcc make epel-release

# 下载SoftEther VPN Server
wget https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz

# 解压下载的文件
tar xzvf softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz

# 进入vpnserver目录并编译
cd vpnserver
make

# 移动vpnserver到/usr/local目录
cd ..
sudo mv vpnserver /usr/local

# 设置权限
cd /usr/local/vpnserver
sudo chmod 600 *
sudo chmod 700 vpncmd vpnserver

# 安装nano编辑器
sudo yum install -y nano

# 创建systemd服务文件
sudo nano /etc/systemd/system/vpnserver.service <<EOF
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
EOF

# 重新加载systemd并启用服务
sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
sudo systemctl status vpnserver
sudo /usr/local/vpnserver/vpnserver start

# 安装OpenSSL
sudo yum install -y openssl

# 生成私钥
openssl genrsa -out /usr/local/vpnserver/key.pem 2048

# 生成CSR文件
openssl req -new -key /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/request.csr <<EOF
CN
Beijing
Beijing
ss
IT Department
vpn.example.com
admin@163.com
lcc666
ss
EOF

# 生成签名证书
openssl x509 -req -days 365 -in /usr/local/vpnserver/request.csr -signkey /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/chain.pem

# 合并证书和私钥
cat /usr/local/vpnserver/chain.pem /usr/local/vpnserver/key.pem > /usr/local/vpnserver/server.pem

# 运行SoftEther配置工具
sudo /usr/local/vpnserver/vpncmd <<EOF
1
<服务器当前的IP>

ServerPasswordSet
a8852217
a8852217
HubCreate VPN
a8852217
a8852217
Hub VPN
UserCreate q

q

UserPasswordSet q
123
123
SecureNatEnable
SstpEnable
yes
HubDelete DEFAULT
EOF

echo "VPN server setup completed!"