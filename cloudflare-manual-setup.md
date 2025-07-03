# Cloudflare Tunnel Manual Setup

## 🔧 Fix the Current Issue

Your tunnel is crashing because the config file has a placeholder hostname. Here's how to fix it:

### Step 1: Stop the Service
```bash
sudo systemctl stop cloudflared
```

### Step 2: List Your Tunnels
```bash
cloudflared tunnel list
```

### Step 3: Create Correct Config File
```bash
# Replace TUNNEL_ID with your actual tunnel ID
# Replace your-domain.com with your actual domain

mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: ~/.cloudflared/YOUR_TUNNEL_ID_HERE.json

ingress:
  - hostname: evergiven.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
EOF
```

### Step 4: Validate Configuration
```bash
cloudflared tunnel --config ~/.cloudflared/config.yml ingress validate
```

### Step 5: Start Service
```bash
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

## 🚀 Quick Fix Script

Or use the automated fix script:
```bash
chmod +x fix-cloudflare-tunnel.sh
./fix-cloudflare-tunnel.sh
```

## 📋 Troubleshooting

### Check if credentials exist:
```bash
ls -la ~/.cloudflared/*.json
```

### Check service logs:
```bash
sudo journalctl -u cloudflared -f
```

### Test tunnel manually:
```bash
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

## 🔍 Common Issues

1. **"no such file or directory"**: Config file has wrong path
2. **"credentials file not found"**: Need to run `cloudflared tunnel login`
3. **"hostname not found"**: DNS not configured properly

## ✅ Success Indicators

- Service status shows "active (running)"
- No errors in logs
- `https://your-domain.com/health` returns JSON response 