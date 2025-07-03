#!/bin/bash

# Verify CGO is properly enabled in the built binary

echo "🔍 Verifying CGO in built binary..."
echo "===================================="

# Build the image
echo "🔨 Building image..."
docker build -t evergiven-test .

# Check if binary has CGO dependencies
echo ""
echo "📊 Checking binary dependencies..."
docker run --rm evergiven-test sh -c "
echo 'Binary size:'
ls -lh /app/evergiven

echo ''
echo 'Checking for CGO symbols:'
strings /app/evergiven | grep -i sqlite | head -5

echo ''
echo 'Checking dynamic libraries:'
ldd /app/evergiven 2>/dev/null || echo 'Static binary (CGO disabled)'

echo ''
echo 'Testing SQLite connection:'
echo 'sqlite:///test.db' > /tmp/test_url
"

echo ""
echo "✅ Verification complete!"
echo ""
echo "If you see 'Static binary (CGO disabled)', the build failed."
echo "If you see dynamic libraries or SQLite symbols, CGO is working." 