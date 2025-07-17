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

# Configure Tailscale serve based on privacy setting
if [ "$TS_PRIVACY" = "public" ]; then
    echo "Setting up public (funnel) access..."
    # Enable funnel for public access
    tailscale serve --https=443 --set-path=/ http://nginx:8000
    tailscale funnel --https=443 on
else
    echo "Setting up private (serve) access..."
    # Just serve without funnel for private access
    tailscale serve --https=443 --set-path=/ http://nginx:8000
fi

echo "Tailscale serve configuration complete!"
tailscale serve status

echo "Keeping container running..."
# Keep the container running
tail -f /dev/null
