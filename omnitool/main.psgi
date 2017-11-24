#!/export/webapps/perl/bin/perl
# This is the PSGI script which runs OmniTool as a Plack application via Starlet (or others)
# Please see $OTHOME/configs/start_omnitool.sh on how to start up the app,
# including environmental variables.
# Each worker/thread started by Starlet (or other) will run a copy of this script

# Please see the Perldoc notes below for more info about what this is.

# load our plack modules
use Plack::Request;		# access the incoming request info (like $q = new CGI;)
use Plack::Response;	# handles the outgoing respose
use Plack::Builder;		# enable use of middleware
use Plack::Middleware::DBIx::DisconnectAll;		# protect DB connections
use File::RotateLogs;	# log rotation
# probably more middleware to come

# load the ot modules we need
use omnitool::dispatcher;				# for dispatching the requests to the right methods
use omnitool::common::db;				# DB connections; try to keep between requests
use omnitool::common::utility_belt;		# Also try to keep the utility_belt object between requests

# Here is the PSGI app itself; Plack needs a code reference, so work it like so:
my $app = sub {
	# grab the incoming request
	my $request = 'Plack::Request'->new(shift);
	# set up the response object
	my $response = 'Plack::Response'->new(200);

	# wrap our calls into omnitool with eval{} so that our mr_zebra() content
	# delivery method can use die() safely break execution
	eval {
		# setup the dispatcher, which means loading this person's %$luggage
		my $omnitool = omnitool::dispatcher->new(
			'request' => $request,
			'response' => $response,
		);

		# presuming pack_luggage() didn't send them to the login_system form,
		# dispatch them to to some actual code under /ui and /tools
		$omnitool->dispatch();
	};

	# catch the 'super' fatals, which is when the code breaks (usually syntax-error) before logging
	if ($@ && $@ !~ /Execution stopped./) {
		my $belt = omnitool::common::utility_belt->new(); # need this for logging
		my $error_id = $belt->logger($@,'superfatals');
		# make sure it goes out to the client via mr_zebra()
		$belt->{request} = $request; # need these for mr_zebra to work
		$belt->{response} = $response;
		# send to client
		if ($ENV{OT_DEVELOPER} && $@ !~ /sha2/) { # show them the error - so long as it's not a password query
			$belt->mr_zebra('Execution failed; '.$@."\n");
		} else { # hide from the regular users
			$belt->mr_zebra('Execution failed; error ID: '.$error_id."\n");
		}
	}

	# vague server name.
	$response->header('Server' => 'Web Application');

	# finish up with our response
	$response->finalize;
};

# rotate the logs every day
my $rotatelogs = File::RotateLogs->new(
	logfile => $ENV{OTHOME}.'/log/ot_access_log.%Y%m%d%H%M',
	linkname => $ENV{OTHOME}.'/log/ot_access_log',
	rotationtime => 86400,
	maxage => 86400,
);

# use Plack::Middleware::ReverseProxy to make sure the remote_addr is actually the client's IP address
builder {
	enable "DBIx::DisconnectAll";
	enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
	"Plack::Middleware::ReverseProxy";
	enable 'Plack::Middleware::AccessLog::Timed',
		format => "%P, %h  %t  %V  %r  %b  %D",
		# the worker PID, the Remote Client IP, Local Time of Service, HTTP Type, URI, HTTP Ver, Response Length, Time to Serve Response
		# separated by double spaces
		logger => sub { $rotatelogs->print(@_) };
	$app;
};

# plack seems not to like 'exit' commands in these scripts

__END__

=head1 main.psgi

This is the Plack/PSGI script which runs OmniTool as a Plack application. It is meant to be run
via Starlet using $OTHOME/configs/start_omnitool.bash, which will start up the Plack service
on port 6000.

You will need to configure an Apache or Nginx server to publish this Plack service to the world
via HTTPS.  An example Apache configuration is at $OTHOME/configs/plack_apache.conf.  All
static files must be served via a proper Web server, and OmniTool is meant to be delivered
on HTTPS only.

This is a fairly minimalist PSGI script.  The omnitool::dispatcher module is used to do
the real work of routing (traffic direction) and execution.

This script does try and catch errors and not allow hard failures.  If we are in developer
mode ($ENV{OT_DEVELOPER} is set.), then the error will be sent to the client as well as
logged; otherwise, it is just logged to the 'superfatals' logs under $OTHOME/logs.

For more information on what OmniTool is, please run 'perldoc omnitool'
