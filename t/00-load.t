#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6 + 1;
use Test::NoWarnings;

BEGIN {
	use_ok( 'VCS::Which' );
	use_ok( 'VCS::Which::Plugin' );
	use_ok( 'VCS::Which::Plugin::Bazaar' );
	use_ok( 'VCS::Which::Plugin::CVS' );
	use_ok( 'VCS::Which::Plugin::Git' );
	use_ok( 'VCS::Which::Plugin::Subversion' );
}

diag( "Testing VCS::Which $VCS::Which::VERSION, Perl $], $^X" );
