#!/bin/bash

# WordPress initialization script
# This ensures .htaccess is created with proper rewrite rules

HTACCESS_FILE="/var/www/html/.htaccess"

# Wait for WordPress to be ready
until [ -f /var/www/html/index.php ]; do
    echo "Waiting for WordPress files to be available..."
    sleep 2
done

# Create .htaccess if it doesn't exist or is empty
if [ ! -f "$HTACCESS_FILE" ] || [ ! -s "$HTACCESS_FILE" ]; then
    echo "Creating WordPress .htaccess file with rewrite rules..."
    cat > "$HTACCESS_FILE" << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
    
    # Set proper ownership
    chown www-data:www-data "$HTACCESS_FILE"
    chmod 644 "$HTACCESS_FILE"
    
    echo "WordPress .htaccess file created successfully!"
else
    echo "WordPress .htaccess file already exists."
fi

echo "WordPress initialization complete!"
