#!/bin/bash

# PHP Configuration Verification Script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Get project name from .env
PROJECT_NAME=$(grep COMPOSE_PROJECT_NAME .env | cut -d'=' -f2)
WORDPRESS_CONTAINER="${PROJECT_NAME}-wordpress-1"

echo "PHP Configuration Verification"
echo "=============================="

# Check if WordPress container is running
if ! docker ps --filter "name=$WORDPRESS_CONTAINER" --format "{{.Names}}" | grep -q "$WORDPRESS_CONTAINER"; then
    print_error "WordPress container is not running!"
    print_status "Please start the stack first: docker-compose up -d"
    exit 1
fi

print_status "Checking PHP configuration in WordPress container..."

# Check PHP configuration
echo ""
echo "Current PHP Settings:"
echo "===================="

# Get PHP settings
upload_max_filesize=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('upload_max_filesize');")
post_max_size=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('post_max_size');")
max_execution_time=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('max_execution_time');")
memory_limit=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('memory_limit');")
max_input_vars=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('max_input_vars');")
max_file_uploads=$(docker exec "$WORDPRESS_CONTAINER" php -r "echo ini_get('max_file_uploads');")

echo "upload_max_filesize: $upload_max_filesize"
echo "post_max_size: $post_max_size"
echo "max_execution_time: $max_execution_time"
echo "memory_limit: $memory_limit"
echo "max_input_vars: $max_input_vars"
echo "max_file_uploads: $max_file_uploads"

# Check if our custom configurations are loaded
echo ""
echo "Configuration Files Check:"
echo "=========================="

# Check if our ini files are present
if docker exec "$WORDPRESS_CONTAINER" ls -la /usr/local/etc/php/conf.d/ | grep -q "uploads.ini"; then
    print_success "uploads.ini is mounted"
else
    print_error "uploads.ini is not mounted"
fi

if docker exec "$WORDPRESS_CONTAINER" ls -la /usr/local/etc/php/conf.d/ | grep -q "wordpress.ini"; then
    print_success "wordpress.ini is mounted"
else
    print_error "wordpress.ini is not mounted"
fi

# Check .htaccess
if docker exec "$WORDPRESS_CONTAINER" ls -la /var/www/html/ | grep -q ".htaccess"; then
    print_success ".htaccess is present"
else
    print_warning ".htaccess is not present (will be created by WordPress)"
fi

# Verify expected values
echo ""
echo "Configuration Verification:"
echo "=========================="

# Check upload_max_filesize
if [[ "$upload_max_filesize" == "1024M" || "$upload_max_filesize" == "1073741824" ]]; then
    print_success "upload_max_filesize is correctly set to 1024M"
else
    print_error "upload_max_filesize is $upload_max_filesize (expected: 1024M)"
fi

# Check post_max_size
if [[ "$post_max_size" == "1024M" || "$post_max_size" == "1073741824" ]]; then
    print_success "post_max_size is correctly set to 1024M"
else
    print_error "post_max_size is $post_max_size (expected: 1024M)"
fi

# Check memory_limit
if [[ "$memory_limit" == "512M" || "$memory_limit" == "536870912" ]]; then
    print_success "memory_limit is correctly set to 512M"
else
    print_error "memory_limit is $memory_limit (expected: 512M)"
fi

# Check max_execution_time
if [[ "$max_execution_time" == "300" ]]; then
    print_success "max_execution_time is correctly set to 300 seconds"
else
    print_error "max_execution_time is $max_execution_time (expected: 300)"
fi

# Create a PHP info file for debugging
echo ""
print_status "Creating phpinfo file for detailed inspection..."
docker exec "$WORDPRESS_CONTAINER" sh -c 'echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php'
print_success "phpinfo.php created - access it at https://your-domain/phpinfo.php"
print_warning "Remember to delete phpinfo.php after inspection for security!"

echo ""
print_status "If the settings are not correct, restart the WordPress container:"
echo "docker-compose restart wordpress"
