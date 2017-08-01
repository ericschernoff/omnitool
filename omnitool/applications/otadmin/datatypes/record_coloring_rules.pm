package omnitool::applications::otadmin::datatypes::record_coloring_rules;
# support for 'Use for Modes' / 'Match Field' options lists

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::record_coloring_rules::dt = '14_1';

use strict;

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# we need a prepare_for_form_fields() method to gather information about the 
# application which contains this tool for our options_* hooks
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far
	
	my ($parent_type,$parent_tool_data_code,$tool_omniclass_object, $lineage);
	
	# we need to determine the parent tool, to get its target datatype and its subordinate modes
	if ($$form{hidden_fields}{new_parent}) {  # create-mode, will be the new parent
		($parent_type,$parent_tool_data_code) = split /:/, $$form{hidden_fields}{new_parent};
	} else {
		($parent_type,$parent_tool_data_code) = split /:/, $self->{data}{metainfo}{parent};
	}

	# load up the tool
	$tool_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '8_1',
		'skip_hooks' => 1,
		'data_codes' => [$parent_tool_data_code],
	);		

	# here is the target datatype
	$self->{parent_target_datatype} = $tool_omniclass_object->{data}{target_datatype};
	
	# and we need the parent application for this tool in order to get the datatypes hash
	$lineage = $tool_omniclass_object->get_lineage(
		'data_code' => $parent_tool_data_code, 
	);
	($self->{parent_application_id} = $$lineage[1]) =~ s/1_1://;	
	
	# now we get the field names for that datatype from our little routine in datatypes_hash.pm
	($self->{parent_target_dtfields}, $self->{parent_target_dtfields_keys}) = 
		get_datatype_field_names($self->{parent_target_datatype}, $self->{db}, $self->{luggage}{database_name});
	

	# and we need the tool modes for this tools; pack it up for use below
	$self->{tool_modes_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '13_1',
		'skip_hooks' => 1,
	);		
	$self->{tool_modes_object}->search(
		'search_options' => [{
			'match_column' => 'parent',
			'operator' => '=',
			'match_value' => '8_1:'.$parent_tool_data_code, 
		}],
		'sort_column' => 'name',
		'auto_load'	=> 1,
		'skip_hooks' => 1,
	);
}

# build options fortarget datatype module field
sub options_match_field {
	my $self = shift;
	my ($data_code) = @_;
	my (%options, @options_keys, $dt, $dtf, $col_type);
	
	# sanity for our datatype var
	$dt = $self->{parent_target_datatype};
	
	# Name field
	$options{Name} = 'Record Name';
	push(@options_keys,'Name');			
	
	# we need the fields for the parent tool's datatype
	foreach $dtf (@{ $self->{parent_target_dtfields_keys} }) {
		if ($self->{parent_target_dtfields}{$dtf}{virtual_field} eq 'Yes') {
			$col_type = 'Virtual Column: ';
		} else {
			$col_type = 'DB Column: ';
		}
		$options{$dtf} = $col_type.$self->{parent_target_dtfields}{$dtf}{name};
		push(@options_keys,$dtf);			
	}

    # return results
    return (\%options,\@options_keys);
}

# selector for modes to include
sub options_use_for_modes {
	my $self = shift;
	my ($data_code) = @_;

	my ($mode_key,$options,$options_keys);
	
	foreach $mode_key (@{ $self->{tool_modes_object}->{records_keys} }) {
		$$options{$mode_key} = $self->{tool_modes_object}->{records}{$mode_key}{name};
		push(@$options_keys,$mode_key);			
	}

	return ($options,$options_keys);
}


1;
