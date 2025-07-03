#!/bin/bash

# Fix Cloudflare Tunnel 404 and SSL Issues
# Comprehensive fix for tunnel problems

set -e

echo "🔧 Fixing Cloudflare Tunnel 404 and SSL Issues"
echo "=============================================="

DOMAIN="evergiven.focacciafowl.com"

# Step 1: Ensure EverGiven API is running
echo "🚀 Step 1: Ensuring EverGiven API is running..."
if ! docker ps | grep -q evergiven; then
    echo "📦 Starting EverGiven API..."
    ./docker-compose-wrapper.sh up -d api
    sleep 10
else
    echo "✅ EverGiven API is already running"
fi

# Step 2: Test local API
echo ""
echo "🏠 Step 2: Testing local API..."
LOCAL_RESPONSE=$(curl -s --connect-timeout 5 "http://localhost:8080/health" 2>/dev/null)
if [ -n "$LOCAL_RESPONSE" ]; then
    echo "✅ Local API is working"
else
    echo "❌ Local API not responding - starting it..."
    ./docker-compose-wrapper.sh restart api
    sleep 5
fi

# Step 3: Update tunnel configuration
echo ""
echo "⚙️  Step 3: Updating tunnel configuration..."
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

# Get tunnel ID - improved parsing
echo "📋 Available tunnels:"
cloudflared tunnel list

echo ""
echo "Enter the tunnel ID from the list above:"
read TUNNEL_ID

if [ -z "$TUNNEL_ID" ]; then
    echo "❌ No tunnel ID provided. Creating new tunnel..."
    TUNNEL_NAME="evergiven-$(date +%s)"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
    echo "✅ Created new tunnel: $TUNNEL_ID"
fi

echo "🚇 Using tunnel ID: $TUNNEL_ID"

# Verify tunnel exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_ID"; then
    echo "❌ Tunnel ID $TUNNEL_ID not found. Available tunnels:"
    cloudflared tunnel list
    exit 1
fi

# Create updated config
mkdir -p "$USER_HOME/.cloudflared"
cat > "$USER_HOME/.cloudflared/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $USER_HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

echo "✅ Configuration updated:"
cat "$USER_HOME/.cloudflared/config.yml"

# Step 4: Route DNS
echo ""
echo "🌍 Step 4: Setting up DNS routing..."
cloudflared tunnel route dns $TUNNEL_ID $DOMAIN

# Step 5: Update systemd service
echo ""
echo "🔧 Step 5: Updating systemd service..."
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

# Step 6: Restart services
echo ""
echo "🔄 Step 6: Restarting services..."
sudo systemctl daemon-reload
sudo systemctl restart cloudflared

# Wait for tunnel to establish
echo ""
echo "⏳ Waiting for tunnel to establish..."
sleep 15

# Step 7: Test the connection
echo ""
echo "🧪 Step 7: Testing connection..."
echo "Testing https://$DOMAIN/health..."

# Test multiple times with retry
for i in {1..5}; do
    echo "Attempt $i/5..."
    HEALTH_RESPONSE=$(curl -s --connect-timeout 10 "https://$DOMAIN/health" 2>/dev/null)
    if [ -n "$HEALTH_RESPONSE" ]; then
        echo "✅ Success! Health endpoint responds:"
        echo "$HEALTH_RESPONSE"
        break
    else
        echo "❌ Attempt $i failed, retrying..."
        sleep 5
    fi
done

# Final status check
echo ""
echo "📊 Final status check:"
sudo systemctl status cloudflared --no-pager

echo ""
echo "🎉 Tunnel fix complete!"
echo "======================"
echo "🌐 Your API should now be available at:"
echo "   https://$DOMAIN"
echo ""
echo "🤖 For ChatGPT Custom GPT, use:"
echo "   Base URL: https://$DOMAIN"
echo ""
echo "📝 If issues persist, check logs:"
echo "   sudo journalctl -u cloudflared -f" 