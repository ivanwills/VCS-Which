#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use lib qw{t/lib};
use VCS::Which;

new();
capabilities();
which();

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

    %capabilities = $vcsw->capabilities('.');

    # Only guarentee Blank installed
    is $capabilities{Blank}{installed}, 0.5, "Blank test VCS installed in .";
}

sub which {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $which = $vcsw->which();
    isa_ok $which, 'VCS::Which::Plugin::Blank';

    $which = $vcsw->which('.');
    isa_ok $which, 'VCS::Which::Plugin::Blank';
}

