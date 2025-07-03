#!/bin/bash

# Cloudflare Tunnel Setup for EverGiven
# This creates a secure HTTPS tunnel to your Raspberry Pi

set -e

echo "🌐 Setting up Cloudflare Tunnel for EverGiven..."
echo "================================================"

# Install cloudflared
echo "📦 Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    echo "✅ cloudflared installed"
else
    echo "✅ cloudflared already installed"
fi

# Login to Cloudflare
echo ""
echo "🔐 Logging into Cloudflare..."
echo "Please follow the browser authentication..."
cloudflared tunnel login

# Create tunnel
echo ""
echo "🚇 Creating tunnel..."
TUNNEL_NAME="evergiven-$(date +%s)"
cloudflared tunnel create $TUNNEL_NAME

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')

# Create config file
echo ""
echo "⚙️  Creating tunnel configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: ~/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: evergiven.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
EOF

# Route DNS
echo ""
echo "🌍 Setting up DNS routing..."
echo "Enter your domain (e.g., yourdomain.com):"
read DOMAIN
echo "Enter subdomain (e.g., evergiven):"
read SUBDOMAIN

FULL_HOSTNAME="$SUBDOMAIN.$DOMAIN"
cloudflared tunnel route dns $TUNNEL_NAME $FULL_HOSTNAME

# Create systemd service
echo ""
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel --config ~/.cloudflared/config.yml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

echo ""
echo "🎉 Cloudflare Tunnel Setup Complete!"
echo "====================================="
echo "🌐 Your API is now available at:"
echo "   https://$FULL_HOSTNAME"
echo ""
echo "🤖 For ChatGPT Custom GPT, use:"
echo "   Base URL: https://$FULL_HOSTNAME"
echo ""
echo "📊 Check tunnel status:"
echo "   sudo systemctl status cloudflared"
echo ""
echo "📝 View tunnel logs:"
echo "   sudo journalctl -u cloudflared -f" 