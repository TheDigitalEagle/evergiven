#!/bin/bash

# Check Cloudflare Tunnel Status
# Diagnoses user and path issues

echo "🔍 Cloudflare Tunnel Status Check"
echo "================================="

# Get current user info
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

echo "👤 Current user: $CURRENT_USER"
echo "🏠 User home: $USER_HOME"

# Check service status
echo ""
echo "📊 Service status:"
if systemctl is-active --quiet cloudflared; then
    echo "✅ Service is running"
else
    echo "❌ Service is not running"
fi

# Check service configuration
echo ""
echo "🔧 Service configuration:"
if [ -f /etc/systemd/system/cloudflared.service ]; then
    echo "✅ Service file exists"
    echo "Service user: $(grep '^User=' /etc/systemd/system/cloudflared.service | cut -d'=' -f2)"
    echo "ExecStart: $(grep '^ExecStart=' /etc/systemd/system/cloudflared.service | cut -d'=' -f2-)"
else
    echo "❌ Service file not found"
fi

# Check config file
echo ""
echo "📋 Config file check:"
CONFIG_PATH="$USER_HOME/.cloudflared/config.yml"
if [ -f "$CONFIG_PATH" ]; then
    echo "✅ Config file exists: $CONFIG_PATH"
    echo "Config contents:"
    cat "$CONFIG_PATH"
else
    echo "❌ Config file not found: $CONFIG_PATH"
fi

# Check credentials
echo ""
echo "🔐 Credentials check:"
if [ -f "$CONFIG_PATH" ]; then
    TUNNEL_ID=$(grep "tunnel:" "$CONFIG_PATH" | awk '{print $2}')
    if [ -n "$TUNNEL_ID" ]; then
        CRED_PATH="$USER_HOME/.cloudflared/$TUNNEL_ID.json"
        if [ -f "$CRED_PATH" ]; then
            echo "✅ Credentials file exists: $CRED_PATH"
        else
            echo "❌ Credentials file not found: $CRED_PATH"
        fi
    else
        echo "❌ Could not extract tunnel ID from config"
    fi
fi

# Check recent logs
echo ""
echo "📝 Recent service logs:"
sudo journalctl -u cloudflared --no-pager -n 10

# Check if cloudflared binary exists
echo ""
echo "🔧 Binary check:"
if command -v cloudflared &> /dev/null; then
    echo "✅ cloudflared binary found: $(which cloudflared)"
else
    echo "❌ cloudflared binary not found"
fi

echo ""
echo "🎯 Recommendations:"
if ! systemctl is-active --quiet cloudflared; then
    echo "1. Run: ./fix-cloudflare-user.sh"
elif [ ! -f "$CONFIG_PATH" ]; then
    echo "1. Run: ./fix-cloudflare-tunnel.sh"
else
    echo "1. Service appears to be working correctly"
fi 