#!/bin/bash
################################################################################
# Start Oracle APEX/ORDS
################################################################################

echo "🚀 Starting Oracle APEX..."

# Check if container is running
if ! docker ps | grep -q "demasy-server"; then
    echo "❌ Error: demasy-server container is not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi

# Start ORDS
docker exec demasy-server start-ords
