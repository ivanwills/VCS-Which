package VCS::Which::Plugin::Subversion;

# Created on: 2009-05-16 16:58:03
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
use File::chdir;

our $VERSION = version->new('0.0.2');
our $name    = 'Subversion';
our $exe     = 'svn';

sub installed {
	my ($self) = @_;

	return $self->{installed} if exists $self->{installed};

	for my $path (split /[:;]/, $ENV{PATH}) {
		next if !-x "$path/svn";

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

	return -d "$dir/.svn";
}

sub uptodate {
	my ($self, $dir) = @_;

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-e $dir;

	return `svn status $dir`;
}

sub cat {
	my ($self, $file, $revision) = @_;

	if ( $revision && $revision =~ /^-\d+$/xms ) {
		my @versions = reverse `svn log -q $file` =~ /^ r(\d+) \s/gxms;
		$revision = $versions[$revision];
	}
	elsif ( !defined $revision ) {
		$revision = '';
	}

	$revision &&= "-r$revision";

	return `svn cat $revision $file`;
}

sub pull {
	my ( $self, $dir ) = @_;

	$dir ||= $self->{base};

	croak "'$dir' is not a directory!" if !-e $dir;

	local $CWD = $dir;
	return !system 'svn update';
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Subversion - The Subversion plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Subversion version 0.0.2.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Subversion;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

Plugin to provide access to the Subversion version control system

=head1 SUBROUTINES/METHODS

=head3 C<installed ()>

Return: bool - True if the Subversion is installed

Description: Determines if Subversion is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Subversion

Description: Determines if the directory is under version control of this Subversion

=head3 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommitted changes

Description: Determines if the directory has no uncommitted changes

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
