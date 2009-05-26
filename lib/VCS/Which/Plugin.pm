package VCS::Which::Plugin;

# Created on: 2009-05-16 17:50:07
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use CGI;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

sub new {
	my $caller = shift;
	my $class  = ref $caller ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	bless $self, $class;

	return $self;
}

sub name {
	my ($self) = @_;
	my $package = ref $self ? ref $self : $self;

	no strict qw/refs/;          ## no critic
	return ${"$package\::name"};
}

sub exe {
	my ($self) = @_;
	my $package = ref $self ? ref $self : $self;

	no strict qw/refs/;          ## no critic
	return ${"$package\::exe"};
}

sub installed {
	my ($self) = @_;

	return die $self->name . ' does not currently implement installed!';
}

sub used {
	my ($self) = @_;

	return die $self->name . ' does not currently implement used!';
}

sub uptodate {
	my ($self) = @_;

	return die $self->name . ' does not currently implement uptodate!';
}

sub exec {
	my ($self, $dir, @args) = @_;

	die $self->name . " not installed\n" if !$self->installed();

	my $cmd = $self->exe;

	return CORE::exec( $cmd, @args );
}

1;

__END__

=head1 NAME

VCS::Which::Plugin - Base class for the various VCS plugins

=head1 VERSION

This documentation refers to VCS::Which::Plugin version 0.1.


=head1 SYNOPSIS

   use VCS::Which::Plugin;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: VCS::Which::Plugin -

Description:

=head3 C<name ()>

Return: string - The pretty name for the System

Description: Returns the pretty name for the VCS

=head3 C<exe ()>

Return: string - The name of the executable that is used to run operations
with the appropriate plugin

Description: Returns name of the executable for the appropriate version
control system.

=head3 C<installed ()>

Return: bool - True if the VCS is installed

Description: Determines if VCS is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this VCS

Description: Determines if the directory is under version control of this VCS

=head3 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommitted changes

Description: Determines if the directory has no uncommitted changes

=head3 C<exec (@params)>

Param: C<@params> - array of strings - The parameters that you wish to pass
on to the vcs program.

Description: Runs a command for the appropriate vcs.

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
