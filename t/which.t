#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use lib qw{t/lib};
use VCS::Which;

new();
capabilities();

done_testing();

sub new {
    my $vcsw = eval { VCS::Which->new };
    ok !$@, "No error creating" or diag $@;

    $vcsw = eval { VCS::Which->new( dir => '.' ) };
    ok !$@, "No error creating" or diag $@;

    $vcsw = eval { VCS::Which->new( dir => 'Build.PL' ) };
    ok !$@, "No error creating" or diag $@;
}

sub capabilities {
    my $vcsw = eval { VCS::Which->new };

    my %capabilities = $vcsw->capabilities;

    # Only guarentee Blank installed
    ok $capabilities{Blank}, "Blank test VCS installed";
}

