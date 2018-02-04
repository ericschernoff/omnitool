package omnitool::tool;
# base class for creating Tool objects, which are the useful Tools provided by
# omnitool; kind of our reason for being here.  Please see involved notes below

# useful debug code
# use Benchmark ':hireswallclock';
# my ($t0, $t1, $td);
# $t0 = Benchmark->new;
# $t1 = Benchmark->new;
# $td = timediff($t1, $t0);
# $self->{luggage}{belt}->logger('XYZ occurred : '.timestr($td),'eric');

# first time doing it this way, but have allowed this many times before
$omnitool::tools::VERSION = '6.4.1';

use strict;

# I am going to use @ISA to allow me to keep my super-long methods in separate modules
use omnitool::tool::action_tool;
use omnitool::tool::bookmark_manager;
use omnitool::tool::center_stage;
use omnitool::tool::display_options_manager;
use omnitool::tool::html_sender;
use omnitool::tool::searcher;

# for getting the parent string from an altcode / data-id
# used in searcher and html_sender, and probably elsewhere, so make it part of our object
use omnitool::common::altcode_decoder;

# call them in
our @ISA = (
	'omnitool::tool::action_tool',
	'omnitool::tool::bookmark_manager',
	'omnitool::tool::center_stage',
	'omnitool::tool::display_options_manager',
	'omnitool::tool::html_sender',
	'omnitool::tool::searcher',
);

sub new {
	my $class = shift;

	# pack_luggage gathers up everything we need, so it is our primary argument to new()
	my ($tool_datacode,$luggage) = @_;

	# stop here if either $tool_datacode or $luggage not provided
	if (!$$luggage{belt}->{all_hail}) {
		die(qq{Can't start a Tool without my luggage.'});
	} elsif (!$tool_datacode) {
		$$luggage{belt}->mr_zebra('Cannot start a Tool without a $tool_datacode.',1);
	# make sure it's a valid Tool
	} elsif (!$$luggage{session}{tools}{$tool_datacode}{name}) {
		$$luggage{belt}->mr_zebra('Cannot start a Tool without a valid $tool_datacode.',1);
	}


	# We have three discrete forms of configurations to build / keep here:
	# attributes = the main parts of the Tool, kept in $$luggage{session}{tools}{$tool_datacode}
	# tool_configs = the options in all the subordinate options tables, kept within
	#				$$luggage{session}{tool_configs}{$tool_datacode} (see session.pm)
	# This first two will be loaded in from the user's session, so we just need to track:
	# display_options = the CGI/PSGI params they have sent previously to this Tool
	#					since loading/displaying a Tool requires multiple runs, all
	#					tools will save 'display_options' and we will instruct
	#					execute_method() when to clear those within the methods we run

	# put the database object / connection at the top for easy-reach
	my $self = bless {
		'db' => $$luggage{db},
		'tool_datacode' => $tool_datacode,
		'luggage' => $luggage,
		'belt' => $$luggage{belt}, # so that $self->{belt} can work
		'attributes' => $$luggage{session}{tools}{$tool_datacode}, # we shall ignore the 'child_tools' bit
		'tool_configs' => $$luggage{session}{tool_configs}{$tool_datacode},
		'tool_configs_keys' => $$luggage{session}{tool_configs_keys}{$tool_datacode},
		# convenience for building url's in the templates
		'my_base_uri' => '/tools/'.$$luggage{session}{tools}{$tool_datacode}{uri_path_base},
		'my_json_uri' => '/tools/'.$$luggage{session}{tools}{$tool_datacode}{uri_path_base}.'/send_json_data', # ?client_connection_id='.$$luggage{params}{client_connection_id},
		# default method to run if in base uri; almost always to send back Tool attributes
		'run_method' => 'send_attributes',
		# the 'client_connection_id' established by /ui/get_instance_info
		# and useful for making sure they get the same display_options each time
		# and we are going to require it to proceed
		'client_connection_id' => $$luggage{params}{client_connection_id},
		# with that in mind, here is the key we will use for saving the display options
		'display_options_key' => $$luggage{params}{client_connection_id}.'_'.$tool_datacode,
		# where those display options go via $db->hash_cache; setting here for easy overriding via _init()
		'display_options_cached' => $$luggage{database_name}.'.tools_display_options_cached',	# for short-term cached searches
		'display_options_saved' => $$luggage{database_name}.'.tools_display_options_saved',		# for bookmarked searches
		# unique ID for this app-instance & Tool
		'tool_and_instance' => $$luggage{app_instance}.'_'.$tool_datacode,
		# for getting the parent string from an altcode / data-id
		'altcode_decoder' => omnitool::common::altcode_decoder->new('luggage' => $luggage),
		# for our non-fatal logging utility
		 'log_type' => $$luggage{session}{tools}{$tool_datacode}{button_name},
	}, $class;

	# take the spaces from that 'log_type' key
	$self->{log_type} =~ s/\s//g;

	# you must send that 'client_connection_id' with every request
	if (!$self->{client_connection_id}) {
		$self->{belt}->mr_zebra("Cannot execute Tool without a proper 'client_connection_id'.",2);
	}

	# if we are setting up this Tool via object_factory, the 'altcode' atrribute
	# would be set based on either the 'altcode' param or URL piece (/tools/viewer/Ginger1999)

	# if calling from a screens's class module, all for an 'init' method to contribute to
	# the objects initalization; that will add or update our attributes in place
	if ($self->can('init')) {
		$self->init();
	}

	# only took me an hour to realize I forgot this line:
	return $self;
}

# wrapper method to execute $self->{run_method}, which was probably doctored by
# object_factory.pm and dispatcher.pm
sub execute_method {
	my $self = shift;

	my ($the_output, $run_method);

	# load-up, set-up, and re-save the display options
	$self->load_display_options();

	# run the desired method, if it exists
	$run_method = $self->{run_method};
	if ($self->can($run_method)) { # make sure it is available to us
		$the_output = $self->$run_method();
	} else { # otherwise, output an error
		$self->{luggage}{belt}->mr_zebra("Unable to execute $run_method Tool method.",1);
	}

	# handle the saved display options appropriately.  if they are to be deleted following
	# this execution, this 'run_method' will set $self->{clear_display_options}
	if ($self->{clear_display_options}) { # clear it out
		$self->clear_display_options_hash();
	# otherwise, re-save the display config for future executes, in case we modified those during the run_method
	} else {

		$self->save_display_options_hash($self->{luggage}{params}{saved_name});
	}

	# return our work product to the dispatcher
	return $the_output;
}

# method to send out attributes about this Tool, so our javascript partner knows how to act
sub send_attributes {
	my $self = shift;

	# this is pretty easy, just return the hashref of the Tools' main attributes
	my $tool_datacode = $self->{tool_datacode}; # sanity

	# we need that app-instance/tool unique ID to be in 'attributes' for easy transfer to the client
	$self->{attributes}{the_tool_id} = $self->{tool_and_instance};

	# ship it out
	return $self->{attributes};
}

# we need a method to just send the app-instance/tool unique ID to the client so it can
# maintain the associative array of tools / tools display data
sub send_tool_id {
	my $self = shift;

	# since the is the first method which is called when a tool is visited via the Web UI,
	# this is a great spot to log the loading of the tool
	$self->{luggage}{belt}->logger($self->{attributes}{name}.' accessed by '.$self->{luggage}{username},'tool_accesses');

	# send the tool ID
	return $self->{tool_and_instance};
}

# method for grabing an omniclass object for this datatype from the object_factory
sub get_omniclass_object {
	my $self = shift;

	# can pass all the same args which you can sent to object_factory->omniclass_object
	my (%args) = @_;

	# have to have a datatype
	if (!$args{dt}) {
		# maybe stashed it in our class; in this way, you can send no %args;
		if ($self->{attributes}{target_datatype}) {
			$args{dt} = $self->{attributes}{target_datatype};

		# can't do much here
		} else {
			$self->{luggage}{belt}->mr_zebra('ERROR: Tool->get_omniclass_object() cannot create an omniclass object without datatype ID.',1);
		}
	}

	# tell omniclass my tool_and_instance value for easily creating links in the virtual field hooks
	$args{tool_and_instance} = $self->{tool_and_instance};

	# allow for a hook for this operation
	if ($self->can('special_omniclass_object')) {  # generic enough name that it could possibly be used for Action Tools
		$self->{omniclass_object} = $self->special_omniclass_object(%args);
	# otherwise, use the standard way
	} else {
		$self->{omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(%args);
	}
	# object_factory likes to return the objectref, so we will honor that but stick
	# it in $self for easy transfer
}

# method to allow them to easily clear search options hash for this client connection
sub reset_search_options {
	my $self = shift;
	
	# use save_display_options_hash() from the display_options_manager
	$self->save_display_options_hash(1); # argument tells it to reset

	return 'OK';
}

# little method to send non-fatal log messages to a log file named for this tool's button name
sub logger {
	my $self = shift;

	# args are the message to log (required) and then an alternative log file type (optiona)
	my ($log_message,$log_type) = @_;

	# if no log file type, use the button name sans spaces
	$log_type ||= $self->{log_type};

	# use the utlity belt's logger
	my $error_id = $self->{luggage}{belt}->logger($log_message,$log_type);

	# send that error id back out
	return $error_id;
}

# empty destructor, to avoid AUTOLOAD being the desctructor
sub DESTROY {
	my $self = shift;
}

# put in a default/autoload method just in case.  execute_method() should negate
# the need for this, but you can never be too careful
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	# figure out the method they tried to call
	my $called =  $AUTOLOAD =~ s/.*:://r;

	# respond via mr_zebra, as we probably are talking to a client
	$self->{luggage}{belt}->mr_zebra("$called Tool method does not exist.",1);

}

1;

__END__

=head1 omnitool::tool

Let's start with a artistic idea:  Tool.pm is OmniClass's ambassador to the world.  The point
is to power the 'tools' that provide interfaces for our users to interact with the data
controlled by OmniClass.

OmniClass provides the CRUD and Search abilities for our data, and the OmniClass Packages should
provide the actions that the data can perform.  For example, if you have an OmniClass object which
represents an intelligent power supply that receives on/off commands via SNMP, then the code
to fire out those SNMP commands should be in your OmniClass Package, not in subclasses of Tool.pm.
A sub-class of Tool.pm provides the interface by which the users inject the commands into that
OmniClass module.  (FYI, "OmniClass Package" means a module set up as a sub-class of OmniClass.)

Based on all that, a well-designed Tool.pm sub-class will not have very much code, it is just
directing the actions of the OmniClass Package.  One should not build all kinds of logic and
actions into the Tool.pm sub-class...but I have succumbed to this temptation myself.  I use
the justification that if an activity will only occur in only one circumstance, then it is
forgivable to put that into a Tool.pm sub-class.  That makes it faster to load the OmniClass
Package, right?  This is a very thin sheet of ice, and often I find myself moving code from
the Tool.pm side over to the OmniClass Package.

Like OmniClass objects, Tool.pm configurations are managed via the web forms of the OmniTool
Admin Web UI.  The modules under omnitool::tool act to make these configurations working web
tools.  This document will not delve into how these system modules actually work, but rather
try to explain how to set up new Tools, including writing your Tool.pm sub-classes.

First some basics:

All Tools should have a 'Target Datatype' which will be the primary OmniClass datatype on
which the Tool operates.  Yes, your Tools may interact with a lot of data, but that core Target
Datatype should tie that data together, at least as a starting point to load the other data.
For example, if you have a simple address book Tool, your Target Datatype would probably
be 'Contact'; if your address book is more complex, your contacts might have 'Contact Method'
sub-data, and you would access those through the 'Contact' OmniClass object.  (Hint: You can use the
'Load Tree Objects' option when defining your Tools to auto-load all the descendent data with
their OmniClass Packages.)

=head2 Types of Tools

Tools have two basic types:

1. A 'Search' Tool is meant to run a query against the Target Datatype's database table and display
the results.  You define search menus and keyword searches to let the user filter the results, and
generally you will have subordinate Tools defined to allow the user to browse into these results,
to either act on those records or search below them.

2. An 'Action' Tool is meant to do something with or to some data, most often one record but possibly
more.  An 'update record' form is an Action Tool.  So is a 'Display Details' tool.  All forms / input
tools are Action Tools, but not all Action Tools must have a form or input.

Search Tools can only be displayed as 'Screens', meaning the entire main area of the web UI.
Action Tools can be displayed in Screens, Modals (pseudo pop-ups) or Messages, which are notifications
sometimes called 'pop-overs.'  If your Action Tool is complex, I recommend going with Screen
display; it's hard to go wrong there.  For simpler forms, Modals are good, and Messages are well-suited
to Action Tools which just commit an act and update you when they are done -- such as 'Flush User Sessions.'
Screen Tools that provide forms can be converted into Message Tools upon form submission, so you can display
the full form and just show a success message on proper submission.

Note that when using OmniTool as an API, outside of the UI, the display modes are irrelevant, as
it's all just JSON.

Action Tools can be configured to 'lock' data, which temporarily prevents other users from opening
other locking Action Tools against that same data.  The lock will be lifted once the user navigates
away from that Action Tool, or it will time out after your configured number of minutes.  For locking
to work well, you will need to make sure all data-modifying Action Tools have locking turned on.

For information on the specific configuration options for a Tool, please see the form for
creating a Tool.

=head2 About Tool URI's and omnitool_routines.js

OmniTool is a single-page application, SPA.  We use the location hash to tell which Tool
we are in, so that locations can be shared and bookmarked and the browser navigation
buttons (should) work.  We rely on a lot of JavaScript/jQuery goodness to work this out,
and all of that is in the 'omnitool_routines.js' file under omnitool::static_files::javascript.

To the user, the URI's should look like this:

	https://some.omnitool-server.org/#tools/path/to/tool/DATA_ALTCODE

	or

	https://primary_host.omnitool-server.org/my_app#tools/path/to/tool/DATA_ALTCODE

so that:

	https://your.omnitool-server.org/#/tools/calendar/show_event/BIRTHDAY_Ginger

	or

	https://primary_host.omnitool-server.org/my_app#/tools/calendar/show_event/BIRTHDAY_Ginger

Would likely show the details for Ginger's Birthday in a Calendar Tool. Please note
the 'tools' is in every URI, and all OmniTool requests are handled via https.

About the alternative URLs:  When you fill-in the 'Cross-Hostname URI' value for an
Instance, that base URI (just one segment) will act like an alias so that accessing
https://YOUR_SERVER_HOSTNAME/base_uri is the same as accessing https://$application_instance_hostname .

My preference is to access via Instance-specific hostnames, so the rest of the examples
below will show that method.  Please just imagine the alternative way ;)

This URI after 'tools' is constructed based on the 'URI Path' you specify for the Tool.
IMPORTANT: this is a one-word phrase, such as 'calendar' or 'update.'  As Tools are nested
below each other, the URI will be built.  In the example above, the 'Show Event'
tool is clearly a sub-tool of the 'Calendar'.

Please also note that the Altcode (human-friendly) code for the data should be at
the end of the URI.  If you want to instruct Tool.pm to execute a special method
(which must output JSON or text), make put this right before the Altcode.

Behind the scenes, the JavaScript will send several requests into your Tool in order
to fetch data to display or render the view.  These URI's include:

	https://your.omnitool-server.org/#/tools/calendar/show_event/send_tool_id

		Sends the identifier for the Tool to keep the JavaScript in order.

		As this is called by the JavaScript at every initial Tool loading, we have a
		little access-logging run here to fill in the 'tool_accesses-YYYY-MM-DD.log'
		log files.

	https://your.omnitool-server.org/#/tools/calendar/show_event/send_attributes

		Sends basic configuration info for the Tool, and tells the JavaScript
		how to behave / render the Tool.

	https://your.omnitool-server.org/#/tools/calendar/show_event/send_html

		Sends the HTML 'skeleton' for the Tool, which will include the quick-action,
		change-view, and quick-search menus.  Also includes the lock countdown
		timer.  A Tool may have any/some of these items, usually not all.
		Modal and Message Tools will have none...well, Modals may have the lock timer.

	https://your.omnitool-server.org/#/tools/calendar/show_event/send_jemplate

		Sends the Jemplate JS template file for the main display area of the Tool.
		** NOTE ** This is the one area for which you will write HTML.  If you
		use one of the 'core' Jemplates, you will write no HTML for your Tool,
		and for me, this is most often the case.
		Much more on Jemplates and Tool View Modes below.

	https://your.omnitool-server.org/#/tools/calendar/show_event/send_json_data

		This is the primary and preferred way for data to be sent in your Tool.
		All data sent from an OmniTool server to a client is sent via JSON objects,
		and the 'send_json_data' method in center_stage.pm works very well.  This
		is where the OmniClass object is created, where the 'session_created' timestamp
		is added (for the client JS to check), and where the instruction as to any
		custom JavaScript to execute is passed.

		You can write a custom method to send out the JSON object, and you refer to
		that method in your location hash, but it is not recommended at all.  Please only
		do that for very specific and specialized circumstances.

Please see the 'tools_flow.jpg' image under the 'notes/diagrams' directory for a better
representation of how this actually works.

In omnitool_routines.js, all these URI's will be fetched via query_tool, which is sure
to include a 'client_connection_id' parameter, and that is created when the page is
first loaded and /ui/get_instance_info is fetched.  The client_connection_id is the
unique fingerprint for that client's window (browser tab).  This is absolutely required,
so when debugging, be sure to include that in your URI's params.  More on the
client_connection_id is under 'Tool Display Options and Bookmarks' below.

Last Note: We automatically generate 'return_link_uri' and 'return_link_title' entries
in the JSON results for Action Tools. NOTE: for create-data Action Tools, those return URI's
are only going to work properly if your URI Path is 'create'.

=head2 Tool View Modes & JavaScript Classes

The server-side Tools code serves to feed data into the client-side Jemplates
and JavaScript files.  The server-side code really takes its direction for our JavaScript.
This is where I continue my raving about Jemplate started in utility_belt.pm ;)

After setting up the Tool record / config in OmniTool Admin, you must set up at least one
'Tool View Mode' for the Tool -- unless it is a 'Action - Message' Tool, in which case
it's just a pop-over.  A Tool can have as many Tool View Modes as you care to set up,
which is a pretty nice feature.  Each Tool View Modes relates to a Jemplate template
filesto display the Tool's output in a different way.  For example, you can display
your appointments as a plain table in one View Mode, as a proper calendar in another
View Mode, and if you're really cheeky, as a Google Map in another View Mode.  Or
however you wish to code up a Jemplate.

You set up the Tool View Modes by selecting 'Tool Modes' next to the Tool's
name in Manage Tools, and when you click to create or update the Tool View Mode.
If this is a Searching Tool, you will have to return to update the new Tool View
Mode to select which Datatype Fields will be included in the JSON object being
sent to the client.

If you configure a Tool to have multiple View Modes, a menu to jump between the
modes will appear next to the Quick Actions menu in the Tool's controls area.
Selecting a different view will trigger a call to the 'send_jemplate' URI and
reprocess of the data.

OmniTool provides several 'core' Jemplates for setting up Tool View Modes,
and these are kept under omnitool::static_files::tool_mode_jemplates .

To create Custom Tool View Modes for your Application, you will first need to specify
an 'Application Custom Code Base Directory' for the Tool's parent Application.
That directory will be under $OTPERL/applications, and it should contain these
subdirectories:

	datatypes		- Contains OmniClass Packages
	tools			- Contains Tool.pm sub-classes
	javascript		- Contains JavaScript for Custom View Modes, plus a
						'application_wide_functions.js' file
	jemplates		- Contains the Template-Toolkit/Jemplate files for the Custom View Modes
	common			- Contains Perl modules/classes which will be shared among your custom
						OmniClass Packages and Tool.pm sub-classes.

You will need to create these directories manually.  Then you will place the custom view template
under 'jemplates' and then enter the filename in the 'Custom Template' field when creating the
new Tool View Mode.

Herein lies the magic: These Tool View Mode Jemplate files are first server-side Template Toolkit
files which are processed into Jemplates to sent to the client and rendered with the Tool's JSON
data.  So it's a template processed on the server to make a template for the client.  This is
necessary because you can choose to include certain columns in your JSON results for the Search
Tools, and you want the Jemplate to adapt as you include/exclude these columns.  See the
'Table.tt' file under the 'static_files/tool_mode_jemplates' directory for a good example.

Jemplate is so wonderful because it's a port of Template Toolkit to run on the client, so you
can use the same syntax for all templates in OmniTool.  There are a lot of really nice JS
frameworks, but there is just something great about the idea tha I can write one template file
which could be rendered on the client or the server.  Plus, it just works so well.

Template Toolkit's manual is here:  http://www.template-toolkit.org/docs/manual/index.html
And once you master that, please see http://www.jemplate.net

I am certainly no great maestro with Template Toolkit yet, which is another testament to how
good it is, when you consider what we have already.

For all your Custom Tool View Mode templates, your first tag should be [% TAGS star %] .
This instructs the server-side processing that all of its directives/code will be inside
[* *] markers, and all the directives/code for the client-side processor will be within
[% %] markers.  I should be doing a better job of commenting these templates.  So far, I have
opted to use HTML comments for that, <!-- -->, although using server-side template comments
is likely a better choice:  [*# some-comment *].

As you write the Templates/Jemplates, it may get confusing to work with the JSON data sent by
the Tool.  I would recommend using the 'JSONView' core Tool Mode View option to have a look
at what is sent from the server for your new Tool.

Your custom template/Jemplate should cover all 'phases' of your Tool, if it has multiple
phases like a multi-page form.  Please make use of the BLOCK directive to separate your phases
and then run PROCESS accordingly.  You can trigger Jemplate re-processing on the client by changing
the location hash (without moving to a different Tool's URI), but better still is to utilize the
'process_action_uri()' method for the Tool object in the JavaScript, as well as submit_form().

Here is an example of using process_action_uri() in a link:

<button type="button" class="btn btn-link"
onclick="tool_objects['[%the_tool_id%]'].process_action_uri('[%create_table_uris.$baseline_table%]')">
	Create
</button>

For submit_form() to work, the 'interactive_form_elements' function has to run.  This function will bind
any forms you create. You really should specify 'interactive_form_elements' for the 'Run JS Function on
Load' field when creating or updating a Tool View Mode that has a form, however, if your Jemplate has
'Form' in it's name that field will default to 'interactive_form_elements'.  If you specify a custom
function in that 'Run JS' field, then make sure it calls 'interactive_form_elements(tool_id)' -- and
the tool_id is always passed as an argument to that 'Run JS Function on Load' function.

Write your forms by setting up a 'form' data structure in your server-side code to be interpreted with
the system-wide form_elements.tt Jemplate routines.  More on that under 'Writing Tool.pm Sub-Classes
for Action Tools' below.

Regarding the 'Run JS Function on Load' option, this will be the name of a function, no ()'s and no
arguments, which must exist in the 'JavaScript Class' you choose when creating the main Tool record.
That file must exist in the 'javascript' sub-directory within the Application's custom code directory.
This class will be loaded up when the whole UI loads for your Application, so if you make changes to
the JavaScript, you will need to reload the whole page for those to take effect.  This is true for really
all of the client-side code, naturally.

The 'interactive_form_elements' function is included in omnitool_routines.js, and if your form-oriented
Tool View Mode needs to have its own JS function, then you can certainly call interactive_form_elements()
from within that function.

=head2 Tool Filter Menus & Record-Coloring Rules

When setting up Search Tools, you are able to configure Tool Filter Menus and Record-Coloring
Rules  via the OmniTool Admin UI.  These options do not apply to Action Tools.

Record-Coloring Rules allow you to set up match logic to add a 'record_color' entry with the
target color for the record under the 'metainfo' hash for the record:

	$self->{omniclass_object}->{metainfo}{$record}{record_color}

This is then (optionally) handled in your Tool View Mode to add the color to the display of
that record.

Tool Filter Menus allow you to set up search menus and keyword matching options for the Tool.  The
search menus (not keywords) can be assigned to the 'Quick Search' area, which is the horizantial
navigation area above the tool display, to the right of the Quick Actions and Change View menus.
Up to four menus can be placed in the Quick Search area.  Search menus and keyword search options
can also be placed in the Advanced Search area, which is presented in a modal view by clicking on
the 'Advanced Search...' button under the 'Advanced' drop-down to the right of the Quick Search area.

For the Tool Filter Menus, you must specify a way to generate the options (name/value pairs) for
each menu.  The create/update form allows you to choose between:

	- Comma-separated list of values, in which each entry serves as the option name and value.
	- Name/Value pairs, in which the options are specified as NAME=VALUE and each option being
		presented on one line, i.e. separated by newlines.
	- SQL Command:  Offering this out of a sense of guilt, it's use is discouraged.  The SQL
		command and corresponding bind variables should yield two columns of results, the first
		being used as the value and the second being the display option name.
	- Method: Will be a method of your Tool.pm sub-class.  Much better to use than the SQL
		Command, and the right choice.

The 'Match Against DB Column' option indicates which column will be matched against the selected
option.  If that database table column is in the Tool's target datatype's DB table, then "Matches'
Relationship to Tool Datatype" will be set to 'Direct'; otherwise, you will specify the foreign
key relationship in 'database_name.table_name.column_name' form to match against the
"concat(code,'_',server_id)" primary key of the target datatype's database table.

=head2 Tool Display Options and Bookmarks

As Tools are accessed and parameters are passed in via Filter menus and keywords (and any other params),
the 'state' of the Tool is saved into the 'tools_display_options_cached' table for the Application
Instance's database.  This is done by keeping all the display parameters in $self->{display_options},
serializing that hash, and keying the record by the username plus the 'client_connection_id' and the
tool's ID.  All of this allows the Tools to be accessed via multiple URI's as above and have the display
options be sticky.  More importantly, the user should / will experience the following:

	- If they navigate away from a tool and then return, within the same browser tab, the system will
		'remember' and re-display according to the last-used options.

	- If they use a tool simultaneously in two separate browser tabs (or client machines), the system
		should treat those views separately so that the options are 'remembered' for each tab
		individually.

	- If they have a default Tool Bookmark (see below) for the Tool, then those bookmarked options
		should be loaded the first time they visit the Tool within a new tab.  Unless:

	- If they are accessing the Tool via a bookmark-share URI, the display options saved in that
		Tool Bookmark will be used to display the Tool.

	- If they do not have a default bookmark for the Tool and are not accessing it via a shared
		bookmark URI, then the last-used display options will be used to display the Tool,
		provided that they accessed the tool in the past seven days.

Regarding the Tool Bookmarks, this sub-system allows the user to save a permanent copy of the
cached display options under a Name, as well as make a Tool Bookmark the default for loading
the Tool.  Users are also able to see a URL/link that they can send out to other users to
share the Tool Bookmark.  Finally, users are able to set the Tool Bookmark as the default
View (Tool + Display Options) to be shown then the user visits the Application Instance without
specifying a hash.  ('https://your.omnitool-server.org' vs. 'https://your.omnitool-server.org/#/tools/calendar')

These Bookmarks are handled via a special sub-system consisting of the bookmark_manager.pm module
under omnitool::tool along with the bookmark_broker.pm under omnitool::common and omnitool_bookmarks.js
and system_modals.tt, both under omnitool::static_files.  Unlike other parts of OmniTool, this system
does not use the Tool object in omnitool_routines.js nor a real Tool config, because the URI can not change
and this really acts a sub-method of the currently-viewed Tool.

Final note on Tool Bookmarks is that they apply only to Screen Tools ('Search - Screen' and 'Action - Screen')
as Message Actions should not be bookmarked, and Modals should be so simple that they would not be bookmarked.

=head2 One-Click CRUD

To get started REALLY quickly on data search and management tools, we have the 'One-Click CRUD' option in
the OmniTool Admin UI.  This lets you launch create-read-update-delete toolsets almost instantly.  Here is
the process:

1. Set up the Datatype under 'Manage Datatypes' below the target Application.  Flush the Datatype Cache
once the Datatype is built.  There is a little Tool for this in the Quick Actions menu for Manage Datatypes.

2. Navigate to 'Manage Tools' under the Application, and browse into the Tool under which you would like
your CRUD toolset to exist.  This could just be the top level of the Application.

3. Select 'One-Click CRUD' under the Quick Actions menu, and complete that form.

4. Select 'Flush Sessions' next to any of the Tools listed under Manage Tools.

Now the Search/CRUD tools are set up, in a very basic mode -- which may be just good enough.  You will likely
want to update them some to change the Font Awesome Glyphs and maybe a few other bits.  Or you may want to
change them a lot, but now you have gotten off the ground.

=head2 Display Charts for Search Results

Through the magic of Chart.js ( http://www.chartjs.org/ ), OmniTool includes 'pretty good' support charting.
You can create pie, bar, and line charts to appear above your Tool's main display area, but below the
Tool Controls.

Here are your three pathways to lovely charts, in order of complexity.

1. You can create basic charts with ZERO CODE for your Searching Tools.  In your Tool View Mode, select a
value other than 'No' for 'Display a Chart', and then for 'Fields to Include', make sure your desired
X-Axis field is first, and then your Y-Axis field is second.  You can have other fields as well, but the
X/Y need to be first and second.  You will still want to set up the other options as per usual.  (For the
curious, this uses render_tool_chart() in omnitool_routines.js.)

2. You can create more complex charts using custom code.  You will add your own 'charting_json' method in
your Tool.pm sub-class to override the one in searcher.pm.  This works for Searching Tools as well as
'Action - Screen' Tools.  Your custom 'charting_json' method will generate the data structure which
will be used for the 'data' argument to the chart, so you can do literally anything.  Please see the
Chart.js docs here:  http://www.chartjs.org/docs/latest/ .  You will also need to set something other
than 'No' for 'Display a Chart' in your Tool View to kick off the chart, but it will ignore the chart
type, as you set that in your data structure.

3. If that's not complex enough for you, please consider that you can cheat and add a chart literally
anywhere in your Tool Mode Jemplates.  You would still have that custom 'charting_json', and you would
ID your target DIV's as 'chartarea_SOME-STRING' where 'SOME-STRING' is anything you like it to be.
Your Tool's custom JS function(s) would invoke: render_tool_chart (tool_id, ''SOME-STRING');
When the query is made to your 'charting_json' method, you'll want to look in
$self->{luggage}{params}{alternative_chart_id} .  You will still need to set something other
than 'No' for 'Display a Chart' in your Tool View, but it will ignore the chart type, as you set that
in your data structure.

That last one is something I haven't done yet.  This part of the system is still kind of nascent.
(Word of the day achieved.)

=head2 Writing Tool.pm Sub-Classes Overview

Writing custom sub-classes for your Tools will open up a lot of this system's power, hopefully without
requiring a lot of code.  You are able to create a great deal of functionality by writing the 'hook'
methods that Tool.pm will attempt to call during various execution phases.  I would really advise
against writing override methods but instead encourage the use of the hooks, which are listed in
the next section.

You have the most opportunity for customization when writing sub-classes for the Action Tools, which all
should have their own sub-classes.  Search Tools can often get by without any custom code, especially if you
are a Template Toolkit wizard, but an Action Tool really does not work without a sub-class.  The caveat to this
is if you are using the standard_data_actions.pm sub-class to drive the create/update form, you can do a lot
with the OmniClass hooks to customize the Tool, particularly pre_save, post_save, prepare_for_form_fields,
post_form_operations, and options_XYZ.

To download a sample / starter sub-class for your Tool, select 'Get Sub-Class' beside the tool in
OmniTool Admin >> Manage Tools, and you can see the template for that file at
omnitool::static_files::subclass_templates::tool_subclass.pm .

Please have a look at the 'developing_custom_tools.jpg' image under the 'notes/diagrams' directory within
the code, as it shows nicely how Tools are built.

When writing Tool.pm sub-classes, you will want to make use of the attributes in $self.  Please check out
the new() constructor for what's there, including comments, but a few of my favorites include:

	- 'belt' => an alias to the utility_belt.pm object from %$luggage -- very convenient.
	- 'attributes' => reference to the main tool config info in $$luggage{session}{tools}{$tool_datacode},
	- 'tool_configs' => reference to the sub-configs in $$luggage{session}{tool_configs}{$tool_datacode},
	- 'my_base_uri' => string with the base URI for the tool (no # mark):  '/tools/'.$$luggage{session}{tools}{$tool_datacode}{uri_path_base},
	- 'my_json_uri' => string to the send_json_data URI for the tool: '/tools/'.$$luggage{session}{tools}{$tool_datacode}{uri_path_base}.'/send_json_data?client_connection_id='.$$luggage{params}{client_connection_id},
	- 'client_connection_id' => string for the fingerprint of the browser window / API session; $$luggage{params}{client_connection_id},
	- 'altcode_decoder' => instance of the omnitool::common::altcode_decoder class for translating altcodes

Let's reiterate that the actions performed on or by data objects should be handled in the OmniClass Packages,
and your Tool.pm sub-classes are meant to control those OmniClass objects.  It can get fuzzy when you have
to set up rules and controls about what can happen when and how, but please try to put as much of that logic
as possible in the OmniClass Packages.

PS: You can find the altcodes for the parent tool's latest search results in the 'altcodes_keys' key of
that tool's display options.  Here is how you can retrieve that out in a subordinate quick-action Action
Tool:

	my $parent_tool_datacode;
	($parent_tool_datacode = $self->{display_options}{return_tool_id}) =~ s/$self->{luggage}{app_instance}_//;
	my $parent_tool_display_options =  $self->{db}->hash_cache(
		'task' => 'retrieve',
		'object_name' => $self->{luggage}{params}{client_connection_id}.'_'.$parent_tool_datacode,
		'db_table' => $self->{display_options_cached},
	);

Now those altcodes are in @{ $$parent_tool_display_options{altcodes_keys} } .

=head2 Available Hooks for Tool.pm Sub-Classes

Here are the hooks which Tool.pm will attempt to call from your sub-class, somewhat categorized:

	- Object Initialization

		- init():  Called during new() and useful to change or add to the object attributes.

	- HTML Skeleton Building

		- pre_tool_controls(): Runs before the tool_controls() method in html_sender.pm,
			allow you to alter the variables that will go into the Tools Controls area,
			via the tool_area_skeleton.tt template.  Primary uses may be to tweak the
			Quick Actions menu or to alter the Tool's description if it is to be displayed
			above the tool controls.

		- special_breadcrumbs(): Generates alternative breadcrumbs array for showing the path
			of the tool above the Tool Controls area.  Rarely used, unless the Tool can be
			nested into itself, like Manage Tools

	- OmniClass Loading (Jemplate and JSON Data preparation)

		- special_omniclass_object(): Called from get_omniclass_object(), which is in turn called
			from send_jemplate and send_json_data in center_stage.pm.  Useful if you want to control
			precisely how the OmniClass object is built for the Target Datatype.  Will be rare,
			and if not provided, the Object Factory will be used to create the OmniClass object
			with standard options, which should be just fine.

		*** Note: The OmniClass object for the tool should be placed in $self->{omniclass_object}.
			That's where the stock get_omniclass_object() code places it, and so should any
			hook.  Granted, you might load all kinds of other objects.  Probably best to
			have a sub-hash for those.  You know what, don't let me live your life for you.

	- Jemplate Preparation and Sending

		- pre_prep_jemplate(): Called before any work is done to build the Jemplate; useful to
			add values to $self, which will be passed into the Template Toolkit processing
			of the template into a Jemplate.  Please put your options for the Jemplate
			in $self->{jemplate_options}

		- pre_send_jemplate():  Called right before the Jemplate code is processed into JavaScript.
			Receives the Jemplate's text as an argument and returns it out, presumably modified.
			Good for brute-forcing the output, and probbaly not a great idea to use.  Available
			for you nevertheless ;)

	- Search Tools

		- pre_search_build(): Called in searcher.pm before the build_search() routine. Useful
			for adding search logic, perhaps tightening or limiting it based on factors outside
			the user's control (day, location, their access, etc.).  Can also augment the choices
			the user made a bit.  You can do all this by modifying the filter menu configs under
			$self->{tool_configs}{tool_filter_menus} ; remember changing anything this way is
			transient just for this execution UNLESS the session gets re-saved.  So be a little
			mindful.

		- pre_search_execute(): Called in searcher.pm right before the search is executed via
			OmniClass's search() method.  Very useful to change all the search criteria built in
			$self->{searches} -- check out the searcher.pm code to learn about those.  Might
			be even easier for tightening the search than pre_search_build().  To make things
			much easier, the standard build_search() will add a 'which_search' entry to each
			hash under $self->{tool_configs}{tool_filter_menus} so you know which hash in
			$self->{searches} goes which each menu, i.e.:

				my $search_array_entry = $self->{tool_configs}{tool_filter_menus}{'some_key'}{which_search};
				my $search_criteria = $self->{searches}[$search_array_entry];

				If you want to modify the match_value of the search_criteria, without disturbing the menu
				option which is shown, then put your new match value into $$search_criteria{real_match_value} .

			This hook can also modify the default ordering column / sort order.

		- post_search_execute(): Called in searcher.pm right after the search is executed, including
			the keyword matching and record coloring rules.  Last opportunity to modify the search
			results before they are sent out as JSON to the user.  Remember, all these results are
			going to be in $self->{omniclass_object}{records} (and {records_keys} and {metainfo}.)
			Potentially the most powerful hook for Search Tools; be careful with it.

		- json_results_modify(): Called as the last search of a search execute, when $self->{json_results}
			is complete.  This is your opportunity to modify that data before delivering to the client.

			** Note:  Put text into $self->{json_results}{breadcrumbs_notice} to pop a notice into the
				breadcrumbs area.  You could also cheat and put something into
				$self->{json_results}{limit_notice} to display in a well DIV above the search
				controls/quick actions area.

		- advanced_search_form_tweak(): Executes at the bottom of advanced_search_form() and allows you to
			tweak the form contents in $self->{json_results}{form} to change up your advanced search.
			Good place to shim in some 'onchange' events.

	- Action Tools

		These hooks are a bit different because you do need to have at least one of them, as Tool.pm
		does not provide default versions nor does it do a whole lot in Action Tool mode without at
		least one of these.  For Action Tools that provide forms, you need to have at least
		generate_form() and perform_form_action().

		These will be discussed in more detail below.  They are all called in action_tool.pm,
		in this order:

		- perform_action(): Used for non-form (or non-standard-form) actions which produce JSON
			to be interpreted by Jemplate into HTML.  A drawing or map Tool would use this.

		- prepare_message(): Used for Action Tools which are non-interactive and just produce
			a pop-over notification. These Action Tools will do some quick work or look up
			some information to display, and they are going to flash the information of their
			'errand'

		- generate_form(): Used for a form-based tool; builds the form-describing data structure,
			and runs even if form is submitted, in case it does not pass validation and needs
			to be displayed again.

		- post_validate_form(): Optional/rare and runs after the built-in form validation.  Useful
			for making that validation more or less strict.

		- $self->{omniclass_object}->post_validate_form( $self->{json_results}{form} ): Optional/more
			useful way to perform additional form validation.  Works exactly as post_validate_form but
			is calledd as a method/hook within the omniclass object.  This is very useful for (a)
			sharing post_validate_form() routines between action tools which address the same Datatype,
			and, more importantly, (b) having a post_validate_form() method available even when using
			the universal standard_data_actions.pm class for adding/updating data.  (If it is not clear
			here, I am saying that you can/should put post_validate_form() into your OmniClass package,
			and pass the form data structure in as the only arg.)

		- perform_form_action(): Completes the action your form is meant to cause ;)  Executes if
			the form passes validation, in which case $self->{stop_form_action} is empty.

		- autocomplete_XYZ: supports the auto-suggest feature of a 'short_text_tags' and 'short_text_autocomplete'
			fields.  The 'XYZ' is the 'name' value of the target form field.  Should work with a query term
			in $self->{luggage}{params}{term} and return a simple arrayref of results.
			*** Only use this for forms not generated by OmniClass -- those should have
			the 'autocomplete_XYZ' hook in the OmniClass Packages. ***

=head2 Creating Virtual OmniClass Fields for Rich Display

In your OmniClass Package, you can create hooks to add keys to the {records} sub-hash, and then
add those as Virtual Datatype Fields under the Datatypes.  These virtual field methods can simply add
a plain value, similiar to a field loaded from the database.  Otherwise, you can add an array of sub-hashes
with any or all of these keys:

	$self->{records}{$id}{ginger} = [{
		'text' => 'Some Text',
		'uri' => 'tool_uri',
		'glyph' => 'font-awesome icon',
		'image' => '/path/to/image',
		'class' => 'css_class_name_for_div',
		}, # can have several more of these
	];

Then your Jemplate will handle accordingly.  Each sub-hash represents a line in the record to display, and
this could be useful for just having one Virtual Field to send to the Jemplate. Generally, you would not have both
the 'glyph' and 'image', but you are the boss.

Remember that these Virtual Field hooks are built after the data is loaded from the database and after any
pre_search() OmniClass hook, so there are many possibilites.

=head2 Writing Tool.pm Sub-Classes for Action Tools

Most of the fun is in writing the sub-classes for Action Tools, as that is where you make the cool stuff
happen, and hopefully, it will be pretty easy. All Action Tools run via action_tool.pm, which is called via the
center_stage.pm module, within send_json_data().  This action_tool.pm module / method tries to handle a lot
of the common tasks for you, so you can focus on the very specific code, including form validation and
data locking.

Action Tools can be displayed as full-screen, modal, and pop-over message.  The message tools should be
simple actors who perform some action or look-up and displays the results in the pop-over.  The modal
Tools should have up to a medium level of interactivity but could be forms; the Action Tools displayed
as screens will be the most complex.

If you are developing a message/pop-over Action Tool, then your sub-class should have the 'prepare_message()'
method and all activity be set up, or called from that method.  This prepare_message() method should fill
in these parts of $self->{json_results}:

	$self->{json_results}{title} --> The title to shown in bold at the top of the pop-over.
	$self->{json_results}{message} --> The text of the message / optional if there is a title.

	OR if there is an error condition, fill in these instead:

	$self->{json_results}{error_title} --> The error message title to be shown in bold.
	$self->{json_results}{error_message} --> The brief details of the error; optional if {error_title}.

If the Action Tool appears in a modal and is NOT a form-oriented tool, then your sub-class should rely
upon perform_action() method.  This is the most free-form style of Action Tool, and you can put what
you like in {json_results} to be interpreted by your Jemplate template.  I should note that you can
write a form in this if you wish, but for larger forms, I highly recommend using the built-in functions.

Side-note:  For logging of non-fatal messages, please use $self->logger() to save to a log named
for the tool.  All you have to do is $self->logger('message');

Without further adieu...for your form-oriented tools, you should build the following:

	- generate_form() to build a form specification in $self->{json_results}{form}, and
		please see the documentation in omnitool::omniclass::form_maker to see how that
		data structure should look and work.

	- post_validate_form() to evaluate the form submission and revise the 'decision' of the
		standard validation routines.

	- perform_form_action() to put the form submission into effect and return the results.

Regarding the standard validation routines, they are designed to test for the required fields being
filled in, as well as for certain field types to be properly formatted.  If an error is found,
$self->{stop_form_action} will be set to '1', along with $self->{json_results}{form}{fields}{$field}{field_error}
where $field is the key of the incorrect field.  Also, action_tool.pm will fill in $self->{json_results}{form}{error_title}.

PRO TIP:  When filling-in 'error_title' or 'error_message,' you can also set a value in $self->{json_results}{form}{show_error_modal}
to have the Web UI pop up an official-looking error modal.

If the form is submitted, once the validation routines are run, if $self->{stop_form_action} is not filled
in, perform_action() will be executed.  You can have OmniTool 'convert' the Tool into a message / pop-over
Tool to show these results.  To do so, put '1' into $self->{json_results}{form}{error_title} and set the
other variables as per messages above.  You can also provide the results to be rendered in the current
display mode via Jemplate, and either way, you should fill in $self->{json_results}{form_was_submitted}
for Jemplate to render properly.

Whether or not the form is submitted, generate_form() will be called.  This is because the form structure
is needed to complete the validation, plus the form may need to be re-displayed if validation fails.

For your Jemplate, I recommend using ScreenForm.tt or ModalForm.tt as the Template / Mode Type.  These
are standard options in the Mode Type menu for the Tool Mode Config.  These Jemplates handle the forms well,
and you can utilize them easily.  If you do want to write a custom Jemplate, please use ScreenForm.tt as
a starting point.

We do have a core Tool.pm sub-class named 'standard_data_actions.pm', which handles nicely providing create,
create-from-another, and update-data forms based from OmniClass objects.  Really, all of your data management
should work through this sub-class, with only the most unique situations calling for a custom sub-class.  You
can accomplish a great deal with custom Jemplates and lots of great hooks in OmniClass, including the
prepare_for_form_fields() hook for OmniClass's form_maker() method.

Regardless of the type of Action Tool, you should consider filling in $self->{clear_display_options} to instruct
OmniTool not to cache the display options for when they return to the Tool.  Unlike Search Tools, Action Tools
may not need to remember your last config upon return -- especially form forms-oriented Action Tools, so that
returning to the Tool does not cause the form to re-submit.  In fact, whenever preform_form_action() is
executed, action_tool.pm will cause the display options to be cleared, unless $self->{do_not_clear_display_options}
is filled in.

Please don't forget that the OmniClass object for the Target Datatype will be in $self->{omniclass_object}
by the time you are in action_tool().  If the URI has an Altcode, meaning a targeted record, then action_tool()
will load up that record straight away, and it will be loaded for your custom method(s).  Almost all Action
Tools will have a target data record, and since there is only one record, its data will be available under
$self->{omniclass_object}{data} and $self->{omniclass_object}{data}{metainfo}.

If the Action Tool has 'Is Locking Action' set to 'Yes,' action_tool() will handle setting the data lock,
and then it will get released if the user navigates to another URI in the UI; if they just close the
window, it will need to time out based on the number of minutes you specified in the Tool's config.  You
can also set $self->{unlock} in your custom methods to tell action_tool() to unlock the data record
at the end of its execution.  This is very useful for a successful form submission.

FYI, locks are recorded in the 'lock_user' and 'lock_expire' columns in the 'metainfo' table for the
database or datatype.

=head2 Summary Thoughts on Custom Tools

Just to summarize that Search Tools will often be just configurations in OmniTool Admin without
any special code, and they may have just a quick sub-class. Of course, complex Search Tools, quite a
lot of code.  Action Tools will generally have a good bit of code, at least in their Tool.pm
sub-class.

When building a custom Tool, you are able to create custom code within:

	- A custom Tool.pm sub-class, associated with the Tool's config record.
	- A custom JavaScript class, also associated with the Tool's config record.
	- A custom Jemplate template, to be processed on the server into a Jemplate for processing
		on the client, and associated with a custom Tool View Mode.
	- A custom JavaScript function, from the class associated with the Tool's config record,
		and enabled in the Tool View Mode record.

Again, please take a look at the 'developing_custom_tools.jpg' image under the 'notes/diagrams'
directory within the code, as it shows how Tools are built.

=head2 Downloading Files to the Web Client

Something kind of nice is that OmniClass will automatically virtual fields with links to download
uploaded files via the Web UI.  If a Datatype has a file upload field named 'dog_picture', then a
virtual field named 'dog_picture_download' will be created.  (So long as 'skip_hooks' is not set,
of course.)

This is codeless; all you have to is select the Virtual Field ending in 'Download' when configure
your Tool View Mode in the OmniTool Admin UI.

=head2 Refreshing One Search Result

For a true asynchronous experience, search tools can refresh just one displayed record.  As of this writing, you can
only do this with the WidgetsV3.tt and Table.tt Jemplates.  To refresh a single record, call the refresh_one_result()
method on the 'tool_object' JavaScript object for the tool.  Your JS code would look like:

	tool_objects['TOOL_DATACODE_AND_INSTANCE_ID'].refresh_one_result('RECORD_DATA_CODE','RESULT_JEMPLATE_BLOCK');

If you are using the WidgetsV3.tt template, the 'RESULT_JEMPLATE_BLOCK' would be 'the_result_widget'.  For Table.tt, the
'RESULT_JEMPLATE_BLOCK' is 'the_result_table_row'.  The JS code to cause a refresh one result would be in your Tool's custom
JavaScript class.  To allow this in your search result Jemplates, be sure to break out the body of the individual-result
display into its own BLOCK, and then be sure to show the result-wrapper DIV like so:

	<div class="WHATEVER_CLASSES_HERE" id="[%record_key%]_result">
		[% PROCESS the_result_widget %]
	</div>

NOTE: You can have Modal and Message Action Tools cause the refresh of their target record's result in the parent search
by setting the 'Single Record Jemplate Block' in the Tool View Mode for the parent Search Tool.  This will likely be
'the_result_widget' or 'the_result_table_row'.  So for example, if you have a Addressbook Search Tool which pops up
modals to update the results, you can have the individual contacts' results refresh when you close that update modal.

=head2 Working in API mode.

API mode is not perfectly hipster-compliant because (a) the system does not accept JSON data in, and (b) the
forms and links could be a bit more rigidly consistent. However this does work really well all things considered.

The basic idea is that in API mode, you will want to access the Tools mainly via their 'send_json_uri' URI's,
as the other URI's are generally for facilitating the Web UI.  The only exception being if you have a
custom method added to your Tool.pm sub-class (i.e. /tools/ot_admin/app_instances/background_tasks/view_error_message)
I just distracted you with a one-off.  My apologies.  99.5% of the time, you want to foucs on the 'send_json_uri'
URI's.

** Please note that ANY tool in this sytem can be accessed via the API programmatically.  This is what my
JavaScript is doing already. **

The first step is to get an API key from the 'Manage API Keys' tool within the OmniTool Admin Web UI (for the Admin
Instance that is driving your target Application, i.e. https://your-ot.yoursystem.com/your_admin#/tools/user_api_keys .
These keys are tied to the username of the client user and the IP address of the server you wish to use as a client.
They will have expiration dates, 90 days from creation by default, and they can be renewed for 90 days at a time.

Regular users are only allowed to make API keys for themselves.  They will get the default 90-day expiration, and they
will be assigned a 50-character random alphanumeric string for their API key.  They are allowed to assign the client
IP addresses and set their keys as Active or Inactive.  Inactive keys are not usable, but I am guessing you guessed that.

Users with the 'OmniTool Admin' access role will be able to create, manage, and view API keys for all users and have
access to all fields of the API keys.  Please be careful.  Remember, being in the OmniTool Admin role for one Admin
instance doesn't mean you must have that for all Instances.

Armed with an API key, one could write a client such as the example in omnitool/static_files/subclass_templates/sample_api_client.pl
and hopefully better.  The 'omnitool::sample_api_client' package in that script does show the basic requirements and
does seem to work well. One key gotcha is the Client Connection ID; please be sure to read those comments.

You can point this client (or your own) towards any Tool's 'send_json_data' URI.  You'll send arguments via POST
and receive back JSON results.  I recommend using the target Tool manually within Chrome (or similiar), woth Developer
Tools open, and studying the data sent via 'send_json_data' as you interact with the Tool.  Specifically, when
you load up a form, 'send_json_data' will include a 'form' structure describing precisely the inputs and options
required, within the 'fields' and 'hidden_fields' structures.  From that, you can easily devise a post response
back to that 'send_json_data' URI.  When submitting forms, be sure to pass a 'form_submitted' value.

When querying Searching Tools, the 'records' and 'records_keys' strctures will contain the matching data for
your search. The 'metainfo' structure contains info about those records, and probably the age/update-time bits
are most interesting.  Devising queries for the searches is not as straightforward as working with forms, so we have the
'show_display_options' standard method for you to see the values to send for your search.  You just configure
the search how you like via the Web UI, then you fetch the JSON object for your current display/search options:

https://your-ot.yoursystem.com/TOOL_URI/show_display_options?client_connection_id=username1467602633F28B05ADB1BF4A0897B1&uri_base=your_admin

Please be careful.  If you are hooking an API into your system to interact with OmniTool on behalf of others, best
practice is to have each of your users generate their own API key to use with your app.  Your friendly OmniTool adminstrator
should be able to help you to automate gnerating those keys.
