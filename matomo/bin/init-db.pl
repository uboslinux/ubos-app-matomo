#!/usr/bin/perl
#
# Initialize the database.
#
# Copyright (C) 2018 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

if( 'install' eq $operation ) {
    my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );
    my $appConfigId  = $config->getResolveOrNull( 'appconfig.appconfigid' );
    my $adminUser    = $config->getResolveOrNull( 'site.admin.userid' );
    my $adminPass    = $config->getResolveOrNull( 'site.admin.credential' );
    my $adminEmail   = $config->getResolveOrNull( 'site.admin.email' );
    my $apache2User  = $config->getResolveOrNull( 'apache2.uname' );

    my $hostname     = $config->getResolveOrNull( 'site.hostname' );
    if( '*' eq $hostname ) {
        $hostname = $config->getResolveOrNull( 'hostname' ); # gotta have something
    }
    my $hostProto    = $config->getResolveOrNull( 'site.protocol' ) . '://' . $hostname;

    my $cmd = "cd '$appConfigDir';";
    $cmd .= " TERM=vt100";
    $cmd .= " sudo -u " . $apache2User;
    $cmd .= " php";
    $cmd .= " -d open_basedir='$appConfigDir:/var/cache/$appConfigId:/tmp/:/ubos/tmp/'";

    # Taken mostly from plugins/Installation/Controller.php
    # and https://raw.githubusercontent.com/nebev/piwik-cli-setup/master/install.php
    my $php = <<PHP;
<?php

define('PIWIK_DOCUMENT_ROOT', '$appConfigDir' );
PHP
        $php .= <<'PHP';
if (file_exists(PIWIK_DOCUMENT_ROOT . '/bootstrap.php')) {
    require_once PIWIK_DOCUMENT_ROOT . '/bootstrap.php';
}
if (!defined('PIWIK_INCLUDE_PATH')) {
    define('PIWIK_INCLUDE_PATH', PIWIK_DOCUMENT_ROOT);
}

require_once PIWIK_INCLUDE_PATH . '/core/bootstrap.php';

use Piwik\ErrorHandler;
use Piwik\ExceptionHandler;
use Piwik\FrontController;
use Piwik\Access;
use Piwik\Plugins\UsersManager\API as APIUsersManager;
use Piwik\Plugins\SitesManager\API as APISitesManager;
use Piwik\Config;
use Piwik\DbHelper;
use Piwik\Updater;
use Piwik\Plugin\Manager;

if (!defined('PIWIK_ENABLE_ERROR_HANDLER') || PIWIK_ENABLE_ERROR_HANDLER) {
    Piwik\ErrorHandler::registerErrorHandler();
    Piwik\ExceptionHandler::setUp();
}

FrontController::setUpSafeMode();
$environment = new \Piwik\Application\Environment(null);
try {
    $environment->init();
} catch(\Exception $e) {}

$config = Config::getInstance();
$config->init();

DbHelper::createTables();
DbHelper::createAnonymousUser();
DbHelper::recordInstallVersion();

Access::getInstance();

Access::doAsSuperUser(function () {
    $updater = new Updater();
    $componentsWithUpdateFile = $updater->getComponentUpdates();

    if (empty($componentsWithUpdateFile)) {
        return false;
    }
    $result = $updater->updateComponents($componentsWithUpdateFile);
});

Access::doAsSuperUser(function () use ($config_arr) {
    $api = APIUsersManager::getInstance();
PHP

    $php .= <<PHP;
    \$api->addUser( '$adminUser', '$adminPass', '$adminEmail' );
    \$api->setSuperUserAccess( '$adminUser', true);
PHP
    $php .= <<'PHP';
});

Access::doAsSuperUser(function () use ($config_arr) {
PHP

    $php .= <<PHP;
    return APISitesManager::getInstance()->addSite( 'dummy', 'http', 0);
PHP
    $php .= <<'PHP';
});

Manager::getInstance()->loadAllPluginsAndGetTheirInfo();
PHP

    my $out = '';
    if( UBOS::Utils::myexec( $cmd, $php, \$out, \$out ) != 0 ) {
        error( "Initializing matomo failed: $out" );
        $ret = 0;
    }
}

$ret;
