#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 13;

my $pw;
my $salt = 'abcdefghijklmnop';
my $pass = 'something';

use_ok('App::Raps2::Password');

$pw = App::Raps2::Password->new();
is($pw, undef, 'new() missing salt and passphrase');

$pw = App::Raps2::Password->new(salt => $salt);
is($pw, undef, 'new() missing passphrase');

$pw = App::Raps2::Password->new(passphrase => $pass);
is($pw, undef, 'new() missing salt');

$pw = App::Raps2::Password->new(
	passphrase => $pass,
	salt => 'abcdefghijklmno',
);
is($pw, undef, 'new() salt one too short');

$pw = App::Raps2::Password->new(
	passphrase => $pass,
	salt => $salt . 'z',
);
is($pw, undef, 'new() salt one too long');

$pw = App::Raps2::Password->new(
	passphrase => $pass,
	salt => $salt,
);
isa_ok($pw, 'App::Raps2::Password');

$pw = App::Raps2::Password->new(
	cost => 8,
	salt => $salt,
	passphrase => $pass,
);

isa_ok($pw, 'App::Raps2::Password');

is($pw->decrypt('53616c7465645f5f80d8c367e15980d43ec9a6eabc5390b4'), 'quux',
	'decrypt okay');

is($pw->decrypt($pw->encrypt('foo')), 'foo', 'encrypt->decrypt okay');

ok($pw->verify('3lJRlaRuOGWv/z3g1DAOlcH.u9vS8Wm'), 'verify: verifies correct hash');

ok(!$pw->verify('3lJRlaRuOGWv/z3g1DAOlcH.u9vS8WM'), 'verify: does not verify invalid hash');

ok($pw->verify($pw->crypt('truth')), 'crypt->verify okay')
