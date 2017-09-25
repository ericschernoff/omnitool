package omnitool::omniclass;
# There is a whole lot here, so please see pod documentation included below.
# perldoc omnitool::omniclass

$omnitool::omniclass::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# will need this in new() and change_options() if switching database servers
use omnitool::common::db;

# for handling file-uploads
use omnitool::common::file_manager;

# I am going to use @ISA to allow me to keep my super-long methods in separate modules
use omnitool::omniclass::background_task_manager;
use omnitool::omniclass::data_locker;
use omnitool::omniclass::deleter;
use omnitool::omniclass::email_creator;
use omnitool::omniclass::email_receiver;
use omnitool::omniclass::field_grabber;
use omnitool::omniclass::form_maker;
use omnitool::omniclass::loader;
use omnitool::omniclass::parent_changer;
use omnitool::omniclass::saver;
use omnitool::omniclass::searcher;
use omnitool::omniclass::sorter;

# call them in
our @ISA = (
	'omnitool::omniclass::background_task_manager',
	'omnitool::omniclass::data_locker',
	'omnitool::omniclass::deleter',
	'omnitool::omniclass::email_creator',
	'omnitool::omniclass::email_receiver',
	'omnitool::omniclass::field_grabber',
	'omnitool::omniclass::form_maker',
	'omnitool::omniclass::loader',
	'omnitool::omniclass::parent_changer',
	'omnitool::omniclass::saver',
	'omnitool::omniclass::searcher',
	'omnitool::omniclass::sorter',
);

# for making DB tables on the fly
use omnitool::common::table_maker;
use omnitool::common::luggage;

# get the party started:
sub new {
	my $class = shift;
	my (%args) = @_;

	# declare vars
	my ($a, $new_hostname, $possible_table_name);

	# if calling from a datype's class module, allow that module to specify
	# it's datatype ID in a package name, i.e.
	# $omnitool::applications::my_family::datatype_modules::family_member::dt = '2_1';
	# if they already filled $args{dt}, we wil go with that
	if (${$class.'::dt'} && !$args{dt}) {
		$args{dt} = ${$class.'::dt'};
	}
	# that prevents 'use strict' from working

	# Need to stop here if luggage or dt not provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an OmniClass without my luggage.'});
	} elsif (!$args{dt}) {
		$args{luggage}{belt}->mr_zebra(qq{Can't create an OmniClass without a datatype ID.},1);
	}

	# did they provide a $db? if not, use $$luggage{db}
	if (!$args{db}) {
		$args{db} = $args{luggage}{db};
	}

	# need a database object for sure
	if (!$args{db}->{created}) {
		$args{luggage}{belt}->mr_zebra(qq{Can't create an OmniClass without a database object.},1);
	}

	# same treatment for database_name
	if (!$args{database_name}) {
		$args{database_name} = $args{luggage}{database_name};
	}

	# perhaps they provided a table name for the 'dt', in which case we resolve that
	# to the datatype; makes it easier as you might know the table name rather than the
	# datatype ID
	if ($args{dt} =~ /[a-z]/i) {
		$possible_table_name = lc($args{dt});
		$args{dt} = $args{luggage}{datatypes}{table_names_to_ids}{$possible_table_name};
	}

	# make 100% sure they passed a valid datatype ID
	if (!$args{luggage}{datatypes}{$args{dt}}{table_name}) {
		$args{luggage}{belt}->mr_zebra(qq{Can't create an OmniClass without a valid datatype ID.},1);
	}

	# good spot to make the piece of %$datatypes for this datatype easily available
	$args{datatype_info} = $args{luggage}{datatypes}{$args{dt}};

	# did they speciy an alternative table? if not, use the one in the datatype info
	if (!$args{table_name}) {
		$args{table_name} = $args{datatype_info}{table_name};
	}

	# which metainfo table to use?  place in %args so it gets into $self
	if ($args{datatype_info}{metainfo_table} eq 'Own Table') { # set one up just for this datatype
		$args{metainfo_table} = $args{table_name}.'_metainfo';
	} else { # use the main metainfo table for the database; possibly skipping if 'metainfo_table' = 'Skip Metainfo'
		$args{metainfo_table} = 'metainfo';
	}

	# alright, if they sent a save_to_server, make sure our $db object is set for that
	if ($args{save_to_server} && $args{db}->{server_id} ne $args{save_to_server}) { # have to replace it
		($new_hostname) = $args{db}->do_sql(qq{select hostname from omnitool(_*).database_servers where server_id=?},[$args{save_to_server}]);
		if ($new_hostname) { # good, it's real
			$args{db} = omnitool::common::db->new($new_hostname);
		} else { # if not real, default to what's in current $db object
			$args{save_to_server} = $args{db}->{server_id};
		}
	}
	# make that easy to get to either way
	$args{server_id} = $args{db}->{server_id};
	# that cannot be empty under any circumstance
	$args{server_id} ||= '1';

	# alright, we should be done!
	# by now, everything should be in that %args hash
	my $self = bless \%args, $class;

	# save ourselves about a million characters to make $self->{belt} work
	$self->{belt} = $self->{luggage}{belt};

	# at this point, before we get into any loading and searching, we need to automatically
	# incorporate any new datatype files (which will be in effect if they clicked 'Flush DT Cache')
	if (!$self->{skip_db_ready_check}) { # prevent an endless loop in table_maker.pm
		$self->database_is_ready();
	}

	# initiate our work history / status log
	$self->work_history(1,$self->{datatype_info}{name}.qq{ OmniClass object initiated.},
		"Server ID: ".$self->{server_id}.
		"\nDB Host: ".$self->{db}->{hostname}.
		"\nDB Name / Table: ".$self->{database_name}.' / '.$self->{table_name}.
		"\nUser: ".$args{luggage}{username}
	);

	# if this datatype accepts file uploads, instantiate the file_manager object
	if ($self->{datatype_info}{has_file_upload}) {
		$self->{file_manager} = omnitool::common::file_manager->new(
			'luggage' => $self->{luggage},
			'db' => $self->{db},
		);
	}

	# if calling from a datatype's class module, all for an 'init' method to contribute to
	# the objects initalization; that will add or update our attributes in place
	if ($self->can('init')) {
		$self->init();
	}

	# if they provided the 'data_codes' list (or the altcodes), load those records up
	if ($args{data_codes}[0] || $args{altcodes}[0] || $args{load_all}) {
		$self->load(
			'data_codes' => $args{data_codes},
			'load_all' => $args{load_all},
			'altcodes' => $args{altcodes},
			'skip_hooks' => $args{skip_hooks},
			'sort_column' => $args{sort_column},
			'sort_direction' => $args{sort_direction},
			'skip_metainfo' => $args{skip_metainfo},
			'load_fields' => $args{load_fields},
			'simple_query_mode' => $args{simple_query_mode},
		);
	# or if they specified a search on load, call that with auto_load=1
	# can't do both
	} elsif ($args{search_options}[0]) {
		$args{auto_load} = 1;
		$self->search(%args); # easier to just pass everything in
	}

	return $self;
}

# now a subroutine to allow them to change the options for this object
sub change_options {
	my $self = shift;
	my (%args) = @_;

	# declare vars
	my ($a, $new_hostname, $status_message);

	# mostly easy, as all of these are optional
	foreach $a (keys %args) {
		$self->{$a} = $args{$a};
		# to log below
		$status_message .= "\n".qq{'$a' changed to '$args{$a}'};
	}

	# only thing is we may need a new db object for that save_to_server ID
	if ($args{save_to_server} && $self->{db}->{server_id} ne $args{save_to_server}) { # have to replace it
		($new_hostname) = $self->{db}->quick_select(qq{select hostname from database_servers where server_id=?},[$args{save_to_server}]);
		if ($new_hostname) { # good, it's real
			$self->{db} = omnitool::common::db->new($new_hostname);
		} else { # if not real, default to what's in current $db object
			$self->{save_to_server} = $self->{db}->{server_id};
		}
		# make that easy to get to either way (do it in here, since it may not be changing like in new() )
		$self->{server_id} =  $self->{db}->{server_id};

		# if this datatype accepts file uploads, instantiate a new file_manager object for the new db
		if ($self->{datatype_info}{has_file_upload}) {
			$self->{file_manager} = omnitool::common::file_manager->new(
				'luggage' => $self->{luggage},
				'db' => $self->{db},
			);
		}

	}

	# log these changes
	$self->work_history(1,qq{OmniClass object options updated.},
		"New Options: ".$status_message.
		"\n-----".
		"\nServer ID: ".$self->{server_id}.
		"\nDB Host / DB Name / Table: ".$self->{db}->{hostname}.' / '.$self->{database_name}.' / '.$self->{table_name}.
		"\nUser: ".$self->{luggage}{username}
	);


	# all done
}

# method to run as part of new() to make sure all the tables and columns are in place
sub database_is_ready {
	my $self = shift;

	my ($table_maker, $dt_table_name, $dt_id, $table_is_there, $metainfo_table, $dtf_id, $dt_table_column, $existing_columns, $existing_column_keys, $column, $need_to_fix_table);

	# isoleate the table name for this datatype
	$dt_table_name = $self->{table_name};
	$dt_id = $self->{dt}; # datatype data_code too

	# if we don't have that otadmin_instance_name for any reason, we back off of this
	return if !$self->{luggage}{otadmin_instance_hostname};

	# only once per execution run
	return if $self->{luggage}{database_ready_checks}{$dt_id} == 1;

	# we want to reduce the use of this heavy/powerful method as much as possible for speed,
	# so to that end, let's do a 'cheap' check before proceeding
	($existing_columns,$existing_column_keys) = $self->{db}->sql_hash(qq{
		select COLUMN_NAME,DATA_TYPE from INFORMATION_SCHEMA.COLUMNS
		where TABLE_SCHEMA=? and TABLE_NAME=?
	}, (
		'bind_values' => [$self->{database_name}, $self->{table_name}]
	));
	# use our handy list of all the database columns for this datatype
	$need_to_fix_table = 0;
	foreach $column (split /,/, $self->{datatype_info}{all_db_columns}) {
		next if $$existing_columns{$column}{DATA_TYPE}; # skip if it's there
		# if we get past that test on any column, then we need to
		$need_to_fix_table = 1;
	}

	# if $need_to_fix_table is still zero, mark this done and exit
	if ($need_to_fix_table == 0) {
		$self->{luggage}{database_ready_checks}{$dt_id} == 1; # don't come back
		return;
	}

	# fire up our table maker object to do the heavy lifting
	$table_maker = omnitool::common::table_maker->new(
		# for some reason, we have to call it out explicitly
		'luggage' => omnitool::common::luggage::pack_luggage(
			'username' => $self->{luggage}{username},
			'hostname' => $self->{luggage}{otadmin_instance_hostname},
			'force' => 1, # only place we should use this
		),
		'app_instance' => $self->{luggage}{app_instance},
	);

	# check that the table is there
	$table_is_there = $table_maker->check_tables_existence($dt_table_name);

	# $self->{belt}->logger('trying to fix tables for '.$dt_id.' - '.$dt_table_name.' - '.$table_is_there,'eric');

	if (!$table_is_there) { # make it!
		$table_maker->create_datatype_table($dt_id);
	}

	if ($self->{datatype_info}{metainfo_table} eq 'Own Table') {
		$metainfo_table = $self->{metainfo_table};
		$table_is_there = $table_maker->check_tables_existence($metainfo_table);
		if (!$table_is_there) { # make it
			$table_maker->create_datatype_metainfo_table($metainfo_table);
		}
	}

	# now verify that each column is there
	$table_maker->verify_datatype_table_columns($dt_id);
	foreach $dtf_id (@{ $self->{datatype_info}{fields_key} }) {
		next if $self->{datatype_info}{fields}{$dtf_id}{virtual_field} eq 'Yes'; # only real db fields

		$dt_table_column = $self->{datatype_info}{fields}{$dtf_id}{table_column}; # sanity

		# if it's not there, make it
		if ($table_maker->{mysql_status}{$dt_table_name}{$dt_table_column} =~ /not found/) {
			$table_maker->add_datatype_table_column($dt_id,$dtf_id);
		}
	}

	# track that we checked this datatype during this execution run, so we are not
	# doing it over and over if the DT gets recreated
	$self->{luggage}{database_ready_checks}{$dt_id} = 1;

}


# little sub for saving our status messages
sub work_history {
	my $self = shift;
	my ($success,$message,$detail,$data_code) = @_;
	# initiate our status/history log
	push(@{$self->{status}},{
		'success' => $success,
		'message' => $message,
		'detail' => $detail,
		'data_code' => $data_code,
	});

}

# another little method/sub to save entries to the update_history table; used when the datatype
# has 'extended_change_history' set to 'Yes'
# just pass the detail text as the argument
sub update_history {
	my $self = shift;
	my ($update_detail,$data_code) = @_;

	$self->{db}->do_sql(
		'insert into '.$self->{database_name}.'.update_history (server_id,data_code,datatype,updater,update_time,changes) values ('.
		'?,?,?,?,unix_timestamp(),?)',
	[$self->{db}->{server_id},$data_code,$self->{dt},$self->{luggage}{username},$update_detail]);
}

# quick method to get the names of the access roles for this application
sub get_access_roles {
	my $self = shift;

	my ($access_roles_array, $key, $name, $access_roles,$roles_keys, $table);

	# where are we pulling this from?
	# if we are currently editing an omnitool instance, use the target database for that instance,
	# i.e., the universe we are editing
	if ($self->{luggage}{database_name} =~ /^omnitool/) {
		$table = $self->{luggage}{database_name}.'.access_roles ';
	# otherwise, let's use the omnitool admin DB for this current app, which is the $db->{current_database}
	} else {
		$table = 'access_roles ';
	}

	# quite easy - read into simple hash
	$access_roles_array = $self->{db}->do_sql(qq{
		select concat(code,'_',server_id),name from $table
		where used_in_applications regexp ? and status='Active'
		order by name
	},[ '(^|,)'.$self->{luggage}{session}{application_id}.'(,|$)' ]);

	# convert into a key-value hash
	while (($key,$name) = @{shift(@$access_roles_array)}) {
		$$access_roles{$key} = $name;
		push(@$roles_keys,$key);
	}

	# send it out
	return ($access_roles,$roles_keys);
}

# some convenience: make it easier to create other omniclass objects from object_factory.pm
# useful as most of our OmniClass Packages will include interactions with other objects
# FYI: we have something very similiar in tool.pm
sub get_omniclass_object {
	my $self = shift;

	# can pass all the same args which you can sent to object_factory->omniclass_object
	my (%args) = @_;

	# have to have a datatype
	if (!$args{dt}) {
		$self->{luggage}{belt}->mr_zebra('ERROR: omniclass->get_omniclass_object() cannot create an omniclass object without datatype ID.',1);
	}

	# if our current $self where built via tool.pm, we will have this
	$args{tool_and_instance} = $self->{tool_and_instance};

	# build and return the new object
	return $self->{luggage}{object_factory}->omniclass_object(%args);

}

# we need a default method in case our clients call the wrong thing
# do not fail out when trying to load a non-existent method; will be more important
# as we have make our datatypes subclasses with all kinds of methods
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	# figure out the method they tried to call
	my $called =  $AUTOLOAD =~ s/.*:://r;
	# prepare a nice message
	my $message = "ERROR: No '$called' method defined for ".$self->{datatype_info}{name}.' objects.';

	# log this mixup
	$self->work_history(0,$message,'No Details');

	# return that message
	return $message;
}


1;

__END__

=head1 omnitool::omniclass

(OK, third time trying to write this.  First time was on a plane, and my laptop failed during the trip.
Actually was dumb enough to try to use the same laptop on the way home.  Third time is the charm.)

If there is a core/kernel module to OmniTool, this would be it. This module handles all the saving,
loading, searching, and deleting of data managed via OmniTool.  It is highly, highly encouraged that
you utilize this module for ALL insert/update/delete commands and not send direct commands into $db->do_sql().
That goes triple for any data saved in replicated databases, as this class works with the 'server_id'
column.

This class does not create separate objects representing specific data records, but instead creates
instances of datatypes as defined via OmniTool Admin and cached in the %$datatype_hash structure.
Actually, it creates instances of specific combinations of datatypes, applications/databases,
and save-to locations -- a combination of one each of those.

This class gets very nice when you set up a sub-class for it, which we call an 'OmniClass Package'.
This allows you to have all the methods described below, plus all kinds of hooks, virtual fields,
and any sort of Datatype-specific functions you need.  Please see the "Hooks & Datatype-Specific
Sub-Classes" section below.

A note on the 'primary key'.  In all database tables managed by this system, there is a two-column
primary key:  the 'code' column, which is an auto_increment int(11), plus a 'server_id' column,
an int() that reflects an entry in omnitool(_*).database_servers.  So you'll see a lot of
"concat(code,'_',server_id)" around.  The server_id column will identify the database server where the
data was originally created.  Hopefully, this allows for some circular replication between your very
busy servers.  This 'server_id' can not be a foreign key to that 'database_servers' table, as you might
bring in a copy of data written on a server from another OmniTool system. That two-column primary key
will be referred to a 'data_code' or 'ID' below.

This class will allow you to load up multiple records for its datatype/source-location, but only
save and delete one at a time for sanity's sake.  You'll see how to handle saving one after another
below.  We will also provide support for search, delete, restore, etc.

Enough talk, on to the usage examples.

(Note, you can name '$dt_obj' anything you want; I just use that variable name in these exmaples.
Perhaps I should assume you know that, I am sorry for insulting you in this manner.)

=head2 new()

This creates a new OmniClass object for a datatype/application-instance combo.

Note: You will almost certainly want to use the methonds in common::object_factory to create OmniClass objects,
rather than call OmniClass directly.  The object_factory->omniclass_object() routine will pull in any defined
subclass for the datatype, plus it opens up the tree-building and data-extracting methods.  It takes all the
arguments below, except for %$luggage, which it will already have.  OmniClass objects created via either
method will have all the methods after new().

	$dt_obj = omnitool::omniclass->new(
		# general startup arguments
		'luggage' => $luggage,	# %$luggage hash; required, can't leave home without your luggage
								# please see pack_luggage() for all the goodness in here
		'dt' => $dt_id, # (generally) required; primary key of datatype being instantiated; can't do anything without this
						# can be the primary key of the datatype in omnitool(_*).datatypes or the table_name of the datatype
		'skip_hooks' => 0 or 1, # optional and defaults to '0'; if 1, will instruct core methods to skip
						# calling this datatype's hook methods (pre_load, post_save, etc)
						# can also specify 'skip_hooks' on individual methods
		# for loading data during object setup (I do not like saying 'instantiation.')
		'data_codes' => [@list_of_ids], # optional, if filled, will call $self->load() on these ID's
		'altcodes' => [@list_of_altcodes], # optional, alternative way to call $self->load() on records, and probably
						# much easier for writing scripts; do not use if you are sending data_codes
		'search_options' => [%$search_options], # optional, if filled, will call $self->search() with these search
						# criteria.  Sends all of %args, so you can pass all options described under 'search()'
						# below; does add auto_load=1 to search()
		# the following options are useful if 'data_codes' or 'search_options' is filled
		'sort_column' => $column_or_key_name,
		'sort_direction' => 'up', # up = ascending / down = descending
		'skip_metainfo' => 1 or 0, # optional; good if you are only reading/displaying; bad for updating operations
		'load_fields' => 'comma,list,of,fields', # optional; allows you to specify which table columns will be retrieved
						 # and which virtual field hooks will be run (name those 'field_HOOK' like the methods)
						 # if blank loads all columns and runs all hooks.
						 # useful to avoid loading big fields for screen/action display
						 # be careful not to sabotage hooks which rely on other DB columns
		'simple_query_mode' => 'list,of,fields'; # optional; makes this system work more like a plain SQL query
												 # this will fill in load_fields and auto-set skip_metainfo and
												 # skip_hooks to 1 (load only)
		# optional value if calling from a Tool.pm object:
		'tool_and_instance' => $tool_and_instance,  # optional, the tool_id value to use to create JS links
						# passed in when tool->get_omniclass_object() creates the object
						# very useful for preparing links for the tools
		# for changing the read/save location for the data; should be rarely and carefully used
		'db' => $db, # alternative database object; will default to $$luggage{db}
		'database_name' => $database_name, # optional; name of database to save-into; will default to %$luggage{database}
		'table_name' => $table_name, # optional; name of table to write into; it's on you to make sure it's identical
						# to this datatype's default table; will default to $$datatype_hash{$dt_id}{table_name}
		'save_to_server' => $server_id, # optional; primary key of server listed in omnitool(_*).database_servers;
						# will default to server in $$luggage{db} or provided $db
						# depends on you to have the database/table set up correctly there
	);

Hey, this is fun: As part of the new() setup, we shall call database_is_ready(), which works with table_maker.pm
to make sure the Datatype table exists and has all the needed columns -- and create the table/columns as needed.
This is very convenient for changing your Datatypes on the fly.

Note on 'dt' option:  If creating via a datatype-specific subclass, you can have a package-specific
'dt' variable defined at the top of that subclass, i.e.:

	$omnitool::applications::my_family::datatype_modules::family_member::dt = '2_1'

And then not pass the 'dt' argument to new(); otherwise, be sure to send the 'dt' argument.

Also, you can pass the 'table_name' value for the datatype in omnitool(_*).datatypes; this presumes
that your table names are unique within your applications.

If this datatype accepts file uploads, omnitool::common::file_manager will be instantiated into $self->{file_manager}.

=head2 change_options()

You can change the save-to-targets / data-source info and skip_hooks anytime like so:

	$dt_obj->change_options(
		'db' => $db, # alternative database connection object; will default to $$luggage{db}
		'database_name' => $database_name, # optional; name of database to save-into; will default to %$luggage{database}
		'table_name' => $table_name, # optional; name of table to write into; it's on you to make sure it's identical
					   # to this datatype's default table; if you leave this off, will default to $$datatype_hash{$dt_id}{table_name}
		'save_to_server' => $server_id, # optional; primary key of server listed in omnitool(_*).database_servers;
						# will default to server in $$luggage{db} or provided $db
						# depends on you to have the database/table set up correctly there
		'skip_hooks' => 0 or 1, # optional and defaults to '0'; if 1, will instruct core methods to skip
						# calling this datatype's hook methods (pre_load, post_save, etc)
	);

=head2 load()

To load up data from your MySQL database into the OmniClass object:

	$dt_obj->load(
		'data_codes' => [@list_of_data_codes], # semi-required; arrayref of primary keys for data to load up
			# send 'all' to load up all records for the datatype in this application instance (dangerous!)
		'altcodes' => [@list_of_altcodes], # optional; can use instead of data_codes for sending values from metainfo.altcode column
		'load_all' => 1, # optional, does the same thing as sending ['all'] for data_codes; only use this if you
						 # want to load up all records
		'do_clear' => 1 or 0, # optional, defaults to 0, which tells load() to clear any previously-loaded records first
		'skip_metainfo' => 1 or 0, # optional, defaults to 0; filling-in will skip loading in data from 'metainfo' table
		'skip_hooks' => 0 or 1, # optional; if '1', skip pre_load or post_load hooks and any virtual field routines
		'load_fields' => 'comma,list,of,fields', # optional; allows you to specify which table columns will be retrieved
			# and which virtual field rotuines will be run (name those 'field_HOOK' like the methods)
			# if blank loads all columns and runs all load routines.
			# useful to avoid loading big fields for screen/action display
			# be careful not to sabotage virtual fields which rely on certain fields
		'simple_query_mode' => 'list,of,fields'; # optional; put your 'load_fields' comma-list here (and not use 'load_fields'), and
												 # it will auto-set 'do_clear', 'skip_metainfo', and 'skip_hooks' all to 1
												 # basically, make this into as pure a DB query as possible; great for snatching 1 or 2 fields
		'sort_column' => $column_or_key_name, # optional, sorts the data by that named column/key
			# default is the order of @$data_codes
			# if you want to sort by a column in the metainfo table, specify this as 'metainfo.column_name',
			# e.g. 'metainfo.create_time'
		'sort_direction' => 'up' or 'down' or 'Ascending' or 'Descending', # optional, only use with 'sort_columns',
			# default is 'asc' and up=asc and down=desc
		'complex_sorting' => [complex,sort,instructions'],  # optional; provide an arrayref of column/direction combinations
															# if you would like the records_keys sorted by multiple columns
															# please see complex_sort() below
	);

This method will populate the data into these attributes of the object:

$dt_obj->{records}{$primary_key}{column1_name} = 'column1_value'; # column from DB table; includes 'name' and 'parent'

$dt_obj->{records}{$primary_key}{column2_name} = 'column2_value';

$dt_obj->{metainfo}{$primary_key}{column1_name} = 'column1_value'; # column would be from the 'metainfo table,
																   # 'create_time' or 'originator', etc.

and the keys for the $dt_obj->{records} hash will be in:

$dt_obj->{records_keys} = [key1,key2,key3]; # those keys are the data_code two-column $primary_key values,
											# i.e. concat(code,'_',server_id)

If you specify values for 'sort_column' and 'sort_direction', those will be rememebered for the next time you call
$dt_obj->load(), which makes auto-loading on updates/deletes kind of nice ;)

In order to act more like an traditional object system, the first record found (after sorting) will be loaded
into $dt_obj->{data}.  This is very handy for when you'd loading just one record.  This means you will have:

	$first_key = $dt_obj->{records_keys}[0];

	$dt_obj->{data} = $dt_obj->{records}{$first_key};

	$dt_obj->{data}{metainfo} = $dt_obj->{metainfo}{$first_key};

	$dt_obj->{data_code} = $first_key;

	$dt_obj->{parent_string} = $dt_ob->{dt}.':'.$first_key; # very nice for finding children of this record

Under the 'metainfo' sub-hashes, you will have all the columns in the metainfo table, plus 'nice_create_time'
and 'nice_update_time', which will be human-friendly date/time strings for the create and update times,
unless you have turned on 'skip_hooks'.

Speaking of hooks, so long as 'skip_hooks' is off, all the 'virtual' fields will be loaded in under the
'records' sub-hashes.  You set up the virtual Datatype Fields via the OmniTool Admin interface, then
you will need to set up a custom class (Package) for this datatypes with methods named for the 'table_column'
values of any virtual fields, such that 'field_birthday' would tie to a virtual datatype field with
a table_column of 'birthday.'  That would load the value into $dt_obj->{records}{$r}{birthday}, and
for the first one, $dt_obj->{data}{birthday}.

=head2 load_last_saved_record()

Simple method to load up the most recently-saved record (created or updated) by this particular object/process.

If you supply an argument, clear_records() will be called first, so that the loaded record will
be the only one loaded (and be in $self->{data}).

=head2 load_all()

Simple utility method to let you load up all the records in the database for the given datatype.  Works
the same as $dt_obj->load( 'load_all' => 1 ) and meant to save you some typing.  You can pass in all 
the same args as you would for load(), except for 'data_codes' and 'altcodes'.

Usage:

	$dt_obj->load_all();  # simple load-all action
	
	$dt_obj->load_all( # little more complex
		'skip_metainfo' => 1,
		'load_fields' => 'some,field,names'
	);

=head2 clear_records()

To clear out all loaded records from $dt_obj->{records} & $dt_obj->{records_keys}, just use this:

	$dt_obj->clear_records();

Also clears out $dt_obj->{data}.

=head2 search()

This how you search (and load) data.  Meant to take the place of SQL 'select' statements.

	$dt_obj->search(
		'search_options' => [ # array of hashes, with the values below; as many hashes as you would like search criteria
			{
			'operator' => '=', # search type, defaults to '=' if not provided;
				# options are: =, !=, <, >, >=, <=,like, not like, regexp, not regexp, in, not in, between
				# if the operator is 'in' or 'not in,' will want 'match_value' to be an arrayref or a proper comma or ','-separated list
				# if the operator is 'like' or 'not like,' will wrap 'match_value' in %'s
				# if the operator is 'between', that's for date ranges.  Provide two dates in 'match_value'
				#	like so:  YYYY-MM-DD---YYYY-MM-DD, i.e. '1976-09-04---1999-08-01'

			'match_column' => 'column_name_to_search', # defaults to 'name'; otherwise provide the DB column name
			'match_value' => 'abc', # required; use arrayref for 'in' and 'not in' options, or if you use 'additional_logic'
				# like/not like match_values automatically have % put at start/end

			## a nice alternative for match_column/match_value:
			'column_to_match' => 'match_value', # so 'priority' => 'P3' would set the 'match_column' to 'priority',
												# and the 'match_value' to 'P3'.  much easier, especially if you
												# take the default = operator

			# the following four options are for searching against cross-table relationships (i.e. finding cities by country name)
			'database_name => 'some_database', # optional; defaults to $dt_obj default or the database in $dt_obj->{database_name})
			'table_name' => 'some_table', # optional, but required for relational searching; defaults to dt's table or the table in $dt_obj->{table_name}
			'relationship_column' => 'column_name', # used when specifying the 'database' and/or 'table' options; will
				# be a column on the 'foreign' table specified in 'table_name'; will tie back to 'primary_table_column' below
				# if 'table_name' =~ /metainfo/, then will default to data_code and in that case, limits to records to $self->{dt}.
				# the defailt is 'parent,' which will look for parent values with the prefix of this object's datatype ID
				# if set to 'data_code' will be translated to 'concat(code,'_',server_id)'
			'primary_table_column' => 'column_name', # used when specifying the 'database' and/or 'table' options,
				# and the 'relationship_column' does not match up the primary key of this object's primary table.
				# is a column of the datatype's primary table, which is in $dt_obj->{table_name}
				# Tells the searcher the relationship to the primary table from the alternative 'table_name' table.
				# This allows us to search against true foreign keys, and not just other tables represent children
				# of this datatype.

			### See example below on cross-table relationships.

			# for specifying ad-hoc logic
			'additional_logic' => qq{some more sql logic, beginning with 'and' or 'or'), # optional
				# this last bit is useful for sending something fancier than these options will allow, and
				# especially if you need to do some 'or' stuff; a lot of 'or' logic can be handled with an IN
				# list or a regexp, if the 'or' is testing values of the same 'match_column.'
				# But if you need to have "name='eric' or type='dog", then you'd probably set additional_logic to
				# qq{or type='dog'); definitely more manual, but at least gives you options
				# remember you can mangle these options a bit in 'pre_search'
				# USE PLACEHOLDERS IN YOUR QUERY TO EXECUTE THE 'additional_logic' IF VALUES ARE USER-PROVIDED
				# To do this, make 'match_value' be an arrayref, with the values for 'additional_logic' at
				# the end of the array
			}
		],
		'log_search' => 1 or blank, # for debugging, if filled, will log the SQL and values of the search into the USERNAME_searches log
									# where 'USERNAME' is $self->{luggage}{username}
		'order_by' => 'some_col', # sorts the results based on an 'order by' SQL clause against the primary table, so any/all
								  # specified columns must be in the primary datatype table.  Regular SQL syntax, minus the
								  # 'order by' bit; very useful when you are not auto-loading records.
								  # Please use with limit_results for best_results ;>
		'limit_results' => blank or an integer, # default blank; if filled, limits the number of results found to value
		'auto_load'	=> 0 or 1, # default is 0; if 1 or otherwise true, calls $dt_obj->load() on search results
		'skip_hooks' => 0 or 1, # optional; if 1 or otherwise true, skip pre_search and post_search
		'sort_column' => $column_or_key_name, # optional; arg passed to load() if auto_load=1
		'sort_direction' => 'up', # optional; arg passed to load() if auto_load=1
		'complex_sorting' => [complex,sort,instructions'],  # optional; provide an arrayref of column/direction combinations
															# if you would like the records_keys sorted by multiple columns
															# please see complex_sort() below

		'do_clear' => 1 or 0, # optional; arg passed to load() if auto_load=1
		'skip_metainfo' => 1 or 0, # optional; arg passed to load() if auto_load=1
		'load_fields' => 'comma,list,of,fields', # optional; if auto_load=1, allows you to specify which table columns will be retrieved
			# and which virtual field hooks will be run (name those 'field_HOOK' like the methods)
			# if blank loads all columns and runs all hooks.
			# useful to avoid loading big fields for screen/action display
			# be careful not to sabotage hooks which rely on certain fields
		'simple_query_mode' => 'list,of,fields'; # optional; put your 'load_fields' comma-list here (and not use 'load_fields'), and
												 # it will auto-set 'do_clear', 'skip_metainfo', and 'skip_hooks' all to 1
												 # basically, make this into as pure a DB query as possible; great for snatching 1 or 2 fields
												 # will set auto-load to 1 as well (presumes you want to load results)
		'resolver_hash_field' => 'field_name',  # supply a valid field name if you would like to process
												# create_resolver_hash() against the found search results.
												# please see notes on create_resolver_hash() below
	);

Upon successful execute, this method fetches an array of the primary keys, 'concat(code,'_',server_id)',
and saves them here:

	$dt_obj->{search_results} = [@found_data_codes];

And the number of matches found will be in $dt_obj->{search_found_count} so that if no matches are found,
$dt_obj->{search_found_count} will be 0.

After the initial run-through, you can just call $dt_obj->search() and it will use all the arguments
which were sent before.  You do have to supply all of the arguments if you want to change any of them,
but the most useful bit is being able to call the same exact search over and over. Very nice for keeping
multiple folks' screens updated as they each make changes.

Here is an example query for cross-table relationships, since I feel like my explanation was kind of terrible:

	# Find cities over 10,000 residents in Japan, with countries in a separate table.
	$cities_object->search(
		'search_options' => [
			{ # population filter
				'population' => 1000,
				'operator' => '>'
			},
			{ # cross-table relationship to countries table
				'match_column' => 'name',
				'match_value' => 'Japan', # "'name' => 'Japan'" would also work
				'table_name' => 'countries',
				'relationship_column' => 'data_code', # so concat(code,'_',server_id) on 'countries' table
				'primary_table_column' => 'country_id', # so 'cities.country'
			},
		],
		'auto_load' => 1,
	);

	The records for cities in Japan with more than 10,000 residents would be in $cities_object->{records} now,
	with the found keys in $cities_object->{search_results}.

=head2 simple_search()

Utility method to save typing when your search() query only involves 'equals' tests and all match columns
are in the primary table.  Perfect for when you just want to find load records where status='Active' or
similar tests.  You can also pass 'auto_load' => 1 to automatically load any found results; use the
regular search() method for anything fancier.

Usage:

	$dt_obj->simple_search(
		'field_one' => $field_one_match_val,
		'field_two' => $field_two_match_val, # at least one of these is require
		'auto_load' => 1, # optional; will auto-load the results
	);

Exmaple:

	$family_object->simple_search(
		'type' => 'Dog',
		'name' => 'Pollywocket',
		'auto_load' => 1,
	);

	# will load up all the dogs in your family named Pollywocket ;)

=head2 save()

Slightly important method: This is where we create and update data in OmniTool.

	$dt_obj->save(
		# args for idenitfying the record
		'data_code' => $data_code, # optional; if filled, will update; if blank, will create
		'parent' => $parent_string, # optional for update / required for create
			# DT_ID:DATA_CODE string for record which will become the parent
			# of the data; can also set to 'top' for top-level

		# quick instruction args
		'skip_hooks' => 0 or 1, # optional (default is 0); if '1', skips pre_save and post_save
		'auto_load'	=> 0 or 1, 	# optional (default is 0); if filled, calls $dt_obj->load() on
								# the target record (update only)

		# for sending the new values for the data
		'params' => {},	# optional; fill with a hashref of key=value pairs if you do not want to use
						# what's in $self->{luggage}{params} for your field values. Discussion below.
		'params_key' => 'string', # optional; prepend this string to all $self->{luggage}{params} keys
			# used to build the record, i.e. 'string_status' for 'status' column;
			# useful when you are saving one record after another and have submitted
			# a spreadsheet-style form
		'skip_blanks' => 0|1,	# optional (default is 0); used for updates only.
			# if filled, will only update fields for which you sent a value in %$params
			# (including a value of 0, so it literally skips blanks).  Useful for 1- or 2-field edits
		'merge_params => 0|1,	# optional, use if you are using the 'params' for setting values, it will
							# pull in any found value from $self->{luggage}{params} that is not set in your
							# 'params' hashref; safer in certain situations.

		# Not well-tested / utilized feature:
		'is_draft' => 0|1,	# optional and for creates only; if filled, will set the 'is_draft' column
			# in the metainfo table to 'Yes', which can be useful for excluding in searches
			# Most useful in conjunction with a datatype that has a bunch of non-required fields
			# and a well-crafted pre_save() hook.
			# To later un-set the 'is_draft' column (aka 'publish' the record), use
			# $dt_obj->not_draft($data_code);
	);

The data-code of the last-saved record will be placed into $dt_obj->{last_saved_data_code}.

The values which are used to create/update the record are usually going to be in $self->{luggage}{params}, also
referred to as 'the %$params hash'.  These are where the PSGI params are placed by pack_luggage().  This will
generally work for saving data submitted via web form or API.  However, there are times when you just want to
pass in the field values, like in secondary saves in post_save() or import scripts.  This is how most OO systems
work, I realize.  For that use case, you can pass in a hashref of values in $args{params}.  That hashref should
have the same key=value format of the usual $self->{luggage}{params}, including the use of any 'multi' arrays
for multi-selects/checkboxes.  If you just want to override a few %$params values and keep some others, then
you can set $args{merge_params} to 1/true to bring in any filled-in value from $self->{luggage}{params} that is
not in your $args{params} hashref.  Using 'merge_params' is probably the safe choice, in case you might have
forgotten something. (I apologize if this is unnecessarily confusing.)

If the datatype has the 'skip_metainfo' option set to 'Yes,' this routine will not write to the 'metainfo' table;
otherwise (and in most cases), that metainfo table is used to store useful data about this data, including the username
of the creating user (the 'originator'), the username of the last user to update the data ('updater'), the unix epoch of
creation (create_time), epoch for update (update_time), the data_code (code,'_',server_id) of the record in its table,
the data_code of its parent, the list of data_codes which are its children (in order), and a list of data_codes for access
lists which are used to restrict access to that data.  Does not add too much overhead versus the usefulness.

The metainfo table also has that 'altcode' column, which is meant to be a somewhat-unique and human-friendly identifier.
In the saver.pm module, we have a basic 'altcode_maker()' method that will create an altcode based on the current month,
creator's username, datatype's table name, and last insert ID of that table.  That formula is OK for most data, but for
important data, you will want to put an 'altcode_maker()' method in the datatype's class/package to override this generic
method.  This is only used on create; if you want to change it for an update, please do so in your post_save() hook.

BTW, if you have your own altcode_maker() method in your OmniClass Package, please check out the altcode_next_number() method,
also in saver.pm.  This will let you find N+1 for records with altcodes matching a base.  Probable use is to pass in
a month/year abbrev (Sep16, Dec18, etc.) to find the next number of the records for that month.  You can send in whatever
you like.  Returns numbers like 003, 024, 567, 1100...minimum three digits, with leading zeros as needed.

The field_grabber.pm methods are going to have more comments about the field types that a datatype may have
and how they work.  One note on file upload fields: when saving outside of a form-upload situation (i.e.
script or background task), you should provide a URI to download the file or a absolute path on the local
filesystem.

This method allows you to save one record at a time, and if you have a batch-entry form, utilize a 'params_key'
sub-key and cycle through the forms submissions in group by key ('record1,' record2', etc....you get the idea,
I mean really, why am I am typing so many comments.)

Finally, this routine will log out to today's 'saves_DBNAME_TABLENAME' log file under the $OTHOME/log directory.

=head2 simple_save()

Handy utility method to update a few fields of an existing record with a little less code.  Can not create
records, only update.  Not appropriate for handling PSGI forms; better for your direct updates.

Usage:

	$dt_object->simple_save(
		'data_code' => $target_record_data_code, # leave off to default to $dt_object->{data_code}
		'field_to_update_one' => $new_value_one,
		'field_to_update_two' => $new_value_two,
		# as many fields as you want
	);

That code is equivalent to:

	$dt_object->save(
		'data_code' => $target_record_data_code, # required in this context
		'skip_blanks' => 1,
		'params' => {
			'field_to_update_one' => $new_value_one,
			'field_to_update_two' => $new_value_two,
		},
	);

So a bit less code, especially if you have a record already loaded and can use $dt_object->{data_code},

=head2 simple_sort()

This method will sort the keys of the loaded records, aka $dt_obj->{records_keys}, given one field name
and one direction.  The direction defaults to 'Up'.  It does not return anything, but just updates
$self->{records_keys} in place:

	$dt_object->simple_sort({
		'sort_column' => 'table_column_or_key_name', # required
		'sort_direction' => 'Up' or 'Down' or 'Ascending' or 'Decesending', # optional
	});

Hint: If you want to sort by age, use 'metainfo.create_time' as the 'sort_column'.
Even if the datatype has it's own metainfo table, you pass the metainfo columns as 'metainfo.COLUMN_NAME'.

=head2 complex_sort()

This little ditty will sort your loaded records keys based on multiple columns, each in different directions.
It wants an arrayref of combos of table_name and direction, separated with a space-pipe-space, i.e. ' | '

So let's say you have loaded a bunch of historical events:

	$history_events_object->complex_sort(
		['event_date | Up', 'country | Up',  'name | Down',]
	);

After that, $history_events_object->{records_keys} will be sorted by event date from earliest to latest (Up),
with events on the same date appearing alphabetized-up by country, and those for the same date/country will
be alphabetized-down (Z->A) by name of the event.

This drives the Advanced Sorting in the Search Tool UI, but it will likely be useful programatically.  Please
also notice that I didn't mention Ginger in this example, though I really should have.

=head2 altcode_to_data_code()

Small utility method to resolve an altcode to a data_code.  For form_maker and data_locker
methods, but useful everywhere.

Usage:

	$data_code = $dt_obj->altcode_to_data_code($altcode);

$data_code will be empty if nothing found.  This is not fancy ;)

=head2 data_code_to_altcode()

Small utility method to resolve a data_code primary key to an altcode, the opposite of
altcode_to_data_code().  Meant for background_task_manager::add_task() method, but
useful everywhere.

Usage:

	$altcode = $dt_obj->data_code_to_altcode($data_code);

$altcode will be empty if nothing found.  This is also not fancy ;)

=head2 get_omniclass_object()

This method helps you load up other OmniClass objects, sparing you the trouble of having to type out
"$self->{luggage}{object_factory}->omniclass_object(%args)" all over the place.  It is useful for your
custom OmniClass packages, where you need to interact with different types of data.

It accepts a hash with all the same options as 'omniclass_object' as documented in object_factory.pm,
which means you can create those fun OmniClass trees with this as well.

Usage:

	$new_omniclass_object = $self->get_omniclass_object(
		'dt' => 'some_table_name_here',
		# other options
	);

Note that if you are working in a Tool.pm subclass, you would utilize the 'get_omniclass_object'
method that is part of tool.pm; same thing, but a little better for that context.

That last sentence exemplifies why my wife does not like to discuss this with me at dinner.

=head2 send_file()

Small method meant to output the contents of an uploaded file out to the web client or retrieve a reference
to the contents of the file.  This file will be associated with an OmniClass-managed data record, via a
'file_upload' Datatype field.  This method is usually called from Tool.pm's send_file() method.

Usage:

	$dt_obj->send_file($data_code); # sends the file to the client

	$file = $dt_obj->send_file($data_code,1); # returns the file contents, which is now in ${$file}

Required argument is the primary key for the OmniClass data record which has the uploaded file attached to it.
This data record does not have to be loaded up into $dt_obj, as this function just retrieves and sends a file
from the DB.

This also assume that almost all datatypes have just one 'file_upload' field, so it just looks for the first
field of that type to retrieve the uploaded file. If the datatype has multiple file_upload fields, you can set
the desired field's DB column name into $self->{luggage}{params}{file_field} before calling send_field().
Example: If you set $self->{luggage}{params}{file_field} to 'attached_file', then the above will send out
the 'attached_file' file in the record ID'ed by $data_code; otherwise it will look for the first
field set as a file_upload.

If there is no second argument, send_file() calls mr_zebra() via omnitool::common::file_manager::retreive_file()
to output the file, MIME-type, and filename, and then exit.  If there is a second argument, a memory reference
of the file contents will be returned.

=head2 get_altcodes_keys()

This creates a version of the 'records_keys' array, but with the loaded data records' altcode values,
placing them into @{ $self->{altcodes_keys} }.  This does not happen automatically, as your tools
routines may be fiddling with $self->{records_keys}.  Please see omnitool/tool/searcher.pm.  These
are used to create forward / next buttons in certain Tool screens.

=head2 create_resolver_hash()

This is a utility method to populate a key=value hash into $dt_obj->{resolver_hash} to allow you to look-up records'
data_codes by a field.  Can be very handy when processing a bunch of saves where you need to know whether to update
an existing record or create a new one.

Usage:

	$dt_obj->create_resolver_hash(
		'field_name' => 'some_field_name', 		# optional; a key that who be under the 'records' hash; defaults to 'name'
		'data_codes' => [list,of,data,codes],	# optional/suggested; the arrayref of data codes that we need to resolve
												# if blank, tries for $self->{search_results}, and if that is empty,
												# it will try for $self->{records_keys}
		'already_loaded' => 1,			# if set, indicates that the records are already loaded and do not reload
										# useful when you are using 'auto_load' on a search() call
	);

	Places the key=value pairs under $dt_obj->{resolver_hash}.

Example:

	$family->create_resolver_hash(
		'field_name' => 'birthdate',
		'data_codes' => ['1_1','2_1','3_1'],
	);

	Now you have a 'resolver_hash' like so:

	$family->{resolver_hash} = {
		'1999-08-01' => '1_1',
		'2002-04-01' => '2_1',
		'2012-03-11' => '3_1',
	};

You can send a comma-separated list of field names if you want multi-field keys, for example:

	$family->create_resolver_hash(
		'field_name' => 'birthdate,name',
		'data_codes' => ['1_1','2_1','3_1'],
	);

	Now you have a 'resolver_hash' like so:

	$family->{resolver_hash} = {
		'1999-08-01_Ginger' => '1_1',
		'2002-04-01_Pepper' => '2_1',
		'2012-03-11_Lorelei' => '3_1',
	};

=head2 check_for_loaded_record()

A lot of the methods you will write will require that a record is loaded-up in $self->{data}.  This utility
method is here to save you a few lines of code by making sure we have that primary record.  Just call it
like so:

	$dt_obj->check_for_loaded_record();
	# usually like so:
	$self->check_for_loaded_record();

If either $self->{data}{name} or $self->{data_code} are empty, then your program will exit with a 'fatals' log
entry indicating that you can't call your method without a loaded record.

=head2 Data-Locking for Tools

For creating, checking, and removing locks, we have the functions in the data_locker.pm sub-class.  These locks are
checked, set, and respected both within the Action Tool 'orchestrator' module, omnitool::tool::action_tool, as well
as in our 'save()' and 'change_parent()' methods.

I have found that I do not interact with these locks very often, as action_tool.pm and omnitool_routines.js takes
'good' care of them, but perhaps it's useful just to review the usage for each lock-related method:

	$result = $dt_obj->lock_data(
		'data_code' => 'string', # required; data_code or altcode of record to lock, required
		'lifetime' => integer, 	# number of minutes to live; optional and defaults to datatypes.default_lock_lifetime
								# this value is probably coming from tool.lock_lifetime
		'force' => '1', 	# optional/discouraged; if filled, will overwrite active locks for other people
	);

	Returns 0 on failure, and you can check the last entry in $self->{status} for reason.
	Returns 1 on success.

	$result = $dt_obj->unlock_data(
		'data_code' => 'string', # required; data_code or altcode of record to un-lock, required
		'force' => '1', 		# optional/discouraged; if filled, will remove active locks for other people
	);

	Returns 0 on failure, and you can check the last entry in $self->{status} for reason.
	Returns 1 on success.

	($lock_user,$lock_remaining_minutes) = $dt_obj->check_data_lock($data_code);

	Only arg is required data_code or altcode of data to check on locks for.
	If the lock is under the name of $self->{luggage}{username} or 'None' then it returns blank.
	If any other lock is found, you receive the username and number of minutes remaining for the lock.

Lock information is kept in the 'lock_user' and 'lock_expire_time' columns of the metainfo tables.  Locks will
expire automatically upon that lock_expire_time, and the front-end JS takes care to end any locks as soon as you
navigate off of the locking Tool.  There is a countdown with an auto-redirect in these locking Tools as well.

=head2 Work logging & extended change history

This method, as well as change_parent(), delete() and restore() will add entries to the $dt_obj->{status} associative array
in order of earliest to latest changes, like so:

	$dt_obj->{status}->[0]->{success} = 1; #  1 or 0; 1=success
	$dt_obj->{status}->[0]->{message} = qq{'Beach Trip' Calendar Event Has Been Updated};  # one liner, no HTML
	$dt_obj->{status}->[0]->{detail} = ""; # longer text goes here; good place for error text
	$dt_obj->{status}->[0]->{data_code} = '1_10'; # primary key of record created/updated

This is very useful for debugging, but this 'status' feature has not been fully utilized as of yet.

If the datatype has 'extended_change_history' set to 'Yes,' then actions will be saved to a to an 'update_history'
table within the target database (which should be auto-created for any new OmniTool application/database).  This
update history looks like:

	CREATE TABLE `update_history` (
	  `code` int(11) NOT NULL AUTO_INCREMENT,
	  `server_id` int(11) NOT NULL DEFAULT '1',
	  `data_code` varchar(30) NOT NULL,
	  `datatype` varchar(30) NOT NULL,
	  `updater` varchar(25) NOT NULL,
	  `update_time` int(11) NOT NULL DEFAULT '0',
	  `changes` mediumtext,
	  PRIMARY KEY (`code`,`server_id`),
	  KEY `data_code` (`data_code`)
	) ENGINE=InnoDB;

For updates, it will try to save the pre/post values of smaller columns (not text/longtext) in 'changes'.

Note that enabling this option will really slow down your application; use it sparingly.  The automatic save
logs mentioned under save() should suffice for most all situations.

=head2 change_parent()

To move data from under parent record to another:

	$dt_obj->change_parent(
		'data_code' => $data_code,   		# required; primary key of data for which to change parent
		'new_parent_id' => $parent_id, 		# required; primary key of proud new parent
		'new_parent_type' => $parent_datatype_id, # required; the datatype ID of the proud new paremt
	);

Will update $dt_obj->{status} as well as the 'update_history' table if the 'extended_change_history' option
is 'Yes' for that datatype.

=head2 form()

This is used to generate a data structure representing a form which is to be rendered by our UI (one of Template-Toolkit,
Jemplate, or an API interpreter).  Does not generate HTML, but rather an instructive hash.  Returns a
reference for that hash and does not store in $self.  Please see the bottom of form_maker.pm for a (mostly)
complete example of a hashref which could be returned.

This is meant to be called from a sub-class of Tool.pm driving an action tool.  I would think 95% of the time,
it would be via omnitool::tools::standard_forms, which is already written.

All of your opportunity to affect the contents of %$form come in the hooks described under "Hooks &
Datatype-Specific Sub-Classes" below.

Usage:

	$form = $dt_obj->form(
		'action' => 'create', 		# 'create' or 'update', defaulting to 'create' unless 'data_code' is filled
		'data_code' => 'string', 	# data_code or altcode of record to load as presets for form; assumes 'update'
									# if this is filled and 'action' is set to 'create,' then you will be in a 'clone'
									# mode where your user is trying to create new data using an old record as a template
		'new_parent' => 'string',	# parent string of the data under which we will create data; for creates only
		'target_url' => 'string', 	# target URI to submit the form into; defaults to $self->{luggage}{uri}
		'title'	 => 'string', 		# Text to display above form; defaults to: ucfirst($args{action}.' a '.$self->{datatype_info}{name}
									# datatype_hash.pm tries to calculate 'a' or 'an'
		'submit_button_text' => 'string', # I bet you can guess; defaults to 'title' without the a/an
		'instructions'	=> 'long_string', # text to display above form; defaults to $self->{datatype_info}{description}
		'hidden_fields'	=> {				# ref to associative array of name=value pairs for the hidden fields
			'field_name' => 'field_value',	# 'data_code' and 'action' will be included by default
		},
		'use_params_key' => 'string' or 1,  # if 1, will pre-pend record datacode (or 'new1') to field names
			# useful for multi-record forms; if otherwise filled (not 0), will
			# append that value to the field names
		'show_fields'	=> [field_data_keys]	# optional: comma-separated list of data_code ID's for the datatype_fields
			# to build, and you should have 'name,' at the front to include the name
			# If blank, all fields are brought in; use this to create a 'mini' form.
			# ** If you use this, be sure to fill the 'skip_blanks' arg for saver(). **
	);

=head2 options_from_directory($directory,$file_extension);

Builds options for the 'options_' datatype hooks based on the contents of a provided directory.  The second
argument is a file extension (txt, docx, or similiar) or 'dir', indicating to search for sub-directories.

Returns a hashref for the options plus an arrayref of the keys, suitable to be passed right into form().

=head2 children_update()

To update the 'children' metainfo column for a record, maybe after moving it under a new parent,
just do:

	$dt_obj->children_update($new_parent_string);

$new_parent_string takes the form of DATATYPE_DATA_CODE:PARENT_DATA_CODE, i.e. 4_3:5_8 where '4_3' is
the primary key for the datatype, and '5_8' is the primary key for the record who is the new parent.
This maybe doesn't make sense.  The record being updated here is the 'parent' of the 'children'
which will appear in the new list.

This probably only gets used within these omniclass methods, so I am just mentioning it so we
know it's there.

FYI, you can use this method to update the 'metainfo.children' column for ANY record in
the selected database, not just records for the selected datatype in $self->{dt}.

=head2 get_lineage()

This method returns a array reference listing the parents of a record, from the 'top' level
all the way to the immediate parent.  Use it like so:

	@$lineage = $dt_obj->get_lineage(
		'data_code' => $primary_key, # required; concat(code,'_',server_id) value of record
	);

That @$lineage array will look like: top, 2_1:4_1, 5_1:18_1

In this example, the record is positioned three levels from the top.  It's immediate parent is
the 18_1 record of datatype 5_1, then it's 'grand-parent' is record 4_1 of datatype 2_1, and then
it's great-grand-parent is the top-level of the database.

=head2 get_descendants()

This method returns a (complex) hash of all the records which are saved under a record, all the
way to the 'bottom' of the tree.  It depends on the metainfo table, so datatypes set with
skip_metainfo=Yes will not work.

	%$descendants = $dt_obj->get_descendants(
		'data_code' => $primary_key, # required; concat(code,'_',server_id) value of record
	);

That %$descendants hash will look like this

	$descendants = {
		'1_1:2_1' => {
			'children' => [
				'6_1:2_1',
				'6_1:3_1',
				'5_1:2_1',
			],
			'6_1:3_1' => {
				'children' => [
					'7_1:3_1'
				]
			},
			'6_1:2_1' => {
				'children' => [
					'7_1:1_1',
					'7_1:2_1',
					'7_1:116_1'
			]
		},
	};


Really recommended for when data is only two or three layers deep, but will go as low as you like.
Basically, each level has a 'children' entry with a list of the children ID's, and you can cycle
through those at that level to see if they have a children 'subkey.'  This is kind of evil because
it invites recursive subroutines.

=head2 parent_string_bits()

This method takes a parent string, which would appear in the 'parent' column of either the record's
primary/datatype-specific table or in metainfo.parent, and convert that to the primary key of
the datatype, followed by the 'code' and 'server_id' bits of the parent's primary key.  So for instance:

	($datatype,$code,$server_id) = $dt_obj->parent_string_bits('4_1:10_1');

The result would be $datatype would be '4_1', $code would be '10' and $server_id would be '1'.

Useful for preparing to pull the name of the parent.

=head2 prep_menu_options()

Uses the currently-loaded records to prepare an %$optons and @$options_keys set suitable to be used
with the form fields which use them (single_select, multi_select, radio_buttons, checkboxes).  I
wrote this 18 months in, and I really should have done this one day 100.

Usage:

	($options, $options_keys) = $dt_object->prep_menu_options();
	# No arg == uses 'name' for the values in %$options

	($options, $options_keys) = $dt_object->prep_menu_options('field_name');
	# Uses 'field_name' for the values in %$options

=head2 find_duplicates()

Helps to identify records with duplicate values, such as staff members with the same birth date or files with the same
names. Reports back a hashref with number of duplicates and the data codes for each duplicate.  I am not explaining
this well.  How about an example

	($duplicate_records,$duplicate_records_keys) = $device_object->find_duplicates(
		'fields_to_test' => 'birthdate', # required: the field to test; use a comma-separated list for multiple fields
		'minimum_duplicates' => 2, # optional; can be set to a higher number, i.e. if you want to find only 4 or more duplicates
									# default is 2
		'extra_sql_logic' => 'where status != ?', # optional: some extra SQL to filter the search
		'extra_sql_logic_bind_values' => ['Inactive'], # optional, bind values for your extra_sql_logic
	);

The %$duplicate_records hashref now is keyed by the duplicate values found for 'birthdate' and contains two sub-keys
under each 'birthdate' value: 'count' for the number of duplicates found and 'records_keys' as a comma-separated list
of the data_codes for the duplicated records.

This only tests on the primary table for the datatype and not against the virtual fields.

=head2 delete() & restore()

To delete a record:

	$dt_obj->delete(
		'data_code' => $data_code, # required; primary key of record to remove
		'skip_hooks' => 0 or 1, # optional; if '1', skip pre_delete and post_delete
	);

Will update $dt_obj->{status} as well as the 'update_history' table if the 'extended_change_history' option
is 'Yes' for that datatype.

Also, logs out to today's 'deletes_DBNAME_TABLENAME' log file under the $OTHOME/log directory.

If the record had previously been loaded into $dt-obj->{records} and $dt_obj->{metainfo} by load(), those hash
entries will be removed (i.e. it'll be taken out of there) and the key removed from $dt_obj->{records_keys}

NOT WELL TESTED: If datatype has 'archive_deletes' set to 'Yes,' then we will try to save the deleted record
to the datatype's database, in the 'deleted_data' table, which looks like:

	CREATE TABLE `deleted_data` (
	`code` int(11) NOT NULL AUTO_INCREMENT,
	`server_id` int(11) NOT NULL DEFAULT '1',
	`data_code` varchar(30) NOT NULL DEFAULT '0',
	`datatype` varchar(30) NOT NULL,
	`delete_time` int(11) NOT NULL DEFAULT '0',
	`deleter` varchar(30) NOT NULL,
	`data_record` longblob,
	`metainfo_record` longblob,
	PRIMARY KEY (`code`,`server_id`),
	KEY `data_code` (`data_code`),
	KEY (`data_code`,`datatype`)
	) ENGINE=MyISAM;

We make that a MyISAM table to keep it out of the InnoDB buffer pool for this database.  The 'data_record'
is a Storable-serialized version of the record from its primary table; the 'metainfo_record' is a
Storable-serialized version of the data's record from 'metainfo.'  We just use 'sql_hash' to pull out
these records to save.

Use this feature for only the most important data ;)  If it gets used a lot, then we need to circle
back to this feature and turn it into more of a full mirror of the source databases with all
table structures being kept up to date.

REALLY NOT WELL TESTED (BUT A LITTLE TESTED): To restore a record from deleted_data:

	$dt_obj->restore(
		'data_code' => $data_code, # required; primary key of record to restore
		'new_parent' => $new_parent_string, # optional; new parent identifier if we want to restore under
											# a new parent; otherwise, will try to go under former parent
	);

This will attempt to restore the record to the tables (primary table and metainfo) in the current
database, and will remove the saved record from archive.deleted_data.  Will update $dt_obj->{status} as well
as the 'update_history' table if the 'extended_change_history' option is 'Yes' for that datatype.

=head2 update_history()

Saves detail entries on data modification to the 'update_history' table within $self->{database}.
Used as needed within these methods, and available for your use elswehwere.

	$self->update_history($update_detail_text);

$update_detail_text can be quite long, but I would suggest limiting it somewhat.

=head2 get_access_roles()

Returns a key-value hash of this Application's Access Roles, along with arrayref of keys, sorted by
the names of the Roles.  Mainly used for the access_roles_select menus, but can have other uses, so
shared as a main method.

	Usage:  ($access_roles,$role_keys) = get_access_roles();

=head2 Running Background Tasks

There are certain tasks which should be run in the background, either because it's a heavy task or because
it interacts with external resources.  For this, we have the background_task_manager.pm portion of this kit.
The idea is to queue up a task to be run via a Perl script that is executed either by a every-X minute cron
task or from another external process-spawning program.

I should mention here that in order to use this feature, you have to have 'Supports Email & Background Tasks'
set to 'Yes' for this Datatype in the OmniTool Admin UI.

A background task represents a call to a custome method in your OmniClass Package, which should respond with
a two-item array; first item is a 'Success' for success or 'Error' for fail; second item is the error or
results messages. Error messages are logged into 'background_tasks' table and inthe 'task_execute_errors_DB-NAME'
log files.  Successful tasks' status messages will be logged to the 'task_execute_success_DB-NAME' log files.

There is an 'example_background_task' method in the OmniClass Package you can generate with the 'Get Package'
button under 'Manage Datatypes.'

When you need to spawn background tasks, you call 'add_task' like so:

	$new_task_id = $dt_obj->add_task(
		'method' => 'method_name' # required: the method in your OmniClass Package that will be performed in the background
		'data_code' => 'DATA_CODE', # optional/recommended; the primary key of a target data record
		'delay_hours' => some_decimel_number, # number of hours from now to wait before performing task; the background
			# script may perform it a bit later than these number of hours due to a backlog, but it will not do so before
			# these hours have past; for 10 minutes, use .17
			# optional, and default is 0
		'not_before_time' => optional; 	# unix epoch for the earliest time this task should run; overrides
										# 'delay_hours' argument
		'args_hash' => \%args, # optional: a hash reference of arguments to pass to the method we are calling
	);

If you wish to cancel that task later, you just need to do:

	$dt_obj->cancel_task($new_task_id);

You can get or set the task's status like so:

	$current_status = $dt_obj->task_status($new_task_id);

	$dt_obj->task_status($new_task_id,'Completed');

	$dt_obj->task_status($new_task_id,'Error','Error reason / message');

	$dt_obj->task_status($new_task_id,'Warn','Error reason / message');

Valid statuses for tasks are 'Pending','Completed','Cancelled','Error', 'Warn', 'Hold', and 'Retry'.
The 'Warn' status is meant to be a 'soft' error, mainly so that you can exclude those tasks from any
kind of daily/week report on errors.  Please use 'Warn' when the task either completed well enough,
or it's failure is not critical to your life being happy.

To retrieve the task ID and the method name for the next-to-run pending task for a record, you can:

	If the record is not already loaded:
	($pending_task_id, $pending_task_method) = $dt_obj->get_next_task_info($record_data_code);

	Or if the record is already loaded and in $dt_obj->{data} & $dt_obj->{data_code}
	($pending_task_id, $pending_task_method) = $dt_obj->get_next_task_info();

Tasks are run with background_tasks.pl, which is a cron script.  Please check out the 'Generate
Crontab' tool under Manage Instances to see how to best run $OTPERL/scripts/background_tasks.pl.

There is an outdated $OTPERL/scripts/background_tasks_forking.pl for an example of a script
which can spawn and run the multiple processes for background tasks, given an
Application Instance hostname as an argument.  I was using this via SystemD, but found that
running via Cron was a lot better.

Tasks are actually run via do_task() within background_task_manager.pm. Please note that do_task()
will automatically load up the data record in question, as well as act as the user for whom the
background task was queued.  So if Bob took an action in the Web UI on a Support Request record
to cause a background task to occur for that Support Request, it will be done as Bob's user.
This allows you to put in access-control logic as needed.

Automatic Retry: If a task causes a 'fatal' error, breaking its eval{} bonds before it can
properly return a 'Success' or 'Error' value, then do_task() will set it up to retry in one hour.
It will mark the status 'Retry,' put the 'not_before_time' to one hour out, and put a '1' in the
'auto_retried' column of the background_tasks table.  This will only happen once, so if it fails and
there is already a 1 in the auto_retried column, it will just mark the task 'Error.'  The idea
is that these hard breaks are usually caused by connectivity or a remote resource being
temporarily unavailable, and in my experience, the task will work again in just a few minutes.

Running Tasks: There 'Process Count for BG Tasks & Email' option when creating/updating a
Datatype in the OmniTool Admin UI, and lets you indicate a number of processes
to run for background tasks, so you will want to set up those multiple processes.
I am using '$OTPERL/scripts/background_tasks.pl' as a cron script (running multiple
instances) in order to execute these tasks.  Why am I using Cron when there are
newer technologies like Resque, RabbitMQ and SystemD?  Well, how about because Cron works
and works quite well.  No need to restart -- you get fresh scripts all the time,
and if it fails one minute, you fix it and succeed the next minute.  Please feel free to
modify my 'background_tasks.pl' script to run in a more modern context.

Monitoring Background Tasks: To "watch" background tasks for your Datatypes, navigate to
'Manage Instances' under the OmniTool Admin UI, and select 'Background Tasks' next to the
desired Application Instance.  This screen will allow you to search background tasks by
Datatype, Method, and Record ID (Altcode).  For failed tasks, you are able to see the error
messages and mark the task 'Retry.'

Pausing Tasks: do_task() will not do anything if the 'pause_background_tasks' column is
set to 'Yes' for the current Application Instance.  This allows for code deploys without
breaking background tasks, and can be set via the OmniTool Admin UI when updating an
Instance. (Or your CI can issue a nice SQL update command or two.)

Also, do_task() will periodically delete tasks which were marked Completed more than
30 days ago.  This will be attempted every 500-1000 seconds.

=head2 Instance Daily Taks

You may want to have Instance-wide background tasks running each day (or week).  Here is
how you set that up:

1. Navigate to the parent Application in the OmniTool Admin web UI and click 'Generate
	Daily Routines PM'.  This will provide the code you should save to 'common/daily_routines.pm
	in your Application's code directory.  This file is a sub-class of the Applications Instances
	OmniClass object.

2. Modify the run_daily_routines() in that new daily_routines.pm file so that it will
	run the Instance-wide tasks of your choosing.  Look for the %$luggage hashref for
	that instance in the arguments.  The user for that %$luggage will be the admin who
	completes step 3 below.  Also, please see the example code for limiting the day(s)
	upon which something is executed.

3. Navigate to the target Instance via the OmniTool Admin web UI and click 'Start Daily
	BG Tasks' from its Actions menu.  This will cancel any previously-scheduled daily
	background tasks and schedule a new one to start immediately, under the name of the
	admin who just clicked that link (which is you, by the way).  To monitor the daily
	background tasks, please navigate to the parent OmniTool Admin Instance and check
	the 'Background Tasks' Tool for the OT Admin Instance that contains the configs
	for your Instance --> so probably at the top level OT Admin Instance.

That last part is confusing.  Basically, you are creating a background task to run on
the App Instance, within its parent OT Admin Instance, so you have to watch it at the
higher level.

With that in mind, your best practice is for your daily Instance-wide tasks to actually spawn
a bunch of other background tasks to run within the Instance itself.

Also, please bear in mind that the daily tasks will happen each day, at roughly the time
you started them.

=head2 Generating & Sending Outbound Email

Similar to how background tasks can be spawn and run, you can generate outbound emails to
be sent in the background.  Also to use this feature, you have to have 'Process Count for BG Tasks
& Email' set to a non-zero number for the Datatype.

You must also configure the 'Info for Sending Email' field for each Application Instance
which uses this Datatype.  If you utilize the 'Gmail' server name, you may need to visit
this URL to 'unlock' the email account you wish to use:
	https://accounts.google.com/b/0/DisplayUnlockCaptcha
FYI, the 'Gmail' function is not really recommended, as Google might change everything
on a whim.

Outgoing emails are sent as HTML, and they are generated via Template-Toolkit templates,
to prevent you/me from stuffing a bunch of HTML into our OmniClass Packages.  There is a way
to send in a glob of HTML to be used as the body, discussed below, but please instead build
out your email templates in $OTPERL/applications/$app_code_directory/email_templates
(System-wide email templates are in $OTPERL/static_files/email_templates).

Here is how you queue a new outgoing email to send in the background:

	$new_email_id = $dt_obj->add_outbound_email(
		'to_addresses' => 'list,of,email,addresses', # required, comma-separated list of valid email addresses
			# you can just send base names if they are in the domain set in $ENV{OT_COOKIE_DOMAIN}
		'subject' => 'Subject Line', # required, the subject line of the email
		'from_address' => 'someone@email-domain.com', # optional; sender's email address; defaults to contact
			$ email for this app instance and then fails over to application contact, finally to $ENV{OTADMIN}
		'template_filename' => 'email_template.tt', # optional/recommended; a template-toolkit template which will
			# should be under either $OTPERL/static_files/email_templates or
			# $OTPERL/applications/$app_code_directory/email_templates
			# if blank, defaults to very-basic $OTPERL/static_files/email_templates/non_template.tt, which
			# expects a glob of HTML in $self->{email_vars}{message_body}
		'data_code' => $record_id, # optional/recommended, a primary key for a target data record for your email template to utilize
		'email_vars' => {}, # optional/recommended; extra variables to send into your email template.  If you are using the plain /
			# pass-through non_template.tt, then put a glob of HTML into the 'message_body' key under here;
			# this gets put into $self->{email_vars} for the template
		'attached_files' => 'list,of,file,ids', # optional; a comma-separted list of primary keys from the stored_files DB table for
			# this app instance; those files get loaded up automatically
	);

So if you want to make the very sad and disappointing decision to send in the message body already prepared,
place that into email_vars => { message_body => 'your body HTML' } } and leave 'template_filename' blank.

To send a specific email, you just:

	$dt_obj->send_outbound_email($email_id);

That $email_id would be the primary key of the record in the 'email_outbound' table in our Instance's database.

To send up to the next 20 emails waiting to be sent (status = 'Pending or 'Retry'), you would:

	$dt_obj->send_outbound_email();

When sending email, we will attempt to send to each recipient separately, so there is no need for BCC, and
one bad recipient will not fail the whole message.  If any recipient fails, the status of the record
will be marked 'Error,' and the errors will be logged into the 'email_errors' log file for this App Instance.
Successful sends will be logged to the 'email_sends' log file for this Instance, and if all recipients
are successful -- just that the messages went out, not necessarily delivered -- then the 'email_outbound.status'
column will be set to 'Completed.'

If you want to retry a message later, set the status to 'Retry'.  Be careful: some recipients may have
already received their copy.  Better to spawn a new message for the missed recipients.

The background_tasks.pl script run via cron will handle sending out your emails.  Most Datatypes which
have outbound emails will also have background tasks, but if you will only have or the other, you will
still need to set up that script to run via cron.  It will only take the needed actions.

Also, send_outbound_email() will also periodically delete email_outbound records marked Completed more
than 30 days ago.  This will happen every 500-1000 seconds.

=head2 Receiving and Processing Incoming Emails

You can have emails come in to your OmniTool system, and have your OmniClass Packages receive and process
those incoming emails.

For example, just out of the blue totally at random, you can have a support ticketing system, and receive
case/ticket updates via email.  A support user would put the case ID in the email's subject line, probably
within brackets, and your OmniClass Package would add that email's content to the case update history.

Here is how you set up email receiving/processing for a Datatype:

1. In the OmniTool Admin Web UI, update the Datatype and set a base email for the
'Account for Incoming Emails' field.  This is the email without the '@domainname' part;
that domain suffix is going to be Hostname for your Application Instance.  Remember that every
Instance will want to receive email for this Datatype.

2. Make a copy of omnitool/scripts/email_receiver.pl Perl Script and modify the %$resolver hash to
point your new email address(es) to the right database server/name.  You will need to add an entry
for each Application Instance that will receive email for this Datatype.

** Note, having configuration like this really isn't my style, but the idea for this script is that
it could run on a very vanilla MTA server which does not have full-on OmniTool installed.  I
probably should update it to just query a default database.

Please see the notes in email_receiver.pl about setting up the special database user account, and
really all of the rambling in there.

3. Configure your MTA or Postfix or whichever email server to receive email for the new email
address(es) and pipe that email into your copy of omnitool/scripts/email_receiver.pl

4. Set up an email_processor() method for the target Datatype's OmniClass Package.  There is an example
of this in the example_datatype_subclass.tt template under static_files/subclass_templates.

Basically, the email_receiver() receiving method (in omniclass/email_receiver.pm) will check in
the 'email_incoming' table, and un-pack the email with common/email_unpack.pm, producing a nice
%$email hash with all the email's particulars.  Please see the docs in email_unpack.pm for more
detail.  It will then call your custom email_processor(), and expect back either 'Success' or
'Error' and some useful error message. Then email_receiver() will log out to the 'email_errors_'
or 'email_parsing_' log, and update the 'status' (and possible 'error_message') column in
'email_incoming'.  Whatever you want to actually do with that email and its attachment(s),
please do within email_processor().

5. Flush your Datatypes hash (via Manage Instances or Manage Datatypes) and then restart your
background processing script.  After that, it *should* work.  Probably.  Should.

email_receiver() is called in the background_tasks_forking.pl script.  If you write your own
script for background tasks and incoming/outgoing email, please make sure to call all the bits
that background_tasks_forking.pl does.  I could see the point of having three separate scripts,
though I think sending out new emails should happen directly after processing background tasks,
as those task often create new emails to send out.

What's really sad about that last paragraph is that I wrote it on a Saturday night.

=head2 Having Multiple Worker Nodes for Background Tasks & Email Functions

You will likely want to separate your background task and email handling functions from
your Plack service, and if your system is busy, you may want to have multiple background
worker nodes.  This is pretty straightforward:

Simply install OmniTool onto the new workers (or clone your existing OmniTool VM into a new
worker), and setup/modify the crontab for that worker so that the 'WORKER_ID' environmental
variable is set to a unique number in your system.  This will allow tasks to be properly
locked and for you to monitor where these tasks are running / have run.  Having dedicated
worker nodes does allow you to run many more copies of background_tasks.pl without a
performance hit.

=head2 Hooks & Datatype-Specific Sub-Classes ("OmniClass Packages")

The base OmniClass module is pretty nice, but the real fun starts when you prepare a sub-class for
your new Datatypes.  This allows you to use any or all of the special 'hook' rountines below as well
as to add any method you like to the sub-class for added functionality.

Rather than call these modules 'OmniClass sub-classes," we are going to call them "OmniClass Packages."
These are sub-classes of OmniClass, but I just cannot write 'OmniClass sub-class" any more; it really
does not reflect well on me at all.

Once you create the new datatype, you can generate a starter / example OmniClass Package via the 'Get
Sub-Class' option next to the Datatype in the Manage Datatypes tool.  It will show you what's needed
to get started, plus lots of examples.  The key is "use parent 'omnitool::omniclass;" of course.
Also, your OmniClass Package should not have it's own 'new()' routine, as so much goes on in
omniclass->new(). You can have an 'init()' in there, which will be automatically called at the
end of new().

Psst: new() adds alias to the utility_belt.pm object from %$luggage to $dt_obj->{belt} for easy use
in your OmniClass Packages ;)

The hooks detailed below will be automatically called at the right times if they appear in your
OmniClass Packages.  If you add other methods, then your Tool.pm sub-classes, background tasks, or
scripts will need to specifically call for those special methods.

Remember that when instantiating the OmniClass object, or in calling load(), save(), search(),
and delete(), you can set a 'skip_hooks' argument to prevent the execution of the hook methods,
even if they exist.

Here is a brief discussion of the hook methods you can create:

	- pre_load(%$args): Called at the start of load() before loading records from the database.
		Useful to adjust which records will be loaded or in fetching extra data to prepare
		for the Virtual Field Hooks.  Receives a reference to the arguments hash passed
		into the load() method.

	- pre_virtual_fields(%$args):  Called during load(), after loading records from the database but before
		running the virtual fields' methods (which would be in your OmniClass Package).
		Useful to load up additional data or modify your loaded DB data before building the virtual fields.
		Receives a reference to the arguments hash passed into the load() method.

	- field_XYZ(%$args): These 'field_*' hooks are called during the load() process to
		implement the 'virtual fields' functionality.  You are able to add a Datatype Field
		with 'Virtual Field' set to 'Yes', in which case you should set up a method in
		your OmniClass Package named as 'field_' plus the 'MySQL Table Column' value of your
		Datatype Field, aka the 'table_column' entry.  So if your Table Column is 'color'
		then this method would be named 'field_color'.

		This hook can do anything you want, actually, but it should setup a value for its
		'table_column' for each of the loaded records under $self->{records}.  For this example,
		it would build up $self->{records}{$id}{ginger}.  The values added to the records could be
		either (a) just a text string or (b) an array of hashes, like so:

			$self->{records}{$id}{ginger} = [{
				'text' => 'Some Text',
				'uri' => 'tool_uri',  # direct link
					# can also use 'default_inline_tool' which will send to the first inline tool for this record
				'glyph' => 'font-awesome icon',
				'image' => '/path/to/image',
				'class' => 'css_class_name_for_div',
				'no_div' => 'fill_in_to_skip_divs_and_just_have_comma_list',
				'action_uri' => 'tool_uri', # link to subroutine within current tool to reprocess jemplate
				'message_uri' => 'tool_uri', # link to subroutine within current tool to present a text message modal,
				}, # can have more of the same
			];

		This structure is used for the view mode Jemplates to build nice columns for display.
		None of those keys are required; you can have any combination of them that you wish/need
		for your Jemplate; you can also add other keys if you need.

		As you create these complex / generated virtual fields, you may also want to create simple/plain
		corresponding data bits for easy sorting.  So for the above example, you might create
			$self->{records}{$id}{ginger_sortable} = 'Some Text';
		and then enter 'ginger_sortable' into the 'Alternative Column for Sorting' value for the
		Datatype Field definition for this Virtual Field.

		This method receives a reference to the arguments hash passed into the load() method.

	- post_load(%$args): Called at the end of load(), after loading records from the database and
		executing any virtual fields' methods.	Useful to alter or trim the loaded data, or for actions
		which can only occur when all records are loaded. Receives a reference to the arguments hash passed
		into the load() method.

	- pre_save(%$args): Called at the start of save(), before creating or updating the record(s).
		Useful for altering the data you are going to use for the save, or to stop the save
		in its tracks by setting 'cancel_save' into the reference it receives to the arguments
		hash passed into save().  The right place for a sanity check.

	- post_save(%$args): Called at the end of save().  Good for any clean-up actions from a save,
		or for setting/sending notifications of the data create/update.  Receives a reference to the
		arguments hash passed into the save() method.  Note that the data_code of the just-saved
		record will be in $self->{last_saved_data_code}.

	- pre_search(%$args): Called at the start of search(), before setting up and executing a search
		for records in the database.  Useful for modifying (or adding to) the arguments passed into
		the search.  Receives a reference to the arguments hash passed into the search() method.
		Remember that any previously run search's args will be available in $self->{prior_search_args}.
		Can also set $self->{cancel_search} to stop the search from executing.

	- post_search(%$args): Called at towards the end of search(), after the search was executed but before
		the records are auto-loaded, if the 'auto_load' arg was set.  Can modify the search results within
		$self->{search_results} (which is an arrayref of the data codes of the matching records.).
		Receives a reference to the arguments hash passed into the search() method.

	- pre_delete(%$args): Called before a record is deleted, but after the data lock is checked.  Can
		set $$args{cancel_delete} to stop the deletion from happening.  May also be useful for sending
		out any notices of the deletion while the data still exists.  Receives a reference to the
		arguments hash passed into the delete() method.

	- post_delete(%$args):  Called after the deletion has occurred.  Useful for performing any data
		actions to adjust to the new world without the removed record.  Receives a reference to the
		arguments hash passed into the delete() method.

	- prepare_for_form_fields($form):  Runs towards the middle of the form() routine, after the
		general preparation of the form is complete but before each form field's sub-structure
		is built.  Receives the $form hashref, which includes the arguments passed into the form()
		method as well as the form's structure so far.  Useful to prepare data which will be shared
		between the 'options_*' hooks described below.  Could also adjust the fields which shall
		be built.

	- options_XYZ($data_code):  Used to prepare the options to be presented for a select, checkboxes,
		or radio buttons field.  'XYZ' is the DB table column for the Datatype field which will be
		represented by this form field.  The '$data_code' is the primary key for the record being
		updated in the field, if we are updating.  This hook should return a hashref to a simple
		key=value structure with the option values and names, along with an arrayref to the keys
		for that simple hash, in the order you wish to display them.

	- options_from_directory($directory,$file_ext,$keep_ext): This method is inside form_maker.pm
		and called from your 'options_XYZ' hooks.  It returns the hashref/arrayref combo for
		options based on files in the directory you specify.  First argument is required and is
		the full path to the directory; second argument is optional and is the file extension
		of the files to list (defaults to 'pm' for Perl modules); third option is optional, if
		filled will prevent the file extension from being trimmed from the filenames.

	- post_form_operations($form): Called at the end of form(), and is useful to modify the %$form
		structure before sending it back to the browser.  Receives a reference to the %$form structure.

	- post_validate_form($form): Kind of an oddball for being called from omnitool::tool::action_tool
		and not an OmniClass module.  Meant to do form validation for a Tool.  The good and proper
		reason for allowing a direct hook from Tool.pm sub-classes is to push the Datatype logic
		under the OmniClass Packages.  However, the real reason is to allow for the 'standard_data_actions'
		to utilize post_validate_form() hooks.  If an value for a field 'fails' validation,
		$self->{stop_form_action} should be set to '1', along with $self->{json_results}{form}{fields}{$field}{field_error}
		where $field is the key of the incorrect field.  The omnitool::tool::action_tool routines will take
		it from there.

	- autocomplete_XYZ: supports the auto-suggest feature of the 'short_text_tags' and 'short_text_autocomplete'
		fields.  The 'XYZ' is the database column name of the target field.  Should work with a query term
		in $self->{luggage}{params}{term} and return a simple arrayref of results.

	- time_adjust(%args): This is a nice subroutine included in loader.pm meant to make it very easy to
		convert UNIX epoch values into human-readable formats, time offset based on the user's timezone
		(which is snagged into their luggage, see the notes at the bottom of pack_luggage.pm).  Here
		is the usage:

		$formatted_time = $self->time_adjust(
			'unix_timestamp' => $epoch, # required arg, the unix epoch to adjust
			'time_to_date_task' => $task, # optional, a task to use to pass this epoch through utility_belt.pm's time_to_date()
				# defaults to 'to_date_human_time'
			'timezone' => $timezone, 	# optional, an alternative timezone (EST, PDT, etc), if we don't want to
				# use $self->{luggage}{timezone}
		);


All of these are able to modify $self, so please be careful.

=head2 About Dynamic Polymorphism

It pained me to write that heading.  What I mean to say is "extending your OmniClass subclass on the fly."
There may come a time when you want to add features and capabilities (methods) to your subclass based on
some logic.  Since this is Perl, it's really easy.

For example, let's say your Application is for kitchen appliances, and you have a nice Datatype named
Kitchen Appliance with an OmniClass subclass at omnitool::applications::kitchen::appliance.  This
subclass would naturally have methods for power_on() and power_off() and maybe get_cleaned().  (I see
now what a terrible example this is, but let's press ahead.)  The Kitchen Appliance Datatype has a single-select
field set up for 'Type' and your options are 'Oven', 'Fridge', 'Microwave' and so forth.  If that choice
is set to 'Fridge', you may want your omnitool::applications::kitchen::datatypes::appliance object to morph into a
omnitool::applications::kitchen::datatypes::appliance::fridge, with cool new methods for cool_food_down()
and light_on() and leak_all_over_the_nice_hardwood_floors() -- but still have all of the capabilities of
the original omnitool::applications::kitchen::datatypes::appliance object.

You can totally do this, so long as omnitool::applications::kitchen::datatypes::appliance::fridge is a subclass
of omnitool::applications::kitchen::datatypes::appliance.  You can even change it to a
omnitool::applications::kitchen::appliance::oven object later on, although that would be weird.

Note:  This kind of morphing-around should be rare, as you'd really want to have different Datatypes
and subclasses set up for materially different things.  This comes into play more when you are trying
to manage related-but-different data as one Datatype and via one Tool and you need to shoehorn it
together to work.  Only do this when it's really necessary!

Second note:  You should only do this if there is one record loaded in the object, as if there are
multiple records, they may not all qualify for the new subclass.  Handle this in your code, and maybe
test multiple records if you so dare.

Here is how I sometimes do it:

1. In the primary Datatype subclass (appliance.pm), import the possible sub-subclass(es) at the top:
	use omnitool::applications::kitchen::datatypes::appliance::fridge;
	use omnitool::applications::kitchen::datatypes::appliance::oven;

2. In the fridge.pm and oven.pm packages, identify the primary Datatype subclass as the parent:
	use parent 'omnitool::applications::kitchen::datatypes::appliance';

	This is quite important so you don't lose your parent's methods and attributes.

3. Back in appliance.pm, add a method which will re-bless the object based on logic:

	sub choose_appliance_subclass {
		my $self = shift;

		#  only do this if there is one record loaded, no more and no less
		return 'Unchanged' if $self->{records_keys}[1] || !$self->{records_keys}[0];

		# proceed based on our 'Type' field

		# rebless as a Fridge
		if ($self->{data}{appliance_type} eq 'Fridge') {
			bless $self, 'omnitool::applications::kitchen::datatypes::appliance::fridge';
			return 'Now a Fridge';

		# rebless into an Oven ?
		} elsif ($self->{data}{appliance_type} eq 'Oven') {
			bless $self, 'omnitool::applications::kitchen::datatypes::appliance::oven';
			return 'Now an Oven';

		# no change
		} else {
			return 'Unchanged';
		}

		# the return is totally optional
	}

Here is a more dynamic way, if you feel snarky:

	sub choose_appliance_subclass {
		my $self = shift;

		#  only do this if there is one record loaded, no more and no less
		return 'Unchanged' if $self->{records_keys}[1] || !$self->{records_keys}[0];

		# calculate the class_name based on the field
		my $class_name = lc($self->{data}{appliance_type});

		# we need its path in the file system
		my $class_path = $ENV{OTHOME}.'/code/omnitool/applications/kitchen/datatypes/appliances/'.$class_name.'.pm';

		# return if module does not exist
		return 'Unchanged' if !(-e "$class_path");

		# load it in - log out if error
		my $the_class_name = 'omnitool::applications::kitchen::datatypes::appliance::'.$class_name;
		unless (eval "require $the_class_name") {
			$self->{belt}->logger("Could not import $the_class_name: ".$@,'superfatals');
		}

		# and finally rebless it
		bless $self, "$the_class_name";
		return 'Now an '.$self->{data}{appliance_type};

	}

I am really not sure which is best.  The second reduces your need to re-code choose_appliance_subclass()
as you add options for the Appliance Type, but perhaps that's minimal compared to creating a whole
other class.

You would probably want to call choose_appliance_subclass() as part of your pre_virtual_fields() hook so that
it can evaluate the info from the database, and then generate Virtual Fields for the specific sub-type.  Yes,
you can safely define Virtual Fields for different sub-classes under the same Datatype; it will just ignore
those Virtual Fields which cannot be built in the current context.

If your Search Tool is set up to only show one sub-type of your Datatype at once (i.e. only Ovens or
only Fridges), then you could dispense with the requirement to only have one record loaded - or override
that policy via an argument.  Otherwise, this will work great for Action Tools that load one record at
a time.
