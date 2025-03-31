#!/bin/bash

# Exit on error
set -e

# Configuration
DOMAIN="hn.cjhammons.com"
API_PORT=8081
CADDY_PORT=90
CADDY_HTTPS_PORT=150

echo "Setting up reverse proxy for ${DOMAIN}..."
echo "----------------------------------------"

# Check if Caddy is installed
if ! command -v caddy &> /dev/null; then
    echo "Caddy is not installed. Installing Caddy..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install caddy
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Installing Caddy on Linux..."
        echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" | sudo tee /etc/apt/sources.list.d/caddy-fury.list
        sudo apt update
        sudo apt install caddy
    else
        echo "Unsupported OS. Please install Caddy manually: https://caddyserver.com/docs/install"
        exit 1
    fi
fi

# Create caddy configuration directory
mkdir -p ./caddy

# Create Caddyfile
echo "Creating Caddyfile..."
cat > ./caddy/Caddyfile << EOF
{
    # Global options
    http_port ${CADDY_PORT}
    https_port ${CADDY_HTTPS_PORT}
    # Use insecure dev settings for local development
    debug
}

${DOMAIN}:${CADDY_PORT} {
    # Serve over HTTP (no TLS) for local development
    reverse_proxy localhost:${API_PORT}
}

${DOMAIN}:${CADDY_HTTPS_PORT} {
    reverse_proxy localhost:${API_PORT}
    # Use self-signed certificate with explicit settings
    tls internal {
        protocols tls1.2 tls1.3
    }
}

# Redirect www subdomain to non-www
www.${DOMAIN}:${CADDY_PORT} {
    redir http://${DOMAIN}:${CADDY_PORT}{uri}
}

www.${DOMAIN}:${CADDY_HTTPS_PORT} {
    redir https://${DOMAIN}:${CADDY_HTTPS_PORT}{uri}
    tls internal
}
EOF

# Create run directory for logs if it doesn't exist
mkdir -p ./run

# Check if Caddy is already running
if pgrep caddy > /dev/null; then
    echo "Stopping existing Caddy instance..."
    pkill caddy || true
    sleep 2
fi

# Start Caddy
echo "Starting Caddy reverse proxy..."
nohup caddy run --config ./caddy/Caddyfile --adapter caddyfile > ./run/caddy.log 2>&1 &
CADDY_PID=$!
echo "Caddy started with PID: $CADDY_PID"

# Save PID for later use
echo "$CADDY_PID" > ./run/caddy.pid

echo "----------------------------------------"
echo "Reverse proxy setup complete!"
echo "Your application is accessible at:"
echo "HTTP:  http://${DOMAIN}:${CADDY_PORT} (no encryption)"
echo "HTTPS: https://${DOMAIN}:${CADDY_HTTPS_PORT} (self-signed certificate)"
echo ""
echo "⚠️ IMPORTANT: When accessing the HTTPS URL, you will see a browser warning"
echo "about an untrusted certificate. This is normal for local development."
echo "You can safely proceed by clicking 'Advanced' and then 'Proceed anyway'."
echo ""
echo "Note: For this to work fully, you need to:"
echo "1. Add '127.0.0.1 ${DOMAIN}' to your hosts file (/etc/hosts)"
echo "2. Open ports ${CADDY_PORT} and ${CADDY_HTTPS_PORT} in your firewall/router"
echo "----------------------------------------"
echo "To check HTTP status: curl -I http://${DOMAIN}:${CADDY_PORT}"
echo "To view logs: tail -f ./run/caddy.log"
echo "To stop proxy: ./scripts/stop-proxy.sh" 