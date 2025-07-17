#!/bin/bash

set -e

echo "Starting Tailscale daemon..."

# Start tailscaled in the background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# Wait for tailscaled to be ready
sleep 5

echo "Connecting to Tailscale..."

# Connect to Tailscale
until tailscale up --authkey="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME}"; do
    echo "Retrying Tailscale connection..."
    sleep 5
done

echo "Tailscale connected successfully!"

# Wait a bit for the connection to stabilize
sleep 5

echo "Setting up Tailscale serve..."

# Since Tailscale serve only supports localhost/127.0.0.1, we need to use a different approach
# We'll set up a simple proxy using socat to forward traffic from localhost to nginx
echo "Installing socat and netcat for proxying..."
apk add --no-cache socat netcat-openbsd

# Start socat in the background to proxy localhost:8000 to nginx:8000
echo "Starting proxy from localhost:8000 to nginx:8000..."
socat TCP-LISTEN:8000,fork,reuseaddr TCP:nginx:8000 &
SOCAT_PID=$!

# Wait for socat to be ready
sleep 2

# Verify socat is running
if kill -0 $SOCAT_PID 2>/dev/null; then
    echo "Socat proxy is running (PID: $SOCAT_PID)"
else
    echo "ERROR: Socat proxy failed to start"
    exit 1
fi

# Test the proxy connection
echo "Testing proxy connection..."
if timeout 5 nc -z localhost 8000; then
    echo "Proxy connection test successful"
else
    echo "WARNING: Proxy connection test failed"
fi

# Configure Tailscale serve based on privacy setting
echo "Clearing any existing serve configuration..."
tailscale serve reset

if [ "$TS_PRIVACY" = "public" ]; then
    echo "Setting up public (funnel) access..."
    # Enable funnel for public access
    echo "Configuring Tailscale serve for HTTPS on port 443..."
    tailscale serve https:443 http://localhost:8000
    if [ $? -eq 0 ]; then
        echo "Tailscale serve configured successfully"
        echo "Enabling funnel for public access..."
        tailscale funnel https:443 on
        if [ $? -eq 0 ]; then
            echo "Tailscale funnel enabled successfully"
        else
            echo "ERROR: Failed to enable Tailscale funnel"
        fi
    else
        echo "ERROR: Failed to configure Tailscale serve"
        echo "Attempting alternative serve configuration..."
        tailscale serve 443 http://localhost:8000
        if [ $? -eq 0 ]; then
            echo "Alternative serve configuration successful"
            tailscale funnel 443 on
        else
            echo "Alternative serve configuration also failed"
        fi
    fi
else
    echo "Setting up private (serve) access..."
    # Just serve without funnel for private access
    echo "Configuring Tailscale serve for HTTPS on port 443..."
    tailscale serve https:443 http://localhost:8000
    if [ $? -eq 0 ]; then
        echo "Tailscale serve configured successfully"
    else
        echo "ERROR: Failed to configure Tailscale serve"
        echo "Attempting alternative serve configuration..."
        tailscale serve 443 http://localhost:8000
        if [ $? -eq 0 ]; then
            echo "Alternative serve configuration successful"
        else
            echo "Alternative serve configuration also failed"
        fi
    fi
fi

echo "Tailscale serve configuration complete!"
tailscale serve status

echo "Keeping container running..."
# Keep the container running
tail -f /dev/null
