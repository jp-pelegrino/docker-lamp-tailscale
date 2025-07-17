#!/bin/bash

set -e

echo "Starting Tailscale daemon..."

# Start tailscaled in the background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# Wait for tailscaled to be ready
sleep 5

echo "Connecting to Tailscale..."

# Connect to Tailscale
until tailscale up --authkey="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME}" --advertise-tags=tag:container; do
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

# Check if packages are already installed
if command -v socat >/dev/null 2>&1 && command -v nc >/dev/null 2>&1; then
    echo "Packages already installed, skipping installation"
else
    if ! apk add --no-cache socat netcat-openbsd; then
        echo "ERROR: Failed to install socat and netcat. Retrying..."
        sleep 5
        if ! apk add --no-cache socat netcat-openbsd; then
            echo "ERROR: Failed to install packages after retry. Exiting."
            exit 1
        fi
    fi
    echo "Packages installed successfully"
fi

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
    
    # Clear any existing funnel configuration first
    echo "Clearing existing funnel configuration..."
    tailscale funnel --https=443 off 2>/dev/null || true
    
    # Enable serve for HTTPS on port 443, serving localhost:8000
    echo "Configuring Tailscale serve for HTTPS on port 443..."
    if ! tailscale serve --https=443 --bg localhost:8000; then
        echo "ERROR: Failed to configure Tailscale serve"
        echo "Attempting to continue anyway..."
    else
        echo "Tailscale serve configured successfully"
        echo "Enabling funnel for public access..."
        
        # Wait a moment for serve to stabilize
        sleep 2
        
        if ! tailscale funnel --https=443 on; then
            echo "ERROR: Failed to enable Tailscale funnel"
            echo "Attempting to continue anyway..."
            echo "Site will be accessible only within your tailnet"
        else
            echo "Tailscale funnel enabled successfully"
            echo "Site should be accessible publicly at: https://wvdoh.dorper-beta.ts.net/"
        fi
    fi
else
    echo "Setting up private (serve) access..."
    # Just serve without funnel for private access
    echo "Configuring Tailscale serve for HTTPS on port 443..."
    if ! tailscale serve --https=443 --bg localhost:8000; then
        echo "ERROR: Failed to configure Tailscale serve"
        echo "Attempting to continue anyway..."
    else
        echo "Tailscale serve configured successfully"
    fi
fi

echo "Tailscale serve configuration complete!"
echo "Checking serve status..."
if ! tailscale serve status; then
    echo "WARNING: Unable to get serve status, but continuing..."
fi

echo "Checking funnel status..."
if ! tailscale funnel status; then
    echo "WARNING: Unable to get funnel status, but continuing..."
fi

echo "Keeping container running..."
# Keep the container running
tail -f /dev/null
