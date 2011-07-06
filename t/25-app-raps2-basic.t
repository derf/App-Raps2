#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 3;

use_ok('App::Raps2');

my $r2 = App::Raps2->new( dont_touch_fs => 1, no_cli => 1 );
isa_ok($r2, 'App::Raps2');

is_deeply(
	$r2->file_to_hash('t/in/hash'),
	{ key => 'value', otherkey => 'othervalue' },
	'file_to_hash works',
);
