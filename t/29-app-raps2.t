#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 4;
use Test::Fatal;

use_ok('App::Raps2');

my $r2 = App::Raps2->new();
isa_ok($r2, 'App::Raps2');

is(length($r2->create_salt()), 16, 'create_salt: correct length');

is_deeply(
	{ $r2->file_to_hash('t/in/hash') },
	{ key => 'value', otherkey => 'othervalue' },
	'file_to_hash works',
);

