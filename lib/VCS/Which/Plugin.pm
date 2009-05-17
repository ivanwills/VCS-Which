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

	no strict qw/refs/;
	return ${"$package\::name"};
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

1;

__END__

=head1 NAME

VCS::Which::Plugin - <One-line description of module's purpose>

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

=head3 C<installed ()>

Return: bool - True if the VCS is installed

Description: Determines if VCS is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this VCS

Description: Determines if the directory is under version control of this VCS

=head3 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommited changes

Description: Determines if the directory has no uncommitted changes

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to ivan (ivan@localhost).

Patches are welcome.

=head1 AUTHOR

ivan - (ivan@localhost)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 ivan (123 Timbuc Too).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
