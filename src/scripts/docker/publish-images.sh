#!/bin/bash
# publish-images.sh - Build and publish Docker images to registries
# Author: Demasy <founder@demasy.io>
# Purpose: Automate image building and publishing to GHCR and Docker Hub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="${1:-v1.0.1}"
IMAGE_NAME="oracle-sandbox"
LOCAL_IMAGE="demasylabs-oracle-sandbox:latest"
GITHUB_USER="demasy"
DOCKER_USER="demasy"

# Functions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Docker Image Publishing Tool${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $VERSION"
    echo "Usage: ./publish-images.sh v1.0.0"
    exit 1
fi

print_info "Version: ${VERSION}"
print_info "Image: ${IMAGE_NAME}\n"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi
print_success "Docker is running"

# Check authentication
print_info "Checking registry authentication..."

# Check GitHub Container Registry
if docker login ghcr.io --username=${GITHUB_USER} --password-stdin < /dev/null 2>&1 | grep -q "Login Succeeded"; then
    print_success "Already authenticated to GitHub Container Registry"
else
    print_warning "Not authenticated to GitHub Container Registry"
    echo -n "Login to GHCR? (y/n): "
    read -r login_ghcr
    if [[ $login_ghcr == "y" ]]; then
        print_info "Login with: echo \$GITHUB_TOKEN | docker login ghcr.io -u ${GITHUB_USER} --password-stdin"
        echo -n "Enter GitHub token: "
        read -s github_token
        echo
        echo "$github_token" | docker login ghcr.io -u ${GITHUB_USER} --password-stdin
        print_success "Authenticated to GitHub Container Registry"
    fi
fi

# Check Docker Hub
if docker login --username=${DOCKER_USER} --password-stdin < /dev/null 2>&1 | grep -q "Login Succeeded"; then
    print_success "Already authenticated to Docker Hub"
else
    print_warning "Not authenticated to Docker Hub"
    echo -n "Login to Docker Hub? (y/n): "
    read -r login_docker
    if [[ $login_docker == "y" ]]; then
        print_info "Login to Docker Hub..."
        docker login
        print_success "Authenticated to Docker Hub"
    fi
fi

echo ""

# Build image
print_info "Building Docker image..."
if docker-compose build demasylabs-oracle-server; then
    print_success "Image built successfully"
else
    print_error "Failed to build image"
    exit 1
fi

# Check if local image exists
if ! docker image inspect ${LOCAL_IMAGE} > /dev/null 2>&1; then
    print_error "Local image not found: ${LOCAL_IMAGE}"
    exit 1
fi
print_success "Local image verified: ${LOCAL_IMAGE}"

echo ""
print_info "Tagging images..."

# Tag for GitHub Container Registry
docker tag ${LOCAL_IMAGE} ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:${VERSION}
docker tag ${LOCAL_IMAGE} ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:latest
print_success "Tagged for GitHub Container Registry"

# Tag for Docker Hub
docker tag ${LOCAL_IMAGE} ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}
docker tag ${LOCAL_IMAGE} ${DOCKER_USER}/${IMAGE_NAME}:latest
print_success "Tagged for Docker Hub"

echo ""
print_info "Tagged images:"
docker images | grep -E "(ghcr.io/${GITHUB_USER}/${IMAGE_NAME}|${DOCKER_USER}/${IMAGE_NAME})" | head -4

echo ""
echo -n "Push images to registries? (y/n): "
read -r confirm
if [[ $confirm != "y" ]]; then
    print_warning "Push cancelled"
    exit 0
fi

# Push to GitHub Container Registry
echo ""
print_info "Pushing to GitHub Container Registry..."
if docker push ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:${VERSION}; then
    print_success "Pushed: ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:${VERSION}"
else
    print_error "Failed to push to GHCR"
fi

if docker push ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:latest; then
    print_success "Pushed: ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:latest"
else
    print_error "Failed to push latest tag to GHCR"
fi

# Push to Docker Hub
echo ""
print_info "Pushing to Docker Hub..."
if docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}; then
    print_success "Pushed: ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}"
else
    print_error "Failed to push to Docker Hub"
fi

if docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}:latest; then
    print_success "Pushed: ${DOCKER_USER}/${IMAGE_NAME}:latest"
else
    print_error "Failed to push latest tag to Docker Hub"
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Images published successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo "📦 Published Images:"
echo ""
echo "GitHub Container Registry:"
echo "  docker pull ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:${VERSION}"
echo "  docker pull ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:latest"
echo ""
echo "Docker Hub:"
echo "  docker pull ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}"
echo "  docker pull ${DOCKER_USER}/${IMAGE_NAME}:latest"
echo ""
echo "🔗 Registry URLs:"
echo "  GHCR: https://github.com/${GITHUB_USER}/${IMAGE_NAME}/pkgs/container/${IMAGE_NAME}"
echo "  Docker Hub: https://hub.docker.com/r/${DOCKER_USER}/${IMAGE_NAME}"
echo ""

exit 0
