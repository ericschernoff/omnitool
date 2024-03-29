package omnitool::applications::otadmin::tools::update_api_key;
# non-privileged-user-facing tool to update API keys.  only allows them to
# specify the IP address and status (active/inactive)

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
		'title' => 'Update an API Key',
		'submit_button_text' => 'Update Key',
		'field_keys' => [1,2],
		'hidden_fields' => {
			'form_submitted' => 1,
			'action' => 'update',
			'record' => $self->{omniclass_object}{data_code},
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Tied to IP Addresses',
				'name' => 'tied_to_ip_address',
				'field_type' => 'long_text',
				'is_required' => 1,
				'preset' => $self->{omniclass_object}->{data}{tied_to_ip_address},
				'instructions' => qq{Required. IP Address(es) of client which will be accessing the API.  Separate with new lines.}
			},
			2 => {
				'title' => 'Status',
				'name' => 'status',
				'field_type' => 'active_status_select',
				'preset' => $self->{omniclass_object}->{data}{status},
			},
		}
	};

}

# pull in the field and update the priorities.  somewwhat easy
sub perform_form_action {
	my $self = shift;

	$self->{luggage}{params}{status} ||= 'Inactive'; # i kind of hate those things

	# save the new key -- the user_api_keys.pm omniclass subclass handles filling in the gaps
	$self->{omniclass_object}->save(
		'data_code' => $self->{omniclass_object}{data_code},
		'skip_blanks' => 1,
	);

	# tell our template what to to
	$self->{json_results}{form_was_submitted} = 1;
	$self->{json_results}{title} = "API Key Has Been Updated";
	$self->{json_results}{message} = "Please click 'View' next to the new key to see full details.";
	$self->{json_results}{show_gritter_notice} = 1;

}


1;

