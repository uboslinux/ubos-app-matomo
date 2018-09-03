#!/usr/bin/perl
#
# Upgrade
#
# Copyright (C) 2018 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

if( 'install' eq $operation || 'upgrade' eq $operation ) {
    my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );

    my $cmd = "cd '$appConfigDir';";
    $cmd .= " TERM=vt100";
    $cmd .= " php";
    $cmd .= " -d open_basedir='$appConfigDir:/ubos/share/:/tmp'";
    $cmd .= " console core:update --yes";

    my $out = '';
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out ) != 0 ) {
        error( "Upgrading matomo failed: $out" );
        $ret = 0;
    }
}

$ret;




