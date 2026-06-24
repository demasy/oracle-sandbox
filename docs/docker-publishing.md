# Docker Image Publishing Guide

This guide explains how to build and publish the Oracle Sandbox Docker images to GitHub Container Registry (GHCR) and Docker Hub.

## Prerequisites

### 1. GitHub Personal Access Token (PAT)
Create a token with `write:packages` permission:
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `write:packages`, `read:packages`, `delete:packages`
4. Generate and save the token

### 2. Docker Hub Access Token
1. Log in to Docker Hub
2. Go to Account Settings → Security → New Access Token
3. Create token with Read & Write permissions
4. Save the token

### 3. GitHub Repository Secrets
Add these secrets to your repository (Settings → Secrets and variables → Actions):
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token

## Publishing Methods

### Method 1: Automated via GitHub Actions (Recommended)

#### Trigger on Tag Push
```bash
# Commit your changes
git add .
git commit -m "Release v1.0.1"

# Create and push tag
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

The GitHub Action will automatically:
- Build multi-platform images (AMD64 + ARM64)
- Push to both GHCR and Docker Hub
- Tag as version and `latest`

#### Manual Trigger
Go to Actions → "Build and Publish Docker Images" → Run workflow

### Method 2: Manual Script

#### Using the publish script:
```bash
# Make script executable
chmod +x src/scripts/docker/publish-images.sh

# Run with version
./src/scripts/docker/publish-images.sh v1.0.1
```

The script will:
1. Check Docker is running
2. Prompt for registry authentication
3. Build the image
4. Tag for both registries
5. Push to GHCR and Docker Hub

#### Manual Docker commands:
```bash
# Login to registries
echo $GITHUB_TOKEN | docker login ghcr.io -u demasy --password-stdin
docker login  # For Docker Hub

# Build image
docker-compose build sandbox-oracle-server

# Tag images
docker tag demasylabs-oracle-sandbox:latest ghcr.io/demasy/oracle-sandbox:v1.0.1
docker tag demasylabs-oracle-sandbox:latest ghcr.io/demasy/oracle-sandbox:latest
docker tag demasylabs-oracle-sandbox:latest demasy/oracle-sandbox:v1.0.1
docker tag demasylabs-oracle-sandbox:latest demasy/oracle-sandbox:latest

# Push to registries
docker push ghcr.io/demasy/oracle-sandbox:v1.0.1
docker push ghcr.io/demasy/oracle-sandbox:latest
docker push demasy/oracle-sandbox:v1.0.1
docker push demasy/oracle-sandbox:latest
```

## Using Published Images

### From GitHub Container Registry (GHCR)
```bash
# Pull specific version
docker pull ghcr.io/demasy/oracle-sandbox:v1.0.1

# Pull latest
docker pull ghcr.io/demasy/oracle-sandbox:latest

# Run
docker run -d \
  --name oracle-sandbox \
  -p 3000:3000 \
  -p 8080:8080 \
  ghcr.io/demasy/oracle-sandbox:v1.0.1
```

### From Docker Hub
```bash
# Pull specific version
docker pull demasy/oracle-sandbox:v1.0.1

# Pull latest
docker pull demasy/oracle-sandbox:latest

# Run
docker run -d \
  --name oracle-sandbox \
  -p 3000:3000 \
  -p 8080:8080 \
  demasy/oracle-sandbox:v1.0.1
```

### Using Docker Compose with Pre-built Images
Update your `docker-compose.yml`:

```yaml
services:
  sandbox-oracle-server:
    image: ghcr.io/demasy/oracle-sandbox:v1.0.1
    # Or: image: demasy/oracle-sandbox:v1.0.1
    container_name: sandbox-oracle-server
    # ... rest of configuration
```

Then run:
```bash
docker-compose pull
docker-compose up -d
```

## Image Details

### Supported Platforms
- `linux/amd64` - Intel/AMD 64-bit
- `linux/arm64` - ARM 64-bit (Apple Silicon, ARM servers)

### Image Size
- Approximately 2-3 GB (compressed)
- Contains:
  - Oracle Instant Client 23.7
  - SQLcl 25.3
  - APEX 24.2 (~289MB)
  - ORDS 25.3
  - Node.js 20 runtime

### Image Tags
- `v1.0.1` - Specific version (immutable)
- `v1.0` - Minor version (updated with patches)
- `v1` - Major version (updated with minors)
- `latest` - Latest stable release

## Registry URLs

### GitHub Container Registry
- **Package URL**: https://github.com/demasy/oracle-sandbox/pkgs/container/oracle-sandbox
- **Pull Command**: `docker pull ghcr.io/demasy/oracle-sandbox:v1.0.1`
- **Public**: Yes (default for public repos)

### Docker Hub
- **Repository URL**: https://hub.docker.com/r/demasy/oracle-sandbox
- **Pull Command**: `docker pull demasy/oracle-sandbox:v1.0.1`
- **Public**: Yes

## Making Images Public

### GitHub Container Registry
1. Go to https://github.com/users/demasy/packages/container/oracle-sandbox/settings
2. Scroll to "Danger Zone"
3. Click "Change visibility" → Select "Public"

### Docker Hub
Images are public by default for free accounts.

## Troubleshooting

### Authentication Errors
```bash
# Verify Docker is logged in
docker login ghcr.io
docker login

# Check credentials
cat ~/.docker/config.json
```

### Build Failures
```bash
# Clean build with no cache
docker-compose build --no-cache

# Check Docker disk space
docker system df

# Prune if needed
docker system prune -a
```

### Push Failures
```bash
# Verify image exists
docker images | grep oracle-sandbox

# Check network connectivity
curl -I https://ghcr.io
curl -I https://hub.docker.com
```

## Best Practices

1. **Version Tags**: Always tag with semantic versioning
2. **Latest Tag**: Keep `latest` pointing to most recent stable
3. **Multi-platform**: Use GitHub Actions for multi-arch builds
4. **Cache**: Leverage BuildKit cache for faster builds
5. **Security**: Scan images before publishing
6. **Changelog**: Update README with each version

## Security Considerations

- Never commit tokens to repository
- Use GitHub Secrets for CI/CD
- Rotate access tokens regularly
- Enable vulnerability scanning
- Review Dependabot alerts

## Next Steps

1. Verify images are publicly accessible
2. Test pulling from both registries
3. Update documentation with pull commands
4. Create README badges for images
5. Set up automated vulnerability scanning
