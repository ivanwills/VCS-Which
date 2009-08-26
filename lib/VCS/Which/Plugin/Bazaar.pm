package VCS::Which::Plugin::Bazaar;

# Created on: 2009-05-16 16:58:36
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

our $VERSION = version->new('0.0.2');
our $name    = 'Bazaar';
our $exe     = 'bzr';

sub installed {
	my ($self) = @_;

	return $self->{installed} if exists $self->{installed};

	for my $path (split /[:;]/, $ENV{PATH}) {
		next if !-x "$path/bzr";

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
		if ( -d "$current_dir/.bzr" ) {
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

	croak "'$dir' is not a directory!" if !-e $dir;

	local $CWD = $dir;
	my $ans = `bzr status $dir`;

	return $ans ? 1 : 0;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Bazaar - The Bazaar plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Bazaar version 0.0.2.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Bazaar;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This is the plugin for the Bazaar version control system.

=head1 SUBROUTINES/METHODS

=head2 C<name ()>

Return: string - The pretty name for the System

Description: Returns the pretty name for the Bazaar

=head2 C<installed ()>

Return: bool - True if the Bazaar is installed

Description: Determines if Bazaar is actually installed and usable

=head2 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Bazaar

Description: Determines if the directory is under version control of this Bazaar

=head2 C<uptodate ($dir)>

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
