package omnitool::common::table_maker;
# please see perldoc comments below

# sixth time is the charm
$omnitool::common::table_maker::VERSION = '6.0';

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# time to grow up
use strict;

# set myself up: get the DB handle & datatype hash for the target instance
sub new {
	my $class = shift;
	# required arguments
	my (%args) = @_;
	# looks like:
	#	'luggage' => $luggage,
	#	'app_instance' => $instance_primary_key or $hostname,
	#	'instance_omniclass_object' => $instance_omniclass_object --> optional omniclass object for instance
	# 													will have it if you are working within the setup mysql tool

	# really must have the luggage, a database connection and aninstance.
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't start table_maker.pm without my luggage.'});
	} elsif (!$args{app_instance}) {
		$args{luggage}{belt}->mr_zebra('Cannot start table_maker.pm module without an Instance code.',1);
	}

	# if the sent instance is a hostname, convert to the primary key
	if ($args{app_instance} =~ /[a-z]/i) {
		$args{app_instance} = lc($args{app_instance});
		($args{app_instance}) = $args{luggage}{db}->quick_select(qq{
			select concat(code,'_',server_id) from instances where hostname=?
		},[$args{app_instance}]);
	}

	# load up the instance via omniclass, unless it was already provided in the args
	if (!$args{instance_omniclass_object}->{data}{name}) {
		$args{instance_omniclass_object} = $args{luggage}{object_factory}->omniclass_object(
			'dt' => '5_1',
			'skip_hooks' => 1,
			'skip_db_ready_check' => 1,
			'data_codes' => [$args{app_instance}]
		);
	}
	# get the parent application for this instance
	($args{parent_application_id} = $args{instance_omniclass_object}{data}{metainfo}{parent}) =~ s/^1_1://;

	# now set the database handle to point to the database server for this instance
	$args{instance_db_obj} = $args{luggage}{belt}->get_instance_db_object($args{app_instance}, $args{luggage}{db}, $args{luggage}{database_name});

	# get the database name for this instance
	$args{database_name} = $args{instance_omniclass_object}{data}{database_name};

	# next get the datatypes hash for this instance / application - grab the latest via no-caching
	$args{app_datatypes} = get_datatypes_hash($args{instance_omniclass_object}{data}{hostname}, $args{instance_db_obj},1);

	# identify the list of tables which should be in this database, based on the defined datatypes
	# start with the baseline tables
	@{$args{needed_tables}} = (
		'background_tasks','deleted_data','email_outbound','email_incoming','metainfo','stored_files',
		'tools_display_options_cached','tools_display_options_saved','update_history'
	);
	# use those as keys for the base_tables hash below
	@{$args{baseline_tables_list}} = (
		'background_tasks','deleted_data','email_outbound','email_incoming','metainfo','stored_files',
		'tools_display_options_cached','tools_display_options_saved','update_history'
	);

	# and go through each datatype and add it's table (and metainfo table)
	my $dt;
	foreach $dt (split /,/, $args{app_datatypes}{all_datatypes}) {
		# primary table for the dt
		push(@{$args{needed_tables}},$args{app_datatypes}{$dt}{table_name});
		# does it have its own metainfo table?
		if ($args{app_datatypes}{$dt}{metainfo_table} eq 'Own Table') {
			push(@{$args{needed_tables}},$args{app_datatypes}{$dt}{table_name}.'_metainfo');
		}
	}

	# track baseline tables; in hash format for easy checking
	$args{baseline_tables} = {
		'background_tasks' => 1,
		'deleted_data' => 1,
		'email_outbound' => 1,
		'email_incoming' => 1,
		'metainfo' => 1,
		'stored_files' => 1,
		'tools_display_options_cached' => 1,
		'tools_display_options_saved' => 1,
		'update_history' => 1,
	};

	# now bless the %args into the object
	my $self = bless \%args, $class;

	# send it out
	return $self;
}

# method to check if the database for this instance exists (oh yeah, probably should do this)
sub check_database_existence {
	my $self = shift;
	# no argument: relies on instance information fetched during new()

	# use information_schema to figure it out
	($self->{database_existence}) = $self->{instance_db_obj}->quick_select(
		'select count(*) from information_schema.schemata where schema_name=?',
		[$self->{database_name}]
	);

	# no need to return; $self->{database_existence} is 1 or 0

}

# method to check which tables exist or need to be created
sub check_tables_existence {
	my $self = shift;
	# only arg is optional; a table name to check in the instance's database; if empty, will check all tables
	my ($table_name) = @_;

	# declare vars
	my ($check_tables, $table, $existing_tables,$et_keys);

	# determine which tables to check
	if ($table_name) {
		$$check_tables[0] = $table_name;
	# otherwise, look at all needed tables
	} else {
		$check_tables = $self->{needed_tables};
	}

	# use information_schema to figure it out
	($existing_tables,$et_keys) = $self->{instance_db_obj}->sql_hash(
		'select table_name,engine from information_schema.tables where table_schema=?',
		'bind_values' => [$self->{database_name}]
	);

	# now create our results, loading into $self
	foreach $table (@$check_tables) {
		if ($$existing_tables{$table}{engine}) {
			$self->{tables_existence}{$table} = 1;
		} else {
			$self->{tables_existence}{$table} = 0;
		}
	}

	# all done

}

# method to create a database for an instance on its server
# just a little dangerous...but trust is important in life
sub create_database {
	my $self = shift;

	# paranoia; the short_text_clean / force_alphanumeric options should have
	# short-circuited any problems, but can't use placeholders here
	$self->{database_name} =~ s/[^a-z0-9\_]//gi;
	# lower case!
	$self->{database_name} = lc($self->{database_name});

	# pretty simple sql statement
	$self->{instance_db_obj}->do_sql(
		'create database '.$self->{database_name}.
		qq{ default character set utf8 default collate utf8_general_ci}
	);

	# create any tables needed at this point
	$self->create_tables();

	# logging in the $db object should handle any errors
}

# combiner/wrapper subroutine to create any/all the needed tables, be they baseline
# tables or datatype tables; you can pass it the names of tables to create, or if no tables
# sent, we will try to create all needed tables
sub create_tables {
	my $self = shift;
	my (@create_tables) = @_;

	# declare some vars
	my ($check_along_the_way, $table_name);

	# if none table names sent, go for all of them
	if (!$create_tables[0]) {
		@create_tables = @{ $self->{needed_tables} };
		# make sure we check the existence of these tables for our subordinate methods
		$self->check_tables_existence();
	# otherwise, we just need to check the existence of those tables which were sent, as we go
	} else {
		$check_along_the_way = 1;
	}

	# now cycle through our list of tables
	foreach $table_name (@create_tables) {
		# check for it's existence, if we need to do so
		$self->check_tables_existence($table_name) if $check_along_the_way;

		# use the correct sub-method
		if ($self->{baseline_tables}{$table_name}) { # baseline table
			$self->create_baseline_tables($table_name);
		# it may be a datatype_metainfo table
		} elsif ($table_name =~ /\_metainfo/) {
			$self->create_datatype_metainfo_table($table_name);
		} else { # datatype table
			# translate it to a datatype ID for our subroutine
			$self->create_datatype_table( $self->{app_datatypes}{table_names_to_ids}{$table_name} );
		}
	}

	# all done

}

# method to create the baseline tables for a new datatype
# takes optional arguments of the table names to create; if none
# sent, will try to create all the baseline tables
sub create_baseline_tables {
	my $self = shift;

	my (@create_tables) = @_;

	# declare some vars
	my ($table_name, $new_table_name);

	# if no tables, try to create them all
	if (!$create_tables[0]) {
		@create_tables = @{$self->{baseline_tables_list}};
	}

	# now go through each one
	foreach $table_name (@create_tables) {
		# and skip if it's not a baseline table
		next if !$self->{baseline_tables}{$table_name};
		# or if already exists
		next if $self->{tables_existence}{$table_name} == 1;

		# if still here, rely on our omnitool admin DB again
		$new_table_name = $self->{database_name}.'.'.$table_name;
		# use the base_table in the omnitool admin database as the starter template
		$self->{instance_db_obj}->do_sql(
			'create table '.$new_table_name.' like omnitool.'.$table_name
		);

		# don't let this happen again
		$self->{tables_existence}{$table_name} = 1;
	}

}

# method to create a mysql table for a new datatype; called from create_tables();
# meant to be called on one datatype at a time; single arg is datatype id
sub create_datatype_table {
	my $self = shift;

	# datatype id is required
	my ($dt_id) = @_;

	# must be a legit datatype
	return if !$dt_id || !$self->{app_datatypes}{$dt_id}{name};

	# declare some vars
	my ($new_table_name, $dtf, $table_name);

	# skip if this table already exists
	$table_name = $self->{app_datatypes}{$dt_id}{table_name}; # sanity
	return if $self->{tables_existence}{$table_name} == 1;
	# or if it's a baseline table
	return if $self->{baseline_tables}{$table_name};

	# use figure_datatype_table_columns() below to get the correct columns
	$self->figure_datatype_table_columns($dt_id);

	# we'll need this a few times:
	$new_table_name = $self->{database_name}.'.'.$table_name;

	# use the base_table in the omnitool admin database as the starter template
	$self->{instance_db_obj}->do_sql(
		'create table '.$new_table_name.' like omnitool.base_table'
	);

	# and add in the columns
	foreach $dtf (@{ $self->{app_datatypes}{$dt_id}{fields_key} }) {
		next if $self->{app_datatypes}{$dt_id}{fields}{$dtf}{virtual_field} eq 'Yes'; # only real db fields

		# use our handy subroutine below
		$self->add_datatype_table_column($dt_id,$dtf);
	}

	# if it needs its own metainfo table, and that does not exist, create it
	if ($self->{app_datatypes}{$dt_id}{metainfo_table} eq 'Own Table' && $self->{tables_existence}{$table_name.'_metainfo'} == 0) {
		$self->create_datatype_metainfo_table($table_name.'_metainfo');
	}

}

# method to create the datatype-specific metainfo tables
# one argument is the proposed table name, which should be DT-TABLE-NAME_metainfo
sub create_datatype_metainfo_table {
	my $self = shift;
	my ($table_name) = @_;

	# return if it does not include '_metainfo'
	return if $table_name !~ /.*\_metainfo/;
	# or if already exists
	return if $self->{tables_existence}{$table_name} == 1;

	# use the metainfo in the omnitool admin database as the starter template
	$self->{instance_db_obj}->do_sql(
		'create table '.$self->{database_name}.'.'.$table_name.' like omnitool.metainfo'
	);

	# don't let this happen again
	$self->{tables_existence}{$table_name} = 1;

}

# method to check a datatype's table definition against what it should be
# takes a datatype ID as a required argument; optional second arg instructs
# us to create any missing columns
sub verify_datatype_table_columns {
	my $self = shift;

	# datatype id is required
	my ($dt_id,$create_missing_columns) = @_;

	# must be a legit datatype
	return if !$dt_id || !$self->{app_datatypes}{$dt_id}{name};

	# use figure_datatype_table_columns() below to get the correct columns
	$self->figure_datatype_table_columns($dt_id);

	# localize some vars
	my ($table_name, $dtf, $table_column, $current_columns,$cur_cols_keys);

	# sanity for the variable name
	$table_name = $self->{app_datatypes}{$dt_id}{table_name};

	# pull the columns for this table from information_schema
	($current_columns,$cur_cols_keys) = $self->{instance_db_obj}->sql_hash(
		qq{
			select column_name,column_type from information_schema.columns
			where table_schema=? and table_name=?
		},
		'bind_values' => [$self->{database_name},$table_name]
	);

	# now go through each datatype field
	foreach $dtf (@{ $self->{app_datatypes}{$dt_id}{fields_key} }) {
		next if $self->{app_datatypes}{$dt_id}{fields}{$dtf}{virtual_field} eq 'Yes'; # only real db fields

		# variable name sanity
		$table_column = $self->{app_datatypes}{$dt_id}{fields}{$dtf}{table_column};

		# does it exist?
		if (!$$current_columns{$table_column}{column_type}) { # nope
			# note it in the object
			$self->{mysql_status}{$table_name}{$table_column} = 'ERROR: Column not found in DB.';
			# do they want to auto-create the missing columns?
			if ($create_missing_columns) { # yes, do it and notate
				$self->add_datatype_table_column($dt_id,$dtf);
				$self->{mysql_status}{$table_name}{$table_column} .= '..but it was auto-created';
			}
		# if it exists but does not match our target, just notate; they must manually change
		} elsif ($$current_columns{$table_column}{column_type} ne $self->{app_datatypes}{$dt_id}{fields}{$dtf}{mysql_table_column}) {
			$self->{mysql_status}{$table_name}{$table_column} = 'ERROR: Incorrect column type: '.$$current_columns{$table_column}{column_type}.' -- Should be: '.$self->{app_datatypes}{$dt_id}{fields}{$dtf}{mysql_table_column};
		# otherwise, it is in there correctly, make note
		} else {
			$self->{mysql_status}{$table_name}{$table_column} = 'OK';
		}
	}
}

# subroutine to add in columns to a datatype's mysql table; meant to do one column/field at a time
# two required args: datatype ID and datatype field ID
sub add_datatype_table_column {
	my $self = shift;
	# grab our datatype and field ID's
	my ($dt_id,$dtf_id) = @_;

	# if we do not have the field->mysql translation, run this for the whole datatype
	# (chances are we are running against the whole DT anyway)
	if (!$self->{app_datatypes}{$dt_id}{fields}{$dtf_id}{mysql_table_column}) {
		$self->figure_datatype_table_columns($dt_id);
	}

	# sanity for table name
	my $table_name = $self->{app_datatypes}{$dt_id}{table_name}; # sanity

	# make sure the table exists
	$self->check_tables_existence($table_name);
	return if $self->{tables_existence}{$table_name} != 1;

	# run the alteration to add in this column
	$self->{instance_db_obj}->do_sql(
		'alter table '.$self->{database_name}.'.'.$table_name.' add '.$self->{app_datatypes}{$dt_id}{fields}{$dtf_id}{table_column}.' '.
		$self->{app_datatypes}{$dt_id}{fields}{$dtf_id}{mysql_table_column}
	);


}


# method to translate field columns into mysql column definitions
# takes a datatype ID as an argument; alters the
# $self->{app_datatypes}{$dt_id}{fields} in place
# called from verify_datatype_table_columns() and add_datatype_table_columns()
sub figure_datatype_table_columns {
	my $self = shift;

	# datatype id is required
	my ($dt_id) = @_;

	# must be a legit datatype
	return if !$dt_id || !$self->{app_datatypes}{$dt_id}{name};

	# hash of OT field types to MySQL column types; LENGTH will get regexp'ed
	my $field_types = {
		'access_roles_select' => 'text',
		'active_status_select' => 'varchar(8)',
		'check_boxes' => 'text',
		'color_picker' => 'varchar(40)',
		'email_address' => 'varchar(LENGTH)',
		'file_upload' => 'varchar(300)',
		'font_awesome_select' => 'varchar(30)',
		'hidden_field' => 'varchar(300)',
		'high_decimal' => 'decimal(15,2)',
		'high_integer' => 'int(10)',
		'long_text' => 'mediumtext',
		'low_decimal' => 'decimal(9,2)',
		'low_integer' => 'int(3)',
		'month_name' => 'varchar(15)',
		'multi_select_ordered' => 'text',
		'multi_select_plain' => 'text',
		'password' => 'varchar(250)',
		'phone_number' => 'varchar(30)',
		'radio_buttons' => 'varchar(LENGTH)',
		'rich_long_text' => 'mediumtext',
		'short_text' => 'varchar(LENGTH)',
		'short_text_clean' => 'varchar(LENGTH)',
		'short_text_encrypted' => 'text',
		'short_text_autocomplete' => 'varchar(LENGTH)',
		'short_text_tags' => 'text',
		'simple_date' => 'varchar(10)',
		'single_select' => 'varchar(LENGTH)',
		'street_address' => 'text',
		'web_url' => 'varchar(LENGTH)',
		'yes_no_select' => 'varchar(3)',
	};
	# declare vars
	my ($dtf, $field_type);

	# go through the non-virtual fields
	foreach $dtf (@{ $self->{app_datatypes}{$dt_id}{fields_key} }) {
		next if $self->{app_datatypes}{$dt_id}{fields}{$dtf}{virtual_field} eq 'Yes'; # only real db fields

		# some sanity
		$field_type = $self->{app_datatypes}{$dt_id}{fields}{$dtf}{field_type};

		# use the above hash to resolve it into 'mysql_table_column'
		($self->{app_datatypes}{$dt_id}{fields}{$dtf}{mysql_table_column} = $$field_types{$field_type}) =~ s/LENGTH/$self->{app_datatypes}{$dt_id}{fields}{$dtf}{max_length}/;
	}

}

1;

__END__

=head1 omnitool5::common::table_maker;

This class provides the functions to create the MySQL databases for your Application Instances.
Using this object, you can create the database, the tables you need, as well as add columns to
the datatype tables as you add datatype fields.  It will not allow you to delete or modify columns,
as that is very dangerous, so you must log into MySQL and do that directly.

I am placing these functions here because (a) I want all SQL commands under either omnitool::common::
or omnitool::omniclass:: and (b) this allows you to write scripts for automatic instance creation.

Generally, this class is used from the 'Setup MySQL Tables' action under 'Manage Instances' in the
OmniTool Administration UI.  The Tool.pm sub-class which drives that is at
omnitool::applications::otadmin::tools::make_tables .

Fun Update: In omniclass->new(), we shall call omniclass->database_is_ready(), which works with
table_maker.pm to make sure the Datatype table exists and has all the needed columns -- and create
the table/columns as needed. This is very convenient for changing your Datatypes on the fly.  That will
reduce your trips into 'Setup MySQL Tables' under 'Manage Instances.'

Regarding the database-wide tables, I refer to these as 'baseline' tables and 'datatype' tables.
The 'baseline' tables are the standard issue tables which should be in every OmniTool App Instance
database, and they are 'metainfo', 'tools_display_options_cached', 'tools_display_options_saved',
'update_history' and 'files'.  The 'datatype' tables refer to the Datatypes which are set up
via Manage Datatypes and where data goes in via OmniClass.  Note that a Datatype can be
set to have it's own metainfo table, and that would go along with the 'datatypes' tables.

=head2 new()

	$table_maker = omnitool::common::table_maker->new(
		'luggage' => $luggage,  # very much required
		'app_instance' => $instance_primary_key or $hostname,
		'instance_omniclass_object' => $instance_omniclass_object --> optional omniclass object for instance
																	will have it if you are working within
																	the setup mysql tool (make_tables.pm)
	);

	The resulting $table_maker object will have several useful attributes:

		- instance_db_obj --> the db.pm object / handle for the target Instance's database server.
		- database_name --> the name of the target Instance's database, or at least what it should be.
		- app_datatypes --> the datatypes hash for the target Intance's parent Application.
		- parent_application_id --> the data_code for the Instance's parent Application.
		- needed_tables --> an arrayref of a list of the needed tables.
		- baseline_tables --> a hashref for the baseline tables, indicating a '1' that they are in that group.
		- baseline_tables_list --> an arrayref of a list of the baseline tables.

=head2 check_database_existence()

	$table_maker->check_database_existence();

	If the database is defined for the Instance exists, then after calling this method,
	$table_maker->{database_existence} will be set to 1.  Otherwise, it'll be 0 or false.

=head2 check_tables_existence()

	This method verifies if a table exists in the Instance's database, and has two
	forms to call:

	$table_maker->check_tables_existence();

	This form checks all tables which are currently required for the Instance, as per the
	defined datatypes, as well as the baseline tables.  It will fill in the
	$table_maker->{tables_existence} sub-hash such that if table1 does not exist
	and table2 does exist, then you will get

	$table_maker->{tables_existence}{table1} = 0
	$table_maker->{tables_existence}{table2} = 1

	$table_maker->check_tables_existence('table_name');

	This form just checks for the existence of 'table_name' table in the Instance's database
	and fills in $table_maker->{tables_existence}{table_name} as 0 or 1 appropriately.

	For the schema-changing commands below, error logging is basically handled by db.pm, which
	will throw fatal errors.  I believe that errors should be rare because this class is generally
	called programmatically by the make_tables.pm OmniTool Admin tool.

=head2 create_database()

	Attempts to create the database, if it does not exist, on the Instance's MySQL server.  Will
	also create all needed tables, based on the Datatypes you have defined for the parent Application
	at this moment.

	$table_maker->create_database();

=head2 create_tables()

	Attempts to specify one, some or all of the needed tables.  Two forms:

	$table_maker->create_tables();

	This will attempt to create all the tables.

	$table_maker->create_tables(@create_tables);

	This will attempt to create all the tables in the @create_tables array (args array).
	Can be one or more.  Usually would be one ;)  Will set the {tables_existence} entry
	for the created table(s) to 1.

	This method dispatches to create_baseline_tables(), create_datatype_table(), and
	create_datatype_metainfo_table() based on which type of table is being created.

	Please note that create_baseline_tables() does rely on the baseline tables always
	being correct in your OmniTool admin database for the parent Instance.

=head2 add_datatype_table_column()

	Method to add a column to a Datatype's MySQL table based on the field type.  Useful
	for when one or more fields have been added to an existing Datatype.  Requires
	the data_codes for the target Datatype and Datatype Field as arguments:

	$table_maker->add_datatype_table_column($dt_id,$dtf_id);

=head2 verify_datatype_table_columns()

	Checks to see if the structure of a Datatype's MySQL table is correct to what the
	figure_datatype_table_columns() subroutine believes it should be based on the
	Datatype's fields.  Requires the data_code of the target Datatype, and if there
	is a true value provided as the second argument, this method will create any
	missing columns.

	$table_maker->verify_datatype_table_columns($dt_id[,$create_missing_columns]);

	Will fill in the 'mysql_status' hashref under the object such that values are
	stored in: $table->{mysql_status}{$table_name}{$table_column}

	The $table_name and $table_column keys are from the table/columns in MySQL,
	and the values under $table_column will either be 'OK' for a column matching
	perfectly or 'ERROR' with one of two reasons following:  the column does not
	exist or the column is an incorrect type.

=head2 figure_datatype_table_columns()

	Adds a 'mysql_table_column' entry under each Datatype Field's sub-hash in the
	$table_maker->{app_datatypes} datatypes hash indicating the MySQL column type
	which should be used for that Datatype Field's column, based on the type
	selected for that Field.  Used by the other methods in this class; mainly
	useful outside for the complete list of Field types.
