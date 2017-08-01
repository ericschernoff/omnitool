package omnitool::applications::otadmin::tools::manage_api_keys;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# this routine ensures that only OT admins can see all users' keys
sub pre_search_execute {
	my $self = shift;

	# if they are not an OT Admin, only show their keys
	if (!$self->{luggage}{session}{access_roles}{'1_1'}) {
		push(@{$self->{searches}},{
			'operator' => '=',
			'match_column' => 'username',
			'match_value' => $self->{luggage}{username}
		});
	}

}

# add a link to the example perl script to the description to be displayed above this tool
sub pre_tool_controls {
	my $self = shift;

	my $download_uri = '/tools/user_api_keys/example_scripts?uri_base='.$self->{luggage}{params}{uri_base}.'&client_connection_id='.$self->{client_connection_id};
	my $download_uri_python = '/tools/user_api_keys/example_scripts?which=python&uri_base='.$self->{luggage}{params}{uri_base}.'&client_connection_id='.$self->{client_connection_id};

	$self->{attributes}{description} .= qq{
		<br/>
		Please download <a href="$download_uri" target="_new">this example Perl script/package</a> or
		<a href="$download_uri_python" target="_new">this example Python script/class</a>
		for more details on how to use this API.
	};
}

# method to send them an example API client scripts
sub example_scripts {
	my $self = shift;

	# which script (language) do they want?
	my ($the_file);
	if ($self->{luggage}{params}{which} eq 'python') {
		$the_file = 'python_api_example_client.py';
	} else { # default is Perl 5
		$the_file = 'sample_api_client.pl';
	}

	# not a template yet, but we will process it that way for future reference
	$self->{belt}->template_process(
		'template_file' => $the_file,
		'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/subclass_templates/',
		'template_vars' => $self,
		'send_out' => 1
	);
}

1;

__END__

Possible / example routines are below.  Please copy and paste them above the '1;' above
to make use of them.  See Pod documentation at the end of tool.pm to see usage suggestions.

Also, please be sure to save this file as $OTHOME/code/omnitool/applications/otadmin/tools/manage_api_keys.pm

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

	# you will want to modify the search criteria in $self->{searches}, which is an array of hashes
	# built via omnitool::tool::searcher::build_search(). That method also adds 'which_search'
	# to 'tool_filter_menus' so you can tie the search-criteria-hash to the filter menu, since you
	# are probably here to make a filter menu work more dynamically (i.e. test different columns based on
	# menu selection).
	# Example:
	# my $search_array_entry = $self->{tool_configs}{tool_filter_menus}{'some_key'}{which_search};
	# my $search_criteria = $self->{searches}[$search_array_entry];
	# if ($$search_criteria{match_value} eq 'my_orders') {
	# 	$$search_criteria{operator} = '=';
	# 	$$search_criteria{match_column} = 'client_username';
	# }

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
