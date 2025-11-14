# Complete Installation Guide for Linode Debian Server

This guide walks you through setting up Soft-VPN on a fresh Linode Debian 12 server.

## Part 1: Set Up Linode Server

### Step 1: Create Linode Instance

1. **Log in to Linode Cloud Manager**
   - Go to: https://cloud.linode.com/
   - Sign in to your account

2. **Create a New Linode**
   - Click **"Create"** → **"Linode"**

3. **Choose Configuration**:
   - **Distribution**: Debian 12
   - **Region**: Choose closest to your users (or strategically for bypass)
   - **Plan**:
     - Minimum: **Nanode 1GB** ($5/month) - for 1-5 users
     - Recommended: **Linode 2GB** ($12/month) - for 5-20 users
   - **Linode Label**: `softvpn-server` (or your choice)

4. **Set Root Password**:
   - Create a strong password
   - **SAVE THIS PASSWORD** - you'll need it

5. **Add SSH Key** (Recommended):
   - If you have SSH key: paste your public key
   - If not: skip for now (we'll use password)

6. **Click "Create Linode"**

7. **Wait for Server to Boot**:
   - Status will change from "Provisioning" to "Running"
   - Takes about 1-2 minutes

8. **Note Your Server IP**:
   - Find **"IP Address"** on the Linode dashboard
   - Example: `172.105.123.45`
   - **SAVE THIS IP ADDRESS**

### Step 2: Configure Firewall (Linode Cloud Firewall)

**IMPORTANT**: You must allow VPN ports through Linode's firewall.

1. **Go to Firewalls**:
   - In Linode Cloud Manager
   - Click **"Firewalls"** in left menu

2. **Create Firewall** (if you want to use Linode Firewall):
   - Click **"Create Firewall"**
   - Name: `softvpn-firewall`

3. **Add Inbound Rules**:
   ```
   SSH:
   - Protocol: TCP
   - Port: 22
   - Source: All IPv4, All IPv6

   HTTPS/SSL-VPN (PRIMARY):
   - Protocol: TCP
   - Port: 443
   - Source: All IPv4, All IPv6

   SoftEther Admin:
   - Protocol: TCP
   - Port: 992
   - Source: All IPv4, All IPv6

   OpenVPN:
   - Protocol: TCP & UDP
   - Ports: 1194
   - Source: All IPv4, All IPv6

   SoftEther VPN:
   - Protocol: TCP
   - Port: 5555
   - Source: All IPv4, All IPv6

   IPsec IKE:
   - Protocol: UDP
   - Port: 500
   - Source: All IPv4, All IPv6

   IPsec NAT-T:
   - Protocol: UDP
   - Port: 4500
   - Source: All IPv4, All IPv6

   L2TP:
   - Protocol: UDP
   - Port: 1701
   - Source: All IPv4, All IPv6

   ICMP (for VPN over ICMP):
   - Protocol: ICMP
   - Source: All IPv4, All IPv6
   ```

4. **Attach to Linode**:
   - Select your `softvpn-server` Linode
   - Click **"Create Firewall"**

**OR Use iptables Only** (Simpler for beginners):
- Skip Linode Firewall creation
- The installer will configure iptables automatically

---

## Part 2: Access Your Server from Local Machine

### Step 3: Test SSH Connection

**On your local machine** (Mac/Linux/WSL):

1. **Open Terminal**

2. **Test SSH connection**:
   ```bash
   ssh root@172.105.123.45
   ```
   Replace `172.105.123.45` with YOUR Linode IP

3. **First connection will ask**:
   ```
   The authenticity of host '172.105.123.45' can't be established.
   Are you sure you want to continue connecting (yes/no)?
   ```
   Type: `yes` and press Enter

4. **Enter root password** (from Step 1.4)

5. **You're now connected to your Linode server!**
   You'll see a prompt like:
   ```
   root@softvpn-server:~#
   ```

6. **Exit for now**:
   ```bash
   exit
   ```

### Step 4: Set Up SSH Key (Recommended - Optional)

This allows password-less login and is required for the installer.

**On your local machine**:

1. **Check if you have SSH key**:
   ```bash
   ls ~/.ssh/id_rsa.pub
   ```

2. **If you don't have one, create it**:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```
   - Press Enter for default location
   - Press Enter for no passphrase (or set one)

3. **Copy SSH key to Linode**:
   ```bash
   ssh-copy-id root@172.105.123.45
   ```
   Replace with YOUR Linode IP

   Enter your root password when prompted

4. **Test password-less login**:
   ```bash
   ssh root@172.105.123.45
   ```
   Should connect WITHOUT asking for password!

5. **Exit**:
   ```bash
   exit
   ```

---

## Part 3: Install Soft-VPN on Linode

### Step 5: Download Installer on Your Local Machine

**On your local machine** (NOT on Linode):

1. **Create a working directory**:
   ```bash
   mkdir ~/softvpn-install
   cd ~/softvpn-install
   ```

2. **Clone the repository**:
   ```bash
   git clone -b claude/softvpn-debian-installer-011UcLBTd4WG3y3CrVo3S9zG https://github.com/tawseo/ia-router.git
   ```

3. **Enter directory**:
   ```bash
   cd ia-router
   ```

4. **Verify files are present**:
   ```bash
   ls -la
   ```

   You should see:
   ```
   install-softvpn.sh
   README.md
   QUICKSTART.md
   TROUBLESHOOTING.md
   ```

5. **Make installer executable**:
   ```bash
   chmod +x install-softvpn.sh
   ```

### Step 6: Run the Installer

**Still on your local machine**:

1. **Run installer**:
   ```bash
   ./install-softvpn.sh
   ```

2. **When prompted, enter**:
   ```
   Remote server IP/hostname: 172.105.123.45
   ```
   (Use YOUR Linode IP)

3. **SSH username**:
   ```
   SSH username (default: root):
   ```
   Press Enter (use default "root")

4. **SSH port**:
   ```
   SSH port (default: 22):
   ```
   Press Enter (use default "22")

5. **Wait for installation** (5-10 minutes):
   - You'll see progress messages
   - The installer connects to your Linode
   - Downloads and installs SoftEther VPN
   - Configures firewall and routing
   - Generates secure credentials

6. **Save the credentials!**

   When complete, you'll see:
   ```
   ═══════════════════════════════════════════════════════════
   ADMIN CREDENTIALS (SAVE THESE SECURELY!)
   ═══════════════════════════════════════════════════════════
   Admin Password:   AbCd1234XyZ567890qrs

   ═══════════════════════════════════════════════════════════
   VPN CLIENT CREDENTIALS
   ═══════════════════════════════════════════════════════════
   Server:           172.105.123.45
   Username:         vpnuser
   Password:         Ef89GhIj012KlMn34567
   Pre-Shared Key:   Op78QrSt901UvWx23456
   Hub Name:         VPN
   ```

   **CRITICAL**: Copy these credentials immediately!

7. **Credentials are also saved locally**:
   ```bash
   cat softvpn-credentials.txt
   ```

---

## Part 4: Connect Your Devices

### Step 7: Connect iPhone/iPad

1. Open **Settings**
2. Go to **General** → **VPN & Device Management** → **VPN**
3. Tap **Add VPN Configuration...**
4. Select **L2TP**
5. Fill in:
   - **Description**: `Soft-VPN`
   - **Server**: `172.105.123.45` (YOUR Linode IP)
   - **Account**: `vpnuser`
   - **Password**: `Ef89GhIj012KlMn34567` (YOUR VPN password)
   - **Secret**: `Op78QrSt901UvWx23456` (YOUR PSK)
6. Tap **Done**
7. Toggle **VPN** switch to **ON**
8. Should connect in 3-5 seconds!

### Step 8: Connect macOS

1. **System Settings** → **Network**
2. Click **+** button (bottom left)
3. Select:
   - **Interface**: VPN
   - **VPN Type**: L2TP over IPsec
   - **Service Name**: Soft-VPN
4. Click **Create**
5. Configure:
   - **Server Address**: `172.105.123.45` (YOUR Linode IP)
   - **Account Name**: `vpnuser`
6. Click **Authentication Settings...**
   - **Password**: `Ef89GhIj012KlMn34567` (YOUR VPN password)
   - **Shared Secret**: `Op78QrSt901UvWx23456` (YOUR PSK)
7. Click **OK**
8. Click **Apply**
9. Click **Connect**

### Step 9: Verify VPN is Working

**On your device** (iPhone/iPad/Mac):

1. **Check your IP address**:
   - Open browser
   - Go to: https://whatismyipaddress.com/
   - Should show your **Linode IP** (not your home IP)

2. **Test internet**:
   - Browse websites
   - Should work normally
   - All traffic goes through VPN

---

## Part 5: Server Management

### Step 10: Useful Commands

**From your local machine**, manage your Linode VPN:

1. **Check VPN status**:
   ```bash
   ssh root@172.105.123.45 '/opt/softvpn/vpn-status.sh'
   ```

2. **Restart VPN server**:
   ```bash
   ssh root@172.105.123.45 'systemctl restart softvpn'
   ```

3. **View credentials again**:
   ```bash
   ssh root@172.105.123.45 'cat /etc/softvpn/credentials.txt'
   ```

4. **View client setup instructions**:
   ```bash
   ssh root@172.105.123.45 'cat /etc/softvpn/clients/ios-macos-setup.txt'
   ```

5. **Access admin console**:
   ```bash
   ssh root@172.105.123.45 '/opt/softvpn/vpn-admin.sh'
   ```

6. **View active VPN sessions**:
   ```bash
   ssh root@172.105.123.45 'cd /opt/softvpn/vpnserver && ./vpncmd localhost /SERVER /HUB:VPN /CMD SessionList'
   ```

---

## Quick Reference Card

### Your Server Info
```
Linode IP:       172.105.123.45 (REPLACE WITH YOURS)
SSH Access:      ssh root@172.105.123.45
Admin Password:  (see softvpn-credentials.txt)
VPN Username:    vpnuser
VPN Password:    (see softvpn-credentials.txt)
Pre-Shared Key:  (see softvpn-credentials.txt)
```

### Firewall Penetration Ports (in order of effectiveness)
```
Port 443  - SSL-VPN (HTTPS)        ⭐⭐⭐⭐⭐ BEST
ICMP      - VPN over Ping          ⭐⭐⭐⭐
DNS       - VPN over DNS            ⭐⭐⭐⭐
Port 1194 - OpenVPN                 ⭐⭐⭐⭐
Port 500  - IPsec (iPhone/Mac)     ⭐⭐⭐
```

### Emergency Commands
```bash
# If VPN stops working:
ssh root@172.105.123.45 'systemctl restart softvpn'

# If server is unresponsive:
# Use Linode Cloud Manager → Reboot

# View logs:
ssh root@172.105.123.45 'journalctl -u softvpn -n 100'
```

---

## Advanced: For Maximum Firewall Penetration

If L2TP/IPsec is blocked by restrictive firewalls:

### Option 1: Use SoftEther Client (Mac)

1. **Download**: https://www.softether.org/
2. **Install** SoftEther VPN Client for macOS
3. **Create connection**:
   - Server: `172.105.123.45:443` (YOUR IP + :443)
   - Hub: `VPN`
   - Username: `vpnuser`
   - Password: (your VPN password)
4. **Enable** "VPN over ICMP" and "VPN over DNS" in settings
5. **Connect** - Works even through most firewalls!

### Option 2: VPN over ICMP (Ping-based)

Already enabled on your server. Use SoftEther client with "VPN over ICMP" enabled.

### Option 3: VPN over DNS

Already enabled on your server. Use SoftEther client with "VPN over DNS" enabled.

---

## Troubleshooting

### Problem: Cannot connect to VPN

**Solution 1**: Check if VPN is running
```bash
ssh root@172.105.123.45 'systemctl status softvpn'
```

**Solution 2**: Check if ports are open
```bash
ssh root@172.105.123.45 'netstat -tulpn | grep vpnserver'
```

**Solution 3**: Verify Linode Firewall allows VPN ports
- Go to Linode Cloud Manager → Firewalls
- Check rules include all VPN ports

**Solution 4**: Restart VPN
```bash
ssh root@172.105.123.45 'systemctl restart softvpn'
```

### Problem: VPN connects but no internet

**Solution**: Restart server
```bash
ssh root@172.105.123.45 'reboot'
```
Wait 2 minutes, then try VPN again.

### Problem: Lost credentials

**Solution 1**: Check local file
```bash
cat ~/softvpn-install/ia-router/softvpn-credentials.txt
```

**Solution 2**: Check server
```bash
ssh root@172.105.123.45 'cat /etc/softvpn/credentials.txt'
```

---

## Security Tips

1. **Save credentials securely**:
   ```bash
   # Copy to secure location
   cp softvpn-credentials.txt ~/Documents/SECURE/

   # Delete from installer directory
   rm softvpn-credentials.txt
   ```

2. **Keep server updated**:
   ```bash
   ssh root@172.105.123.45 'apt update && apt upgrade -y'
   ```

3. **Monitor VPN usage**:
   ```bash
   ssh root@172.105.123.45 '/opt/softvpn/vpn-status.sh'
   ```

4. **Backup credentials**: Store in password manager (1Password, LastPass, etc.)

---

## Cost Estimate

- **Linode Nanode 1GB**: $5/month (1-5 users)
- **Linode 2GB**: $12/month (5-20 users)
- **Linode 4GB**: $24/month (20+ users)

Plus minimal bandwidth costs (usually included).

---

## Next Steps

1. ✅ Connect all your devices (iPhone, iPad, Mac)
2. ✅ Test VPN from different networks
3. ✅ Bookmark this guide for future reference
4. ✅ Save credentials in password manager
5. ✅ Share VPN with trusted family/friends if needed

---

**🎉 Congratulations! Your Soft-VPN is ready!**

For detailed documentation, see `README.md` and `TROUBLESHOOTING.md` in the repository.
