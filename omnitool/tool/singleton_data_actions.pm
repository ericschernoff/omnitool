package omnitool::tool::singleton_data_actions;
# Acts as a tool.pm sub-class, providing the create and update functions for Action Tools for
# situations where there can be only one record of a certain type under another record.
#
# For example, each 'Person' would only have one 'Appearance Description' sub-record, so
# you would note set up separate tools for 'Create Appearance Description' and 'Update
# Appearance Description' but rather one 'Configure Appearance Description' tool using
# this sub-class.  It will go into the proper create or update mode depending on whether
# a record of the target datatype exists under the selected parent (based on the link clicked).
#
# *** Best to set links for these tools as Inline / Data Record.
#
# This includes providing a generate_form() method to build the form hash from omniclass->form()
# and the perform_form_action() to create or save save the new record under our parent tool's
# current data-record.
#
# Most tool.pm sub-classes will live within an Application's Perl Modules directory, but this
# is a core feature of OmniTool and will available as a tool.pm class for any Application/Tool.

$omnitool::tool::singleton_data_actions::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# method to set up form structure in $self->{json_results}{form} from omniclass->form()
sub generate_form {
	my $self = shift;

	my ($tool_datacode, $parent_tool_datacode, $parent_string, $parent_tool_datatype, $action_arg, $send_data_code, );

	# we need to set some variables based on our uri / argument

	# determine the desired parent / data placement based on $self->{display_options}{altcode}
	# re-usable subroutine from action_tool.pm:
	$parent_string = $self->figure_new_parent();

	# now see if a record already exists under this parent
	$self->{omniclass_object}->search(
		'search_options' => [
			{
				'match_column' => 'parent',
				'operator' => '=',
				'match_value' => $parent_string,
			},
		],
	);

	# if one was found, we are in update mode
	if ($self->{omniclass_object}->{search_results}[0]) {
		$action_arg = 'update';
		$send_data_code = $self->{omniclass_object}->{search_results}[0];

	# otherwise, create mode
	} else {
		$action_arg = 'create';
		$send_data_code = '';
	}

	# this is very simple because of all the defaults in the form() method,
	# we just have to provide it with the target record data_code and the 'update' action
	$self->{json_results}{form} = $self->{omniclass_object}->form(
		'data_code' => $send_data_code,
		'action' => $action_arg,
		'new_parent' => $parent_string
	);

	# override the title we are outputting to the jemplate with the form title
	$self->{json_results}{title} = $self->{json_results}{form}{title};

	# all done ;)
}

# system-standard method to create/update data from a form-submission
# this will be identical to standard_data_actions's routine
sub perform_form_action {
	my $self = shift;
	my $p;

	# test code, uncomment as needed for debug
=cut
	foreach $p (keys %{ $self->{luggage}{params} }) {
		$self->{json_results}{params}{$p} = $self->{luggage}{params}{$p};
	}
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

	# if we got this far without an error message, then we have...
	$self->{json_results}{title} = 'Success!';

	if ($self->{luggage}{params}{name} eq 'Not Named') { # does not use name, so substitute datatype name
		$self->{json_results}{message} = $self->{omniclass_object}{datatype_info}{name}.' was '.ucfirst($self->{luggage}{params}{action}).'d.';
	} else { # use proper name
		$self->{json_results}{message} = $self->{luggage}{params}{name}.' was '.ucfirst($self->{luggage}{params}{action}).'d.';
	}


	# tell omnitool_routines->Tool->submit_form() to use gritter for the notice
	$self->{json_results}{show_gritter_notice} = 1;

	# tell jemplate what to show -- should not need this, but leaving for now
	$self->{json_results}{form_was_submitted} = 1;
}


1;

