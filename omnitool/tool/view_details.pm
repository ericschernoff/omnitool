package omnitool::tool::view_details;
# generic tool.pm sub-class to display details that are meant to be shown via complex_details.tt
# works if the OmniClass Package has a 'view_details' method to produce %$details_hash

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;

}

# routine for performing complex actions and adding information to $self->{json_results}
# you can cheat and use it to prepare messages
sub perform_action {
	my $self = shift;

	my ($part, $details_hash);

	# perhaps they are retrieving a diagram?
	if ($self->{luggage}{params}{diagram_action}) { # yes, see below
		$self->network_diagram_data();

	# otherwise, plain old details_hash
	} else {
		# load the inline actions via utility method in action_tools.pm so we can embed into the details
		$self->get_inline_actions_for_action_tool();

		# for the title (altcode is automatically there)
		$self->{json_results}{data_title} = $self->{omniclass_object}{data}{name};

		# if the omniclass object has a view_details() method, use that to get a probably-complex %$details_hash
		if ($self->{omniclass_object}->can('view_details')) {
			$details_hash = $self->{omniclass_object}->view_details();
		# otherwise, just use the basic one below, which works off the 'Fields to Include' option for the Tool View Mode
		} else {
			$details_hash = $self->get_basic_details_hash();
		}

		# and load it into $self->{json_results}
		foreach $part (keys %$details_hash) {
			$self->{json_results}{$part} = $$details_hash{$part};
		}

		# perhaps they want to load a network diagram in a few moments?
		$self->{display_options}{load_network_diagram} = $self->{luggage}{params}{load_network_diagram};
	}
}

# support for network diagrams within complex details --> load data only!
sub network_diagram_data {
	my $self = shift;

	# the routine we used to generate the details_hash populated '$self->{display_options}{load_network_diagram}'

	# load that diagram up
	my $saved_network_diagram_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'saved_network_diagrams',
		'data_codes' => [ $self->{display_options}{load_network_diagram} ],
	);

	# does this object want to 'overload' the diagram data?
	if ($self->{omniclass_object}->can('overload_network_data')) {
		# will really just munge $saved_diagram_object->{data}{diagram_data}
		$self->{luggage}{saved_network_diagrams} = $saved_network_diagram_object;
		$self->{json_results}{diagram_data} = $self->{omniclass_object}->overload_network_data();

	} else { # just return our data
		$self->{json_results}{diagram_data} = $saved_network_diagram_object->{data}{diagram_data};
	}

}

# method to build a basic, one-tab %$details_hash, working from the 'Fields to Include' option for the Tool View Mode
sub get_basic_details_hash {
	my $self = shift;

	my ($db_column, $details_hash, $field, $n, $num);

	# here is the skeleton structure for the single tab
	$details_hash = {
		'tab_keys' => [1],
		'tab_info' => {
			1 => ['main','Main Info'],
		},
		'tabs' => {
			1 => {
				'type' => 'info_groups',
				'data' => [
					[
						# [ 'Author', $author_object->{data}{name} ],
					],
					[
						# [ 'Author', $author_object->{data}{name} ],
					],
				],
				'text_blocks' => [
					# [ 'Description', $self->{data}{description}],
				],
			},
		},
	};

	# we need the current view mode config in $self->{this_mode_config}
	# as well as the field names into $self->{included_field_names}, and
	# this nice method from center_stage.pm will handle all that for us:
	$self->prep_fields_to_include();

	# now add in the fields
	$num = 0; # for tracking which tab side we are in
	$n = 0; # for tracking our place in included_records_fields
	foreach $field (split /,/, $self->{this_mode_config}{fields_to_include}) {
		$db_column = $self->{omniclass_object}->{datatype_info}{fields}{$field}{table_column};

		# long text fields go into 'text_blocks'
		if ($self->{omniclass_object}->{datatype_info}{fields}{$field}{field_type} =~ /long_text/) {
			push(@{ $$details_hash{tabs}{1}{text_blocks} },[
				$self->{included_field_names}[$n], $self->{omniclass_object}->{data}{$db_column}
			]);

		} elsif (ref($self->{omniclass_object}->{data}{$db_column}) eq 'ARRAY') {
			push(@{ $$details_hash{tabs}{1}{data}[$num] }, [
				$self->{included_field_names}[$n], {
					'uri' => $self->{omniclass_object}->{data}{$db_column}[0]{uri},
					'text' => $self->{omniclass_object}->{data}{$db_column}[0]{text},
				}
			]);
			$num++;
			$num = 0 if $num > 1; # only 0 or 1
		} else { # two-column info_groups
			push(@{ $$details_hash{tabs}{1}{data}[$num] }, [
				$self->{included_field_names}[$n], $self->{omniclass_object}->{data}{$db_column}.' '
			]);
			$num++;
			$num = 0 if $num > 1; # only 0 or 1
		}
		$n++;
	}

	# delete $$details_hash{tabs}{1}{text_blocks} if empty
	if (!$$details_hash{tabs}{1}{text_blocks}[0]) {
		delete($$details_hash{tabs}{1}{text_blocks});
	}

	return $details_hash;
}

1;
