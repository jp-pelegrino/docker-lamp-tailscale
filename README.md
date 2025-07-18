# Docker Stack with Tailscale Serve/Funnel

This Docker stack provides a complete web development environment with:
- **WordPress 6.8.1** (latest version)
- **MySQL 8.0** database
- **phpMyAdmin** for database management
- **Nginx** reverse proxy
- **Tailscale Serve/Funnel** for secure networking and public access
- **Custom PHP application** (your existing www folder)

## ✅ Current Status

**WORKING CONFIGURATION** - All issues resolved as of July 18, 2025:
- ✅ Container stability achieved (no more restart loops)
- ✅ Tailscale funnel enabled for public internet access
- ✅ WordPress accessible via Tailscale serve/funnel
- ✅ phpMyAdmin accessible at `/phpmyadmin/` path
- ✅ Nginx reverse proxy properly configured
- ✅ Public internet access confirmed working

## 🚀 Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- Tailscale account (free at https://tailscale.com)

### 2. Get Tailscale Auth Key

1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Generate auth key"
3. **Important:** Check "Ephemeral" (recommended for testing)
4. Copy the generated key

### 3. Configure Environment

Edit the `.env` file with your settings:

```bash
TS_AUTHKEY="tskey-auth-xxxxxxxxxxxxxxxxxxxxx"
TS_HOSTNAME="your-hostname"
TS_PRIVACY="public"  # Use "public" for internet access, "private" for tailnet-only
```

### 4. Start the Stack

```bash
# Option 1: Use the helper script
./start.sh

# Option 2: Manual start
docker-compose up -d
```

## 🌐 Access Your Applications

### Private Access (TS_PRIVACY=private)
- **WordPress**: `https://your-hostname.<your-tailnet>.ts.net`
- **Custom PHP App**: `https://your-hostname.<your-tailnet>.ts.net` (you'll need to configure routing)
- **phpMyAdmin**: `https://your-hostname.<your-tailnet>.ts.net/phpmyadmin`

### Public Internet Access (TS_PRIVACY=public)
- **WordPress**: `https://your-hostname.your-tailnet.ts.net/` - Accessible from anywhere on the internet
- **phpMyAdmin**: `https://your-hostname.your-tailnet.ts.net/phpmyadmin/` - Database management via web
Change `TS_PRIVACY=public` in `.env` file, then restart:
```bash
docker-compose down
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables (`.env`)

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker project name | `your_project_tailscale` |
| `TS_AUTHKEY` | Tailscale authentication key | `<get-this-from-tailscale>` |
| `TS_HOSTNAME` | Tailscale hostname | `your-hostname` |
| `TS_PRIVACY` | Access level: `private` or `public` | `private` |
| `MYSQL_DATABASE` | Database name | `dbname` |
| `MYSQL_USER` | Database user | `dbuser` |
| `MYSQL_PASSWORD` | Database password | `your_secure_password_here` |

### Services

| Service | Description | Port |
|---------|-------------|------|
| `db` | MySQL 8.0 database | 3306 |
| `www` | Custom PHP application | 80 |
| `wordpress` | WordPress 6.8.1 | Internal |
| `phpmyadmin` | Database management | 8080 |
| `nginx` | Reverse proxy | 8000 |
| `tailscale` | Tailscale networking | N/A |

## 📁 File Structure

```
.
├── docker-compose.yml          # Main orchestration file
├── Dockerfile                  # Custom PHP container
├── .env                        # Environment configuration
├── nginx.conf                  # Nginx configuration
├── start.sh                    # Helper startup script
├── config/
│   └── tailscale/
│       ├── tailscale-private.json   # Private network config
│       └── tailscale-public.json    # Public network config
├── www/                        # Your custom PHP application
│   ├── index.php
│   ├── info.php
│   └── assets/
└── dump/                       # Database initialization
    └── myDb.sql
```

## 🛠️ Management Commands

### View logs
```bash
docker-compose logs -f
```

### Check service status
```bash
docker-compose ps
```

### Check Tailscale status
```bash
docker-compose exec tailscale tailscale status
```

### Check serve configuration
```bash
docker-compose exec tailscale tailscale serve status
```

### Stop services
```bash
docker-compose down
```

### Restart services
```bash
docker-compose restart
```

### Clean restart (removes volumes)
```bash
docker-compose down --volumes
docker-compose up -d
```

## 🔐 Security Features

- **Automatic HTTPS** via Tailscale's built-in Let's Encrypt integration
- **Private networking** by default (only accessible via Tailscale)
- **Security headers** configured in Nginx
- **Non-root user** in PHP container
- **Network isolation** between frontend and backend

## 🌍 Switching Between Private and Public

### Private Mode (default)
- Only accessible to devices on your Tailscale network
- Perfect for development and team collaboration
- Set `TS_PRIVACY=private`

### Public Mode (Funnel)
- Accessible from anywhere on the internet
- Great for client demos and production
- Set `TS_PRIVACY=public`

## 🎯 WordPress Setup

1. Access WordPress at your Tailscale URL
2. Follow the WordPress installation wizard
3. Database details:
   - **Database Name**: `dohwvchdwp`
   - **Username**: `wvchdroot`
   - **Password**: `dohwvchd2025admin`
   - **Database Host**: `db`

## 📊 phpMyAdmin Access

Access phpMyAdmin for database management:
- **URL**: `https://your-hostname.your-tailnet.ts.net/phpmyadmin/`
- **Username**: `root`
- **Password**: Use the value from `MYSQL_ROOT_PASSWORD` in your `.env` file

## 🔧 Troubleshooting

### Container Restart Loop Issues (RESOLVED)
If you encounter "flag provided but not defined: -config-file" errors:
- ✅ **Fixed**: Removed invalid `--config-file` flag from Tailscale startup
- ✅ **Fixed**: Added `--reset` flag to clear persistent state
- ✅ **Fixed**: Removed problematic `--advertise-tags=tag:container`

### Nginx Proxy Issues (RESOLVED)
If WordPress shows phpMyAdmin content instead:
- ✅ **Fixed**: Removed conflicting default nginx configuration
- ✅ **Fixed**: Proper path routing for `/phpmyadmin/` requests
- ✅ **Fixed**: Cookie path rewriting for phpMyAdmin

### Tailscale Funnel "tailnet only" Status (RESOLVED)
If funnel shows "tailnet only" instead of "Funnel on":
- ✅ **Fixed**: Separated serve and funnel configuration logic
- ✅ **Fixed**: Direct funnel configuration when `TS_PRIVACY=public`
- ✅ **Fixed**: Proper retry logic with fallback mechanisms

### General Troubleshooting

#### Services won't start
```bash
# Check logs
docker-compose logs

# Check if ports are in use
sudo netstat -tulpn | grep :80
```

#### Tailscale connection issues
```bash
# Check Tailscale container logs
docker-compose logs tailscale

# Verify auth key is set correctly
grep TS_AUTHKEY .env
```

#### Can't access via Tailscale URL
1. Ensure you're connected to the same Tailscale network
2. Check if the hostname is registered: `tailscale status`
3. Verify serve/funnel configuration: `docker-compose exec tailscale tailscale serve status`

## 📝 Configuration Notes

### Environment Variables
- **TS_PRIVACY**: Set to `"public"` for internet access via Tailscale funnel, or `"private"` for tailnet-only access
- **TS_HOSTNAME**: Choose a unique hostname for your Tailscale node
- **TS_AUTHKEY**: Get from https://login.tailscale.com/admin/settings/keys

### Technical Details
- The setup uses **userspace networking** for Tailscale, which works in most Docker environments
- **Ephemeral auth keys** are recommended for testing - they auto-cleanup when containers stop
- **WordPress data** is persisted in Docker volumes
- **Database data** is persisted in Docker volumes
- **Nginx** acts as reverse proxy routing traffic to appropriate backend services
- **socat** proxy handles Tailscale's localhost limitation in Docker containers

### Security Considerations
- Change all default passwords in production
- Use strong, unique passwords for database access
- Consider using Tailscale ACLs to restrict access
- Regularly update Docker images for security patches
- The **nginx proxy** handles SSL termination and routing

## 🎉 What's Next?

1. **Customize your hostname** by changing `TS_HOSTNAME` in `.env`
2. **Add more services** to the Docker stack
3. **Set up automated backups** for your WordPress data
4. **Configure custom domains** if needed
5. **Set up monitoring** with tools like Portainer

---

Enjoy your new Tailscale-powered development environment! 🚀
