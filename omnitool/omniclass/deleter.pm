package omnitool::omniclass::deleter;

=cut

Provides the 'delete' and 'restore' methods, which are described
in the comments of omniclass.pm

=cut

$omnitool::omniclass::deleter::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# for archiving data prior to delete
use Storable qw( freeze thaw );

# time to grow up
use strict;

# kick off the routine to delete data when desired
sub delete {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;
	my ($stored_files, $stored_file, $dc, $index, $args_ref,$code,$server_id, $target_name, $old_parent_string, $record_cols, $the_record, $rec_key, $metainfo_cols, $the_metainfo, $mi_key, $stored_record, $stored_metainfo, $old_parent_string, $delete_detail, $lock_user,$lock_remaining_minutes,$log_message, $log_file);

	# needs one arg: the data_code being deleted; die if that is not valid
	if ($args{data_code} !~ /\d\_\d/) {
		return;
	}

	# check to see if this data is locked
	($lock_user,$lock_remaining_minutes) = $self->check_data_lock($args{data_code});
	if ($lock_user) { # locked, can't proceed
		return;
	}

	# fix up match-query for data_code
	($code,$server_id) = split /_/, $args{data_code};

	# get name and parent of the condemned record
	($target_name,$old_parent_string) = $self->{db}->quick_select(
		'select name,parent from '.$self->{database_name}.'.'.$self->{table_name}.
		' where code=? and server_id=?',
		[$code, $server_id]
	);

	# target doesn't exist? fail again
	if (!$target_name) {
		return;
	}

	# references to %args for the two hooks
	$args_ref = \%args;

	# great place to do a pre_delete() hook in the datatype module
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('pre_delete')) {
		$self->pre_delete($args_ref);

		# we might choose to cancel the delete in the pre_delete hook; if you want to do that, fill '$$args{cancel_delete}'
		if ($args{cancel_delete}) {
			return;
		}
	}

	# if this datatype has 'archive_deletes' enabled, grab and save the record to 'arhive_deletes'
	if ($self->{datatype_info}{archive_deletes} eq 'Yes') {
		# grab the record out

		$record_cols = $self->{db}->grab_column_list($self->{database_name},$self->{table_name});
		($the_record,$rec_key) = $self->{db}->sql_hash(
			qq{select $record_cols from }.$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?',
			('bind_values' => [$code, $server_id])
		);

		# the metainfo too
		$metainfo_cols = $self->{db}->grab_column_list($self->{database_name},$self->{metainfo_table},1);
		$metainfo_cols = 'code,server_id,parent,'.$metainfo_cols; # no 'concat(code,server_id) stuff here;

		($the_metainfo,$mi_key) = $self->{db}->sql_hash(
			qq{select $metainfo_cols from }.$self->{database_name}.'.'.$self->{metainfo_table}.
			' where data_code=? and the_type=?',
			( 'bind_values' => [$args{data_code}, $self->{dt}] )
		);
		$$the_metainfo{$$mi_key[0]}{code} = $$mi_key[0];

		# i thought about just using Data::Dumper to make this a clear-text hash, but
		# i really like Storable better and I don't think we are going back to 32-bit machines,
		# and by the time we get to 128-bit, this will all be Lorelei's problem
		$stored_record = freeze($$the_record{$$rec_key[0]});
		$stored_metainfo = freeze($$the_metainfo{$$mi_key[0]});

		$self->{db}->do_sql(
			'insert into '.$self->{database_name}.'.deleted_data (server_id,data_code,datatype,deleter,delete_time,data_record,metainfo_record) values '.
			'(?,?,?,?,unix_timestamp(),?,?)',
			[$self->{db}->{server_id},$args{data_code},$self->{dt},$self->{luggage}{username},$stored_record,$stored_metainfo]
		);
	}


	# delete the record
	# first from the main table
	$self->{db}->do_sql(
		'delete from '.$self->{database_name}.'.'.$self->{table_name}.
		' where code=? and server_id=?',
		[$code, $server_id]
	);

	# now metainfo table - assume metainfo is on, we want it gone
	$self->{db}->do_sql(
		'delete from '.$self->{database_name}.'.'.$self->{metainfo_table}.
		' where the_type=? and data_code=?',
		[$self->{dt}, $args{data_code}]
	);

	# now update the 'children' column of the grieving parent's metainfo record, using the module in parent_changer.pm
	if ($old_parent_string ne 'top') { # wouldn't be necessary
		$self->children_update($old_parent_string);
	}

	# nice sentence for logging purposes.
	$delete_detail = $target_name.' was deleted.';

	# if this datatype has the 'extended_change_history' enable, save an entry to 'update_history'
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		$self->update_history($delete_detail,$args{data_code});
	}

	# if it has stored files, delete those too
	if ($self->{file_manager}) {
		$stored_files = $self->{file_manager}->get_stored_files_for_record($args{data_code}, $self->{dt});
		foreach $stored_file (@$stored_files) {
			$self->{file_manager}->remove_file($stored_file, 1);
		}
	}

	# great place to do a post_delete() hook in the datatype module
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('post_delete')) {
		$self->post_delete($args_ref);
	}

	# if we have loaded this record previously with load(), remove
	$dc = $args{data_code}; # sanity
	if ($self->{records}{$dc}) {
		delete($self->{records}{$dc});
		delete($self->{metainfo}{$dc});
		# remove the key for it too
		$index = 0;
		$index++ until $self->{records_keys}[$index] eq $dc;
		splice(@{$self->{records_keys}}, $index, 1);
	}

	# let's log out all changes / deletes
	$log_message = $self->{luggage}{username}.' deleted '.$target_name;
	$log_file = 'deletes_'.$self->{database_name}.'_'.$self->{table_name};
	$self->{belt}->logger($log_message, $log_file);

	# all done

}

# start subroutine to restore data, which will be rarely used, I bet.
# depends on datatype having 'archive_deletes' enabled at time of delete
sub restore {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;
	# declare my vars
	my (@mi_keys, $mi_key, $code, $the_metainfo, $stored_record, $stored_metainfo, $the_record, $record_cols, $metainfo_cols, $data_code, @q_marks, @values, $col, $q_mark_list, $server_id, $data_code, $parent, $detail, $restore_detail);

	# needs one arg: the data_code being restored; die if that is not valid
	if ($args{data_code} !~ /\d\_\d/) {
		return;
	}

	# can also send a 'new_parent' to put it under another record

	# is the reecord in the table?
	($stored_record,$stored_metainfo) = $self->{db}->quick_select(
		qq{select data_record,metainfo_record from }.$self->{database_name}.
		'.deleted_data where datatype=? and data_code=?',
		[$self->{dt}, $args{data_code}]
	);

	# need at least the record's data, as metainfo could be skipped
	if (!$stored_record) {
		return;
	}

	# OK, proceed with restoring the primary record; first, thaw it out
	$the_record = thaw($stored_record);
	# probably should test it again, but I think it's highly-unlikely to be incorrect
	# at this point; maybe eat my words later; there is always 6.1
	# remember, it is from sql_hash so it has the data_code as its top key, then column=value pairs under that

	# let's build an INSERT command based on the record table's current list of columns
	$record_cols = $self->{db}->grab_column_list($self->{database_name},$self->{table_name},1);
	# leaving off the code,server_id,parent cols for this go round for simplicity

	# sanity
	$data_code = $args{data_code};

	# did they send a new_parent string?
	if ($args{new_parent}) { # yes, go with that
		$$the_record{parent} = $args{new_parent};
	}

	# build two nice arrays, of ? marks and values
	# now the rest of the columns
	foreach $col (split /,/, $record_cols) {
		$$the_record{$col} = '' if !$$the_record{$col}; # maybe new since deletion
		push(@values,$$the_record{$col});
	}
	# one for the parent column
	push(@values,$$the_record{parent});

	# need a comma-list of the q-marks
	$q_mark_list = $self->{belt}->q_mark_list(scalar @values);

	# separate the data_code into code,server_id bits for insert
	($code,$server_id) = split /\_/, $data_code;

	# alright, ready for a nice insert command
	$self->{db}->do_sql(
		'insert into '.$self->{database_name}.'.'.$self->{table_name}.
		' (code,server_id,'.$record_cols.',parent) values ('.
		$code.','.$server_id.','.$q_mark_list.')',
		\@values
	);

	# now for the metainfo, if we have it
	if ($stored_metainfo) {
		$the_metainfo = thaw($stored_metainfo);

		$metainfo_cols = $self->{db}->grab_column_list($self->{database_name},$self->{metainfo_table},1);
		$metainfo_cols = 'code,server_id,parent,'.$metainfo_cols; # no 'concat(code,server_id) stuff here;

		# sub out parent if provided
		if ($args{new_parent}) {
			$$the_metainfo{parent} = $args{new_parent};
		}

		# again, build two nice arrays, of ? marks and values
		@values = (); # fresh start
		# bit simpler this time
		foreach $col (split /,/, $metainfo_cols) {
			$$the_metainfo{$col} = '' if !$$the_metainfo{$col}; # maybe new since deletion
			push(@values,$$the_metainfo{$col});
		}

		# need a comma-list of the q-marks
		$q_mark_list = $self->{belt}->q_mark_list(scalar @values);

		# alright, ready for a nice insert command
		$self->{db}->do_sql(
			'insert into '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' ('.$metainfo_cols.') values ('.$q_mark_list.')',
			\@values
		);

		# update the new parent's 'children' column
		if ($$the_metainfo{parent} ne 'top') { # wouldn't be necessary
			$self->children_update($$the_metainfo{parent});
		}
	}

	# if this datatype has the 'extended_change_history' enable, save an entry to 'update_history'
	if ($stored_metainfo) { # note the metainfo was done
		$detail = 'Metainfo was restored.';
	} else {
		$detail = 'Metainfo was not available and skipped.';
	}
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		$restore_detail = qq{$$the_record{name} was restored under $$the_record{parent}}."\n".$detail;
		$self->update_history($restore_detail,$args{data_code});
	}

	# all done
}


1;
