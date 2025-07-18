<?php
/**
 * phpMyAdmin configuration for reverse proxy setup
 * This file handles HTTPS/reverse proxy configuration
 */

/* Enable reverse proxy detection */
$cfg['PmaAbsoluteUri'] = '';

/* Trust proxy headers for HTTPS detection */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}

/* Force HTTPS for cookie security when behind proxy */
$cfg['ForceSSL'] = false; // Let the proxy handle SSL
$cfg['CookieHttpOnly'] = true;
$cfg['CookieSameSite'] = 'Lax';

/* Authentication method - use cookie for login prompt */
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = $_ENV['PMA_HOST'] ?: 'db';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

/* Increase cookie validity to 8 hours */
$cfg['LoginCookieValidity'] = 28800;

/* Other security settings */
$cfg['blowfish_secret'] = 'a8b7c6d9e0f1g2h3i4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x9y0z1';
$cfg['VersionCheck'] = false;

/* Upload settings */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

/* Navigation and interface */
$cfg['NavigationTreeEnableGrouping'] = true;
$cfg['NavigationTreeDbSeparator'] = '_';
$cfg['NavigationTreeDefaultTabTable'] = 'browse';

/* Query settings */
$cfg['SqlQuery']['Edit'] = true;
$cfg['SqlQuery']['Explain'] = true;
$cfg['SqlQuery']['ShowAsPHP'] = true;
