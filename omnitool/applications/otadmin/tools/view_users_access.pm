package omnitool::applications::otadmin::tools::view_users_access;
# show a particular user's access profile for a single instance

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to perform the action specified by the form from generate_form (goes hand-in-hand with that method)
sub perform_form_action {
	my $self = shift;

	# cancel if no target_username provided (validation should handle this)
	return if !$self->{luggage}{params}{target_username};

	my ($app_instances, $instances_omniclass, $access_roles_omniclass_object, $match_text, $right_db_obj, $role, $target_application, $target_instance, $target_username, $target_users_session);

	# sanity
	$target_username = $self->{luggage}{params}{target_username};
	$target_instance = $self->{luggage}{params}{target_instance};

	# grab a session for this user
	$target_users_session = $self->grab_instance_session($target_instance, $target_username);
	$target_application = $target_users_session->{all_app_instance_info}{$target_instance}{application_id};

	# load the access roles for the target instance's parent application
	$access_roles_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '12_1',
		'skip_hooks' => 1,
		'load_fields' => 'name,used_in_applications',
		'data_codes' => ['all'],
		'sort_column' => 'name',
	);
	
	# grab the app / instance combos for this omnitool admin db
	$app_instances = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'data_codes' => [$target_instance],
		'load_fields' => 'name',
	);	

	# finally ready to gather up their roles
	foreach $role (@{ $access_roles_omniclass_object->{records_keys} }) {
		# skip role if it is not used in this instance's application
		next if !( $self->{belt}->really_in_list($target_application, $access_roles_omniclass_object->{records}{$role}{used_in_applications}) );

		# skip if they are not a member of this access role
		next if !$target_users_session->{access_roles}{$role};

		# indicate if they are a member becase of hard set access
		if ($self->{belt}->really_in_list($target_instance.'::'.$role , $target_users_session->{hard_set_access_roles})) {
			$match_text = 'Hard-set membership';

		# or if they matched logic
		} else {
			$match_text = 'Matched logic';

		}

		# now add it to our results
		push(@{$self->{json_results}{access_roles}},{
			'name' =>  $access_roles_omniclass_object->{records}{$role}{name},
			'match_text' => $match_text,
		});

	}

	# also, indicate if they have access at all
	if ($target_users_session->{no_access}) {
		$self->{json_results}{no_access} = 'User has no access to this Instance.';
	} elsif (!$target_users_session->{tools_keys}[0]) {
		$self->{json_results}{no_access} = 'User has no access to any Tools in this Instance.';
	} elsif (!$self->{json_results}{access_roles}[0]{name}) {
		$self->{json_results}{no_access} = 'User does not hold any Access Roles for this Instance.';
	}

	# send the instance name too
	$self->{json_results}{instance_name} = $app_instances->{data}{name};
	$self->{json_results}{username} = $target_username;

	# make sure form displays again
	$self->{redisplay_form} = 1;

}

# prepare the form to allow them to name the user and select the target instance
sub generate_form {
	my $self = shift;
	my ($app, $inst, $app_instances);
	$self->{json_results}{form} = {
		'title' => 'View Access Roles for a User',
		'submit_button_text' => 'View Access Roles',
		'field_keys' => [1,2],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Username for Target User',
				'name' => 'target_username',
				'field_type' => 'short_text',
				'is_required' => 1,
				'preset' => $self->{luggage}{params}{target_username},
			},
			2 => {
				'title' => 'Target Instance',
				'name' => 'target_instance',
				'field_type' => 'single_select_plain',
				'preset' => $self->{luggage}{params}{target_instance},
			},
		}
	};

	# grab the app / instance combos for this omnitool admin db
	$app_instances = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'data_codes' => ['all'],
		'load_fields' => 'name',
		'tree_mode' => 1,
		'tree_datatypes' => '5_1',
		'return_extracted_data' => 1,
	);

	# now read them in from this plain hash
	foreach $app (@{ $$app_instances{records_keys} }) {

		foreach $inst (@{ $$app_instances{records}{$app}{instances}{records_keys} }) {
			$self->{json_results}{form}{fields}{2}{options}{$inst} = $$app_instances{records}{$app}{name}.' / '.$$app_instances{records}{$app}{instances}{records}{$inst}{name};
			push(@{ $self->{json_results}{form}{fields}{2}{options_keys} }, $inst);
		}

	}

}

# subroutine to grab the user's session in the target instance; useful in both methods above
sub grab_instance_session {
	my $self = shift;

	# looking for primary key of instance & username for user
	my ($target_instance, $target_username) = @_;

	my ($right_db_obj, $instances_omniclass, $target_users_session);

	# need database hostname
	$instances_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'skip_hooks' => 1,
		'load_fields' => 'hostname',
		'data_codes' => [$target_instance]
	);

	# get the proper DB object for this instance
	$right_db_obj = $self->{belt}->get_instance_db_object($target_instance, $self->{db}, $self->{luggage}{database_name});

	# grab a session for the desired user to figure out their access roles
	$target_users_session = omnitool::common::session->new(
		'username' => $target_username,
		'db' => $right_db_obj,
		'hostname' => $instances_omniclass->{data}{hostname},
		'belt' => $self->{belt},
	);

	# ship it out
	return $target_users_session;
}

1;

__END__

Possible / example routines are below.  Please copy and paste them above the '1;' above
to make use of them.  See Pod documentation at the end of tool.pm to see usage suggestions.

Also, please be sure to save this file as $OTHOME/code/omnitool/applications/otadmin/tools/view_users_access.pm

### GENERAL ROUTINES ###

# special routine to build breadcrumbs links, which can appear above the tool controls area.
# really only needed for tools that refer to themselves, like Manage Tools under OT Admin
sub special_breadcrumbs {
	my $self = shift;
	my ($altcode) = @_; # altcode of current data point; pass as arg in case this is a recursive routine

=cut
	Fills $self->{bc_store}{breadcrumbs} as an array of hashes with three keys:
	unshift(@{$self->{bc_store}{breadcrumbs}},{
		'tool_name' => 'Name to Appear for Link',
		'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$tool_datacode}{uri_path_base}.'/'.$data_id_altcode,
		'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_datacode}{icon_fa_glyph},
	});
=cut

}

# special routine to grab an omniclass argument; only use if you have a very strong reason
# to avoid object_factory.pm; use this rarely please ;)
sub special_omniclass_object {
	my $self = shift;
	my (%args) = @_; # could be any args you'd pass to object_factory()
				  # see where center_stage.pm calls $self->get_omniclass_object()

	# return an omniclass object, to mimic behavior of object_factory
	return $omniclass_object;
}

# routine to do extra preparation before processing the Jemplate template
sub pre_prep_jemplate {
	my $self = shift;

	# main reason is to add elements to $self
}

# routine to modify the Jemplate text before sending to the client
sub pre_send_jemplate {
	my $self = shift;
	my ($jemplate_text) = @_; # what we have so far

	# return modified results
	return $jemplate_text;
}

### SEARCH TOOL ROUTINES ###

# routine run in searcher.pm before the build_search() routine
# modifies items in $self in place, likely $self->{tool_configs}{tool_filter_menus}
sub pre_search_build {
	my $self = shift;

}

# routine run in searcher.pm right before the search is executed via Omniclass's search() method
sub pre_search_execute {
	my $self = shift;

}

# routine run in searcher.pm right after the search is executed.
# good for modifying $self->{omniclass_object}->{records}; especially the inline_actions
sub post_search_execute {
	my $self = shift;

}

### ACTION TOOL ROUTINES ###

# routine for performing complex actions and adding information to $self->{json_results}
# you can cheat and use it to prepare messages
sub perform_action {
	my $self = shift;

	# if you are using it to prepare a message; be sure to choose 'Action - Message Display'
	# for Tool Type
	$self->{json_results}{title} = 'MESSAGE TITLE HERE';
	$self->{json_results}{message} = 'MESSAGE TEXT HERE';

}

# routine to perform quicker/simpler actions and prepare notification messsages
sub prepare_message {
	my $self = shift;

	$self->{json_results}{title} = 'MESSAGE TITLE HERE';
	$self->{json_results}{message} = 'MESSAGE TEXT HERE';

}

# routine to prepare a form data structure and load it into $self->{json_results}
sub generate_form {
	my $self = shift;

=cut

	# example one-field form

	$self->{json_results}{form} = {
		'title' => 'Mood Self-Evaluation',
		'instructions' => 'Please answer honestly',
		'submit_button_text' => 'Send My Answer',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'How Are You Doing?',
				'name' => 'your_mood',
				'field_type' => 'single_select',
				'options' => {
					'Great' => 'I feel great',
					'Good' => ' I feel good',
					'So-so' => 'I feel so-so',
					'Not Good' => 'I don\'t feel good',
				},
				'options_keys' => ['Great','Good','So-so','Not Good']
			},
		}
	};
=cut

}

# routine to add to the standard form validation routines
sub post_validate_form {
	my $self = shift;

	# stop the form submission in its tracks
	$self->{stop_form_action} = 1;

	# or to allow it through
	$self->{stop_form_action} = '';

	# don't modify that unless you want to override what validate_form() decided in action_tool.pm
}

# routine to perform the action specified by the form from generate_form (goes hand-in-hand with that method)
sub perform_form_action {
	my $self = shift;

	# send this upon successful submit
	$self->{json_results}{form_was_submitted} = 1;

	# if you want to convert to a pop-up notice
	$self->{json_results}{title} = 'Records Have Been Re-Ordered';
	$self->{json_results}{message} = $n.' '.$self->{this_omniclass_object}{datatype_info}{name}.' records re-ordered under '.$self->{omniclass_object}{data}{name};
	$self->{json_results}{show_gritter_notice} = 1;

	# otherwise, fill in some values in $self->{json_results} for your Jemplate
}

