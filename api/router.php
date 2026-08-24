<?php
// PHP Built-in Web Server Router for Mobile & Web Development
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

if ($uri !== '/' && file_exists(__DIR__ . '/..' . $uri)) {
    return false; // serve requested resource as-is
}

$_SERVER['SCRIPT_NAME'] = '/EXAMVERSE/api/index.php';
require_once __DIR__ . '/index.php';
