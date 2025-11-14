#!/bin/bash

# Quick diagnostic script to check installation logs

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Soft-VPN Installation Log Checker                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ -f /tmp/softvpn-install.log ]; then
    echo "Full installation log:"
    echo "════════════════════════════════════════════════════════════"
    cat /tmp/softvpn-install.log
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Last 100 lines of log:"
    echo "════════════════════════════════════════════════════════════"
    tail -100 /tmp/softvpn-install.log
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Searching for errors..."
    echo "════════════════════════════════════════════════════════════"
    grep -i "error\|failed\|cannot\|denied" /tmp/softvpn-install.log | tail -20
else
    echo "Log file not found: /tmp/softvpn-install.log"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Additional diagnostics:"
echo "════════════════════════════════════════════════════════════"

# Check if vpnserver directory exists
if [ -d /tmp/vpnserver ]; then
    echo "✓ VPN server extracted to /tmp/vpnserver"
    ls -la /tmp/vpnserver/ | head -20
else
    echo "✗ VPN server directory not found in /tmp"
fi

echo ""
# Check system resources
echo "System information:"
echo "- Free disk space:"
df -h /tmp
echo ""
echo "- Free memory:"
free -h
echo ""
echo "- OS Version:"
cat /etc/os-release | grep -E "NAME|VERSION"
