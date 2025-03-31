#!/bin/bash

# Exit on error
set -e

# Default image names
WORKER_IMAGE="hn-rank-worker"
API_IMAGE="hn-rank-api"

# Check if we need to build the images first
if [ "$1" == "build" ]; then
    ./scripts/build.sh
fi

# Create data directory if it doesn't exist
mkdir -p ./data

echo "Running Docker containers..."

# Run API server
echo "Starting API server..."
docker run -d --name hn-api -p 8080:8080 -v $(pwd)/data:/app/data ${API_IMAGE}:latest
echo "API server running at http://localhost:8080"

# Run Worker
echo "Starting Worker..."
docker run -d --name hn-worker -v $(pwd)/data:/app/data ${WORKER_IMAGE}:latest
echo "Worker started in background"

echo "----------------------------------------"
echo "To view logs:"
echo "  API logs: docker logs -f hn-api"
echo "  Worker logs: docker logs -f hn-worker"
echo ""
echo "To stop containers:"
echo "  docker stop hn-api hn-worker"
echo "  docker rm hn-api hn-worker" 