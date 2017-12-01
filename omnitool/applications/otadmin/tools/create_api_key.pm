package omnitool::applications::otadmin::tools::create_api_key;
# non-privileged-user-facing tool to create API keys.  only allows them to
# specify the IP address; everything else is filled-in for them

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# prepare the form to allow them to name the user and select the target instance
sub generate_form {
	my $self = shift;

	my ($app_instances, $app, $hostname, $inst);

	$self->{json_results}{form} = {
		'title' => 'Create an API Key',
		'submit_button_text' => 'Create Key',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Tied to IP Address',
				'name' => 'tied_to_ip_address',
				'field_type' => 'short_text',
				'is_required' => 1,
				'instructions' => qq{Required. IP Address of client which will be accessing the API.}
			},
		}
	};

}

# IP has to be valid (contain a number)
sub post_validate_form {
	my $self = shift;

	if ($self->{luggage}{params}{tied_to_ip_address} !~ /\d/) {
		# stop the form submission in its tracks
		$self->{stop_form_action} = 1;

		# specify a field error
		$self->{json_results}{form}{fields}{1}{field_error} = 1;
		$self->{json_results}{form}{fields}{1}{error_instructions} = 'Please provide a valid IP address';
	}

}

# pull in the field and update the priorities.  somewwhat easy
sub perform_form_action {
	my $self = shift;

	# can only be for them
	$self->{luggage}{params}{username} = $self->{luggage}{username};

	# and is active
	$self->{luggage}{params}{status} = 'Active';

	# save the new key -- the user_api_keys.pm omniclass subclass handles filling in the gaps
	$self->{omniclass_object}->save(
		'parent' => 'top',
	);

	# tell our template what to to
	$self->{json_results}{form_was_submitted} = 1;
	$self->{json_results}{title} = "New API Key Created";
	$self->{json_results}{message} = "Please click 'View' next to the new key to see full details.";
	$self->{json_results}{show_gritter_notice} = 1;

}


1;

