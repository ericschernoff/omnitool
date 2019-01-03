package omnitool::applications::otadmin::datatypes::instances;
# provide the options for the database servers as well as the
# possible time zones

use parent 'omnitool::omniclass';

$omnitool::applications::otadmin::datatypes::instances::dt = '5_1';

use strict;

use omnitool::common::luggage;

# special new() routines
sub init {
	my $self = shift;

}

# figure out my new parent application for omniclass->get_access_roles()
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far

	if ($$form{hidden_fields}{new_parent}) {
		my ($new_parent_type,$new_parent_data_code) = split /:/, $$form{hidden_fields}{new_parent};
		$self->{parent_application_id} = $new_parent_data_code;
	}
}

# nice field for a link to load the instance in Manage Instances
sub field_instance_link {
	my $self = shift;
	my $r;
	foreach $r (@{$self->{records_keys}}) {
		$self->{records}{$r}{instance_link}[0] = {
			'text' => $self->{records}{$r}{hostname},
			'uri' => 'https://'.$self->{records}{$r}{hostname},
		};
		if ($self->{records}{$r}{uri_base_value} && $self->{belt}->{request}) {
			$self->{records}{$r}{instance_link}[1] = {
				'text' => $self->{belt}->{request}->env->{HTTP_HOST}.'/'.$self->{records}{$r}{uri_base_value},
				'uri' => 'https://'.$self->{belt}->{request}->env->{HTTP_HOST}.'/'.$self->{records}{$r}{uri_base_value},
			};
		}
	}
}

# virtual field hook to list the Instance's Database Server and Name
# special field to make browsing through Manage Tools easier
sub field_database_info {
	my $self = shift;
	my ($args) = @_;

	my ($database_server_obj, $db_server, $code, $server_id, %database_server_names, $r);

	# load up the database servers
	$database_server_obj = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '4_1',
		'skip_hooks' => 1,
		'data_codes' => ['all'],
		'load_fields' => 'name,hostname',
	);
	# need a lookup array with just the 'code' part of the primary key
	foreach $db_server (@{ $database_server_obj->{records_keys} }) {
		($code,$server_id) = split /\_/, $db_server;
		$database_server_names{$code} = $database_server_obj->{records}{$db_server}{name}.' / '.$database_server_obj->{records}{$db_server}{hostname};
	}

	# now set the DB info
	foreach $r (@{$self->{records_keys}}) {
		$db_server = $self->{records}{$r}{database_server_id};
		$self->{records}{$r}{database_info} = $database_server_names{$db_server}.': '.$self->{records}{$r}{database_name};
	}
}

# determine if this can be deployed into production
sub build_tool_access_strings {
	my $self = shift;
	my ($args) = @_; # args passed to load()

	# can ony deploy from dev DB's
	foreach my $r (@{$self->{records_keys}}) {
		if ($self->{records}{$r}{database_info} =~ /dev.*: omnitool/i) {
			$self->{records}{$r}{tool_access_strings}{can_deploy_db} = 1;
		}
	}
}

# build options for database server chooser
sub options_database_server_id {
	my $self = shift;
	my ($database_server_obj, $data_code, $code, $created_srvr, $options,$options_keys);

	# load up the database servers via omniclass
	$database_server_obj = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '4_1',
		'skip_hooks' => 1,
	);
	$database_server_obj->search(
		'search_options' => [{
			'match_column' => 'status',
			'operator' => '=',
			'match_value' => 'Active',
		}],
		'sort_column' => 'name',
		'auto_load'	=> 1,
		'skip_hooks' => 1,
	);

	foreach $data_code (@{ $database_server_obj->{records_keys} }) {
		($code,$created_srvr) = split /\_/, $data_code;
		$$options{$code} = $database_server_obj->{records}{$data_code}{name};
		push(@$options_keys,$code);
	}

    # return results
    return ($options,$options_keys);
}

# routine to generate a list of Access Roles/Instance combos to allow users to
# change into this Instance from other Instances; so access roles in other instances only
sub options_switch_into_access_roles {
	my $self = shift;
	my ($data_code) = @_; # primary key for recording updating, if applicable

	my ($access_roles_omniclass, $instances_omniclass, $role, $instance, $app, $options, $options_keys);

	# first, load up all the access roles in this OT Admin DB
	$access_roles_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '12_1',
		'skip_hooks' => 1,
		'skip_metainfo' => 1,
		'load_fields' => 'name,used_in_applications',
		'data_codes' => ['all']
	);

	# second, get the list of instances - separate object just to be sure
	$instances_omniclass = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'skip_hooks' => 1,
		'load_fields' => 'name',
		'data_codes' => ['all']
	);

	# now we load them in, listed for each available instance of the associated applications
	# i *really* hate having three nested foreach's here, but there should not be many of each of these

	# we cycle through all the access roles
	foreach $role (@{ $access_roles_omniclass->{records_keys} }) {
		# and then down into the app's named in 'used in applications'
		foreach $app (split /,/, $access_roles_omniclass->{records}{$role}{used_in_applications}) {
			# and then for all instances
			foreach $instance (@{ $instances_omniclass->{records_keys} }) {
				# SKIP MY OWN ACCESS ROLES
				next if $instance eq $self->{data_code};
				# skip if this instance is not for the desired application
				next if $instances_omniclass->{metainfo}{$instance}{parent} ne '1_1:'.$app;
				# finally, add in the option
				$$options{$instance.'::'.$role} = $access_roles_omniclass->{records}{$role}{name}." from '".$instances_omniclass->{records}{$instance}{name}."'";
			}
		}
	}

	# now prepare the keys, sorted by the option names
	@$options_keys = sort { $$options{$a} cmp $$options{$b} } keys %$options;

	# get an 'Open' in there, at the top
	$$options{'Open'} = 'Open Access';
	unshift(@$options_keys ,'Open');

	# return results
	return ($options,$options_keys);
}


# post_form_validation for create/update form submissions
# make sure there are no instances for other applications have the same DB name or hostname
sub post_validate_form {
	my $self = shift;
	my ($form) = @_; # the complete form structure

	my ($fk, $field, $db_name_conflict, $hostname_conflict, $conflict_type);

	# skip if not in 'create/update' mode
	return 0 if !$$form{new_parent} && !$$form{data_code};

	# commenting out the restriction on using the same database name for now,
	# since we are experimenting with Applications sharing data (but not tools)
=cut
	# see if any instances for other applications share this database name
	$self->search(
		'search_options' => [
			{
				'match_column' => 'parent',
				'operator' => '!=',
				'match_value' => $$form{new_parent},
			},
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $$form{data_code},
			},
			{
				'match_column' => 'database_name',
				'operator' => '=',
				'match_value' => $self->{luggage}{params}{database_name},
			},
		],
		'auto_load' => 1,
		'skip_hooks' => 1,
	);

	# save off the db conflict, if there is one
	if ($self->{search_results}[0]) {
		$db_name_conflict = $self->{search_results}[0];
		$conflict_type = 'database_name';

	# if no DB conflict, make sure there are no conflicting hostnames
	} else {
=cut

	# still make sure there are no conflicting hostnames
	$self->search(
		'search_options' => [
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $$form{data_code},
			},
			{
				'match_column' => 'hostname',
				'operator' => '=',
				'match_value' => $self->{luggage}{params}{hostname},
			},
		],
		'auto_load' => 1,
		'skip_hooks' => 1,
	);
	if ($self->{search_results}[0]) {
		$hostname_conflict = $self->{search_results}[0];
		$conflict_type = 'hostname';
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
		if ($conflict_type eq 'database_name') {
			$$form{fields}{$field}{error_instructions} = "ERROR: DB name is duplicate to another App's Instance: ".$self->{records}{$db_name_conflict}{name};
		} else {
			$$form{fields}{$field}{error_instructions} = "ERROR: Hostname is duplicate to another App's Instance: ".$self->{records}{$hostname_conflict}{name};
		}

		# then return a '1'
		return 1;

	# otherwise, we are good
	} else {
		return 0;
	}
}

# database names have to be all lower case
sub pre_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()
	
	$self->{luggage}{params}{database_name} = lc($self->{luggage}{params}{database_name});
	
}

# routine to run at the end of save().  Good for any clean-up actions or sending notices.
# need to clear the otstatedata.hostname_info_cache Instances cache for this app-instance
sub post_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

	if ($$args{data_code}) {
		$self->{db}->do_sql(qq{
			delete from otstatedata.hostname_info_cache where app_instance_id=?
		},[$$args{data_code}]);
	}
}

# start our routine to run our daily/weekly routines
# this is run via $OTPERL/scripts/backgroun_tasks.pl
# example cron entry:
# 0 23 * * * /opt/omnitool/code/omnitool/scripts/background_tasks.pl OT_ADMIN_INSTANCE_HOSTNAME 5_1 daily_routines TARGET_INSTANCE_ALTCODE
# I like 23, which is 11pm, because the servers are on UTC time and that's 6-9pm in the US
sub daily_routines {
	my $self = shift;

	my ($args) = @_;

	my ($the_class_name, $this_instance_luggage, $status, $message, $new_task_id, $next_task_delay_hours, $end_time, $start_time);

	# get a %$luggage for this instance
	$this_instance_luggage = pack_luggage(
		'username' => $self->{luggage}{username},
		'hostname' => $self->{data}{hostname},
	);

	# find the module's name in perl-space
	$the_class_name = 'omnitool::applications::'.$$this_instance_luggage{session}{app_instance_info}{app_code_directory}.'::common::daily_routines';

	# load in if we can; return error if we fail
	unless (eval "require $the_class_name") {
		return('Error',"Could not import $the_class_name: ".$@);
	}

	# now become that instance-specific class
	bless $self, $the_class_name;

	# execute the daily-tasks method, carefully
	eval {
		($status,$message) = $self->run_daily_routines($args, $this_instance_luggage);
	};
	if ($@) { # hard error
		$status = 'Error';
		$message = 'Eval message: '.$@;
	
	# if no error, record successful run-through
	} else {
		$self->{db}->do_sql(qq{
			replace into otstatedata.instance_daily_routines_runs (instance_data_code, last_run_timestamp)
			values (?, unix_timestamp())
		}, [ $self->{data_code} ]);		
	}

=cut
	Depends on:
	
	CREATE TABLE otstatedata.instance_daily_routines_runs (
	instance_data_code varchar(25) NOT NULL,
	last_run_timestamp int(11) DEFAULT NULL,
	PRIMARY KEY (instance_data_code)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
=cut

	# send back our results
	return ($status,$message);
}

1;
