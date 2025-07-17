#!/bin/bash

# Docker LAMP Stack with Tailscale - Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_help() {
    echo "Docker LAMP Stack with Tailscale - Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start              Start all services"
    echo "  stop               Stop all services"
    echo "  restart            Restart all services"
    echo "  status             Show container status"
    echo "  logs [service]     Show logs (optionally for specific service)"
    echo "  tailscale-status   Show Tailscale connection status"
    echo "  enable-funnel      Enable public access (Funnel mode)"
    echo "  disable-funnel     Disable public access (Serve mode)"
    echo "  backup-db          Backup MySQL database"
    echo "  restore-db [file]  Restore MySQL database from backup"
    echo "  update             Update all containers to latest versions"
    echo "  cleanup            Remove unused Docker resources"
    echo "  shell [service]    Open shell in container"
    echo "  help               Show this help message"
}

start_services() {
    print_status "Starting Docker LAMP Stack..."
    docker-compose up -d
    print_success "Services started successfully!"
}

stop_services() {
    print_status "Stopping Docker LAMP Stack..."
    docker-compose down
    print_success "Services stopped successfully!"
}

restart_services() {
    print_status "Restarting Docker LAMP Stack..."
    docker-compose restart
    print_success "Services restarted successfully!"
}

show_status() {
    print_status "Container Status:"
    docker-compose ps
    echo ""
    print_status "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

show_logs() {
    if [ -z "$1" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$1"
    fi
}

tailscale_status() {
    print_status "Tailscale Status:"
    TAILSCALE_CONTAINER=$(docker-compose ps -q tailscale)
    if [ ! -z "$TAILSCALE_CONTAINER" ]; then
        docker exec $TAILSCALE_CONTAINER tailscale status
        echo ""
        print_status "Serve/Funnel Status:"
        docker exec $TAILSCALE_CONTAINER tailscale serve status || true
        docker exec $TAILSCALE_CONTAINER tailscale funnel status || true
    else
        print_error "Tailscale container not found or not running"
    fi
}

enable_funnel() {
    print_status "Enabling Funnel mode (public access)..."
    TAILSCALE_CONTAINER=$(docker-compose ps -q tailscale)
    if [ ! -z "$TAILSCALE_CONTAINER" ]; then
        docker exec $TAILSCALE_CONTAINER tailscale funnel --https=443 --bg localhost:8000
        print_success "Funnel mode enabled - your site is now publicly accessible!"
    else
        print_error "Tailscale container not found or not running"
    fi
}

disable_funnel() {
    print_status "Disabling Funnel mode (switching to private access)..."
    TAILSCALE_CONTAINER=$(docker-compose ps -q tailscale)
    if [ ! -z "$TAILSCALE_CONTAINER" ]; then
        docker exec $TAILSCALE_CONTAINER tailscale funnel --https=443 --bg localhost:8000 --remove
        docker exec $TAILSCALE_CONTAINER tailscale serve --https=443 --bg localhost:8000
        print_success "Funnel mode disabled - your site is now private to your tailnet"
    else
        print_error "Tailscale container not found or not running"
    fi
}

backup_database() {
    print_status "Creating database backup..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DB_NAME=$(grep MYSQL_DATABASE .env | cut -d'=' -f2)
    DB_USER=$(grep MYSQL_USER .env | cut -d'=' -f2)
    DB_PASSWORD=$(grep MYSQL_PASSWORD .env | cut -d'=' -f2)
    
    docker-compose exec -T db mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > "backup_${DB_NAME}_${TIMESTAMP}.sql"
    print_success "Database backup created: backup_${DB_NAME}_${TIMESTAMP}.sql"
}

restore_database() {
    if [ -z "$1" ]; then
        print_error "Please provide backup file path"
        print_status "Usage: $0 restore-db /path/to/backup.sql"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        print_error "Backup file not found: $1"
        exit 1
    fi
    
    print_status "Restoring database from: $1"
    DB_NAME=$(grep MYSQL_DATABASE .env | cut -d'=' -f2)
    DB_USER=$(grep MYSQL_USER .env | cut -d'=' -f2)
    DB_PASSWORD=$(grep MYSQL_PASSWORD .env | cut -d'=' -f2)
    
    docker-compose exec -T db mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME < "$1"
    print_success "Database restored successfully!"
}

update_containers() {
    print_status "Updating containers to latest versions..."
    docker-compose pull
    docker-compose up -d
    print_success "Containers updated successfully!"
}

cleanup_docker() {
    print_status "Cleaning up unused Docker resources..."
    docker system prune -f
    docker volume prune -f
    print_success "Docker cleanup completed!"
}

open_shell() {
    if [ -z "$1" ]; then
        print_error "Please specify a service"
        print_status "Available services: db, wordpress, nginx, phpmyadmin, tailscale"
        exit 1
    fi
    
    print_status "Opening shell in $1 container..."
    docker-compose exec "$1" sh
}

check_php_config() {
    print_status "Checking PHP configuration..."
    if [ -f "./check-php.sh" ]; then
        ./check-php.sh
    else
        print_error "check-php.sh script not found!"
    fi
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    tailscale-status)
        tailscale_status
        ;;
    enable-funnel)
        enable_funnel
        ;;
    disable-funnel)
        disable_funnel
        ;;
    check-php)
        check_php_config
        ;;
    backup-db)
        backup_database
        ;;
    restore-db)
        restore_database "$2"
        ;;
    update)
        update_containers
        ;;
    cleanup)
        cleanup_docker
        ;;
    shell)
        open_shell "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
