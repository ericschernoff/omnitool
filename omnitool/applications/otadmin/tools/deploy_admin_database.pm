package omnitool::applications::otadmin::tools::deploy_admin_database;
# this tool allows ot admins to copy omnitool_* databases from dev to prod

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;
use File::Slurp;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to prepare a form data structure and load it into $self->{json_results}
sub generate_form {
	my $self = shift;

	my ($instance, $data_code, $parent, $search_term);

	$self->{json_results}{form} = {
		'title' => 'Deploy '.$self->{omniclass_object}->{data}{name} .' To Production',
		'instructions' => 'BE CAREFUL.  Choosing a Target Instance and clicking "Deploy OT Admin Database" will overwrite the '.
			$self->{omniclass_object}->{data}{database_name}. ' for that Instance!',
		'submit_button_text' => 'Deploy OT Admin Database',
		'field_keys' => [1,2],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Source Instance',
				'name' => 'source_instance',
				'field_type' => 'just_text',
				'preset' => $self->{omniclass_object}->{data}{name},
			},
			2 => {
				'title' => 'Target Instance',
				'name' => 'target_instance',
				'field_type' => 'single_select',
			},
		}
	};

	# in case we end up overwriting
	$data_code = $self->{omniclass_object}->{data_code};
	$parent = $self->{omniclass_object}->{data}{metainfo}{parent};

	# let's look for the 'Prod' version of this DB
	($search_term = $self->{omniclass_object}->{data}{name}) =~ s/\s\(Dev\)$//i;

	# now load up the instances under this parent
	$self->{omniclass_object}->search(
		'search_options' => [
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $data_code,
			},
			{
				'table_name' => 'metainfo',
				'match_column' => 'parent',
				'match_value' => $parent,
			},
			{
				'match_column' => 'name',
				'operator' => 'like',
				'match_value' => $search_term,
			},
		],
		'auto_load' => 1,
	);
	foreach $instance (@{ $self->{omniclass_object}{records_keys} }) {
		# can't choose myself or a dev DB
		next if $instance eq $data_code || $self->{omniclass_object}{records}{$instance}{database_info} =~ /dev/i;
		$self->{json_results}{form}{fields}{2}{options}{$instance} = $self->{omniclass_object}{records}{$instance}{name};
		push(@{$self->{json_results}{form}{fields}{2}{options_keys}}, $instance);
	}

}

# routine to deploy the target otadamin instance's database to the selected otadmin instance
# (the target is one we clicked on to get to the form, and the selected one is the one we chose in the form)
# PRESUMES that the mysql password is the same on the source/target server and that this web server has the MySQL client package
sub perform_form_action {
	my $self = shift;

	my ($username, $target_instance, $target_instance_name, $target_dbname, $target_database_server, $table, $source_instance_name, $source_dbname, $source_database_server, $password, $mysqldump_file, $dump_command, $credentials, $load_command, $right_db_obj, $target_hostname);

	# get the credentials
	$credentials = read_file($ENV{OTHOME}.'/configs/dbinfo.txt');
	if ($credentials !~ /\n/) { # it's been obfuscated with utility_belt::stash_some_text() via installation
		$credentials = pack "h*", $credentials;
	}
	($username,$password) = split /\n/, $credentials; # notice the format; two-line field, username first, then pw next line

	# the source DB info is easy, becauase we have already loaded that database
	$source_database_server = $self->{belt}->get_instance_db_hostname($self->{omniclass_object}->{data_code}, $self->{luggage}{omnitool_admin_database}, $self->{db});
	$source_dbname = $self->{omniclass_object}->{data}{database_name};
	$source_instance_name = $self->{omniclass_object}->{data}{name};

	# load up the info for the target
	$target_instance = $self->{luggage}{params}{target_instance};
	$self->{omniclass_object}->load(
		'data_codes' => [$target_instance],
		'skip_hooks' => 1,
		'load_fields' => 'name,database_name,hostname',
	);

	# target database server / dbname
	$target_database_server = $self->{belt}->get_instance_db_hostname($target_instance, $self->{luggage}{omnitool_admin_database}, $self->{db});
	$target_dbname = $self->{omniclass_object}->{records}{$target_instance}{database_name};
	$target_instance_name = $self->{omniclass_object}->{records}{$target_instance}{name};
	$target_hostname = $self->{omniclass_object}->{records}{$target_instance}{hostname};

	# where the mysqldump file will go
	$mysqldump_file = $ENV{OTHOME}.'/tmp/'.$source_dbname.'.sql';

	# now construct our command to safely transfer the omnitool admin database, without breaking
	# background_tasks, tools_display_options_cached, tools_display_options_saved, and user_api_keys_metainfo
	$dump_command = 'mysqldump -h'.$source_database_server.' -u'.$username.' -p'.$password.' --single-transaction';
	foreach $table ('background_tasks','tools_display_options_cached','tools_display_options_saved','user_api_keys','user_api_keys_metainfo') {
		$dump_command .= ' --ignore-table='.$source_dbname.'.'.$table;
	}
	$dump_command .= ' '.$source_dbname.' -r '.$mysqldump_file;

	# execute that command -- don't tell ron about this.  i wish there was a nice DBD::MySQL::MySQLDump module
	system($dump_command);

	# and now construct the command to read it in
	$load_command = 'mysql -h'.$target_database_server.' -u'.$username.' -p'.$password.' '.$target_dbname.' < '.$mysqldump_file;

	# execute that command -- don't tell ron about this.  i wish there was a nice DBD::MySQL::MySQLDump module
	# Ron, if you're reading this, the whole point of this tool is to make this process safer by avoiding a
	# manual process which would be rife with mistakes
	system($load_command);

	# we will want to clear out the datatype hash and sessions for our target instance, so we shall need the db handle
	$right_db_obj = $self->{belt}->get_instance_db_object($target_instance, $self->{db}, 'omnitool');

	# now clear the datatype hashes for that target instance's database server
	$right_db_obj->do_sql(
		'delete from otstatedata.datatype_hashes'
	);
	# and the sessions for that target instance's database server
	$right_db_obj->do_sql(
		'delete from otstatedata.omnitool_sessions'
	);
	# have to do all because it is tough to narrow down to one app

	# send this upon successful submit
	$self->{json_results}{form_was_submitted} = 1;

	# if you want to convert to a pop-up notice
	# $self->{json_results}{title} = 'Records Have Been Re-Ordered';
	$self->{json_results}{title} = $source_instance_name.' DB was deployed to '.$target_instance_name;
	$self->{json_results}{show_gritter_notice} = 1;

	# otherwise, fill in some values in $self->{json_results} for your Jemplate
}


1;

