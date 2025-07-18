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

/* Disable version check */
$cfg['VersionCheck'] = false;

/* Handle reverse proxy setup */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

/* Set the base path for phpMyAdmin when accessed via /phpmyadmin/ */
$cfg['PmaAbsoluteUri'] = '';
