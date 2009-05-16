#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'VCS::Which' );
}

diag( "Testing VCS::Which $VCS::Which::VERSION, Perl $], $^X" );
