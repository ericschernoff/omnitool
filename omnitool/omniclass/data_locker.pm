package omnitool::omniclass::data_locker;
=cut

Provides the 'lock_data', 'unlock_data,' and 'check_data_lock' methods,
which are described in the comments of omniclass.pm.  Mostly useful for
omnitool::tool::actioner::run_action() to respect data locks by other
users when a tool has is_locking='Yes'.

Locks are recorded in the datatype's metainfo table, tied to 'lock_user'
and 'lock_expire', the last one being a unix_timestamp() after which
the lock is no good; your tool should have an extend_lock method to keep
locks going.

Please see usage notes in omniclass.pm's Pod text.

=cut

$omnitool::omniclass::data_locker::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# time to grow up
use strict;

# subroutine to set a lock
sub lock_data {
	my $self = shift;

	# grab arguments
	my (%args) = @_;

	# declare our vars
	my ($data_code, $lock_user, $lock_remaining_minutes);

	# return if they failed to send a record arg
	if (!$args{data_code}) { # log error for possible use
		return 0;
	}

	# for easy access
	$data_code = $args{data_code};

	# if they sent an altcode, resolve it with our handy method within loader.
	if ($args{data_code} =~ /[a-z]/i) {
		($data_code) = $self->altcode_to_data_code($args{data_code});
		if (!$data_code) {
			return 0;
		}
	}

	# check to make sure no one else has it locked, unless we have 'force' turned on
	if (!$args{force}) {
		($lock_user,$lock_remaining_minutes) = $self->check_data_lock($data_code);
		# both of those will be empty if the $lock_user is $self->{luggage}{username}
		if ($lock_user) {
			return 0;
		}
	}

	# safe to proceed with lock.  just need duration

	# if it was not set, look in datatypes.lock_lifetime
	if (!$args{lifetime}) {
		$args{lifetime} = $self->{datatype_info}{lock_lifetime};
	}
	# still empty?  make it 10 minutes
	$args{lifetime} = 10 if !$args{lifetime};

	# finally, place the lock!
	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.'.$self->{metainfo_table}.
		' set lock_user=?, lock_expire=(unix_timestamp()+(60*?)) '.
		'where the_type=? and data_code=?',
		[$self->{luggage}{username}, $args{lifetime}, $self->{dt}, $data_code]
	);

	# success!
	return 1;
}

# i bet you can guess what this dones ;)
sub unlock_data {
	my $self = shift;

	# grab arguments
	my (%args) = @_;

	# declare our vars
	my ($data_code, $lock_user, $lock_remaining_minutes);

	# return if they failed to send a record arg
	if (!$args{data_code}) {
		return 0;
	}

	# for easy access
	$data_code = $args{data_code};


	# if they sent an altcode, resolve it with our handy method within loader.
	if ($args{data_code} =~ /[a-z]/i) {
		($data_code) = $self->altcode_to_data_code($args{data_code});
		if (!$data_code) {
			return 0;
		}
	}

	# check to make sure the lock is for this user and not someone else, unless we have 'force' turned on
	if (!$args{force}) {
		($lock_user,$lock_remaining_minutes) = $self->check_data_lock($data_code);
		# both of those will be empty if the $lock_user is $self->{luggage}{username}
		if ($lock_user) {
			return 0;
		}
	}

	# still here?  safe to un-lock
	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.'.$self->{metainfo_table}.
		" set lock_user='None', lock_expire=0 where the_type=? and data_code=?",
		[$self->{dt}, $data_code]
	);

	# success!
	return 1;
}

# method to see if data is locked by someone else
sub check_data_lock {
	my $self = shift;

	# grab single argument
	my ($data_code) = @_;
	# just wants the data_code (or altcode) of record to check
	# if the lock is under the name of $self->{luggage}{username} or 'None' then it returns clear
	# if any other lock is found, you receive the username and number of minutes remaining for the lock

	# declare our vars
	my ($lock_user, $lock_remaining_minutes, $lock_remaining_seconds);

	# return if they failed to send a record arg
	if (!$data_code) { # log error for possible use
		return 0;
	}


	# if they sent an altcode, resolve it with our handy method within loader.
	if ($data_code =~ /[a-z]/i) {
		($data_code) = $self->altcode_to_data_code($data_code);
		if (!$data_code) {
			return 0;
		}
	}

	# still here?  check the lock
	($lock_user,$lock_remaining_seconds) = $self->{db}->quick_select(
		'select lock_user, (lock_expire-unix_timestamp()) from '.$self->{database_name}.'.'.$self->{metainfo_table}.
		" where the_type=? and data_code=? and lock_user!='None' and lock_user!=? and lock_expire > unix_timestamp()",
		[$self->{dt}, $data_code, $self->{luggage}{username}]
	);

	# if no lock user, it's clear to go
	if (!$lock_user) {
		return;
	# otherwise, calculate the remaining minutes
	} else {
		# i prefer to do math in perl, not mysql
		# make it a round number of minutes, with an extra thrown in for good measure
		$lock_remaining_minutes = int( ($lock_remaining_seconds + 60)/60 );

		# send it out
		return ($lock_user, $lock_remaining_minutes);
	}

}

1;
