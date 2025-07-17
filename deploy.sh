#!/bin/bash

# Docker LAMP Stack with Tailscale - Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_status "Creating .env from .env.example..."
    cp .env.example .env
    print_warning "Please edit .env file with your configuration before running this script again."
    exit 1
fi

# Check if Tailscale auth key is configured
if grep -q "your_tailscale_auth_key" .env; then
    print_error "Tailscale auth key not configured!"
    print_status "Please edit .env file and set your TS_AUTHKEY"
    print_status "Get your auth key from: https://login.tailscale.com/admin/settings/keys"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running!"
    print_status "Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "Docker Compose is not installed!"
    print_status "Please install Docker Compose and try again."
    exit 1
fi

print_status "Starting Docker LAMP Stack with Tailscale..."

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down

# Pull latest images
print_status "Pulling latest images..."
docker-compose pull

# Build and start containers
print_status "Building and starting containers..."
docker-compose up -d

# Wait for services to be healthy
print_status "Waiting for services to be healthy..."
sleep 30

# Check container status
print_status "Checking container status..."
docker-compose ps

# Get Tailscale status
print_status "Getting Tailscale status..."
TAILSCALE_CONTAINER=$(docker-compose ps -q tailscale)
if [ ! -z "$TAILSCALE_CONTAINER" ]; then
    sleep 10
    docker exec $TAILSCALE_CONTAINER tailscale status || true
    docker exec $TAILSCALE_CONTAINER tailscale serve status || true
fi

# Get configuration from .env
HOSTNAME=$(grep TS_HOSTNAME .env | cut -d'=' -f2)
DOMAIN=$(grep TS_DOMAIN .env | cut -d'=' -f2)
SERVE_MODE=$(grep TS_SERVE_MODE .env | cut -d'=' -f2)

# Display access information
print_success "Stack deployed successfully!"
echo ""
print_status "Access your applications:"
echo "  WordPress: https://${HOSTNAME}.${DOMAIN}/"
echo "  phpMyAdmin: https://${HOSTNAME}.${DOMAIN}/phpmyadmin/"
echo ""
if [ "$SERVE_MODE" = "funnel" ]; then
    print_status "Mode: Public access (Funnel) - Anyone can access your site"
else
    print_status "Mode: Private access (Serve) - Only your Tailscale network can access"
fi
echo ""
print_status "To view logs: docker-compose logs -f"
print_status "To stop: docker-compose down"
print_status "To enable public access: Set TS_SERVE_MODE=funnel in .env and restart"
