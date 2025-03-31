#!/bin/bash

# Exit on error
set -e

# Default image names
WORKER_IMAGE="hn-rank-worker"
API_IMAGE="hn-rank-api"
VERSION=$(git rev-parse --short HEAD)

echo "Building Docker images..."
echo "API Image: ${API_IMAGE}"
echo "Worker Image: ${WORKER_IMAGE}"
echo "Version: ${VERSION}"
echo "----------------------------------------"

# Build API
echo "Building API Docker image..."
docker build -t ${API_IMAGE}:${VERSION} -f Dockerfile .
docker tag ${API_IMAGE}:${VERSION} ${API_IMAGE}:latest
echo "API image built successfully"
echo "----------------------------------------"

# Build worker
echo "Building Worker Docker image..."
docker build -t ${WORKER_IMAGE}:${VERSION} -f Dockerfile.worker .
docker tag ${WORKER_IMAGE}:${VERSION} ${WORKER_IMAGE}:latest
echo "Worker image built successfully"
echo "----------------------------------------"

echo "All images built successfully. You can now run them with Docker:"
echo "# Run API server:"
echo "docker run -p 8080:8080 -v \$(pwd)/data:/app/data ${API_IMAGE}:latest"
echo ""
echo "# Run Worker:"
echo "docker run -v \$(pwd)/data:/app/data ${WORKER_IMAGE}:latest" 