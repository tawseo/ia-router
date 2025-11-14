#!/bin/bash

###############################################################################
# Soft-VPN Remote Installer for Debian 12
# This script installs SoftEther VPN on a REMOTE Debian 12 server
# Optimized for penetrating Russian government firewalls
# Supports Mac, iPhone, and iPad clients
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Soft-VPN Remote Installer for Debian 12 Servers        ║${NC}"
echo -e "${GREEN}║      Firewall Penetration Optimized Configuration          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for required tools
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}Error: ssh client is not installed${NC}"
    exit 1
fi

# Get remote server details
echo -e "${BLUE}Enter remote server details:${NC}"
read -p "Remote server IP/hostname: " REMOTE_HOST
read -p "SSH username (default: root): " SSH_USER
SSH_USER=${SSH_USER:-root}
read -p "SSH port (default: 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

echo ""
echo -e "${YELLOW}Testing SSH connection to ${SSH_USER}@${REMOTE_HOST}:${SSH_PORT}...${NC}"

# Test SSH connection
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -p "$SSH_PORT" "${SSH_USER}@${REMOTE_HOST}" "echo 2>&1" &>/dev/null; then
    echo -e "${YELLOW}SSH key authentication failed or not configured.${NC}"
    echo -e "${YELLOW}You will be prompted for password during installation.${NC}"
    SSH_OPTS="-p ${SSH_PORT}"
else
    echo -e "${GREEN}✓ SSH connection successful${NC}"
    SSH_OPTS="-o BatchMode=yes -p ${SSH_PORT}"
fi

echo ""
echo -e "${BLUE}Generating secure credentials...${NC}"

# Generate random secure passwords locally
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-20
}

ADMIN_PASSWORD=$(generate_password)
VPN_PASSWORD=$(generate_password)
PSK_KEY=$(generate_password)

# Configuration variables
SOFTETHER_VERSION="v4.43-9799-beta"
SOFTETHER_BUILD="2023.08.31"
VPN_HUB_NAME="VPN"
VPN_USER="vpnuser"

echo -e "${GREEN}✓ Credentials generated${NC}"
echo ""
echo -e "${BLUE}Starting remote installation on ${REMOTE_HOST}...${NC}"
echo ""

# Create the remote installation script
REMOTE_SCRIPT=$(cat <<'EOFREMOTE'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ADMIN_PASSWORD="__ADMIN_PASSWORD__"
VPN_PASSWORD="__VPN_PASSWORD__"
PSK_KEY="__PSK_KEY__"
SOFTETHER_VERSION="__SOFTETHER_VERSION__"
SOFTETHER_BUILD="__SOFTETHER_BUILD__"
VPN_HUB_NAME="__VPN_HUB_NAME__"
VPN_USER="__VPN_USER__"

INSTALL_DIR="/opt/softvpn"
CONFIG_DIR="/etc/softvpn"
LOG_FILE="/var/log/softvpn-install.log"

echo -e "${BLUE}[1/8] Verifying Debian 12...${NC}"
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
    echo -e "${YELLOW}Warning: This installer is designed for Debian 12${NC}"
fi

echo -e "${BLUE}[2/8] Updating system and installing dependencies...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
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
    dnsmasq \
    openssl \
    ca-certificates \
    net-tools \
    iptables-persistent > /dev/null 2>&1

echo -e "${BLUE}[3/8] Downloading SoftEther VPN Server...${NC}"
mkdir -p "$INSTALL_DIR"
cd /tmp

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    SOFTETHER_URL="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/${SOFTETHER_VERSION}/softether-vpnserver-${SOFTETHER_VERSION}-${SOFTETHER_BUILD}-linux-x64-64bit.tar.gz"
else
    SOFTETHER_URL="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/${SOFTETHER_VERSION}/softether-vpnserver-${SOFTETHER_VERSION}-${SOFTETHER_BUILD}-linux-arm64-64bit.tar.gz"
fi

wget -q --show-progress "$SOFTETHER_URL" -O softether-vpnserver.tar.gz 2>&1 || {
    echo -e "${YELLOW}Trying alternative download source...${NC}"
    SOFTETHER_URL="https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz"
    wget -q --show-progress "$SOFTETHER_URL" -O softether-vpnserver.tar.gz 2>&1
}

echo -e "${BLUE}[4/8] Installing SoftEther VPN Server...${NC}"
tar xzf softether-vpnserver.tar.gz
cd vpnserver
make i_read_and_agree_the_license_agreement > /dev/null 2>&1
cd ..
mv vpnserver "$INSTALL_DIR/"

echo -e "${BLUE}[5/8] Creating systemd service...${NC}"
cat > /etc/systemd/system/softvpn.service << 'EOF'
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service

[Service]
Type=forking
EnvironmentFile=-/etc/default/softvpn
ExecStart=/opt/softvpn/vpnserver/vpnserver start
ExecStop=/opt/softvpn/vpnserver/vpnserver stop
KillMode=process
Restart=on-failure
RestartSec=3s

# Hardening
NoNewPrivileges=false
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
ReadWritePaths=/opt/softvpn

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable softvpn.service > /dev/null 2>&1
systemctl start softvpn.service

# Wait for VPN server to start
sleep 5

echo -e "${BLUE}[6/8] Configuring VPN Server for firewall penetration...${NC}"

cd "$INSTALL_DIR/vpnserver"

# Create configuration commands
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
ProtoOptionsSet OpenVPN /NAME:default /PORT:1194
EOF

# Apply configuration
./vpncmd localhost /SERVER /IN:/tmp/vpn_config.txt > /dev/null 2>&1

# Clean up config file
rm -f /tmp/vpn_config.txt

echo -e "${BLUE}[7/8] Configuring firewall rules...${NC}"

# Get primary network interface
PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -n1)

# Enable IP forwarding
cat > /etc/sysctl.d/99-softvpn.conf << EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.$PRIMARY_IF.rp_filter=0
EOF

sysctl -p /etc/sysctl.d/99-softvpn.conf > /dev/null 2>&1

# Configure iptables for NAT
iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
iptables -A FORWARD -i vpn_+ -o "$PRIMARY_IF" -j ACCEPT
iptables -A FORWARD -i "$PRIMARY_IF" -o vpn_+ -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow VPN ports through firewall
iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS/SSL-VPN (PRIMARY for firewall penetration)
iptables -A INPUT -p tcp --dport 992 -j ACCEPT   # SoftEther Admin
iptables -A INPUT -p tcp --dport 1194 -j ACCEPT  # OpenVPN TCP
iptables -A INPUT -p udp --dport 1194 -j ACCEPT  # OpenVPN UDP
iptables -A INPUT -p tcp --dport 5555 -j ACCEPT  # SoftEther VPN
iptables -A INPUT -p udp --dport 500 -j ACCEPT   # IPsec IKE
iptables -A INPUT -p udp --dport 4500 -j ACCEPT  # IPsec NAT-T
iptables -A INPUT -p udp --dport 1701 -j ACCEPT  # L2TP
iptables -A INPUT -p icmp -j ACCEPT              # VPN over ICMP

# Save iptables rules
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
netfilter-persistent save > /dev/null 2>&1

echo -e "${BLUE}[8/8] Creating configuration files...${NC}"

# Get server public IP
PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

mkdir -p "$CONFIG_DIR/clients"

# Create iOS/macOS configuration file
cat > "$CONFIG_DIR/clients/ios-macos-setup.txt" << EOF
╔════════════════════════════════════════════════════════════╗
║       iOS/macOS L2TP/IPsec Configuration                   ║
║     Optimized for Russian Firewall Penetration             ║
╚════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════
CONNECTION DETAILS
═══════════════════════════════════════════════════════════
Server IP:      ${PUBLIC_IP}
Username:       ${VPN_USER}
Password:       ${VPN_PASSWORD}
Pre-Shared Key: ${PSK_KEY}
VPN Hub:        ${VPN_HUB_NAME}

═══════════════════════════════════════════════════════════
IPHONE/IPAD SETUP (L2TP/IPsec - Native)
═══════════════════════════════════════════════════════════
1. Open Settings → General → VPN & Device Management → VPN
2. Tap "Add VPN Configuration..."
3. Select "L2TP"
4. Fill in the following:
   Description:    Soft-VPN
   Server:         ${PUBLIC_IP}
   Account:        ${VPN_USER}
   Password:       ${VPN_PASSWORD}
   Secret:         ${PSK_KEY}
5. Tap "Done"
6. Toggle VPN switch to connect

═══════════════════════════════════════════════════════════
MAC SETUP (L2TP/IPsec - Native)
═══════════════════════════════════════════════════════════
1. Open System Settings → Network
2. Click "+" (bottom left) to add a service
3. Select:
   Interface:      VPN
   VPN Type:       L2TP over IPsec
   Service Name:   Soft-VPN
4. Configure:
   Server Address: ${PUBLIC_IP}
   Account Name:   ${VPN_USER}
5. Click "Authentication Settings..."
   Password:       ${VPN_PASSWORD}
   Shared Secret:  ${PSK_KEY}
6. Click "OK" → "Apply" → "Connect"

═══════════════════════════════════════════════════════════
ADVANCED: SoftEther VPN Client (RECOMMENDED)
═══════════════════════════════════════════════════════════
For better firewall penetration, use SoftEther VPN Client:

macOS/iOS Download: https://www.softether.org/

SoftEther provides:
✓ SSL-VPN over HTTPS (Port 443) - Best for firewall bypass
✓ VPN over ICMP (works through ping)
✓ VPN over DNS (works through DNS queries)
✓ Multiple protocol support

Connection Settings:
- Server: ${PUBLIC_IP}:443 (use port 443 for best penetration)
- Hub: ${VPN_HUB_NAME}
- Username: ${VPN_USER}
- Password: ${VPN_PASSWORD}

═══════════════════════════════════════════════════════════
FIREWALL PENETRATION FEATURES ENABLED
═══════════════════════════════════════════════════════════
✓ SSL-VPN over HTTPS (Port 443) - PRIMARY METHOD
✓ VPN over ICMP (Ping tunneling)
✓ VPN over DNS (DNS tunneling)
✓ L2TP/IPsec (Native iOS/macOS support)
✓ SSTP (SSL-based VPN)
✓ OpenVPN (TCP & UDP)
✓ Multiple listening ports for redundancy

═══════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════
If connection fails:
1. Try port 443 first (most likely to work)
2. If blocked, try ICMP/DNS mode with SoftEther client
3. Ensure server firewall allows VPN ports
4. Check if your ISP blocks VPN (use port 443 to avoid)

For support: Check server logs at /var/log/softvpn-install.log
EOF

# Create admin credentials file
cat > "$CONFIG_DIR/credentials.txt" << EOF
Soft-VPN Server Credentials
Installation Date: $(date)
Server IP: ${PUBLIC_IP}

ADMINISTRATOR ACCESS:
Admin Password: ${ADMIN_PASSWORD}
Management: ssh ${SSH_USER}@${PUBLIC_IP}
Admin Console: /opt/softvpn/vpn-admin.sh

VPN CLIENT ACCESS:
Server:         ${PUBLIC_IP}
Username:       ${VPN_USER}
Password:       ${VPN_PASSWORD}
Pre-Shared Key: ${PSK_KEY}
Hub Name:       ${VPN_HUB_NAME}

PORTS:
- 443  (SSL-VPN HTTPS) ← RECOMMENDED
- 992  (SoftEther Admin)
- 1194 (OpenVPN)
- 5555 (SoftEther VPN)
- 500/4500 (IPsec)
- 1701 (L2TP)
EOF

chmod 600 "$CONFIG_DIR/credentials.txt"

# Create management scripts
cat > /opt/softvpn/vpn-admin.sh << 'ADMINEOF'
#!/bin/bash
cd /opt/softvpn/vpnserver
./vpncmd localhost /SERVER
ADMINEOF
chmod +x /opt/softvpn/vpn-admin.sh

cat > /opt/softvpn/vpn-status.sh << 'STATUSEOF'
#!/bin/bash
echo "═══════════════════════════════════════════════════════════"
echo "SoftVPN Server Status"
echo "═══════════════════════════════════════════════════════════"
systemctl status softvpn.service --no-pager -l
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Active VPN Sessions"
echo "═══════════════════════════════════════════════════════════"
cd /opt/softvpn/vpnserver
./vpncmd localhost /SERVER /HUB:VPN /CMD SessionList
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Server Information"
echo "═══════════════════════════════════════════════════════════"
./vpncmd localhost /SERVER /CMD ServerStatusGet
STATUSEOF
chmod +x /opt/softvpn/vpn-status.sh

# Output completion marker
echo "INSTALL_COMPLETE"
echo "PUBLIC_IP=${PUBLIC_IP}"

EOFREMOTE
)

# Replace placeholders in remote script
REMOTE_SCRIPT="${REMOTE_SCRIPT//__ADMIN_PASSWORD__/$ADMIN_PASSWORD}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VPN_PASSWORD__/$VPN_PASSWORD}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__PSK_KEY__/$PSK_KEY}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SOFTETHER_VERSION__/$SOFTETHER_VERSION}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SOFTETHER_BUILD__/$SOFTETHER_BUILD}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VPN_HUB_NAME__/$VPN_HUB_NAME}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VPN_USER__/$VPN_USER}"

# Execute installation on remote server
echo "$REMOTE_SCRIPT" | ssh $SSH_OPTS "${SSH_USER}@${REMOTE_HOST}" 'bash -s' 2>&1 | tee /tmp/softvpn-install.log

# Extract public IP from output
PUBLIC_IP=$(grep "PUBLIC_IP=" /tmp/softvpn-install.log | tail -1 | cut -d'=' -f2)

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="$REMOTE_HOST"
fi

# Check if installation was successful
if grep -q "INSTALL_COMPLETE" /tmp/softvpn-install.log; then
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║   Soft-VPN Remote Installation Completed Successfully! ✓   ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}SERVER INFORMATION${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Server IP:        ${PUBLIC_IP}"
    echo -e "SSH Access:       ssh ${SSH_USER}@${REMOTE_HOST} -p ${SSH_PORT}"
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
    echo -e "${YELLOW}FIREWALL PENETRATION FEATURES${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓${NC} SSL-VPN over HTTPS (Port 443) - ${RED}PRIMARY METHOD${NC}"
    echo -e "${GREEN}✓${NC} VPN over ICMP (Ping-based tunneling)"
    echo -e "${GREEN}✓${NC} VPN over DNS (DNS-based tunneling)"
    echo -e "${GREEN}✓${NC} L2TP/IPsec (Native iOS/macOS support)"
    echo -e "${GREEN}✓${NC} SSTP (SSL tunneling)"
    echo -e "${GREEN}✓${NC} OpenVPN (TCP & UDP)"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}AVAILABLE PORTS${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "  443  - SSL-VPN (HTTPS) ${RED}← USE THIS FOR BEST PENETRATION${NC}"
    echo -e "  992  - SoftEther Admin"
    echo -e "  1194 - OpenVPN"
    echo -e "  5555 - SoftEther VPN"
    echo -e "  500/4500 - IPsec"
    echo -e "  1701 - L2TP"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}CLIENT SETUP INSTRUCTIONS${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Retrieve from server:"
    echo -e "  ${BLUE}scp ${SSH_USER}@${REMOTE_HOST}:/etc/softvpn/clients/ios-macos-setup.txt .${NC}"
    echo ""
    echo -e "Or SSH to server and view:"
    echo -e "  ${BLUE}ssh ${SSH_USER}@${REMOTE_HOST}${NC}"
    echo -e "  ${BLUE}cat /etc/softvpn/clients/ios-macos-setup.txt${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}REMOTE MANAGEMENT COMMANDS${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Check VPN status:"
    echo -e "  ${BLUE}ssh ${SSH_USER}@${REMOTE_HOST} '/opt/softvpn/vpn-status.sh'${NC}"
    echo ""
    echo -e "Access admin console:"
    echo -e "  ${BLUE}ssh ${SSH_USER}@${REMOTE_HOST} '/opt/softvpn/vpn-admin.sh'${NC}"
    echo ""
    echo -e "Control VPN service:"
    echo -e "  ${BLUE}ssh ${SSH_USER}@${REMOTE_HOST} 'systemctl {start|stop|restart|status} softvpn'${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}RECOMMENDATION FOR MAXIMUM FIREWALL PENETRATION:${NC}"
    echo -e "${BLUE}Use SoftEther VPN Client with SSL-VPN on port 443${NC}"
    echo -e "${BLUE}Download: https://www.softether.org/${NC}"
    echo ""
    echo -e "${GREEN}Installation log saved to: /tmp/softvpn-install.log${NC}"
    echo -e "${RED}Server credentials saved at: /etc/softvpn/credentials.txt${NC}"
    echo ""

    # Save credentials locally
    cat > "./softvpn-credentials.txt" << EOF
Soft-VPN Remote Installation
Installation Date: $(date)

REMOTE SERVER:
IP/Hostname: ${REMOTE_HOST}
SSH Port: ${SSH_PORT}
SSH User: ${SSH_USER}
Public IP: ${PUBLIC_IP}

ADMIN CREDENTIALS:
Password: ${ADMIN_PASSWORD}

VPN CLIENT CREDENTIALS:
Server: ${PUBLIC_IP}
Username: ${VPN_USER}
Password: ${VPN_PASSWORD}
Pre-Shared Key: ${PSK_KEY}
Hub: ${VPN_HUB_NAME}

RECOMMENDED CONNECTION:
Protocol: SSL-VPN (SoftEther Client)
Server: ${PUBLIC_IP}:443
Hub: ${VPN_HUB_NAME}
Username: ${VPN_USER}
Password: ${VPN_PASSWORD}

ALTERNATIVE (Native iOS/Mac):
Type: L2TP/IPsec
Server: ${PUBLIC_IP}
Account: ${VPN_USER}
Password: ${VPN_PASSWORD}
Secret: ${PSK_KEY}

MANAGEMENT:
SSH: ssh ${SSH_USER}@${REMOTE_HOST} -p ${SSH_PORT}
Status: /opt/softvpn/vpn-status.sh
Admin: /opt/softvpn/vpn-admin.sh
Config: /etc/softvpn/clients/ios-macos-setup.txt
EOF

    echo -e "${GREEN}Local credentials saved to: ./softvpn-credentials.txt${NC}"
    echo -e "${RED}IMPORTANT: Save these credentials securely and delete the file!${NC}"
    echo ""
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║         Installation Failed - Check Logs                   ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Check installation log: /tmp/softvpn-install.log${NC}"
    exit 1
fi
