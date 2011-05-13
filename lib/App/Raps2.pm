package App::Raps2;

=head1 NAME

App::Raps2 - A Password safe

=head1 SYNOPSIS

    use App::Raps2;

    my $raps2 = App::Raps2->new();
    my ($action, @args) = @ARGV;

    $raps2->sanity_check();
    $raps2->load_config();

    given ($action) {
        when ('add')  { $raps2->cmd_add(@args) }
        when ('dump') { $raps2->cmd_dump(@args) }
        when ('get')  { $raps2->cmd_get(@args) }
        when ('info') { $raps2->cmd_info(@args) }
    }

=head1 DESCRIPTION

B<App::Raps2> is the backend for B<raps2>, a simple commandline password safe.

=cut

use strict;
use warnings;
use autodie;
use 5.010;

use App::Raps2::Password;
use App::Raps2::UI;
use Carp qw(confess);
use File::BaseDir qw(config_home data_home);
use File::Path qw(make_path);
use File::Slurp qw(read_dir slurp write_file);

our $VERSION = '0.1';

=head1 METHODS

=over

=item $raps2 = App::Raps2->new(%conf)

Returns a new B<App::Raps2> object.

Accepted configuration parameters are:

=over

=item B<cost> => I<int>

B<cost> of key setup, passed on to App::Raps2::Password(3pm).

=back

=cut

sub new {
	my ($obj, %conf) = @_;
	my $ref = {};

	$ref->{'xdg_conf'} = config_home('raps2');
	$ref->{'xdg_data'} = data_home('raps2');

	$ref->{'ui'} = App::Raps2::UI->new();

	$ref->{'default'} = \%conf;

	return bless($ref, $obj);
}

=item $raps2->create_salt()

Returns a 16-character random salt for App::Raps2::Password(3pm).

=cut

sub create_salt {
	my ($self) = @_;
	my $salt = q{};

	for (1 .. 16) {
		$salt .= chr(0x21 + int(rand(90)));
	}

	return $salt;
}

=item $raps2->file_to_hash($file)

Reads $file (lines with key/value separated by whitespace) and returns a hash
with its key/value pairs.

=cut

sub file_to_hash {
	my ($self, $file) = @_;
	my %ret;

	for my $line (slurp($file)) {
		my ($key, $value) = split(qr{\s+}, $line);

		if (not ($key and $value)) {
			next;
		}

		$ret{$key} = $value;
	}
	return %ret;
}

=item $raps2->sanity_check()

Create working directories (~/.config/raps2 and ~/.local/share/raps2, or the
respective XDG environment variable contents), if they don't exist yet.

Calls B<create_config> if no raps2 config was found.

=cut

sub sanity_check {
	my ($self) = @_;

	make_path($self->{'xdg_conf'});
	make_path($self->{'xdg_data'});

	if (not -e $self->{'xdg_conf'} . '/password') {
		$self->create_config();
	}

	return;
}

=item $raps2->get_master_password()

Asks the user for the master passphrase.

=cut

sub get_master_password {
	my ($self) = @_;
	my $pass = $self->ui()->read_pw('Master Password', 0);

	$self->{'pass'} = App::Raps2::Password->new(
		cost => $self->{'default'}->{'cost'},
		salt => $self->{'master_salt'},
		passphrase => $pass,
	);

	$self->{'pass'}->verify($self->{'master_hash'});
}

=item $raps2->create_config()

Creates a default config and asks the user to set a master password.

=cut

sub create_config {
	my ($self) = @_;
	my $cost = 12;
	my $salt = $self->create_salt();
	my $pass = $self->ui()->read_pw('Master Password', 1);

	$self->{'pass'} = App::Raps2::Password->new(
		cost => $cost,
		salt => $salt,
		passphrase => $pass,
	);
	my $hash = $self->{'pass'}->crypt();

	write_file(
		$self->{'xdg_conf'} . '/password',
		"cost ${cost}\n",
		"salt ${salt}\n",
		"hash ${hash}\n",
	);
}

=item $raps2->load_config()

Load config

=cut

sub load_config {
	my ($self) = @_;
	my %cfg = $self->file_to_hash($self->{'xdg_conf'} . '/password');
	$self->{'master_hash'} = $cfg{'hash'};
	$self->{'master_salt'} = $cfg{'salt'};
	$self->{'default'}->{'cost'} //= $cfg{'cost'};
}

=item $raps2->ui()

Returns the App::Raps2::UI(3pm) object.

=cut

sub ui {
	my ($self) = @_;
	return $self->{'ui'};
}

=item $raps2->cmd_add($name)

Adds a new password file called $name.

=cut

sub cmd_add {
	my ($self, $name) = @_;
	my $pwfile = $self->{'xdg_data'} . "/${name}";

	if (-e $pwfile) {
		confess('Password file already exists');
	}

	$self->get_master_password();

	my $salt = $self->create_salt();
	my $url = $self->ui()->read_line('URL');
	my $login = $self->ui()->read_line('Login');
	my $pass = $self->ui()->read_pw('Password', 1);
	my $extra = $self->ui()->read_multiline('Additional content');

	$self->{'pass'}->salt($salt);
	my $pass_hash = $self->{'pass'}->encrypt($pass);
	my $extra_hash = (
		$extra ?
		$self->{'pass'}->encrypt($extra) :
		q{}
	);


	write_file(
		$pwfile,
		"url ${url}\n",
		"login ${login}\n",
		"salt ${salt}\n",
		"hash ${pass_hash}\n",
		"extra ${extra_hash}\n",
	);
}

=item $raps2->cmd_dump($name)

Dumps the content of $name.

=cut

sub cmd_dump {
	my ($self, $name) = @_;
	my $pwfile = $self->{'xdg_data'} . "/${name}";

	if (not -e $pwfile) {
		confess('Password file does not exist');
	}

	my %key = $self->file_to_hash($pwfile);

	$self->get_master_password();

	$self->{'pass'}->salt($key{'salt'});

	$self->ui()->output(
		['URL', $key{'url'}],
		['Login', $key{'login'}],
		['Password', $self->{'pass'}->decrypt($key{'hash'})],
	);
	if ($key{'extra'}) {
		print $self->{'pass'}->decrypt($key{'extra'});
	}
}

=item $raps2->cmd_get($name)

Puts the password saved in $name into the X clipboard.

=cut

sub cmd_get {
	my ($self, $name) = @_;
	my $pwfile = $self->{'xdg_data'} . "/${name}";

	if (not -e $pwfile) {
		confess('Password file does not exist');
	}

	my %key = $self->file_to_hash($pwfile);

	$self->get_master_password();

	$self->{'pass'}->salt($key{'salt'});

	$self->ui()->to_clipboard($self->{'pass'}->decrypt($key{'hash'}));

	if ($key{'extra'}) {
		print $self->{'pass'}->decrypt($key{'extra'})
	}
}

=item $raps2->cmd_info($name)

Prints unencrypted information about $name.

=cut

sub cmd_info {
	my ($self, $name) = @_;
	my $pwfile = $self->{'xdg_data'} . "/${name}";

	if (not -e $pwfile) {
		confess('Password file does not exist');
	}

	my %key = $self->file_to_hash($pwfile);
	$self->ui()->output(
		['URL', $key{'url'}],
		['Login', $key{'login'}],
	);
}

=item $raps2->cmd_list()

Lists all saved passwords and their logins and urls

=cut

sub cmd_list {
	my ($self) = @_;

	for my $file (read_dir($self->{xdg_data})) {
		my %key = $self->file_to_hash($self->{xdg_data} . "/${file}");
		$self->ui->list(
			['Account', $file],
			['Login', $key{login}],
			['URL', $key{url}],
		);
	}
}

=head1 DEPENDENCIES

L<App::Raps2::Password>, L<App::Raps2::UI>, L<File::BaseDir>, L<File::Slurp>.

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
