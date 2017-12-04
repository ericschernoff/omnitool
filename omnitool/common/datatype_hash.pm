package omnitool::common::datatype_hash;

# please see pod documentation included below
# perldoc omnitool::common::datatype_hash

$omnitool::common::datatype_hash::VERSION = '6.0';

# load exporter module and export the subroutines
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( get_datatypes_hash get_datatype_names get_datatype_field_names );

# we keep the serialized/cached hash in a mysql table, so we will
# need these modules to get it out of hock
use Storable qw( nfreeze thaw );

# time to grow up
use strict;

# start the dtHash subroutine, where we build the datatype hash -- which contains all kinds of good info on datatypes
sub get_datatypes_hash {
	# localize our variables & grab args
	my ($nice_list, $pull_from_applications, $table_name, $omnitool_admin_db, @column_names, $application_id, $dir, @data, $all_datatype_list, $code, $col, $cols, $datatype_hash_string, $datatype_hash, $datatypes, $db, $dkeys, $dt_fields, $dt, $dtf, $dtfs, $dtHashString, $id, $kids, $no_cache, $parent, $priority, @field_columns, $field_cols, $col, $fkeys, $fields, $hostname, $omnitool_admin_databases, $otadmin_db, $real_hostname);

	($hostname,$db,$no_cache) = @_;

	return if !$hostname;

	# check to see if the hash exists
	if (!$no_cache) { # only if they don't want to clear the old one
		($datatype_hash_string) = $db->quick_select(qq{
			select dthash from otstatedata.datatype_hashes where hostname=?
		},[$hostname]);
	}

	# if they have nonCache enabled, don't send out exister
	if (!$no_cache && $datatype_hash_string) { # it does -- pull it out and send it back

		%$datatype_hash = %{ thaw($datatype_hash_string) };
		return $datatype_hash;

	} else { # we're going to have to make it

		# let's fix it so we don't have to come back here if we change the columns in the datatypes table
		# use our handy column-list grabber
		$cols = $db->grab_column_list('omnitool','datatypes',1);
		$field_cols = $db->grab_column_list('omnitool','datatype_fields',1); # will want the 'parent' col for that
		(@field_columns) = split /,/, $field_cols;

		# figure out the parent application ID
		($application_id) = $db->quick_select(qq{
			select parent from instances where hostname=?
		},[$hostname]);
		# clean out the DT ID
		$application_id =~ s/^1_1\://;

		# other applications can share their datatypes with our application; combine that
		# list with our current $application_id from above
		$pull_from_applications = $db->list_select(qq{
			select concat('1_1:',code,'_',server_id) from applications
			where share_my_datatypes=? or concat(code,'_',server_id)=?
		},[$application_id, $application_id]);

		# combine these into a nice list for pulling out all the datatypes
		$nice_list = qq{'}.join(qq{','}, @$pull_from_applications).qq{'};

		# grab the primary datatype records now
		($datatypes,$dkeys) = $db->sql_hash(qq{
			select concat(code,'_',server_id),$cols from datatypes
			where parent in ($nice_list) order by name
		});

		# will need a commaified list of all datatypes for below
		$all_datatype_list = join(',',@$dkeys);

		# some operations on the who kit-and-cabodle
		foreach $dt (@$dkeys) {
			# article to use in 'create a / an' phrases
			if ($$datatypes{$dt}{name} =~ /^[a|e|i|o|u|y]/i && $$datatypes{$dt}{name} !~ /^(ho|un|us|on)/i) {
				$$datatypes{$dt}{article} = 'an';
			} else {
				$$datatypes{$dt}{article} = 'a';
			}

			# grab out the fields for this datatype
			# i hate to do this in invidual queries per datatype, esp. since there may be 200+ datatypes,
			# however, this routine should only run once every few days at most, and it should be a pretty fast table
			($fields,$fkeys) = $db->sql_hash(
				qq{select concat(code,'_',server_id),$field_cols from datatype_fields where parent=? order by priority},
				('bind_values' => ['6_1:'.$dt])
			);
			foreach $dtf (@$fkeys) {
				# cannot serialize hash references and expect to get real data back later, so make it a real data struct
				foreach $col (@field_columns) {
					$$datatypes{$dt}{fields}{$dtf}{$col} = $$fields{$dtf}{$col};
				}
				push(@{ $$datatypes{$dt}{fields_key} },$dtf);

				# track all the columns in the db table for loading / saving; only for 'real' / non-virtual fields
				$$datatypes{$dt}{all_db_columns} .= ','.$$datatypes{$dt}{fields}{$dtf}{table_column} if $$datatypes{$dt}{fields}{$dtf}{virtual_field} ne 'Yes';

				# track if this datatype accepts file uploads
				if ($$datatypes{$dt}{fields}{$dtf}{field_type} eq 'file_upload') {
					# this tells omniclass->new() to load file_manager.pm
					$$datatypes{$dt}{has_file_upload} = 1;
					# and this builds in a virtual field for loader.pm to provide a download link
					$$datatypes{$dt}{fields}{$dtf.'_download'} = {
						'name' => 'Download '.$$datatypes{$dt}{fields}{$dtf}{name},
						'virtual_field' => 'Yes',
						'table_column' => $$datatypes{$dt}{fields}{$dtf}{table_column}.'_download',
						'field_type' => 'file_download',
					};
					push(@{ $$datatypes{$dt}{fields_key} },$dtf.'_download');
				}

				# also track encrypted text filds
				push(@{$$datatypes{$dt}{encrypted_fields}},$dtf) if $$datatypes{$dt}{fields}{$dtf}{field_type} =~ /encrypt/;
			}

			# trim that leading comma, so we don't forget it's there ;)
			$$datatypes{$dt}{all_db_columns} =~ s/,//;

			# also, if any datatype is set to contain all, translate that to codes
			$$datatypes{$dt}{containable_datatypes} = $all_datatype_list if $$datatypes{$dt}{containable_datatypes} eq "All";

			# special sub-hash for resolving table-names to datatype ID's
			$table_name = $$datatypes{$dt}{table_name}; # sanity
			$$datatypes{table_names_to_ids}{$table_name} = $dt;
		}

		# keep those ordered keys for future use
		$$datatypes{all_datatypes} = $all_datatype_list;

		# save out if not in no-cache mode
		if (!$no_cache) {
			$dtHashString = nfreeze($datatypes);
			$db->do_sql(qq{replace into otstatedata.datatype_hashes (dthash,hostname) values (?,?)},
				[$dtHashString,$hostname]
			);
		}

		# send out our hashref
		return $datatypes;
	}
}

# method to grab the names of a app's datatypes within a particular ot admin database
# useful for the OmniClass packages used for OT Administration
sub get_datatype_names {
	my ($app_id, $db, $database_name) = @_;
	# requires application ID, database object, and database name; all required

	return if !$app_id || !$db || !$database_name;

	# construct the table names
	my $app_table_name = $database_name.'.applications';
	my $dt_table_name = $database_name.'.datatypes';

	# other applications can share their datatypes with our application; combine that
	# list with our current $application_id from above
	my $pull_from_applications = $db->list_select(qq{
		select concat('1_1:',code,'_',server_id) from $app_table_name
		where share_my_datatypes=? or concat(code,'_',server_id)=?
	},[$app_id, $app_id]);

	# combine these into a nice list for pulling out all the datatypes
	my $nice_list = qq{'}.join(qq{','}, @$pull_from_applications).qq{'};

	# very nice query
	my ($datatypes_names, $datatypes_keys);
	($datatypes_names, $datatypes_keys) = $db->sql_hash(qq{
		select concat(code,'_',server_id),name from $dt_table_name
		where parent in ($nice_list) order by name
	});

	return ($datatypes_names, $datatypes_keys);
}

# another OT Admin support subroutine:  grab datatype field names for a specific datatype in this DB
sub get_datatype_field_names {
	my ($datatype_id, $db, $database_name) = @_;
	# requires datatype ID, database object, and database name; all required

	return if !$datatype_id || !$db || !$database_name;

	# construct the table name
	my $table_name = $database_name.'.datatype_fields';

	my ($datatype_fields_names, $datatype_fields_keys, $field);

	# very nice query
	($datatype_fields_names, $datatype_fields_keys) = $db->sql_hash(qq{
		select concat(code,'_',server_id),name,virtual_field,field_type from $table_name where parent=? order by name,(virtual_field='Yes')
	},( 'bind_values' => ['6_1:'.$datatype_id] ) );

	# need to get any 'file_download' virtual fields in there
	foreach $field (@$datatype_fields_keys) {
		next if $$datatype_fields_names{$field}{field_type} ne 'file_upload';
		# add the file_download' virtual field
		$$datatype_fields_names{$field.'_download'} = {
			'name' => 'Download '.$$datatype_fields_names{$field}{name},
			'virtual_field' => 'Yes',
			'field_type' => 'file_download',
		};
		push(@$datatype_fields_keys,$field.'_download');
	}

	return ($datatype_fields_names, $datatype_fields_keys);
}


1;


__END__

=head1 omnitool::common::datatype_hash

System module to build a nice cached hash of datatype definitions (which are used in omniclass.pm to
build objects). Unlike previous versions, this module will load just the datatype definitions for
a specified Application Instance, which is generally the one in current use.

We need an Instance's hostname and a omnitool::common::db object as arguments to interact with the database.
We do depend on the omnitool::common::db object being set to the OmniTool Admin database for the current
Instance / Hostname, which pack_luggage will do for us.

This will usually be called in the luggage() routine, who also packages up our db object, session data, and
this datatype hash into a nice portable hashref.

The basic/main info on the datatypes will be stored in the 'datatypes' table in the OmniTool Admin databases.
The structural information, the info on the fields db columns, will be stored in the 'datatype_fields' table.

Usage:

	$datatypes = get_datatypes_hash($hostname,$db);
	Retrieves the pre-built datatype definitions hash from our little cache; builds it if not in said cache.

	$datatypes = get_datatypes_hash($hostname,$db,1);
	This forces a re-build; useful if you made a change in Admin screen; new version is saved into our cache.

I have also stashed a little subroutine here called 'get_datatype_names', which is for grabbing the primary keys
and names for Datatypes within one app in the current OmniTool Admin DB; this is for the administrative tools only.
