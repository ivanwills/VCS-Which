#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval { require Test::Spelling; Test::Spelling->import() };

plan skip_all => "Test::Spelling required for testing POD coverage" if $@;

add_stopwords(qw/NSW Hornsby Param SVK CVS VCS vcs versioned plugins /);
all_pod_files_spelling_ok();
