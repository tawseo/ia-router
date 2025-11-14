# Soft-VPN Installer for Debian 12

A comprehensive automated installer for deploying SoftEther VPN on remote Debian 12 servers with optimized configurations for penetrating restrictive firewalls (including Russian government firewalls).

## Features

- **Remote Installation**: Install VPN server on any Debian 12 server via SSH
- **Firewall Penetration**: Multiple protocols and obfuscation techniques
- **Automatic Configuration**: Zero-configuration setup with secure defaults
- **Multi-Device Support**: Native support for Mac, iPhone, and iPad
- **Secure by Default**: Randomly generated strong passwords
- **Easy Management**: Simple commands for monitoring and administration

## Firewall Penetration Technologies

This installer configures the following technologies to bypass restrictive firewalls:

✓ **SSL-VPN over HTTPS (Port 443)** - Primary method, appears as normal HTTPS traffic
✓ **VPN over ICMP** - Tunnels VPN through ping packets
✓ **VPN over DNS** - Tunnels VPN through DNS queries
✓ **L2TP/IPsec** - Native support on iOS and macOS
✓ **SSTP** - SSL-based VPN protocol
✓ **OpenVPN** - Industry-standard VPN with TCP/UDP support

## Requirements

### Local Machine (where you run the installer)
- Linux, macOS, or WSL on Windows
- SSH client installed
- OpenSSL installed
- Bash shell

### Remote Server
- Debian 12 (Bookworm)
- Root or sudo access
- SSH access (key-based or password)
- Public IP address
- Minimum 1GB RAM
- At least 10GB free disk space

## Quick Start

### 1. Prepare Remote Server

Ensure you have SSH access to your Debian 12 server:

```bash
ssh root@your-server-ip
```

If using SSH keys (recommended):
```bash
ssh-copy-id root@your-server-ip
```

### 2. Download and Run Installer

On your local machine:

```bash
# Clone repository
git clone <repository-url>
cd ia-router

# Run installer
./install-softvpn.sh
```

### 3. Follow Prompts

The installer will ask for:
- Remote server IP/hostname
- SSH username (default: root)
- SSH port (default: 22)
- SSH password (if not using keys)

### 4. Save Credentials

After installation, you'll receive:
- **Admin password** - For VPN server management
- **VPN user credentials** - For connecting clients
- **Pre-shared key** - For IPsec connections
- **Server IP** - Your VPN server address

**IMPORTANT**: Save these credentials securely! They are displayed once and saved to `softvpn-credentials.txt`.

## Client Setup

### iPhone/iPad (Native L2TP/IPsec)

1. Go to **Settings** → **General** → **VPN & Device Management** → **VPN**
2. Tap **Add VPN Configuration**
3. Select **L2TP**
4. Enter:
   - **Description**: Soft-VPN
   - **Server**: `<your-server-ip>`
   - **Account**: `vpnuser`
   - **Password**: `<vpn-password>`
   - **Secret**: `<psk-key>`
5. Tap **Done** and toggle VPN on

### macOS (Native L2TP/IPsec)

1. Go to **System Settings** → **Network**
2. Click **+** to add a service
3. Select:
   - **Interface**: VPN
   - **VPN Type**: L2TP over IPsec
   - **Service Name**: Soft-VPN
4. Configure:
   - **Server Address**: `<your-server-ip>`
   - **Account Name**: `vpnuser`
5. Click **Authentication Settings**:
   - **Password**: `<vpn-password>`
   - **Shared Secret**: `<psk-key>`
6. Click **OK** → **Apply** → **Connect**

### Advanced: SoftEther VPN Client (Recommended)

For maximum firewall penetration, use the official SoftEther VPN Client:

**Download**: https://www.softether.org/

**macOS Installation**:
```bash
# Download and install SoftEther VPN Client
# Then configure with these settings:
```

**Connection Settings**:
- **Server**: `<your-server-ip>:443` (use port 443!)
- **Hub**: `VPN`
- **Username**: `vpnuser`
- **Password**: `<vpn-password>`

**Why SoftEther Client?**
- Uses SSL-VPN over port 443 (appears as HTTPS)
- Automatic protocol switching if blocked
- VPN over ICMP/DNS fallback options
- Better performance and reliability

## Server Management

### Check VPN Status

```bash
ssh root@your-server-ip '/opt/softvpn/vpn-status.sh'
```

### Access Admin Console

```bash
ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
```

### Control VPN Service

```bash
# Start VPN
ssh root@your-server-ip 'systemctl start softvpn'

# Stop VPN
ssh root@your-server-ip 'systemctl stop softvpn'

# Restart VPN
ssh root@your-server-ip 'systemctl restart softvpn'

# Check status
ssh root@your-server-ip 'systemctl status softvpn'
```

### View Client Configuration

```bash
ssh root@your-server-ip 'cat /etc/softvpn/clients/ios-macos-setup.txt'
```

Or download locally:
```bash
scp root@your-server-ip:/etc/softvpn/clients/ios-macos-setup.txt .
```

## Port Information

The VPN server listens on the following ports:

| Port | Protocol | Purpose | Firewall Penetration |
|------|----------|---------|---------------------|
| 443 | TCP | SSL-VPN (HTTPS) | ⭐⭐⭐⭐⭐ Best |
| 992 | TCP | SoftEther Admin | ⭐⭐⭐ Good |
| 1194 | TCP/UDP | OpenVPN | ⭐⭐⭐⭐ Excellent |
| 5555 | TCP | SoftEther VPN | ⭐⭐⭐ Good |
| 500 | UDP | IPsec IKE | ⭐⭐ Moderate |
| 4500 | UDP | IPsec NAT-T | ⭐⭐ Moderate |
| 1701 | UDP | L2TP | ⭐⭐ Moderate |
| ICMP | - | VPN over ICMP | ⭐⭐⭐⭐ Excellent |
| DNS | UDP | VPN over DNS | ⭐⭐⭐⭐ Excellent |

**Recommendation**: Use port **443 with SSL-VPN** for maximum firewall penetration.

## Firewall Configuration

The installer automatically configures:

- IP forwarding (IPv4 and IPv6)
- NAT/masquerading
- iptables rules for all VPN ports
- Persistent firewall rules (survives reboot)

If you're behind a router, ensure these ports are forwarded to your VPN server.

## Troubleshooting

### Cannot Connect to VPN

1. **Check if VPN service is running**:
   ```bash
   ssh root@your-server-ip 'systemctl status softvpn'
   ```

2. **Verify ports are open**:
   ```bash
   ssh root@your-server-ip 'netstat -tulpn | grep vpnserver'
   ```

3. **Check firewall rules**:
   ```bash
   ssh root@your-server-ip 'iptables -L -n -v'
   ```

4. **View VPN server logs**:
   ```bash
   ssh root@your-server-ip 'cat /var/log/softvpn-install.log'
   ssh root@your-server-ip 'tail -f /opt/softvpn/vpnserver/server_log/*.log'
   ```

### Connection Blocked by Firewall

If standard ports are blocked:

1. **Try SSL-VPN on port 443** (most likely to work)
2. **Use VPN over ICMP** (requires SoftEther client)
3. **Use VPN over DNS** (requires SoftEther client)

With SoftEther VPN Client:
- Enable **VPN over ICMP**
- Enable **VPN over DNS**
- Set server to port 443

### SSH Access Lost After Installation

If you lose SSH access:

1. Access server via console (VPS control panel)
2. Check if SSH is still running:
   ```bash
   systemctl status sshd
   ```
3. The installer doesn't modify SSH, check your firewall/security groups

## Security Considerations

### Credentials

- Admin and user passwords are randomly generated (20 characters)
- Credentials are displayed once during installation
- Saved locally to `softvpn-credentials.txt`
- Also saved on server at `/etc/softvpn/credentials.txt` (readable by root only)

**Important**: Delete credential files after saving securely!

### Firewall

- Server allows VPN ports through iptables
- NAT is configured for internet access through VPN
- No other services are exposed

### Updates

Keep your system updated:

```bash
ssh root@your-server-ip 'apt update && apt upgrade -y'
```

SoftEther VPN updates should be done manually when new versions are released.

## Advanced Configuration

### Add More VPN Users

```bash
ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
# In the admin console:
Hub VPN
UserCreate newuser /GROUP:none /REALNAME:New_User /NOTE:none
UserPasswordSet newuser /PASSWORD:securepassword
```

### Change Admin Password

```bash
ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
# In the admin console:
ServerPasswordSet newpassword
```

### Enable Additional Protocols

The installer enables most protocols by default. To customize:

```bash
ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
# Explore available commands with: help
```

## Uninstallation

To remove Soft-VPN:

```bash
ssh root@your-server-ip << 'EOF'
systemctl stop softvpn
systemctl disable softvpn
rm -rf /opt/softvpn
rm -f /etc/systemd/system/softvpn.service
rm -rf /etc/softvpn
systemctl daemon-reload
echo "Soft-VPN removed. Firewall rules remain - remove manually if needed."
EOF
```

## Technical Details

### Software Stack

- **SoftEther VPN Server**: v4.43-9799-beta
- **Protocols**: SSL-VPN, L2TP/IPsec, OpenVPN, SSTP, VPN over ICMP/DNS
- **OS**: Debian 12 (Bookworm)
- **Service Management**: systemd
- **Firewall**: iptables with netfilter-persistent

### Directory Structure

```
/opt/softvpn/
├── vpnserver/              # VPN server binaries
├── vpn-admin.sh           # Admin console shortcut
└── vpn-status.sh          # Status check script

/etc/softvpn/
├── credentials.txt        # Server credentials
└── clients/
    └── ios-macos-setup.txt # Client setup guide
```

### Network Configuration

- **Virtual Hub**: VPN
- **Default User**: vpnuser
- **SecureNAT**: Enabled (provides DHCP and NAT)
- **IP Range**: 192.168.30.0/24 (default)
- **DNS**: Provided by SecureNAT

## FAQ

**Q: Can I use this on other Linux distributions?**
A: The script is designed for Debian 12. It may work on Ubuntu 22.04+ with modifications.

**Q: Do I need a domain name?**
A: No, you can use the IP address directly.

**Q: Can I use Let's Encrypt SSL certificate?**
A: Yes, but manual configuration is required. SoftEther generates a self-signed certificate by default.

**Q: How many simultaneous connections are supported?**
A: SoftEther supports thousands of concurrent connections, limited by server resources.

**Q: Is this legal?**
A: Using VPN for privacy is legal in most countries. Check your local laws. This tool is for authorized use only.

**Q: Can this bypass the Great Firewall of China?**
A: The techniques used (especially SSL-VPN on port 443) are designed to bypass deep packet inspection, but no guarantee is provided.

## Support

For issues, please check:

1. Installation logs: `/tmp/softvpn-install.log` (local)
2. Server logs: `/var/log/softvpn-install.log` (remote)
3. VPN server logs: `/opt/softvpn/vpnserver/server_log/` (remote)

## License

This installer script is provided as-is for educational and authorized use only.

SoftEther VPN is licensed under Apache License 2.0.

## Credits

- **SoftEther VPN Project**: https://www.softether.org/
- Built for penetrating restrictive firewalls
- Optimized for iOS and macOS devices

---

**⚠️ Disclaimer**: This tool is provided for authorized use only. Use responsibly and in compliance with local laws and regulations. The authors are not responsible for misuse.
