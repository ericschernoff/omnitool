package omnitool::applications::otadmin::tools::make_tables;
# helps the admin/developer to create database tables for
# an intsance, including the baseline tables (metainfo, update_history, etc.)
# and the datatype-specific tables.
# this should be your first stop after adding a datatype field.
# meant for creation only -- does not delete or modify current table columns.
# if you want to jump off a building, i am not providing the elevator.

=cut

Here is what the json_results will look like:

	$self->{json_results} = {
		'title' => 'Set Up MySQL DB / Tables for '.INSTANCE_NAME,
		'message' => 'Status Message of Last Action',
		'database_hostname' => 'db.hostname.com',
		'database_name' => 'mysql_database_name',
		'database_existence' => 0|1, # 1=database exists
		'baseline_tables' => {
			'table1_name' => 0|1, # 1=table exists
			'table2_name' => 0|1, # 1=table exists
		},
		'baseline_tables_list' => ['sorted','baseline','tables','key'],
		'datatype_tables' => [ # array of hashes, ordered alphabetically
			{
				'table_name' => 'mysql_table1_name',
				'datatype_name' => 'Name of Datatype Associated with Table',
				'table_existence' => 0|1, # 1=table exists
				'metainfo_table_needed' => 0|1, # 1=dt-specific metainfo table required
				'metainfo_table_existence' => 0|1, # 1=dt-specific metainfo table exists
				'columns_status' => [ # array of hashes, ordered by priority of columns
					{
						'field_name' => 'Name of Datatype Field for Column',
						'column_name' => 'mysql_column_name',
						'column_existence' => 0|1, # 1=column exists
						'column_status' => 'Error Condition' or 'Column is correct',
						'column_codes' => 'DT-ID:DTF-ID', # param suitable for passing to add_datatype_table_column()
					},
				]
			}
		]
	};

	Accepts the following GET commands, which will be sent via update_json_uri() in omnitool_routines.js

	- create_database --> if filled, will create the mysql database for the instance; $table_maker->create_database()
	- create_baseline_tables --> if filled, will attempt to create all the baseline tables; $table_maker->create_baseline_tables()
	- create_table --> if filled, will attempt to create that specified table; $table_maker->create_tables($create_table)
	- add_datatype_table_column --> if filled, will attempt to add a needed column to a datatype's mysql table for the instance
							--> fill with $dt_id.':'.$dtf_id

	If any of those are sent, do_make_table_actions() will attempt to perform the action and fill in
	$self->{json_results}{message} appropriately.

=cut

use parent 'omnitool::tool';

# we have a special system module for these functions:
use omnitool::common::table_maker;
# having that separate makes future scripting easier

# If only I could apply this next line to my diet.
use strict;

# we will do everything in perform_action() and rely on the
# make_tables.tt jemplate-template
sub perform_action {
	my $self = shift;

	# local vars
	my ($table_maker, $blt, $dt, $dt_table_name, $dtf, $dt_table_column, $column_existence,$action_link, $other_instance);

	# start off easy: set the title for the page
	$self->{json_results}{title} = 'Managing MySQL DB / Tables for '.$self->{omniclass_object}->{data}{name};

	# fire up our table maker object to do the heavy lifting
	$table_maker = omnitool::common::table_maker->new(
		'luggage' => $self->{luggage},
		'app_instance' => $self->{omniclass_object}->{data_code},
		'instance_omniclass_object' => $self->{omniclass_object},
	);

	# now we know the database server's hostname
	$self->{json_results}{database_hostname} = $table_maker->{instance_db_obj}->{hostname};
	# we had this before in the omniclass object, but six in one hand...
	$self->{json_results}{database_name} = $table_maker->{database_name};

	# check the database's existence
	$table_maker->check_database_existence();

	# pass the create database uri, if needed
	if ($table_maker->{database_existence} == 0) {
		$self->{json_results}{create_database_uri} = $self->{my_json_uri}.'?create_database=1';

		# if that database is missing (and they haven't instructed to create it), no need to continue
		$self->{json_results}{database_existence} = 0;
		return if !$self->{luggage}{params}{create_database} && !$self->{luggage}{params}{source_instance};
	}

	# here is the right place to run any commands which were sent; separate into another method below
	$self->do_make_table_actions($table_maker);

	# check the database's existence again to see if it was created
	$table_maker->check_database_existence();

	# add that database existence to the results
	$self->{json_results}{database_existence} = $table_maker->{database_existence};

	# if we are still here, check for the existence of the tables
	$table_maker->check_tables_existence();

	# support showing just one of the boxes in the jemplate:
	# 1. have a link for changing the display
	$self->{json_results}{tables_display_link} = $self->{my_json_uri}.'?display=';
	# 2. pass back that sent-in param for the jemplate to handle
	$self->{json_results}{display} = $self->{luggage}{params}{display};
	$self->{json_results}{display} ||= 'baseline_tables';
	# use a pre-set link with that 'display' option for all links below
	$action_link = $self->{my_json_uri}.'?display='.$self->{json_results}{display};

	# set up the baseline_tables tables sub-hash
	foreach $blt (@{ $table_maker->{baseline_tables_list} }) {
		$self->{json_results}{baseline_tables}{$blt} = $table_maker->{tables_existence}{$blt};

		# if it's missing, provide a link to create
		if ($table_maker->{tables_existence}{$blt} == 0) {
			$self->{json_results}{create_table_uris}{$blt} = $action_link.'&create_table='.$blt;
		}
	}

	# need those ordered keys
	$self->{json_results}{baseline_tables_list} = $table_maker->{baseline_tables_list};

	# now the more complex sub-hash
	foreach $dt (split /,/, $table_maker->{app_datatypes}{all_datatypes}) {
		$dt_table_name = $table_maker->{app_datatypes}{$dt}{table_name}; # sanity
		push(@{ $self->{json_results}{datatype_tables} },{
			'table_name' => $dt_table_name,
			'datatype_name' => $table_maker->{app_datatypes}{$dt}{name},
			'table_existence' => $table_maker->{tables_existence}{$dt_table_name},
			'metainfo_table_needed' => ($table_maker->{app_datatypes}{$dt}{metainfo_table} eq 'Own Table') || 0,
			'metainfo_table_existence' => $table_maker->{tables_existence}{$dt_table_name.'_metainfo'},
		});
		# need a dt-specific metainfo table create link?
		if ($self->{json_results}{datatype_tables}[-1]{metainfo_table_existence} == 0 && $self->{json_results}{datatype_tables}[-1]{metainfo_table_needed} == 1) { # yes
			$self->{json_results}{datatype_tables}[-1]{metainfo_table_create_link} = $action_link.'&create_table='.$dt_table_name.'_metainfo';
		}

		# if the table exists, verify and show the column status
		if ($table_maker->{tables_existence}{$dt_table_name} == 1) {
			# run the verification
			$table_maker->verify_datatype_table_columns($dt);
			foreach $dtf (@{ $table_maker->{app_datatypes}{$dt}{fields_key} }) {
				$dt_table_column = $table_maker->{app_datatypes}{$dt}{fields}{$dtf}{table_column}; # sanity

				if ($table_maker->{mysql_status}{$dt_table_name}{$dt_table_column} =~ /not found/) {
					$column_existence = 0;
				} else {
					$column_existence = 1;
				}

				# don't you just love perl's complex data structures?
				push(@{ $self->{json_results}{datatype_tables}[-1]{columns_status} },{
					'field_name' => $table_maker->{app_datatypes}{$dt}{fields}{$dtf}{name},
					'column_name' => $dt_table_column,
					'column_existence' => $column_existence,
					'column_status' => $table_maker->{mysql_status}{$dt_table_name}{$dt_table_column},
					'column_codes' => $dt.':'.$dtf
				});
				# need a column creation link?
				if ($column_existence == 0) { # yes
					$self->{json_results}{datatype_tables}[-1]{columns_status}[-1]{create_link} = $action_link.'&add_datatype_table_column='.$dt.':'.$dtf;
				}
			}

		# if it's missing, provide a link to create
		} else {
			$self->{json_results}{datatype_tables}[-1]{create_link} = $action_link.'&create_table='.$dt_table_name;
		}

	}

	# clear the lock
	# $self->{unlock} = 1;
}

# separate spot to complete any actions set via GET params
sub do_make_table_actions {
	my $self = shift;

	# needs the $table_maker object
	my ($table_maker) = @_;

	my ($dt_id,$dtf_id, $source_instance_name);

	# do they want to create the database?
	if ($self->{luggage}{params}{create_database}) {
		$table_maker->create_database();
		$self->{json_results}{message} = "Created '".$table_maker->{database_name}."' MySQL Database and All Needed Tables";
	}

	# or clone a database?
	if ($self->{luggage}{params}{source_instance}) {
		$source_instance_name = $table_maker->clone_database( $self->{luggage}{params}{source_instance} );
		$self->{json_results}{message} = "Created '".$table_maker->{database_name}."' MySQL Database from ".$source_instance_name;
	}

	# do they want to create all the baseline tables?
	if ($self->{luggage}{params}{create_baseline_tables}) {
		$table_maker->create_baseline_tables();
		$self->{json_results}{message} = "Created Required Baseline Tables in '".$table_maker->{database_name}."' Database";
	}

	# or maybe create a specific table?
	if ($self->{luggage}{params}{create_table}) {
		$table_maker->create_tables( $self->{luggage}{params}{create_table} );
		$self->{json_results}{message} = "Created '".$self->{luggage}{params}{create_table}."' Table in '".$table_maker->{database_name}."' Database";
	}

	# finally, they may want to create a table column for a datatype field
	if ($self->{luggage}{params}{add_datatype_table_column}) {
		($dt_id,$dtf_id) = split /:/, $self->{luggage}{params}{add_datatype_table_column};
		$table_maker->add_datatype_table_column($dt_id,$dtf_id);
		$self->{json_results}{message} = "Added '".$table_maker->{app_datatypes}{$dt_id}{fields}{$dtf_id}{table_column}.
			"' Table Column to '".$table_maker->{app_datatypes}{$dt_id}{table_name}.
			"' DB Table for ".$table_maker->{app_datatypes}{$dt_id}{name};
	}

	# fix up gritter title
	$self->{json_results}{gritter_skip_title} = 1;

}

1;
