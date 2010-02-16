package VCS::Which::Plugin::CVS;

# Created on: 2009-05-16 16:58:14
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

our $VERSION = version->new('0.1.1');
our $name    = 'CVS';
our $exe     = 'cvs';
our $meta    = 'CVS';

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

	return -d "$dir/$meta";
}

sub uptodate {
	my ( $self, $dir ) = @_;

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-e $dir;

	return `$exe status $dir`;
}

sub pull {
	my ( $self, $dir ) = @_;

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-e $dir;

	local $CWD = $dir;
	return !system '$exe update';
}

sub cat {
	my ($self, $file, $revision) = @_;

	if ( $revision && $revision =~ /^-\d+$/xms ) {
		my @versions = reverse `$exe log -q $file` =~ /^ revision \s+ (\d+[.]\d+)/gxms;
		$revision = $versions[$revision];
	}
	elsif ( !defined $revision ) {
		$revision = '';
	}

	$revision &&= "-r$revision";

	return `$exe cat $revision $file`;
}

sub log {
	my ($self, @args) = @_;

	my $args = join ' ', @args;

	return
		SCALAR   { `$exe log $args` }
		ARRAYREF { `$exe log $args` }
#		HASHREF  {
#			my $logs = `$exe log $args`;
#			my @logs = split /^-+\n/xms, $logs;
#			shift @logs;
#			my $num = @logs;
#			my %log;
#			for my $log (@logs) {
#				my ($details, $description) = split /\n\n?/, $log, 2;
#				$details =~ s/^\s*(.*?)\s*/$1/;
#				my @details = split /\s+\|\s+/, $details;
#				$details[0] =~ s/^r//;
#				$log{$num--} = {
#					rev    => $details[0],
#					Author => $details[1],
#					Date   => $details[2],
#					description => $description,
#				},
#			}
#			return \%log;
#		}
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::CVS - CVS plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::CVS version 0.1.1.

=head1 SYNOPSIS

   use VCS::Which::Plugin::CVS;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

The plugin for the Concurrent Versioning System (CVS)

=head1 SUBROUTINES/METHODS

=head3 C<installed ()>

Return: bool - True if the CVS is installed

Description: Determines if CVS is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this CVS

Description: Determines if the directory is under version control of this CVS

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
