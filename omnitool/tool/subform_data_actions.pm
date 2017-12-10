package omnitool::tool::subform_data_actions;
# Standard Tool.pm sub-class to provide for creating/update a record with sub-data.
# This means a veritical form up top for the main record, followed by a set of spreadsheet-style
# forms for batch-editing the children (of a single type) of that main record.
#
# For this to work:
# 1. make the 'uri_path_base' one of 'create', 'update', 'create_from'
# 2. Use Spreadsheet_FormV1.tt as the tool view jemplate.
# 3. Make sure the datatype of the main record has only one 'Can Contain Datatypes' configured

$omnitool::tool::standard_data_actions::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# method to generate a form consisting of one main record and several sub-records/sub-forms
sub generate_form {
	my $self = shift;

	my (@possible_types, $action_arg, $field, $form_counter, $need_new_parent, $new_parent_string, $p, $send_data_code, $sub_record, $subdata_object, $subdata_type, $use_params_key, $row_name);

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

	# if a post_form routine kicks us back, we may need to fix these two params
	$self->{luggage}{params}{name} =~ s/,.*//g;
	$self->{luggage}{params}{new_parent} =~ s/,.*//g;

	# now generate the form for the primary/main record
	$self->{json_results}{form} = $self->{omniclass_object}->form(
		'data_code' => $send_data_code,
		'action' => $action_arg,
		'new_parent' => $new_parent_string
	);

	# send the primary data code special
	$self->{json_results}{form}{hidden_fields}{main_record} = $self->{omniclass_object}->{data_code};

	$self->{json_results}{submit_button_text} = $self->{json_results}{form}{submit_button_text};

	# override the title we are outputting to the jemplate with the form title
	$self->{json_results}{display_title} = $self->{json_results}{form}{title};
	# $self->{json_results}{submit_button_text} = '';

	# STARTING THE SUB-DATA FORMS HERE.

	# Get an omniclass object of the sub-data type
	$subdata_type = $self->{omniclass_object}->{datatype_info}{containable_datatypes};
	if ($subdata_type =~ /,/) { # more than one: chose the first
		(@possible_types) = split /,/, $subdata_type;
		$subdata_type = $possible_types[0];
	}
	# no subdatatype? error out
	if (!$subdata_type) {
		$self->{belt}->mr_zebra(qq{Cannot use subform_data_actions.pm without defining a containable datatype for the main datatype.},1);
	}

	# finally, get the subdata object
	$subdata_object = $self->{omniclass_object}->get_omniclass_object(
		'dt' => $subdata_type,
	);

	# some field-related tasks
	foreach $field (@{$subdata_object->{datatype_info}{fields_key}}) {
		# the spreasheet form does not like chosen, so avoid it
		if ($subdata_object->{datatype_info}{fields}{$field}{field_type} eq 'single_select') {
			$subdata_object->{datatype_info}{fields}{$field}{field_type} = 'single_select_plain';
		}

		# hide the hiddens and the virtual fields
		next if $subdata_object->{datatype_info}{fields}{$field}{field_type} eq 'hidden_field';
		next if $subdata_object->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';

		# we need headings for the batch-entry area
		push( @{$self->{json_results}{headings}},
			$subdata_object->{datatype_info}{fields}{$field}{name}
		);
	}

	# name field heading?
	if ($subdata_object->{datatype_info}{show_name} eq 'Yes') {
		unshift( @{$self->{json_results}{headings}},
			'Name'
		);
	}

	# id of the form
	unshift( @{$self->{json_results}{headings}},
		'ID'
	);

	# if we are doing update or create-from, load the existing records
	if ($self->{attributes}{uri_path_base} =~ /update|create_from/) {
		$subdata_object->simple_search(
			'parent' => $self->{omniclass_object}->{parent_string},
			'auto_load' => 1,
		);
	}

	# pack up the $subdata_object for use in preform_form_action
	$self->{subdata_object} = $subdata_object;

	# now we build out the forms:

	# the forms will be in an array
	$form_counter = 0;

	# now let's add a form for each of those records
	foreach $sub_record (@{$subdata_object->{records_keys}}) {
		# create_from mode means they are all 'New' values
		if ($self->{attributes}{uri_path_base} =~ /create_from/) {
			$use_params_key = 'new';
			$row_name = 'New';
		# otherwise, we will update the records themselves
		} else {
			$use_params_key = $sub_record;
			$row_name = $form_counter + 1;
		}

		$self->{json_results}{forms}[$form_counter] = $subdata_object->form(
			'data_code' => $sub_record,
			'use_params_key' => $use_params_key,
			'row_name' => $row_name,
		);
		$form_counter++;
	}

	# and we need a form to create a new record (the JS will let them copy this)
	$self->{json_results}{forms}[$form_counter] = $subdata_object->form(
		'use_params_key' => 'new',
		'row_name' => 'New',
	);

}

# method to parse this main form and its subordinates
sub perform_form_action {
	my $self = shift;

	my ($subdata_object, $subdata_parent_string, $first_field, $params_key, $col, $n, $new_params, $first_field_value);

	# saving the main record will be very similiar to our older brother, standard_data_actions:

	# fix the name field
	if ($self->{luggage}{params}{multi}{name}[0]) {
		$self->{luggage}{params}{name} = $self->{luggage}{params}{multi}{name}[0];
	}

	# thankfully, omniclass->save() handles 99% of this for us and pulls from $self->{luggage}{params}
	# we just need to decide how to call it
	if ( $self->{attributes}{uri_path_base} =~ /create/ ) { # data-create, need parent
		# might have sent more than one of these ;)
		if ($self->{luggage}{params}{multi}{new_parent}[0]) {
			$self->{luggage}{params}{new_parent} = $self->{luggage}{params}{multi}{new_parent}[0];
		}

		$self->{omniclass_object}->save(
			'parent' => $self->{luggage}{params}{new_parent},
		);

	} else { # simple update, provide the record's data_code
		$self->{omniclass_object}->save(
			'data_code' => $self->{luggage}{params}{main_record},
		);

		# instruct action_tool to release the lock
		$self->{unlock} = 1;
	}

	# this part is where we differ:  we need to save each of the subodinate records

	# get the subdata omniclass object from what we did in generate_form
	$subdata_object = $self->{subdata_object};

	# get the new parent string -- can't depend on {parent_string}, as we may have just made something
	$subdata_parent_string = $self->{omniclass_object}->{dt}.':'.$self->{omniclass_object}->{last_saved_data_code};

	# what is the first field?
	if ($subdata_object->{datatype_info}{show_name} eq 'Yes') { # will be the name field
		$first_field = 'name';
	} else { # no name, first actual form field
		$first_field = $subdata_object->{datatype_info}{fields_key}[0];
		$first_field = $subdata_object->{datatype_info}{fields}{$first_field}{table_column};
	}

	# let's handle the existing records first
	foreach $params_key (split /,/, $self->{luggage}{params}{the_params_key}) {
		# skip the 'new' ones
		next if $params_key eq 'new';

		# if they blanked out the first field for an existing record form, they want to delete the record
		$first_field_value = $self->{luggage}{params}{$params_key.'_'.$first_field}; # sanity
		if (!$first_field_value) {
			$subdata_object->delete(
				'data_code' => $params_key,
			);

		# otherwise, update the record
		} else {
			$subdata_object->save(
				'parent' => $subdata_parent_string,
				'params_key' => $params_key,
				'data_code' => $params_key,
				'params' => $self->{luggage}{params},
			);
		}
	}

	# what if there was only one new entry?  won't be in @{$self->{luggage}{params}{multi}} -- fix it
	if (!$self->{luggage}{params}{multi}{'new_'.$first_field}[0] && $self->{luggage}{params}{'new_'.$first_field}) {
		foreach $col (split /,/, $subdata_object->{datatype_info}{all_db_columns}) {
			$self->{luggage}{params}{multi}{'new_'.$col}[0] = $self->{luggage}{params}{'new_'.$col};
		}
		# name too
		$self->{luggage}{params}{multi}{'new_name'}[0] = $self->{luggage}{params}{'new_name'};
	}

	# do the 'new' ones seprately, as they will all be array params
	$n = 0;
	foreach $first_field_value ( @{$self->{luggage}{params}{multi}{'new_'.$first_field}} ) {
		# skip if no component number
		if ($first_field_value) {
			$new_params = {};
			foreach $col (split /,/, $subdata_object->{datatype_info}{all_db_columns}) {
				$$new_params{$col} = $self->{luggage}{params}{multi}{'new_'.$col}[$n];
			}

			# name too
			$$new_params{name} = $self->{luggage}{params}{multi}{'new_name'}[$n];

			# do the save
			$subdata_object->save(
				'parent' => $subdata_parent_string,
				'params' => $new_params,
			);
		}
		$n++;
	}

	# if the primary record type has a post_save, let's run it (again) now
	if ($self->{omniclass_object}->can('post_save')) {
		$self->{omniclass_object}->post_save();
	}

	# back to standard procedures: prepare a return message
	# if we got this far without an error message, then we have...
	$self->{json_results}{title} = 'Success!';

	if ($self->{luggage}{params}{name} eq 'Not Named') { # does not use name, so substitute datatype name
		$self->{json_results}{message} = $self->{omniclass_object}{datatype_info}{name}.' was saved';
	} else { # use proper name
		$self->{json_results}{message} = $self->{luggage}{params}{name}.' was saved';
	}

	# send back the ID's, in case we are in API mode
	$self->{json_results}{new_data_code} = $self->{omniclass_object}{last_saved_data_code};
	$self->{json_results}{new_altcode} = $self->{omniclass_object}->data_code_to_altcode( $self->{json_results}{new_data_code} );

	# tell omnitool_routines->Tool->submit_form() to use gritter for the notice
	$self->{json_results}{show_gritter_notice} = 1;

	# tell jemplate what to show -- should not need this, but leaving for now
	$self->{json_results}{form_was_submitted} = 1;
}

1;

