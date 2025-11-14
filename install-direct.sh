#!/bin/bash

###############################################################################
# Direct Soft-VPN Installer for Debian 12
# Run this script DIRECTLY on your Debian server (not remote)
# ssh root@your-server-ip
# Then run this script
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Soft-VPN Direct Installer for Debian 12                 ║${NC}"
echo -e "${GREEN}║    Run this ON your server (not remotely)                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Generate passwords
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-20
}

ADMIN_PASSWORD=$(generate_password)
VPN_PASSWORD=$(generate_password)
PSK_KEY=$(generate_password)

VPN_HUB_NAME="VPN"
VPN_USER="vpnuser"
INSTALL_DIR="/opt/softvpn"
CONFIG_DIR="/etc/softvpn"
LOG_FILE="/var/log/softvpn-install.log"

echo -e "${BLUE}[1/8] Checking Debian version...${NC}"
if ! grep -q "Debian" /etc/os-release 2>/dev/null; then
    echo -e "${RED}Warning: This installer is designed for Debian${NC}"
fi

echo -e "${BLUE}[2/8] Updating system and installing dependencies...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
apt-get install -y \
    build-essential \
    wget \
    curl \
    gcc \
    make \
    libreadline-dev \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    iptables \
    openssl \
    ca-certificates \
    net-tools \
    iptables-persistent 2>&1 | tee -a "$LOG_FILE"

echo -e "${BLUE}[3/8] Downloading SoftEther VPN Server...${NC}"
cd /tmp
rm -rf vpnserver softether-vpnserver.tar.gz

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.43-9799-beta/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DOWNLOAD_URL="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.43-9799-beta/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-arm64-64bit.tar.gz"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

echo "Downloading from: $DOWNLOAD_URL"
wget --show-progress "$DOWNLOAD_URL" -O softether-vpnserver.tar.gz 2>&1 | tee -a "$LOG_FILE"

if [ ! -f softether-vpnserver.tar.gz ]; then
    echo -e "${RED}Download failed!${NC}"
    exit 1
fi

echo -e "${BLUE}[4/8] Extracting SoftEther VPN Server...${NC}"
tar xzf softether-vpnserver.tar.gz 2>&1 | tee -a "$LOG_FILE"

if [ ! -d vpnserver ]; then
    echo -e "${RED}Extraction failed!${NC}"
    exit 1
fi

echo -e "${BLUE}[5/8] Compiling SoftEther VPN Server...${NC}"
cd vpnserver

# Show what we're compiling
echo "Current directory: $(pwd)"
echo "Files in directory:"
ls -la

echo ""
echo "Starting compilation... This may take 2-3 minutes."
echo "You will see compiler output below:"
echo "════════════════════════════════════════════════════════════"

# Run make with full output
if make i_read_and_agree_the_license_agreement 2>&1 | tee -a "$LOG_FILE"; then
    echo "════════════════════════════════════════════════════════════"
    echo -e "${GREEN}✓ Compilation successful!${NC}"
else
    echo "════════════════════════════════════════════════════════════"
    echo -e "${RED}✗ Compilation failed!${NC}"
    echo -e "${YELLOW}Error log saved to: $LOG_FILE${NC}"
    echo ""
    echo "Common fixes:"
    echo "1. Make sure all dependencies are installed:"
    echo "   apt-get install build-essential gcc make libssl-dev zlib1g-dev"
    echo ""
    echo "2. Check if you have enough disk space:"
    echo "   df -h /tmp"
    echo ""
    echo "3. Try a different SoftEther version"
    exit 1
fi

echo -e "${BLUE}[6/8] Installing VPN Server...${NC}"
cd /tmp
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/vpnserver"
mv vpnserver "$INSTALL_DIR/"

echo -e "${BLUE}[7/8] Creating systemd service...${NC}"
cat > /etc/systemd/system/softvpn.service << 'EOF'
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/opt/softvpn/vpnserver/vpnserver start
ExecStop=/opt/softvpn/vpnserver/vpnserver stop
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable softvpn.service 2>&1 | tee -a "$LOG_FILE"
systemctl start softvpn.service

sleep 5

# Check if service started
if ! systemctl is-active --quiet softvpn; then
    echo -e "${RED}VPN service failed to start!${NC}"
    systemctl status softvpn
    exit 1
fi

echo -e "${GREEN}✓ VPN service started successfully${NC}"

echo -e "${BLUE}[8/8] Configuring VPN Server...${NC}"
cd "$INSTALL_DIR/vpnserver"

# Create configuration
cat > /tmp/vpn_config.txt << EOF
ServerPasswordSet ${ADMIN_PASSWORD}
HubCreate ${VPN_HUB_NAME} /PASSWORD:${ADMIN_PASSWORD}
Hub ${VPN_HUB_NAME}
SecureNatEnable
UserCreate ${VPN_USER} /GROUP:none /REALNAME:Default_VPN_User /NOTE:none
UserPasswordSet ${VPN_USER} /PASSWORD:${VPN_PASSWORD}
IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK_KEY} /DEFAULTHUB:${VPN_HUB_NAME}
OpenVpnEnable yes /PORTS:1194
SstpEnable yes
ServerCertRegenerate SoftVPN-Server
ListenerCreate 443
ListenerCreate 992
ListenerCreate 5555
VpnOverIcmpDnsEnable /ICMP:yes /DNS:yes
EOF

./vpncmd localhost /SERVER /IN:/tmp/vpn_config.txt 2>&1 | tee -a "$LOG_FILE"
rm -f /tmp/vpn_config.txt

# Configure firewall
echo -e "${BLUE}Configuring firewall...${NC}"
PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -n1)

# Enable IP forwarding
cat > /etc/sysctl.d/99-softvpn.conf << EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl -p /etc/sysctl.d/99-softvpn.conf >/dev/null 2>&1

# Configure iptables
iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
iptables -A FORWARD -i vpn_+ -o "$PRIMARY_IF" -j ACCEPT
iptables -A FORWARD -i "$PRIMARY_IF" -o vpn_+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 992 -j ACCEPT
iptables -A INPUT -p tcp --dport 1194 -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A INPUT -p tcp --dport 5555 -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -p udp --dport 1701 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Save rules
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
netfilter-persistent save >/dev/null 2>&1

# Get public IP
PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# Create config directory
mkdir -p "$CONFIG_DIR/clients"

# Save credentials
cat > "$CONFIG_DIR/credentials.txt" << EOF
Soft-VPN Installation Credentials
Installation Date: $(date)
Server IP: ${PUBLIC_IP}

ADMINISTRATOR:
Admin Password: ${ADMIN_PASSWORD}

VPN CLIENT:
Server:         ${PUBLIC_IP}
Username:       ${VPN_USER}
Password:       ${VPN_PASSWORD}
Pre-Shared Key: ${PSK_KEY}
Hub Name:       ${VPN_HUB_NAME}
EOF
chmod 600 "$CONFIG_DIR/credentials.txt"

# Create management scripts
cat > /opt/softvpn/vpn-status.sh << 'STATUSEOF'
#!/bin/bash
echo "SoftVPN Server Status:"
systemctl status softvpn.service --no-pager
echo ""
echo "Active Sessions:"
cd /opt/softvpn/vpnserver
./vpncmd localhost /SERVER /HUB:VPN /CMD SessionList
STATUSEOF
chmod +x /opt/softvpn/vpn-status.sh

# Display success
clear
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║   Soft-VPN Installation Completed Successfully! ✓          ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}ADMIN CREDENTIALS (SAVE THESE SECURELY!)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}Admin Password:   ${ADMIN_PASSWORD}${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}VPN CLIENT CREDENTIALS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "Server:           ${PUBLIC_IP}"
echo -e "Username:         ${VPN_USER}"
echo -e "Password:         ${VPN_PASSWORD}"
echo -e "Pre-Shared Key:   ${PSK_KEY}"
echo -e "Hub Name:         ${VPN_HUB_NAME}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}CLIENT SETUP (iPhone/iPad/Mac)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "1. Go to Settings → VPN → Add VPN Configuration"
echo -e "2. Select: L2TP"
echo -e "3. Server: ${PUBLIC_IP}"
echo -e "4. Account: ${VPN_USER}"
echo -e "5. Password: ${VPN_PASSWORD}"
echo -e "6. Secret: ${PSK_KEY}"
echo ""
echo -e "${GREEN}Installation log: ${LOG_FILE}${NC}"
echo -e "${GREEN}Credentials saved: ${CONFIG_DIR}/credentials.txt${NC}"
echo ""
