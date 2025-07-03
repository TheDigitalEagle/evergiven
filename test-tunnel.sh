#!/bin/bash

# Test Cloudflare Tunnel Connection
# Diagnoses 404 and SSL issues

echo "🧪 Testing Cloudflare Tunnel Connection"
echo "======================================"

DOMAIN="evergiven.focacciafowl.com"

echo "🌐 Testing domain: $DOMAIN"
echo ""

# Test basic connectivity
echo "📡 Testing basic connectivity..."
if curl -s --connect-timeout 10 "https://$DOMAIN" > /dev/null; then
    echo "✅ Domain is reachable"
else
    echo "❌ Domain is not reachable"
fi

# Test health endpoint
echo ""
echo "🏥 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s --connect-timeout 10 "https://$DOMAIN/health" 2>/dev/null)
if [ -n "$HEALTH_RESPONSE" ]; then
    echo "✅ Health endpoint responds:"
    echo "$HEALTH_RESPONSE"
else
    echo "❌ Health endpoint not responding"
fi

# Test local API
echo ""
echo "🏠 Testing local API..."
LOCAL_RESPONSE=$(curl -s --connect-timeout 5 "http://localhost:8080/health" 2>/dev/null)
if [ -n "$LOCAL_RESPONSE" ]; then
    echo "✅ Local API is working:"
    echo "$LOCAL_RESPONSE"
else
    echo "❌ Local API not responding"
fi

# Check tunnel status
echo ""
echo "🚇 Checking tunnel status..."
sudo systemctl status cloudflared --no-pager

# Check tunnel logs
echo ""
echo "📝 Recent tunnel logs:"
sudo journalctl -u cloudflared --no-pager -n 10

# Test SSL certificate
echo ""
echo "🔒 Testing SSL certificate..."
SSL_INFO=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
if [ -n "$SSL_INFO" ]; then
    echo "✅ SSL certificate info:"
    echo "$SSL_INFO"
else
    echo "❌ SSL certificate issue"
fi

echo ""
echo "🎯 Troubleshooting steps:"
echo "1. Ensure EverGiven API is running: ./docker-compose-wrapper.sh up -d api"
echo "2. Check tunnel configuration: ./check-cloudflare-status.sh"
echo "3. Restart tunnel: sudo systemctl restart cloudflared" 