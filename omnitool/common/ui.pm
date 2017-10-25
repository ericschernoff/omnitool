package omnitool::common::ui;

# please see pod documentation included below
# perldoc omnitool::ui

$omnitool::common::ui::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# will need this in new() and change_options() if switching database servers
use omnitool::common::db;
use File::Slurp;

# need the bookmark broker so we can fetch the bookmarks for the navigation menu
use omnitool::common::bookmark_broker;

# grow up, when possible
use strict;

sub new {
	my $class = shift;
	my (%args) = @_;

	# Need to croak out if luggage or dt not provided
	# May use Carp::croak for this; need to see if I can capture die() via JSON
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create a UI object without my luggage.'});
	}

	# did they provide a $db? if not, use $$luggage{db}
	if (!$args{db}) {
		$args{db} = $args{luggage}{db};
	}

	# need a database object for sure
	if (!$args{db}->{created}) {
		die(qq{Can't create a UI object without a database object.});
	}

	# by now, everything should be in that %args hash
	my $self = bless \%args, $class;

	# let's allow them to override and add to this class for their application
	# we need to see if there is a 'custom_ui' module for the selected instance's application
	my $app_code_directory = $self->{luggage}{session}->{app_instance_info}{app_code_directory}; # sanity
	my $class_name = 'omnitool::applications::'.$app_code_directory.'::custom_ui';
	# try to load it in and bless myself into it to access the methods with all my data imported
	if (eval "require $class_name") { # phew, loaded ;)
		bless $self, "$class_name";  # see notes below about this, please
	}

	return $self;
}

# start the method to output the HTML skeleton file
sub skeleton_html {
	my $self = shift;
	# my one argument is a possible override to the default.html file or the file sent via the %args to new()
	my ($use_file) = @_;

	# which file to use
	my ($file) = 'default.tt';
	if ($use_file) { # sent via arg to this method
		$file = $use_file;
	} elsif ($self->{use_file}) { # sent to new()
		$file = $self->{use_file};

	} elsif ($self->{luggage}{session}{app_instance_info}{ui_template}) { # has one defined in the session
		$file = $self->{luggage}{session}{app_instance_info}{ui_template};
	} # otherwise, stick to first value
	# i realize there is probably an awesome perl one-line to handle that, but I am a very boring person

	# these files live in $OTPERL/static_files/skeletons where $OTPERL is the 'omnitool' subdirectory under the home directory.

	# the 'api keys' link needs the uri_base_value for the omnitool admin instance of the current application
	# we are going to pull this here as a one-time deal, so it's not done in pack_luggage() on every request
	($self->{luggage}{system_uri_base}) = $self->{db}->quick_select(qq{
		select uri_base_value from omnitool.instances where parent='1_1:1_1' and database_name=? and database_server_id=?
	},[ $self->{luggage}{omnitool_admin_database}, $self->{db}->{server_id} ]);

	# where to look for the subordinate files
	my $include_directories = $ENV{OTHOME}.'/code/omnitool/static_files/skeletons/';

	# check to see if there is an additional JS/CSS includes file to load into the primary template skeleton
	my $app_directory = $self->{luggage}{session}->{app_instance_info}{app_code_directory};
	my $application_extra_skeleton_classes = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_directory.'/javascript/application_extra_skeleton_classes.tt';
	if (-e $application_extra_skeleton_classes) {
		$self->{luggage}{application_extra_skeleton_classes} = 1;
		$include_directories .= ':'.$ENV{OTHOME}.'/code/omnitool/applications/'.$app_directory.'/javascript/';
	}

	# include their closet full of skeletons?
	my $their_skeletons = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_directory.'/skeletons/';
	if (-d $their_skeletons) {
		$include_directories .= ':'.$their_skeletons;
	}

	# prevent the 'change your password' dialog if they have auth_helper.pm installed
	if (eval "require omnitool::applications::auth_helper") { # it exists and loaded
		$self->{luggage}{allow_password_changing} = 'No';
	} else {
		$self->{luggage}{allow_password_changing} = 'Yes';
	}

	# append the suffix if it does not have one
	$file .= '.tt' if $file !~ /\.([a-z]+)/i;

	# fix up the ui template options (set at the Application in OT Admin)
	$self->{luggage}{session}{app_instance_info}{ui_navigation_placement} ||= 'Left Side';
	$self->{luggage}{session}{app_instance_info}{ui_ace_skin} ||= 'no-skin';
	# fix the pretty option they may have chose
	$self->{luggage}{session}{app_instance_info}{ui_ace_skin} = lc($self->{luggage}{session}{app_instance_info}{ui_ace_skin});
	$self->{luggage}{session}{app_instance_info}{ui_ace_skin} =~ s/ /-/g;

	# it will be a template toolkit file, which should be process and shipped ASAP:
	$self->{luggage}{belt}->template_process(
		'template_file' => $file,
		'template_vars' => $self->{luggage},
		'include_path' => $include_directories,
		'send_out' => 1,
		'stop_here' => 1,
	);

}

# method to print the no-access error page; called by dispatcher.pm and fed from luggage->session
# called when there is no access to this instance
sub error_no_access {
	my $self = shift;

	# add omnitool admin email address, in case nothing is defined
	$self->{luggage}{OMNITOOL_ADMIN} = $ENV{OMNITOOL_ADMIN};

	# very straightforward
	$self->{luggage}{belt}->template_process(
		'template_file' => 'error_no_access.tt',
		'template_vars' => $self->{luggage},
		'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/skeletons/',
		'send_out' => 1,
		'stop_here' => 1,
	);

}

# simple method to sign them out of omnitool entirely
sub signout {
	my $self = shift;

	# step one: clear the authentication records
	$self->{luggage}{db}->do_sql(qq{
		delete from otstatedata.authenticated_users
		where username=?
	},[$self->{luggage}{session}{username}]);

	# step two: delete their session
	$self->{luggage}{db}->do_sql(qq{delete from otstatedata.omnitool_sessions where code=?},[$self->{luggage}{session}->{code}]);

	# final step: present a 'you are logged out' page
	$self->{luggage}{belt}->template_process(
		'template_file' => 'signout.tt',
		'template_vars' => $self->{luggage},
		'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/skeletons/',
		'send_out' => 1,
		'stop_here' => 1,
	);

}

# load and output a javascript file as per requested; these will be referenced in the skeleton HTML
sub load_javascript {
	my $self = shift;
	# my one argument is the name of the file/class to load from $OTPERL/static_Files/javascript
	# and that is passed as a URL param
	my $javascript_file = $self->{luggage}{params}{javascript_file};

	# default to the main one for the UI
	$javascript_file ||= 'omnitool_routines.js';

	# these files live in $OTPERL/static_files/javascript where $OTPERL is the 'omnitool' subdirectory under the home directory.
	# we are going to tell Mr. Zebra that it's Javascript, with a clear initial comment.
	# see the notes in utility_belt.pm for mr_zebra().

	# i love file::slurp so much
	return "// This is Javascript, Mr. Zebra.\n".read_file($ENV{OTHOME}.'/code/omnitool/static_files/javascript/'.$javascript_file);

}

# start the method to build a data structure representing our tools navigation
sub build_navigation {
	my $self = shift;
	# no args needed; we shall operate on the session stored in $$luggage

	# allow them to override this in their custom_ui.pm class
	if ( $self->can('custom_build_navigation') ) {
		my $custom_tools = $self->custom_build_navigation();
		# if it was good, use it, otherwise, we will continue below
		if ($$custom_tools{menu}[0]) {
			return $custom_tools;
		}
	}

	# local vars
	my ($n, $sn, %tools, $child_tool_key, $tool_key, %this_action, @navigation, $bookmark_broker, $bm, $tool_id);


	# $n starts at 0
	$n = 0;

	# before loading tools, load up any tool bookmarks for this user
	# crank up the bookmark broker & auto-load the bookmarks
	$bookmark_broker = omnitool::common::bookmark_broker->new(
		'luggage' => $self->{luggage},
		'db' => $self->{db},
		'auto_fetch' => 1,
	);
	# if there are any bookmarks, load into the menu
	if ($bookmark_broker->{bookmark_keys}[0]) {
		# first the heading
		$tools{menu}[$n] = {
			'name' => 'Tool Bookmarks',
			'button_name' => 'Bookmarks',
			'icon_fa_glyph' => 'fa-bookmark',
			# 'uri' => '/tools/'.$self->{luggage}{session}{tools}{$tool_key}{uri_path_base},
			# 'tool_type' => $self->{luggage}{session}{tools}{$tool_key}{tool_type},
		};

		$sn = 0;
		foreach $tool_id (@{ $bookmark_broker->{bookmarked_tool_keys} }) {
			$tools{menu}[$n]{sub_menus}[$sn] = {
				'name' => $self->{luggage}{session}{tools}{$tool_id}{name},
				'button_name' => $self->{luggage}{session}{tools}{$tool_id}{button_name},
				'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_id}{icon_fa_glyph}, # from font-awesome glyphs
				# 'uri' => '/tools/'.$self->{luggage}{session}{tools}{$tool_key}{uri_path_base},
				# 'tool_type' => $self->{luggage}{session}{tools}{$tool_key}{tool_type},
			};

			foreach $bm (@{ $bookmark_broker->{bookmark_keys_by_tool}{$tool_id} }) {
				push(@{$tools{menu}[$n]{sub_menus}[$sn]{bookmarks}},{
					'name' => $bookmark_broker->{bookmarks}{$bm}{saved_name},
					'button_name' => $bookmark_broker->{bookmarks}{$bm}{saved_name},
					'uri' =>  '/tools/'.$self->{luggage}{session}{tools}{$tool_id}{uri_path_base}.'/bkmk'.$bm,
					'tool_type' => $self->{luggage}{session}{tools}{$tool_id}{tool_type},
				});
			}

			$sn++;
		}

		# for below
		$n = 1;
	}

	# the screens are ordered when pulled in the session class, so cyle thru those
	foreach $tool_key (@{ $self->{luggage}{session}{tools_keys} }) {
		next if $self->{luggage}{session}{tools}{$tool_key}{link_type} =~ /Hidden/;
		$tools{menu}[$n] = {
			'name' => $self->{luggage}{session}{tools}{$tool_key}{name},
			'button_name' => $self->{luggage}{session}{tools}{$tool_key}{button_name},
			'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_key}{icon_fa_glyph}, # from font-awesome glyphs
			'uri' => '/tools/'.$self->{luggage}{session}{tools}{$tool_key}{uri_path_base},
			'tool_type' => $self->{luggage}{session}{tools}{$tool_key}{tool_type},
		};
		# i am sorry for how deep these structures get
		foreach $child_tool_key (@{ $self->{luggage}{session}{tools}{$tool_key}{child_tools_keys} }) {
			# only menubar actions
			next if $self->{luggage}{session}{tools}{$child_tool_key}{link_type} ne 'Menubar';
			# add to the object # {$tool_key}{child_tools}
			push(@{$tools{menu}[$n]{child_tools}},{
				'name' => $self->{luggage}{session}{tools}{$child_tool_key}{name},
				'button_name' => $self->{luggage}{session}{tools}{$child_tool_key}{button_name},
				'uri' => '/tools/'.$self->{luggage}{session}{tools}{$child_tool_key}{uri_path_base},
				'tool_type' => $self->{luggage}{session}{tools}{$child_tool_key}{tool_type},
			});
		}
		# stuff it into our array of hashes
		$n++;
	}

	# send it out...will be sent out via mr_zebra, who will convert it to JSON
	return \%tools;
}

# method to send out a system-level template for client-side processing in Jemplate (see utility_belt.pm notes)
# 'system-level' means it lives in $ENV{OTHOME}/code/omnitool/static_files/templates
# update: relenting; you can pass 'jemplates/file_name.tt' to use something in your app-level directory
sub send_jemplate {
	my $self = shift;

	# allow an argument to override $self->{luggage}{params}{jemplate} for calling from another method
	my ($jemplate_file) = @_;

	$self->{luggage}{params}{jemplate} = $jemplate_file if $jemplate_file;

	# okay, okay, let's relent and allow for application-specific jemplates to be called in
	# via application_extra_skeleton_classes.tt
	if ($self->{luggage}{params}{jemplate} =~ /jemplates\//) {
		my $app_inst = $self->{luggage}{app_inst};
		my $app_code_directory = $self->{luggage}{session}{app_instance_info}{app_code_directory};

		# the utility belt does all the heavy lifting ;)
		return $self->{luggage}{belt}->jemplate_process(
			'template_file_paths' => [ $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/'.$self->{luggage}{params}{jemplate} ],
			# 'stop_here' => 1,
		);

	# otherwise, send the system file, if specified
	} elsif ($self->{luggage}{params}{jemplate}) {
		# the utility belt does all the heavy lifting ;)
		return $self->{luggage}{belt}->jemplate_process(
			'template_file_paths' => [ $self->{luggage}{params}{jemplate} ],
			# 'stop_here' => 1,
		);
	# error if no file specified
	} else {
		$self->{luggage}{belt}->mr_zebra("ERROR: Please specify 'jemplate' param for send_jemplate().",1);
	}

}

# method to output some instance information from our session
sub get_instance_info {
	my $self = shift;

	my ($info_hashref, $default_tool, $random_string, $bookmark_broker);

	# for the 'client_connection_id' below
	$random_string = $self->{luggage}{belt}->random_string(20);

	# oh, if it could all be this easy
	$info_hashref = {
		'instance_title' => $self->{luggage}{session}->{app_instance_info}{inst_name},
		'hostname' => $self->{luggage}{session}->{app_instance_info}{hostname},
		'username' => $self->{luggage}{session}->{user},
		'user_fullname' => $self->{luggage}{session}->{their_name},
		'contact_email' => $self->{luggage}{session}{app_instance_info}{inst_contact},
		'instance_description' => $self->{luggage}{session}->{app_instance_info}{inst_description},
		'appwide_search_function' => $self->{luggage}{session}->{app_instance_info}{appwide_search_function},
		'session_created' => $self->{luggage}{session}->{created},
		# 'default_tool' => '/tools/'.$self->{luggage}{session}{tools}{$default_tool}{uri_path_base},
		# every client does need a unique fingerprint for its connection, beyond
		# the authentication cookie.  Really, we are talking about a fingerprint
		# for a specific browser tab/window; consider each window its own connection
		# we will create that here and pass it back for use in omnitool_routines.ks
		'client_connection_id' => $self->{luggage}{username}.time().$random_string,
		# hard to imagine one user getting the same random 20-character strings in the same second
	};

	# figure out the default tool
	# see if they have a default bookmark
	$bookmark_broker = omnitool::common::bookmark_broker->new(
		'luggage' => $self->{luggage},
		'db' => $self->{db},
	);
	$$info_hashref{default_tool} = $bookmark_broker->fetch_default_bookmark_uri;
	# if it's still blank, we go with the first tool by order
	if (!$$info_hashref{default_tool}) {
		$default_tool = $self->{luggage}{session}{tools_keys}[0];
		$$info_hashref{default_tool} = '/tools/'.$self->{luggage}{session}{tools}{$default_tool}{uri_path_base};
	}

	return $info_hashref;
}

# method to load all the javascript classes used by this application
# we do this here to avoid loading and reloading via complex AJAX
# called at the bottom of our HTML skeleton
sub tools_javascript_classes {
	my $self = shift;

	# declare our vars
	my (@all_tool_uris, $tool_uri, $app_inst, %done, $system_javascripts, $app_directory, $app_javascripts, $javascript_content, $tool_key, $javascript_class);

	# set up system-wide location
	$system_javascripts = $ENV{OTHOME}.'/code/omnitool/static_files/javascript/';

	# setup location for this application
	$app_directory = $self->{luggage}{session}->{app_instance_info}{app_code_directory};
	$app_javascripts = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_directory.'/javascript/';

	# start it off right so it goes out well
	$javascript_content = "// This is Javascript, Mr. Zebra.\n";

	# load up any application-wide javascript, which should be in application_wide_functions.js
	# under $app_javascripts
	if (-e $app_javascripts.'application_wide_functions.js') {
		$javascript_content .= "\n".read_file($app_javascripts.'application_wide_functions.js');
	}

	# now cycle through the tools and put together a huge JS glob to send out
	# use 'uris_to_tools' to make sure we 100% of all of the tools
	@all_tool_uris = keys %{ $self->{luggage}{session}{uris_to_tools} };
	foreach $tool_uri (@all_tool_uris) {
		$tool_key = $self->{luggage}{session}{uris_to_tools}{$tool_uri};

		$javascript_class = $self->{luggage}{session}{tools}{$tool_key}{javascript_class}.'.js';

		# skip if blank or 'None' or we already loaded it
		next if !$javascript_class || $javascript_class eq 'None' || $done{$javascript_class};

		# is it in the standard location?
		if (-e $system_javascripts.$javascript_class) {
			$javascript_content .= "\n// ".$system_javascripts.$javascript_class;
			$javascript_content .= "\n".read_file($system_javascripts.$javascript_class);

		# or is it app-specific?  Notice the system classes win
		} elsif (-e $app_javascripts.$javascript_class) {
			$javascript_content .= "\n// ".$app_javascripts.$javascript_class;
			$javascript_content .= "\n".read_file($app_javascripts.$javascript_class);

		}

		# track that it's done
		$done{$javascript_class} = 1;
	}

	# send it to our client browser
	return $javascript_content;

}

# method to send out the appropriate menubar/navar template
sub menubar_template {
	my $self = shift;

	# if we are using top_menu_skeleton.tt, we need to use ui_menu_top.tt for menubar_template
	my $menubar_template = 'ui_menu.tt'; # all others use the plain version
	if ($self->{luggage}{session}{app_instance_info}{ui_template} eq 'top_menu_skeleton.tt') {
		$menubar_template = 'ui_menu_top.tt';
	}

	# we will use jemplate_process() from our utility belt, making sure the jemplate
	# is called 'ui_menu.tt' on the client
	my $template_content = read_file($ENV{OTHOME}.'/code/omnitool/static_files/system_wide_jemplates/'.$menubar_template);

	return $self->{luggage}{belt}->jemplate_process(
		'template_content' => $template_content,
		'template_name' => 'ui_menu.tt',
		# 'stop_here' => 1,
	);
}


# empty destructor, to avoid AUTOLOAD being the desctructor
sub DESTROY {
	my $self = shift;
}

# provide for an AUTOLOAD, and possibly send out a jemplate for it if called via /ui/special_method
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	# figure out the method they tried to call
	my $called =  $AUTOLOAD =~ s/.*:://r;

	# perhaps they want one of our special Jemplates
	# here is our dispatch table for that
	my $jemplate_methods = {
		'full_screen_form' => 'full_screen_form.tt',
		'form_elements_template' => 'form_elements.tt',
		'breadcrumbs_template' => 'breadcrumbs.tt',
		'complex_fields_template' => 'complex_fields.tt',
		# 'inline_action_buttons_template' => 'inline_action_buttons.tt',
		'inline_action_menu_template' => 'inline_action_menu.tt',
		'system_modals_template' => 'system_modals.tt',
		'advanced_search_and_sort_template' => 'advanced_search_and_sort.tt',
		'modal_parts_template' => 'modal_parts.tt',
		'process_any_div' => 'process_any_div.tt',
	};
	# if they called for one of these, send it out
	if ($$jemplate_methods{$called}) {
		# we will lean on our nice send_jemplate() method
		$self->send_jemplate($$jemplate_methods{$called});

	# otherwise, they called a bad method
	} else {
		# prepare a nice message
		my $message = "ERROR: No '$called' method defined for UI system.";
		# return that message
		return $message;
	}
}

1;

__END__

=head1 omnitool5::common::ui

This class provides access and support to the Web / HTML UI.  Basically, it's job is to
load up the 'skeleton' file for this Application Instance, then produce the JSON which
will be used on the client side to build the navigation menu and fill in the particulars
for the page (title, admin contact, etc.).  There are some other fun UI-supporting
methods in here as well.  This class is concerned with delivering the overall UI,
and Tool.pm will handle functions for the tools themselves.

Once a user gets past the login page, dispatcher.pm will route us here and have skeleton_html()
parse and send out the 'skeleton' HTML file, which will link to all the JS and CSS we need, as
well as to present the basic HTML layout.  These skeletons live under
$ENV{OTHOME}/code/omnitool/static_files/skeletons and please look at 'default.tt' for an example.
The system administrator selects one of the available skeleton HTML files when configuring
the Instance in the OmniTool Admin screen, and the 'send_skeleton' method here loads and returns
that HTML file.

The 'skeleton' page will link to our omnitool_routines.js and omnitool_toolobj.js JavaScript
classes, which should contain all the methods to drive the UI.  Upon page load, omnitool_routines.js
will call back to get_instance_info() here to get the Application Instance information, as well as
build_navigation() and send_jemplate() to get the navigation menu, and jQuery/Jemplate
magic will be used to round out the page before the default tool is loaded in.

Regarding Jemplate, that is my FAVORITE new thing.  It allows Template-Toolkit templates
to be used client-side via JavaScript.  We send a Jemplate.js runtime, which is required
to make this work, and our UI skeletons must all load this in right with omnitool_routines.js.
BTW, we have the load_javascript() method above for loading in JavaScripts from our 'static_files'
directory.

You can create a sub-class of ui.pm to override any of the methods here, as well as add a
'custom_build_navigation()' method (see below).  To do that, create the sub-class as
'custom_ui.pm' directly under your Applications Code Directory.  Override these methods VERY
carefully.  The true use of this feature is if you are using a custom template skeleton, other
than default.tt.  As of this writing, I have only used custom_build_navigation().

=head2 new()

Creates the ui.pm object, storing the %$luggage structure and $db obj within $self, for easy
access elsewhere.  %$luggage should contain the user's session, which is very key to building
the navigation structure.

Usage:

	$ui_obj = omnitool::common::ui-new(
		'luggage' => $luggage,	# %$luggage hash; required, can't leave home without your luggage
		'db' => $db, # optional; alternative database object; will default to $$luggage{db}
		'use_file' => $skeleton_html_file, # optional; filename of the the HTML skeleton, with or
							# without the '.tt';
							# defaults to the file chosen for the current application/instance
							# and failing that, 'default.tt'. Those files exist under
							# $OTPERL/ui/skeletons directory.
	);

=head2 skeleton_html()

Loads and returns a UI skeleton file, ready to send to the client;

Usage:

	$skeleton_html = $ui_obj->skeleton_html($skeleton_html_file);

Where $skeleton_html_file is optional and would be the filename of an alternative HTML file,
with or without the '.tt'.  If blank, will default to the file specified in new() above,
and next to the file chosen for the current Application Instance, and if nothing else,
'default.tt'.

=head2 load_javascript()

Loads and returns a JavaScript class (aka a file), which shall be stored under the
$OTPERL/static_files/javascript.  We are especially handling JavaScript files this way in
order to keep them away from folks who do not have access to the Application for which
they are meant to use; this is because they probably will have URLs and API hints in them.

Usage:

	$some_javascript_code = $ui_obj->load_javascript($javascript_file);

=head2 build_navigation()

Builds a array of hashes with the navigation links using the user'ss session
in $self->{luggage}{session}.

Will first try to run custom_build_navigation() if you have set up a custom_ui.pm class,
and if that doesn't exist or doesn't return anything, it will continue with the standard
navigation build.

Usage:

	$navigation_arrayref = $ui_obj->build_navigation();

The format of the created structure will be:

	$navigation_arrayref = [
		{
			'name' => "Some Screen Name",
			'button_name' => 'Screen Name',
			'icon_fa_glyph' => 'icon_name', # from font-awesome glyphs
			'uri_path_base' => '/screens/screen_uri_path_base',
			'actions' => [
				{
					'name' => 'Action 1 Name',
					'uri_path_end' => '/ot/screen_uri/action_one_uri',
				},
				{
					'name' => 'Action 2 Name',
					'uri_path_end' => '/ot/screen_uri/action_two_uri',
				},
			],
		},
	];

So it is an array of hashes, each possibly containing a second-level array of hashes.  A bit
complex, but hopefully translates to a top-menu of screens with a secondary menu for the
screen action links which translate to sub-menu items.

This structure will get encoded into JSON when it's delivered via mr_zebra() in the utility_belt
class.

=head2 get_instance_info()

Builds a simple hashref of information about the Instance we're running, for filling-out the UI
Skeleton.  Uses the goodies in $self->{luggage}{session}.  Usage:

	$info_hashref = $ui_obj->get_instance_info();

The resulting structure will look like:

	$info_hashref = {
		'instance_title' => 'Instance Title / Name',
		'hostname' => 'some_hostname.omnitool.org',
		'username' => 'their_username',
		'user_fullname' => 'Their Name',
		'contact_email' => 'instance_contact@somedomain.com',
		'instance_description' => 'Description of instance',
	};

=head2 send_jemplate($jemplate_file);

Sends out a Jemplate template file from under $ENV{OTHOME}/code/omnitool/static_files/jemplates via
jemplate_process() in the utility_belt.pm class.  Meant for you to easily request system-wide
jemplates.  The $jemplate_file arg is for when this is called from another subroutine/method.
Otherwise, it relies on the 'jemplate' CGI param being filled in.

Please note some of the 'false' methods created in AUTOLOAD() which utilize send_jemplate() to
send out some system-wide Jemplates.

How about a nice update?  You can call in your application-specific Jemplates by prepending
'jemplates/' to the filename you send.  So you can add something like this to your
application_extra_skeleton_classes.tt file (which is under $app_code_directory/javascript):

<script src="/ui/send_jemplate?jemplate=jemplates/my_great_jemplate.tt[%uri_base_param_amp%]"></script>

Substituting out 'my_great_jemplate.tt' for the filename.  Make sure that file only contains a
[% BLOCK %] of Jemplate goodness to be used in your custom Tool View Mode Jemplates or via
custom JavaScript like this:

	data.block_name = 'my_great_jemplate_block';
	jemplate_bindings['process_any_div'].element_id = '#target_div_id';
	jemplate_bindings['process_any_div'].process_json_data(data);

Nice and easy ;)

=head tools_javascript_classes()

Also invoked at the bottom of the UI skeleton file.  Combines and ships back all of the static
Javascript files which are needed to drive the tools.  These are defined in the 'javascript_class'
of the 'tools' table in the Admin database.
