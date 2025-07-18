<?php
/**
 * phpMyAdmin configuration for reverse proxy setup
 * Note: Login security disabled due to reverse proxy session cookie issues
 */

/* Blowfish secret for cookie encryption */
$cfg['blowfish_secret'] = 'your-32-character-secret-key-here-1234';

/* Disable version check */
$cfg['VersionCheck'] = false;

/* Simple configuration that works with reverse proxy */
$cfg['PmaAbsoluteUri'] = '';

/* Reduce security for reverse proxy compatibility */
$cfg['AllowThirdPartyFraming'] = true;

/* Note: For production use, enable login security and access phpMyAdmin 
   directly at localhost:8080 instead of through the reverse proxy */
