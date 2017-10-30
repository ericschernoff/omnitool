package omnitool::common::session;

# please see pod documentation included below
# perldoc omnitool::common::session

$omnitool::common::session::VERSION = '6.0';

# we keep the serialized/cached hash in a mysql table, so we will
# need these modules to get it out of hock
use Storable qw( nfreeze thaw );

# time to grow up
use strict;

# create ourself and connect to the database
sub new {
	my $class = shift;

	my ($required_access_roles, $appinst, $access_role, $instance_id, $access_role_id, $correct_db, $app_instance_info, $appinst_keys, $application_id, $instance_id, $now, $ready_session, $self, $session_code, $their_name, $hard_set_access_roles, %args, $app_code_directory, $class_name);

	# grab args
	(%args) = @_;
	# looks like:
	#	'username' => $username,
	#	'db' => $db,
	#	'hostname' => $instance_hostname, --> required if not provided in app_instance
	#	'app_instance' => $instance_primary_key or $hostname,
	#	'belt' => a utility_belt.pm object; not required for this module but use(d|ful) to the custom_session.pm modules
	#	'code' => 'new' or 'primary_key_value' or blank

	# really must have a database connection, username, omnitool admin database and instance.
	if (!$args{db} || !$args{username} || (!$args{app_instance} && !$args{hostname})) {
		# would love to use mr. zebra, but he won't be available just yet
		print "ERROR: Must send a username ($args{username}), and instance ID ($args{app_instance} or $args{hostname}), and a database object ($args{db}) to fetch a session.\n";
		exit;
	}

	# if the sent instance is a hostname, convert to the primary key
	if ($args{app_instance} =~ /[a-z]/i) {
		$args{hostname} = lc($args{app_instance});
		$args{app_instance} = '';
	# can't be too careful
	} else {
		$args{hostname} = lc($args{hostname});
	}
	if (!$args{app_instance}) {
		($args{app_instance}) = $args{db}->quick_select(qq{
			select concat(code,'_',server_id) from instances where hostname=?
		},[$args{hostname}]);
	}

	# pull out the saved session for this user/instance -- make sure it has been accessed in the past 24 hours
	# allow developers to have a fresh session every time if they set a 'FORCE_FRESH_SESSIONS' var
	# in the startup command -- never for prod!
	if ($ENV{OT_COOKIE_ID} eq 'prod' || !$ENV{FORCE_FRESH_SESSIONS}) {
		($session_code,$ready_session) = $args{db}->quick_select(qq{
			select code,session from otstatedata.omnitool_sessions
			where username=? and app_instance=? and hostname=?
			and last_access > (unix_timestamp()-86400)
			order by code limit 1
		},[$args{username},$args{app_instance}, $args{hostname}]);
	}

	if ($ready_session) {
		$self = thaw($ready_session);

		# re-bless the session
		$self = bless $self, $class;

		$self->{code} = $session_code;

		# track last access...may be a bottleneck and subject to removing later
		$args{db}->do_sql(qq{update otstatedata.omnitool_sessions set last_access=unix_timestamp() where code=?},[$session_code]);

	# otherwise, we will rebuild it and save it off
	} else {

		# no more than every 100 seconds, clear any sessions
		# which were last accessed more than 24 hours ago
		$now = time();
		if ($now =~ /40$/) {
			$args{db}->do_sql(qq{
				delete from otstatedata.omnitool_sessions
				where last_access < (unix_timestamp()-86400)
			});
		}

		# continue with building the session

		# grab the information on the applications & instances in one fell swoop
		($app_instance_info,$appinst_keys) = $args{db}->sql_hash(qq{
			select concat(i.code,'_',i.server_id), concat(a.code,'_',a.server_id), i.hostname, i.database_server_id,
			ds.hostname, i.database_name, i.contact_email, a.contact_email, a.appwide_search_function, a.appwide_search_name,
			a.appwide_quickstart_tool_uri, i.name, i.access_roles, i.switch_into_access_roles, i.file_storage_method, i.file_location,
			a.ui_template, a.ui_navigation_placement, a.ui_ace_skin, i.ui_logo,
			a.lock_lifetime, a.app_code_directory, a.description, i.description, i.uri_base_value
			from instances i, applications a, database_servers ds
			where i.parent=concat('1_1:',a.code,'_',a.server_id) and i.database_server_id=ds.code
			and i.status=? and a.status=? and ds.status=? order by i.name
		},(
			'names' => ['application_id','hostname','database_server','database_hostname','database_name','inst_contact',
						'app_contact','appwide_search_function','appwide_search_name','appwide_quickstart_tool_uri','inst_name',
						'access_roles','switch_into_access_roles','file_storage_method','file_location',
						'ui_template','ui_navigation_placement','ui_ace_skin','ui_logo',
						'lock_lifetime','app_code_directory','app_description','inst_description','uri_base_value'],
			'bind_values' => ['Active','Active','Active']
		));

		# if we wanted to limit it to just one
		# concat(i.code,'_',i.server_id)='$args{app_instance}' and

		# instance name used to be 'application name / instance name,' but i decided the instances should be
		# a more precise reflection of their parent applications

		# isolate the instance and application ID's for the desired instance / sanity
		$instance_id = $args{app_instance};
		$application_id = $$app_instance_info{$instance_id}{application_id};

		# instance description overrides app description; this is just for UI
		$$app_instance_info{$instance_id}{inst_description} ||= $$app_instance_info{$instance_id}{app_description};
		$$app_instance_info{$instance_id}{app_description} = ''; # keep it light and tight

		# defaults for UI options
		$$app_instance_info{$instance_id}{ui_navigation_placement} ||= 'Left Side';
		$$app_instance_info{$instance_id}{ui_ace_skin} ||= 'no-skin';

		# if there is no app instance found, we have a problem and need to report back upstream
		# to get the UI class to display the no-access message
		if (!$$app_instance_info{$instance_id}{hostname}) {
			# send the instruction to show the error screen; this exact has is used in error_no_access.tt
			return { 'NO_APP_INSTANCE_FOUND' => 1 };
		}

		# what is their name & hard-set access roles?
		($their_name,$hard_set_access_roles) = $args{db}->quick_select(qq{
			select name,hard_set_access_roles from omnitool_users where username=?
		},[$args{username}]); # mainly for ui

		# put it together
		$self = bless {
			'username' => $args{username},
			'user' => $args{username}, # because no one is perfect
			'their_name' => $their_name,
			'hard_set_access_roles' => $hard_set_access_roles,
			'created' => time(),
			'app_instance' => $instance_id,
			'application_id' => $application_id,
			'app_instance_info' => $$app_instance_info{$instance_id}, # too lazy not to use sql_hash
			'all_app_instance_info' => $app_instance_info, # all of it, so object_factory is more useful, cross-app
			'appinst_keys' => $appinst_keys,
		}, $class;

		# now we need to see if there is a 'custom_session' module for the selected instance's application
		# now the module's name in perl-space
		$app_code_directory = $$app_instance_info{$instance_id}{app_code_directory}; # sanity
		$class_name = 'omnitool::applications::'.$app_code_directory.'::custom_session';

		# try to load it in and bless myself into it to access the methods with all my data imported
		if (eval "require $class_name") { # phew, loaded ;)
			bless $self, "$class_name";  # see notes below about this, please

			# we need to be 100% sure we have a database object for the instance's DB server,
			# without over-writing the $db object we already received, as we want to store
			# the session in the local DB server, even if we are going remote for the app DB
			$correct_db = $self->get_instance_db_object($args{db});

			# first see if there is a fun extend_session_info() method to grow our session info
			# for this application/instance -- un-related to access info bits
			if ($self->can('extend_session_info')) {
				$self->extend_session_info($correct_db,$args{belt});
			}

			# now try to run fetch_access_info()
			if ($self->can('fetch_access_info')) {
				$self->fetch_access_info($correct_db,$args{belt});
				# $self->{access_info} should have some data now
			}
		#} else {
		#	print $@."\n";
		}

		# now we use find_access_roles() below to load and evaluate the access roles and see which
		# roles this user qualifies for --> tagging in $self->{access_roles}
		$self->find_access_roles($args{db},$args{belt});

		# let's make sure they have access to this instance
		if (!( $self->check_access( $self->{app_instance_info}{access_roles} ) )) {
			$self->{no_access} = 1; # pack_luggage.pm will know what to do with this
		}

		# see which other instances they have access to change into from this instance
		foreach $appinst (@{$self->{appinst_keys}}) {
			# Blank or 'Open' means totally open
			if (!$self->{all_app_instance_info}{$appinst}{switch_into_access_roles} || $self->{all_app_instance_info}{$appinst}{switch_into_access_roles} =~ /Open/) {
				$self->{all_app_instance_info}{$appinst}{has_switch_into_access} = 1;

			# otherwise, test it out
			} else {
				$required_access_roles = 'Z_Z'; # start with fresh list / make sure they have to qualify against one of these
				foreach $access_role (split /,/, $self->{all_app_instance_info}{$appinst}{switch_into_access_roles}) {
					# format is 'instance_id::role_id'
					($instance_id,$access_role_id) = split /::/, $access_role;
					# only test access role requirements tied to this exact instance
					next if $instance_id ne $self->{app_instance};
					$required_access_roles .= ','.$access_role_id;
				}

				# just note with a '1' if they have the access
				$self->{all_app_instance_info}{$appinst}{has_switch_into_access} = $self->check_access($required_access_roles);

			}
		}

		# if they do have access to this instance, use the recursive method below to get
		# or tree-hash of tools and the 'uris_to_tools' resolution hash
		if (!$self->{no_access}) {
			($self->{tools_keys}) = $self->fetch_the_tools($args{db},'1_1:'.$application_id);
			# 'uris_to_tools' was added right into $self->{uris_to_tools} since it's just $a => $b
		}

		# don't need this
		$self->{table_columns} = '';

		# now save it out
		$self->save($args{db});
	}

	# ship it
	return $self;
}

# utility method to fetch the proper DB object for this instance, for the hook
# methods to work properly; this might replace utility_belt::get_instance_db_object() later
# The reason this has to work precisely this way is because we may be saving this session
# to the local database server but using a remote server for the application/instance DB
sub get_instance_db_object {
	my $self = shift;
	my ($db) = @_; # need to receive the database object separately
	my ($correct_db, $proper_otadmin_db);

	if ($db->{server_id} ne $self->{app_instance_info}{database_server}) {
		$correct_db = omnitool::common::db->new($self->{app_instance_info}{database_hostname});
		# make sure it is connected to the current / proper omnitool admin database for this instance
		$proper_otadmin_db = $db->quick_select('select DATABASE()');
		$correct_db->{dbh}->do(qq{use $proper_otadmin_db});
	} else {
		$correct_db = $db;
	}

	return $correct_db;
}

# method to serialize this object and save to our database / data store
# supports update now, for possibly keeping tools' search states here too ;)
sub save {
	my $self = shift;
	# grab my args / declare my vars
	my ($random_string, $db,$remote_ip,$serialized_session,$instance_list);
	($db) = @_; # need database connection, but cannot store in $self

	# use nfreeze to allow use across different machines / platforms
	$serialized_session = nfreeze($self);

	if ($self->{code}) { # we are updating
		$db->do_sql(qq{
			update otstatedata.omnitool_sessions set last_access=unix_timestamp(), session=? where code=?
		}, [$serialized_session, $self->{code}]);

	} else { # add a new one

		# clear any previous sessions for this combo
		$db->do_sql(qq{
			delete from otstatedata.omnitool_sessions where username=? and app_instance=? and hostname=?
		},[$self->{username}, $self->{app_instance}, $self->{hostname}]);

		# save the new session into the database
		$db->do_sql(qq{insert into otstatedata.omnitool_sessions (username,last_access,app_instance,hostname,session)
			values (?,unix_timestamp(),?,?,?)},
		[$self->{username}, $self->{app_instance}, $self->{app_instance_info}{hostname}, $serialized_session]);

		# tell me the unique code of the session
		$self->{code} = $db->{last_insert_id};
	}
}

# method to load the access roles, test the matches and hard-set statuses, and determine this user's roles
# this builds an easy hash in {access_roles} so that $self->{access_roles}{$role} = 1 if they have that $role;
sub find_access_roles {
	my $self = shift;

	my ($db, $belt) = @_; # need database connection, but cannot store in $self
	my ($hard_set_role, $hsr_instance, $hsr_role_id, $access_roles,$roles_keys, $role, $match_hash_key, $match_value, $match_operator);

	# start with the hard-set roles
	foreach $hard_set_role (split /,/, $self->{hard_set_access_roles}) {
		# format is 'instance_id::role_id'
		($hsr_instance,$hsr_role_id) = split /::/, $hard_set_role;
		# only add in if for this instance
		$self->{access_roles}{$hsr_role_id} = 1 if $hsr_instance eq $self->{app_instance};
	}

	# everyone has the 'Open' role
	$self->{access_roles}{Open} = 1;

	# load in the access roles for this app, with their match rules
	($access_roles,$roles_keys) = $db->sql_hash(qq{
		select concat(code,'_',server_id),match_hash_key,match_operator,match_value
		from access_roles where used_in_applications regexp ?
	},( 'bind_values' => [ '(^|,)'.$self->{application_id}.'(,|$)' ] ) );

	# cycle through, skipping the ones we already have
	foreach $role (@$roles_keys) {
		next if $self->{access_roles}{$role};

		# skip if either the 'match_hash_key' or 'match_value' is blank
		next if !$$access_roles{$role}{match_hash_key} || !$$access_roles{$role}{match_value};

		# sanity-ize our two test values
		$match_hash_key = $$access_roles{$role}{match_hash_key};
		$match_value = $$access_roles{$role}{match_value};
		$match_operator = $$access_roles{$role}{match_operator};

		# proceed based on operator; equals / not equals is easy
		if ($match_operator eq 'Equals' && $self->{access_info}{$match_hash_key} eq $match_value) {
			$self->{access_roles}{$role} = 1;
		} elsif ($match_operator eq 'Not Equals' && $self->{access_info}{$match_hash_key} ne $match_value) {
			$self->{access_roles}{$role} = 1;
		} elsif ($match_operator eq 'Contains' && $self->{access_info}{$match_hash_key} =~ /$match_value/i) {
			$self->{access_roles}{$role} = 1;
		} elsif ($match_operator eq 'Does Not Contain' && $self->{access_info}{$match_hash_key} !~ /$match_value/i) {
			$self->{access_roles}{$role} = 1;
		}
	}
}

# method to test their access roles against a comma-list of access roles
# these should come straight out of the tools.access_roles columns in the omnitool admin DB
sub check_access {
	my $self = shift;

	# required arg is the comma,list,of,acess,roles,to,test,against
	my ($access_roles_list) = @_;

	# if it is an empty list, that's as good as 'open'
	return 1 if !$access_roles_list;

	my ($role);
	foreach $role (split /,/, $access_roles_list) {
		if ($role eq 'Open' || $self->{access_roles}{$role}) { # it's open or we found it in their list, so return positively
			return 1;
		}
	}

	# there is probably a very nice one-liner to do that, but I am very old

	# still here?  must have found nothing
	return 0;
}

# recursive method to get the tree of tools under this application
sub fetch_the_tools {
	my $self = shift;
	# grab the args: DB handle, current parent, and current place in the tree we're building
	my ($db,$parent,$parent_uri_path_base) = @_;

	my ($tool_key, $tools, $tools_keys, $uri_path_base, $table_name, $this_sorting, $allowed_tools_keys, $tool_config_hash,$tool_configs_keys, $config_key);

	# we need the list of columns for the tool tabe and its subordinate tables
	# only do this once
	if (!$self->{table_columns}{tools}{columns}) {
		$self->get_tools_table_columns($db);
	}

	# fetch from the database
	($tools,$tools_keys) = $db->sql_hash('select '.$self->{table_columns}{tools}{columns}.qq{ from tools
		where parent=? order by priority
	},( 'bind_values' => [$parent] ) );

	foreach $tool_key (@$tools_keys) {
		# first off, check their access - if there are access roles defined for this tool
		next if !( $self->check_access($$tools{$tool_key}{access_roles}) );
		# just skip if it's non-open and they don't have one of the roles; this will prevent access to subordinate tools

		# expressively forbid the creation of applications in the core omnitool admin database
		next if $self->{app_instance} eq '1_1' && $parent eq '8_1:2_1' && $tool_key eq '26_1';

		# first, work on our uri-to-toolID hashref
		if ($parent_uri_path_base) { # if set, coming in from a parent tool, and we will want a unique uri representing this level
			$$tools{$tool_key}{uri_path_base} = $parent_uri_path_base.'/'.$$tools{$tool_key}{uri_path_base};
		}
		$uri_path_base = $$tools{$tool_key}{uri_path_base};
		$self->{uris_to_tools}{$uri_path_base} = $tool_key;

		# grab the configuration options for this tool
		# we shall stash this under $$tools_hash{configs} so it does not
		# cloud up our navigation structure but is easy to retrieve
		foreach $table_name (@{ $self->{tool_config_tables} }) {
			# if there is a 'priority' column, we need to sort these records from that
			if ($self->{table_columns}{$table_name}{columns} =~ /priority/) {
				$this_sorting = 'priority';
			} else { # first-in sorting
				$this_sorting = 'code';
			}

			# grab them out
			($tool_config_hash,$tool_configs_keys) = $db->sql_hash(
				'select '.$self->{table_columns}{$table_name}{columns}.
				qq{ from $table_name where parent=? order by $this_sorting},
			( 'bind_values' => ['8_1:'.$tool_key] ) );

			# if it is a mode view config, it can have access roles
			if ($table_name eq 'tool_mode_configs') {
				foreach $config_key (@$tool_configs_keys) {
					# skip if they don't have access
					next if !( $self->check_access($$tool_config_hash{$config_key}{access_roles}) );

					# still here? add it in
					$self->{tool_configs}{$tool_key}{$table_name}{$config_key} = $$tool_config_hash{$config_key};
					push(@{ $self->{tool_configs_keys}{$tool_key}{$table_name} }, $config_key);
				}

			# all other config types just go in
			} else {
				$self->{tool_configs}{$tool_key}{$table_name} = $tool_config_hash;
				$self->{tool_configs_keys}{$tool_key}{$table_name} = $tool_configs_keys;
			}
		}

		# if this is not a message display tool and they do not have access to any tool mode views,
		# then we need to skip and not include this tool
		next if $$tools{$tool_key}{tool_type} ne 'Action - Message Display' && !( $self->{tool_configs_keys}{$tool_key}{tool_mode_configs}[0] );

		# still here?  add the tool definition to the hash
		$self->{tools}{$tool_key} = $$tools{$tool_key};

		# now see if there are any subordinate tools
		$self->fetch_the_tools($db,'8_1:'.$tool_key,$uri_path_base);

		# build a second array ref of the keys for the tools we actually have access to, for below
		push(@$allowed_tools_keys,$tool_key);
	}

	# set the subordinate tools for this tool
	if ($parent =~ /8_1:/) {
		$parent =~ s/8_1://;
		$self->{tools}{$parent}{child_tools_keys} = $allowed_tools_keys;
	} else {
		$self->{tools_keys} = $allowed_tools_keys;
	}
}

# method to grab the table fields from for tools and tools-configs tables for use in fetch_the_tools()
# we have to do this here because we don't have the datatypes_hash yet
# meant to do this just one and load up a $self=>{tools_tables} hash
sub get_tools_table_columns {
	my $self = shift;
	# need this
	my ($db) = @_;

	# declare vars
	my ($containable_datatypes, $datatypes_list, $dt, $code,$server_id, $table_name, $skip_ot_keys);

	# get the containtable datatypes for tools
	($containable_datatypes) = $db->quick_select(qq{
		select containable_datatypes from omnitool.datatypes where code=? and server_id=?
	},[8,1]);

	$datatypes_list = '8_1,'.$containable_datatypes;

	# rest is much less hard-coded, so it can extended-upon later
	foreach $dt (split /,/, $datatypes_list) {
		# don't have the utility_bet yet, so do it the old fashioned way
		($code,$server_id) = split /_/, $dt;

		# get the table_name
		($table_name) = $db->quick_select(qq{
			select table_name from omnitool.datatypes where code=? and server_id=?
		},[$code,$server_id]);

		# get our colunns - removing $skip_ot_keys from subordinate tables
		#if ($table_name eq 'tools') { # for the main table we want concat(code,'_',server_id),parent,
		#	$skip_ot_keys = 0;
		#} else { # otherwise, just need the facts
		#	$skip_ot_keys = 1;
		#}

		# at least we have the db object for this
		$self->{table_columns}{$table_name}{columns} = $db->grab_column_list('omnitool',$table_name,$skip_ot_keys);

		# list of tables, exclude 'tools'
		push (@{ $self->{tool_config_tables} }, $table_name) if $table_name ne 'tools';
	}
}

# method to clear out a session (best to use a script, as the session would live through the end of the page run)
sub close {
	my $self = shift;
	# grab database handle
	my ($db) = @_;
	# clear it out
	$db->do_sql(qq{delete from otstatedata.omnitool_sessions where code=?},[$self->{code}]);
}

# all done
1;

__END__

=head1 omnitool::common::session

This module allows us to create and store/retrieve user sessions.  The point of these sessions is to cache all the
details for tools to which the users have access, both for building navigation and for calling the correct subroutines.

We use Storable to nfreeze/thaw the saved hash once it's built, and we have a session-flusher in the OmniTool Admin
Tools for clearing these sessions after we've made any changes to the user records, tools or access lists.  Sessions
will be automatically cleared if the user has not accessed the system in the past 24 days.

We will make this an object for the sake of having a save() method for updating the session along the way.  In prior
versions of OmniTool, the session was really a glob of access rights info more than a place to store state information
between requests.  That's because it was just really built once, after a pause in access, but now we can update it
along the way.  ** If you do that, be sure to send a $db object for this Plack server's default database server.**

Notice that we have 'instances' of Applications, which represent combinations of URL hostnames and target
database server ID's for an Application.  This would allow Comapny A and Company B to have separate hostnames
and data-sets but share the same Datatypes and Tools.  This is further enhanced by the fact that we allow for
multiple OmniTool Admin databases, which means the $db object must be connected to the proper database in order to
create the session properly.  The 'pack_luggage()' subroutine handles that for us when creating the $db object,
and you will want to take this into account if creating a session elsewhere for any reason.

Each session will be assigned to a particular Application Instance, so a user who is able to access multiple
Applications or Instances will have a separate session for each one.  I started out going with just one session
per user, but quickly realized that would make sessions more difficult to deal with.  Also, it will be simpler
to flush sessions for specific Application Instances when administrative changes are made.  Specify the
Instance via the 'hostname' arg to new(), which should be the value in instances.hostname for the desired
Instance.

BTW, this is separated from the otstatedata.authenticated table, which confirms that the user has successfully
authenticated, and that ties to a browser cookie as well as their client IP address.  We removed all that stuff
from this sessions code, limiting the authenication bits to login_system.pm.  The session is available to users
between browsers/clients.

Also note that otstatedata is the one database which is not meant to be replicated among the database servers,
but it is OK for us to use the default DB server for this Apache server for saving/retrieving user sessions.
Going to a foreign DB server should generally be an exception, and you will want this session process to
be quick.  Note that if you use %$luggage to get this, that will always be the case.

=head2 Access Control via Access Roles

To manage / control access to the various Tools, Tool Modes, and Application Instances, we have
Access Roles.  For creating/updating these, we have the 'Manage Access Roles' tool in the
OmniTool Admin UI, which saves to the 'access_roles' table in your OmniTool Admin DB's. Once you
have these set up, you can select them in the 'Access Roles' field in the create/update
forms for Tools, Tool Modes, and Application Instances.

Access Roles are set to be useable in Applications, and user membership is controlled per-Instance.
OmniTool User accounts are system-wide, allowing a user to log into all of their Instances with
one username/password -- at least all Instances associated with that OT Admin database.  However,
if we have "Application A" with "Instance 1" and "Instance 2", then "User X" may have high levels
of access to Tools in Instance 1 but little to no access to Tools in Instance 2.

Instance-level membership in Access Roles can be set in two ways:

1. By hard-setting the membership in the User record via Update User.  This is the
simple and surefire way to assign membership, but it is only appropriate for smaller,
simpler systems.

2. By evaluating tests set up in the Access Roles records against data loaded into the
$self->{access_info} hash in an Application-specific fetch_access_info() method.  This
is explained in more detail below, and it is more appropriate for larger/more complex
Applications. It is especially better for those Applications which use an authentication
plugin to utilize an external user/password database or auth service.

To allow for per-Instance logic, we set up Application-specific sub-classes for this
package, saved as 'custom_session.pm' under the Application's code directory, with these
two methods:

1. extend_session_info($db): This method is the opportunity to modify and add to the
	session attributes in a free-form fashion.

2. fetch_access_info($db): This method should add key/value pairs under $self->{access_info}.
	It is these attributes which are tested in find_access_roles() above aginst the
	'Match' in the Access Roles records.  Work done in extend_session_info() may
	apply here.

For both of these methods, the $db argument is a omnitool::common::db handle for the
Instance's database, and your logic should be very Instance-specific.  Please remember at
this point, we don't have a full session and are not ready to use the utility_belt
or OmniClass, so SQL queries are OK.  Also, since we need to be 100% sure we are on the
desired Instance's database, get_instance_db_object() is called above before these two methods.

Though I just said SQL logic is OK, it should be pulling against tables managed via OmniClass
objects either in live Tools or background scripts.

An example custom_session.pm is included below for your reference.

The find_access_roles() method above handles determining the user's membership in Access Roles,
and those are saved into $self->{access_roles}, where each of the user's Access Roles for this
Instance will have a key with just a '1' value, for easy testing.  The check_access($comma_list) method
will access a comma-separated list of IDs for Access Roles, and will return a 1 if the user has one
of those roles or a 0 if they do not.  This is primarily used for the fetch_the_tools() method.

Last point:  We should only have 5-10 Access Roles per Systme; beyond that, you should think
about splitting your system into another OmniTool Admin database.

=head2 Controlling Access to Instances

Allowing access to each Instance involves two steps in the 'Create/Update an Instance' form in
the UI:

1. Set the 'Required Access Roles' field to control direct access via the hostname.
This is the most important option for controlling access.  A user must qualify against
this logic to use the target Instance at all.

2. Set the '"Switch-Into" Access Roles' field to control who will see links into the
Instance from within other Instances.  Those Access Roles will be based on the users'
memberships while logged into those Instances.  This sounds very complex, but you should
make your cross-Instances Access Roles work very similiarly across Instances.

Remember, if they don't see the link based on #2, they can still access the Instances
if they qualify under #1.

=head2 Usage of this module (very rare):

This is provided for your information, but since everything is handled in pack_luggage(), you
will very likely not need this.

	$session = omnitool::common::session->new(
		'username' => $username, # the valid username from omnitool.omnitool_users.username
								# optional if you send a good value for 'code'
		'db' => $db, # a omnitool::common::db object; OK for it to be the local-most server, even
					# if that's not the db server for our app instance.
		'hostname' => $instance_hostname,	# the 'hostname' value for the desired target instance
		'instance' => $instance_id or $hostname,	# alternative to 'hostname': either the primary key for the
													# target instance or the hostname for that instance
	);

That method is meant to retrieve / re-blesses the saved session for the user/instance combination
or builda a new one if necessary

	$session->save($db);
	serializes and stores the session; can be called multiple times (but not recommended)

	$session->close($db);
	clears the cached session from the database / object store

Probably faster to use a script for that last function.


=head2 Example of Custom Session Class for an Application

package omnitool::applications::otadmin::custom_session;
# custom session hooks for the OmniTool Admin database

########################################################
# Be aware that this is called before we have a complete %$luggage,
# so calling OmniClass and the Utility Belt are not really a good idea.
# You have my permission to use SQL, but if SQL gets re-used, please
# make a central class/module when it makes sense.
########################################################

# is a sub-class of OmniClass
use parent 'omnitool::common::session';
# so $self is the luggage object we are building, before the tools are
# fetched

use strict;

# special routine to extend session information; basically add data intelligently
# be careful not to put business logic or hard-coded info in here; read from the DB
sub extend_session_info {
	my $self = shift;
	my ($db) = @_; # will be tied to the instance's DB server

	# can do a lot here, but just an example
	# $self->{my_information} = directory_lookup($self->{username});

	$self->{my_information} = time();

}

# special subroutine to build out $self->{access_info} hashref, which
# is used by find_access_roles() in session.pm to grant/deny access to
# access roles;  ## MAKE YOUR LOGIC / SQL CALLS INSTANCE-SPECIFIC;
sub fetch_access_info {
	my $self = shift;
	my ($db) = @_; # will be tied to the instance's DB server

	# simple example
	$self->{access_info}{is_ginger} = 1 if $self->{username} eq 'ginger';

}

1;
