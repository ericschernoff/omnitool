package omnitool::common::ot6_api_client;
# Class to allow an OT6 system to access another via API mode.
# Kind of ambitious on my part, believing there would be so many OT6 servers,
# but the motivation is to enable using another OT6 app as a file storage method.

# load our web client modules from CPAN; you may like WWW::Mechanize a lot better
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use IO::Socket::SSL qw();

# for translating results into a perl hash
use JSON;

# for being a good person
use strict;

# object constructor; required args are your api key, the omnitool server hostname,
# and the URI base path for the application
sub new {
	my $class = shift;

	# require all three args.  Better verification would probably be good
	my ($api_key, $hostname, $uri_path_base) = @_;
	if (!$api_key || !$hostname || !$uri_path_base) {
		die 'Cannot create a omnitool::sample_api_client object without an API key, a $hostname and a $uri_path_base'."\n";
	}

	# pack up the object
	my $self = bless {
		'json' => JSON->new->utf8,		# to translate JSON to Perl Hashes
		'ua' => LWP::UserAgent->new(	# our web client; ignoring SSL errors for now
			ssl_opts => {
				SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
				verify_hostname => 0,
			},
		),
		# the three arguments from above
		'hostname' => $hostname,
		'uri_path_base' => $uri_path_base,
		'api_key' => $api_key
	}, $class;

	# call the get_client_connection_id() to get the Client Connection ID from
	# /ui/get_instance_info on the server.  All OmniTool connections have a distinct ID to
	# cache tool options; stores into $self->{client_connection_id} for use in perform_requests()
	$self->get_client_connection_id();

	# send back the object handler
	return $self;
}

# the central method to communicate with the omnitool application
# call with a target URI (e.g. /tools/labmgr/staff/create/send_json_data) along with
# a reference to an array of key/value pairs for the POST params.
# Should return a JSON object for results; if in error, will return one line of text.
# BTW: send multi-options as comma-separated lists
sub perform_requests {
	my $self = shift;

	# retrieve our arguments; $uri is required
	my ($uri,$post_args_array) = @_;
	die "ERROR: Must send a URI to perform_requests()\n" if !$uri;

	# be sure to include the standard post args to our @$post_args_array;
	# these are all required for requests to work properly
	push(@$post_args_array,
		'uri_base' => $self->{uri_path_base},
		'api_key' => $self->{api_key},
		'client_connection_id' => $self->{client_connection_id}, # not required for /ui/get_instance_info, but all others
	);

	# send the request
	my $req = POST 'https://'.$self->{hostname}.$uri, $post_args_array;
	# retrieve the results
	my $results = $self->{ua}->request($req)->content;

	# die if returned error
	if ($results =~ /^ERROR/) {
		die $results."\n";

	# otherwise, convert the JSON to a data structure and return that
	} else {
		return $self->{json}->decode( $results );
	}
}

# simple call to get the Client Connection ID as part of new()
sub get_client_connection_id {
	my $self = shift;

	# fetch the instance info JSON
	my $instance_info = $self->perform_requests('/ui/get_instance_info',[]);

	# extract the part we want and store in the object
	$self->{client_connection_id} = $$instance_info{client_connection_id};
}

# all done
1;

__END__

=head1 omnitool::common::ot6_api_client

Class to allow an OT6 system to access another via API mode.

=head2 new()

Creates an instance of this class.  Required args are your api key, the omnitool server hostname,
and the URI base path for the application.

Usage:

	$ot6_client = omnitool::common::ot6_api_client->new($api_key, $hostname, $uri_path_base);


=head2 perform_requests()

The routine to interact with the remote OT6 server and receive results back.  For example, if you have
a product catalog on the remote server:

	my $part = 'gingers-love-080199';

	my $returned_data = $ot6_client->perform_requests(
		'/tools/store/price_lookup/send_json_data',
		[
			'form_submitted' => 1,
			'part_numbers' => $part,
		]
	);

	print "The price of $part is currently \$".$$returned_data{results}{$part}."\n";

=head2 More extensive tips on API mode:

The basic idea is that in API mode, you will want to access the Tools mainly via their 'send_json_uri' URI's,
as the other URI's are generally for facilitating the Web UI.  The only exception being if you have a
custom method added to your Tool.pm sub-class (i.e. /tools/ot_admin/app_instances/background_tasks/view_error_message)
I just distracted you with a one-off.  My apologies.  99.5% of the time, you want to foucs on the 'send_json_uri'
URI's.  ** Please note that ANY tool in this sytem can be accessed via the API programmatically.  This is what
the JavaScript is doing already.

The first step is to get an API key from the 'Manage API Keys' tool within the OmniTool Admin Web UI (for the Admin
Instance that is driving your target Application, i.e. https://your-ot.yoursystem.com/your_admin#/tools/user_api_keys .
These keys are tied to the username of the client user and the IP address of the server you wish to use as a client.
They will have expiration dates, 90 days from creation by default, and they can be renewed for 90 days at a time.

Regular users are only allowed to make API keys for themselves.  They will get the default 90-day expiration, and they
will be assigned a 50-character random alphanumeric string for their API key.  They are allowed to assign the client
IP address and set their keys as Active or Inactive.  Inactive keys are not usable, but I am guessing you guessed that.

Users with the 'OmniTool Admin' access role will be able to create, manage, and view API keys for all users and have
access to all fields of the API keys.  Please be careful.  Remember, being in the OmniTool Admin role for one Admin
instance doesn't mean you must have that for all Instances.

Armed with an API key, one could write a client such as the example in omnitool/static_files/subclass_templates/sample_api_client.pl
and hopefully better.  The 'omnitool::sample_api_client' package in that script does show the basic requirements and
does seem to work well. One key gotcha is the Client Connection ID; please be sure to read those comments.

You can point this client (or your own) towards any Tool's 'send_json_data' URI.  You'll send arguments via POST
and receive back JSON results.  I recommend using the target Tool manually within Chrome (or similiar), with Developer
Tools open, and studying the data sent via 'send_json_data' as you interact with the Tool.  Specifically, when
you load up a form, 'send_json_data' will include a 'form' structure describing precisely the inputs and options
required, within the 'fields' and 'hidden_fields' structures.  From that, you can easily devise a post response
back to that 'send_json_data' URI.  When submitting forms, be sure to pass a 'form_submitted' value.

When querying Searching Tools, the 'records' and 'records_keys' strctures will contain the matching data for
your search. The 'metainfo' structure contains info about those records, and probably the age/update-time bits
are most interesting.  Devising queries for the searches is not as straightforward as working with forms, so we have the
'show_display_options' standard method for you to see the values to send for your search.  You just configure
the search how you like via the Web UI, then you fetch the JSON object for your current display/search options:

https://your-ot.yoursystem.com/tools/user_api_keys/show_display_options?client_connection_id=username1467602633F28B05ADB1BF4A0897B1&uri_base=your_admin

Please be careful.  If you are hooking an API into your system to interact with OmniTool on behalf of others, best
practice is to have each of your users generate their own API key to use with your app.  Your friendly OmniTool Admin
should be able to help you to automate gnerating those keys.

If you are writing a program to interact with your OmniTool system, then you should create a user specifically for that
software in OmniTool Admin >> Manage OmniTool Users and assign it to a special Access Role which has only the
necessary access.
