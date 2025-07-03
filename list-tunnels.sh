#!/bin/bash

# List and select Cloudflare tunnels

echo "🚇 Cloudflare Tunnels"
echo "===================="

# Show all tunnels
echo "📋 Available tunnels:"
cloudflared tunnel list

echo ""
echo "🔍 To use a tunnel:"
echo "1. Copy the tunnel ID from above"
echo "2. Run: ./fix-cloudflare-tunnel.sh"
echo "3. Enter the tunnel ID when prompted"
echo ""
echo "🆕 To create a new tunnel:"
echo "   cloudflared tunnel create evergiven-$(date +%s)"
echo ""
echo "🗑️  To delete a tunnel:"
echo "   cloudflared tunnel delete TUNNEL_ID" 