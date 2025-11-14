# Quick Start Guide - Soft-VPN Installation

## 5-Minute Setup

### Prerequisites
- A Debian 12 server with root access
- SSH client on your local machine
- Server's IP address

### Installation Steps

#### 1. Download Installer
```bash
git clone <repository-url>
cd ia-router
chmod +x install-softvpn.sh
```

#### 2. Run Installation
```bash
./install-softvpn.sh
```

#### 3. Provide Server Details
When prompted, enter:
```
Remote server IP/hostname: 192.168.1.100  # Your server IP
SSH username (default: root): root         # Press Enter for default
SSH port (default: 22): 22                 # Press Enter for default
```

#### 4. Wait for Installation
The installer will:
- Connect to your server
- Install all dependencies
- Configure SoftEther VPN
- Set up firewall rules
- Generate secure credentials

This takes approximately 5-10 minutes.

#### 5. Save Your Credentials
After installation, you'll see:

```
═══════════════════════════════════════════════════════════
ADMIN CREDENTIALS (SAVE THESE SECURELY!)
═══════════════════════════════════════════════════════════
Admin Password:   AbCd1234XyZ567890qrs

═══════════════════════════════════════════════════════════
VPN CLIENT CREDENTIALS
═══════════════════════════════════════════════════════════
Server:           123.45.67.89
Username:         vpnuser
Password:         Ef89GhIj012KlMn34567
Pre-Shared Key:   Op78QrSt901UvWx23456
Hub Name:         VPN
```

**⚠️ CRITICAL**: Copy these credentials immediately! They're also saved in `softvpn-credentials.txt`.

### Connect Your Device

#### iPhone/iPad (30 seconds)

1. **Settings** → **General** → **VPN & Device Management** → **VPN**
2. Tap **Add VPN Configuration...**
3. Select **L2TP**
4. Fill in:
   ```
   Description:    Soft-VPN
   Server:         123.45.67.89           # Your server IP
   Account:        vpnuser
   Password:       Ef89GhIj012KlMn34567   # Your VPN password
   Secret:         Op78QrSt901UvWx23456   # Your PSK
   ```
5. Tap **Done**
6. Toggle VPN **ON**

#### macOS (1 minute)

1. **System Settings** → **Network**
2. Click **+** button
3. Choose:
   ```
   Interface:      VPN
   VPN Type:       L2TP over IPsec
   Service Name:   Soft-VPN
   ```
4. Configure:
   ```
   Server Address: 123.45.67.89           # Your server IP
   Account Name:   vpnuser
   ```
5. Click **Authentication Settings**:
   ```
   Password:       Ef89GhIj012KlMn34567   # Your VPN password
   Shared Secret:  Op78QrSt901UvWx23456   # Your PSK
   ```
6. Click **OK** → **Apply** → **Connect**

### For Maximum Firewall Penetration

If the native VPN doesn't work due to firewall restrictions:

1. **Download SoftEther VPN Client** for macOS:
   - Visit: https://www.softether.org/
   - Download "SoftEther VPN Client"
   - Install on your Mac

2. **Create VPN Connection**:
   - Open SoftEther VPN Client
   - Create new connection:
     ```
     Server:   123.45.67.89:443    # Use port 443!
     Hub:      VPN
     Username: vpnuser
     Password: [your VPN password]
     ```
   - Enable **VPN over ICMP/DNS** in advanced settings

3. **Connect** - This works even behind restrictive firewalls!

### Verify Connection

Once connected, test your VPN:

#### Check Your IP
```bash
curl https://api.ipify.org
# Should show your VPN server's IP
```

#### Test Internet Access
```bash
ping 8.8.8.8
curl https://www.google.com
```

### Common Issues

#### "Cannot connect to VPN"
**Solution**: Use port 443 with SoftEther client instead of native L2TP

#### "Authentication failed"
**Solution**: Double-check credentials, especially Pre-Shared Key (case-sensitive)

#### "VPN connects but no internet"
**Solution**:
```bash
ssh root@your-server-ip 'systemctl restart softvpn'
```

### Next Steps

- **Read full documentation**: See `README.md`
- **Add more users**: See "Advanced Configuration" in README
- **Monitor connections**: Run `/opt/softvpn/vpn-status.sh` on server
- **Secure credentials**: Delete `softvpn-credentials.txt` after saving elsewhere

### Quick Commands Reference

```bash
# Check VPN status
ssh root@your-server-ip '/opt/softvpn/vpn-status.sh'

# Restart VPN server
ssh root@your-server-ip 'systemctl restart softvpn'

# View active sessions
ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'

# Get setup instructions again
ssh root@your-server-ip 'cat /etc/softvpn/clients/ios-macos-setup.txt'
```

### Success Checklist

- [ ] Installation completed without errors
- [ ] Credentials saved securely
- [ ] VPN connection successful from iPhone/iPad/Mac
- [ ] Internet access works through VPN
- [ ] IP address shows VPN server location
- [ ] Credentials file deleted from local machine

---

**🎉 Congratulations! Your Soft-VPN is ready to use!**

For advanced features and troubleshooting, see the complete [README.md](README.md).
