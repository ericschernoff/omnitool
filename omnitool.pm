package omnitool;
# Nominally provides an entry-way into OmniTool.  Really just an abstraction of
# omnitool::common::luggage. Exists for the Pod documentation below and for a snappy
# way to write scripts.
# The Web/HTTPS interface all goes through Plack / main.psgi

# for the record, this module, and luggage.pm are the only non-OO packages in the system.

# The first five were so bad, they are classified.
$omnitool::VERSION = '6.4';

use strict; # this is for my perl, but not my lorelei

# where we actually build the luggage, which includes everything one needs for a
# great OmniTool script; please see the Pod in there for the contents of %$luggage
use omnitool::common::luggage;

# alright, it's time to:
sub pack_luggage {
	my $class = shift; # not used here, just yet.

	# takes the same args as the real pack_luggage, in luggage.pm, and
	# that module will take care to throw errors if the args are not right
	my (%args) = @_;

	# call and return the real luggage routines
	return omnitool::common::luggage::pack_luggage(%args);
}

1;

__END__

=head1 NAME

OmniTool - Build web application suites very quickly and with minimal code.

=head1 SYNOPSIS

use omnitool;

$luggage = omnitool->pack_luggage(
	'username' => 'someones_username',
	'hostname' => 'hostname-to-an-omnitool.application.omnitool.com',
);

# %$luggage now contains a user session, utility belt, object factory, and
# more goodies used to write a program to operate on your application.

# The rest is OO, like so:

$dogs = $$luggage{object_factory}->omniclass_object( 'dt' => 'dogs' );

$dogs->search(
	'search_options' => [
		{ 'name' => 'Ginger' },
		{ 'age' => 17, 'operator' => '>' },
	],
	'auto_load' => 1,
);

if ($dog->{search_results_found}) {

	print "The first dog I found is ."$dogs->{data}{name}."\n";

	$dogs->perform_trick('roll-over');

}

This is an example of what a test script might look like.  The vast majority
of your real-world use will be run via the included main.psgi and
background_tasks.pl.

=head1 SUMMARY / DESCRIPTION

OmniTool is a comprehensive platform for the rapid development of web application suites.  It is
designed to simplify and speed up the development process, reducing code requirements to only
the specific features and logic for the target application.  The resulting applications are
mobile-responsive and API-enabled with no extra work by the developers.

The OmniTool Administration UI allows developers to design object models (datatypes), specify
the behavior of controllers (tools), manage display views (templates), import custom code
(sub-classes), and configure the authentication and authorization logic.  These actions are
all completed via straight-forward and well-documented web forms. Most changes to
application behavior are implemented without code changes and can be deployed instantly.

The configurations of tools, datatypes, templates, and custom sub-classes combine to form OmniTool
Applications, which are put into use via separate Application Instances.  Each Application Instance
may (often will) have a separate database, will use separate logic to authorize users, and can have
a separate application server.  This allows for horizontal scaling as well as single-tenancy for each
organization making use of a given Application.

A key differentiator for OmniTool is the inclusion of a complete mobile-responsive User Interface.
This UI kit provides a login form, all navigation, view bookmarking, and all search controls.  For most
applications, there will be no need to develop HTML templates or JavaScript for new applications,
as the standard view mode templates are capable to handle search results, record-details display,
forms inputs, modal views, pop-up messages, and more.

Every application developed with OmniTool is automatically equipped with a client API without any
special code.  Users are able to provision API keys that can be used to access their tools to
submit requests to OmniTool.  These keys are tied to IP addresses and require periodic renewal
(which can be indefinitely extended by the administrators).  Because all OmniTool applications receive d
ata via POST and return data via JSON objects, it is very straight-forward to write an API client for
any tool in the system.  Example libraries are provided.

Additional facilities within OmniTool include:  background task management and execution, inbound
email processing, outbound email creation, and a large library of utility functions to aid with
many common tasks.

OmniTool is an object-oriented system, written in Modern(ish) Perl using Plack for delivery.
Application-specific code is written as sub-classes to tools and datatypes, so that all of the
common facilities are always available.  The client-side code is developed with HTML5, Bootstrap,
clean JavaScript, jQuery, and Jemplates.  All data is stored in well-normalized MySQL 5.7+ / MariaDB 10.3+
databases.  OmniTool is meant to run on Linux or FreeBSD, and the installation process has been tested
most on Ubuntu 16.04 as of this writing.  OmniTool is a extremely well-documented system with many examples
in the extensive developer guides.

=head2 TARGET AUDIENCE / USES

Folks who install and run OmniTool will be experienced LAMP developers who are looking to save a lot
of time.  Anyone with a web browser will be able to make use of the applications that you build and
publish with this software, but building and administering these applications will require development
expertise.

This is a great system for small-to-medium organizations or departments within larger organizations.
The well-defined UI and 'more-is-more' functionality do tighten its focus a bit, although building
alternative UI's is quite possible for the industrious.  I think this system is perfect for building apps
to manage resources, processes, and requests.

There are three usage modes for the applicatins you build in OmniTool:

=over

=item 1. Web UI (HTML):  Easiest way for everyone to use your app.  Mobile-responsive, and really shines on tablets.

=item 2. API: Allows users to set up their own programs to send requests via POST's and receive JSON back.  Very nice
for extending your application across your organization and beyond.

=item 3. Perl Scripts: Maybe you just want to manage your datatypes via the Admin UI and then write your scripts to
make use of these databases.  Would be the least fun, but there is plenty of utilities here to have some fun.

=back

=head2 DEVELOPER'S OVERVIEW

All of the main modules have Pod documentation within them, so this is just an overview.
The main parts of this code / system are:

- omnitool::omniclass, which I obnoxiously refer to as 'The OmniClass.'  This is meant to be
the 'Model' piece, and its objects are instances of Datatypes, which are object definitions
configured in the OmniTool Admin UI.  This class handles all the database functions (search,
load, save) as well as producing forms.  Special functons driven by your data should
be developed in sub-classes for OmniClass, all the way from small hooks to massage data for
presentation up to large actions to impact other data and systems.  Please see
'perldoc omnitool::omniclass' for lots more information.  FYI, "OmniClass Sub-Class" was
so obnoxious, I have to call them "OmniClass Packages"; this is only marginally better, I know.

- omnitool::tool, which I refer to as 'Tool.pm', provides the 'Controller' piece.  This
module brings to life the Tools which are configured in the OmniTool Admin UI, and those
Tools are meant to command OmniClass and its packages.  Like OmniClass, Tool.pm is a base
class which provides a lot of functionality, and your Tool.pm sub-classes are where you build
the custom applications.  Please see 'perldoc omnitool::tool' for lots more information.

- omnitool::static_files:: is our collection of JavaScript classes and Template-Toolkit
templates that combine to form our 'View' piece for the Web UI.  We use the excellent Jemplate
library to utilize Template-Toolkit on the client-side, allowing us to fully separate the data
from the presentation, sending all data to the client via JSON.  This makes it possible to
have a fully-functional API mode outside of the Web UI, automatically available for each
new Tool configured.  ** Note: yes, I am keeping these 'static' files here within the Perl
code, because (a) this is very much custom code which will be maintained as part of this
single system, (b) it will be served to the clients via omnitool::common::ui and (c) I
believe the 'htdocs' directory is for very static documents, image files and third-party
HTML/JS/CSS/image libraries like ACE.  *** Second note: I did start using the 'we' and 'us'
lingo in this section.  If you read this far, you are definitely involved.

- omnitool::common::, is the Perl name-space for our utility and glue modules which
provide the routines Tool.pm and OmniClass both rely upon as well as to make this system
actually function as a application framework.  Database functions, user sessions, UI producing,
and template processing all happen in here, among other important work.

Conceptually, OmniTool is meant to power 'Applications,' which consist of:

=over

=item 1. Datatypes - OmniClass configurations create/maintained via the OT Admin Web UI.

=item 2. Tools - Tool.pm configurations create/maintained via the OT Admin Web UI.

=item 3. Custom Code - Your sub-classes for OmniClass.pm and Tool.pm plus any custom templates and
				JavaScript developed to support your Tools.

=back

These three ingredients allow for functional Tools, and to make them usable, you
create 'Instances,' sometimes referred to as 'Application Instances.'  Instance definitions
consist of:

=over

=item 1. A web hostname, which should point to a virtual host on an Apache or nginix server which
	will reverse proxy over to the Perl/Plack app server running this very script.

=item 2. A connection to a MySQL database server.  This server should have everything it needs to
	serve the data needs of this OmniTool Application.

=item 3. A database on the target MySQL database server which will house all the data for
	this Application Instance.

=back

This separation of Application configs, code and logic from Instance delivery / storage
configuration allows two important features:

=over

=item 1. Applications may be utilized by multiple groups or teams of people without those separate
	groups having to share data.  ('Single-tenant' databases is the term, I believe.)

=item 2. Scalability.  All your Instances may be served via one HTTPS server and one database server, or
	you could have one HTTPS server, many Plack/Perl servers and a few database servers.  If you are
	brave enoughto have Galera multi-master replication set up for your MySQL server, you can set up
	one Application Instance per DB master server, all connecting to the same database name.
	(Or you can just use a load balancer and have one instance.)

=back

To have separate Database servers, all of your OmniTool Admin databases (omnitool / omnitool_*)
must be replicated among all the servers in your OmniTool system. Each database server should
have its own, unique copy of otstatedata, with only the table structures being kept in sync
between otstatedata DB's.

Please note that the OmniTool Administration Application will itself have multiple Instances,
so you are able to separate Application/Datatype/Tools configuration data very nicely.  You
will be required to build your apps out in a second OT Admin instance, and not in
the base Instance tied to the 'omnitool' database.  This makes it easy to accept upgrades
and share your work.

=head2 TECHNOLOGIES USED

This system requires Perl 5.22 or better in the 5.x line.  It also expects MySQL 5.7 or higher.
This system also requires the full Plack suite, which is detailed here: -L<http://plackperl.org>
as well as the great docs in CPAN.

For templating, we rely on Template Toolkit on the server side and the amazing Jemplate
Perl/JavaScript library. Please see http://www.template-toolkit.org and
http://www.jemplate.net . Please see the notes in omnitool::common::utility_belt for the
template_process() and jemplate_process() methods for more info on how we use these, as well
as the notes in omnitool::tool on Tool Modes.

For the HTML, CSS, and much of the JavaScript, we have the most excellent Ace Admin Template
from www.wrapbootstrap.com.  OmniTool uses version 1.3.4 of that package, with no plans
to update at this time.  We are using Bootstrap 3.3.5, which seems to work just great.
The Ace Admin files are kept at $OTHOME/htdocs/omnitool/ace.

As of this writing, the system has been most tested on Ubuntu 16.04, but the code should work
well on recent versions of FreeBSD, RHEL, Fedora, or CentOS.

=head2 ACKNOWLEDGEMENTS

I am very appreciative to my employer, Cisco Systems, Inc., for allowing this software to be
released to the community as open source.  (IP Central ID: 153330984).

I am also grateful to Mohsen Hosseini for allowing me to include his most excellent Ace
Admin as part of this software.

=head2 LICENSE

MIT License

Copyright (c) 2017 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


