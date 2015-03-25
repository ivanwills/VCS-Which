#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use lib qw{t/lib};
use VCS::Which;

new();

done_testing();

sub new {
    my $vcsw = eval { VCS::Which->new };
    ok !$@, "No error creating" or diag $@;
}
