#!/bin/bash

# ngrok Setup for EverGiven
# Alternative to Cloudflare Tunnel

set -e

echo "🌐 Setting up ngrok for EverGiven..."
echo "===================================="

# Install ngrok
echo "📦 Installing ngrok..."
if ! command -v ngrok &> /dev/null; then
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok
    echo "✅ ngrok installed"
else
    echo "✅ ngrok already installed"
fi

# Authenticate ngrok
echo ""
echo "🔐 Authenticating ngrok..."
echo "Please enter your ngrok authtoken (get it from https://dashboard.ngrok.com/get-started/your-authtoken):"
read AUTHTOKEN
ngrok config add-authtoken $AUTHTOKEN

# Create systemd service
echo ""
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/ngrok.service > /dev/null << EOF
[Unit]
Description=ngrok tunnel for EverGiven
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/ngrok http 8080 --log=stdout
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ngrok
sudo systemctl start ngrok

echo ""
echo "🎉 ngrok Setup Complete!"
echo "========================"
echo "🌐 Your API will be available at:"
echo "   https://[random-subdomain].ngrok.io"
echo ""
echo "📊 Check ngrok status:"
echo "   sudo systemctl status ngrok"
echo ""
echo "📝 View ngrok logs:"
echo "   sudo journalctl -u ngrok -f"
echo ""
echo "🌍 Get your public URL:"
echo "   curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'"
echo ""
echo "🤖 For ChatGPT Custom GPT, use the ngrok URL above" 