package omnitool::tool::standard_data_actions;
# Acts as a tool.pm sub-class, providing the standard create and update functions for Action Tools.
# This means providing a generate_form() method to build the form hash from omniclass->form()
# and the perform_form_action() to create or save save the new record under our parent tool's
# current data-record.
#
# Most tool.pm sub-classes will live within an Application's Perl Modules directory, but this
# is a core feature of OmniTool and will available as a tool.pm class for any Application/Tool.
#
# When using this for your tools, make the 'uri_path_base' the value for $args{action}
# for omniclass->form(), so one of 'create', 'update', 'create_from'

$omnitool::tool::standard_data_actions::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# method to set up form structure in $self->{json_results}{form} from omniclass->form()
sub generate_form {
	my $self = shift;

	my ($action_arg, $send_data_code, $need_new_parent, $parent_tool_datacode, $parent_tool_datatype, $new_parent_string, $tool_datacode);

	# we need to set some variables based on our uri / argument

	# are we are updating?
	if ($self->{attributes}{uri_path_base} =~ /\/update$/) {
		$action_arg = 'update';
		$send_data_code = $self->{omniclass_object}->{data_code};
		$need_new_parent = 0;

	# maybe create-from-another?
	} elsif ($self->{attributes}{uri_path_base} =~ /\/create_from$/) {
		$action_arg = 'create';
		$send_data_code = $self->{omniclass_object}->{data_code};
		$need_new_parent = 0;

	# definitely create
	} else {
		$action_arg = 'create';
		$send_data_code = '';
		$need_new_parent = 1;

	}

	# if we are creating/creating-from, we we need the identity of the new parent
	if ($need_new_parent) {

		# re-usable subroutine from action_tool.pm:
		$new_parent_string = $self->figure_new_parent($action_arg);

	}

	# this is very simple because of all the defaults in the form() method,
	# we just have to provide it with the target record data_code and the 'update' action
	$self->{json_results}{form} = $self->{omniclass_object}->form(
		'data_code' => $send_data_code,
		'action' => $action_arg,
		'new_parent' => $new_parent_string
	);

	# override the title we are outputting to the jemplate with the form title
	$self->{json_results}{title} = $self->{json_results}{form}{title};

	# all done ;)
}

# system-standard method to create/update data from a form-submission
sub perform_form_action {
	my $self = shift;
	my $p;

	# test code, uncomment as needed for debug
#	foreach $p (keys %{ $self->{luggage}{params} }) {
#		$self->{json_results}{params}{$p} = $self->{luggage}{params}{$p};
#	}
=cut
	# for the jemplate
		[% FOREACH p IN params.keys %]
			<br/>[% p %] - [% params.$p %]
		[% END %]
=cut

	# thankfully, omniclass->save() handles 99% of this for us and pulls from $self->{luggage}{params}
	# we just need to decide how to call it
	if ( $self->{luggage}{params}{action} =~ /create/) { # data-create, need parent
		$self->{omniclass_object}->save(
			'parent' => $self->{luggage}{params}{new_parent},
		);

	} else { # simple update, provide the record's data_code
		$self->{omniclass_object}->save(
			'data_code' => $self->{luggage}{params}{record},
		);

		# instruct action_tool to release the lock
		$self->{unlock} = 1;
	}

	# was it successful?
	if ($self->{omniclass_object}->{status}[-1]{success}) { # yes, show message
		$self->{json_results}{title} = 'Success!';

		if ($self->{luggage}{params}{name} eq 'Not Named') { # does not use name, so substitute datatype name
			$self->{json_results}{message} = $self->{omniclass_object}{datatype_info}{name}.' was '.ucfirst($self->{luggage}{params}{action}).'d.';
		} else { # use proper name
			$self->{json_results}{message} = $self->{luggage}{params}{name}.' was '.ucfirst($self->{luggage}{params}{action}).'d.';
		}

		# send back the ID's, in case we are in API mode
		$self->{json_results}{new_data_code} = $self->{omniclass_object}{last_saved_data_code};
		$self->{json_results}{new_altcode} = $self->{omniclass_object}->data_code_to_altcode( $self->{json_results}{new_data_code} );

	# otherwise, show error
	} else {
		$self->{json_results}{error_title} = $self->{omniclass_object}->{status}[-1]{message};
		$self->{json_results}{error_message} = $self->{omniclass_object}->{status}[-1]{detail};
	}

	# tell omnitool_routines->Tool->submit_form() to use gritter for the notice
	$self->{json_results}{show_gritter_notice} = 1;

	# tell jemplate what to show -- should not need this, but leaving for now
	$self->{json_results}{form_was_submitted} = 1;
}

1;

