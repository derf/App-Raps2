#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	build_requires => {
		'Test::Command' => 0,
		'Test::Compile' => 0,
		'Test::Fatal' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
	},
	dist_name => 'App-Raps2',
	dist_version_from => 'bin/raps2',
	license => 'unrestricted',
	requires => {
		'perl' => '5.10.0',
		'autodie' => 0,
		'Crypt::CBC' => 0,
		'Crypt::Eksblowfish' => 0,
		'Crypt::Eksblowfish::Bcrypt' => 0,
		'File::Path' => 0,
		'File::Slurp' => 0,
		'POSIX' => 0,
	},
	script_files => 'bin/',
);
$build->create_build_script();
