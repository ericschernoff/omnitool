package omnitool::applications::otadmin::datatypes::omnitool_users;

# is a sub-class of OmniClass
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::otadmin::datatypes::omnitool_users::dt = '9_1';

# for updating the user's password throughout the system
use omnitool::common::password_sealer;

# for being a better person
use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to generate a list of Access Roles/Instance combos to allow us to hard-set user membership
sub options_hard_set_access_roles {
	my $self = shift;
	my ($data_code) = @_; # primary key for recording updating, if applicable

	my ($access_roles_omniclass, $instances_omniclass, $role, $instance, $app, $options, $options_keys);

	# first, load up all the access roles in this OT Admin DB
	$access_roles_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '12_1',
		'skip_hooks' => 1,
		'skip_metainfo' => 1,
		'load_fields' => 'name,used_in_applications',
		'data_codes' => ['all']
	);

	# second, get the list of instances
	$instances_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'skip_hooks' => 1,
		'load_fields' => 'name',
		'data_codes' => ['all']
	);

	# now we load them in, listed for each available instance of the associated applications
	# i *really* hate having three nested foreach's here, but there should not be many of each of these

	# we cycle through all the access roles
	foreach $role (@{ $access_roles_omniclass->{records_keys} }) {
		# and then down into the app's named in 'used in applications'
		foreach $app (split /,/, $access_roles_omniclass->{records}{$role}{used_in_applications}) {
			# and then for all instances
			foreach $instance (@{ $instances_omniclass->{records_keys} }) {
				# skip if this instance is not for the desired application
				next if $instances_omniclass->{metainfo}{$instance}{parent} ne '1_1:'.$app;
				# finally, add in the option
				$$options{$instance.'::'.$role} = $access_roles_omniclass->{records}{$role}{name}." for '".$instances_omniclass->{records}{$instance}{name}."'";
			}
		}
	}

	# now prepare the keys, sorted by the option names
	@$options_keys = sort { $$options{$a} cmp $$options{$b} } keys %$options;

	# return results
	return ($options,$options_keys);
}

# default 'password-set-date' to today
sub post_form_operations {
	my $self = shift;
	my ($form) = @_; # the complete form structure

	my ($field);
	foreach $field (@{$$form{field_keys}}) {
		next if $$form{fields}{$field}{name} ne 'password_set_date' || $$form{fields}{$field}{preset};
		# default to today
		$$form{fields}{$field}{preset} = $self->{belt}->todays_date();
		last;
	}

}

# WE NEED TO KEEP ALL THE PASSWORDS FOR THIS USER IN SYNC ACROSS ALL OMNITOOL ADMIN DATABASES

# so grab the plaintext password before it gets encryped so change_a_users_password() works in post_save()
sub pre_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

	$self->{luggage}{params}{new_password} = $self->{luggage}{params}{password};

}
# now use the db->change_a_users_password() to update across the system, provided these values were sent
sub post_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

	# only if the username/password values were provided
	if ($self->{luggage}{params}{username} && $self->{luggage}{params}{new_password}) {
		# use our Crypt::PBKDF2 library to strongly encode this password and store it everywhere
		my $password_sealer = omnitool::common::password_sealer->new( $self->{luggage} );
		$password_sealer->change_a_users_password( $self->{luggage}{params}{username}, $self->{luggage}{params}{new_password} );
	}

}


1;

