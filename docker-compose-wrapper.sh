#!/bin/bash

# Docker Compose Wrapper Script
# Automatically detects and uses the correct Docker Compose command

# Function to detect Docker Compose command
detect_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "ERROR: Docker Compose not found"
        exit 1
    fi
}

# Get the correct command
DOCKER_COMPOSE_CMD=$(detect_docker_compose)

if [[ "$DOCKER_COMPOSE_CMD" == "ERROR:"* ]]; then
    echo "❌ $DOCKER_COMPOSE_CMD"
    echo "💡 Install Docker Compose with: sudo apt-get install docker-compose-plugin"
    exit 1
fi

echo "🔧 Using: $DOCKER_COMPOSE_CMD"
echo ""

# Execute the command with all arguments
exec $DOCKER_COMPOSE_CMD "$@" 