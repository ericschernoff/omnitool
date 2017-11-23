package omnitool::omniclass::parent_changer;

=cut

Provides the 'change_parent' method to move data from one parent to another; useful
if your data is organized in a heirarchy (sp?)

Also has the 'children_update' method to rebuild a children list for a parent's metainfo
record; useful for processing moves and deletes.

=cut

$omnitool::omniclass::parent_changer::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# time to grow up
use strict;

# kick off the routine to move data between parents
sub change_parent {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;
	my ($code,$server_id,$old_parent_code,$old_parent_server_id, $np_code,$np_server_id,$new_parent_name, $target_name, $old_parent_info, $old_parent_detail, $old_parent_type, $old_parent_id, $old_parent_name, $new_parent_detail, $new_parent_name, $new_parent_detail, $new_parent_string, $new_children, $update_detail, $target_name, $lock_user,$lock_remaining_minutes);

	# needs three args: the data_code of the record to move, the new parent's primary key (code.'_'.server_id, like all the others),
	# and the datatype ID of the new parent
	# quit if those are not valid
	if ($args{data_code} !~ /\d\_\d/ || $args{new_parent_id} !~ /\d\_\d/ || $args{new_parent_type} !~ /\d\_\d/) {
		return;
	}

	# check to see if this data is locked
	($lock_user,$lock_remaining_minutes) = $self->check_data_lock($args{data_code});
	if ($lock_user) { # locked, can't proceed
		return;
	}

	# get the name of the new parent
	if ($args{new_parent_id} ne 'top') { # special parent
		($np_code,$np_server_id) = split /_/, $args{new_parent_id};
		($new_parent_name) = $self->{db}->quick_select(
			'select name from '.$self->{database_name}.'.'.$self->{luggage}{datatypes}{$args{new_parent_type}}{table_name}.
			' where code=? and server_id=?',
			[$np_code, $np_server_id]
		);
	} else {
		$new_parent_name = 'Top Level';
	}

	# good chance to die, if that name is blank, they either didn't send 'top' or sent an invalid parent id/type combo
	if (!$new_parent_name) {
		return;
	}

	# fix up match-query for data_code
	($code,$server_id) = split /_/, $args{data_code};

	# get name of the moving record
	($target_name) = $self->{db}->quick_select(
		'select name from '.$self->{database_name}.'.'.$self->{table_name}.
		' where code=? and server_id=?',
		[$code, $server_id]
	);

	# target doesn't exist? fail again
	if (!$target_name) {
		return;
	}

	# we made it this far? start the update

	# need the old parent string even if we are not logging extended update history
	($old_parent_info) = $self->{db}->quick_select(
		'select parent from '.$self->{database_name}.'.'.$self->{table_name}.
		' where code=? and server_id=?',
		[$code, $server_id]
	);

	# if we have the extended update status enabled, grab the existing info
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		if ($old_parent_info eq 'Top') { # simple
			$old_parent_detail = 'Top Level';
		} else { # not simple
			($old_parent_type,$old_parent_code,$old_parent_server_id) = $self->parent_string_bits($old_parent_info);

			($old_parent_name) = $self->{db}->quick_select(
				'select name from '.$self->{database_name}.'.'.$self->{luggage}->{datatypes}{$old_parent_type}{table_name}.
				' where code=? and server_id=?',
				[$old_parent_code, $old_parent_server_id]
			);
			if ($old_parent_name) {
				$old_parent_detail = $self->{luggage}->{datatypes}{$old_parent_type}{name}.': '.$old_parent_name.' ('.$old_parent_info.')';
			} else {
				$old_parent_detail = 'Unknown / Deleted ('.$old_parent_info.')';
			}
		}

		# also need new detail
		if ($new_parent_name eq 'Top Level') { # easy
			$new_parent_detail = $new_parent_name;
		} else { # less easy
			$new_parent_detail = $self->{luggage}->{datatypes}{$args{new_parent_type}}{name}.': '.$new_parent_name.' ('.$args{new_parent_type}.':'.$args{new_parent_id}.')';
		}

		$update_detail = $target_name." moved.\nTo: ".$new_parent_detail."\nFrom: ".$old_parent_detail;
		# we shall have this below
	}

	# some sanity
	$new_parent_string = $args{new_parent_type}.':'.$args{new_parent_id};

	# update the record's main table
	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.'.$self->{table_name}.
		' set parent=? where code=? and server_id=?',
		[$new_parent_string, $code, $server_id]
	);

	# now metainfo table - if metainfo is on
	if ($self->{datatype_info}{metainfo_table} ne 'No Metainfo') {

		$self->{db}->do_sql
			('update '.$self->{database_name}.'.'.$self->{metainfo_table}.
			' set parent=?, update_time=unix_timestamp(), updater=?'.
			' where the_type=? and data_code=?',
			[$new_parent_string, $self->{luggage}{username}, $self->{dt}, $args{data_code}]
		);

		# update the 'children' column for that new parent in metainfo, using fun subroutine below
		if ($new_parent_string ne 'top') { # wouldn't be necessary
			$self->children_update($new_parent_string);
		}

		# also update the old parent's children column
		if ($old_parent_info ne 'top') { # wouldn't be necessary
			$self->children_update($old_parent_info);
		}
	}

	# update the extended status history table?
	if ($self->{datatype_info}{extended_change_history} eq 'Yes') {
		$self->update_history($update_detail,$args{data_code});
	}

	# okay, that's enough about this
}

# useful method to rebuild a 'children' list for a parent
# needs one arg: the new parent string, which is $datatype_id.':'.$data_code
# assumes the 'parent' column is updated in metainfo for the new child(ren)
sub children_update {
	my $self = shift;
	my ($new_parent_string) = @_;

	my ($did_plain_metainfo, $table_is_there, @metainfo_tables, $dt, $metainfo_table, $new_children, $this_new_children, $new_parent_type,$new_parent_id, $new_parent_metainfo_table);

	# datatype and see about its table

	# grab the list from each table
	foreach $dt (split /,/, $self->{luggage}{datatypes}{all_datatypes}) {
		# skip if it is set to skip writing to the parent's children column
		next if $self->{luggage}{datatypes}{$dt}{skip_children_column} eq 'Yes';

		# since datatypes can have their own metainfo tables...
		if ($self->{luggage}{datatypes}{$dt}{metainfo_table} eq 'Own Table') {
			$metainfo_table = $self->{luggage}{datatypes}{$dt}{table_name}.'_metainfo';
		} else {
			$metainfo_table = 'metainfo';
		}

		# skip if it is the plain metainfo table and we already touched it
		next if $did_plain_metainfo && $metainfo_table eq 'metainfo';

		# make sure we only touch the regular metainfo table once
		$did_plain_metainfo = 1 if $metainfo_table eq 'metainfo';

		# make sure this metainfo table exists; may not be there if the
		# otadmin DB was just deployed and any new item's omniclass is not
		# yet instantiated for the first time to call out database_is_ready()
		($table_is_there) = $self->{db}->quick_select(qq{
			select count(*) from information_schema.tables
			where table_name=? and table_schema=?
		}, [$metainfo_table, $self->{database_name}]);

		# skip if not there
		next if !$table_is_there;

		# OK, pull out the potential children
		$this_new_children = $self->{db}->comma_list_select(
			qq{select concat(the_type,':',data_code) from }.
			$self->{database_name}.'.'.$metainfo_table.
			' where parent=?',
			[$new_parent_string]
		);
		$new_children .= ','.$this_new_children if $this_new_children;
	}

	# no leading commas
	$new_children =~ s/^,//;

	# need to break up the parent_string for the update
	($new_parent_type,$new_parent_id) = split /:/, $new_parent_string;

	# which metainfo table do we update?
	if ($self->{luggage}{datatypes}{$new_parent_type}{metainfo_table} eq 'Own Table') {
		$new_parent_metainfo_table = $self->{luggage}{datatypes}{$new_parent_type}{table_name}.'_metainfo';
	} else {
		$new_parent_metainfo_table = 'metainfo';
	}

	# update that new parent
	# so, if the new parent has 4000+ children, i.e. a $new_children string over 65535 chars long,
	# then we aren't going to track that, because it's not like our searching tools is going to use
	# that information (the usefulness of the 'children' column is debatable anyway.  it's just
	# not worth having a mediumtext or longtext column in our possibly-already-overtaxed metainfo table
	if (length($new_children) > 65535) { # still mark the 'update_time
		$self->{db}->do_sql('update '.$self->{database_name}.'.'.$new_parent_metainfo_table.
			qq{ set children='', update_time=unix_timestamp() where the_type=? and data_code=?},
			[$new_parent_type, $new_parent_id]
		);
		# blanking out 'children' as it's better to be blank than inaccurate

	} else { # safe to update the children
		$self->{db}->do_sql('update '.$self->{database_name}.'.'.$new_parent_metainfo_table.
			' set children=?, update_time=unix_timestamp() where the_type=? and data_code=?',
			[$new_children, $new_parent_type, $new_parent_id]
		);
	}

}

# another useful method for getting the 'lineage' of a record, all the way to the top-level
# depends on all the parents and grand-parents having metainfo enabled
sub get_lineage {
	my $self = shift;
	my (%args) = @_;
	my($lineage_array,$target,$current_spot,$datatype,$code,$server_id,$my_parent,$ordered_lineage,$data_code, $last_one, $table_name);

	# no endless loops!
	return if !$args{data_code};

	# if we are in recursive/search mode, keep querying upward until we get to 'top'
	if ($args{lineage_array}[0]) {
		$last_one = @{$args{lineage_array}} - 1;
		$target = $args{lineage_array}[$last_one];
		($datatype,$code,$server_id) = $self->parent_string_bits($target);

		# the table's name might be hiding
		if ($datatype eq $self->{dt}) { # use my table
			$table_name = $self->{table_name};
		} else { # another table, in the datatypes hash
			$table_name = $self->{luggage}{datatypes}{$datatype}{table_name};
		}

		($current_spot) = $self->{db}->quick_select(
			'select parent from '.$self->{database_name}.'.'.$table_name.'
			 where code=? and server_id=?',
			[$code, $server_id]
		);

		# add that to our list
		push(@{$args{lineage_array}},$current_spot);

		# not at top, keep going
		if ($current_spot ne 'top' && $current_spot) {
			$lineage_array = $self->get_lineage(
				'data_code' => $args{data_code},
				'lineage_array' => $args{lineage_array}
			);
		}

		# send it out
		return $args{lineage_array};

	# in start-up mode, start our search based on $args{data_code}
	} else {
		($code,$server_id) = split /_/, $args{data_code};

		($my_parent) = $self->{db}->quick_select(
			'select parent from '.$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?',
			[$code, $server_id]
		);
		# go recursive unless we are at the 'top'
		if ($my_parent eq 'top') { # stop here
			$lineage_array = ['top'];
		} elsif ($my_parent) { # otherwise, keep going
			$lineage_array = $self->get_lineage(
				'data_code' => $args{data_code},
				'lineage_array' => [$my_parent]
			);
		}
	}

	# usually, we will need to go top->down, so reverse it
	@$ordered_lineage = reverse(@$lineage_array);

	# probably need for a screen, so just return back
	return $ordered_lineage;
}

# method to get all the descendents of a record; useful for building trees in object_factory::omniclass_tree()
# NOTE:  This is Alpha and shouldn't be used yet.
sub get_descendants {
	my $self = shift;
	my (%args) = @_;

	# no endless loops!
	return if !$args{data_code};

	# some local vars
	my ($child, $child_dt,$child_data_code, $dt, $metainfo_table, $found_children, $this_records_parent_value);

	# sanity
	my $data_code = $args{data_code};

	# what type of datatype are we looking at?
	if ($args{dt}) { # will be a child of the original data_code
		$dt = $args{dt};
		# figure out the metainfo table for this datatype
		if ($self->{luggage}{datatypes}{$dt}{metainfo_table} eq 'Own Table') {
			$metainfo_table = $self->{luggage}{datatypes}{$dt}{table_name}.'_metainfo';
		} else {
			$metainfo_table = 'metainfo';
		}
	} else { # otherwise, will be the DT for this omniclass object
		$dt = $self->{dt};
		$metainfo_table = $self->{metainfo_table};
	}

	# metainfo.children *should* be accurate, but I trust the 'parent' column more
	$this_records_parent_value = $dt.':'.$data_code;

	$found_children = $self->{db}->list_select(
		qq{select concat(the_type,':',data_code) from }.$self->{database_name}.'.'.$metainfo_table.' where parent=?',
		[$this_records_parent_value]
	);

	if ($$found_children[0]) {
		# add the children list to my data-structure
		$args{descendants}{$this_records_parent_value}{children} = $found_children;

		# recurse down into this record's children and see about the grand-children
		foreach $child (@$found_children) {
			($child_dt,$child_data_code) = split /:/, $child;
			$args{descendants}{$this_records_parent_value} = $self->get_descendants(
				'data_code' => $child_data_code,
				'dt' => $child_dt,
				'descendants' => $args{descendants}{$this_records_parent_value},
			);
		}
	}

	return $args{descendants};

}


# quick method to take a parent string and return the parent's datatype data_code, the parents server_id and the parent's code
sub parent_string_bits {
	my $self = shift;
	my ($parent_string) = @_;
	my ($parent_type,$parent_data_code,$parent_code,$parent_server_id);

	# kind of easy, just don't want to type it over and over
	($parent_type,$parent_data_code) = split /:/, $parent_string;
	($parent_code,$parent_server_id) = split /_/, $parent_data_code;

	return ($parent_type,$parent_code,$parent_server_id);
}

1;
