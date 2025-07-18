<?php
/**
 * phpMyAdmin configuration for reverse proxy setup
 */

/* Blowfish secret for cookie encryption */
$cfg['blowfish_secret'] = 'your-32-character-secret-key-here-1234';

/* Authentication method - cookie for login prompt */
$i = 1;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'db';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

/* Cookie settings for reverse proxy */
$cfg['CookieHttpOnly'] = true;
$cfg['CookieSameSite'] = 'Lax';
$cfg['LoginCookieValidity'] = 28800; // 8 hours

/* Session settings for reverse proxy */
$cfg['SessionSavePath'] = '';

/* Disable version check */
$cfg['VersionCheck'] = false;

/* Handle reverse proxy setup - must be before any redirects */
// Force HTTPS detection when behind reverse proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = '443';
}

// Additional HTTPS detection methods
if (isset($_SERVER['HTTP_X_FORWARDED_PORT']) && $_SERVER['HTTP_X_FORWARDED_PORT'] == '443') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = '443';
}

// Override REQUEST_SCHEME if needed
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO'])) {
    $_SERVER['REQUEST_SCHEME'] = $_SERVER['HTTP_X_FORWARDED_PROTO'];
}

/* Force HTTPS URLs in phpMyAdmin */
$cfg['ForceSSL'] = true;

/* Set the absolute URI for phpMyAdmin to handle reverse proxy properly */
$cfg['PmaAbsoluteUri'] = 'https://wvdoh.dorper-beta.ts.net/phpmyadmin/';

/* Additional security settings for reverse proxy */
$cfg['TrustedProxies'] = ['172.19.0.6/32']; // nginx container IP
$cfg['AllowThirdPartyFraming'] = false;
