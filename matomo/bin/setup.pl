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
    my $context      = $config->getResolveOrNull( 'appconfig.context' );
    my $adminUser    = $config->getResolveOrNull( 'site.admin.userid' );
    my $adminPass    = $config->getResolveOrNull( 'site.admin.credential' );
    my $adminEmail   = $config->getResolveOrNull( 'site.admin.email' );
    my $apache2User  = $config->getResolveOrNull( 'apache2.uname' );
    my $dbUser       = $config->getResolveOrNull( 'appconfig.mysql.dbuser.maindb' );
    my $dbPass       = $config->getResolveOrNull( 'appconfig.mysql.dbusercredential.maindb' );
    my $dbName       = $config->getResolveOrNull( 'appconfig.mysql.dbname.maindb' );
    my $dbHost       = '127.0.0.1'; # for now to avoid localhost # $config->getResolveOrNull( 'appconfig.mysql.dbhost.maindb' );

    my $hostname     = $config->getResolveOrNull( 'site.hostname' );
    if( '*' eq $hostname ) {
        $hostname = $config->getResolveOrNull( 'hostname' ); # gotta have something
    }
    my $fullContext = $config->getResolveOrNull( 'site.protocol' ) . '://' . $hostname . $context;

    my @cmds = (
        # We don't do:
        #     "curl --insecure --fail -X POST '$fullContext/index.php?action=databaseSetup&clientProtocol=http' --data 'type=InnoDB&host=$dbHost&username=$dbUser&password=$dbPass&dbname=$dbName&tables_prefix=matomo_&adapter=PDO%5CMYSQL&submit=Next+%C2%BB'"
        # because this will only create the config file, and we did that already

        "curl --insecure --fail '$fullContext/index.php?action=tablesCreation&clientProtocol=http&module=Installation'",
        "curl --insecure --fail -X POST '$fullContext/index.php?action=setupSuperUser&clientProtocol=http&module=Installation' --data 'login=$adminUser&password=$adminPass&password_bis=$adminPass&email=$adminEmail&submit=Next+%C2%BB'",
        "curl --insecure --fail -X POST '$fullContext/index.php?action=firstWebsiteSetup&clientProtocol=http&module=Installation' --data 'siteName=Dummy&url=https%3A%2F%2Fwww.example.com%2F&timezone=UTC&ecommerce=0&submit=Next+%C2%BB'",
        "curl --insecure --fail -X POST '$fullContext/index.php?action=finished&clientProtocol=http&module=Installation&site_idSite=1&site_name=Dummy' --data 'setup_geoip2=1&do_not_track=1&anonymise_ip=1&submit=Continue+to+Matomo+%C2%BB'"
    );

    my $out = '';
    foreach my $cmd ( @cmds ) {
        if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out ) != 0 ) {
            error( "Initializing matomo failed: $cmd: $out" );
            $ret = 0;
        }
    }
}

$ret;
