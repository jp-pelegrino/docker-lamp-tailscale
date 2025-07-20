<?php
/**
 * WordPress Reverse Proxy Configuration
 * This file handles HTTPS detection and URL generation for WordPress
 * when running behind a reverse proxy (nginx) with Tailscale HTTPS
 */

// Force HTTPS detection when behind reverse proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}

// Force HTTPS detection from additional headers
if (isset($_SERVER['HTTP_X_FORWARDED_SSL']) && $_SERVER['HTTP_X_FORWARDED_SSL'] === 'on') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}

// Set the correct host for WordPress URL generation
if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}

// Force WordPress to use HTTPS URLs in all contexts
if (!defined('FORCE_SSL_ADMIN')) {
    define('FORCE_SSL_ADMIN', true);
}

// Define the home and site URLs with HTTPS
if (isset($_SERVER['HTTP_HOST'])) {
    $protocol = 'https://';
    $domain = $_SERVER['HTTP_HOST'];
    
    if (!defined('WP_HOME')) {
        define('WP_HOME', $protocol . $domain);
    }
    
    if (!defined('WP_SITEURL')) {
        define('WP_SITEURL', $protocol . $domain);
    }
}
?>
