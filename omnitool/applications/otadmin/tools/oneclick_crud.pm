package omnitool::applications::otadmin::tools::oneclick_crud;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# for grabbing the datatype hash for display_fields_options
use omnitool::common::datatype_hash;

# routine to prepare a form data structure and load it into $self->{json_results}
sub generate_form {
	my $self = shift;

	# grab the datatypes for the parent application, leveraging the datatype-functions
	# already in place for Tools
	$self->{omniclass_object}->prepare_for_form_fields({
		'hidden_fields' => {
			'new_parent' => $self->figure_new_parent(),
		},
	});
	my ($datatypes_options, $datatypes_options_keys) = $self->{omniclass_object}->options_target_datatype();

	# similar for the access roles
	my ($access_roles_options,$access_roles_options_keys) = $self->{omniclass_object}->get_access_roles();

	# get an 'open' in there
	$$access_roles_options{Open} = 'Open Access';
	unshift(@$access_roles_options_keys, 'Open');

	$self->{json_results}{form} = {
		'title' => 'One-Click CRUD',
		'instructions' => qq{
			This form allows you to quickly create a Search Tool for a particular Datatype with
			subordinate Tools to create, update, and delete records of that Datatype.  These will
			be very 'vanilla' and basic Tools, and you will likely need to alter to taste, but
			this will combine the first six steps.
		},
		'submit_button_text' => 'Create These Tools',
		'field_keys' => [1,2,3,4],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => {
			1 => {
				'title' => 'Select Target Datatype',
				'name' => 'target_datatype',
				'field_type' => 'single_select',
				'options' => $datatypes_options,
				'options_keys' => $datatypes_options_keys,
				'onchange' => "tool_objects['" . $self->{tool_and_instance} . "'].trigger_menu('multiselect_display_fields',this.options[this.selectedIndex].value,'display_fields_options');",
				'is_required' => 1,
			},
			2 => {
				'title' => 'Display Fields in Search',
				'name' => 'display_fields',
				'field_type' => 'multi_select_ordered',
				'options' => {
				},
				'options_keys' => [],
				'options_size' => '6',
				'is_required' => 1,
			},
			3 => {
				'title' => 'Sub-Tools to Create',
				'name' => 'sub_tools_to_create',
				'field_type' => 'multi_select_plain',
				'options' => {
					'view' => 'View Details',
					'create' => 'Create Data',
					'update' => 'Update Data',
					'delete' => 'Delete Data',
				},
				'options_keys' => ['view','create','update','delete'],
				'presets' => {
					'view' => 1,
					'create' => 1,
					'update' => 1,
					'delete' => 0,
				},
			},
			4 => {
				'title' => 'Access Roles',
				'name' => 'access_roles',
				'field_type' => 'access_roles_select',
				'options' => $access_roles_options,
				'options_keys' => $access_roles_options_keys,
			},
		}
	};

}

# routine to provide options for fields to display for the datatype for the onchange
sub display_fields_options {
	my $self = shift;

	my ($target_datatype_fields, $target_datatype_fields_keys, $json_results, $dtf);

	# now we get the field names for that datatype from our little routine in datatypes_hash.pm
	($target_datatype_fields, $target_datatype_fields_keys) =
		get_datatype_field_names($self->{luggage}{params}{source_value}, $self->{db}, $self->{luggage}{database_name});

	# Name and Altcode fields
	$$json_results{options}{Name} = 'Record Name';
	push(@{$$json_results{options_keys}},'Name');
	$$json_results{options}{altcode} = 'ID';
	push(@{$$json_results{options_keys}},'altcode');

	# we need the fields for the parent tool's datatype
	foreach $dtf (@$target_datatype_fields_keys) {
		if ($$target_datatype_fields{$dtf}{virtual_field} eq 'Yes') {
			$$json_results{options}{$dtf} = 'Virtual Field: '.$$target_datatype_fields{$dtf}{name};
		} else {
			$$json_results{options}{$dtf} = 'DB Column: '.$$target_datatype_fields{$dtf}{name};
		}
		push(@{$$json_results{options_keys}},$dtf);
	}

    # return results
    return $json_results;


}

# routine to perform the action specified by the form from generate_form (goes hand-in-hand with that method)
sub perform_form_action {
	my $self = shift;

	my ($create_tool_parent_string, $delete_tool_parent_string, $field, $new_parent_string, $params_key, $parent_string, $target_datatype_name, $target_datatype, $tool_object, $tool_params, $tool_view_mode_object, $tool_view_mode_params, $update_tool_parent_string,$parent_target_dtfields, $parent_target_dtfields_keys);

	# send this upon successful submit
	$self->{json_results}{form_was_submitted} = 1;

	# Step 1: need some omniclass objects
	# get a new Tool object
	$tool_object = $self->{luggage}{object_factory}->omniclass_object('dt' => 'tools');
	# get the tool view mode
	$tool_view_mode_object = $self->{luggage}{object_factory}->omniclass_object('dt' => 'tool_mode_configs');

	# Step 2: Set up a base %$params for both the Tool and the Tool View Mode Configs
	# using the default field values for those datatypes
	# first, the Tool object
	foreach $field (@{ $tool_object->{datatype_info}{fields_key} }) {
		# skip virtual fields
		next if $tool_object->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';
		$params_key = $tool_object->{datatype_info}{fields}{$field}{table_column};
		$$tool_params{$params_key} = $tool_object->{datatype_info}{fields}{$field}{default_value};
	}
	# then, the Tool View Mode object
	foreach $field (@{ $tool_view_mode_object->{datatype_info}{fields_key} }) {
		# skip virtual fields
		next if $tool_view_mode_object->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';
		$params_key = $tool_view_mode_object->{datatype_info}{fields}{$field}{table_column};
		$$tool_view_mode_params{$params_key} = $tool_view_mode_object->{datatype_info}{fields}{$field}{default_value};
	}
	$$tool_view_mode_params{priority} = 1;

	# Step 3: load up the params from the form just submitted
	foreach $params_key ('access_roles','target_datatype','uri_path_base') {
		$$tool_params{$params_key} = $self->{luggage}{params}{$params_key};
	}

	# We are going to build each tool separately, due to the differences between them

	# we need the name of the target datatype
	# again grab the datatypes for the parent application, leveraging the datatype-functions
	# already in place for Tools
	$self->{omniclass_object}->prepare_for_form_fields({
		'hidden_fields' => {
			'new_parent' => $self->figure_new_parent(),
		},
	});
	my ($datatypes_options, $datatypes_options_keys) = $self->{omniclass_object}->options_target_datatype();

	$target_datatype = $$tool_params{target_datatype}; # sanity
	$target_datatype_name = $$datatypes_options{$target_datatype};

	# Step 4: Build the Search / Top Tool, under the current parent
	$$tool_params{name} = 'Manage '.$target_datatype_name.'s'; # they will want to edit that later
	$$tool_params{uri_path_base} = lc($target_datatype_name);
		$$tool_params{uri_path_base} =~ s/[^0-9a-z\_]//gi;
	$$tool_params{button_name} = $target_datatype_name.'s'; # they will want to edit that later

	# get the parent string
	$parent_string = $self->figure_new_parent();

	# finally, do the save
	$tool_object->save(
		'parent' => $parent_string,
		'params' => $tool_params,
		'skip_blanks' => 1,
	);

	# get our new parent string
	$new_parent_string = '8_1:'.$tool_object->{last_saved_data_code};

	# now save the tool view mode for that new tool
	$$tool_view_mode_params{name} = 'Table View';
	$$tool_view_mode_params{mode_type} = 'Table';
	$$tool_view_mode_params{fields_to_include} = $self->{luggage}{params}{display_fields};
	$tool_view_mode_object->save(
		'parent' => $new_parent_string,
		'params' => $tool_view_mode_params,
		'skip_blanks' => 1,
	);
	# Step 5: Build the View-Details tool, if they want it
	if ($self->{belt}->really_in_list('view', $self->{luggage}{params}{sub_tools_to_create})) {
		$$tool_params{name} = 'View '.$target_datatype_name.' Details';
		$$tool_params{uri_path_base} = 'view_details';
		$$tool_params{button_name} = 'View Details';
		# $$tool_params{is_locking} = 'Yes';
		$$tool_params{share_parent_inline_action_tools} = 'Yes';
		# Use Inline Actions from Parent Search   | share_parent_inline_action_tools | No                |
		$$tool_params{tool_type} = 'Action - Screen';
		$$tool_params{perl_module} = 'view_details';
		$$tool_params{link_type} = 'Inline / Data Row';
		$$tool_params{icon_fa_glyph} = 'fa-search';

		# now save that new tool
		$tool_object->save(
			'parent' => $new_parent_string,
			'params' => $tool_params,
			'skip_blanks' => 1,
		);

		# now we get the field names for that datatype from our little routine in datatypes_hash.pm
		($parent_target_dtfields, $parent_target_dtfields_keys) =
			get_datatype_field_names($target_datatype, $self->{db}, $self->{luggage}{database_name});

		# and then prepare to create the new view
		$create_tool_parent_string = '8_1:'.$tool_object->{last_saved_data_code};
		$$tool_view_mode_params{name} = 'Complex Details';
		$$tool_view_mode_params{mode_type} = 'Complex_Details';
		$$tool_view_mode_params{fields_to_include} = join(',',@$parent_target_dtfields_keys);
		$$tool_view_mode_params{execute_function_on_load} = 'None';
		$tool_view_mode_object->save(
			'parent' => $create_tool_parent_string,
			'params' => $tool_view_mode_params,
			'skip_blanks' => 1,
		);
	}


	# Step 6: Build the Create-Data tool, if they want it
	if ($self->{belt}->really_in_list('create', $self->{luggage}{params}{sub_tools_to_create})) {
		$$tool_params{name} = 'Create a '.$target_datatype_name;
		$$tool_params{uri_path_base} = 'create';
		$$tool_params{button_name} = 'Create a '.$target_datatype_name;
		# $$tool_params{is_locking} = 'Yes';
		$$tool_params{share_parent_inline_action_tools} = 'Yes';
		# Use Inline Actions from Parent Search   | share_parent_inline_action_tools | No                |
		$$tool_params{tool_type} = 'Action - Screen';
		$$tool_params{perl_module} = 'standard_data_actions';
		$$tool_params{link_type} = 'Quick Actions';
		$$tool_params{icon_fa_glyph} = 'fa-plus';

		# now save that new tool
		$tool_object->save(
			'parent' => $new_parent_string,
			'params' => $tool_params,
			'skip_blanks' => 1,
		);

		# and then prepare to create the new view
		$create_tool_parent_string = '8_1:'.$tool_object->{last_saved_data_code};
		$$tool_view_mode_params{name} = 'Form View';
		$$tool_view_mode_params{mode_type} = 'ScreenForm';
		$$tool_view_mode_params{fields_to_include} = '';
		$$tool_view_mode_params{execute_function_on_load} = 'None';
		$tool_view_mode_object->save(
			'parent' => $create_tool_parent_string,
			'params' => $tool_view_mode_params,
			'skip_blanks' => 1,
		);
	}

	# Step 7: Build the Update-Data tool, if they want it
	if ($self->{belt}->really_in_list('update', $self->{luggage}{params}{sub_tools_to_create})) {
		$$tool_params{name} = 'Update a '.$target_datatype_name;
		$$tool_params{uri_path_base} = 'update';
		$$tool_params{button_name} = 'Update a '.$target_datatype_name;
		$$tool_params{is_locking} = 'Yes';
		$$tool_params{share_parent_inline_action_tools} = 'Yes';
		# Use Inline Actions from Parent Search   | share_parent_inline_action_tools | No                |
		$$tool_params{tool_type} = 'Action - Screen';
		$$tool_params{perl_module} = 'standard_data_actions';
		$$tool_params{link_type} = 'Inline / Data Row';
		$$tool_params{icon_fa_glyph} = 'fa-edit';
		$$tool_params{priority} = 1;

		# now save that new tool
		$tool_object->save(
			'parent' => $new_parent_string,
			'params' => $tool_params,
			'skip_blanks' => 1,
		);

		# and then prepare to create the new view
		$update_tool_parent_string = '8_1:'.$tool_object->{last_saved_data_code};
		$$tool_view_mode_params{name} = 'Form View';
		$$tool_view_mode_params{mode_type} = 'ScreenForm';
		$$tool_view_mode_params{fields_to_include} = '';
		$$tool_view_mode_params{execute_function_on_load} = 'None';
		$tool_view_mode_object->save(
			'parent' => $update_tool_parent_string,
			'params' => $tool_view_mode_params,
			'skip_blanks' => 1,
		);
	}

	# Step 8: Build the Delete-Data tool, if they want it
	if ($self->{belt}->really_in_list('delete', $self->{luggage}{params}{sub_tools_to_create})) {
		$$tool_params{name} = 'Delete a '.$target_datatype_name;
		$$tool_params{uri_path_base} = 'delete';
		$$tool_params{button_name} = 'Delete a '.$target_datatype_name;
		$$tool_params{is_locking} = 'Yes';
		$$tool_params{share_parent_inline_action_tools} = 'No';
		# Use Inline Actions from Parent Search   | share_parent_inline_action_tools | No                |
		$$tool_params{tool_type} = 'Action - Modal';
		$$tool_params{perl_module} = 'standard_delete';
		$$tool_params{link_type} = 'Inline / Data Row';
		$$tool_params{icon_fa_glyph} = 'fa-eraser';
		$$tool_params{priority} = 2;

		# now save that new tool
		$tool_object->save(
			'parent' => $new_parent_string,
			'params' => $tool_params,
			'skip_blanks' => 1,
		);

		# and then prepare to create the new view
		$delete_tool_parent_string = '8_1:'.$tool_object->{last_saved_data_code};
		$$tool_view_mode_params{name} = 'Message Modal';
		$$tool_view_mode_params{mode_type} = 'MessageModal';
		$$tool_view_mode_params{fields_to_include} = '';
		$$tool_view_mode_params{execute_function_on_load} = '';
		$tool_view_mode_object->save(
			'parent' => $delete_tool_parent_string,
			'params' => $tool_view_mode_params,
			'skip_blanks' => 1,
		);
	}

	# Step 9: Tell them that it is done via pop-up notice
	$self->{json_results}{title} = 'The New CRUD Tools Have Been Created';
	$self->{json_results}{message} = 'Please Edit to Suit Your Needs.';
	$self->{json_results}{show_gritter_notice} = 1;

	# otherwise, fill in some values in $self->{json_results} for your Jemplate
}

1;

