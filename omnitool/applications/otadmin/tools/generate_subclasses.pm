package omnitool::applications::otadmin::tools::generate_subclasses;

# tool to generate starter sub-class files for Tools and Datatypes
# called via 'Generate Sub-Class' Inline Action Tool

# leverages files in $OTHOME/code/omnitool/static_files/subclass_templates

use parent 'omnitool::tool';

use strict;

# perform_action() will prepare the values for the 'generate_subclasses.tt' Jemplate
# to display the modal; will present a link to open a new tab to run generate_subclass()
# below directly and get the output
sub perform_action {
	my $self = shift;

	# class type is based on type of record
	my ($class_type, $which);
	if ($self->{target_datatype} eq '6_1') {
		$class_type = 'OmniClass Package';
		$which = 'Datatype';
	} else {
		$class_type = 'Tool.pm Sub-Class';
		$which = 'Tool';
	}

	$self->{json_results}{modal_title} = 'Generate a '.$class_type." for '".$self->{omniclass_object}{data}{name}."' ".$which;
	$self->{json_results}{modal_title_icon} = 'fa-code';
	$self->{json_results}{class_type} = $class_type;
	$self->{json_results}{generate_subclass_link} = $self->{my_base_uri}.'/generate_subclass/'.$self->{display_options}{altcode}.'?client_connection_id='.$self->{client_connection_id};
		if ($self->{luggage}{params}{uri_base}) {
			$self->{json_results}{generate_subclass_link} .= '&uri_base='.$self->{luggage}{params}{uri_base};
		}

	$self->{json_results}{class_type} = $class_type;
	$self->{json_results}{which} = $which;
	$self->{json_results}{record_name} = $self->{omniclass_object}{data}{name};

}

# generate_subclass() actually generates the sub-class based on the data clicked and
# pipes it to the screen; relies on template_process() in the utility_$self->{belt}
sub generate_subclass {
	my $self = shift;

	# declare vars
	my ($applications_omniclass_object, $template_file, $lineage, $parent_application_id);

	# by here we would have the 'altcode' in the display options

	# we need to get an omniclass object and load up that record
	$self->get_omniclass_object( 'dt' => $self->{attributes}{target_datatype} );

	# load up the record for $self->{display_options}{altcode}
	$self->{omniclass_object}->load('altcodes' => [$self->{display_options}{altcode}]);

	# based on the type of sub-class we want to make, we need to set a few parameters

	# are we setting up for a datatype sub-class?
	if ($self->{attributes}{target_datatype} eq '6_1') {
		$self->{table_name} = $self->{omniclass_object}->{data}{table_name};

		$self->{datatype_id} = $self->{omniclass_object}->{records_keys}[0];

		$template_file = 'example_datatype_subclass.tt';

	# otherwise must be a tool.pm sub-class?
	} else {
		# need a short tool name, no spaces and lowercase
		($self->{short_tool_name} = $self->{omniclass_object}->{data}{uri_path_base}) =~ s/\s/_/g;
		$self->{short_tool_name} =~ s/[^A-Z0-9\_]//gi;
		$self->{short_tool_name} = lc($self->{short_tool_name});

		$template_file = 'example_tool_subclass.tt';
	}

	# for either one, we need the parent application's App Code Directory
	# first figure out the containing application
	$lineage = $self->{omniclass_object}->get_lineage(
		'data_code' => $self->{omniclass_object}->{records_keys}[0],
	);
	($parent_application_id = $$lineage[1]) =~ s/1_1://;

	# then load up that application
	$applications_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'skip_hooks' => 1,
		'data_codes' => [$parent_application_id]
	);

	# and isolate the app code directory
	$self->{app_code_directory} = $applications_omniclass_object->{data}{app_code_directory};
	$self->{app_name} = $applications_omniclass_object->{data}{name};

	# book it and cook it!
	$self->{belt}->template_process(
		'template_file' => $template_file,
		'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/subclass_templates/',
		'template_vars' => $self,
		'send_out' => 1
	);

}


1;
