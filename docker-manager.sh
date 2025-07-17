#!/bin/bash

# Docker management script for Tailscale LAMP stack

case "$1" in
    start)
        echo "Starting Docker services..."
        sudo docker compose up -d
        ;;
    stop)
        echo "Stopping Docker services..."
        sudo docker compose down
        ;;
    restart)
        echo "Restarting Docker services..."
        sudo docker compose down
        sudo docker compose up -d
        ;;
    status)
        echo "Docker services status:"
        sudo docker compose ps
        ;;
    logs)
        if [ -z "$2" ]; then
            sudo docker compose logs -f
        else
            sudo docker compose logs -f "$2"
        fi
        ;;
    tailscale-logs)
        echo "Tailscale logs:"
        sudo docker compose logs -f tailscale
        ;;
    tailscale-status)
        echo "Tailscale status:"
        sudo docker compose exec tailscale tailscale status
        ;;
    tailscale-serve)
        echo "Tailscale serve status:"
        sudo docker compose exec tailscale tailscale serve status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs [service]|tailscale-logs|tailscale-status|tailscale-serve}"
        echo ""
        echo "Commands:"
        echo "  start           - Start all services"
        echo "  stop            - Stop all services"
        echo "  restart         - Restart all services"
        echo "  status          - Show service status"
        echo "  logs [service]  - Show logs (optionally for specific service)"
        echo "  tailscale-logs  - Show Tailscale logs"
        echo "  tailscale-status - Show Tailscale status"
        echo "  tailscale-serve - Show Tailscale serve configuration"
        exit 1
        ;;
esac
