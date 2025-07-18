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

/* Disable version check */
$cfg['VersionCheck'] = false;

/* Override protocol detection - simple approach */
$_SERVER['HTTPS'] = 'on';
$_SERVER['SERVER_PORT'] = '443';

/* Session and cookie settings that work with reverse proxy */
$cfg['CookieHttpOnly'] = false;  // Allow JavaScript access to cookies
$cfg['CookieSameSite'] = 'None';  // Allow cross-site cookies
$cfg['LoginCookieValidity'] = 28800; // 8 hours

/* Force disable SSL checks that might cause issues */
$cfg['ForceSSL'] = false;

/* Set absolute URI to empty to let phpMyAdmin auto-detect */
$cfg['PmaAbsoluteUri'] = '';

/* Disable trusted proxies check */
$cfg['TrustedProxies'] = [];
$cfg['AllowThirdPartyFraming'] = true;
