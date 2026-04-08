#!/bin/bash

################################################################################
# Download File Utility
# Description: Downloads a file from a URL to a specified directory
# Usage: download-file.sh <URL> <destination_directory>
# Author: Demasy Labs
################################################################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/colors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/logging.sh" 2>/dev/null || true

# Function to display usage
usage() {
    echo "Usage: $0 <URL> <destination_directory>"
    echo ""
    echo "Parameters:"
    echo "  URL                    - The URL of the file to download"
    echo "  destination_directory  - The directory where the file will be saved"
    echo ""
    echo "Example:"
    echo "  $0 https://example.com/file.zip /tmp/downloads"
    exit 1
}

# Validate parameters
if [ $# -ne 2 ]; then
    log_error "Invalid number of parameters"
    usage
fi

URL="$1"
DEST_DIR="$2"

# Validate URL format
if [[ ! "$URL" =~ ^https?:// ]]; then
    log_error "Invalid URL format. Must start with http:// or https://"
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    log_info "Creating destination directory: ${DEST_DIR}"
    mkdir -p "$DEST_DIR" || {
        log_error "Failed to create destination directory"
        exit 1
    }
fi

# Extract filename from URL
FILENAME=$(basename "$URL" | cut -d'?' -f1)

# Full destination path
DEST_PATH="${DEST_DIR}/${FILENAME}"

log_info "Downloading file from: ${URL}"
log_info "Destination: ${DEST_PATH}"

# Download with curl (preferred) or fallback to wget
if command -v curl &> /dev/null; then
    log_step "Using curl for download..."
    curl -L --progress-bar -o "$DEST_PATH" "$URL"
    DOWNLOAD_STATUS=$?
elif command -v wget &> /dev/null; then
    log_step "Using wget for download..."
    wget -O "$DEST_PATH" "$URL"
    DOWNLOAD_STATUS=$?
else
    log_error "Neither curl nor wget is available. Cannot download file."
    exit 1
fi

# Check download status
if [ $DOWNLOAD_STATUS -eq 0 ]; then
    FILE_SIZE=$(du -h "$DEST_PATH" | cut -f1)
    log_success "File downloaded successfully: ${FILENAME} (${FILE_SIZE})"
    log_info "Location: ${DEST_PATH}"
    exit 0
else
    log_error "Download failed with status code: ${DOWNLOAD_STATUS}"
    # Clean up failed download
    [ -f "$DEST_PATH" ] && rm -f "$DEST_PATH"
    exit 1
fi