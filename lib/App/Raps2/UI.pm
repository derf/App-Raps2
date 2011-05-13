package App::Raps2::UI;

use strict;
use warnings;
use autodie;
use 5.010;

use Carp qw(confess);
use POSIX;

our $VERSION = '0.2';

sub new {
	my ($obj) = @_;
	my $ref = {};
	return bless($ref, $obj);
}

sub list {
	my ($self, @list) = @_;
	my $format = "%-20s %-20s %s\n";

	if (not $self->{list}->{header}) {
		printf($format, map { $_->[0] } @list);
		$self->{list}->{header} = 1;
	}
	printf($format, map { $_->[1] // q{} } @list);
}

sub read_line {
	my ($self, $str) = @_;

	print "${str}: ";
	my $input = readline(STDIN);

	chomp $input;
	return $input;
}

sub read_multiline {
	my ($self, $str) = @_;
	my $in;

	say "${str} (^D to quit)";

	while (my $line = <STDIN>) {
		$in .= $line;
	}
	return $in;
}

sub read_pw {
	my ($self, $str, $verify) = @_;
	my ($in1, $in2);

	my $term = POSIX::Termios->new();
	$term->getattr(0);
	$term->setlflag($term->getlflag() & ~POSIX::ECHO);
	$term->setattr(0, POSIX::TCSANOW);

	print "${str}: ";
	$in1 = readline(STDIN);
	print "\n";

	if ($verify) {
		print 'Verify: ';
		$in2 = readline(STDIN);
		print "\n";
	}

	$term->setlflag($term->getlflag() | POSIX::ECHO);
	$term->setattr(0, POSIX::TCSANOW);

	if ($verify and $in1 ne $in2) {
		confess('Input lines did not match');
	}

	chomp $in1;
	return $in1;
}

sub to_clipboard {
	my ($self, $str) = @_;

	open(my $clipboard, '|-', 'xclip -l 1');
	print $clipboard $str;
	close($clipboard);
	return;
}

sub output {
	my ($self, @out) = @_;

	for my $pair (@out) {
		printf(
			"%-8s : %s\n",
			$pair->[0],
			$pair->[1] // q{},
		);
	}
	return;
}

1;
