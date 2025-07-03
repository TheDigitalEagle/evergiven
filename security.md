# Security Guide for EverGiven + ChatGPT Custom GPT

## 🔒 ChatGPT Custom GPT Requirements

### **Local Network Deployment (Recommended)**
✅ **Port 8080**: Perfectly fine  
✅ **HTTP (no SSL)**: Acceptable for local access  
✅ **No Authentication**: Works by default  

### **Internet Deployment (Production)**
❌ **HTTP only**: NOT allowed by ChatGPT  
✅ **HTTPS required**: Must use SSL/TLS  
✅ **Authentication**: Highly recommended  

## 🏠 Home Network Setup

```yaml
# gpt-config.yaml
base_url: "http://YOUR_PI_IP:8080"
```

**Why this works:**
- ChatGPT can access local network IPs
- No SSL certificate needed
- Simple and secure within your network
- No external exposure

## 🌐 Internet Access (If Needed)

If you need internet access for your GPT:

### Option 1: Reverse Proxy with SSL
```bash
# Install nginx on Pi
sudo apt install nginx certbot python3-certbot-nginx

# Configure nginx reverse proxy
sudo nano /etc/nginx/sites-available/evergiven
```

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Option 2: Cloudflare Tunnel (Easiest)
```bash
# Install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared.deb

# Create tunnel
cloudflared tunnel create evergiven
cloudflared tunnel route dns evergiven your-subdomain.your-domain.com
```

## 🔐 Optional Authentication

If you want extra security, add API key authentication:

### 1. Set Environment Variable
```bash
# In your .env file or docker-compose.yml
API_KEY=your-secret-key-here
```

### 2. Update GPT Configuration
```yaml
# In your Custom GPT settings, add header:
headers:
  X-API-Key: your-secret-key-here
```

### 3. Test Authentication
```bash
# Test with curl
curl -H "X-API-Key: your-secret-key-here" http://YOUR_PI_IP:8080/orders
```

## 🛡️ Security Best Practices

### For Home Network:
1. **Firewall**: Ensure only port 8080 is open
2. **Network Isolation**: Keep Pi on separate VLAN if possible
3. **Regular Updates**: Keep Pi and Docker images updated
4. **Backup**: Regular database backups

### For Internet Access:
1. **SSL Certificate**: Always use HTTPS
2. **API Key**: Implement authentication
3. **Rate Limiting**: Prevent abuse
4. **Monitoring**: Log all access attempts

## 🚀 Quick Security Checklist

### ✅ Home Network (Current Setup)
- [ ] Pi on local network only
- [ ] Port 8080 accessible
- [ ] No external port forwarding
- [ ] Regular backups

### ✅ Internet Access (If Needed)
- [ ] SSL certificate installed
- [ ] API key authentication
- [ ] Domain configured
- [ ] Firewall rules set
- [ ] Monitoring enabled

## 🔍 Testing Your Setup

### Health Check
```bash
curl http://YOUR_PI_IP:8080/health
```

### API Test
```bash
curl http://YOUR_PI_IP:8080/orders
```

### With Authentication (if enabled)
```bash
curl -H "X-API-Key: your-key" http://YOUR_PI_IP:8080/orders
```

## 📝 ChatGPT Custom GPT Configuration

### Basic Setup (Home Network)
```yaml
name: "EverGiven Order Manager"
base_url: "http://YOUR_PI_IP:8080"
```

### Secure Setup (Internet)
```yaml
name: "EverGiven Order Manager"
base_url: "https://your-domain.com"
headers:
  X-API-Key: "your-secret-key"
```