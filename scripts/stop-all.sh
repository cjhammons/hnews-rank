#!/bin/bash

echo "Stopping all services..."
echo "----------------------------------------"

# Stop the proxy first
echo "Stopping reverse proxy..."
./scripts/stop-proxy.sh

# Stop local services
echo "Stopping local services..."
./scripts/stop-local.sh

# Stop embedding service last
echo "Stopping embedding service..."
./scripts/stop-embedding.sh

echo "----------------------------------------"
echo "All services have been stopped." 