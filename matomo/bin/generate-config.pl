#!/usr/bin/perl
#
# Generate the configuration file. This needs to be a script to handle
# hostname == * correctly.
#
# Copyright (C) 2018 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

if( 'deploy' eq $operation ) {
    my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );
    my $cacheDir     = $config->getResolveOrNull( 'appconfig.cachedir' );
    my $dbUser       = $config->getResolveOrNull( 'appconfig.mysql.dbuser.maindb' );
    my $dbPass       = $config->getResolveOrNull( 'appconfig.mysql.dbusercredential.maindb' );
    my $dbName       = $config->getResolveOrNull( 'appconfig.mysql.dbname.maindb' );
    my $dbHost       = $config->getResolveOrNull( 'appconfig.mysql.dbhost.maindb' );

    my $salt         = $config->getResolveOrNull( 'installable.customizationpoints.salt.value' );

    my $apache2User  = $config->getResolveOrNull( 'apache2.uname' );
    my $apache2Group = $config->getResolveOrNull( 'apache2.gname' );

    my $hostname     = $config->getResolveOrNull( 'site.hostname' );

    my $content = <<CONTENT;
; <?php exit; ?> DO NOT REMOVE THIS LINE
; file automatically generated or modified by UBOS; do not modify
[database]
host = "$dbHost"
username = "$dbUser"
password = "$dbPass"
dbname = "$dbName"
tables_prefix = "matomo_"
adapter = "MYSQLI"

[General]
salt = "$salt"
CONTENT

    if( '*' eq $hostname ) {
        $content .= <<CONTENT;
enable_trusted_host_check=0
CONTENT
    } else {
        $content .= <<CONTENT;
trusted_hosts[] = "$hostname"
CONTENT
    }


    UBOS::Utils::saveFile( "$appConfigDir/config/config.ini.php", $content, 0600, $apache2User, $apache2Group );
}
if( 'undeploy' eq $operation ) {
    my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );

    UBOS::Utils::deleteFile( "$appConfigDir/config/config.ini.php" );
}

1;
