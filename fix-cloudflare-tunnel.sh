#!/bin/bash

# Fix Cloudflare Tunnel Configuration
# This corrects the config file with the proper hostname

set -e

echo "🔧 Fixing Cloudflare Tunnel Configuration..."
echo "============================================"

# Stop the service
echo "🛑 Stopping cloudflared service..."
sudo systemctl stop cloudflared

# Get current tunnel info
echo "📋 Getting tunnel information..."
TUNNELS=$(cloudflared tunnel list)
echo "$TUNNELS"

# Get tunnel ID
echo ""
echo "Enter the tunnel ID from the list above:"
read TUNNEL_ID

# Get domain information
echo ""
echo "Enter your full domain (e.g., evergiven.yourdomain.com):"
read FULL_HOSTNAME

# Create corrected config file
echo ""
echo "⚙️  Creating corrected configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: ~/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $FULL_HOSTNAME
    service: http://localhost:8080
  - service: http_status:404
EOF

echo "✅ Configuration file created:"
echo "   ~/.cloudflared/config.yml"
echo ""
cat ~/.cloudflared/config.yml

# Verify credentials file exists
if [ ! -f ~/.cloudflared/$TUNNEL_ID.json ]; then
    echo "❌ Credentials file not found: ~/.cloudflared/$TUNNEL_ID.json"
    echo "Please run: cloudflared tunnel login"
    exit 1
fi

# Test the configuration
echo ""
echo "🧪 Testing configuration..."
cloudflared tunnel --config ~/.cloudflared/config.yml ingress validate

# Start the service
echo ""
echo "🚀 Starting cloudflared service..."
sudo systemctl start cloudflared

# Check status
echo ""
echo "📊 Service status:"
sudo systemctl status cloudflared --no-pager

echo ""
echo "🎉 Tunnel configuration fixed!"
echo "=============================="
echo "🌐 Your API is now available at:"
echo "   https://$FULL_HOSTNAME"
echo ""
echo "🤖 For ChatGPT Custom GPT, use:"
echo "   Base URL: https://$FULL_HOSTNAME"
echo ""
echo "📝 View logs:"
echo "   sudo journalctl -u cloudflared -f" 