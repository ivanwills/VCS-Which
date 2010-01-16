package VCS::Which::Plugin::Git;

# Created on: 2009-05-16 16:58:22
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/VCS::Which::Plugin/;
use Path::Class;
use File::chdir;
use Contextual::Return;

our $VERSION = version->new('0.1.0');
our $name    = 'Git';
our $exe     = 'git';
our $meta    = '.git';

sub installed {
	my ($self) = @_;

	return $self->{installed} if exists $self->{installed};

	for my $path (split /[:;]/, $ENV{PATH}) {
		next if !-x "$path/$exe";

		return $self->{installed} = 1;
	}

	return $self->{installed} = 0;
}

sub used {
	my ( $self, $dir ) = @_;

	if (-f $dir) {
		$dir = file($dir)->parent;
	}

	croak "$dir is not a directory!" if !-d $dir;

	my $current_dir = dir($dir)->absolute;
	my $level       = 1;

	while ($current_dir) {
		if ( -d "$current_dir/$meta" ) {
			$self->{base} = $current_dir;
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

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-d $dir;

	local $CWD = $dir;
	my $ans = `$exe status $dir`;

	return $ans =~ /nothing \s to \s commit/xms ? 1 : 0;
}

sub pull {
	my ( $self, $dir ) = @_;

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-e $dir;

	local $CWD = $dir;
	return !system "$exe pull";
}

sub cat {
	my ($self, $file, $revision) = @_;

	if ( $revision && $revision =~ /^-\d+$/xms ) {
		eval { require Git };
		if ($EVAL_ERROR) {
			die "Git.pm is not installed only propper revision names can be used\n";
		}

		my $repo = Git->repository(Directory => $self->{base});
		my @revs = reverse $repo->command('rev-list', '--all', '--', $file);
		my $rev = $revs[$revision];

		return join "\n", $repo->command('show', $rev . ':' . $file);
	}
	elsif ( !defined $revision ) {
		$revision = '';
	}

	return `$exe show $revision\:$file`;
}

sub log {
	my ($self, @args) = @_;

	my $args = join ' ', @args;

		SCALAR   { `$exe log $args` }
		ARRAYREF { `$exe log $args` }
		HASHREF  {
			my $logs = `$exe log $args`;
			my @logs = split /^commit\s*/xms, $logs;
			shift @logs;
			my $num = @logs;
			my %log;
			for my $log (@logs) {
				my ($ver, $rest) = split /\n/, $log, 2;
				my ($details, $description) = split /\n\n\s*/, $rest, 2;
				$log{$num} = { map {split /:\s*/, $_, 2} split /\n/, $details };
				$log{$num}{description} = $description;
				$log{$num--}{rev} = $ver;
			}
			return \%log;
		}
}

sub versions {
	my ($self, $file, $revision) = @_;

	eval { require Git };
	if ($EVAL_ERROR) {
		die "Git.pm is not installed only propper revision names can be used\n";
	}

	my $repo = Git->repository(Directory => $self->{base});
	my @revs = reverse $repo->command('rev-list', '--all', '--', file($file)->absolute->resolve);

	return @revs;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Git - The Git plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Git version 0.1.0.

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
