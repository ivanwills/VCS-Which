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
uptodate();

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

sub uptodate {
    my $vcsw = eval { VCS::Which->new() };

    eval { $vcsw->uptodate() };
    my $error = $@;
    like $error, qr/No directory supplied!/, "Errors if no directory set";

    $vcsw->{dir} = 't';
    my $uptodate = $vcsw->uptodate();
    is $uptodate, 1, 'The t directory is up to date';

    {
        no warnings;
        $VCS::Which::Plugin::Blank::uptodate = 0;
    }

    $uptodate = $vcsw->uptodate('t');
    is $uptodate, 1, 'The t directory is up to date (cached)';

    $uptodate = $vcsw->uptodate('.');
    is $uptodate, 0, 'The current directory is not up to date';
}

