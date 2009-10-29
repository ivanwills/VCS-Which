use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'VCS::Which',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from => 'lib/VCS/Which.pm',
	requires          => {
		perl                 => 5.008,
		'Path::Class'        => '0.16',
		'File::chdir'        => 0,
		'File::Slurp'        => 0,
		'File::Basename'     => 0,
		'File::Spec'         => 0,
		'version'            => 0,
		'Contextual::Return' => 0,
	},
	build_requires => {
		'Test::More'       => 0,
		'Test::NoWarnings' => 0,
	},
	add_to_cleanup     => [ 'VCS-Which-*' ],
	create_makefile_pl => 'traditional',
	create_license     => 1,
);

$builder->create_build_script();
