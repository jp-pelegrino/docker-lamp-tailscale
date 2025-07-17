#!/bin/bash

# Docker Health Check Script for LAMP Stack

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if container is running
check_container() {
    local container_name="$1"
    local service_name="$2"
    
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        echo -e "${GREEN}✓${NC} $service_name is running"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name is not running"
        return 1
    fi
}

# Check health status
check_health() {
    local container_name="$1"
    local service_name="$2"
    
    health_status=$(docker inspect --format="{{.State.Health.Status}}" "$container_name" 2>/dev/null)
    
    case "$health_status" in
        "healthy")
            echo -e "${GREEN}✓${NC} $service_name is healthy"
            return 0
            ;;
        "unhealthy")
            echo -e "${RED}✗${NC} $service_name is unhealthy"
            return 1
            ;;
        "starting")
            echo -e "${YELLOW}⚠${NC} $service_name is starting"
            return 1
            ;;
        *)
            echo -e "${YELLOW}?${NC} $service_name health status unknown"
            return 1
            ;;
    esac
}

# Check network connectivity
check_network() {
    local container_name="$1"
    local target="$2"
    local service_name="$3"
    
    if docker exec "$container_name" ping -c 1 "$target" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $service_name can reach $target"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name cannot reach $target"
        return 1
    fi
}

# Check HTTP endpoint
check_http() {
    local container_name="$1"
    local url="$2"
    local service_name="$3"
    
    if docker exec "$container_name" curl -f -s "$url" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $service_name HTTP endpoint is responding"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name HTTP endpoint is not responding"
        return 1
    fi
}

# Main health check
echo "Docker LAMP Stack Health Check"
echo "==============================="

# Get project name from .env
PROJECT_NAME=$(grep COMPOSE_PROJECT_NAME .env | cut -d'=' -f2)

# Define container names
DB_CONTAINER="${PROJECT_NAME}-db-1"
WORDPRESS_CONTAINER="${PROJECT_NAME}-wordpress-1"
NGINX_CONTAINER="${PROJECT_NAME}-nginx-1"
PMA_CONTAINER="${PROJECT_NAME}-phpmyadmin-1"
TAILSCALE_CONTAINER="${PROJECT_NAME}_tailscale"

total_checks=0
passed_checks=0

# Check container status
echo ""
echo "Container Status:"
for container in "$DB_CONTAINER:MySQL" "$WORDPRESS_CONTAINER:WordPress" "$NGINX_CONTAINER:Nginx" "$PMA_CONTAINER:phpMyAdmin" "$TAILSCALE_CONTAINER:Tailscale"; do
    container_name=$(echo "$container" | cut -d':' -f1)
    service_name=$(echo "$container" | cut -d':' -f2)
    
    total_checks=$((total_checks + 1))
    if check_container "$container_name" "$service_name"; then
        passed_checks=$((passed_checks + 1))
    fi
done

# Check health status
echo ""
echo "Health Status:"
for container in "$DB_CONTAINER:MySQL" "$WORDPRESS_CONTAINER:WordPress" "$NGINX_CONTAINER:Nginx" "$PMA_CONTAINER:phpMyAdmin"; do
    container_name=$(echo "$container" | cut -d':' -f1)
    service_name=$(echo "$container" | cut -d':' -f2)
    
    total_checks=$((total_checks + 1))
    if check_health "$container_name" "$service_name"; then
        passed_checks=$((passed_checks + 1))
    fi
done

# Check network connectivity
echo ""
echo "Network Connectivity:"
total_checks=$((total_checks + 1))
if check_network "$NGINX_CONTAINER" "wordpress" "Nginx"; then
    passed_checks=$((passed_checks + 1))
fi

total_checks=$((total_checks + 1))
if check_network "$NGINX_CONTAINER" "phpmyadmin" "Nginx"; then
    passed_checks=$((passed_checks + 1))
fi

total_checks=$((total_checks + 1))
if check_network "$WORDPRESS_CONTAINER" "db" "WordPress"; then
    passed_checks=$((passed_checks + 1))
fi

# Check HTTP endpoints
echo ""
echo "HTTP Endpoints:"
total_checks=$((total_checks + 1))
if check_http "$NGINX_CONTAINER" "http://localhost:8000/health" "Nginx"; then
    passed_checks=$((passed_checks + 1))
fi

total_checks=$((total_checks + 1))
if check_http "$NGINX_CONTAINER" "http://wordpress:80" "WordPress"; then
    passed_checks=$((passed_checks + 1))
fi

total_checks=$((total_checks + 1))
if check_http "$NGINX_CONTAINER" "http://phpmyadmin:80" "phpMyAdmin"; then
    passed_checks=$((passed_checks + 1))
fi

# Tailscale specific checks
echo ""
echo "Tailscale Status:"
if docker ps --filter "name=$TAILSCALE_CONTAINER" --format "{{.Names}}" | grep -q "$TAILSCALE_CONTAINER"; then
    total_checks=$((total_checks + 1))
    if docker exec "$TAILSCALE_CONTAINER" tailscale status &>/dev/null; then
        echo -e "${GREEN}✓${NC} Tailscale is connected"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}✗${NC} Tailscale is not connected"
    fi
fi

# Summary
echo ""
echo "Summary:"
echo "========"
echo "Passed: $passed_checks/$total_checks checks"

if [ "$passed_checks" -eq "$total_checks" ]; then
    echo -e "${GREEN}All systems operational!${NC}"
    exit 0
else
    echo -e "${RED}Some issues detected. Check the logs for more details.${NC}"
    exit 1
fi
