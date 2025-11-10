#!/bin/bash

#------------------------------------------------------------------------------
# macOS Host Network Setup Script
# Purpose: Create host aliases for Docker containers
# Author: Ahmed El Demasy
#------------------------------------------------------------------------------

echo "Setting up host aliases for Docker containers..."

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Backup current hosts file
cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

# Remove existing entries
sed -i '' '/# Docker Oracle Database/d' /etc/hosts
sed -i '' '/192.168.1.10/d' /etc/hosts
sed -i '' '/192.168.1.20/d' /etc/hosts

# Add new entries
echo "" >> /etc/hosts
echo "# Docker Oracle Database - Added $(date)" >> /etc/hosts
echo "127.0.0.1    192.168.1.10    # Oracle Database Container" >> /etc/hosts
echo "127.0.0.1    192.168.1.20    # Oracle Server Container" >> /etc/hosts

echo "Host aliases added successfully!"
echo "You can now access:"
echo "  Database: 192.168.1.10:1521"
echo "  Server: http://192.168.1.20:3000"
echo "  Enterprise Manager: http://192.168.1.10:5500"

# Show current hosts file entries
echo ""
echo "Current hosts file entries:"
grep -A 5 "Docker Oracle Database" /etc/hosts
