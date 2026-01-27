package VCS::Which::Plugin::Git;

# Created on: 2009-05-16 16:58:22
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use File::chdir;
use Contextual::Return;

extends 'VCS::Which::Plugin';

our $VERSION = version->new('0.6.9');
our $name    = 'Git';
our $exe     = 'git';
our $meta    = '.git';

sub installed {
    my ($self) = @_;

    return $self->_installed if defined $self->_installed;

    for my $path (split /[:;]/, $ENV{PATH}) {
        next if !-x "$path/$exe";

        return $self->_installed( 1 );
    }

    return $self->_installed( 0 );
}

sub used {
    my ( $self, $dir ) = @_;

    if (-f $dir) {
        $dir = path($dir)->parent;
    }

    croak "$dir is not a directory!" if !-d $dir;

    my $current_dir = path($dir)->absolute;
    my $level       = 1;

    while ($current_dir) {
        if ( -d "$current_dir/$meta" ) {
            $self->_base( $current_dir );
            return $level;
        }

        $level++;

        # check that we still have a parent directory
        last if $current_dir eq $current_dir->parent;

        $current_dir = $current_dir->parent;
    }

    return 0;
}

sub uptodate {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-d $dir;

    local $CWD = path($dir)->absolute;
    my $ans = `$exe status`;

    return $ans =~ /nothing \s to \s commit/xms ? 1 : 0;
}

sub pull {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe pull > /dev/null 2> /dev/null";
}

sub push {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe push origin master > /dev/null 2> /dev/null";
}

sub cat {
    my ($self, $file, $revision) = @_;

    # git expects $file to be relative to the base of the git repo not the
    # current directory so we change it to being relative to the repo if nessesary
    my $repo_dir = path($self->_base) or confess "How did I get here with out a base directory?\n";
    my $cwd      = path('.')->absolute;
    local $CWD = $CWD;

    if ( -f $file && $cwd ne $repo_dir ) {
        # get relavie directory of $cwd to $repo_dir
        my ($relative) = $cwd =~ m{^ $repo_dir / (.*) $}xms;
        my $old = $file;
        $file = path("$relative/$file");
        warn "Using repo absolute file $file from $old\n" if $ENV{VERBOSE};
        $CWD = $repo_dir;
    }

    if ( $revision && $revision =~ /^-?\d+$|[^0-9a-fA-F]/xms ) {
        eval { require Git };
        if ($EVAL_ERROR) {
            die "Git.pm is not installed only propper revision names can be used\n";
        }

        my $repo = Git->repository(Directory => $self->_base);
        my @revs = reverse $repo->command('log', '--format=format:%H', '--', $file);
        $revision = $revision =~ /^[-]?\d+$/xms && $revs[$revision] ? $revs[$revision] : $revision;
    }
    elsif ( !defined $revision ) {
        $revision = '';
    }
    warn "$exe show $revision\:$file\n" if $ENV{VERBOSE};

    return `$exe show $revision\:$file`;
}

sub log {
    my ($self, @args) = @_;
    local $CWD = $CWD;

    my $dir;
    if ( defined $args[0] && -d $args[0] && $args[0] =~ m{^/} ) {
        $dir = shift @args;
        $CWD = $dir;
    }
    my $args = join ' ', grep {defined $_} @args;

    return
        SCALAR   { scalar `$exe log $args` }
        ARRAYREF {
            my @raw_log = `$exe log $args`;
            my @log;
            my $line = '';
            for my $raw (@raw_log) {
                if ( $raw =~ /^commit / && $line ) {
                    CORE::push @log, $line;
                    $line = $raw;
                }
                else {
                    $line .= $raw;
                }

            }
            return \@log;
        }
        HASHREF  {
            my $logs = `$exe log $args`;
            my @logs = split /^commit\s*/xms, $logs;
            shift @logs;
            my $num = @logs;
            my %log;
            for my $log (@logs) {
                $log{$num--} = $self->_log_expand($log);
            }
            return \%log;
        }
}

sub _log_expand {
    my ($self, $log) = @_;

    # split the commit from the reset of the message
    my ($ver, $rest) = split /\n/, $log, 2;

    # split log details and the description
    my ($details, $description) = split /\n\n\s*/, $rest, 2;

    # remove excess whitespace at the end of the description
    $description =~ s/\s+\Z//xms;
    my ($conflicts) = $description =~ /\s+Conflicts:\s+(.*)\Z/xms;
    $description =~ s/\s+Conflicts:\s+(.*)\Z//xms;

    # split up the details
    my %log = map {split /:\s*/, $_, 2} split /\n/, $details;

    # add in the description
    $log{description} = $description;

    # add in the revision
    $log{rev} = $ver;

    # add conflicts if any
    $log{conflicts} = [ split /\n\s+/, $conflicts ] if $conflicts;

    return \%log;
}

sub versions {
    my ($self, $file, $oldest, $newest, $max) = @_;

    eval { require Git };
    if ($EVAL_ERROR) {
        die "Git.pm is not installed only propper revision names can be used\n";
    }

    my $repo = Git->repository(Directory => $self->_base);
    my @revs = reverse $repo->command('rev-list', '--all', '--', path($file)->absolute);

    return @revs;
}

sub status {
    my ($self, $dir) = @_;
    my %status;
    my $name = '';
    if ( -f $dir ) {
        $name = path($dir)->absolute->basename;
    }
    local $CWD = -f $dir ? path($dir)->absolute->parent : path($dir)->absolute;
    my @status = `$exe status --porcelain=v2 $name`;
#    my @status = split /\n/, <<'SAMPLE';
#1 M. N... 100644 100644 100644 7abbe249688069952d659f985b9f1b31932365f1 682fc51a637bee78625a3c7abbb7d5969f328c53 .storybook/main.js
#1 M. N... 100644 100644 100644 65ac8a3f3bba6c286295fc753f0b94c81c7e9375 3dbc9982cef436ffb2d44472b3157fd401cd24ff .storybook/preview.js
#1 M. N... 100644 100644 100644 35f913af84de61aae985360e022e1db2ed20fd0b 451d961ad22a22e051588ca86b8644aae1a22d0f bamboo-specs/src/main/java/au/com/optus/lux2/FortifySpec.java
#1 M. N... 100644 100644 100644 515a1cafd7ed5338d54b9196bb4613215a713994 91272f841a56e89882034d6296490d00f4ea9fff configs/setupTests.js
#1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 0967ef424bce6791893e9a57bb952f80fd536e93 cypress/fixtures/status.json
#1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 096e00d32336b66648a1d6a0191f08686b3bbc14 mocks/server.js
#1 .M N... 100644 100644 100644 fb53c20d436346683d8775fe0e3015504d5318be fb53c20d436346683d8775fe0e3015504d5318be modules.d.ts
#1 M. N... 100644 100644 100644 89ec0a534dbe35c7cf8b7cb4164d629d123a5ed2 f4f46592383bffec3739eac12fb368abd9106fed pages/usesingleifmulti.html
#1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 51d85eeebf6abeaeef7d640b6fa0bdc60b872738 public/mockServiceWorker.js
#1 M. N... 100644 100644 100644 dbee3b985b2597bc915efa8ada8c1a11a78cefe0 0180cf0daf171ec94ddf957c0580fe75532fd71c routes.js
#1 M. N... 100755 100755 100755 b658997458b1a576c9bd183669291a0bb139361b fb7b3236fa8138e908c13929d0047f3ade33f111 scripts/bamboo.sh
#1 M. N... 100644 100644 100644 32850044be404098ef0b534e366c9a800f95cd0a c55cd824aff83a10ab368c1d1c98e6311b6c8dc8 src/App.tsx
#1 D. N... 100644 000000 000000 3c8ab75b73e0224161090cc0c50b698802828486 0000000000000000000000000000000000000000 src/Imports/Anchor/AnchorWrapper.js
#1 D. N... 100644 000000 000000 e5df0cf0999e3e3643f5326f7534a3f49b71adf6 0000000000000000000000000000000000000000 src/Imports/ImageOptus/ImageOptus.js
#1 M. N... 100644 100644 100644 07c33e3ce0a6a286d146355482de1e3bfede7073 9285dfa38de1bae1d5fcaad8b18a524205337500 src/StateProvider.tsx
#1 M. N... 100644 100644 100644 898acc85e0e97877c1e3ac52e37473bca6ec239e 3c8491eea481f85d405abad40202e8a792c0560e src/__tests__/App.test.tsx
#1 M. N... 100644 100644 100644 fd136aad5aeff250b6f7f3e2102fbaa93919a949 481409de2c528dc05e75eb838d1269eb5c9f3a19 src/components/CisSearchCategory/__tests__/CisSearchCategory.test.tsx
#1 M. N... 100644 100644 100644 e060b5b9c8b4c13fc980cd006e219e89ab168154 d7df526b0b3031a8eb08a69778de6c82e346b30c src/components/CisSearchPlanId/SearchResults/ResultList.tsx
#1 M. N... 100644 100644 100644 c84c3d047a9ae30b0f855a56eaa40b0ddd47a50d b43b609876ac0015628e61e5aa200966070272db src/components/CisSearchPlanId/SearchResults/index.tsx
#1 M. N... 100644 100644 100644 dc88d11e3931bb8ebb0da48b00de08da73308dba 2316ab5d6c6238c094c14598714dd99cfd09b947 src/components/CisSearchPlanId/index.tsx
#1 M. N... 100644 100644 100644 64f2504a99c1082e4da30d3ee6a7ec2a32ac5581 01be8d3d9a41059cc881d026dd7b60d4a9130bb9 src/componentsMap.tsx
#1 M. N... 100644 100644 100644 70a32c40622e1740114a528f1da707cb6bae0687 7c0c449baea8afe4bac3ea2f2f7d043addff12df src/index.tsx
#1 M. N... 100644 100644 100644 3992dd7f5d2c072e2ee960927394ae026453145d d14c80527c00fc149f3ece0d9e360d99885840bb src/unique.tsx
#u AA N... 000000 100644 100644 100644 0000000000000000000000000000000000000000 11e20b51ed9c76cf03f58834fda5b4a5ba357538 c50d3994031b27e644ede223850f3adbcb4c0c4a .gitlab-ci.yml
#u AA N... 000000 100644 100644 100644 0000000000000000000000000000000000000000 96afe490ceebf2f8937b09f79d38222c9289cfda 7fcde6eb8e81a6e6029dae4b1a90eeca062646ff CODEOWNERS
#u UU N... 100644 100644 100644 100644 cc67f3aca819d11e42d66fe2b5ba6f2e9531ccad 58c2b4eac378e49df7b72200290c8998fc1ff5c7 b32aba7cdff9a5b057935671dce69a011e41a81e Changes.md
#u UU N... 100644 100644 100644 100644 f448410a585a551a3f994cacd6fb134cfacd74e4 0b71c62442a7fa951b25a48ab0cb59129700e31e 0340381e16657351d151a1f224b899d87ba41e39 babel.config.js
#u UU N... 100644 100644 100644 100644 09002a805c9a52c5a4566e34c087fcfc82d14886 e405367df64198ac3ad3d7432f631c5893c40292 5e96c50c1e7d27dbc8b6cd5edb4665af531ffbbe bamboo-specs/src/main/java/au/com/optus/lux2/PlanSpec.java
#u UU N... 100644 100644 100644 100644 e29073510c6836ff1e9ef07231dd559ab4a0f785 e57b2b0cb812c50c37a86d3a5765da0301c3f3e5 6d8eb896c8936d656cc41a4fa8c1426e758b0b4c configs/jest.config.js
#u DU N... 100644 000000 100644 100644 6e8bf9993e087dcbd45c18b478ee6679dcaaefce 0000000000000000000000000000000000000000 669e8bcb3c2ca07c6a06cdb48e066444e959b618 cypress/integration/breadcrumbs.feature
#u UU N... 100644 100644 100644 100644 951243534df1f958a7814176e9c1cb2adda1260a f4d21f147fb9559a3cb86baa375a7af493741f00 554d9950f6dfcfaa96fa35141b2ade8f3b5b87e9 package-lock.json
#u UU N... 100644 100644 100644 100644 da2792acea7acfc37523b41f75b28063ad8daa88 af5547fde4354a2d4254fb0992e44e9107bad4ef 2d337e666d889ed89ad171a445ba531a18b8b8f0 package.json
#u UU N... 100644 100644 100644 100644 7dc233ecde584377ac17aaa3d5921b6a609e4284 9c3400f118bc03ed755f6f7e89c246441e05b502 54c92e45b8ad3f7dfddf46e38a866a2dbae21bd5 src/GlobalComponents.tsx
#u UU N... 100644 100644 100644 100644 700fc2e902b9e056f83cfc2906a9affef3bf8e40 2c92c7532e388a3fb5fd69ee97a1364790670a61 da345c0da7283aa1dfe92e9d4bdccba4912b02b3 src/Imports/BannerVideo.jsx
#u DU N... 100644 000000 100644 100644 356b09a272809c79fd90cc8ab5359ec12dce959d 0000000000000000000000000000000000000000 7269d4fe0f6dd30a2980d630a03c29236c32504a src/Imports/Breadcrumbs/Breadcrumbs.stories.tsx
#u UU N... 100644 100644 100644 100644 4b65a568986c731f027f53c9d7d4f65949cdd69f 7deb645eeb6b9e441769e671ae3decb7ac3caca3 90d8b1f1baa59d882d4e0b842e9c87e026a4f204 src/register.js
#u UU N... 100644 100644 100644 100644 4e13d1bf72df3f723e4eaf646615d93b559890e3 47cda57e9b5aa47e3a88aa84fe6de6a30fd82562 d552f491db056f8b10537e19731c226dd0d3c17a tsconfig.json
#u UU N... 100644 100644 100644 100644 3fd7277cbced6ca0dfbe42d3520588393b6bbb66 34400ab1773329099e97d23722fe6d5344f21c07 154096624a3b9e3f04bc0f6ac6cde1518a6a9704 webpack.common.js
#? independentIndex.html
#? mock
#? pages/prod.html
#? pages/sit.html
#? pages/webex-prod-orig.html
#? pages/webex-prod.html
#? pages/webex-sit-orig.html
#? pages/webex-sit.html
#SAMPLE

    for my $file_line (@status) {
        my ($type, $rest) = $file_line =~ /^(.) (.*)$/;
        if ($type eq '?') {
            CORE::push @{$status{untracked}}, $rest;
            next;
        }
        my ($other, $thing, $fss, $shas, $file) = $rest =~ /^([.ADMU]{2}) \s (\S{4}) \s ((?:\d{6} \s?){3,4}) \s ((?:[\dABCDEFabcdef]+ \s?){2,3}) \s (.*)$/xms;

        my $second = $type eq 'u' ? 'unmerged' : 'changed';
        CORE::push @{$status{$second}}, $file;
    }
    return \%status;

    #$status =~ s/^no \s+ changes (.*?) $//xms;
    #chomp $status;

    #my @both = split /\n?[#]?\s+both\s+modified:\s+/, $status;
    #if ( @both > 1 ) {
    #    shift @both;
    #    $both[-1] =~ s/\n.*//xms;
    #    $status{both} = \@both;
    #}

    #my @modified = split /\n?[#]?\s+modified:\s+/, $status;
    #if ( @modified > 1 ) {
    #    shift @modified;
    #    $modified[-1] =~ s/\n.*//xms;
    #    $status{modified} = \@modified;
    #}

    #my @added = split /\n?[#]?\s+new\sfile:\s+/, $status;
    #if ( @added > 1 ) {
    #    shift @added;
    #    $added[-1] =~ s/\n.*//xms;
    #    $status{added} = \@added;
    #}

    #my @committed = split /Changes to be committed:\n/, $status;
    #if (@committed > 1) {
    #    my $new = pop @committed;
    #    $status{committed} = [ $new =~ /^\t[^:]+:\s+(.*?)\n/gxms ];
    #}

    #my @untracked = split /Untracked files:\n/, $status;
    #if ( @untracked > 1 ) {
    #    my $untracked = pop @untracked;
    #    if ($untracked =~ s/^\s+[(]use \s+ "git \s+ add \s+ [^"]+" \s+ [^)]+\)\n\n//xms) {
    #        chomp $untracked;
    #    }
    #    else {
    #        $untracked =~ s/^[#].*?\n//gxms;
    #    }

    #    if ($untracked =~ /^[#]/xms) {
    #        $status{untracked} = [ grep {$_} map {chomp; $_} split /\n?[#]\s+/, $untracked ];
    #    }
    #    else {
    #        $status{untracked} = [ $untracked =~ /^\t(.*?)\n/gxms ];
    #    }
    #}

    #if ($status =~ /
    #    You \s+ have \s+ unmerged \s+ paths[.]$
    #    |
    #    All \s+ conflicts \s+ fixed \s+ but \s+ you \s+ are \s+ still \s+ merging[.]$
    #/xms) {
    #    $status{merge} = 1;
    #}

    #return \%status;
}

sub diff_files {
    warn Dumper \@_;
    my ($self, $dir, @extra) = @_;
    my $name = '';
    if ( -f $dir ) {
        $name = path($dir)->absolute->basename;
    }
    local $CWD = -f $dir ? path($dir)->absolute->parent : path($dir)->absolute;
    my $extra = join ' ', @extra;
    warn Dumper \@_, \@extra;
    warn "$exe diff --name-only $extra\n";
    my @files = split /\n/, `$exe diff --name-only $extra`;
    pop @files;

    return @files;
}

sub checkout {
    my ($self, $dir, @extra) = @_;
    my $name = '';
    if ( -f $dir ) {
        $name = path($dir)->absolute->basename;
    }
    local $CWD = -f $dir ? path($dir)->absolute->parent : path($dir)->absolute;
    my $extra = join ' ', @extra;
    `$exe checkout $extra $name`;

    return;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Git - The Git plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Git version 0.6.9.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Git;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

The plugin for the Git version control system

=head1 SUBROUTINES/METHODS

=head3 C<installed ()>

Return: bool - True if the Git is installed

Description: Determines if Git is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Git

Description: Determines if the directory is under version control of this Git

=head3 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommitted changes

Description: Determines if the directory has no uncommitted changes

=head3 C<cat ( $file[, $revision] )>

Param: C<$file> - string - The name of the file to cat

Param: C<$revision> - string - The revision to get. If the revision is negative
it refers to the number of revisions old is desired. Any other value is
assumed to be a version control specific revision. If no revision is specified
the most recent revision is returned.

Return: The file contents of the desired revision

Description: Gets the contents of a specific revision of a file.

=head3 C<log ( @args )>

TO DO: Body

=head3 C<versions ( [$file], [@args] )>

Description: Gets all the versions of $file

=head3 C<pull ( [$dir] )>

Description: Pulls or updates the directory $dir to the newest version

=head3 C<push ( [$dir] )>

Description: push updates to the master repository

=head3 C<status ( $dir )>

Description: push updates to the master repository

=head3 C<checkout ( [$dir] )>

Checkout clean copy of C<$file>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
