#!/bin/bash
set -e

docker-compose down

read -p "This will remove all unused Docker data (including volumes). Continue? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  docker system prune -af --volumes
else
  echo "Prune cancelled."
fi

docker-compose build
docker-compose up -d

echo "Docker environment refreshed successfully."