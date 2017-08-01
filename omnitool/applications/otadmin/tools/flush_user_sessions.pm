package omnitool::applications::otadmin::tools::flush_user_sessions;
# action to allow the admins to flush a single user's session, either just
# for one instance or across all instances

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# method to perform the flushes
sub perform_form_action {
	my $self = shift;

	# cancel if no target_username provided (validation should handle this)
	return if !$self->{luggage}{params}{target_username};

	my ($instances_omniclass, $instance_name, $target_instance, $right_db_obj);

	# for-instance defaults to all
	$self->{luggage}{params}{for_instances} ||= 'All Instances';

	$instances_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'skip_hooks' => 1,
		'load_fields' => 'name,hostname',
		'data_codes' => ['all']
	);

	# how about we just do it ;)
	foreach $target_instance (@{ $instances_omniclass->{records_keys} }) {
		# skip if they don't want all and this isn't what they asked for
		next if $self->{luggage}{params}{for_instances} ne 'All Instances' && $self->{luggage}{params}{for_instances} ne $target_instance;
		
		# get the proper DB object
		$right_db_obj = $self->{belt}->get_instance_db_object($target_instance, $self->{db}, $self->{luggage}{database_name});

		# and flush the sessions
		$right_db_obj->do_sql(
			'delete from otstatedata.omnitool_sessions where hostname=? and username=?',
			[$instances_omniclass->{records}{$target_instance}{hostname}, $self->{luggage}{params}{target_username}]
		);	

		# let's clear the hostname_info_cache table as well, incase the hostnames or uris changed
		$right_db_obj->do_sql('delete from otstatedata.hostname_info_cache');
	}	

	# prepare a nice message by updating the form
	
	# flush for all instances?
	if ($self->{luggage}{params}{for_instances} eq 'All Instances') {
		
		$self->{json_results}{form}{instructions} = qq{
			Flushed Sessions Across All Instances for $self->{luggage}{params}{target_username}.
		};
			
	# flush for just one instance?
	} else {
		# resolve that sucker
		$target_instance = $self->{luggage}{params}{for_instances};
		$target_instance = $instances_omniclass->{records}{$target_instance}{name};
		
		$self->{json_results}{form}{instructions} = qq{
			Flushed Session in '$target_instance' for $self->{luggage}{params}{target_username}.
		};

	}
	
	# make sure form displays again
	$self->{redisplay_form} = 1;
	
}

# prepare the form to allow them to name the user and select the target instance
sub generate_form {
	my $self = shift;

	my ($app_instances, $app, $hostname, $inst);

	$self->{json_results}{form} = {
		'title' => 'Flush Sessions for a User',
		'submit_button_text' => 'Flush User Session(s)',
		'field_keys' => [1,2],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Username for Target User',
				'name' => 'target_username',
				'field_type' => 'short_text', 
				'is_required' => 1,
				'preset' => $self->{luggage}{params}{target_username},
			},
			2 => {
				'title' => 'For Application Instance(s)',
				'name' => 'for_instances',
				'field_type' => 'radio_buttons', 
				'preset' => $self->{luggage}{params}{for_instances},
				'options' => {
					'All Instances' => 'Across All Instances',
				},
				'options_keys' => ['All Instances']
			},
		}
	};	

	# grab the app / instance combos for this omnitool admin db
	$app_instances = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '1_1',
		'data_codes' => ['all'],
		'tree_mode' => 1,
		'tree_datatypes' => '5_1',
		'return_extracted_data' => 1,
	);	

	# now read them in from this plain hash
	foreach $app (@{ $$app_instances{records_keys} }) {

		foreach $inst (@{ $$app_instances{records}{$app}{instances}{records_keys} }) {
			$self->{json_results}{form}{fields}{2}{options}{$inst} = $$app_instances{records}{$app}{name}.' / '.$$app_instances{records}{$app}{instances}{records}{$inst}{name};
			push(@{ $self->{json_results}{form}{fields}{2}{options_keys} }, $inst);		
		}

	}
	

}

1;
