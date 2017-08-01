package omnitool::applications::otadmin::datatypes::tool_mode_configs;
# support for 'Fields to Include' / 'Default Ordering Field' options lists

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::tool_mode_configs::dt = '13_1';

use strict;

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# we need a prepare_for_form_fields() method to gather information about the
# application which contains this tool for our options_* hooks
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far

	my ($lineage, $new_parent_type,$new_parent_data_code, $parent_tool_data_code, $parent_omniclass_object, $tool_omniclass_object);

	# we will need the target_datatype of the parent tool, so we will want this either way:
	$tool_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '8_1',
		'skip_hooks' => 1,
	);

	# we need to determine the ID of the application containing this tool / tool mode config
	# if we have a target parent location, find the application containing that tool
	# will need an omniclass object for this parent to get_lingenage
	if ($$form{hidden_fields}{new_parent}) {
		($new_parent_type,$new_parent_data_code) = split /:/, $$form{hidden_fields}{new_parent};

		# the parent will be of type 'Tool'

		$lineage = $tool_omniclass_object->get_lineage(
			'data_code' => $new_parent_data_code,
		);
		($self->{parent_application_id} = $$lineage[1]) =~ s/1_1://;

		$parent_tool_data_code = $new_parent_data_code;

	# or if we are updating ourself, get our own lineage to get to the app ID
	} elsif ($$form{hidden_fields}{record}) {
		$lineage = $self->get_lineage(
			'data_code' => $$form{hidden_fields}{record},
		);
		($self->{parent_application_id} = $$lineage[1]) =~ s/1_1://;

		($parent_tool_data_code = $$lineage[-1]) =~ s/8_1://;
	}

	# load the parent tool to get that 'target_datatype;
	$tool_omniclass_object->load(
		'data_codes' => [$parent_tool_data_code]
	);
	$self->{parent_target_datatype} = $tool_omniclass_object->{data}{target_datatype};

	# now we get the field names for that datatype from our little routine in datatypes_hash.pm
	($self->{parent_target_dtfields}, $self->{parent_target_dtfields_keys}) =
		get_datatype_field_names($self->{parent_target_datatype}, $self->{db}, $self->{luggage}{database_name});

	# need an omniclass object for that datatype so we can get the field hook names
#	$self->{parent_target_datatype_object} = $self->{luggage}{object_factory}->omniclass_object(
#		'dt' => $self->{parent_target_datatype},
#	);


}

# build options fortarget datatype module field
sub options_fields_to_include {
	my $self = shift;
	my ($data_code) = @_;
	my (%options, @options_keys, $dt, $dtf, $hook);

	# sanity for our datatype var
	$dt = $self->{parent_target_datatype};

	# Name and Altcode fields
	$options{Name} = 'Record Name';
	push(@options_keys,'Name');
	$options{altcode} = 'ID';
	push(@options_keys,'altcode');

	# we need the fields for the parent tool's datatype
	foreach $dtf (@{ $self->{parent_target_dtfields_keys} }) {
		if ($self->{parent_target_dtfields}{$dtf}{virtual_field} eq 'Yes') {
			$options{$dtf} = 'Virtual Field: '.$self->{parent_target_dtfields}{$dtf}{name};
		} else {
			$options{$dtf} = 'DB Column: '.$self->{parent_target_dtfields}{$dtf}{name};
		}
		push(@options_keys,$dtf);
	}

    # return results
    return (\%options,\@options_keys);
}

# default sorting field really need to do the same thing as options_fields_to_include
sub options_default_sort_column {
	my $self = shift;
	my ($data_code) = @_;

	my ($options,$options_keys) = $self->options_fields_to_include($data_code);
	return ($options,$options_keys);
}

# allow them to select the Mode Type (system jemplate or 'custom')
sub options_mode_type {
	my $self = shift;

	my ($jemplates_path, $dh, $options,$options_keys);

	# here is where the possible perl modules live
	# where do the modules for this application live?
	$jemplates_path = $ENV{OTHOME}.'/code/omnitool/static_files/tool_mode_jemplates/';
	# use our utility method for reading in files from form_maker
	($options,$options_keys) = $self->options_from_directory($jemplates_path,'tt');

    # add in 'Custom'
	$$options{Custom} = 'Custom';
	push(@$options_keys,'Custom');

    # return results
    return ($options,$options_keys);
}


1;
