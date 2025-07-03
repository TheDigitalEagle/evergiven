#!/bin/bash

# Check Docker image contents
echo "🔍 Checking Docker image contents..."
echo "====================================="

# Build the image
echo "🔨 Building image..."
docker build -t evergiven-test .

# Check image size
echo ""
echo "📊 Image size:"
docker images evergiven-test

# Check what's in the runtime image
echo ""
echo "📁 Runtime image contents:"
docker run --rm evergiven-test ls -la /app/

# Check if GCC is present (it shouldn't be)
echo ""
echo "🔍 Checking for GCC (should not be present):"
docker run --rm evergiven-test which gcc || echo "✅ GCC not found (good!)"

# Check SQLite runtime
echo ""
echo "🗄️ Checking SQLite runtime:"
docker run --rm evergiven-test which sqlite3 || echo "❌ SQLite not found"

echo ""
echo "🎉 Runtime image analysis complete!" 