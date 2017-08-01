package omnitool::applications::otadmin::tools::order_items;
# This module drives the ordering (priority-setting) tools for
# ordering tool modes, tool filter menus, recording-color rules, tools themselves,
# and datatype fields.  All of these datatypes have a 'priority' field, so
# we just need to get the appropriate omniclass object. For tools which use
# this class, we will set our 'uri_path_base' to reflect the datatype to use,
# i.e. order_tools, order_datatype_fields

use parent 'omnitool::tool';

use strict;

# generate the form, which is one field, a multi-select for the sub-tools
sub generate_form {
	my $self = shift;
	
	my ($record, $form, $non_useful_bits, $dt_table);

	# first step, determine the type of data we are sorting
	($non_useful_bits,$dt_table) = split /order_/, $self->{attributes}{uri_path_base};
	
	# get an omniclass object for that datatype
	$self->{this_omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => $dt_table,
		'skip_hooks' => 1,
	);	
		
	# the baseline one-field form with the multi-select
	$form = {
		'title' => 'Order '.$self->{this_omniclass_object}{datatype_info}{name}.' Records Under '.$self->{omniclass_object}{data}{name},
		'instructions' => 'Use the Up/Down buttons to place the sub-tools in the order in which you would like to prioritize them.  Select all the options prior to submitting the form.',
		'submit_button_text' => 'Set Ordering',
		# here is a total hack:  select-all these options so there are no accidental submissions with half
		# of them un-selected....only really for this specific tool
		'submit_button_hover' => qq{onmouseover="selectAllOptions(document.getElementById('multiselect_ordered_items'));"},	
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Set Record Order',
				'name' => 'ordered_items',
				'field_type' => 'multi_select_ordered', # e.g. short_text, single_select
				'is_required' => 1, # will be required for form submit; works for text fields
			},
		}
	};	


	# now get the subordinate tools:
	$self->{this_omniclass_object}->search(
		'search_options' => [{
			'match_column' => 'parent',
			'match_value' => $self->{target_datatype}.':'.$self->{omniclass_object}{records_keys}[0]
		}],
		'sort_column' => 'priority',
		'auto_load' => 1,
		'do_clear' => 1,
		'skip_hooks' => 1
	);

	# now read them in
	foreach $record (@{ $self->{this_omniclass_object}{records_keys} }) {
		$$form{fields}{1}{options}{$record} = $self->{this_omniclass_object}->{records}{$record}{name};

		# if we are working on datatypes, and this is a virtual field, indicate as such
		if ($self->{this_omniclass_object}->{records}{$record}{virtual_field} eq 'Yes') {
			$$form{fields}{1}{options}{$record} = 'Virtual Field: '.$$form{fields}{1}{options}{$record};
		}

		push(@{ $$form{fields}{1}{options_keys} }, $record);
	}
	
	# put it in the right spot
	$self->{json_results}{form} = $form;
	
}

# pull in the field and update the priorities.  somewwhat easy
sub perform_form_action {
	my $self = shift;
	
	my ($n, $sub_tool);
	
	$n = 1;
	foreach $sub_tool (split /,/, $self->{luggage}{params}{ordered_items}) {
		$self->{luggage}{params}{priority} = $n;
		$self->{this_omniclass_object}->save(
			'data_code' => $sub_tool, 
			'skip_blanks' => 1
		);	
		$n++;	
	}
	
	$n--;	
	
	# tell our template what to to
	$self->{json_results}{form_was_submitted} = 1;
	$self->{json_results}{title} = 'Records Have Been Re-Ordered';
	$self->{json_results}{message} = $n.' '.$self->{this_omniclass_object}{datatype_info}{name}.' records re-ordered under '.$self->{omniclass_object}{data}{name};
	$self->{json_results}{show_gritter_notice} = 1;	
}

1;
