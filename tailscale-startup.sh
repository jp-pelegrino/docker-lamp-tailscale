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
echo "Installing socat for proxying..."
apk add --no-cache socat

# Start socat in the background to proxy localhost:8000 to nginx:8000
echo "Starting proxy from localhost:8000 to nginx:8000..."
socat TCP-LISTEN:8000,fork,reuseaddr TCP:nginx:8000 &

# Wait for socat to be ready
sleep 2

# Configure Tailscale serve based on privacy setting
if [ "$TS_PRIVACY" = "public" ]; then
    echo "Setting up public (funnel) access..."
    # Enable funnel for public access
    tailscale serve --https=443 --set-path=/ http://localhost:8000
    tailscale funnel --https=443 on
else
    echo "Setting up private (serve) access..."
    # Just serve without funnel for private access
    tailscale serve --https=443 --set-path=/ http://localhost:8000
fi

echo "Tailscale serve configuration complete!"
tailscale serve status

echo "Keeping container running..."
# Keep the container running
tail -f /dev/null
