package VCS::Which;

# Created on: 2009-05-16 16:54:35
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

our %systems;

sub new {
	my $caller = shift;
	my $class  = ref $caller ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	bless $self, $class;

	if ( !%systems ) {
		$self->get_systems();
	}

	$self->load_systems();

	return $self;
}

sub load_systems {
	my ( $self ) = @_;

	for my $module (keys %systems) {
		$self->{systems}{$module} = $module->new;
	}

	return;
}

sub get_systems {
	my ($self) = @_;

	for my $dir (@INC) {
		my @files = glob "$dir/VCS/Which/Plugin/*.pm";

		for my $file (@files) {
			my $module = $file;
			$module =~ s{$dir/}{}xms;
			$module =~ s{/}{::}gxms;
			$module =~ s{[.]pm$}{}xms;

			next if $systems{$module};

			require $file;
			$systems{$module} = 1;
		}
	}

	return;
}

sub capabilities {
	my ($self, $dir) = @_;
	my $out;
	my %out;

	if ($dir) {
		$self->{dir} = $dir;
	}
	else {
		$dir = $self->{dir};
	}

	for my $system (values %{ $self->{systems} }) {

		$out .= $system->name . ' ' x (10 - length $system->name);
		$out .= $system->installed  ? ' installed    ' : ' not installed';
		$out{$system->name}{installed} = $system->installed;

		if ($dir) {
			eval {
				$out .= $system->used($dir) ? ' versioning' : ' not versioning';
				$out{$system->name}{installed} = $system->used($dir);
			};
			if ($EVAL_ERROR) {
				warn "$system error in determining if the directory is used: $EVAL_ERROR\n";
				$out .= ' NA';
				$out{$system->name}{installed} = ' NA';
			}
		}

		$out .= "\n";
	}

	return wantarray ? %out : $out;
}

sub which {
	my ( $self, $dir ) = @_;

	if ($dir) {
		$self->{dir} = $dir;
	}
	else {
		$dir = $self->{dir};
	}

	croak "No directory supplied!" if !$dir;

	return $self->{which}{$dir} if exists $self->{which}{$dir};

	$self->{which}{$dir} = undef;
	my %used;
	my $min;

	for my $system (values %{ $self->{systems} }) {
		my $used = eval { $system->used($dir) || 0 };
		next if $EVAL_ERROR;

		$min ||= $used if $used;

		# check that the directory is used and that it was found at a level closer to $dir that the last found system
		if ( $used && $used <= $min ) {
			$self->{which}{$dir} = $system;
			$min = $used;
		}
	}

	return $self->{which}{$dir};
}

sub uptodate {
	my ( $self, $dir ) = @_;

	if ($dir) {
		$self->{dir} = $dir;
	}
	else {
		$dir = $self->{dir};
	}

	croak "No directory supplied!" if !$dir;

	return $self->{uptodate}{$dir} if exists $self->{uptodate}{$dir};

	my $system = $self->which;

	return $self->{uptodate}{$dir} = $system->uptodate($dir);
}

1;

__END__

=head1 NAME

VCS::Which - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to VCS::Which version 0.1.


=head1 SYNOPSIS

   use VCS::Which;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: VCS::Which -

Description:

=head3 C<load_systems ()>

Description: Creates new objects for each version control system found

=head3 C<get_systems ()>

Description: Searches for version control systems plugins installed

=head3 C<capabilities ( [$dir] )>

Param: C<$dir> - string - Directory to base out put on

Return: list context - The data for each system's capabilities
        scalar context - A string displaying each system's capabilities

Description: Gets the capabilities of each system and returns the results

=head3 C<which ( $dir )>

Param: C<$dir> - string - Directory to work out which system it is using

Return: VCS::Which::Plugin - Object which can be used against the directory

Description: Determines which version control plugin can be used to with the
supplied directory.

=head3 C<uptodate ( $dir )>

Param: C<$dir> - string - Directory to base out put on

Return: bool - True if the everything is checked in for the directory

Description: Determines if there are any changes that have not been commited
to the VCS running the directory.

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
