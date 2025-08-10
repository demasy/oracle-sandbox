#!/bin/bash

# Healthcheck script for the server

# Define the server URL
SERVER_URL="http://localhost:3000/health"

# Perform the healthcheck
response=$(curl -s -o /dev/null -w "%{http_code}" $SERVER_URL)

# Check if the response code is 200 (OK)
if [ "$response" -eq 200 ]; then
  echo -e "\033[0;32mServer is healthy.\033[0m"
  exit 0
else
  echo -e "\033[0;31mServer is unhealthy. HTTP status code: $response\033[0m"
  exit 1
fi
