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
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use Path::Class qw/file/;

our $VERSION     = version->new('0.4.3');
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

    if ( $self->{dir} && -f $self->{dir} ) {
        $self->{dir} = file($self->{dir})->parent->cleanup;
    }

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

    if ( $dir && -f $dir ) {
        $self->{dir} ||= $dir = file($dir)->parent;
    }

    confess "No directory supplied!" if !$dir;

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

    confess "Could not work out what plugin to use with '$dir'\n" if !$self->{which}{$dir};

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

    confess "No directory supplied!" if !$dir;

    return $self->{uptodate}{$dir} if exists $self->{uptodate}{$dir};

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $self->{uptodate}{$dir} = $system->uptodate($dir);
}

sub exec {
    my ( $self, @args ) = @_;

    my $dir = $self->{dir};

    confess "No directory supplied!" if !$dir;

    my $system = $self->which;

    return $system->exec($dir, @args);
}

sub log {
    my ( $self, $file, @args ) = @_;

    if ( ! -e $file ) {
        unshift @args, $file;
        undef $file;
    }

    my $dir
        = !defined $file ? $self->{dir}
        : -f $file       ? file($file)->parent
        : -d $file       ? $file
        :                  confess('No file passed and no default directory setup!');

    confess "No directory supplied! '$dir'" if !$dir;

    my $system = $self->which($dir);

    return $system->log($file, @args);
}

sub cat {
    my ( $self, $file, @args ) = @_;

    if ($file) {
        $self->{dir} = $file;
    }
    else {
        $file = $self->{dir};
    }

    confess "No file supplied!" if !$file;

    my $system = $self->which;

    return $system->cat($file, @args);
}

sub versions {
    my ( $self, $file, @args ) = @_;

    if ($file) {
        $self->{dir} = $file;
    }
    else {
        $file = $self->{dir};
    }

    confess "No file supplied!" if !$file;

    my $system = $self->which;

    return $system->versions($file, @args);
}

sub pull {
    my ( $self, $dir ) = @_;

    if ($dir) {
        $self->{dir} = $dir;
    }
    else {
        $dir = $self->{dir};
    }

    confess "No directory supplied!" if !$dir;

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $system->pull($dir);
}

sub push {
    my ( $self, $dir ) = @_;

    if ($dir) {
        $self->{dir} = $dir;
    }
    else {
        $dir = $self->{dir};
    }

    confess "No directory supplied!" if !$dir;

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $system->push($dir);
}

sub status {
    my ( $self, $dir ) = @_;

    if ($dir) {
        $self->{dir} = $dir;
    }
    else {
        $dir = $self->{dir};
    }

    confess "No directory supplied!" if !$dir;

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $system->status($dir);
}

sub checkout {
    my ( $self, $dir, @extra ) = @_;

    if ($dir) {
        $self->{dir} = $dir;
    }
    else {
        $dir = $self->{dir};
    }

    confess "No directory supplied!" if !$dir;

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $system->checkout($dir, @extra);
}

sub add {
    my ( $self, $dir, @extra ) = @_;

    if ($dir) {
        $self->{dir} = $dir;
    }
    else {
        $dir = $self->{dir};
    }

    confess "No directory supplied!" if !$dir;

    my $system = $self->which || confess "Could not work out which version control system to use!\n";

    return $system->add($dir, @extra);
}

1;

__END__

=head1 NAME

VCS::Which - Generically interface with version control systems

=head1 VERSION

This documentation refers to VCS::Which version 0.4.3.


=head1 SYNOPSIS

   use VCS::Which;

   # create a new object
   my $vcs = VCS::Which->new();

   if ( !$vcs->uptodate('.') ) {
       warn "Directory has uncommitted changes\n";
   }

=head1 DESCRIPTION

This module provides methods to interface with a version control system
(vcs) with out having to care which command to use or which sub command in
needed for several basic operations like checking if there are any
uncommitted changes.

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: C<dir> - string - (optional) a directory that will be used for
determining the used version control system. It is used for other methods
that require a directory and one is not supplied.

Return: VCS::Which - A new object.

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

=head3 C<which ( [$dir] )>

Param: C<$dir> - string - Directory to work out which system it is using

Return: VCS::Which::Plugin - Object which can be used against the directory

Description: Determines which version control plugin can be used to with the
supplied directory.

=head3 C<uptodate ( $dir )>

Param: C<$dir> - string - Directory to base out put on

Return: bool - True if the everything is checked in for the directory

Description: Determines if there are any changes that have not been committed
to the VCS running the directory.

=head3 C<exec ( @args )>

Param: C<@args> - array - Arguments to pass on to the appropriate vcs command

Description: Runs the appropriate vcs command with the parameters supplied

=head3 C<cat ( $file[, $revision] )>

Param: C<$file> - string - The name of the file to cat

Param: C<$revision> - string - The revision to get. If the revision is negative
it refers to the number of revisions old is desired. Any other value is
assumed to be a version control specific revision. If no revision is specified
the most recent revision is returned.

Return: The file contents of the desired revision

Description: Gets the contents of a specific revision of a file.

=head3 C<log ( [$file], [@args] )>

Param: C<$file> - string - The name of the file or directory to get the log of

Param: C<@args> - strings - Any other arguments to pass to the log command

Return: The log out put

Description: Gets the log of changes (optionally limited to a file)

=head3 C<versions ( [$file], [@args] )>

Description: Gets all the versions of $file

=head3 C<pull ( [$dir] )>

Description: Pulls or updates the directory $dir to the newest version

=head3 C<push ( [$dir] )>

Description: Pushes content to master repository for distributed VCS systems

=head3 C<status ( [$dir] )>

Return: HASHREF - Status of files

Description: Get the statuses of all files not added or not committed in the
repository.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

The initial template usually just has:

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
