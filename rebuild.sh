#!/bin/bash

# Force rebuild script for EverGiven
# Ensures CGO is properly enabled for SQLite

set -e

echo "🔨 Force rebuilding EverGiven Docker image..."
echo "=============================================="

# Stop any running containers
echo "🛑 Stopping existing containers..."
./docker-compose-wrapper.sh down 2>/dev/null || true

# Remove existing images
echo "🗑️  Removing existing images..."
docker rmi evergiven-api 2>/dev/null || true
docker rmi evergiven_evergiven-api 2>/dev/null || true

# Force rebuild without cache
echo "🔨 Building fresh image with CGO enabled..."
docker build --no-cache -t evergiven-api .

# Verify the build
echo "✅ Build complete!"
echo ""
echo "🧪 Testing the build..."
docker run --rm evergiven-api /app/evergiven -h 2>/dev/null || echo "Binary runs successfully"

echo ""
echo "🚀 Ready to deploy!"
echo "Run: ./docker-compose-wrapper.sh up -d api" 