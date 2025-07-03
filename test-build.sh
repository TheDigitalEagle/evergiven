#!/bin/bash

# Test build script for EverGiven
# Tests both SQLite and PostgreSQL builds

set -e

echo "🧪 Testing EverGiven builds..."
echo "================================"

# Test SQLite build (with CGO)
echo "🔨 Testing SQLite build (CGO enabled)..."
CGO_ENABLED=1 go build -o evergiven-sqlite main.go
if [ -f "evergiven-sqlite" ]; then
    echo "✅ SQLite build successful"
    rm evergiven-sqlite
else
    echo "❌ SQLite build failed"
    exit 1
fi

# Test PostgreSQL build (without CGO)
echo "🔨 Testing PostgreSQL build (CGO disabled)..."
CGO_ENABLED=0 go build -o evergiven-postgres main.go
if [ -f "evergiven-postgres" ]; then
    echo "✅ PostgreSQL build successful"
    rm evergiven-postgres
else
    echo "❌ PostgreSQL build failed"
    exit 1
fi

echo ""
echo "🎉 All builds successful!"
echo "================================"
echo "✅ SQLite build (CGO_ENABLED=1) - Ready for Pi deployment"
echo "✅ PostgreSQL build (CGO_ENABLED=0) - Ready for production"
echo ""
echo "🚀 Ready to deploy on Raspberry Pi 5!" 