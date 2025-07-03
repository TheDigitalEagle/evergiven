#!/bin/bash

# Fix CGO issue on Raspberry Pi
# This script forces a clean rebuild with CGO enabled

set -e

echo "🔧 Fixing CGO issue on Raspberry Pi..."
echo "======================================"

# Stop everything
echo "🛑 Stopping all containers..."
./docker-compose-wrapper.sh down 2>/dev/null || true

# Remove all related images
echo "🗑️  Cleaning up images..."
docker rmi evergiven-api 2>/dev/null || true
docker rmi evergiven_evergiven-api 2>/dev/null || true
docker rmi evergiven-evergiven-api 2>/dev/null || true

# Clean Docker build cache
echo "🧹 Cleaning build cache..."
docker builder prune -f

# Force rebuild with CGO enabled
echo "🔨 Rebuilding with CGO enabled..."
docker build --no-cache --build-arg CGO_ENABLED=1 -t evergiven-api .

# Verify the build
echo "✅ Verifying build..."
docker run --rm evergiven-api sh -c "
echo 'Checking binary:'
ls -la /app/evergiven
echo ''
echo 'Testing CGO:'
ldd /app/evergiven 2>/dev/null || echo 'Binary is static (CGO disabled)'
"

# Start the service
echo "🚀 Starting service..."
./docker-compose-wrapper.sh up -d api

echo ""
echo "🎉 CGO fix complete!"
echo "Check logs with: ./docker-compose-wrapper.sh logs -f api" 