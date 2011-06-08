#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More;

eval "use Test::MockObject";
plan skip_all => 'Test::MockObject required' if $@;

plan tests => 4;

my $mock = Test::MockObject->new();
$mock->fake_module(
	'Term::ReadLine',
	new => sub { return bless({}, $_[0]) },
);

use_ok('App::Raps2');

my $r2 = App::Raps2->new( dont_touch_fs => 1 );
isa_ok($r2, 'App::Raps2');

isa_ok($r2->ui(), 'App::Raps2::UI');

is_deeply(
	{ $r2->file_to_hash('t/in/hash') },
	{ key => 'value', otherkey => 'othervalue' },
	'file_to_hash works',
);
