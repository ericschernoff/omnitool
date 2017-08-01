package omnitool::applications::otadmin::datatypes::datatypes;
# support module for the 'datatypes' datatype object ;)  Meta enough for you?
# provide the options for the 'can contain datatypes' and
# 'Supporting Perl Module' options

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::datatypes::dt = '6_1';

use strict;

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# special new() routines
sub init {
	my $self = shift;

}

# we need a pre-save so we can make suere that the datatype's table name is lower case;
# probably should add this as a feature of omniclass / datatype definitions if it comes up a lot
sub pre_save {
	my $self = shift;

	# i receive the args sent into omniclass
	my ($args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key('table_name',$args);

	# and make it lower case:
	$self->{luggage}{params}{$params_key} = lc($self->{luggage}{params}{$params_key});
}

# we need a prepare_for_form_fields() method to gather information about the
# application which contains this datatype for our options_* hooks
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far

	# declare local vars
	my ($app_datatype, $application_omniclass_object);

	# fortunately, it will be a direct child of the application, so easier to determine
	# than the tools, which can go down several levels
	# if it's a 'create,' we shall already have the parent
	if ($$form{hidden_fields}{new_parent}) {
		($app_datatype,$self->{parent_application_id}) = split /:/, $$form{hidden_fields}{new_parent};

	# otherwise, it's an update, and we should have our 'parent' in $self->{data}
	} else {
		($app_datatype,$self->{parent_application_id}) = split /:/, $self->{data}{metainfo}{parent};

	}

	# let's get the app code directory for this application
	$self->{application_omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'skip_hooks' => 1,
		'data_codes' => [$self->{parent_application_id}]
	);
	$self->{parent_application_code_dir} = $self->{application_omniclass_object}->{data}{app_code_directory};

	# have a nice utility method stashed in datatypes.pm to fetch just the names of the datatypes
	# in the current omnitool admin database; useful for these OT-Admin Datatype sub-classes
	($self->{parent_app_datatypes}, $self->{parent_app_datatypes_keys}) = get_datatype_names($self->{parent_application_id}, $self->{db}, $self->{luggage}{database_name});

}

# build options for containable_datatypes
sub options_containable_datatypes {
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

# build options for supporting perl module field
sub options_perl_module {
	my $self = shift;
	my ($data_code) = @_;

	my ($class_path, $dh, $options,$options_keys);

	# here is where the possible perl modules live
	# where do the modules for this application live?
	$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{parent_application_code_dir}.'/datatypes/';

	# use our utility method for reading in files from form_maker
	($options,$options_keys) = $self->options_from_directory($class_path,'pm');

    # return results
    return ($options,$options_keys);
}

# post_form_validation for create/update form submissions
# make sure there are no datatypes for this applications with the same mysql table name
sub post_validate_form {
	my $self = shift;
	my ($form) = @_; # the complete form structure

	my ($fk, $field, $table_name_conflict, $hostname_conflict, $conflict_type);

	# see if any instances for other applications share this database name
	$self->search(
		'search_options' => [
			{
				'match_column' => 'parent',
				'operator' => '=',
				'match_value' => $$form{new_parent},
			},
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $$form{data_code},
			},
			{
				'match_column' => 'table_name',
				'operator' => '=',
				'match_value' => $self->{luggage}{params}{table_name},
			},
		],
		'auto_load' => 1,
		'skip_hooks' => 1,
	);

	# save off the db conflict, if there is one
	if ($self->{search_results}[0]) {
		$table_name_conflict = $self->{search_results}[0];
		$conflict_type = 'table_name';
	}

	# if there is a conflict, then we have a problem
	if ($conflict_type) {

		# figure out which field this is for
		foreach $fk (@{$$form{field_keys}}) {
			if ($$form{fields}{$fk}{name} eq $conflict_type) {
				$field = $fk;
				last;
			}
		}

		# first, mark the field as error:
		$$form{fields}{$field}{field_error} = 1;

		# then, give a reason in the offending form field
		if ($conflict_type eq 'table_name') {
			$$form{fields}{$field}{error_instructions} = "ERROR: MySQL table name is duplicate to another Datatype: ".$self->{records}{$table_name_conflict}{name};
		}

		# then return a '1'
		return 1;

	# otherwise, we are good
	} else {
		return 0;
	}
}


1;
