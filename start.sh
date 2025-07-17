#!/bin/bash

# Tailscale Docker Setup Script
# This script helps configure and start your Tailscale-enabled Docker environment

echo "🔧 Setting up Tailscale Docker environment..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found! Please create it first."
    exit 1
fi

# Check if Tailscale auth key is set
if grep -q "TS_AUTHKEY=\"<get-this-from-tailscale>\"" .env; then
    echo "⚠️  Please set your Tailscale auth key in .env file"
    echo "   1. Go to https://login.tailscale.com/admin/settings/keys"
    echo "   2. Generate an ephemeral auth key"
    echo "   3. Replace <get-this-from-tailscale> with your actual key"
    echo "   4. Make sure to set it as ephemeral for testing"
    exit 1
fi

# Load environment variables
source .env

echo "📋 Current configuration:"
echo "   Project: $COMPOSE_PROJECT_NAME"
echo "   Hostname: $TS_HOSTNAME"
echo "   Privacy: $TS_PRIVACY"

# Check if user wants to switch between private/public
echo ""
echo "🔐 Privacy Settings:"
echo "   - private: Only accessible via your Tailscale network"
echo "   - public: Accessible from the public internet (Funnel)"
echo ""
read -p "Current setting is '$TS_PRIVACY'. Change to private/public? (or press Enter to keep): " new_privacy

if [ ! -z "$new_privacy" ] && [ "$new_privacy" != "$TS_PRIVACY" ]; then
    if [ "$new_privacy" = "private" ] || [ "$new_privacy" = "public" ]; then
        # Update .env file
        sed -i "s/TS_PRIVACY=$TS_PRIVACY/TS_PRIVACY=$new_privacy/" .env
        echo "✅ Updated privacy setting to: $new_privacy"
    else
        echo "❌ Invalid privacy setting. Use 'private' or 'public'"
        exit 1
    fi
fi

# Start the services
echo ""
echo "🚀 Starting Docker services..."
docker-compose down --remove-orphans
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

# Show logs
echo ""
echo "📋 Recent logs:"
docker-compose logs --tail=20

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📱 Access your application:"
if [ "$TS_PRIVACY" = "private" ]; then
    echo "   Private URL: https://$TS_HOSTNAME.<your-tailnet>.ts.net"
    echo "   (Only accessible from devices on your Tailscale network)"
else
    echo "   Public URL: https://$TS_HOSTNAME.<your-tailnet>.ts.net"
    echo "   (Accessible from anywhere on the internet)"
fi
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose logs -f"
echo "   Stop services: docker-compose down"
echo "   Restart services: docker-compose restart"
echo "   Check Tailscale status: docker-compose exec tailscale tailscale status"
echo "   Check serve config: docker-compose exec tailscale tailscale serve status"
