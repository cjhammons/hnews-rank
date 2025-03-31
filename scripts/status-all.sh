#!/bin/bash

echo "Checking status of all services..."
echo "----------------------------------------"

# Check status of local services
echo "LOCAL SERVICES:"
./scripts/status-local.sh

echo "----------------------------------------"
echo "EMBEDDING SERVICE:"
./scripts/status-embedding.sh

echo "----------------------------------------"
echo "REVERSE PROXY:"
./scripts/status-proxy.sh

echo "----------------------------------------"
echo "To start all services: ./scripts/start-all.sh"
echo "To stop all services: ./scripts/stop-all.sh" 