package App::Raps2::Password;




use strict;
use warnings;
use autodie;
use 5.010;

use base 'Exporter';

use Crypt::CBC;
use Crypt::Eksblowfish;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64 de_base64);

our @EXPORT_OK = ();
our $VERSION = '0.1';

sub new {
	my ($obj, %conf) = @_;

	$conf{'cost'} //= 12;

	if (not (defined $conf{'salt'} and length($conf{'salt'}) == 16)) {
		return undef;
	}

	if (not (defined $conf{'passphrase'} and length $conf{'passphrase'})) {
		return undef;
	}

	my $ref = \%conf;

	return bless($ref, $obj);
}

sub salt {
	my ($self, $salt) = @_;

	if (not (defined $salt and length($salt) == 16)) {
		return undef;
	}

	$self->{'salt'} = $salt;
}

sub encrypt {
	my ($self, $in) = @_;

	my $eksblowfish = Crypt::Eksblowfish->new(
		$self->{'cost'},
		$self->{'salt'},
		$self->{'passphrase'},
	);
	my $cbc = Crypt::CBC->new(-cipher => $eksblowfish);

	return $cbc->encrypt_hex($in);
}

sub decrypt {
	my ($self, $in) = @_;

	my $eksblowfish = Crypt::Eksblowfish->new(
		$self->{'cost'},
		$self->{'salt'},
		$self->{'passphrase'},
	);
	my $cbc = Crypt::CBC->new(-cipher => $eksblowfish);

	return $cbc->decrypt_hex($in);
}

sub crypt {
	my ($self) = @_;

	return en_base64(
		bcrypt_hash({
				key_nul => 1,
				cost => $self->{'cost'},
				salt => $self->{'salt'},
			},
			$self->{'passphrase'},
	));
}

sub verify {
	my ($self, $testhash) = @_;

	my $myhash = $self->crypt();

	if ($testhash eq $myhash) {
		return 1;
	}
	return undef;
}

1;
