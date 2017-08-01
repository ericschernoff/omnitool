package omnitool::applications::otadmin::datatypes::applications;
# primarily here to list the available perl module directories

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::applications::dt = '1_1';

# special new() routines
sub init {
	my $self = shift;

	# must keep an associative array of field hooks to the records' keys
	# they populate for tools to work properly
	$self->{field_hooks} = {
		# 'field_birthdate' => 'Birthday',
	};
}

# build options for supporting 'app code directory' field
sub options_app_code_directory {
	my $self = shift;

	my ($class_path, $dh, $options,$options_keys);

	# here is where the possible code directories live
	$class_path = $ENV{OTHOME}.'/code/omnitool/applications/';

	# use our utility method for reading in directories from form_maker
	($options,$options_keys) = $self->options_from_directory($class_path,'dir');

    # return results
    return ($options,$options_keys);
}

# build options for supporting 'ui_template' field
sub options_ui_template {
	my $self = shift;

	my ($template_path, $dh, $options,$options_keys, $their_skeleton_directory, $key, $more_options,$more_options_keys);

	# here is where the possible code directories live
	$template_path = $ENV{OTHOME}.'/code/omnitool/static_files/skeletons/';

	# use our utility method for reading in directories from form_maker
	($options,$options_keys) = $self->options_from_directory($template_path,'tt',1);

	# do they have any available skeletons? (update only)
	if ($self->{data}{app_code_directory}) {
		$their_skeleton_directory = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{data}{app_code_directory}.'/skeletons/';
		($more_options,$more_options_keys) = $self->options_from_directory($their_skeleton_directory,'tt',1);
		# read them in to our main options
		foreach $key (@$more_options_keys) {
			$$options{$key} = $$more_options{$key};
			push (@$options_keys, $key);
		}
	}

    # return results
    return ($options,$options_keys);
}

# options for allowing datatypes to be shared with other applications in this OT Admin database
sub options_share_my_datatypes {
	my $self = shift;
	my ($data_code) = @_;

	my ($application_omniclass_object, $options, $options_keys, $app);

	# get a second omniclass object to pull in applications, so not to mess up the one we are in
	$application_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'skip_hooks' => 1,
		'data_codes' => ['all'],
		'load_fields' => 'name',
		'sort_column' => 'name',
	);

	# 'None' is first option
	$$options{None} = 'None';
	push(@$options_keys,'None');

	# all the other apps in this OT Admin database
	foreach $app (@{ $application_omniclass_object->{records_keys} }) {
		next if $app eq $data_code; # not myself
		push(@$options_keys, $app);
		$$options{$app} = $application_omniclass_object->{records}{$app}{name};
	}

    # return results
    return ($options,$options_keys);
}

# post-save operations: make sure their app code directory is proper
sub post_save {
	my $self = shift;
	my (%args) = @_;

	# get ahold of our new record
	$self->load_last_saved_record();

	my ($class_path, $sub_dir);

	# our new app_code_directory
	$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{data}{app_code_directory};

	# cycle through the ones we might need
	foreach $sub_dir ('common','datatypes','javascript','jemplates','scripts','tools','skeletons') {
		# and if it does not exist, create it
		if (!(-d $class_path.'/'.$sub_dir)) {
			mkdir($class_path.'/'.$sub_dir, 0755);
		}
	}

}



1;
