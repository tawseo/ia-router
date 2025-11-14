# Troubleshooting Guide - Soft-VPN

## Installation Issues

### Error: "ssh: connect to host X.X.X.X port 22: Connection refused"

**Cause**: Cannot connect to remote server via SSH

**Solutions**:
1. Verify server IP address is correct
2. Check if SSH service is running on remote server
3. Verify SSH port (default 22, may be changed)
4. Check firewall/security groups allow SSH access
5. Ensure you have the correct SSH credentials

```bash
# Test SSH connection manually
ssh -v root@your-server-ip

# Try alternative SSH port if changed
ssh -p 2222 root@your-server-ip
```

### Error: "Permission denied (publickey,password)"

**Cause**: SSH authentication failed

**Solutions**:
1. Verify username (try 'root' or 'admin' or server-specific user)
2. Check password is correct
3. If using SSH keys, ensure key is added:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```
4. Try password authentication:
   ```bash
   ssh -o PreferredAuthentications=password root@your-server-ip
   ```

### Error: "This installer is designed for Debian 12"

**Cause**: Wrong operating system detected

**Solutions**:
1. Verify you're running Debian 12:
   ```bash
   ssh root@your-server-ip 'cat /etc/os-release'
   ```
2. If you have Debian 12, you can continue anyway when prompted
3. For Ubuntu, minor modifications may be needed
4. For other distributions, significant changes required

### Installation Hangs During "Downloading SoftEther VPN Server"

**Cause**: Network issues or GitHub rate limiting

**Solutions**:
1. Wait a few minutes - large download
2. Check server internet connectivity:
   ```bash
   ssh root@your-server-ip 'curl -I https://github.com'
   ```
3. The script has fallback URLs, it will retry automatically
4. If persistent, download manually:
   ```bash
   ssh root@your-server-ip
   cd /tmp
   wget https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz
   ```

### Error: "Installation Failed - Check Logs"

**Cause**: Something went wrong during installation

**Solutions**:
1. Check local installation log:
   ```bash
   cat /tmp/softvpn-install.log
   ```
2. SSH to server and check:
   ```bash
   ssh root@your-server-ip 'cat /var/log/softvpn-install.log'
   ```
3. Common issues:
   - Insufficient disk space
   - Missing dependencies
   - Firewall blocking downloads
   - SELinux/AppArmor restrictions

## Connection Issues

### iPhone/iPad: "The VPN server did not respond. Verify the server address."

**Cause**: Cannot reach VPN server

**Solutions**:
1. **Verify server is running**:
   ```bash
   ssh root@your-server-ip 'systemctl status softvpn'
   ```

2. **Check if ports are listening**:
   ```bash
   ssh root@your-server-ip 'netstat -tulpn | grep -E "443|500|1701|4500"'
   ```

3. **Verify firewall allows VPN ports**:
   ```bash
   ssh root@your-server-ip 'iptables -L -n | grep -E "443|500|1701|4500"'
   ```

4. **Check cloud provider security groups**:
   - AWS: Security Groups must allow UDP 500, 4500, 1701
   - Google Cloud: Firewall rules must allow VPN ports
   - Azure: Network Security Groups must allow VPN ports

5. **Test port connectivity from your location**:
   ```bash
   # From your local machine
   nc -zv your-server-ip 500
   nc -zv your-server-ip 4500
   nc -zv your-server-ip 1701
   ```

### iPhone/iPad: "A configuration error occurred. Verify your settings and try again."

**Cause**: Incorrect VPN credentials

**Solutions**:
1. **Double-check all fields**:
   - Server IP (not hostname if DNS issues)
   - Account: must be exactly `vpnuser`
   - Password: case-sensitive, copy-paste recommended
   - Secret (PSK): case-sensitive, copy-paste recommended

2. **Verify credentials on server**:
   ```bash
   ssh root@your-server-ip 'cat /etc/softvpn/credentials.txt'
   ```

3. **Common mistakes**:
   - Extra spaces before/after password
   - Using admin password instead of VPN password
   - Using password where PSK should be
   - Wrong VPN type selected (must be L2TP)

### macOS: "The VPN connection could not be established"

**Cause**: Similar to iPhone - server unreachable or wrong credentials

**Solutions**:
1. Open **Console.app** on Mac
2. Search for "VPN" or "IPsec" to see detailed error messages
3. Common errors:
   - **"No response from server"**: Firewall blocking ports
   - **"Authentication failed"**: Wrong credentials
   - **"Shared secret incorrect"**: Wrong PSK

4. **Try alternative port** (if 500/4500 are blocked):
   ```bash
   # Use SoftEther client instead
   # It can use port 443 which is rarely blocked
   ```

### VPN Connects But No Internet Access

**Cause**: Routing or NAT issues on server

**Solutions**:
1. **Check IP forwarding**:
   ```bash
   ssh root@your-server-ip 'sysctl net.ipv4.ip_forward'
   # Should show: net.ipv4.ip_forward = 1
   ```

2. **Verify NAT rules**:
   ```bash
   ssh root@your-server-ip 'iptables -t nat -L -n -v'
   # Should show MASQUERADE rule
   ```

3. **Check SecureNAT status**:
   ```bash
   ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
   # In admin console:
   Hub VPN
   SecureNatStatusGet
   ```

4. **Restart VPN server**:
   ```bash
   ssh root@your-server-ip 'systemctl restart softvpn'
   ```

5. **Check DNS resolution**:
   ```bash
   # While connected to VPN
   nslookup google.com
   # Should resolve successfully
   ```

### Connection Works But Very Slow

**Cause**: Network congestion, encryption overhead, or routing issues

**Solutions**:
1. **Check server load**:
   ```bash
   ssh root@your-server-ip 'top -n 1'
   # Check CPU and memory usage
   ```

2. **Test server bandwidth**:
   ```bash
   ssh root@your-server-ip 'curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
   ```

3. **Reduce encryption if not critical**:
   - L2TP/IPsec uses strong encryption
   - For speed over security, consider OpenVPN with reduced encryption
   - Best balance: Use SSL-VPN on port 443

4. **Check latency**:
   ```bash
   # While connected to VPN
   ping 8.8.8.8
   # High latency (>200ms) indicates network issues
   ```

## Firewall Bypass Issues

### VPN Blocked by Restrictive Firewall (Russia, China, etc.)

**Cause**: Deep Packet Inspection (DPI) detecting VPN traffic

**Solutions**:
1. **Use SSL-VPN on port 443** (primary method):
   - Download SoftEther VPN Client
   - Connect to: `your-server-ip:443`
   - Appears as normal HTTPS traffic

2. **Enable VPN over ICMP**:
   ```bash
   # Already enabled by installer
   # Use SoftEther client and enable "VPN over ICMP"
   # Works through ping packets
   ```

3. **Enable VPN over DNS**:
   ```bash
   # Already enabled by installer
   # Use SoftEther client and enable "VPN over DNS"
   # Works through DNS queries
   ```

4. **Use obfuscation**:
   - SoftEther automatically obfuscates on port 443
   - Appears as standard SSL/TLS traffic
   - Very difficult for DPI to detect

5. **Multi-hop VPN** (advanced):
   - Set up VPN in country with less restrictions
   - Chain to your primary VPN
   - Adds latency but increases bypass success

### Port 443 Still Blocked

**Cause**: Extreme firewall restrictions

**Solutions**:
1. **Verify port 443 is actually blocked**:
   ```bash
   # From restricted network
   curl -v https://your-server-ip:443
   ```

2. **Use VPN over ICMP (requires SoftEther client)**:
   - Works even when all TCP/UDP ports are blocked
   - Uses ICMP echo (ping) packets
   - Slower but very reliable

3. **Use VPN over DNS**:
   - Works through DNS queries
   - Very slow but bypasses most firewalls
   - Requires DNS server accessible

4. **Fronting technique** (advanced):
   - Use CDN domain fronting
   - Requires additional setup
   - Not covered in basic installation

## Server Issues

### Server Runs Out of Memory

**Symptoms**:
- VPN server crashes
- `systemctl status softvpn` shows "killed"
- Server becomes unresponsive

**Solutions**:
1. **Check memory usage**:
   ```bash
   ssh root@your-server-ip 'free -h'
   ```

2. **Add swap space**:
   ```bash
   ssh root@your-server-ip << 'EOF'
   dd if=/dev/zero of=/swapfile bs=1G count=2
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   echo '/swapfile none swap sw 0 0' >> /etc/fstab
   EOF
   ```

3. **Upgrade server**:
   - Minimum: 1GB RAM
   - Recommended: 2GB+ RAM for multiple users

### VPN Server Won't Start After Reboot

**Cause**: Service not enabled or dependency issue

**Solutions**:
1. **Check service status**:
   ```bash
   ssh root@your-server-ip 'systemctl status softvpn'
   ```

2. **Check service is enabled**:
   ```bash
   ssh root@your-server-ip 'systemctl is-enabled softvpn'
   ```

3. **Enable if disabled**:
   ```bash
   ssh root@your-server-ip 'systemctl enable softvpn'
   ```

4. **Check logs**:
   ```bash
   ssh root@your-server-ip 'journalctl -u softvpn -n 50'
   ```

5. **Manual start**:
   ```bash
   ssh root@your-server-ip 'systemctl start softvpn'
   ```

### Lost Admin Password

**Cause**: Forgot or lost admin password

**Solutions**:
1. **Check saved credentials**:
   ```bash
   ssh root@your-server-ip 'cat /etc/softvpn/credentials.txt'
   ```

2. **Check local credentials**:
   ```bash
   cat ./softvpn-credentials.txt
   ```

3. **Reset admin password** (requires server access):
   ```bash
   ssh root@your-server-ip
   cd /opt/softvpn/vpnserver
   systemctl stop softvpn
   ./vpnserver stop
   # Edit vpn_server.config and remove ServerPasswordHash line
   # Or reinstall
   ```

### Cannot Access Admin Console

**Cause**: Port 992 blocked or admin password incorrect

**Solutions**:
1. **Use local admin access**:
   ```bash
   ssh root@your-server-ip '/opt/softvpn/vpn-admin.sh'
   ```

2. **Check if port 992 is listening**:
   ```bash
   ssh root@your-server-ip 'netstat -tulpn | grep 992'
   ```

3. **Access from server itself** (always works):
   ```bash
   ssh root@your-server-ip
   cd /opt/softvpn/vpnserver
   ./vpncmd localhost /SERVER
   ```

## Client-Specific Issues

### iPhone/iPad Won't Save VPN Configuration

**Cause**: iOS restrictions or MDM (Mobile Device Management)

**Solutions**:
1. Check if device has MDM profile that restricts VPN
2. Try removing and re-adding configuration
3. Restart iPhone/iPad
4. Update iOS to latest version
5. Try on different Wi-Fi network (some networks block VPN config)

### macOS Shows "Configuration Error" Immediately

**Cause**: Malformed VPN configuration

**Solutions**:
1. Delete and recreate VPN configuration
2. Ensure no extra characters in any field
3. Use IP address instead of hostname
4. Check System Preferences → Network for conflicting VPN configs

### SoftEther Client Says "Connection Failed"

**Cause**: Multiple possible reasons

**Solutions**:
1. **Check connection settings**:
   - Server: `ip.add.re.ss:443` (include :443!)
   - Hub: `VPN` (case-sensitive)
   - Username: `vpnuser`
   - Password: correct VPN password

2. **Enable advanced features**:
   - Try enabling "VPN over ICMP"
   - Try enabling "VPN over DNS"
   - Enable "VPN over SSL"

3. **Check logs** in SoftEther client

4. **Verify server is reachable**:
   ```bash
   telnet your-server-ip 443
   ```

## Diagnostic Commands

### Complete Server Health Check

```bash
ssh root@your-server-ip << 'EOF'
echo "=== VPN Service Status ==="
systemctl status softvpn --no-pager

echo -e "\n=== Listening Ports ==="
netstat -tulpn | grep vpnserver

echo -e "\n=== IP Forwarding ==="
sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding

echo -e "\n=== NAT Rules ==="
iptables -t nat -L -n -v | grep MASQUERADE

echo -e "\n=== Firewall Rules ==="
iptables -L INPUT -n | grep -E "443|992|1194|5555|500|4500|1701"

echo -e "\n=== Memory Usage ==="
free -h

echo -e "\n=== Disk Usage ==="
df -h /opt/softvpn

echo -e "\n=== Server Uptime ==="
uptime

echo -e "\n=== Recent Errors ==="
journalctl -u softvpn -p err -n 10 --no-pager
EOF
```

### Check Active VPN Sessions

```bash
ssh root@your-server-ip << 'EOF'
cd /opt/softvpn/vpnserver
./vpncmd localhost /SERVER /HUB:VPN /CMD SessionList
EOF
```

### View Real-Time Logs

```bash
ssh root@your-server-ip 'journalctl -u softvpn -f'
```

## Getting Help

If none of these solutions work:

1. **Gather diagnostic information**:
   ```bash
   # Run complete health check (above)
   # Save output
   ```

2. **Check installation logs**:
   - Local: `/tmp/softvpn-install.log`
   - Server: `/var/log/softvpn-install.log`

3. **Check VPN server logs**:
   ```bash
   ssh root@your-server-ip 'ls -ltr /opt/softvpn/vpnserver/server_log/'
   ssh root@your-server-ip 'tail -100 /opt/softvpn/vpnserver/server_log/vpn_*.log'
   ```

4. **SoftEther VPN documentation**:
   - Official docs: https://www.softether.org/4-docs
   - Community forum: https://www.reddit.com/r/SoftEtherVPN/

## Prevention Tips

- **Regular backups** of `/etc/softvpn/credentials.txt`
- **Monitor server resources** (CPU, RAM, disk)
- **Keep system updated**: `apt update && apt upgrade`
- **Test VPN** after any server changes
- **Document any custom changes** you make
- **Keep credentials secure** but accessible

---

**Still having issues?** Review the complete [README.md](README.md) for detailed information.
