#!/bin/bash

LOGFILE="/var/log/softether_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[INFO] Starting SoftEther VPN installation script..."

# Update system
echo "[INFO] Updating system packages..."
sudo yum update -y

# Install dependencies
echo "[INFO] Installing GCC, Make, and EPEL release..."
sudo yum install -y gcc make epel-release

# Download SoftEther VPN Server
echo "[INFO] Downloading SoftEther VPN Server..."
SOFTETHER_URL="https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz"
wget $SOFTETHER_URL

# Extract the downloaded file
FILENAME="$(basename $SOFTETHER_URL)"
echo "[INFO] Extracting $FILENAME..."
tar xzvf $FILENAME

# Compile SoftEther VPN Server
echo "[INFO] Compiling SoftEther VPN Server..."
cd vpnserver
make

# Move and set permissions
echo "[INFO] Moving vpnserver to /usr/local and setting permissions..."
cd ..
sudo mv vpnserver /usr/local
cd /usr/local/vpnserver
sudo chmod 600 *
sudo chmod 700 vpncmd vpnserver

# Install nano
echo "[INFO] Installing nano text editor..."
echo "Y" | sudo yum install nano -y

# Create systemd service file
echo "[INFO] Creating vpnserver systemd service file..."
SERVICE_FILE="/etc/systemd/system/vpnserver.service"

sudo bash -c "cat > $SERVICE_FILE" << EOF
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

# Enable and start VPN service
echo "[INFO] Enabling and starting vpnserver service..."
sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
sudo systemctl status vpnserver

# Install OpenSSL
echo "[INFO] Installing OpenSSL..."
sudo yum install -y openssl

# Generate private key and CSR
echo "[INFO] Generating private key and CSR..."
openssl genrsa -out /usr/local/vpnserver/key.pem 2048

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

# Generate self-signed certificate
echo "[INFO] Generating self-signed certificate..."
openssl x509 -req -days 365 -in /usr/local/vpnserver/request.csr -signkey /usr/local/vpnserver/key.pem -out /usr/local/vpnserver/chain.pem

# Merge certificate and private key
cat /usr/local/vpnserver/chain.pem /usr/local/vpnserver/key.pem > /usr/local/vpnserver/server.pem

# Automate SoftEther VPN configuration
echo "[INFO] Configuring SoftEther VPN automatically..."

sudo /usr/local/vpnserver/vpncmd << EOF
1
47.238.102.11

# Set Server Password
ServerPasswordSet
a8852217
a8852217

# Create VPN Hub
HubCreate VPN
a8852217
a8852217

# Switch to VPN Hub
Hub VPN

# Create VPN User
UserCreate q

q

# Set User Password
UserPasswordSet q
123
123

# Enable Secure NAT
SecureNatEnable

# Enable SSTP
SstpEnable
yes

# Delete Default HUB
HubDelete DEFAULT
EOF

echo "[INFO] SoftEther VPN installation and configuration completed successfully."
