package omnitool::common::password_sealer;
# Ctility class to handle password tasks, namely hashing (encoding) and validating
# passwords.  Can also update passwords for omnitool_users entries.
# Uses Crypt::PBKDF2 for the heavy lifting.

# Separating this so we don't continue to clutter up utility_belt.pm.

# sixth time doing this all wrong
$omnitool::common::password_handler::VERSION = '1.0';

# CPAN is the jewel of the modern world...
use Crypt::PBKDF2;

# time to grow up
use strict;

# constructor needs %$luggage
sub new {
	my $class = shift;

	my ($luggage) = @_;

	# Need to stop here if luggage not provided
	if (!$$luggage{belt}->{all_hail}) {
		die(qq{Can't create an OmniClass without my luggage.'});
	}

	# create myself, with the Crypt::PBKDF2 dependency
	my $self = bless {
		'luggage' => $luggage,
		'pbkdf2' => Crypt::PBKDF2->new(
			'hash_class' => 'HMACSHA3',
			'hash_args' => {
				'sha_size' => 512,
			},
			'iterations' => 50000,
			'salt_len' => 30,
		),
	}, $class;

	return $self;
}

# method to create a hash for a supplied password string
sub hash_from_password {
	my $self = shift;

	# required argument is the password
	my ($password) = @_;

	# no password = no results
	return if !$password;

	# look how incredibly difficult this is
	return $self->{pbkdf2}->generate($password);

}

# method to verify a password against a hash
sub check_a_password {
	my $self = shift;

	# required argument is the password and a previously-hashed password
	my ($password, $hashed_password) = @_;

	# returning false if either is blank
	return 0 if !$password || !$hashed_password;

	# returning false if hash is not in the right format -- may be checking an old SHA2 password
	return 0 if $hashed_password !~ /^{X-PBKDF2}/;

	# use Crypt::PBKDF2 otherwise
	return $self->{pbkdf2}->validate($hashed_password,$password);
}


# method for login_system.pm to use to validate a password for an omnitool_user
sub check_a_users_password {
	my $self = shift;

	# required argument is the supplied username + password
	my ($username, $password) = @_;

	if (!$username || !$password) {
		$self->{luggage}{belt}->mr_zebra('check_a_users_password() requires both a username and a password.',1);
		return;
	}

	### REMOVE THIS ONE DAY
	# we have to support my previous sinful ways for a while
	my ($valid_user) = $self->{luggage}{db}->quick_select(qq{
		select count(*) from omnitool_users
		where username=? and password=SHA2(?,224)
	},[$username, $password]);
	return $valid_user if $valid_user;
	### END REMOVE THIS ONE DAY

	# pull out our hash for the provided username
	my ($hashed_password) = $self->{luggage}{db}->quick_select(qq{
		select password from omnitool_users where username=?
	},[$username]);

	# use the method above to validate that, returning the result
	return $self->check_a_password($password, $hashed_password);

}

# password-changer: utility method to change/set/update a user's password in all omnitool admin DB's
# needed in multiple spots; put here because it's basically SQL
sub change_a_users_password {
	my $self = shift;

	# required argument is the username + password
	my ($username, $new_password) = @_;

	if (!$username || !$new_password) {
		$self->{luggage}{belt}->mr_zebra('change_a_users_password() requires both a username and a password.',1);
		return;
	}

	my ($omnitool_admin_databases, $otadmin_db, $hashed_password);

	# use the above method and Crypt::PBKDF2 to encode the passwor
	$hashed_password = $self->hash_from_password($new_password);

	# update the passowrd - on all omnitool databases
	$omnitool_admin_databases = $self->{luggage}{db}->list_select(qq{
		select database_name from omnitool.instances where parent='1_1:1_1' and status='Active'
	});
	foreach $otadmin_db (@$omnitool_admin_databases) {
		$self->{luggage}{db}->do_sql('update '.$otadmin_db.
			qq{.omnitool_users set password=?, require_password_change='No',
				password_set_date=curdate() where username=?
		},[$hashed_password, $username]);
	}

	# avoid endless looping in authentication screen
	$self->{luggage}{db}->do_sql(qq{
		update otstatedata.authenticated_users
		set require_password_change='No' where username=?
	},[$username]);

	# success, no need to return
}

1;

=head1 omnitool::common::password_sealer

Attempt to protect the sanctity of our stored password by using the most excellent Crypt::PBKDF2
to hash them up -- http://search.cpan.org/~arodland/Crypt-PBKDF2-0.161520/lib/Crypt/PBKDF2.pm#encoding
Thanks to Chas Owens for getting me to do this and recommending this article:
https://perlmaven.com/storing-passwords-in-a-an-easy-but-secure-way

This is used heavily by login_system.pm, and anywhere else you'd need to one-way encode passwords.

=head2 new()

Simple object constructor.  Requires a valid %$luggage as the only argument.  Sets up the object for
Crypt::PBKDF2.

	$password_sealer = omnitool::common::password_sealer->new($luggage);

=head2 hash_from_password()

Generates a hash from a password string, (hopefully) suitable for storing in the database.  Set your
fields to varchar(250).

	$new_hash = $password_sealer->hash_from_password('password_string');

=head2 check_a_password()

Checks if a password string matches a hash.  Returns 1 if it matches.

	$does_match = $password_sealer->check_a_password('password_string', $previously_generated_hash);

=head2 check_a_users_password()

Checks provided username/password against the 'omnitool_users' table for the current OmniTool Admin database,
which will be the current database of the $self->{luggage}{db} and is set based on the Application that we are
currently using.

This system will *try* to keep users' passwords synchronized across all 'omnitool_users' tables in your
OmniTool Admin databases.  You can get them out of sync by creating same-named users separately in your Admin
DB's.  If that is going ot be an issue, I recommend using email addresses as usernames.

Returns 1 if a valid user was found for the provided username/password

	$valid_user = $password_sealer->check_a_users_password('username', 'password_string');

=head2 change_a_users_password()

Sets the password for a given username in all 'omnitool_users' tables across all OmniTool Admin databases on
the MySQL server.  Does not test against any password policies; that is done in login_system.pm when the
user attempts to change their password.  If the Admin is changing via the 'Manage Users' tool, then anything goes.

	$password_sealer->change_a_users_password('username', 'new-password_string');

