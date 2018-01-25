package omnitool::omniclass::loader;

=cut

Provides the data-loading capabilities of the omniclass module.  See extensive notes inside
that omniclass.pm module for how this is used

Includes the load() and clear_records() methods/subroutines.

=cut

$omnitool::omniclass::loader::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# time to grow up
use strict;

# main subroutine to load up data records, based on an array of primary keys
sub load {
	# keep vars lexical
	my ($table_column, $bind_values, $load_column_list, $q_mark_list, $col, $args_ref, $in_list, $load_columns, $loader_sql, $records, $r_keys, $main_loader_sql, $metainfo_loader_sql, $metainfo, $m_keys, $r, $field, $method, $sort_column, $first_col, $which, $sort_column, $count, $dc, $code, $server_id, $search_logic, $searches, $metainfo_q_list, $file_upload_field);

	# become myself and grab my args hash
	my $self = shift;
	my (%args) = @_;

	# allow for 'simple_query_mode', which makes this as close as possible to a raw table query
	if ($args{simple_query_mode}) {
		# disable special features and make sure data is fresh
		$args{skip_metainfo} = 1;
		$args{skip_hooks} = 1;
		$args{do_clear} = 1;
		# the 'simple_query_mode' doubles as the 'load_fields' argument
		$args{load_fields} = $args{simple_query_mode};
	}

	# first things first, clear previous records by default
	if ($args{do_clear}) {
		$self->clear_records();
	}

	# perhaps they provided the altcodes instead of data codes?
	if ($args{altcodes}[0] && !$args{data_codes}[0]) { # yes: resolve those to data_codes

		# use placeholders for this for sure
		$q_mark_list = $self->{belt}->q_mark_list(scalar @{$args{altcodes}});

		$args{data_codes} = $self->{db}->list_select(
			'select data_code from '.$self->{database_name}.'.'.$self->{metainfo_table}.
			qq{ where the_type=? and altcode in ($q_mark_list)},
			[$self->{dt}, @{$args{altcodes}}]
		);
	}

	# return empty if no data ids sent and not asking for 'all'
	return if !$args{data_codes}[0] && !$args{load_all};

	# DANGEROUS: allow for loading all records; useful when there are just a few records
	if ($args{data_codes}[0] eq 'all' || $args{load_all}) {
		$args{data_codes} = $self->{db}->list_select(
			'select data_code from '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' where the_type=?', [$self->{dt}]
		);

		# exit if none found
		return if !$args{data_codes}[0];
	}

	# make a reference to %args for our hooks
	$args_ref = \%args;

	# HERE IS WHERE WE WOULD DO PRE_LOAD HOOK
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('pre_load')) {
		$self->pre_load($args_ref);
	}

	# let's try to use our primary key for the lookup; we have a nice subroutine in our utility belt for that
	($search_logic,$bind_values) = $self->{belt}->datacode_query($args{data_codes});

	# would they only like certain columns?
	if ($args{load_fields}) {
		foreach $col (split /,/, $self->{datatype_info}{all_db_columns}) {
			next if !( $self->{belt}->really_in_list($col,$args{load_fields}) );
			push(@$load_columns,$col);
		}
		$load_column_list = $self->{belt}->comma_list($load_columns);
	} else { # otherwise, load all
		$load_column_list = $self->{datatype_info}{all_db_columns};
	}

	# perhaps they only wanted the name? make the SQL safe in that case
	if ($load_column_list) {
		$load_column_list = ','.$load_column_list;
	}

	# build a nice sql query for grabbing the records from our main table
	# pull our main data

	# if they want to limit the number of records to load, so so in the SQL
	if ($args{load_records_limit}) {
		$search_logic .= ' order by code desc limit '.$args{load_records_limit};
	}

	($records,$r_keys) = $self->{db}->sql_hash(
		qq{select concat(code,'_',server_id),name}.$load_column_list.qq{ from }.$self->{database_name}.
			'.'.$self->{table_name}.' where '.$search_logic,
		( 'bind_values' => [@$bind_values] )
	);

	# and for our metainfo; skip if they explicity said skip_metainfo or if the datatype call for it
	if (!$args{skip_metainfo} && $self->{datatype_info}{metainfo_table} ne 'No Metainfo' && $$r_keys[0]) {
		# need question_marks for placeholders in IN list
		$metainfo_q_list = $self->{belt}->q_mark_list(scalar @$r_keys);

		# grab them
		($metainfo,$m_keys) = $self->{db}->sql_hash(
			'select data_code,altcode,table_name,originator,create_time,updater,update_time,parent,children from '.
			$self->{database_name}.'.'.$self->{metainfo_table}.
			qq{ where the_type=? and data_code in ($metainfo_q_list)},
			( 'bind_values' => [$self->{dt}, @$r_keys] )
		);

		# let's make the created / updated times prettier, unless they don't want to run the hooks
		if (!$self->{skip_hooks} && !$args{skip_hooks}) {
			foreach $r (@$m_keys) {
				# use our very nice time_adjust method below to localize it to the user
				$$metainfo{$r}{nice_create_time} = $self->time_adjust(
					'unix_timestamp' => $$metainfo{$r}{create_time},
				);
				$$metainfo{$r}{nice_update_time} = $self->time_adjust(
					'unix_timestamp' => $$metainfo{$r}{update_time},
				);

				# and now the create / upate ages too, using the utility belt
				$$metainfo{$r}{nice_create_age} = $self->{belt}->figure_age( $$metainfo{$r}{create_time} );
				$$metainfo{$r}{nice_update_age} = $self->{belt}->figure_age( $$metainfo{$r}{update_time} );

			}
		}
	}

	# if there are any encrypted fields, encrypted them here using the $field ID as the sale
	# NOTE: This is NOT hard security.  It is only meant to help you secure your
	# database dumps a bit better than plain text.
	foreach $r (@$r_keys) {
		foreach $field (@{ $self->{datatype_info}{encrypted_fields} }) {
			$table_column = $self->{datatype_info}{fields}{$field}{table_column};
			if ($$records{$r}{$table_column} && $self->{datatype_info}{fields}{$field}{field_type} eq 'short_text_encrypted') {
				$$records{$r}{$table_column} = $self->{db}->decrypt_string($$records{$r}{$table_column}, $field);
			}
		}
	}

	# if we have non-cleared / pre-existing records, feed them in

	if ($self->{records_keys}[0]) {
		# really should send a sort_column if you are appending records like this, but just in case
		push(@{$self->{records_keys}},@$r_keys);

		foreach $r (@$r_keys) {
			$self->{records}{$r} = $$records{$r};
			if ($$metainfo{$r}{table_name}) {
				$self->{metainfo}{$r} = $$metainfo{$r};
			}
		}
	# otherwise, just load in the whole results hashref at once
	} else {
		$self->{records} = $records;
		$self->{metainfo} = $metainfo;
		$self->{records_keys} = $r_keys;
	}

	# Here is where we run the hooks to generate the virtual fields
	# hint: anything at all can happen in one of these, so be creative;
	if (!$self->{skip_hooks} && !$args{skip_hooks}) {

		# let's allow for a pre_virtual_fields() hook for any preparation which needs
		# to be done before the virtual fields methods, now that we have all the 'raw' data
		if ($self->can('pre_virtual_fields')) {
			$self->pre_virtual_fields($args_ref);
		}

		foreach $field (@{ $self->{datatype_info}{fields_key} }) {

			$table_column = $self->{datatype_info}{fields}{$field}{table_column}; # sanity

			$method = 'field_'.$table_column;

			# maybe they only want to load certain fields
			next if $args{load_fields} && !( $self->{belt}->really_in_list($method,$args{load_fields}) );

			# or maybe they want to skip this specific virtual field?
			next if $args{'skip_'.$table_column} || $self->{'skip_'.$table_column};
			# notice that you can pass 'skip_virtual_field_name' either to $self->load() for a one-time skip
			# or you can pass that in to new() for the life of this omniclass object

			# if it's a file-upload, we build out the virtual field right here
			# see the virtual field shoe-horning in datatype_hash.pm
			if ($method =~ /_download/ && $self->{datatype_info}{fields}{$field}{field_type} eq 'file_download') {

				# get the field name for the actual file upload field
				($file_upload_field = $table_column) =~ s/_download//;

				# and now call our virtual hook to get those links
				$self->download_virtual_field($file_upload_field);

			# otherwise, it's a pure hook method
			} elsif ($self->can($method)) {
				$self->$method($args_ref);
			}

		}

	}

	# do they want a complex sort?
	if ($args{complex_sorting}[0]) {

		$self->complex_sort($args{complex_sorting});

	# otherwise conduct a simple-sort automatically; see omnitool::omniclass::sorter.pm
	} else {
		$self->simple_sort($args_ref);
	}

	# as a special treat, make it act more like a regular object by putting the first
	# record under $self->{data}; useful if there is just one record
	if ($self->{records_keys}[0]) {
		$r = $self->{records_keys}[0];
		$self->set_primary_record($r); # see below
	}

	# HERE IS WHERE WE DO POST_LOAD HOOK
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('post_load')) {
		$self->post_load($args_ref);
	}

	# all done!
}

# subroutine to load the latest created/update record; generally, this
# will load up the record into $self->{data}
sub load_last_saved_record {
	# who am i?
	my $self = shift;

	# only argument indicates to clear the previously-loaded records
	my ($do_clear) = @_;

	if ($do_clear) {
		$self->clear_records();
	}

	# auto-load the most-recently saved record
	$self->load(
		'data_codes' => [$self->{last_saved_data_code}],
		'skip_hooks' => $self->{skip_hooks},
	);
}

# method for making any loaded record the primary recorded in $self->{data}
sub set_primary_record {
	my $self = shift;

	# have to send a loaded record
	my ($which_record) = @_;
	return if !$which_record;
	
	# if it's not loaded already, load it up
	if (!$self->{records}{$which_record}) {
		$self->load($which_record);
	}

	# set up the references, maybe easy
	$self->{data} = $self->{records}{$which_record};
	$self->{data}{metainfo} = $self->{metainfo}{$which_record};
	# convenience: the data_code of that first record
	$self->{data_code} = $which_record;
	# and HYPER-convenience: the parent_string value of that first record
	$self->{parent_string} = $self->{dt}.':'.$which_record;

}

# utility method to just load all records - kind of dangerous, but you are smart, right?
sub load_all {
	my $self = shift;
	my (%args) = @_; # let them pass the other args to load

	# clean up args that could conflict with our missing
	$args{data_codes} = [];
	$args{altcodes} = [];

	# pass the instruction
	$args{load_all} = 1;

	# send the command
	$self->load(%args);

	# done
}

# handy utility method that accepts one or more data_codes or altcodes, and does a do_clear an then load()
# nothing fancy, just a very simple way to load data
sub simple_load {
	my $self = shift;

	# require arg is one or more data_codes or altcodes
	my (@items_to_load) = @_;

	# return empty if nothing sent
	return if !$items_to_load[0];

	my (%args);

	# otherwise, are these altcodes or data_codes?  should all be the same!
	if ($items_to_load[0] !~ /^\d+\_\d+$/) { # looks like their altcodes
		$args{altcodes} = \@items_to_load;
	} else { # data_codes
		$args{data_codes} = \@items_to_load;
	}

	# make sure to clear records
	$args{do_clear} = 1;

	# do it
	$self->load(%args);

	# all done ;)
}

# subroutine to build a list of altcodes for the loaded data / akin to record_keys
# not always needed, so not automatically done (yet)
sub get_altcodes_keys {
	my $self = shift;

	# empty it out
	$self->{altcodes_keys} = [];

	# and load it back up
	my $record;
	foreach $record (@{$self->{records_keys}}) {
		push(@{ $self->{altcodes_keys} }, $self->{metainfo}{$record}{altcode});
	}
}

# subroutine to clear out loaded-up records
sub clear_records {
	# who am i?
	my $self = shift;

	# how many are there, for our record below
	my $count;
	if ($self->{records_keys}[0]) {
		$count = @{$self->{records_keys}};
	}

	# somewhat easy:
	$self->{records} = {};
	$self->{metainfo} = {};
	$self->{records_keys} = [];
	$self->{altcodes_keys} = [];

	# primary record cache too
	$self->{data} = {};
	$self->{data_code} = '';

	# all done

}

# method to produce a 'resolver' hash to allow you to find records' data codes by a field
# looks for a list of data_codes and a field name; if data_codes not provided, will check
# in $self->{search_results} before failing; if no field name provided, defaults to 'nane'
sub create_resolver_hash {
	my $self = shift;

	my (%args) = @_;
	# looks like:
	#	'field_name' => 'some_field_name', # optional; a key that who be under the 'records' hash; defaults to 'name'
	#	'data_codes' => [list,of,data,codes],	# optional/suggested; the arrayref of data codes that we need to resolve
	#											# if blank, tries for $self->{search_results}

	my ($data_code, $field_name, $field_value, $field, $load_field);

	# if no data_codes sent and nothing in $self->{search_results}, then fail
	if (!$args{data_codes}[0] && !$self->{search_results}[0] && !$self->{records_keys}[0]) {
		return;
	}

	# if data_codes is empty, use search results
	if (!$args{data_codes}[0]) {
		$args{data_codes} = $self->{search_results};
	}
	# if data_codes is still empty, use records_keys
	if (!$args{data_codes}[0]) {
		$args{data_codes} = $self->{records_keys};
	}

	# field_name defaults to record names
	$args{field_name} ||= 'name';

	# sanity
	$field_name = $args{field_name};

	# if not already loaded - load up the records / field
	if (!$args{already_loaded}) {
		if ($field_name eq 'parent') {
			$load_field = 'name';
		} else {
			$load_field = $field_name;
		}

		# load at last
		$self->load(
			'data_codes' => $args{data_codes},
			'load_fields' => $load_field,
		);
	}

	# blank out any previous resolution hash
	$self->{resolver_hash} = {};

	# now go through and build the resolution hash
	foreach $data_code (@{ $args{data_codes} }) {
		if ($field_name =~ /\,/) { # comma-separated list of fields
			$field_value = '';
			foreach $field (split /\,/, $field_name) {
				$field_value .= '_'.$self->{records}{$data_code}{$field};
			}
			$field_value =~ s/\_//; # no leader

		} else { # single field
			if ($field_name eq 'parent' || $field_name eq 'altcode') {
				$field_value = $self->{metainfo}{$data_code}{$field_name};
			} else {
				$field_value = $self->{records}{$data_code}{$field_name};
			}
		}
		$self->{resolver_hash}{$field_value} = $data_code;
	}

	# all done
}

# method to output the contents of a file attached to a file_upload field
# called from tool::center_stage::send_file()
# please see omnitool::applications::my_family::datatypes::work_projects::field_attachment_link()
# for a working example of how to call this
sub send_file {
	my $self = shift;

	# required arg is the primary key of the record
	# optional second argument tells us to just return the memory reference of the file contents
	my ($data_code,$return_file_contents) = @_;

	my ($field_to_use, $field);

	# fail if not provided
	if (!$data_code) {
		$self->{belt}->mr_zebra("ERROR: Cannot use omniclass->send_file() with ".$self->{datatype_info}{name}." without a valid data record / altcode.",1);
	}

	# fail if this datatype does not take file uploads
	if (!$self->{datatype_info}{has_file_upload}) {
		$self->{belt}->mr_zebra("ERROR: Cannot use omniclass->send_file() with ".$self->{datatype_info}{name}." as that Datatype is not configured with a file-upload field.",1);
	}

	# load the data if not already loaded
	if (!$self->{records}{$data_code}{name}) {
		$self->load('data_codes' => [$data_code]);
	}

	# determine which field to send - 'file_field' param is how to hard-set it
	if ($self->{luggage}{params}{file_field}) {
		$field_to_use = $self->{luggage}{params}{file_field};

	# otherwise, go with the first file upload field
	} else {
		foreach $field (@{ $self->{datatype_info}{fields_key} }) {
			if ($self->{datatype_info}{fields}{$field}{field_type} eq 'file_upload') {
				$field_to_use = $self->{datatype_info}{fields}{$field}{table_column};
				last;
			}
		}
	}

	# fail if that field is not filled
	if (!$self->{records}{$data_code}{$field_to_use}) {
		$self->{belt}->mr_zebra("ERROR: Cannot use omniclass->send_file() with ".$self->{records}{$data_code}{name}.' ('.
			$self->{datatype_info}{name}.") as that $field_to_use field is not filled.",1);
	}

	# if we got this far, send out the file - will have that 'file_manager' object as per new()
	if ($return_file_contents) { # they just want a link to the file contents
		# easy: just do not send the second argument
		return $self->{file_manager}->retrieve_file($self->{records}{$data_code}{$field_to_use});

	# otherwise, tell the retrieve_file sub to call mr_zebra
	} else {
		$self->{file_manager}->retrieve_file($self->{records}{$data_code}{$field_to_use},1);
	}
}

# method to generate the '_download' virtual fields, with links to download files via the Web ui
# expects data to be loaded into $self->{records}
# this is called from around line 185 above
sub download_virtual_field {
	my $self = shift;

	# needs the column for the actual file upload field
	my ($table_column) = @_;

	return if !$table_column;

	my ($r, $attachment_info);

	# go through each loaded record
	foreach $r (@{$self->{records_keys}}) {
		# if this field is null, no need to add a link
		if (!$self->{records}{$r}{$table_column}) {
			$self->{records}{$r}{$table_column.'_download'} = 'N/A';
			next;
		}

		# if the attachment is not there, also short-circuit
		$attachment_info = $self->{file_manager}->load_file_info( $self->{records}{$r}{$table_column} );
		if (!$$attachment_info{filename}) {
			$self->{records}{$r}{$table_column.'_download'} = 'N/A';
			next;
		}

		# still here?  add in the link
		$self->{records}{$r}{$table_column.'_download'}[0] = {
			'text' => $$attachment_info{filename},
			'uri' => "javascript:tool_objects['".$self->{tool_and_instance}."'].fetch_uploaded_file('".$self->{metainfo}{$r}{altcode}."','".$table_column."','".$self->{dt}."');"
		};
	}

	# all done, memory reference updated in place
}

# utility method to locate a record based on it's altcode;
# built for form_maker and data_locker
sub altcode_to_data_code {
	my $self = shift;

	my ($altcode) = @_; # one argument, needs to be an string, and is required

	return if !$altcode;

	# proceed with our search
	my ($record_data_code) = $self->{db}->quick_select(
		'select data_code from '.$self->{database_name}.'.'.$self->{metainfo_table}.
		qq{ where the_type=? and (altcode=? or data_code=?)},
		[$self->{dt}, $altcode, $altcode]
	);

	# So why did we do "(altcode=? or data_code=?)" ?  Because if the altcodes can't be trusted to be unique,
	# then our inline_actions tools may have just sent us the data_code for the target record versus the altcode.
	# Please see the 'Altcodes are Unique' setting for the Datatype, as well as how the get_inline_actions() method
	# sets $this_record_id.

	# send it out
	return $record_data_code;
}

# utility method to find the altcode for a data_code, without loading the whole
# record; primarily for background_task_manager::add_task()
sub data_code_to_altcode {
	my $self = shift;

	my ($data_code) = @_; # one argument, needs to be an string, and is required

	return if !$data_code;

	# proceed with our search
	my ($altcode) = $self->{db}->quick_select(
		'select altcode from '.$self->{database_name}.'.'.$self->{metainfo_table}.
		qq{ where the_type=? and data_code=?},
		[$self->{dt}, $data_code]
	);

	# send it out
	return $altcode;
}


# nice utility method to form a unix epoch based on the user's time zone
sub time_adjust {
	my $self = shift;

	my (%args) = @_;
	# 'unix_timestamp' => $epoch, # required arg, the unix epoch to adjust
	# 'time_to_date_task' => $task, # optional, a task to use to pass this epoch through utility_belt.pm's time_to_date()
									# defaults to 'to_date_human_time'
	# 'timezone_name' => 'Country/City', # optional, a tzdata time zone name, i.e. America/New_York
										# use $self->{luggage}{timezone_name}

	# blank if no epoch sent (or not word)
	return if !int($args{unix_timestamp});

	# default conversion task & timezone
	$args{time_to_date_task} ||= 'to_date_human_time';
	$args{timezone_name} ||= $self->{luggage}{timezone_name};

	return $self->{belt}->time_to_date( $args{unix_timestamp}, $args{time_to_date_task}, $args{timezone_name} );

}

# another nice utility to confirm that there is at least one loaded record; very useful to call for
# error-checking in methods which require a record be loaded into $self->{data}
sub check_for_loaded_record {
	my $self = shift;

	# throw a fatal error if nothing is in $self->{data}
	if (!$self->{data_code} || !$self->{data}{name}) {
		my $caller = ( caller(1) )[3];
		$self->{belt}->mr_zebra(qq{Error: Cannot run $caller without a record loaded into \$self->{data}},1);
	}
}

# utility method to generate %$options and @$options_keys for use in a single-select form
# very simple, just uses the data_code for the keys and one field for the option text
# written on 4/28/16 - and i should have written this 15 months ago!
sub prep_menu_options {
	my $self = shift;

	# alternative field? or have a 'none'
	my ($use_field,$include_none_option) = @_;

	# default to name
	$use_field ||= 'name';

	my ($record, $options, $options_keys);

	# return if nothing loaded
	return if !$self->{data_code};

	# load them up
	foreach $record (@{$self->{records_keys}}) {
		$$options{$record} = $self->{records}{$record}{$use_field};
	}

	# and the keys, sorted by the field
	@$options_keys = sort  {
		$$options{$a} <=> $$options{$b} || $$options{$a} cmp $$options{$b}
	} keys %$options;

	# do they want a 'none'?
	if ($include_none_option) {
		$$options{none} = 'None';
		unshift(@$options_keys,'none');
	}

	# send them out
	return ($options, $options_keys);
}

1;
