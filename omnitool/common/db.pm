package omnitool::common::db;

# please see pod documentation included below
# perldoc omnitool::common::db

$omnitool::common::db::VERSION = '6.0';

# load needed third-part modules
use DBI; # tim bounce, where would the world be without you? nowhere.
use File::Slurp;
use Try::Tiny;

# for error logging
use omnitool::common::utility_belt;

# for storing / retrieving data structures via the hash_cache() method
use Storable qw( nfreeze thaw dclone );

# for checking the status of the DBI reference
use Scalar::Util qw(blessed);

# time to grow up
use strict;

# create ourself and connect to the database
sub new {
	my $class = shift;

	# declare vars
	my ($connect_to_database, $dbh, $dsn, $host, $password, $self, $username, $hostname, $credentials, $outside_server, $iv);

	# grab args
	($hostname,$connect_to_database,$outside_server) = @_;

	# if $connect_to_database is empty, go with the main 'omnitool' system database
	$connect_to_database ||= "omnitool";

	# if they provided a $hostname, we shall try to connect to that; otherwise, connect to the
	# default dababase server's IP.  Try to look in $ENV{DATABASE_SERVER}
	# Factory standard is the localhost IP, but change this
	# line if your default DB server is separate
	if (!$hostname) {
		if ($ENV{DATABASE_SERVER}) {
			$hostname = $ENV{DATABASE_SERVER};
		} else {
			$hostname = '127.0.0.1';
		}
	}

	# the theory goes that the default database server in $ENV{DATABASE_SERVER} for this Plack server
	# should be the default server for the application instance being served by this hostname.
	# in some circumstances, this may not be the case, and you should either send an alternate
	# hostname or live with the fact that we might end up constructing two database objects to
	# get right.

	# let them set up their own init vector
	if ($ENV{INIT_VECTOR}) {
		$iv = $ENV{INIT_VECTOR};
	} else { # default
		$iv = 'A104EE235B045DA9AB50DE1F5FA8E2B1202534983037819BAE';
	}

	# make the object
	$self = bless {
		'hostname' => $hostname,
		'created' => time(),
		'current_database' => $connect_to_database,
		'outside_server' => $outside_server,
		'iv' => $iv,
	}, $class;
	# change the 'iv' key to make your installation more unique and possibly more secure
	# however, you can't change it again without first de-crypting every value encrypted with it

	# now connect to the database and get a real DBI object into $self->{dbh}
	$self->connect_to_database();

	return $self;
}

# special method to connect or re-connect to the database
sub connect_to_database {
	my $self = shift;

	# only do this if $self->{dbh} is not already a DBI object
	return if $self->{dbh} && blessed($self->{dbh}) =~ /DBI/ && $self->{dbh}->ping;

	my ($username, $password, $credentials, $dsn);

	# allow two ways for the DB user/password to be sent
	# First way is via DB_USERNAME / DB_USERNAME env vars
	if ($ENV{DB_USERNAME} && $ENV{DB_PASSWORD}) {
		$username = $ENV{DB_USERNAME};
		$password = $ENV{DB_PASSWORD};
	# second is to load from a (hopefully-secured) file; all databases servers to which
	# omnitool connects should allow this username/password and have the 'omnitool' database
	} else {
		$credentials = read_file($ENV{OTHOME}.'/configs/dbinfo.txt');
		if ($credentials !~ /\n/) { # it's been obfuscated with utility_belt::stash_some_text() via installation
			$credentials = pack "h*", $credentials;
		}
		($username,$password) = split /\n/, $credentials; # notice the format; two-line field, username first, then pw next line
	}

	# make the connection - fail and log if cannot connect
	$dsn = 'DBI:mysql:database='.$self->{current_database}.';host='.$self->{hostname}.';port=3306';
	$self->{dbh} = DBI->connect($dsn, $username, $password,{ PrintError => 0, RaiseError=>0, mysql_enable_utf8=>8 }) or $self->log_errors('Cannot connect to '.$self->{hostname});

	# Set Long to 1000000 for long text...may need to adjust this
	$self->{dbh}->{LongReadLen} = 1000000;

	# let's automatically reconnect if the connection is timed out
	$self->{dbh}->{mysql_auto_reconnect} = 1;
	# note that this doesn't seem to work too well

	# let's use UTC time in DB saves
	$self->do_sql(qq{set time_zone = '+0:00'});

	# i need the server-id of database server on the other end of this connection
	# this is the one spot where we do not use the "concat(code,'_',server_id)" stuff, as this needs to be unique
	if (!$self->{outside_server}) { # skip this if we are connecting to a server outside of this system
		($self->{server_id}) = $self->quick_select(qq{
			select code from database_servers where hostname=?
		},[$self->{hostname}]);
	}

	# are we on MySQL or MariaDB?
	($self->{is_mariadb}) = $self->quick_select(qq{
		select \@\@version like '%maria%'
	});

	# $self->{dbh} is now ready to go
}

# method to make sure I am alive
sub your_birthdate {
	my $self = shift;

	# make sure we are connected to the DB
	$self->connect_to_database();

	# pull and return the info
	my ($created) = $self->quick_select('select from_unixtime('. $self->{'created'}.')');
	return $created;
}

# method to change the current working database for a connection
sub change_database {
	my $self = shift;

	# required argument is the database they want to switch into
	my ($database_name) = @_;

	# nothing to do if that's not specified
	return if !$database_name;

	# no funny business
	return 'Bad Name' if $database_name =~ /[^a-z0-9\_]/i;

	# make sure we are connected to the DB
	$self->connect_to_database();

	# pretty easy
	$self->{dbh}->do(qq{use $database_name});

	# put in object attribute
	$self->{current_database} = $database_name;

	# if this is an OT admin database, make sure we have the right server id
	# this comes into play in pack_luggage()
	if ($database_name =~ /omnitool/) {
		($self->{server_id}) = $self->quick_select(qq{
			select code from database_servers where hostname=?
		},[$self->{hostname}]);
	}

}


# comma_list_select: same as list_select, but returns a commafied list rather than an array
sub comma_list_select {
	my $self = shift;

	# declare vars
	my ($sql, $results,$bind_values);

	# grab args
	($sql,$bind_values) = @_;

	# rely on our brother upstairs
	$results = $self->list_select($sql,$bind_values);

	# nothing found?  just return
	if (!$$results[0]) {
		return;
	} else { # otherwise, return our comma-separated version of this
		return join(',',@$results);
	}
}

# decrypt_string: a method to decrypt a base64-encoded and encrypted string
sub decrypt_string {
	my $self = shift;

	# the arguments are the string to encrypt and the 'salt' value
	my ($encoded_and_encrypted_string,$salt_phrase) = @_;

	# first required is very much required
	return if !$encoded_and_encrypted_string;

	# if no salt is sent, use $ENV{SALT_PHRASE}, failing that, default to the truth
	$salt_phrase ||= $ENV{SALT_PHRASE};
	$salt_phrase ||= 'AllHailGinger'; # please set up a $salt_phrase

	# make sure we are connected to the DB
	$self->connect_to_database();

	# queries are a little difference for MariaDB (no IV, only 128 bits)
	my ($plain_text_string);
	if ($self->{is_mariadb}) {
		($plain_text_string) = $self->quick_select(qq{
			select AES_DECRYPT(FROM_BASE64(?),SHA2(?,512));
		},[ $encoded_and_encrypted_string, $salt_phrase ]);

	# eric hearts mysql
	} else {
		($plain_text_string) = $self->quick_select(qq{
			select AES_DECRYPT(FROM_BASE64(?),SHA2(?,512), ?);
		},[ $encoded_and_encrypted_string, $salt_phrase, $self->{iv} ]);
	}

	# send it out
	return $plain_text_string;
}

# do_sql: our most flexible way to execute SQL statements
sub do_sql {
	my $self = shift;

	# declare vars
	my ($results, $sql, $sth, $bind_values, $cleared_deadlocks);

	# grab args
	($sql,$bind_values) = @_;

	# sql statement to execute and if placeholders used, arrayref of values

	# make sure we are connected to the DB
	$self->connect_to_database();

	# i shouldn't need this, but just in case
	if (!$self->{dbh}) {
		$self->log_errors(qq{Missing DB Connection for $sql.});
	}

	# prepare the SQL
	$sth = $self->{dbh}->prepare($sql) or $self->log_errors(qq{Error preparing $sql: }.$self->{dbh}->errstr());

	# get a utility belt, if we don't have one already
	# UPDATE: Should not need this here, and we do not want to interfere
	# with the belt coming from luggage, since this gets called in new().
	# if (not $self->{belt}->{all_hail}) { # set it up
	#	$self->{belt} = omnitool::common::utility_belt->new();
	# }

	# ready to execute, but we want to plan for some possible deadlocks, since InnoDB is still not perfect
	$cleared_deadlocks = 0;
	while ($cleared_deadlocks == 0) {
		$cleared_deadlocks = 1; # if it succeeds once, we can stop
		# attempt to execute; catch any errors and keep retrying in the event of a deadlock
		try {
			# use $@values if has placeholders
			if ($bind_values) {
				$sth->execute(@$bind_values);
			} else { # plain-jane
				$sth->execute;
			}
		}
		# catch the errors
		catch {
			if ($_ =~ /Deadlock/) { # retry after three seconds
				$cleared_deadlocks = 0;
				sleep(3);
			} else { # regular error: log-out and die
				$self->log_errors(qq{Error executing $sql: }.$sth->errstr());
				$cleared_deadlocks = 1;
			}
		}
	}

	# i like pretty formatting/spacing for my code, maybe too much
	$sql =~ s/^\s+//g;

	# if SELECT, grab all the results into a arrayref of arrayrefs
	if ($sql =~ /^select|^show|^desc/i) {
		# snatch it
		$results = $sth->fetchall_arrayref;
		# here's how you use this:
		# while (($one,$two) = @{shift(@$array)}) { ... }

		# clean up
		$sth->finish;

		# send out results
		return $results;

	# if it is an insert, let's stash the last-insert ID, mainly for omniclass's save()
	} elsif ($sql =~ /^(insert|replace)/i) {
		$self->{last_insert_id} = $sth->{'mysql_insertid'};
	}

	# any finally, clean (will only still be here for insert, replace, or update statements)
	$sth->finish;
}

# encrypt_string: a method to encrypt plain text and return a base64 version of that encrypted value
sub encrypt_string {
	my $self = shift;

	# the arguments are the string to encrypt and the 'salt' value
	my ($plain_text_string,$salt_phrase) = @_;

	# return blank if no plain text
	return if !$plain_text_string;

	# if no salt is sent, use $ENV{SALT_PHRASE}, failing that, default to the truth
	$salt_phrase ||= $ENV{SALT_PHRASE};
	$salt_phrase ||= 'AllHailGinger'; # please set up a $salt_phrase

	# make sure we are connected to the DB
	$self->connect_to_database();

	# queries are a little different for MariaDB (no IV, only 128 bits)
	my ($encoded_and_encrypted_string);
	if ($self->{is_mariadb}) {
		($encoded_and_encrypted_string) = $self->quick_select(qq{
			select TO_BASE64( AES_ENCRYPT(?,SHA2(?,512)) )
		},[ $plain_text_string, $salt_phrase ]);

	# eric hearts mysql
	} else {
		($encoded_and_encrypted_string) = $self->quick_select(qq{
			select TO_BASE64( AES_ENCRYPT(?,SHA2(?,512),?) )
		},[ $plain_text_string, $salt_phrase, $self->{iv} ]);
	}

	# ship it out
	return $encoded_and_encrypted_string;
}

# grab_column_list: get a comma list of column names for a table
sub grab_column_list {
	my $self = shift;
	# grab args
	my ($database,$table,$skip_ot_keys) = @_;
	# database name, table name, and optional 1 indicating to leave off the 'concat(code,'_',server_id),parent' bit

	my ($cols) = $self->quick_select(qq{
		select group_concat(column_name) from information_schema.columns
		where table_schema=? and table_name=? and column_key !='PRI'
		and column_name !='parent'
	},[$database, $table]);

	# how to return
	if ($skip_ot_keys) { # just columns
		return $cols;
	} else { # include OT fun stuff
		return "concat(code,'_',server_id),parent,".$cols;
	}
}

# hash_cache: utility to save or retrieve deep data structures for future use (next run?)
# put it here instead of utility_belt since it relies on the database handle
# see usage notes below
sub hash_cache {
	my $self = shift;
	my (%args) = @_;

	my ($now, $target_file, $serialized_hash, $ready_hash, $cloned_hash, @values, $extra_field, $field_list, $q_marks);

	# $args{object_name} is required; it's the unique name of the object being saved
	if (!$args{object_name}) {
		$self->log_errors('ERROR: Object Name is required.');
	}

	# where to we want to keep (or retrieve from) this item
	$args{location} ||= 'db'; # default is to the database
	if ($args{location} eq 'db') { # default to db
		$args{db_table} ||= 'otstatedata.hash_cache'; # default table; they can send another
		# see below for what this table should have
		$args{max_lifetime} ||= 86400; # seconds to keep this around; used in cleaning scripts, default 1 day
	} elsif ($args{location} eq 'file') {
		# if they did not send a directory, default to our special place
		$args{directory} ||= $ENV{OTHOME}.'/hash_cache/';

		$target_file = $args{directory}.$args{object_name}.'.othash';
	}

	if ($args{task} eq 'retrieve') {

		if ($args{location} eq 'db') { # retrieve the hashref from the DB
			($serialized_hash) = $self->quick_select(qq{
				select cached_hash from $args{db_table}
				where object_name=? and
				(expiration_time > unix_timestamp() or expiration_time=0)
			},[$args{object_name}]);
			# we made sure not to use an expired version

		} elsif (-e "$target_file") { # retrieve from the file
			$serialized_hash = read_file($target_file);
			# files are better for never-ending hashes, as they do not check the expiration time
		}

		# if it was found, thaw it out and return
		if ($serialized_hash) {
			$ready_hash = thaw($serialized_hash);
		}

		# send it out; may be blank if it expired and was removed by a script
		# will expect code on the other end of this to know what to do
		return $ready_hash;

	# if they sent us a hashref or arrayref, let's store it
	} elsif (ref($args{hashref}) eq 'HASH' || ref($args{hashref}) eq 'ARRAY') {

		# make sure to resolve any nested memory references into real data
		# if your structure is complex, this will not be lightning fast
		$cloned_hash = dclone($args{hashref});

		# serialize it
		$serialized_hash = nfreeze($cloned_hash);

		# and save it
		if ($args{location} eq 'db') { # into the database

			# did they pass additional extra_fields in $args{extra_fields}?
			@values = ($args{object_name}, $serialized_hash);
			foreach $extra_field (keys %{$args{extra_fields}}) {
				next if !$args{extra_fields}{$extra_field};
				$field_list .= ','.$extra_field;
				$q_marks .= ',?';
				push(@values,$args{extra_fields}{$extra_field});
			}

			$self->do_sql(qq{
				replace into $args{db_table} (object_name,cached_hash,expiration_time $field_list)
				values (?,?,unix_timestamp()+$args{max_lifetime} $q_marks)
			},\@values);

			# if they want it to live forever, set expiration_time=0
			if ($args{never_expire}) {
				$self->do_sql(qq{
					update $args{db_table} set expiration_time=0 where object_name=?
				}, [$args{object_name}] );
			}

			# some house-keeping: no more than every 100 seconds, clear the expired records
			$now = time();
			if ($now =~ /50$/) {
				$self->do_sql(qq{
					delete from $args{db_table} where expiration_time != 0 and expiration_time < unix_timestamp()
				});
			}

		} elsif ($target_file) { # into a file
			write_file($target_file,$serialized_hash);
		}

		# all done
	}
}

# list_select: easily execute sql SELECTs that will return a simple array; returns an arrayref
sub list_select {
	my $self = shift;

	# declare vars
	my ($sql, $sth, @data, @sendBack,$bind_values);

	# grab args
	($sql,$bind_values) = @_;
	# sql statement to execute and if placeholders used, arrayref of values

	# make sure we are connected to the DB
	$self->connect_to_database();

	# we should never have this error condition, but just in case
	if (!$self->{dbh}) {
		$self->log_errors(qq{Missing DB Connection for $sql.});
	}

	# prep & execute the sql
	$sth = $self->{dbh}->prepare($sql);
	# use $@values if has placeholders
	if ($bind_values) {
		$sth->execute(@$bind_values) or $self->log_errors(qq{Error executing $sql: }.$self->{dbh}->errstr);
	} else { # place-jane
		$sth->execute or $self->log_errors(qq{Error executing $sql: }.$self->{dbh}->errstr);
	}
	# grab the data & toss it into an array
	while ((@data)=$sth->fetchrow_array) {
		push(@sendBack,$data[0]); # take left most one, so it's 100%, for-sure one-dimensional (no funny business)
	}

	# send back the arrayref
	return \@sendBack;
}

# subroutine to use the utility_belt's logging and return functions to capture errors and return a proper message
# doing this route because often this class won't have the utility belt because it is called before the belt is set up
sub log_errors {
	my $self = shift;

	my ($error_message) = @_;

	# default message in cause of blank
	$error_message ||= 'Database error.';

	# do we have utility belt?  if built within pack_luggage(), we will
	if (not $self->{belt}->{all_hail}) { # set it up
		$self->{belt} = omnitool::common::utility_belt->new();
	}

	# log and then send the message
    $self->{belt}->logger($error_message,'database_errors');
    $self->{belt}->mr_zebra($error_message,1);
}

# quick_select: easily execute sql SELECTs that will return one row; returns live array
sub quick_select {
	my $self = shift;

	# declare vars
	my ($sql, @data, $sth, $bind_values);

	# grab args
	($sql,$bind_values) = @_;
	# sql statement to execute and if placeholders used, arrayref of values

	# make sure we are connected to the DB
	$self->connect_to_database();

	# we should never have this error condition, but just in case
	if (!$self->{dbh}) {
		$self->log_errors(qq{Missing DB Connection for $sql.});
	}

	# prep & execute the sql
	$sth = $self->{dbh}->prepare($sql);

	# use $@values if has placeholders
	if ($$bind_values[0]) {
		$sth->execute(@$bind_values) or $self->log_errors(qq{Error executing $sql (@$bind_values): }.$self->{dbh}->errstr);
	} else { # plain-jane
		$sth->execute or $self->log_errors(qq{Error executing $sql: }.$self->{dbh}->errstr);
	}

	# grab the data
	(@data) = $sth->fetchrow_array;

	# return a real, live array, not a memory reference for once...just easier this way,
	# since much of the time, you are just sending a single piece of data
	return (@data);
}

# sql_hash: take an sql command and return a hash of results; my absolute personal favorite
sub sql_hash {
	my $self = shift;

	# declare vars
	my (%args, $c, $cnum, $columns, $key, $kill, $num, $rest, $sql, $sth, %our_hash, @cols, @data, @keys, $names);

	# grab args -- see below, but %args can include an arrayref for 'names' for the subhash keys and
	# an arrayref for 'bind_values' for the placeholders
	($sql,%args) = @_;
	# the command to run and optional: list of names to key the data by...if blank, i'll use @cols from the sql

	if (!$args{names}[0]) { # determine the column names and make them an array
		($columns,$rest) = split /\sfrom\s/i, $sql;
		$columns =~ s/count\(\*\)\ as\ //; # allow for 'count(*) as NAME' columns
		$columns =~ s/select|[^0-9a-z\_\,]//gi; # take out "SELECT" and spaces
		$columns =~ s/\,\_\,/_/; # account for a lot of this: concat(code,'_',server_id)

		(@{$args{names}}) = split /\,/, $columns;
		$kill = shift (@{$args{names}}); # kill the first one, as that one will be our key
	}

	# make sure we are connected to the DB
	$self->connect_to_database();

	# this is easy: run the command, and build a hash keyed by the first column, with the column names as sub-keys
	# note that this works best if there are at least two columns listed
	$num = 0;
	if (!$self->{dbh}) {
		$self->log_errors(qq{Missing DB Connection for $sql.});
	}
	$sth = $self->{dbh}->prepare($sql);

	# use $@values if has placeholders
	if ($args{bind_values}[0]) {
		$sth->execute(@{$args{bind_values}}) or $self->log_errors(qq{Error executing $sql: }.$self->{dbh}->errstr);
	} else {
		$sth->execute or $self->log_errors(qq{Error executing $sql: }.$self->{dbh}->errstr);
	}

	while(($key,@data)=$sth->fetchrow_array) {
		$cnum = 0;
		foreach $c (@{$args{names}}) {
			$our_hash{$key}{$c} = $data[$cnum];
			$cnum++;
		}
		$keys[$num] = $key;
		$num++;
	}

	# return a reference to the hash along with the ordered set of keys
	return (\%our_hash, \@keys);
}

# be nice and disconnect from the database when done
# http://search.cpan.org/~dwheeler/DBIx-Connector-0.53/lib/DBIx/Connector.pm
sub DESTROY {
	my $self = shift;
	if ($self->{dbh} && blessed($self->{dbh}) =~ /DBI/) {
		$self->{dbh}->disconnect;
	}
}

# all done
1;

__END__

=head1 omnitool::common::db

This is our object for interacting with the database server, which will be MySQL 5.7 or Maria 10.3+.

Upon object creation, connects to either a specified database server (and database) or the default,
which is set within the code below.  new() also sets the 'server_id' attribute, which helps the OmniClass
routines tag all new data with the code of its original database server.  This (hopefully) enables
circular replication.

=head2 new()

Constructor for the object.

	$db_object = omnitool::common::db($hostname,$connect_to_database,$outside_server);

First arg is optional and is the hostname or IP of the MySQL or MariaDB server to which
we shall connect.  Defaults to 127.0.0.1.

Second arg is optional and the name of the database to be the primary DB for this
connection.  Defaults to 'omnitool.'

Third arg is optional and tells us that the target server is not part of this OmniTool system.
Will prevent us from trying to find the server_id.  Please be careful; should use for SELECTs
only if you can help it.

With no args, will just connect to 'omnitool' on 127.0.0.1.

=head2 change_database()

Changes the current working database.  This allows you to query tables without prepending their
DB name (i.e no 'db_name.table_name'), and it is most useful for allowing multiple OmniTool Admin
instances without crazy gymnastics in the omnitool::common:: modules.

Usage:  $db->change_database('new_db_name');

=head2 do_sql()

Highly-flexible way to execute a SQL statement of any kind.

Args are the SQL statement itself and optionally (highly-encouraged), an arrayref
of values for placeholders.

If it is a SELECT statement, returns a reference to an array of arrays of results.

	$results = $db->do_sql(
		'select code,name from finances.properties where name=?',
		['123 Any Street']
	);
	while (($code,$name) = @{shift(@$results)}) {
		print "$code == $name\n";
	}

It's maybe worth noting that do_sql() is the only place to do non-SELECT statements.

Use placeholders!! This is an honor-system, but absolutely best-practice to use that
@$bind_values arrayref argument!

=head2 grab_column_list()

Returns a list of the column names for a table, making for easier 'grab-all' SELECTs
Args are the name of the database, the name of the table, and optionally a '1' to
tell it to skip prepending the standard omnitool bits: "concat(code,'_',server_id),parent"

=head2 list_select()

Accepts a SELECT statement (and optional arrayref of values for placeholders) and returns
a arrayref to the resulting list. Let's be clear that this SELECT statement should select
only one column, as this is just a simple array.  This is useful for selecting the primary
keys for a datatype.

	$list = $db->list_sql(
		'select code from finances.properties where client=? and status=?',
		[23,'Active']
	);
	foreach $l (@$list) { ... }

Again, use placeholders!! This is an honor-system, but best-practice to use that @$bind_values
arrayref argument!

=head2 comma_list_select()

Same as list_select(), but results a 'commified' version in a basic string,
e.g. '1,2,3,4,5'; useful for grabing lists of primary keys for IN SELECTs.

Ex: $comma_list = $db->comma_list_select('select name from finances.tenants where lease_type=?',['Month-to-Month']);

Don't neglect the placeholders ;)  Honor systems require honor.

=head2 quick_select()

Accepts a SELECT statement (and optional arrayref of values for placeholders) and returns a live
array of results.  This is designed to pull a single row of results, so it is a horizantial array
versus a vertical one, if that makes any sense.  Since we might often be returning just a single
value, I felt it made more sense to just return live values (and not an arrayref).

	($name,$phone_number) = $db->quick_select(
		'select name,phone_number from finances.tenants where code=?',
		[42]
	);

Placeholders please ;)

=head2 sql_hash()

My personal favorite ;> Accepts a SELECT statement like this:

	select id,name,age from people.folks order by age

And turns it into a data structure like this:

	$people = {
		'3' => {
			'name' => 'Lorelei',
			'age' => '5',
		},
		'1' => {
			'name' => 'Eric',
			'age' => '40',
		},
		'2' => {
			'name' => 'Melanie',
			'age' => '42',
		},
	};

Also returns our hash keys for ordering:

	$pkeys = [3,1,2];

Usage:

	($results_hash,$results_keys) = $db->sql_hash(qq{
		select code,name,status,concat(phone_one,' / 'email_address)
		from property_management.tenants where status=? and type=?
	},(
		'names' => ['name','status','contact_info'],
		'bind_values' => ['Pending','Long-Term'],
	));

The first arg is required, it's a SQL/SELECT statement.  The second argument is
an arrayref containing the 'names' arrayref of the names you'd like to use for
the sub-hashes, and a 'bind_values' arrayref for the values to use in the placeholders.
Both of these are optional, but PLEASE USE THE PLACEHOLDERS!

=head2 Regarding Placeholders

Notes on using placeholders with Perl/DBI:  https://metacpan.org/pod/DBI#Placeholders-and-Bind-Values

We need to use these when passing any user-provided values to a SQL statement, and that includes
values derived from the request, such as hostname, username, password, client IP, etc. These folks
are smart enough to try SQL injection in many ways.

However, I am making placeholders somewhat optional, because I believe that (a) you are probably
pretty smart with good judgement and (b) I don't think you have to use them if the match-value is
derived from logic in your code or from a previous SQL statement.  So for example, if you grab
the Application Instance ID based on the hostname, you use a placeholder for that query, but then
the Application Instance ID should be safe for plain use in future SQL statements.  Perhaps I should
be more paranoid.

=head2 encrypt_string() and decrypt_string()

These methods work together to provide a rudimentary two-way encryption function for you to garble up
text.  This is meant to help OmniTool be 'more secure,' not 'perfectly secure.'  It uses MySQL's built-in
AES_ENCRYPT() and AES_DECRYPT() functions, as well as TO_BASE64() / FROM_BASE64().

Please set your own values for $ENV{SALT_PHRASE} and $ENV{INIT_VECTOR} in start_omnitool.bash and bash_aliases
to customize the encryption for your system.  Otherwise, your encryption is completely insecure!  Make those
values the same in both files. Please don't change these without first decrypting your encrypted values!

Usage:

	$encoded_encrypted_string = $db->encrypt_string('Some text string',$salt_phrase);

	Returns a Base64-encoded string representing the AEAES_ENCRYPT() value for the plain-text string,
	with the $salt_phrase key/password.  Save that $salt_phrase if you ever want to get this back.

	$plain_text_string = $db->decrypt_string($encoded_encrypted_string,$salt_phrase);

	Retrieves the plain text string stored in the Base64-encoded/encrypted binary in $encoded_encrypted_string;
	$salt_phrase needs to be the same phrase / value used to encrypt the value.

=head2 hash_cache()

Store and retrieve complex data structures (hashes), either in a DB table or a file
I keep this here instead of utility_belt.pm because of the dependence on the DB handle.

To store a hash:

	$db->hash_cache(
		'object_name' => $unique_file_name, # required: unique name for this hash, i.e. 'echernof_cases_10-15-17' or similar
		'task' => 'store', # not really needed
		'hashref' => \%hash, # or just $hash-reference; required for this operation
		'location' => 'db' or 'file', # indicates database table or filepath; default is 'db'
		'directory' => $directory_location, # target directory for serialized hash files; optional; defaults to $ENV{OTHOME}/hash_cache/
		'db_table' => 'dbname.table_name', # target database/table for storing serialized hashes; optional; defaults to otstatedata.hash_cache
		'max_lifetime' => 1000, # number of seconds that the hash will be good.  optional and defaults to 86400 / one day
								# this last bit on works when location is 'db' and depends on your code to enforce.
		'extra_fields' => {		# optional hash if you have extra fields in your database table and want to update those
			'field_name' => 'field_value'
		},
		'never_expire' => 1, # if filled, will set expiration_time=0 when storing in the database, so that items never expire
	);

	Note that the hash-caching database tables should be build like so:

	create table otstatedata.hash_cache (
		object_name varchar(250) not null,
		expiration_time int(15) unsigned not null default 0,
		cached_hash longtext,
		primary key (object_name)
	);

** Note: If the current epoch ends with '50', when you attempt to load a hash, it will also remove any expired caches
from the table.  Unless you have a screamingly-busy server, this will likely only happen a few times per day.

To retrieve a hash:

	$retrieved_hashref = $db->hash_cache(
		'object_name' => $unique_file_name, # required: unique name for this hash, i.e. 'echernof_cases_10-15-17' or similar
		'task' => 'retrieve', # required for this
		'location' => 'db' or 'file', # indicates database table or filepath; default is 'db'
		'directory' => $directory_location, # target directory for serialized hash files; optional; defaults to $ENV{OTHOME}/hash_cache/
		'db_table' => 'dbname.table_name', # target database/table for storing serialized hashes; optional; defaults to otstatedata.hash_cache
	);

Because of the defaults, I would expect typical usage to be more like this:

	$db->hash_cache(
		'object_name' => 'todays_test_hash_name',
		'hashref' => $hash_reference,
	);

	$retrieved_hashref = $db->hash_cache(
		'object_name' => 'todays_test_hash_name',
	);
