package omnitool::applications::otadmin::tools::move_tool;
# tool designed to allow changing tools' parent tool within an application

use parent 'omnitool::tool';

use strict;

# generate the form, which is one field, a multi-select for the sub-tools
sub generate_form {
	my $self = shift;

	my ($lineage, $plain_hash, $form);

	# figure out the parent-string for the containing application
	$lineage = $self->{omniclass_object}->get_lineage(
		'data_code' => $self->{omniclass_object}->{data_code},
	);
	# it will be $$lineage[1]

	# now, using our super-cool omniclass_tree functions, build a deep hash
	# containing all of the tools under this application
	$plain_hash = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'tools',
		'tree_mode' => 1,
		'tree_datatypes' => 'tools',
		'return_extracted_data' => 1,
		'skip_hooks' => 1,
		'load_fields' => 'uri_path_base',
		'search_options' => [{
			'match_column' => 'parent',
			'match_value' => $$lineage[1],
		}]
	);

	# put together our form with the chosen single-select to let them choose the parent tool
	$form = {
		'title' => "Move '".$self->{omniclass_object}{data}{name}."' to Another Tool",
		'instructions' => 'Use the select menu below to choose another parent for '.$self->{omniclass_object}{data}{name}.
			'. It will be added as the last entry, so you may need to use "Order Tools" feature next.',
		'submit_button_text' => 'Move '.$self->{omniclass_object}{data}{name},
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => {
			1 => {
				'title' => 'Select New Parent',
				'name' => 'new_parent_tool',
				'field_type' => 'single_select',
				'is_required' => 1,
				'Instructions' => 'Required.'
			},
		}
	};

	# get 'Top' in there
	$$form{fields}{1}{options}{ $$lineage[1] } = 'Top';
	push(@{ $$form{fields}{1}{options_keys} }, $$lineage[1]);

	# nowe we need to load in the options; to do that, we shall need a recursive method
	$self->load_tool_parent_options($form,$plain_hash,'Top');

	# put it in the right spot to go to the client
	$self->{json_results}{form} = $form;

}

# recursive method to find the potential parents for the target tool
sub load_tool_parent_options {
	my $self = shift;
	my ($form,$plain_hash,$parent_name) = @_;
	# declare vars
	my ($record);

	foreach $record (@{$$plain_hash{records_keys}}) {
		# can't be under myself
		next if $record eq $self->{omniclass_object}->{data_code};

		# pre-fill the name of the current parent tool
		if ('8_1:'.$record eq $self->{omniclass_object}{data}{metainfo}{parent}) {
			$$form{fields}{1}{preset} = $record;
		}

		$$form{fields}{1}{options}{$record} = $$plain_hash{records}{$record}{name}.qq{ under $parent_name};
		push(@{ $$form{fields}{1}{options_keys} }, $record);

		# if there are subordinates, spiral down
		if ($$plain_hash{records}{$record}{tools}{records_keys}[0]) { # yes, go for it
			# give it the current location in the structure plus the name of the current tool
			$self->load_tool_parent_options($form,$$plain_hash{records}{$record}{tools},$$plain_hash{records}{$record}{name});
		}
	}

}

# pull in the field and update the priorities.  somewwhat easy
sub perform_form_action {
	my $self = shift;

	# sanity
	my $new_parent_code = $self->{luggage}{params}{new_parent_tool};

	my ($new_parent_name, $new_parent_type);

	if ($new_parent_code =~ /1_1:/) { # application
		($new_parent_type,$new_parent_code) = split /:/, $new_parent_code;
		$new_parent_name = ' the top of the application ';
	} else {
		$new_parent_type = '8_1';
		$new_parent_name = $self->{omniclass_object}{records}{$new_parent_code}{name};
	}

	# okay, let's make a move!
	$self->{omniclass_object}->change_parent(
		'data_code' => $self->{omniclass_object}->{data_code},
		'new_parent_id' => $new_parent_code,
		'new_parent_type' => $new_parent_type,
	);

	# get the new parent's name
	$self->{omniclass_object}->load('data_codes' => [$new_parent_code]);

	# tell our template what to to
	$self->{json_results}{form_was_submitted} = 1;
	$self->{json_results}{title} = "'".$self->{omniclass_object}{data}{name}."' Was Moved.";
	$self->{json_results}{message} = "It is now under '".$new_parent_name."'.";;
	$self->{json_results}{show_gritter_notice} = 1;
}

1;
