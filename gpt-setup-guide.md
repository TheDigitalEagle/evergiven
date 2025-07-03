# ChatGPT Custom GPT Setup Guide

## 🎯 Overview

This guide shows how to integrate your EverGiven API with ChatGPT Custom GPTs using OpenAPI 3.1.0 specification.

## 📋 Prerequisites

1. **EverGiven API running** on Raspberry Pi
2. **HTTPS tunnel** (Cloudflare or ngrok) configured
3. **OpenAPI specification** file ready

## 🚀 Step-by-Step Setup

### Step 1: Deploy EverGiven API

```bash
# On your Raspberry Pi
./deploy-pi.sh
# Choose SQLite when prompted
```

### Step 2: Set Up HTTPS Tunnel

#### Option A: Cloudflare Tunnel (Recommended)
```bash
./cloudflare-tunnel-setup.sh
# Follow prompts to set up your domain
```

#### Option B: ngrok (Alternative)
```bash
./ngrok-setup.sh
# Get your ngrok URL
```

### Step 3: Update OpenAPI Specification

Edit `openapi.yaml` and update the server URL:

```yaml
servers:
  - url: https://your-domain.com  # Replace with your actual URL
    description: Production server
```

### Step 4: Configure ChatGPT Custom GPT

1. **Go to ChatGPT Custom GPTs**
   - Visit: https://chat.openai.com/gpts
   - Click "Create a GPT"

2. **Configure the GPT**
   - **Name**: "EverGiven Order Manager"
   - **Description**: "Manage and track orders from China with dual currency support"

3. **Add Actions**
   - Click "Add actions"
   - Choose "Import from OpenAPI spec"
   - Upload your `openapi.yaml` file
   - Set the server URL to your HTTPS endpoint

4. **Test the Integration**
   - Try: "Show me all my orders"
   - Try: "Create a new order for 5 wireless earbuds at 299.99 CNY each"

## 🔧 Troubleshooting

### Common Issues

1. **"Could not find a valid URL in servers"**
   - Ensure you're using HTTPS URLs
   - Check that your tunnel is working

2. **"API not responding"**
   - Verify EverGiven API is running: `./docker-compose-wrapper.sh ps`
   - Check tunnel status: `sudo systemctl status cloudflared`

3. **"SSL certificate not secure"**
   - Use the tunnel fix script: `./fix-tunnel-issues.sh`
   - Ensure DNS is properly configured

### Testing Your Setup

```bash
# Test local API
curl http://localhost:8080/health

# Test tunnel
curl https://your-domain.com/health

# Check tunnel logs
sudo journalctl -u cloudflared -f
```

## 📊 API Endpoints

Your GPT will have access to these endpoints:

- `GET /health` - Check API status
- `GET /orders` - List all orders
- `POST /orders` - Create new order
- `PUT /orders/{id}` - Update order
- `DELETE /orders/{id}` - Delete order

## 🎯 Example GPT Prompts

- "Show me all my orders from China"
- "Create a new order for 10 wireless earbuds at 299.99 CNY each"
- "Update the tracking number for order #5 to TRK123456789"
- "What's the total value of all my orders in USD?"
- "Delete order #3"

## 🔒 Security Notes

- **HTTPS Required**: ChatGPT only accepts HTTPS URLs
- **Authentication**: Optional API key support included
- **CORS**: Configured for GPT access
- **Rate Limiting**: Consider adding for production use

## 📝 Files Used

- `openapi.yaml` - OpenAPI 3.1.0 specification
- `main.go` - API implementation
- `docker-compose.yml` - Container configuration
- `cloudflare-tunnel-setup.sh` - Tunnel setup
- `fix-tunnel-issues.sh` - Troubleshooting

## ✅ Success Indicators

- ✅ GPT can list orders
- ✅ GPT can create new orders
- ✅ GPT can update existing orders
- ✅ GPT can delete orders
- ✅ All responses include dual currency (CNY/USD) 