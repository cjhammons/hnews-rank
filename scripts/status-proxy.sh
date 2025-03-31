#!/bin/bash

echo "Checking status of Caddy reverse proxy..."
echo "----------------------------------------"

DOMAIN="hn.cjhammons.com"
CADDY_PORT=90
CADDY_HTTPS_PORT=150

# Check if Caddy is running
if pgrep caddy > /dev/null; then
    CADDY_PID=$(pgrep caddy)
    echo "✅ Caddy is running (PID: $CADDY_PID)"
    
    # Check if the HTTP domain is responding
    if curl -s -I -L --connect-timeout 5 http://${DOMAIN}:${CADDY_PORT} 2>&1 | grep -q "HTTP/"; then
        echo "✅ HTTP Domain is accessible: http://${DOMAIN}:${CADDY_PORT}"
        
        # Get HTTP status code
        STATUS=$(curl -s -I -L --connect-timeout 5 http://${DOMAIN}:${CADDY_PORT} 2>/dev/null | grep "HTTP/" | tail -1 | awk '{print $2}')
        if [[ "$STATUS" =~ ^(200|301|302)$ ]]; then
            echo "   HTTP Status: $STATUS (Good)"
        else
            echo "⚠️ HTTP Status: $STATUS (Unexpected)"
        fi
    else
        echo "❌ HTTP Domain is NOT accessible: http://${DOMAIN}:${CADDY_PORT}"
    fi
    
    # Check if the HTTPS domain is responding (ignore cert errors)
    if curl -s -I -L --connect-timeout 5 --insecure https://${DOMAIN}:${CADDY_HTTPS_PORT} 2>&1 | grep -q "HTTP/"; then
        echo "✅ HTTPS Domain is accessible: https://${DOMAIN}:${CADDY_HTTPS_PORT} (self-signed certificate)"
        
        # Get HTTP status code
        STATUS=$(curl -s -I -L --connect-timeout 5 --insecure https://${DOMAIN}:${CADDY_HTTPS_PORT} 2>/dev/null | grep "HTTP/" | tail -1 | awk '{print $2}')
        if [[ "$STATUS" =~ ^(200|301|302)$ ]]; then
            echo "   HTTPS Status: $STATUS (Good)"
        else
            echo "⚠️ HTTPS Status: $STATUS (Unexpected)"
        fi
    else
        echo "❌ HTTPS Domain is NOT accessible: https://${DOMAIN}:${CADDY_HTTPS_PORT}"
    fi
    
    # Check ports
    echo "   Port ${CADDY_PORT} (HTTP): $(lsof -i:${CADDY_PORT} | grep -q . && echo "In use by Caddy" || echo "Not in use")"
    echo "   Port ${CADDY_HTTPS_PORT} (HTTPS): $(lsof -i:${CADDY_HTTPS_PORT} | grep -q . && echo "In use by Caddy" || echo "Not in use")"
    
    # Get Host file entry
    if grep -q "${DOMAIN}" /etc/hosts; then
        HOST_IP=$(grep "${DOMAIN}" /etc/hosts | awk '{print $1}')
        echo "✅ Host file entry: ${HOST_IP} ${DOMAIN}"
    else
        echo "❌ No host file entry for ${DOMAIN}. Add this to /etc/hosts:"
        echo "   127.0.0.1 ${DOMAIN} www.${DOMAIN}"
    fi
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me)
    echo "   External IP: ${EXTERNAL_IP}"
else
    echo "❌ Caddy is NOT running"
fi

echo "----------------------------------------"
echo "Log file: ./run/caddy.log"
echo "----------------------------------------"
echo "To start proxy: ./scripts/setup-proxy.sh"
echo "To stop proxy:  ./scripts/stop-proxy.sh" 