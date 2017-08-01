package omnitool::dispatcher;
# this is the point of entry module which receives the requests and determines
# which code to execute. see more extensive notes below
# will be called via main.psgi

# set version...feels like 1,000.0
$omnitool::dispatcher::VERSION = '6.0';

# load our brothers and sisters
use omnitool::common::ui;				# for presenting UI skeleton / elements
use omnitool::common::db;				# DB connections; try to keep between requests
use omnitool::common::utility_belt;		# Also try to keep the utility_belt object between requests
use omnitool::common::luggage;			# for session, utility-belt packaging

# time to really grow up
use strict;

# create this object, which involves setting up our %$luggage hashref
# if coming from main.psgi, we will receive the utility_belt.pm and db.pm
# objects via our arguments; otherwise, pack_luggage() will create those
sub new {
	my $class = shift;
	my (%args) = @_;

	# step one...so many steps...: grab a utility belt object for our common tools
	# if they didn't send one (i.e. within a script), make one
	if (!$args{belt} || (not $args{belt}->{all_hail}) )  {
		$args{belt} = omnitool::common::utility_belt->new();
	}

	# step two: if the DB connection was not provided, connect here
	if (!$args{db} || (not $args{db}->{dbh}->ping)) {
		$args{db} = omnitool::common::db->new();
	} 	

	# let's get ready for our trip.  Please see notes within omnitool::common::luggage for all that this does
	# luggage.pm and sessions.pm conspire to keep this tied to just this instance based on the HTTP_HOST
	# also, this will trigger our authentication scheme, login_system.pm, if their cookie is not in place
	my $self = bless {
		'luggage' => pack_luggage(
			'request' => $args{request},
			'response' => $args{response},
			'belt' => $args{belt},
			'db' => $args{db},		
		),
	}, $class;
	
	return $self;	
}

# the main event: dispatch the requests to the proper routines
sub dispatch {
	my ($luggage, $ui, $our_output, @uri_parts, $base_path, $blank, $method_name, $uri_path_base, $tool_obj, $run_method, $time_left);
	my $self = shift;
	
	# if we are under a maintenance, we will want to report that to the user/browser
	# in that case, the OT_MAINTENANCE env var will be set in our startup script
	if ($ENV{OT_MAINTENANCE}) {
		$time_left = lcfirst( $self->{luggage}{belt}->figure_delay_time( $ENV{OT_MAINTENANCE} ) );
		$our_output = 'The system is currently undergoing maintenance.  We expect this to be completed '.$time_left.'.';

	# otherwise, we shall act based on the uri, explained more in detail below
	# if it is very likely a call to ui.pm, then create the object here
	} elsif ($self->{luggage}{uri} eq '/index.html' || $self->{luggage}{uri} eq '/' || $self->{luggage}{uri} =~ /^\/ui/) {
		$ui = omnitool::common::ui->new(
			'luggage' => $self->{luggage},
		);
		
		# determine the method name for ui.pm
		
		# not the main, one of the secondaries
		if ($self->{luggage}{uri} =~ /^\/ui/) { 
			# the method name will be the part right after /ui/
			($method_name = $self->{luggage}{uri}) =~ s/\/ui\///;			
			# may have params which are not relevant
			$method_name =~ s/\?.*// if $method_name =~ /\?/; 
		
		# otherwise, it's definitely calling for the skeleton (/ or /index.html)
		} else {
			$method_name = 'skeleton_html';
		}
		
		# call the desired method here:
		$our_output = $ui->$method_name();
		
	# if it's a tool module, we need our object_factory to figure out which class to 
	# call, as many tools will have their own classes/perl modules
	} elsif ($self->{luggage}{uri} =~ /^\/tool/) {
			
		# use the object_factory, instantiated in pack_luggage, to figure out which class we 
		# need and create an object; it will already have %$Luggage, including the uri
		$tool_obj = $self->{luggage}{object_factory}->tool_object();
			
		# our tool object will have a 'run_method' attribute, which is set to a 
		# default in it's new() or _init() methods and overriden by object_factory's
		# work with the uri
		# tool.pm includes a wrapper method, execute_method() to make 
		# sure the tools' display config gets saved properly after each run
		# and execute_method() will look inside $self->{run_method}
		$our_output = $tool_obj->execute_method();
		
	# if that uri starts with something else, there was some kind of mistake.  
	# your server config should prevent this, but things happen
	} else {
		$our_output = 'ERROR: Do not have a handler set for '.$self->{luggage}{uri}.'.';
	}
	
	# call on our postman object to deliver this
	$self->{luggage}{belt}->mr_zebra($our_output);
	
}

1;

__END__

=head1  omnitool::dispatcher 

This module acts as the primary traffic-director to route our incoming rquests to the proper 
method/subroutine for preparing the appropriate output.  It is ready to answer requests under
these base URI's:

	/index.html
	/ui
	/tools or /tool 
	
The '/tool' is there because I am prone to typo's, as you have propbably seen.  The proper 
base URI is '/tools'.

If the URI is /index.html (or /), then the skeleton HTML will be loaded for this application instance.
Please see the notes in omnitool::common::ui for more of an explanation on this HTML.  That skeleton
should have a JavaScript routine calling back for a JSON object with the navigation info, and that
will be called via /ui/build_navigation. 

If the URI starts with /tool, then we want to run some of the Tool.pm code.  At least 95%, probably
99% of our web requests will be for Tool.pm.  Many tools will just be run via the standard
omnitool::tool object, but many will also have their own module, which will be sub-class of
omnitool::tool.  For this reason, we need to use our object_factory class to figure out
which Tool.pm sub-class to use. 

The second part of the /tools URI path will identify which tool we are trying to load/use, and the reaminder 
of the URI will refer to the Tools's method we want to run.  If there is no third part to that URI path, 
the default method will be 'send_attributes.'  Please see notes in omnitool::tool to see how that class and its 
children need to work.

Any of the methods we can run from here should output *something.*  It could be HTML, plain text or
a reference to a Perl hash data structure which is meant to be converted into a JSON object before
shipping to the client.  We rely on the mr_zebra() method in omnitool::common::utility_belt
to figure out what type of output we have, then to send the proper HTTP header, ship out the content,
and report OK to the browser.

BONUS: If you are doing a maintenance window for the system, set the 'OT_MAINTENANCE' environmental
variable in the start_omnitool.bash script to a UNIX epoch when the maintenance should be done.
