package omnitool::common::file_manager;
# methods for storing / updating / retrieving files saved for your instance
# works with omnitool::omniclass::manage_files, and should be called from there.

# sixth time's the charm
$omnitool::common::file_manager::VERSION = '6.0';

# time to grow up
use strict;

# library for opening files from the file system
use File::Slurp;

# for opening files via HTTP / HTTPS
use HTTP::Tiny;

# for determining a file's mime type based on file name
use MIME::Types;

# for determining the size of a file / scalar
use Devel::Size qw(total_size);

# for saving/loading files via swift
use Net::OpenStack::Swift;

# set myself up:  need the %$luggage and alternatively a $db object
sub new {
	my $class = shift;
	# required arguments
	my (%args) = @_;
	# looks like:
	#	'luggage' => $luggage, # required
	#	'db' => omnitool::common::db object, optional, will default to $args{luggage}{db};

	# fail if no %$luggage provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an omnitool::common::file_manager object without my luggage.'});
	}

	# did they provide a $db? if not, use $$luggage{db}
	if (!$args{db}) {
		$args{db} = $args{luggage}{db};
	}

	# bless myself
	my $self = bless \%args, $class;

	# get a mime-type object
	$self->{mime_type} = MIME::Types->new;

	# where logging goes
	$self->{logtype} = 'file_manager';

	# simplification:
	# isolate the target table:
	$self->{table} = $self->{luggage}{database_name}.'.stored_files';
	# isolate the storage method / location

	# first the method
	$self->{file_storage_method} = $self->{luggage}{session}{app_instance_info}{file_storage_method};

	# the location is encrypted because if the method is 'swift,' the credentials will be in there
	$self->{file_location} = $self->{db}->decrypt_string( $self->{luggage}{session}{app_instance_info}{file_location}, '127_1' );

	# if swift store, break out the credentials and set up the client object
	if ($self->{file_storage_method} eq 'Swift Store') {
		my ($auth_url, $username, $password) = split /\|/, $self->{file_location};

		$self->{swift_object} = Net::OpenStack::Swift->new(
			auth_version  => '1.0',
			auth_url       => $auth_url,
			user           => $username,
			password       => $password,
			tenant_name   => 'AUTH'.$username,
		);
	}

	# ready to go
	return $self;
}

# wrapper method to receive a file and save it into the system
sub store_file {
	my $self = shift;

	# first argument is required, which points one of a (a) file upload,
	# (b) filesystem location or (c) web uri for download
	my ($file_to_receive,$data_code) = @_;
	# optional second argument is the data_code for a file we may be overriding

	# declare the rest of our vars
	my ($file, $filename, $filesize, $suffix, $mime_type, $size_in_kb, $location, $result, $code, $server_id, $file_info);

	# return if that was not provided
	if (!$file_to_receive) {
		$self->{luggage}{belt}->logger('ERROR: Can not store file without a file pointer.',$self->{logtype});
		return;
	}

	# use the appropriate method for retrieving the actual file, including file name, suffix, and mime type
	if ($self->{luggage}{belt}->{request} && $self->{luggage}{belt}->{request}->uploads->{$file_to_receive}) { # uploaded via the web
		($file,$filename,$filesize) = $self->receive_from_upload($file_to_receive);

	} elsif ($file_to_receive =~ /^http/i) { # web url to fetch
		($file,$filename,$filesize) = $self->receive_from_web($file_to_receive);

	} elsif (-e "$file_to_receive") { # file in my filesystem
		($file,$filename,$filesize) = $self->receive_from_filesystem($file_to_receive);

	} elsif ($file_to_receive =~ /^COPY:/) { # they want to copy a pre-existing file
		# isolate the primary key
		$file_to_receive =~ s/COPY://;

		# load up the file itself
		$file = $self->retrieve_file($file_to_receive);

		# and get the need info
		$file_info = $self->load_file_info($file_to_receive);
		$filename = $$file_info{filename};
		$filesize = $$file_info{size_in_kb} * 1024;

	} else { # cannot retrieve
		$self->{luggage}{belt}->logger("ERROR: Can not retrieve $file_to_receive.",$self->{logtype});
		return;
	}

	# note that $file is actually a memory reference to the file

	# figure out the suffix of the filename
	($suffix = $filename) =~ s/^.*\.//g;
	if (!$suffix) { # default to '.file'
		$suffix = 'file';
		$filename .= '.file';
	}

	# then mime_type
	$mime_type = $self->{mime_type}->mimeTypeOf($filename);
	$mime_type ||= 'application/binary';

	# get the size of the file in Kilobytes
	$size_in_kb = sprintf("%.0f",$filesize/1024);

	# return if blank file
	if (!$filesize) {
		$self->{luggage}{belt}->logger("ERROR: No data found in $file_to_receive.",$self->{logtype});
		return;
	}

	# get the current month abbreviation, which will be sub-directory/location of the new file
	# with the database name pre-pended
	$location = $self->{luggage}{database_name}.'_'.$self->{luggage}{belt}->time_to_date(time(),'to_month_abbrev');

	# if they passed a $data_code, they want to overwrite a file / stored_files record
	if ($data_code) {
		$result = $self->remove_file($data_code);
		# if that failed, it was not a real record, and we should be doing an 'insert'
		$data_code = '' if !$result;
	}

	# if the $data_code is filled, do an update for the record in database table
	if ($data_code) {
		($code,$server_id) = split /_/, $data_code;
		$self->{db}->do_sql(
			'update '.$self->{table}.' set updated=unix_timestamp(), location=?, '.
			qq{filename=?, suffix=?, mime_type=?, size_in_kb=? where code=? and server_id=?},
			[$location, $filename, $suffix, $mime_type, $size_in_kb, $code, $server_id]
		);

	# create the record in database table for this new file and get that new unique code to save off the file
	} else {
		$self->{db}->do_sql(
			'insert into '.$self->{table}.' (server_id,updated,location,filename,suffix,mime_type,size_in_kb) '.
			'values ('.$self->{db}->{server_id}.',unix_timestamp(),?,?,?,?,?)',
			[$location, $filename, $suffix, $mime_type, $size_in_kb]
		);
		# determine the new primary key
		$data_code = $self->{db}->{last_insert_id}.'_'.$self->{db}->{server_id};
	}

	# now, save the file using the appropriate method
	if ($self->{file_storage_method} eq 'File System') {
		$self->save_to_filesystem($file,$data_code,$suffix,$location);

	} elsif ($self->{file_storage_method} eq 'Swift Store') {
		$self->save_to_swift($file,$data_code,$suffix,$location);

	}

	# return the new data_code from stored_files
	return $data_code;

}

# method to retrieve a stored file, either loading it into a memory reference
# or sending out to the web client
sub retrieve_file {
	my $self = shift;

	# first argument is the primary key for the 'stored_files' table
	# second, optional argument instructs to send out the file, if filled.
	my ($data_code,$send_out) = @_;

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for retrieve_file().",$self->{logtype});
		return;
	}

	# grab the file information from the DB
	my $file_info = $self->load_file_info($data_code);

	# now, load the file using the appropriate method
	# this returns a memory reference to the file contents
	my ($file);
	eval {
		if ($self->{file_storage_method} eq 'File System') {
			$file = $self->load_from_filesystem($data_code,$file_info);
	
		} elsif ($self->{file_storage_method} eq 'Swift Store') {
			$file = $self->load_from_swift($data_code,$file_info);
		}
	};
	if ($@) { # there was an error: put that into the file contents
		$file = $@;
	}
	
	# if they want to send it to the client, let's do so and end here
	if ($send_out) {
		$self->{luggage}{belt}->mr_zebra(${$file}, 2, $$file_info{mime_type}, $$file_info{filename});

	# otherwise, return that memory reference with the file contents
	} else {
		return $file;
	}
}

# method to delete a file from storage, and possibly the database
sub remove_file {
	my $self = shift;

	# required argument is the data_code for the record in stored_files
	# optional arg will indicate to delete the stored_files record too
	my ($data_code,$delete_from_database) = @_;

	my ($code,$server_id,$result,$file_info);

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for remove_file().",$self->{logtype});
		return 0;
	}

	# load the file information hashref
	$file_info = $self->load_file_info($data_code);

	# make sure it found a real record
	return 0 if !$$file_info{updated};

	# call the proper subroutine to delete the file
	if ($self->{file_storage_method} eq 'File System') {
		$result = $self->remove_from_filesystem($data_code,$file_info);

	} elsif ($self->{file_storage_method} eq 'Swift Store') {
		$result = $self->remove_from_swift($data_code,$file_info);
	}

	# remove from the database if they want that
	# may be skipping this if we are overwriting an existing file in store_file
	if ($delete_from_database) {
		($code,$server_id) = split /_/, $data_code;
		$self->{db}->do_sql('delete from '.$self->{table}.qq{ where code=? and server_id=?},[$code, $server_id] );
	}

	# report what the remove-file routine reported
	return $result;

}


# method to pull out information for a file; returns a nice hashref
sub load_file_info {
	my $self = shift;

	# only argument is the primary key for the 'stored_files' table
	my ($data_code) = @_;

	# that arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for load_file_info().",$self->{logtype});
		return;
	}

	my (%file_info);

	# field names in one spot
	my $field_list = 'location,filename,suffix,mime_type,size_in_kb,updated';
	my ($code,$server_id) = split /_/, $data_code;
	my (@results) =
		$self->{db}->quick_select(qq{
			select $field_list from }.$self->{table}.qq{ where code=? and server_id=?},
		[$code,$server_id]
	);

	# read them in
	my ($field);
	foreach $field (split /,/, $field_list) {
		$file_info{$field} = shift @results;
	}

	# if saved locally, provide the full path to the file
	if ($self->{file_storage_method} eq 'File System') {
		$file_info{filepath} = $self->{file_location}.'/'.$file_info{location}.'/'.$data_code.'.'.$file_info{suffix};

	# swift store needs the object name
	} else {
		$file_info{object_name} = $data_code.'.'.$file_info{suffix};
	}

	# make that date human-friendly
	$file_info{updated_human} = $self->{luggage}{belt}->time_to_date(
		$file_info{updated},
		'to_date_human_time',
		$self->{luggage}{timezone}
	);

	# ship it out
	return \%file_info;
}

# subroutine to get all of the stored files data_codes which are tied to a particular record
# used for deletes
sub get_stored_files_for_record {
	my $self = shift;

	# need the data_code of the record and the datatype ID
	my ($record_data_code, $record_data_type) = @_;

	# fail out if both are not provided
	if (!$record_data_code || !$record_data_type) {
		$self->{luggage}{belt}->logger("ERROR: Both the 'record_data_code' and 'record_data_type' arguments are required for get_stored_files_for_record().",$self->{logtype});
		return;
	}

	# easy-peasy
	my $stored_files = $self->{db}->list_select(qq{
		select concat(code,'_',server_id) from }.$self->{table}.qq{ where tied_to_record_id=? and tied_to_record_type=?},
	[$record_data_code,$record_data_type]);

	# return
	return $stored_files;
}

# subroutine to tie a record in stored_file to a omniclass data record / field
sub tie_to_record {
	my $self = shift;

	# required arguments are the data_code for the stored_files record
	# the the record's datatype ID, data code and field ID
	my ($data_code,$record_datatype,$record_data_code,$record_field) = @_;

	# all arguments required
	if (!$data_code || !$record_datatype || !$record_data_code || !$record_field) {
		$self->{luggage}{belt}->logger("ERROR: All arguments required for tie_to_record().",$self->{logtype});
		return;
	}

	# do the update
	my ($code,$server_id) = split /_/, $data_code;
	$self->{db}->do_sql(
		'update '.$self->{table}.' set tied_to_record_type=?, tied_to_record_id=?, tied_to_record_field=? '.
		qq{where code=? and server_id=?},
	[$record_datatype, $record_data_code, $record_field, $code, $server_id]);

}

### Start Supporting Methods ###

# method to receive an uploaded file from Plack::Request
sub receive_from_upload {
	my $self = shift;

	# the argument will be a field name
	my $field_name = $_[0];
	# this is required
	return if !$field_name;

	# get the Plack::Request::Upload object
	my $upload = $self->{luggage}{belt}->{request}->uploads->{$field_name};

	# slurp in the file
	my $file = read_file($upload->path);

	# return a memory reference to that file glob, the original filename, and the size
	# of the file in bytes
	return (\$file, $upload->filename, total_size($file));
}

# method to receive a file from web via HTTP::Tiny
sub receive_from_web {
	my $self = shift;

	# the argument will be a url
	my $url = $_[0];
	# this is required
	return if !$url;

	# figure out the filename
	my (@bits) = split /\//, $url;

	# if a file name is not evident, provide a placeholder
	if ($bits[-1] !~ /\..+$/ || $bits[-1] =~ /\?|\&/) {
		push(@bits,'web_download.file');
	}

	# $filename will be $bits[-1];

	my $response = HTTP::Tiny->new->get($url);

	# if it failed, log and return
	if (!$response->{success}) {
		$self->{luggage}{belt}->logger("ERROR: Could not fetch $url.",$self->{logtype});
		return;
	}

	# load into a scalar
	my $file = $response->{content};

	# return a memory reference to that file glob, the original filename, and the size
	# of the file in bytes
	return (\$file, $bits[-1], total_size($file));

}

# method to receive a file from the file system
sub receive_from_filesystem {
	my $self = shift;

	# the argument will be a url
	my $filepath = $_[0];
	# this is required
	return if !$filepath || !(-e "$filepath");

	# figure out the filename - $bits[-1] will be it
	my (@bits) = split /\//, $filepath;

	# slurp into a scalar
	my $file = read_file($filepath);

	# return a memory reference to that file glob, the original filename, and the size
	# of the file in bytes
	return (\$file, $bits[-1], total_size($file));

}

# method to save a retrieved/uploaded/provided file into the file system
sub save_to_filesystem {
	my $self = shift;

	# arguments are: (1) the memory reference to the file contents,
	# (2) the data_code for the file in the 'stored_files' table,
	# (3) the suffix / extension for the file and (4) the sub-location/sub-directory
	# for the file to be saved into
	my ($file,$data_code,$suffix,$location) = @_;

	# all of those are required
	if (!$file || !$data_code || !$suffix || !$location) {
		$self->{luggage}{belt}->logger("ERROR: All four arguments required for save_to_filesystem().",$self->{logtype});
		return;
	}

	# here is the target directory
	my $target_directory = $self->{file_location}.'/'.$location;
	# make sure that exists
	if (!(-d "$target_directory")) {
		mkdir($target_directory);
	}

	# construct our full path: file is named based on the primary key in the DB table, with the suffix
	my $filepath = $target_directory.'/'.$data_code.'.'.$suffix;

	# good 'ol file::slurp
	write_file($filepath,$$file);

	# and that's it ;)
}

# TODO: method to save a retrieved/uploaded/provided file into a swift store
# based on the instance's configuration
sub save_to_swift {
	my $self = shift;
	# arguments are: (1) the memory reference to the file contents,
	# (2) the data_code for the file in the 'stored_files' table,
	# (3) the suffix / extension for the file and (4) the sub-location/sub-directory
	# for the file to be saved into
	my ($file,$data_code,$suffix,$location) = @_;

	# all of those are required
	if (!$file || !$data_code || !$suffix || !$location) {
		$self->{luggage}{belt}->logger("ERROR: All four arguments required for save_to_swift().",$self->{logtype});
		return;
	}

	# need to log in to transact business
	my ($storage_url, $token) = $self->{swift_object}->get_auth();

	# make sure the container exists
	my $headers = $self->{swift_object}->put_container(container_name => $location);

	# need the actual size of the file
	my $real_size = length(${$file});

	# $self->{luggage}{belt}->logger("$data_code - $suffix",$self->{logtype});

	# now upload it to swift
	my $headers = $self->{swift_object}->put_object(container_name => $location,
		object_name => $data_code.'.'.$suffix, content => ${$file},
		content_length => $real_size);

	# and that's it ;)

}

# method to load up a file saved in the file system
sub load_from_filesystem {
	my $self = shift;

	# required argument is the primary key / data_code from the stored_files table
	# optional is to provide the %$file_info hash from load_file_info()
	my ($data_code, $file_info) = @_;

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for retrieve_file().",$self->{logtype});
		return;
	}

	# if file-info was not provied, grab the file information from the DB
	if (!$$file_info{updated}) {
		$file_info = $self->load_file_info($data_code);
	}

	# the absolute path to the file will be in $$file_info{filepath}
	# make sure it's there
	if (!(-e "$$file_info{filepath}")) { # fatal error if not
		$self->{luggage}{belt}->mr_zebra("ERROR: A $$file_info{filepath} could not be loaded.",1);
	}

	# otherwise, load it up and return the memory reference
	my $file = read_file($$file_info{filepath});

	return \$file;
}

# TODO: Load a file from the swift store
sub load_from_swift {
	my $self = shift;

	# required argument is the primary key / data_code from the stored_files table
	# optional is to provide the %$file_info hash from load_file_info()
	my ($data_code, $file_info) = @_;

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for retrieve_file().",$self->{logtype});
		return;
	}

	# if file-info was not provied, grab the file information from the DB
	if (!$$file_info{updated}) {
		$file_info = $self->load_file_info($data_code);
	}

	# need to log in to transact business
	my ($storage_url, $token) = $self->{swift_object}->get_auth();

	# pull it from the swift store.
	my ($file);
	eval {
		my $etag = $self->{swift_object}->get_object(container_name => $$file_info{location},
			object_name => $$file_info{object_name}, write_code => sub {
	            my ($status, $message, $headers, $chunk) = @_;
	            $file .= $chunk;
	    });
    };
    if ($@) { # if it's not there, show the error in the file and not a fatal error
		$file = $@;
    }

	return \$file;
}

# method to delete a file from our file system
sub remove_from_filesystem {
	my $self = shift;

	# required argument is the primary key / data_code from the stored_files table
	# optional is to provide the %$file_info hash from load_file_info()
	my ($data_code, $file_info) = @_;

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for remove_from_filesystem().",$self->{logtype});
		return 0;
	}

	# if file-info was not provied, grab the file information from the DB
	if (!$$file_info{updated}) {
		$file_info = $self->load_file_info($data_code);
	}

	# give it our best college try
	unlink $$file_info{filepath} or $self->{luggage}{belt}->logger("ERROR: Could not delete $$file_info{filepath} ($data_code).",$self->{logtype});

	return 1;
}

# method to delete a file from a swift store
sub remove_from_swift {
	my $self = shift;

	# required argument is the primary key / data_code from the stored_files table
	# optional is to provide the %$file_info hash from load_file_info()
	my ($data_code, $file_info) = @_;

	# first arg is required
	if (!$data_code) {
		$self->{luggage}{belt}->logger("ERROR: A 'data_code' argument is required for remove_from_swift().",$self->{logtype});
		return 0;
	}

	# if file-info was not provied, grab the file information from the DB
	if (!$$file_info{updated}) {
		$file_info = $self->load_file_info($data_code);
	}

	# need to log in to transact business
	my ($storage_url, $token) = $self->{swift_object}->get_auth();

	# remove from swift store - carefully
	eval {
		my $headers = $self->{swift_object}->delete_object(container_name => $$file_info{location} ,
			object_name => $$file_info{object_name} );
	};

	return 1;
}

1;

__END__

=head1 omnitool::common::file_manager

This package / class handles the storage and retrieval of files as attachments to database
records.  Most of these files are sent in as form uploads via 'file_upload' Datatype fields,
and this package is meant to interact with the OmniClass objects to load in these uploaded files.

Every Application Instance database will have a 'stored_files' table (part of the baseline tables),
which will look like this:

	CREATE TABLE `stored_files` (
	  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
	  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
	  `location` varchar(100) NOT NULL,
	  `filename` varchar(100) NOT NULL,
	  `suffix` varchar(12) NOT NULL,
	  `mime_type` varchar(60) DEFAULT NULL,
	  `updated` int(11) unsigned DEFAULT NULL,
	  `size_in_kb` int(11) unsigned DEFAULT NULL,
	  `tied_to_record_type` varchar(30) DEFAULT NULL,
	  `tied_to_record_id` varchar(30) DEFAULT NULL,
	  `tied_to_record_field` varchar(30) DEFAULT NULL,
	  PRIMARY KEY (`code`,`server_id`),
	  KEY `tied_to_record` (`tied_to_record_type`,`tied_to_record_id`,`tied_to_record_field`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8

And this will allow for the look-ups of the files, their names, and where they are stored.
The 'code' and 'server_id' columns make up the primary key, and that primary key will
be stored into the primary (OmniClass) data record's file_upload column.

When defining an Application Instance, you can configure how and where files will be stored via
the 'File Storage Method' and 'File Location' fields.  Currently, we have support for two
File Storage Methods:  File System (on the server's disk) and Swift Storage, via an OpenStack
Swift Store.  If you set 'File Storage Method' to 'File System,' then the 'File Location' should
be the root directory for the files.  For example, /export/webapps/files .

The 'location' column in the 'stored_files' table will be the abbreviation for the current month,
i.e. 'Mar16'.  This is auto-calculated and will be set up as a sub-directory for File System storage 
or sub-container for Swift Store.

The 'filename' will be original filename for the file.  The actual fiel will be saved in its storage 
location under its primary key -- concat(code,'_',server_id) -- plus the file extension/suffix.

This module does support retrieving files as Plack uploads, Web URL's or full-paths to local files.
Please note that retrieving files via Web URL's requires that those URL's do not require authentication.

Below are the methods you will call from outside this package.  There are several supporting methods
we will not document.  Please also see the notes for the 'send_file' methods in both Tool.pm and
OmniClass.

=head2 new()

Creates the file manager object.

Usage:

	$file_manager = omnitool::common::file_manager->new(
		'luggage' => $luggage,	# %$luggage hash; required, can't leave home without your luggage
		'db' => $db, # optional; alternative database object; will default to $$luggage{db}
	);

The DB handle provided in luggage or as an argument must point to a valid Instance database.  Honor
system on that for now :)

=head2 load_file_info()

Returns a hashref containing file information from stored files.  Expects the primary key of a
record in stored_files.

Usage:

	$info = $file_manager->load_file_info($data_code);

And $info will look like:

	$VAR1 = {
		'location' => 'Feb16',
		'size_in_kb' => '61',
		'updated_human' => 'GMT Feb 20 - 10:09pm',
		'mime_type' => 'application/octet-stream',
		'filename' => 'session.dump',
		'updated' => '1456006188',
		'filepath' => '/export/webapps/files/family/Feb16/5_1.dump',
		'suffix' => 'dump'
	};

=head2 retrieve_file()

Loads the file from either its storage method/location and either (a) returns a memory reference
to the file contents or (b) ships out the file via mr_zebra().  If you ship out that way, mr_zebra()
will set the 'content-type' header as well as send out the original filename.

Expects the primary key of a record in stored_files.

Usage:

	$file_reference = $file_manager->retrieve_file($data_code);

	To output the file contents, use:  print ${$file_reference};

	$file_manager->retrieve_file($data_code,1);

	Sends out the file to the web client.

The function to deliver files to the web clients is exposed via the 'fetch_uploaded_file' function
in omnitool_routines.js, referring to the 'send_file' method in tool::center_stage along with
omniclass::loader::send_file.  To create a link for downloading a file, your virtual field hooks
can create a link such as:

	"javascript:tool_objects['".$self->{tool_and_instance}."'].fetch_uploaded_file('".$self->{metainfo}{$r}{altcode}."');"

=head2 store_file()

Stores a file into our desired method/location and creates (or updates) the corresponding record
in the 'stored_files' table.

First argument is required.  It should be one of:

	1. A PSGI param name pointing to an upload field, for which the user did provide a file.
	2. A full-path to a file on the local filesystem, i.e. /usr/home/eric/notes.txt
	3. A Web URI to a file not protected by a password, i.e. http://www.walnutstreetrentals.com/images/wsr_logo2015sm.jpg
	4. Another file already saved in this database, i.e. 'COPY:5_2' to duplicate the file with the primary 
		key of 5_2 in stored_files.

The second argument is optional, and it would be the primary key -- concat(code,'_',server_id) -- of an existing
record in the 'stored_files' table.  If that is provided, the target record will be updated and the corresponding
stored file will be overwritten with the new file.

This returns the primary key of the new or updated record in stored_files.

Usage:

	$data_code = $file_manager->store_file($file_to_retrieve);

	Creates new file / record in stored_files.

	$data_code = $file_manager->store_file($file_to_retrieve,$existing_data_code);

	Updates the stored_files record identified by $existing_data_code.

=head2 tie_to_record()

Updates the 'tied_to_record_type', 'tied_to_record_id', and 'tied_to_record_field' fields so
that the 'stored_files' records maps to the OmniClass-managed data to which it belongs.  Meant
to make it easier to write maintenance / cleaning scripts more easily.

All four arguments are required, and thease are:

	- The primary key of the target entry in stored_files.
	- The primary key of the OmniClass Datatype for the tied-to-record.
	- The primary key for the tied-to-record.
	- The primary key of the OmniClass Datatype Field for the tied-to-record.

Usage:

	$file_manager->tie_to_record($data_code,$record_datatype,$record_data_code,$record_field);

This is called from omniclass::saver(), and will very likely not be used anywhere else.

=head2 get_stored_files_for_record()

This is used to get all of the stored files associated with a particular record in your database.  It is
most useful when deleting, so please see it in action in omnitool::omniclass::deleter.

It requires a data_code plus a datatype ID as an argument, and returns a arrayref of the primary keys
(code,'_',server_id) from stored_files for those files associated with that record.

Usage

	$list_of_stored_file_keys = $file_manager->get_stored_files_for_record($data_code,$datatype_id);
