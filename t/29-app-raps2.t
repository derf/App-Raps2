#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 2;

use_ok('App::Raps2');

my $r2 = App::Raps2->new();
isa_ok($r2, 'App::Raps2');
