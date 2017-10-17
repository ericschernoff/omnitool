package omnitool::omniclass::saver;

=cut

Here is the main event: where we create or update the data records managed
by OmniTool.  Please see extensive notes in omniclass.pm

=cut

$omnitool::omniclass::saver::VERSION = '6.0';
# new way of doing something we've done in the past

# time to grow up
use strict;

# kick off the routine to find our data!
sub save {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;
	my ($restore_params, $args_ref, $data_code, $field, $field_type, $table_column, $we_shall, $lock_user,$lock_remaining_minutes, $params_key, $log_message, $log_file, $p);

	# create or update?  use easy-to-remember scalar
	if ($args{data_code} !~ /\d\_\d/) {
		$we_shall = 'create';
		$args{data_code} = ''; # no bogus data-codes
	} else {
		$we_shall = 'update';
	}

	# most of the time, our field values will be in the %$params hash, but let's allow them to use
	# an alternative hashref, placed into $args{params}
	# since we prefer you use $self-{luggage}{params}, we'll wedge it in a bit
	if ($args{params} && ref($args{params}) eq 'HASH') {
		# save the standard %$params for use afer we're done in save()
		$self->{luggage}{stash_params} = $self->{luggage}{params};
		$restore_params = 1; # only do this within this execute, if we are saving many items

		# and put their desired values
		$self->{luggage}{params} = $args{params};

		# perhaps they want to use some of the $self->{luggage}{params}, allow for a merge
		if ($args{merge_params}) {
			foreach $p (keys %{ $self->{luggage}{stash_params} }) {
				$args{params}{$p} = $self->{luggage}{stash_params}{$p} if !$args{params}{$p};
			}
		}
	}

	# if updating, check to see if this data is locked
	if ($we_shall eq 'update') {
		($lock_user,$lock_remaining_minutes) = $self->check_data_lock($args{data_code});
		if ($lock_user) { # locked, can't proceed
			$self->work_history(0,"ERROR: Can not update data.","Can not update $args{data_code}, as it is locked by $lock_user for another $lock_remaining_minutes minutes.",$args{data_code});
			return;
		}
	# if creating, make sure we have a valid parent set
	} elsif ($we_shall eq 'create' && $args{parent} !~ /top|\d\_\d\:\d/) {
		$self->work_history(0,qq{Could not $we_shall record.},
			qq{You must specify a new parent via the 'new_parent_id'/'new_parent_type' combo args or 'parent' arg (DT_ID:DC_ID).}
		);
		return;
	}

	# good place to reun the pre-save hook
	$args_ref = \%args; # will need below too
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('pre_save')) {
		$args{we_shall} = $we_shall; # useful to know what we are doing
		$self->pre_save($args_ref);

		# we might choose to cancel the create/update in the pre_save hook; if you want to do that, fill '$$args{cancel_save}'
		if ($args{cancel_save}) {
			# how about a useful message?
			$self->work_history(0,ucfirst($we_shall).' action was canceled.',
				qq{Canceled within 'pre_save' hook.}
			);
			return;
		}
	}

	# at this point, we need to massage the %$params a bit to make sure everything is in their right place;
	# simple fields (short text, long-text, single-selects) will already be in place, but dates, files
	# multi-selects, and others may be a bit spread out.  If calling from a script or CLI, they may
	# be already prepped, but let's go through them anyway.  We just want to make sure there is a value
	# in the %$params which relates to each column in this datatype's table; bearing in mind that (a)
	# the field may not be required and (b) we may have a prefix on the key name in %$params, i.e.
	# when creating multiple records (of different or the same type).  Also, "%$params" means $$luggage{params}.
	# Gosh, this comment has been going on a while.  I am likely not impressing you with either my clarity
	# nor my brevity.  Should have used 'neither/nor' there.  Will fix that later.

	# we are going to rely on the omniclass::field_grabber() package, which is part of
	# this monster object
	# go thru each field and handle based on its field_type
	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		# some sanity here
		$table_column = $self->{datatype_info}{fields}{$field}{table_column};
		$field_type = $self->{datatype_info}{fields}{$field}{field_type};

		# call the module, which will update $self->{luggage}{params} in place
		if ($self->can($field_type)) {
			$self->$field_type($table_column,$args_ref,$field);
		}
	}

	# now, to do the actual create or update, we are going to use separate methods below, for the sake
	# of segmenting this code a bit.

	if ($we_shall eq 'create') { # do you need a comment here?
		$data_code = $self->do_create($args_ref);
	} else { # or here?
		$data_code = $self->do_update($args_ref);
	}

	# note that for use in post_save
	$self->{last_saved_data_code} = $data_code;

	# if there were some file uploads, tie them to this record
	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		# only file updates
		next if $self->{datatype_info}{fields}{$field}{field_type} ne 'file_upload';

		# figure the params keys
		$table_column = $self->{datatype_info}{fields}{$field}{table_column};
		$params_key = $self->figure_the_key($table_column,$args_ref);

		# skip if blank
		next if !$self->{luggage}{params}{$params_key};

		# go for the tie-in
		$self->{file_manager}->tie_to_record($self->{luggage}{params}{$params_key},$self->{dt},$data_code,$field);
	}

	# good place to run the post-save hook
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('post_save')) {
		$self->post_save($args_ref);
	}

	# if they used their own params, put the 'real' psgi params back in place for the rest of execute
	if ($self->{luggage}{stash_params} && $restore_params) {
		$self->{luggage}{params} = $self->{luggage}{stash_params};
	}

	# in the words of my sweet Lorelei, "Did it!"
	$self->work_history(1,ucfirst($we_shall).'d '.$args{new_name},
		"Record's primary key is ".$data_code, $data_code
	);

	# let's log out all changes
	$log_message = $self->{luggage}{username}.' '.$we_shall.'d '.$data_code;
	$log_file = 'saves_'.$self->{database_name}.'_'.$self->{table_name};
	$self->{belt}->logger($log_message, $log_file);

}

# subroutine to handle the actual creating / insert commands
sub do_create {
	# need myself and my args
	my $self = shift;
	my ($args) = @_;
	my ($is_draft, $altcode, $data_code, $field, $name_key, $params_key, $q_mark_list, $record_cols, $table_column, @values);

	# first the parent and name
	push(@values,$$args{parent});

	# remember, may have a base-name to the %$params, so rely on a module below to save lines
	$name_key = $self->figure_the_key('name',$args);
	if (!$self->{luggage}{params}{$name_key}) { # some forms do not provide a name field
		push(@values,'Not Named');

	} else {
		push(@values,$self->{luggage}{params}{$name_key});
	}

	# will need this for status message
	$$args{new_name} = $values[1];

	# start off our column list
	$record_cols = 'parent,name';

	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		# skip virtual fields
		next if $self->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';
		# table column
		$table_column = $self->{datatype_info}{fields}{$field}{table_column}; # sanity
		# add to the list of columns
		$record_cols .= ','.$table_column;
		# which %$params key shall we use?
		$params_key = $self->figure_the_key($table_column,$args);
		# add to our values
		push(@values,$self->{luggage}{params}{$params_key});
	}

	# need a comma-list of the q-marks
	$q_mark_list = $self->{belt}->q_mark_list(scalar @values);

	# FYI, this is the spot where $self->{server_id} is used to imprint this record
	# as having been created on this particular database server

	# construct and execute the insert statement for the main record
	$self->{db}->do_sql(
		'insert into '.$self->{database_name}.'.'.$self->{table_name}.
		' (server_id,'.$record_cols.') values ('.
		$self->{server_id}.','.$q_mark_list.')',
		\@values
	);

	# determine the new 'data_code' primary key
	$data_code = $self->{db}->{last_insert_id}.'_'.$self->{server_id};

	# constructing the metainfo record is a bit more dynamic, and probably confusing
	# and we can skip it if the datatype does not want metainfo
	if ($self->{datatype_info}{skip_metainfo} ne 'Yes') {

		# the 'altcode' is the human-friendly unique identifier, and we have a standard
		# altcode-maker method below; it is recommended that for important datatypes,
		# you override this in the datatype's specific class/perl_module
		$altcode = $self->altcode_maker($args);

		# on create only, they can flag something as 'draft' data, and later set it to not draft
		# via the 'not_draft()' method below
		if ($$args{is_draft}) {
			$is_draft = 'Yes';
		} else {
			$is_draft = 'No';
		}

		$self->{db}->do_sql('insert into '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' (server_id,altcode,data_code,the_type,table_name,originator,'.
				'create_time,updater,update_time,parent,is_draft) '.
				'values (?,?,?,?,?,?,unix_timestamp(),?,unix_timestamp(),?,?)',
			[
				$self->{server_id}, $altcode, $data_code, $self->{dt},
				$self->{table_name}, $self->{luggage}{username},
				$self->{luggage}{username}, $$args{parent}, $is_draft
			]
		);

		# update the proud new parent's children column
		$self->children_update($$args{parent}) if $$args{parent} ne 'top';
	}

	# if they want an extended update history, this is a good time to start it
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		$self->update_history('New Record "'.$$args{new_name}.'" was created.',$$args{data_code});
	}

	# send back the data_code
	return $data_code;
}

# quick method to mark a piece of data as 'not draft'
# just need the target primary key / data code for lifting the 'draft' mark
sub not_draft {
	my $self = shift;
	my ($data_code) = @_;

	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.'.$self->{metainfo_table}.
		qq{ set is_draft='No' where the_type=? and data_code=?},
		[$self->{dt}, $data_code]
	);

	# pretty easy
}

# subroutine to handle the actual updating / update commands
sub do_update {
	# need myself and my args
	my $self = shift;
	my ($args) = @_;
	my ($altcode, $before_altcode, $before_update_record, $code, $dc, $field, $params_key, $rec_key, $server_id, $table_column, $update_detail, $update_detail_name_chg, $update_detail_text, $update_sql, @update_details, @values);

	# let's try to use our primary key for the lookup; we have a nice subroutine in our utility belt for that
	($code,$server_id) = split /_/, $$args{data_code};

	# sanity for the comparisons for extended_change_history
	$dc = $$args{data_code};

	# if they want detailed updates, our first order of business is to grab a copy of the record
	# prior to its modification
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		($before_update_record,$rec_key) = $self->{db}->sql_hash(
			qq{select concat(code,'_',server_id),name,}.$self->{datatype_info}{all_db_columns}.' from '.
			$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?',
			( 'bind_values' => [$code,$server_id] )
		);
	}

	# note that we do not change the parent here; the method for that is change_parent();

	# build a nice update statement
	$update_sql = 'update '.$self->{database_name}.'.'.$self->{table_name}.' set ';

	# go thru each field
	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		$table_column = $self->{datatype_info}{fields}{$field}{table_column}; # sanity

		# skip if it's a virtual (generated) field
		next if $self->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';

		# which %$params key shall we use?
		$params_key = $self->figure_the_key($table_column,$args);

		# if they sent 'skip_blank_fields', we will only update those fields which have some value
		next if $$args{skip_blanks} && !(length($self->{luggage}{params}{$params_key}));
		# testing with length() allows them to send a 0

		# if it's a hidden_field, it may be blank for a normal form update, allowing
		# for the parent to set these via post_save
		next if $self->{datatype_info}{fields}{$field}{field_type} eq 'hidden_field' && !(length($self->{luggage}{params}{$params_key}));

		# add to the update SQL
		$update_sql .= $table_column.'=?, ';

		# add to our values
		push(@values,$self->{luggage}{params}{$params_key});

		# if logging the update details, keep track of changes
		if ($self->{datatype_info}{extended_change_history} eq 'Yes' && $$before_update_record{$dc}{$table_column} ne $self->{luggage}{params}{$params_key}) {
			# we will limit the values to the first 200 chars for space/sanity
			# we will join this together later
			push(@update_details,
				$self->{datatype_info}{fields}{$field}{name}.' was modified:'.
				"\nOld Value: ".substr($$before_update_record{$dc}{$table_column},0,200).
				"\nNew Value: ".substr($self->{luggage}{params}{$params_key},0,200)
			);
		}
	}

	# name/title column too
	# which %$params key shall we use?
	$params_key = $self->figure_the_key('name',$args);
	# for the name, if they didn't send a name, we will automatically use the pre-existing name
	if (length($self->{luggage}{params}{$params_key})) {
		$update_sql .= 'name=?';
		# add to our values
		push(@values,$self->{luggage}{params}{$params_key});
		# will need this for status message
		$$args{new_name} = $self->{luggage}{params}{$params_key};

	} else { # get the name from the DB
		($$args{new_name}) = $self->{db}->quick_select(
			'select name from '.$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?',
			[$code,$server_id]
		);

		# also can't use the last space/comma in $update_sql now
		$update_sql =~ s/\,\ $//;
	}

	# if logging the update details, keep track of changes
	if ($self->{datatype_info}{extended_change_history} eq 'Yes' && $$before_update_record{$dc}{'name'} ne $self->{luggage}{params}{$params_key}) {
		# we will limit the values to the first 200 chars for space/sanity
		# this one goes on the front
		unshift(@update_details,
			'Name/Title was modified:'.
			"\nOld Value: ".substr($$before_update_record{$dc}{'name'},0,200).
			"\nNew Value: ".substr($self->{luggage}{params}{$params_key},0,200)
		);
		$update_detail_name_chg .= "\nOld Value: ".substr($$before_update_record{$dc}{'name'},0,200);
		$update_detail_name_chg .= "\nNew Value: ".substr($self->{luggage}{params}{$params_key},0,200);
	}

	# finish the SQL statement
	$update_sql .= ' where code=? and server_id=?';

	push(@values,$code,$server_id);

	# commit the update to the main record table
	if (scalar(@values) > 2) { # only proceed if at least one field is getting updated, since we allow for skipping-blanks
  		$self->{db}->do_sql($update_sql,\@values);
	}

	# for the metainfo, mainly it's the updater & update_time; and they may want to to update the altcode
	if ($self->{datatype_info}{metainfo_table} ne 'No Metainfo') {
		# see if there are changes to the altcode
		($before_altcode) = $self->{db}->quick_select(
			'select altcode from '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' where the_type=? and data_code=?',
			[$self->{dt}, $$args{data_code}]
		);

		# check the altcode & access list; which %$params key shall we use?
		$params_key = $self->figure_the_key('altcode',$args);
		$altcode = $self->{luggage}{params}{$params_key};

		# check to see if they are changed
		if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
			if ($altcode ne $before_altcode && $altcode) { # blank is OK too
				push(@update_details,
					'Altcode was modified:'.
					"\nOld Value: ".$before_altcode.
					"\nNew Value: ".$altcode
				);
			}
		}

		# if neither was sent, originals are defaults
		$altcode ||= $before_altcode;

		# commit the update to the metainfo table
		$self->{db}->do_sql(
			'update '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' set altcode=?, updater=?, update_time=unix_timestamp()'.
			' where the_type=? and data_code=?',
			[$altcode,$self->{luggage}{username}, $self->{dt}, $$args{data_code}]
		);

	}

	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		# put the details together
		if (!$update_details[0]) { # no changes?
			$update_detail_text = 'No fields were actually changed';
		} else { # put them together
			$update_detail_text = join("\n------\n",@update_details);
		}
		# save that history
		$self->update_history($update_detail_text,$$args{data_code});
	}

	# OK, do they want to auto-(re)load the updated record
	if ($$args{auto_load}) { # yessir!
		$self->load(
			'data_codes' => [$$args{data_code}],
			'skip_hooks' => $$args{skip_hooks},
		);
	}

	return $$args{data_code};

}

# generic altcode-generator; you definitely want to override this with your custom classes
sub altcode_maker {
	# need myself and my args
	my $self = shift;
	my ($args) = @_;
	my ($month_year, $table_name, $proposed_altcode);

	# get month abbreviation from utility belt
	$month_year = $self->{belt}->time_to_date(time(),'to_month_abbrev');

	# clean table table
	($table_name = $self->{table_name}) =~ s/_//g;

	# mash together the month, username, table name, and auto_increment column, and send that mess out
	$proposed_altcode = $month_year.$self->{luggage}{username}.'_'.$table_name.$self->{db}->{last_insert_id};

	# if that's more than 50 chars, try a version without the username
	if (length($proposed_altcode) > 50) {
		$proposed_altcode = $month_year.'_'.$table_name.$self->{db}->{last_insert_id};
		# still over 50 chars? really stripped down version
		if (length($proposed_altcode) > 50) {
			$proposed_altcode = $month_year.'_'.$self->{dt}.'_'.$self->{db}->{last_insert_id};
		}
	}
	# that is not the right way to handle that logic, but I still like it.

	# send it out
	return $proposed_altcode;

}

# if you have overriden altcode_maker() in your own class, you probably don't want to use
# the 'last_insert_id', but rather count(*)+1 of the records created this month
# this subroutine allows you to pass a base-pattern (i.e. MonYYYY) to find the count(*)+1 value
# the base_pattern is always the start of the proposed altcode
sub altcode_next_number {
	my $self = shift;

	my ($base_pattern) = @_;

	return if !$base_pattern;

	# proceed with our search
	my ($altcode_next_number) = $self->{db}->quick_select(
		'select count(*)+1 from '.$self->{database_name}.'.'.$self->{metainfo_table}.
		qq{ where the_type=? and altcode like ?},
		[$self->{dt}, $base_pattern.'%']
	);

	# make sure it is at least three digits long
	while (length($altcode_next_number) < 3) {
		$altcode_next_number = '0'.$altcode_next_number;
	}

	# send it out
	return $altcode_next_number;
}

# quick subroutine to minimize repeated if/else for figuring %$param keys; for use in this module only
sub figure_the_key {
	my $self = shift;
	my ($key,$args) = @_;

	if (length($$args{params_key})) {
		return $$args{params_key}.'_'.$key;
	} else {
		return $key;
	}
}

# convenience method for updating a few fields of a record
# something i should have written two years ago ;)
sub simple_save {
	my $self = shift;
	my (%args) = @_;

	my (@sent_keys, $data_code);

	# did they send a data code?
	if ($args{data_code}) { # yes
		$data_code = $args{data_code};
		# don't pass that value into the save() params
		delete($args{data_code});

	# no -- is there a loaded record?
	} elsif ($self->{data_code}) {
		$data_code = $self->{data_code};
	}

	# if there is no data_code, we cannot proceed
	if (!$data_code) {
		$self->work_history(0,"ERROR: Can not use simple_save() without a data_code either passed in the args or a pre-loaded record.");
		return;
	}

	# now that we cleared $args{data_code}, make sure there are some items left in %args
	@sent_keys = keys %args;
	if (!$sent_keys[0]) {
		$self->work_history(0,"ERROR: Can not use simple_save() some params to send to save().");
		return;
	}

	# okay, send the command to save() to update the fields
	$self->save(
		'data_code' => $data_code,
		'skip_blanks' => 1,
		'params' => \%args,
	);

	# update our meaningless log
	$self->work_history(1,"Successfully called simple_save() to update $data_code via save().");

}

1;
