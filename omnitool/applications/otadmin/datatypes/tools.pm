package omnitool::applications::otadmin::datatypes::tools;

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::tools::dt = '8_1';

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# special new() routines
sub init {
	my $self = shift;
}

# special field to make browsing through Manage Tools easier
sub field_enhanced_name {
	my $self = shift;
	my ($args) = @_;
	foreach $r (@{$self->{records_keys}}) {
		$self->{records}{$r}{enhanced_name}[0] = {
			'text' => $self->{records}{$r}{name}, # .'-'.$self->{metainfo}{$r}{nice_update_time},
			'uri' => '#/tools/ot_admin/tools_mgr/'.$self->{metainfo}{$r}{altcode},
			'glyph' => $self->{records}{$r}{icon_fa_glyph}
		};
	}
}

# we need a prepare_for_form_fields() method to gather information about the
# application which contains this tool for our options_* hooks
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far

	my ($lineage, $parent_tool_target_datatype, $plain_tool_omniclass_object, $new_parent_type,$new_parent_data_code, $parent_omniclass_object, $application_omniclass_object, $data_code);

	# determine the ID of the application containing this tool
	# if we have a target parent location, find the application containing that tool
	# will need an omniclass object for this parent to get_lingenage
	if ($$form{hidden_fields}{new_parent}) {
		($new_parent_type,$new_parent_data_code) = split /:/, $$form{hidden_fields}{new_parent};
	}

	# if the parent is another tool, get that parent's target datatype for the inline link
	# Link Match Field
	if ($new_parent_type eq '8_1') {
		$plain_tool_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => 'tools',
			'skip_hooks' => 1,
			'load_fields' => 'target_datatype',
			'data_codes' => [$new_parent_data_code]
		);
		$parent_tool_target_datatype = $plain_tool_omniclass_object->{data}{target_datatype};
	}

	# if we have a parent, and it's an application, that's our parent app ID
	if ($new_parent_type eq '1_1') { # our parent is an application
		$self->{parent_application_id} = $new_parent_data_code;

	# or if we have a parent but's a tool, we need to get the lineage for that parent to get to the app ID
	} elsif ($new_parent_type eq '8_1') {
		$lineage = $self->get_lineage(
			'data_code' => $new_parent_data_code,
		);
		($self->{parent_application_id} = $$lineage[1]) =~ s/1_1://;

	# or if we are updating ourself, get our own lineage to get to the app ID
	} elsif ($$form{hidden_fields}{record}) {
		$lineage = $self->get_lineage(
			'data_code' => $$form{hidden_fields}{record},
		);
		($self->{parent_application_id} = $$lineage[1]) =~ s/1_1://;
	}

	# get the app_code_directory for that tool
	$application_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'skip_hooks' => 1,
		'data_codes' => [$self->{parent_application_id}]
	);
	$self->{parent_application_code_dir} = $application_omniclass_object->{data}{app_code_directory};

	# have a nice utility method stashed in datatypes.pm to fetch just the names of the datatypes
	# in the current omnitool admin database; useful for these OT-Admin Datatype sub-classes
	($self->{parent_app_datatypes}, $self->{parent_app_datatypes_keys}) = get_datatype_names($self->{parent_application_id}, $self->{db}, $self->{luggage}{database_name});

	# also have a nice utility method stashed in datatypes.pm to fetch just the names of the fields
	# for the current target datatype, if there is one
	# in the current omnitool admin database; useful for these OT-Admin Datatype sub-classes
	if ($self->{data_code}) {
		$data_code = $self->{data_code};
		($self->{datatype_fields_names}, $self->{datatype_fields_keys}) = get_datatype_field_names($parent_tool_target_datatype, $self->{db}, $self->{luggage}{database_name});
		# if the parent's target datatype is different from mine, allow for a hack to also test against my fields
		# this let's them stuff in sub-data records to complex data views
		if ($self->{data}{target_datatype} ne $parent_tool_target_datatype) {
			($self->{my_datatype_fields_names}, $self->{my_datatype_fields_keys}) = get_datatype_field_names($self->{data}{target_datatype}, $self->{db}, $self->{luggage}{database_name});
			$self->{parent_tool_target_datatype} = $parent_tool_target_datatype; # needed for options renaming
		}
	}

}

# build options for supporting perl module field
sub options_perl_module {
	my $self = shift;

	my ($class_path, $dh, $options,$options_keys);

	# here is where the possible perl modules live
	# where do the modules for this application live?
	$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{parent_application_code_dir}.'/tools/';

	# use our utility method for reading in files from form_maker
	($options,$options_keys) = $self->options_from_directory($class_path,'pm');

    # add in our core / factory tool modules
    foreach $core_class ('standard_delete','standard_data_actions','singleton_data_actions','subform_data_actions','basic_data_view','view_details','basic_calendar','setup_diagram','call_named_method') {
		$$options{$core_class} = $core_class;
		unshift(@$options_keys,$core_class);
	}

    # return results
    return ($options,$options_keys);
}

# also for javascript class
sub options_javascript_class {
	my $self = shift;

	my ($class_path, $dh, $options,$options_keys, $core_class);

	# here is where the possible perl modules live
	# where do the modules for this application live?
	$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{parent_application_code_dir}.'/javascript/';

	# use our utility method for reading in files from form_maker
	($options,$options_keys) = $self->options_from_directory($class_path,'js');

    # return results
    return ($options,$options_keys);
}

# build options fortarget datatype module field
sub options_target_datatype {
	my $self = shift;
	my ($data_code) = @_;
	my (%options, @options_keys, $dt, $lineage, $the_app_datatypes, $the_app_id);

	# we grabbed the names the 'parent_application_datatypes' hash for this tool's
	# containing application up in 'prepare_for_form_fields'
	foreach $dt (@{ $self->{parent_app_datatypes_keys} }) {
		$options{$dt} = $self->{parent_app_datatypes}{$dt}{name};
		push(@options_keys,$dt);
	}

    # return results
    return (\%options,\@options_keys);
}

# set up options for the 'default mode' menu
# basically the code & name of our children under tool_mode_configs
sub options_default_mode {
	my $self = shift;
	my ($data_code) = @_;

	my ($tool_modes_obj, $r, %options, @options_keys);

	# only if we are in update / create-from modes
	if ($data_code) {
		# use an omniclass object to fetch these out
		$tool_modes_obj = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => '13_1',
		);
		$tool_modes_obj->search(
			'search_options' => [{
				'match_column' => 'parent',
				'operator' =>'=',
				'match_value' => '8_1:'.$data_code,
			}],
			'auto_load' => 1,
			'sort_column' => 'name',
		);
		foreach $r (@{ $tool_modes_obj->{records_keys} }) {
			$options{$r} = $tool_modes_obj->{records}{$r}{name};
			push(@options_keys,$r);
		}
	}

	# ship it
	return (\%options,\@options_keys);
}

# link match field
sub options_link_match_field {
	my $self = shift;
	my ($data_code) = @_;
	my (%options, @options_keys, $dt, $dtf, $dt_name);

	if ($data_code) {
		$options{'name'} = 'Name';
		push(@options_keys,'name');

		foreach $dtf (@{ $self->{datatype_fields_keys} }) {
			$options{$dtf} = $self->{datatype_fields_names}{$dtf}{name};
			push(@options_keys,$dtf);
		}

		# if the current tool's datatype is different from it's parent's target DT, then
		# include the fields for both datatypes
		# this let's them stuff in sub-data records to complex data views
		if ($self->{my_datatype_fields_keys} ) {
			# prepend the name of the parent's tools DT in the options made above
			$dt = $self->{parent_tool_target_datatype};
			$dt_name = $self->{parent_app_datatypes}{$dt}{name};
			foreach $dtf (@options_keys) {
				$options{$dtf} = $dt_name.': '.$options{$dtf};
			}

			# and include the my target DT's name in the additional options
			$dt = $self->{data}{target_datatype};
			$dt_name = $self->{parent_app_datatypes}{$dt}{name};

			foreach $dtf (@{ $self->{my_datatype_fields_keys} }) {
				$options{$dtf} = $dt_name.': '.$self->{my_datatype_fields_names}{$dtf}{name};
				push(@options_keys,$dtf);
			}
		}
	}

    # return results
    return (\%options,\@options_keys);
}


sub pre_save {
	my $self = shift;
	my ($args) = @_;

	# $self->{luggage}{params}{name} .= ' - Not as Great as Ginger';
}

sub post_save {
	my $self = shift;
	my ($args) = @_;


	# $self->{luggage}{params}{name} .= ' - Not as Great as Ginger';
}

sub pre_load {
	my $self = shift;
	my ($args) = @_;

	# print "\nwill be pulling out family members from ".$self->{database_name}.'.'.$self->{table_name}."\n";

}

sub post_load {
	my $self = shift;
	my ($args) = @_;

}

sub pre_search {
	my $self = shift;
	my ($args) = @_;

	# $$args{cancel_search} = 1;
}

sub post_search {
	my $self = shift;
	my ($args) = @_;

}


1;
