package omnitool::common::luggage;

# please see pod documentation included below
# perldoc omnitool::common::luggage

$omnitool::common::luggage::VERSION = '6.4';

# load exporter module and export the subroutines
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( pack_luggage pack_extra_luggage change_user_session );

# load our brothers, where we build this fancy stuff;
use omnitool::common::datatype_hash;
use omnitool::common::db;
use omnitool::common::login_system;
use omnitool::common::object_factory;
use omnitool::common::session;
use omnitool::common::table_maker;
use omnitool::common::utility_belt;

# time to grow up
use strict;

# on to the main event:
sub pack_luggage {
	# declare vars and grab our data structure argument, which is explained above.
	my ($app_instance, $public_mode, $table_maker, $value, $database_existence, @vars,%args,$luggage,$new_val,$r,$v, $ai, $conn, $remote_ip, $login_system, @values, $otadmin_db, $omnitool_admin_databases, @uri_parts, $uri_base, $hostname_info_cache_bit, $found_hostname, $app_code_directory, $extra_luggage_package, $extra_luggage_subroutine);

	(%args) = @_;

	# start out: note my version
	$$luggage{omnitool_version} = '6.3';

	# make sure we have the OTHOME envvar; default to '/export/webapps', if it exists
	# otherwise, /opt/omnitool
	if (-d "/export/webapps") {
		$ENV{OTHOME} ||= '/export/webapps';
	} else {
		$ENV{OTHOME} ||= '/opt/omnitool';
	}

	# step one...so many steps...: grab a utility belt object for our common tools
	# if they didn't send one (i.e. within a script), make one
	if (!$args{belt} || (not $args{belt}->{all_hail}) )  {
		$args{belt} = omnitool::common::utility_belt->new();
	}
	$$luggage{belt} = $args{belt};

	# first, fail out if we don't give us a hostname
	if (!$args{hostname} && !$args{request}->env->{HTTP_HOST}) { # invalid hostname
		$$luggage{belt}->mr_zebra("ERROR: A hostname is required to run pack_luggage().",1);
	}

	# step two: grab a database object; if one was sent, use that;
	if ($args{db} && $args{db}->{dbh}->ping) {
		$$luggage{db} = $args{db};
	} else { # was not sent or had stopped working
		$$luggage{db} = omnitool::common::db->new();
	}

	# if we have the Plack request and response, pack them in the utility belt for mr_zebra
	$$luggage{belt}->{request} = $args{request} if $args{request};
	$$luggage{belt}->{response} = $args{response} if $args{response};

	# let that db object use our utility_belt for error logger
	$$luggage{db}->{belt} = $$luggage{belt};

	# step three: stash the host name & uri...can be passed as arguments or retrieved from the Plack environment
	# the arguments values take precendence for your convenience
	# this makes it easier to create sessions in scripts too...just don't change your hostnames
	if ($args{hostname}) { # sent via args
		$$luggage{hostname} = lc($args{hostname});
	} elsif ($args{request}) { # in PSGI world
		$$luggage{hostname} = lc($args{request}->env->{HTTP_HOST});
	}
	if ($args{uri}) { # sent via args
		$$luggage{uri} = $args{uri};
	} elsif ($args{request}) { # in PSGI world
		$$luggage{uri} = $args{request}->request_uri();

		# handy to have the whole url
		$$luggage{complete_url} = 'https://'.$args{request}->env->{HTTP_HOST}.$args{request}->request_uri();

	}
	# no double //'s at the front
	$$luggage{uri} =~ s/^\/*/\//;

	# step four, pack the PSGI environment into a simple hashref; will need add other
	# ways to pull in user-arguments for other venues later on
	if ($$luggage{belt}->{request}) { # would not have this outside of Plack/PSGI
		# create a hash of the CGI params they've sent
		@vars = $$luggage{belt}->{request}->parameters->keys;
		foreach $v (@vars) {
			# ony do it once! --> those multi values will get you
			next if $$luggage{params}{$v};

			# plack uses the hash::multivalue module, so multiple values can be sent via one param
			@values = $$luggage{belt}->{request}->parameters->get_all($v);
			if (scalar(@values) > 1 && $v ne 'client_connection_id') { # must be a multi-select or similiar: two ways to access
				# note that we left off 'client_connection_id' as we only want one of those, in case they got too excited in JS-land
				foreach $value (@values) { # via array, and I am paranoid to just reference, as we are resuing @values
					push(@{$$luggage{params}{multi}{$v}}, $value);
				}
				$$luggage{params}{$v} = join(',', @values);  # or comma-delimited list
				$$luggage{params}{$v} =~ s/^,//; # no leading commas
			} elsif ($values[0]) { # single value, make a simple key->value hash
				$$luggage{params}{$v} = $values[0];
			}
		}
	}

	# step five is to use the $$luggage{hostname} or $$luggage{params}{uri_base} value to figure out
	# which OmniTool Admin database are using, and then which Application Instance we are using from that DB

	# first see if they sent a 'uri_base' if they are on $ENV{PRIMARY_HOSTNAME}
	# it can be the first segment of the URI

	(@uri_parts) = split /\//, $$luggage{uri};

	if ($uri_parts[1] && $uri_parts[1] !~ /^(index.html|tool|ui)/) {
		$uri_base = $uri_parts[1];

		# we will have this bit in the initial page load, and we need the JS to
		# know about it for the building the queries back into the system
		$$luggage{uri_base} = $uri_base;

	# or a PSGI param
	} elsif ($$luggage{params}{uri_base}) {
		$uri_base = $$luggage{params}{uri_base};
	}

	# for constructing links
	$$luggage{link_uri} = 'https://'.$$luggage{hostname}.'/'.$uri_base;

	# if $uri_base is blank, make sure it's not matchable
	if (!$uri_base) {
		$uri_base = 'Not in Use';

		# for caching the ot admin database location below
		$hostname_info_cache_bit = $$luggage{hostname};

	# make sure the $$luggage{hostname} is un-matchable, so that it does not interfere with our $uri_base
	} else {
		$$luggage{hostname} = 'Not in Use';

		# for caching the ot admin database location below
		$hostname_info_cache_bit = $uri_base;
	}

	# now, let's try our (hopefully) high-performance cache table to look up the admin db / app instance
	($$luggage{omnitool_admin_database}, $$luggage{app_instance}, $found_hostname, $public_mode) = $$luggage{db}->quick_select(qq{
		select omnitool_admin_database, app_instance_id, hostname, public_mode
		from otstatedata.hostname_info_cache where hostname_or_uri=?
	},[$hostname_info_cache_bit]);

	# if it found a hostname, possibly for the $uri_base, use that hostname
	$$luggage{hostname} = $found_hostname if $found_hostname;

	# if that's not found, look inside each OmniTool Admin DB until we find it
	if (!$$luggage{omnitool_admin_database}) {
		$omnitool_admin_databases = $$luggage{db}->list_select(qq{
			select database_name from omnitool.instances where parent='1_1:1_1' and status='Active'
		});
		foreach $otadmin_db (@$omnitool_admin_databases) {
			# try the lookup
			($$luggage{app_instance}, $found_hostname, $public_mode) = $$luggage{db}->quick_select(
				qq{select concat(code,'_',server_id), hostname, public_mode from }.
				$otadmin_db.'.instances where hostname=? or uri_base_value=?',
				[$$luggage{hostname}, $uri_base]
			);

			# if it was found, remember the DB name and update otstatedata.hostname_info_cache
			# for next time and break loop
			if ($$luggage{app_instance}) {

				# use the hostname that we found
				$$luggage{hostname} = $found_hostname;

				# public mode defaults to 'No', as it is unsafe
				$public_mode ||= 'No';

				$$luggage{db}->do_sql(qq{
					replace into otstatedata.hostname_info_cache
					(hostname_or_uri, hostname, omnitool_admin_database, app_instance_id, public_mode) values (?,?,?,?,?)
				},[$hostname_info_cache_bit, $$luggage{hostname}, $otadmin_db, $$luggage{app_instance}, $public_mode]);

				$$luggage{omnitool_admin_database} = $otadmin_db;

				last;

			}
		}
	}

	# if we found a omnitool admin database, let's make our lives much easier by changing the DB handle to it
	$$luggage{db}->change_database($$luggage{omnitool_admin_database});

	# step six: do a kanipshin if we don't have the hostname or the app_instance
	if (!$$luggage{app_instance}) {

		# see if there is a public instance we can send them to
		($found_hostname) = $$luggage{db}->quick_select(qq{
			select hostname from otstatedata.hostname_info_cache
			where public_mode='Yes'
		});
		# found one and in web mode? then redirect
		if ($found_hostname && $$luggage{belt}->{response}) {
			$$luggage{belt}->{response}->redirect('https://'.$found_hostname);
		} else { # otherwise, error out
			$$luggage{belt}->mr_zebra("ERROR: No OmniTool Application found for $$luggage{complete_url}.",2);
		}
	}

	# if this is a public_mode='Yes' instance, then our username is 'public'
	# BE CAREFUL: only use this if you have a read-only application instance
	$args{username} = 'public' if $public_mode eq 'Yes';

	# step seven, figure out our username & session situation
	# if we are in a script but a username was not sent, have a kanipshin
	if (!$args{request} && !$args{username}) {
		$$luggage{belt}->mr_zebra("ERROR: No username sent to &pack_luggage() -- cannot continue.",1);

	# we will trust at if $args{username} is filled, we were called from trusted code
	} elsif ($args{username}) {
		$$luggage{username} = $args{username};
		# okay, grab our omnitool session
		$$luggage{session} = omnitool::common::session->new(
			'username' => $$luggage{username},
			'db' => $$luggage{db},
			'app_instance' => $$luggage{app_instance},
			'hostname' => $$luggage{hostname},
			'belt' => $$luggage{belt},
		); # see perldoc bits in session.pm to understand all that

		# see if they have a timezone name from a previous web authentication
		($$luggage{timezone_name}) = $$luggage{db}->quick_select(qq{
			select timezone_name from otstatedata.authenticated_users where username=?
			and timezone_name like '%/%' order by code desc limit 1
		},[ $$luggage{username} ]);

	# otherwise, use our web authentication system to force them to log in
	# note that if they submit that login form, we'll be flowing back to this spot a few times.
	} else {
		$login_system = omnitool::common::login_system->new($luggage);

		# if they sent an api key, try to use that
		if ($$luggage{params}{api_key}) {
			$login_system->api_key_athentication();

		# otherwise, use the standard web authentication system
		} else {
			# the web_authentication() method handles everything
			$login_system->web_authentication();

		}

		# a session will get created by either of those routines and saved into $$luggage{session}

		# make sure we have their username in place
		$$luggage{username} = $$luggage{session}{username};

	}

	# if we are using a $uri_base in the actual URI, revert the URI to index.html
	# We need to do this after the authentication step, to make sure the login form gets the
	# proper URI
	if ($uri_parts[1] eq $uri_base) {
		$$luggage{uri} = '/index.html';
	}

	# the 'timezone_name' key is loaded in via login_system::web_authentication()
	# and we should add it into the utility_belt object for easy access in time_to_date()
	if ($$luggage{timezone_name}) {
		$$luggage{belt}->{timezone_name} = $$luggage{timezone_name};
	}
	# similiar for the (possibly more important) timezone_name
	$$luggage{belt}->{timezone_name} = $$luggage{timezone_name};

	# step eight: if they have no tools for this instance, show them an error and quick
	# the caveat being if they passed 'force,' which should be used only for the table_maker.pm
	# call in omniclass->database_is_ready()
	if (!$$luggage{session}{tools_keys}[0] && !$args{force}) {
		# log it first, as we may need to send the 'force' argument for secondary pack_luggage calls
		$$luggage{belt}->logger("ERROR: Can't set up luggage for $$luggage{session}{app_instance_info}{inst_name} for $$luggage{username}",'luggage_errors');
		# send to browser
		$$luggage{belt}->mr_zebra("ERROR: There are no Tools available for $$luggage{session}{app_instance_info}{inst_name}.  Please send email to $$luggage{session}{app_instance_info}{contact_email} with questions.",2);
	}

	# step nine: grab a datatypes hashref for this application; again, this module handles the caching
	$$luggage{datatypes} = get_datatypes_hash($$luggage{hostname}, $$luggage{db});

	# step ten: keep the pertinent info on this instance handy
	$$luggage{database_name} = $$luggage{session}->{app_instance_info}{database_name};
	$$luggage{database_server} = $$luggage{session}->{app_instance_info}{database_server};
	$$luggage{database_hostname} = $$luggage{session}->{app_instance_info}{database_hostname};
	$$luggage{instance_name} = $$luggage{session}->{app_instance_info}{inst_name};
	# also stash the hostname of the otadmin instance for this app, for the automatic table_maker functions
	($$luggage{otadmin_instance_hostname}) = $$luggage{db}->quick_select(qq{
		select i.hostname from omnitool.instances i, omnitool.database_servers ds
		where i.database_name=? and ds.hostname=? and i.database_server_id=ds.code
	},[ $$luggage{omnitool_admin_database}, $$luggage{database_hostname} ] );

	# step eleven: it is possible that the DB server we connected to above is not the database server for this
	# application instance. We should be accessing the instance via the Apache host who has this
	# instances' datbaase server configured as it's default server, but it may not be, so check:
	if ($$luggage{db}->{server_id} ne $$luggage{database_server}) {
		$$luggage{db} = omnitool::common::db->new($$luggage{database_hostname});

		# and make sure it's on the right database
		$$luggage{db}->change_database($$luggage{omnitool_admin_database});

		# again, let that db object use our utility_belt for error logger
		$$luggage{db}->{belt} = $$luggage{belt};

	}
	# because of this, every OT database server must also have the omnitool_* and otstatedata DB's

	# step twelve: if the database does not exist, create it
	($database_existence) = $$luggage{db}->quick_select(
		'select count(*) from information_schema.schemata where schema_name=?',
		[$$luggage{database_name}]
	);
	if (!$database_existence) {
		# fire up our table maker object to do the heavy lifting
		$table_maker = omnitool::common::table_maker->new(
			# for some reason, we have to call it out explicitly
			'luggage' => omnitool::common::luggage::pack_luggage(
				'username' => $$luggage{username},
				'hostname' => $$luggage{otadmin_instance_hostname},
			),
			'app_instance' => $$luggage{app_instance},
		);
		# and make the DB with the baseline tables
		$table_maker->create_database();
		# omniclass will handle the rest
	}

	# step thirteen, i think, lost count: get an object_factory so that my screens can get
	# created as I need them; i sure hope that passing a reference to myself doesn't create
	# some crazy loop...main need to do this in main.pm
	$$luggage{object_factory} = omnitool::common::object_factory->new($luggage);

	# # step fourteen, use subroutine below to attempt to pack any app-specific luggage from
	# 'omnitool::applications::'.$app_code_directory.'::extra_luggage';
	&pack_extra_luggage($luggage); # re-usable because of change_user_session() below

	# OK, ready to go ;)
	return $luggage;

}

# re-usable subroutine to pack extra / app-specific luggage
sub pack_extra_luggage {
	my ($luggage) = @_;

	my ($app_code_directory, $extra_luggage_package, $extra_luggage_subroutine);

	# finally, we will allow your app to pack some 'extra luggage' to carry around via the
	# application.  This needs to be very important, as it will get loaded up every time.
	$app_code_directory = $$luggage{session}->{app_instance_info}{app_code_directory}; # sanity
	$extra_luggage_package = 'omnitool::applications::'.$app_code_directory.'::extra_luggage';
	# if it loads, run it's &pack_extra_luggage subroutine to extend %$luggage
	if (eval "require $extra_luggage_package") {
		$extra_luggage_subroutine = $extra_luggage_package.'::pack_extra_luggage';
		$extra_luggage_subroutine = \&$extra_luggage_subroutine;
		&$extra_luggage_subroutine($luggage);
	}

	# all done
}

# subroutine to change the user session, within the same instance
# used for handling background tasks on behalf of multiple users via a script
# requires a reference to an already-packed luggage and a username
sub change_user_session {
	my ($luggage,$username) = @_;

	# error-out if no luggage
	if (not $$luggage{belt}->{all_hail}) {

		return 'ERROR: Pre-packed %$luggage required for change_user_session()';

	# also cannot be used in plack-land; only safe for (trusted) scripts
	} elsif ($$luggage{belt}->{request}) {
		$$luggage{belt}->mr_zebra(qq{Error: change_user_session() is only allowed in scripts, not within Plack.},1);

	# and a username is required
	} elsif ($username !~ /[a-z]/i) {
		$$luggage{belt}->logger('Valid username required for change_user_session()','background_task_errors');
		return 'Valid username required for change_user_session()';
	}

	# after all that, safe to proceed

	# step 1: change the username
	$$luggage{username} = $username;

	# step 2: get the new session
	$$luggage{session} = omnitool::common::session->new(
		'username' => $username,
		'db' => $$luggage{db},
		'app_instance' => $$luggage{app_instance},
		'hostname' => $$luggage{hostname},
		'belt' => $$luggage{belt},
	); # see perldoc bits in session.pm to understand all that

	# step 3: get a fresh datatypes hash
	$$luggage{datatypes} = get_datatypes_hash($$luggage{hostname}, $$luggage{db});
	# due to the magic of perl memory references, any cross-linked DT info in
	# omniclass objects will have been updated if the datatype hash got refreshed

	# step 4: pack extra luggage for this application instance
	&pack_extra_luggage($luggage);

}

1;

__END__

=head1 omnitool::common::luggage

This module is meant to be a one-stop shop to gather up the objects and hashes
we will need to travel through our modules and subroutines through execution-land.
When you go on a trip, you need some luggage, right?  I decided against an object because
this is really just a collection of hash reference pointers.

The idea is that you just call this module rather than the four other modules
needed to gather up the commonly-used system data and objects.  Note that many of these
use some type of caching, so they are quite quick, even though they add up to a fair
amount of data.

You may add Application-specific routines to extend %$luggage with anything else which
would be useful on every access of your Application by creating an extra_luggage.pm
package at the top level of your Application's code directory (right next to custom_session.pm).
That extra_luggage.pm should contain a 'pack_extra_luggage' subroutine which receives the
$luggage hashref as a single arg.  It can call other routines from there, and just update
the contents of %$luggage without returning.  I am sorry for the 'extra_luggage' pun;
believe me, I almost said 'carry_on_luggage,' so it could have been worse.  Note that this
gets called last, after all of the items below have been added in.

When returned, %$luggage data-structure will contain:

	- $$luggage{db} --> a omnitool::common::db object, including a database connection
		with SQL-execute methods.

	- $$luggage{session} -> a session object, with all of their user profile and access
		information.

	- $$luggage{hostname} -> the hostname of the Application Instance we are working within.

	- $$luggage{omnitool_admin_database} -> the database name for the App Instance of
		OmniTool Admin which contains the configurations for the current Application.
		As all OT6 Applications may have multiple Instances, and the OT Admin function
		is just another OT6 Application, we allow you to have multiple Instances of OT
		Admin.  This makes it possible to very cleanly separate your Applications.
		YOU CAN NOT BUILD APPLICATIONS IN THE MAIN 'OmniTool.Org System Admin' INSTANCE,
		SO ONLY USE THAT TO SET UP SECONDARY ADMIN INSTANCES.

	- $$luggage{datatypes} -> a hashref containing the Datatype definitions for the current
		Application, used by omnitool::common::omniclass to build instances of Datatype.
		I wanted to use the word 'descriptive' here, but couldn't fit it in.

	- $$luggage{belt} -> a omnitool::common::utility_belt object, which is a handy
		set of utilities for general use that i tend to need everywhere.
			NOTE:  The Plack::Request and Plack::Response object handles
			go here as $$luggage{belt}->{request} and $$luggage{belt}->{response},
			as 'response' is very much used for mr_zebra()

	- $$luggage{object_factory} -> a omnitool::common::object_factory object, which makes
		it quite easy to generate OmniClass or Tool.pm objects from the proper subclasses;
		also extends OmniClass by allowing for 'trees' of OmniClass's based on complex data

	- $$luggage{params} -> the 'arguments' provided by the client.  Will generally be
		the PSGI params and env info provided by Plack.

	- $$luggage{uri} = The REQUEST_URI value from Plack

	- $$luggage{url} = The full URL, with hostname, from Plack

	- $$luggage{database_name} is the MySQL database for the current application instance, which
		is determined by the current hostname in Plack world or by the 'app_instance' argument;
		if you provide 'app_instance,' that takes precendence.  That current instance's ID
		is also saved in $$luggage{app_instance}

	- $$luggage{timezone_name} is the user's time zone name, from the tzdata database.
		It will be in the format of Country/City_Name with a default of 'Etc/UTC'.
		Read more about tzdata here:  https://en.wikipedia.org/wiki/Tz_database
		This is used by the various DateTime methods in utility_belt.pm to localize the user's
		time, sparing us from writing all kinds of Daylight Savings Time detection code.
		This value is figured out in using moment.js in omnitool_routines.js when it calls /ui/get_instance_info.
		That is the first JSON call and is required for the system to work properly (because of client_connection_id).
		When this param is sent, login_system::web_authentication() grabs the value.
		If you are using a lot of scripts that need this value to always be there, you may want to come up
		with an pack_extra_luggage() routine to do some sort of lookup based on the user's city.

	The usage is

		$luggage = pack_luggage(
			'username' => 'SOME-USER', 	# no caps; required
			'db' => $db_handle, 		# optional, will create one if not provided
			'hostname' => $hostname, 	# required: hostname of application intsance;
										# Plack sends this, but you can provide via %args
			'response' => $response, 	# the Plack::Response object, for building a response
										# to the client, very similiar to $r in mod_perl
										# will load this into the 'request' attribute of the utility_belt
										# object, as it is primarily used for mr_zebra() there
			'request' => $request, 		# the Plack::Request object from main.psgi;
										# equivalent to the CGI handler, $q = new CGI;
										# will load this into the 'request' attribute of the
										# utility_belt object; keep it with it's partner, 'response'
			'uri' => $uri, # also allows you to override the Plack value.  not sure how one would use this
		);

	'username' needs to be a value of the 'username' column from the omnitool(_*).users table.
		This is not optional, as I can't really grab a session and act without it.

	'db' is an already-existing omnitool::common::db object; I prefer that not be sent,
		but can see how it might be already available if you did some pre-execution in a script
		checking to see if it's worth even going this far.

Plesae note that Application Instances are meant to be tied to hostnames, but hey, wildcard SSL certs are
expensive, so I fixed it up to allow you to set up URI aliases to these Application Instances.
Please see the 'Cross-Hostname URI' field in the Create/Update an Instance web form.  For example:
If you want access the system via 'ginger.chernoff.org', and you have 'kitchen.chernoff.org' as the
hostname for your Application Instance and 'kitchen' as its 'Cross-Hostname URI', then you can
access this Application Instance both via https://kitchen.chernoff.org and https://ginger.chernoff.org/kitchen .
You would also not have to serve the 'kitchen.chernoff.org' virtual host if you just want the /kitchen
URI to work, though the system will refer to this hostname in some places.  ** Writing scripts to access
data works best when you pass in the 'hostname' arg above. **

=head2 change_user_session()

This utility routine allows your scripts (particularly scripts for running background tasks) to change
the current user.  Will not work inside Plack and requires an already-packed %$luggage plus some value
for a username (must have letters).  BE CAREFUL WITH THIS.

Usage:  &change_user_session($luggage,$username);
