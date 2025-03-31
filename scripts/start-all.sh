#!/bin/bash

# Exit on error
set -e

# Configuration
DOMAIN="hn.cjhammons.com"
CADDY_PORT=90
CADDY_HTTPS_PORT=150

echo "Starting all services (API, Worker, Embedding, and Reverse Proxy)..."
echo "----------------------------------------"

# Check for host file entry and suggest adding if not present
if ! grep -q "${DOMAIN}" /etc/hosts; then
    echo "⚠️ Warning: No host file entry found for ${DOMAIN}"
    echo "For local access, please add this line to your /etc/hosts file:"
    echo "127.0.0.1 ${DOMAIN} www.${DOMAIN}"
    echo ""
    echo "You can do this with the following command:"
    echo "sudo bash -c 'echo \"127.0.0.1 ${DOMAIN} www.${DOMAIN}\" >> /etc/hosts'"
    echo ""
    read -p "Would you like to add this entry now? (y/n) " -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo bash -c "echo \"127.0.0.1 ${DOMAIN} www.${DOMAIN}\" >> /etc/hosts"
        echo "Host entry added."
    fi
    echo "----------------------------------------"
fi

# Start embedding service first
echo "Starting embedding service..."
./scripts/start-embedding.sh
sleep 2  # Give time for the embedding service to start

# Start local services
echo "Starting local services..."
./scripts/run-local.sh &
LOCAL_PID=$!

# Give some time for the local services to start
sleep 5

# Kill the local service script but keep its children running
kill $LOCAL_PID 2>/dev/null || true

# Start the proxy
echo "Starting reverse proxy..."
./scripts/setup-proxy.sh

# Show status
echo "----------------------------------------"
echo "Checking overall system status..."
echo "----------------------------------------"
./scripts/status-local.sh
echo "----------------------------------------"
./scripts/status-proxy.sh

echo "----------------------------------------"
echo "All services are now running!"
echo "Your application is accessible at:"
echo "- HTTP:  http://${DOMAIN}:${CADDY_PORT} (no encryption)"
echo "- HTTPS: https://${DOMAIN}:${CADDY_HTTPS_PORT} (self-signed certificate)"
echo ""
echo "⚠️ Note: When accessing via HTTPS, you'll see a certificate warning."
echo "This is expected in development. Click 'Advanced' and 'Proceed anyway'."
echo "----------------------------------------"
echo "To stop all services: ./scripts/stop-all.sh"
echo "To check status: ./scripts/status-all.sh" 