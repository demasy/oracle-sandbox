#!/bin/bash
set -e

# Check for package.json
if [[ ! -f package.json ]]; then
  echo "Error: package.json not found in the current directory."
  exit 1
fi

echo "This script will remove node_modules and package-lock.json, update all dependencies, and reinstall them."
read -p "Are you sure you want to continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Remove old dependencies
echo "Removing node_modules and package-lock.json..."
rm -rf node_modules package-lock.json

# Check for npm and npx
if ! command -v npm &> /dev/null; then
  echo "npm is not installed. Please install Node.js and npm."
  exit 1
fi
if ! command -v npx &> /dev/null; then
  echo "npx is not installed. Please install Node.js and npm."
  exit 1
fi

# Ensure npm-check-updates is available
if ! npx --no-install npm-check-updates --version &> /dev/null; then
  echo "npm-check-updates is not installed. Installing it globally..."
  npm install -g npm-check-updates
fi

# Update dependencies
echo "Updating package.json dependencies to latest versions..."
npx npm-check-updates -u

# Reinstall dependencies
echo "Installing updated dependencies..."
if ! npm install; then
  echo "npm install failed. Please check your npm logs."
  exit 1
fi

echo "Node.js environment refreshed successfully."