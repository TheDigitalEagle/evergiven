#!/bin/bash

# Fix Cloudflare Tunnel User and Path Issues
# This ensures the service runs as the correct user with proper paths

set -e

echo "🔧 Fixing Cloudflare Tunnel User and Path Issues..."
echo "=================================================="

# Get current user and home directory
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

echo "👤 Current user: $CURRENT_USER"
echo "🏠 User home: $USER_HOME"

# Stop the service
echo "🛑 Stopping cloudflared service..."
sudo systemctl stop cloudflared

# Check if config file exists
if [ ! -f "$USER_HOME/.cloudflared/config.yml" ]; then
    echo "❌ Config file not found at: $USER_HOME/.cloudflared/config.yml"
    echo "Please run the fix-cloudflare-tunnel.sh script first"
    exit 1
fi

# Get tunnel ID from config
TUNNEL_ID=$(grep "tunnel:" "$USER_HOME/.cloudflared/config.yml" | awk '{print $2}')
echo "🚇 Tunnel ID: $TUNNEL_ID"

# Check if credentials file exists
if [ ! -f "$USER_HOME/.cloudflared/$TUNNEL_ID.json" ]; then
    echo "❌ Credentials file not found: $USER_HOME/.cloudflared/$TUNNEL_ID.json"
    echo "Please run: cloudflared tunnel login"
    exit 1
fi

# Create corrected systemd service with absolute paths
echo ""
echo "🔧 Creating corrected systemd service..."
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$USER_HOME
ExecStart=/usr/local/bin/cloudflared tunnel --config $USER_HOME/.cloudflared/config.yml run
Restart=always
RestartSec=5
Environment=HOME=$USER_HOME

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart service
echo ""
echo "🔄 Reloading systemd and restarting service..."
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Check status
echo ""
echo "📊 Service status:"
sudo systemctl status cloudflared --no-pager

# Show config file contents
echo ""
echo "📋 Current configuration:"
echo "Config file: $USER_HOME/.cloudflared/config.yml"
cat "$USER_HOME/.cloudflared/config.yml"

echo ""
echo "🎉 Cloudflare Tunnel user and path issues fixed!"
echo "================================================"
echo "👤 Service now runs as: $CURRENT_USER"
echo "🏠 Using home directory: $USER_HOME"
echo "📁 Config file: $USER_HOME/.cloudflared/config.yml"
echo ""
echo "📝 View logs:"
echo "   sudo journalctl -u cloudflared -f" 