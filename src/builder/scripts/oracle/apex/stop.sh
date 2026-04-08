#!/bin/bash
################################################################################
# Stop Oracle APEX/ORDS
################################################################################

echo "🛑 Stopping Oracle APEX..."

# Check if container is running
if ! docker ps | grep -q "demasy-server"; then
    echo "❌ Error: demasy-server container is not running"
    exit 1
fi

# Stop ORDS
docker exec demasy-server stop-ords
