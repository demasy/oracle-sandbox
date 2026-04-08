#!/bin/bash
# ============================================
# Architecture Detection Utility
# ============================================
# Detects system architecture and sets appropriate variables
# Usage: source /usr/demasy/scripts/utils/detect-arch.sh
# ============================================

# Detect system architecture
ARCH=$(uname -m)

# Normalize architecture names
case "$ARCH" in
    x86_64|amd64)
        DETECTED_ARCH="x86_64"
        ARCH_TYPE="amd64"
        ;;
    aarch64|arm64)
        DETECTED_ARCH="aarch64"
        ARCH_TYPE="arm64"
        ;;
    *)
        DETECTED_ARCH="$ARCH"
        ARCH_TYPE="unknown"
        ;;
esac

# Export variables for use in other scripts
export DETECTED_ARCH
export ARCH_TYPE

# Function to check if architecture is supported
is_arch_supported() {
    if [ "$ARCH_TYPE" = "amd64" ] || [ "$ARCH_TYPE" = "arm64" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if running on ARM64
is_arm64() {
    [ "$ARCH_TYPE" = "arm64" ]
}

# Function to check if running on AMD64
is_amd64() {
    [ "$ARCH_TYPE" = "amd64" ]
}

# Function to get Oracle client architecture string
get_oracle_arch() {
    if [ "$ARCH_TYPE" = "arm64" ]; then
        echo "arm64"
    else
        echo "x64"
    fi
}

# Export functions
export -f is_arch_supported
export -f is_arm64
export -f is_amd64
export -f get_oracle_arch