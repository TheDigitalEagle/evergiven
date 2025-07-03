#!/bin/bash

# EverGiven Raspberry Pi 5 Deployment Script
# This script sets up the EverGiven API on a Raspberry Pi 5

set -e

echo "🚀 EverGiven Raspberry Pi 5 Deployment Script"
echo "=============================================="

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi 5"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed. Please log out and back in, then run this script again."
    exit 0
fi

# Check for Docker Compose (newer versions use 'docker compose' without hyphen)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "📋 Installing Docker Compose..."
    sudo apt-get install docker-compose-plugin -y
    # Check again after installation
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "❌ Failed to install Docker Compose"
        exit 1
    fi
fi

echo "🔧 Using Docker Compose command: $DOCKER_COMPOSE_CMD"

# Create data directory
echo "📁 Creating data directory..."
mkdir -p ./data
sudo chown -R $USER:$USER ./data

# Get Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Your Pi's IP address is: $PI_IP"

# Create environment file
echo "⚙️  Creating environment configuration..."
cat > .env << EOF
# EverGiven Configuration for Raspberry Pi 5
DATABASE_URL=sqlite:///app/evergiven.db
PORT=8080
PI_IP=$PI_IP
EOF

# Build and start the application
echo "🔨 Building and starting EverGiven API..."
$DOCKER_COMPOSE_CMD up -d api

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 10

# Test the API
echo "🧪 Testing API health..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ API is running successfully!"
    echo ""
    echo "🎉 Deployment Complete!"
    echo "======================"
    echo "📊 API Health: http://$PI_IP:8080/health"
    echo "📋 API Base URL: http://$PI_IP:8080"
    echo "📖 API Documentation: http://$PI_IP:8080/orders"
    echo ""
    echo "🤖 For Custom GPT Integration:"
    echo "   Use base URL: http://$PI_IP:8080"
    echo "   Available endpoints:"
    echo "   - GET /health"
    echo "   - GET /orders"
    echo "   - POST /orders"
    echo "   - PUT /orders/{id}"
    echo "   - DELETE /orders/{id}"
    echo ""
    echo "📊 Monitor with: docker stats"
    echo "📝 View logs with: $DOCKER_COMPOSE_CMD logs -f api"
    echo "🛑 Stop with: $DOCKER_COMPOSE_CMD down"
else
    echo "❌ API health check failed"
    echo "📝 Check logs with: $DOCKER_COMPOSE_CMD logs api"
    exit 1
fi

# Optional: Set up auto-start
read -p "🤔 Set up auto-start on boot? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Setting up auto-start..."
    sudo systemctl enable docker
    echo "✅ Docker will start automatically on boot"
    echo "💡 To auto-start EverGiven, add to /etc/rc.local:"
    echo "   cd $(pwd) && $DOCKER_COMPOSE_CMD up -d api"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Configure your Custom GPT with the API URL"
echo "2. Test the API endpoints"
echo "3. Set up monitoring and backups"
echo ""
echo "📚 For more information, see README.md" 