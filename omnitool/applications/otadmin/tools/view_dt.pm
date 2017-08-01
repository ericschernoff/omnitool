package omnitool::applications::otadmin::tools::view_dt;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to prepare the info hash for display
sub perform_action {
	my $self = shift;

	my (@dt_codes, $dt_code, $dt_field);


	$self->{json_results}{data_title} = 'Details for "'.$self->{omniclass_object}{data}{name}.'" OmniClass Datatype';
	$self->{json_results}{hide_altcode} = 1;

	$self->{json_results}{tab_info} = {
		1 => ['main','Main Info'],
		2 => ['description','Description'],
		3 => ['fields','Fields'],
	};
	$self->{json_results}{tab_keys} = [1,2,3];

	# some defaults

	# description
	if (!$self->{omniclass_object}{data}{description}) {
		$self->{omniclass_object}{data}{description} = 'Not Defined';
	}

	# lock lifetime
	if ($self->{omniclass_object}{data}{lock_lifetime}) {
		$self->{omniclass_object}{data}{lock_lifetime} .= ' mins' ;
	} else {
		$self->{omniclass_object}{data}{lock_lifetime} = 'App / Tool Default';
	}

	# perl module / sub-class
	if ($self->{omniclass_object}{data}{perl_module}) {
		$self->{omniclass_object}{data}{perl_module} .= '.pm' ;
	} else {
		$self->{omniclass_object}{data}{perl_module} = 'Not Defined';
	}

	# containable datatypes is a bit of a pain
	if (!$self->{omniclass_object}{data}{containable_datatypes}) {
		$self->{omniclass_object}{data}{containable_datatypes} = 'Not Defined';

	# if there are some, have to resolve to names
	} else {
		(@dt_codes) = split /,/, $self->{omniclass_object}{data}{containable_datatypes};
		$self->{omniclass_object}->load(
			'skip_hooks' => 1,
			'data_codes' => [@dt_codes],
			'load_fields' => 'name',
		);
		$self->{omniclass_object}{data}{containable_datatypes} = '';
		foreach $dt_code (@dt_codes) {
			$self->{omniclass_object}{data}{containable_datatypes} .= $self->{omniclass_object}->{records}{$dt_code}{name}."\n";
		}
	}

	# load up our details
	$self->{json_results}{tabs} = {
		1 => {
			'type' => 'info_groups',
			'data' => [
				[
					[ 'DB Table', $self->{omniclass_object}{data}{table_name} ],
					[ 'Metainfo Table', $self->{omniclass_object}{data}{metainfo_table} ],
					[ 'Sub-Class', $self->{omniclass_object}{data}{perl_module} ],
					[ 'Lock Lifetime', $self->{omniclass_object}{data}{lock_lifetime}],
				],
				[
					[ 'Show Name Field', $self->{omniclass_object}{data}{show_name} ],
					[ 'Log Updates', $self->{omniclass_object}{data}{extended_change_history} ],
					[ 'Archive Deletes', $self->{omniclass_object}{data}{archive_deletes} ],
					[ 'Tasks / Email', $self->{omniclass_object}{data}{support_email_and_tasks} ],
				],
			],
		},
		2 => {
			'type' => 'text_blocks',
			'data' => [
				[ 'Description', $self->{omniclass_object}{data}{description} ],
				[ 'Can Contain Datatypes', $self->{omniclass_object}{data}{containable_datatypes} ],
			],
		},
		3 => {
			'type' => 'table',
			'data' => [
				['Priority','Name','Type','DB Column / Method','Required / Force Alpha'],
			],
		},
	};

	# load up the fields
	$self->{dt_fields_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'datatype_fields',
		'skip_hooks' => 1,
		'search_options' => [{
			'match_column' => 'parent',
			'operator' => '=',
			'match_value' => '6_1:'.$self->{omniclass_object}{data_code},
		}],
		'auto_load'	=> 1,
		'sort_column' => 'priority',
	);

	foreach $dt_field (@{ $self->{dt_fields_object}{records_keys} }) {
		if ($self->{dt_fields_object}{records}{$dt_field}{virtual_field} eq 'Yes') {
			$self->{dt_fields_object}{records}{$dt_field}{field_type} = 'Virtual';
			$self->{dt_fields_object}{records}{$dt_field}{table_column} = 'field_'.$self->{dt_fields_object}{records}{$dt_field}{table_column}.'()';
		}

		push(@{ $self->{json_results}{tabs}{3}{data} },
			[
				$self->{dt_fields_object}{records}{$dt_field}{priority},
				$self->{dt_fields_object}{records}{$dt_field}{name},
				$self->{dt_fields_object}{records}{$dt_field}{field_type},
				$self->{dt_fields_object}{records}{$dt_field}{table_column},
				$self->{dt_fields_object}{records}{$dt_field}{is_required}.' / '.$self->{dt_fields_object}{records}{$dt_field}{force_alphanumeric},
			] );
	}

}


1;

__END__

Possible / example routines are below.  Please copy and paste them above the '1;' above
to make use of them.  See Pod documentation at the end of tool.pm to see usage suggestions.

Also, please be sure to save this file as $OTHOME/code/omnitool/applications/otadmin/tools/view_dt.pm

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
