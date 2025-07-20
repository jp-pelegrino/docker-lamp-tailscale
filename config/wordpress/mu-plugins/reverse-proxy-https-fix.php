<?php
/**
 * Plugin Name: Reverse Proxy HTTPS Fix
 * Description: Fixes HTTPS URL handling for WordPress running behind a reverse proxy
 * Version: 1.0
 * Author: Auto-generated
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Fix URLs for WordPress Customizer and admin when behind HTTPS reverse proxy
 */
class ReverseProxyHTTPSFix {
    
    public function __construct() {
        add_action('init', array($this, 'init_fixes'));
        add_action('admin_init', array($this, 'admin_fixes'));
    }
    
    /**
     * Initialize URL fixes for front-end and customizer
     */
    public function init_fixes() {
        // Fix for WordPress Customizer preview iframe
        if (is_customize_preview() || (isset($_GET['customize_theme']) && $_GET['customize_theme'])) {
            add_filter('home_url', array($this, 'force_https_url'));
            add_filter('site_url', array($this, 'force_https_url'));
            add_filter('wp_get_attachment_url', array($this, 'force_https_url'));
        }
        
        // Fix for any AJAX calls or REST API requests
        if (wp_doing_ajax() || (defined('REST_REQUEST') && REST_REQUEST)) {
            add_filter('home_url', array($this, 'force_https_url'));
            add_filter('site_url', array($this, 'force_https_url'));
        }
    }
    
    /**
     * Initialize URL fixes for admin area
     */
    public function admin_fixes() {
        if (is_admin()) {
            add_filter('admin_url', array($this, 'force_https_url'));
            add_filter('home_url', array($this, 'force_https_url'));
            add_filter('site_url', array($this, 'force_https_url'));
            add_filter('wp_get_attachment_url', array($this, 'force_https_url'));
        }
    }
    
    /**
     * Force HTTPS in URLs
     */
    public function force_https_url($url) {
        return str_replace('http://', 'https://', $url);
    }
}

// Initialize the plugin
new ReverseProxyHTTPSFix();
?>
