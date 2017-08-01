package omnitool::common::bookmark_broker;

# central object to handle tool bookmarks functions needed
# for common::ui::build_navigation() and tool::bookmark_manager()
# mainly here so SQL does not get strewn in those two packages

# please see notes below

$omnitool::common::bookmark_broker::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# grow up, when possible
use strict;

# new() is the same as for common::ui; needs 'db' and 'luggage'
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

	# the table where our bookmarks live
	$args{bookmarks_table} = $args{luggage}{database_name}.'.tools_display_options_saved';

	# by now, everything should be in that %args hash
	my $self = bless \%args, $class;

	# lastly, did they want to auto-fetch the tool bookmarks?
	if ($args{auto_fetch}) {
		$self->fetch_tool_bookmarks();
	}

	return $self;
}

# first method to load up the tool bookmarks for this instance; mostly used for ui::build_navigation()
# but also called from tool::bookmark_manager()
sub fetch_tool_bookmarks {
	my $self = shift;

	# declare local vars
	my ($tool_id, $bm);

	# grab their bookmarks out from the database...should have a nice object for these
	($self->{bookmarks},$self->{bookmark_keys}) = $self->{db}->sql_hash(
		'select object_name, tool_id, default_for_tool, default_for_instance, saved_name '.
		'from '.$self->{bookmarks_table}.' where username=?',
	'bind_values' => [$self->{luggage}{username}] );

	# we need to add the tools' button_names to the bookmarks
	foreach $bm (@{$self->{bookmark_keys}}) {
		$tool_id = $self->{bookmarks}{$bm}{tool_id}; # sanity

		# if the acl's changed and they no longer have access to this tool, blank the bookmark
		if (!$self->{luggage}{session}{tools}{$tool_id}{button_name}) {
			delete($self->{bookmarks}{$bm});
			next;
		}

		# track the default bookmarks
		if ($self->{bookmarks}{$bm}{default_for_instance} eq 'Yes') {
			$self->{bookmarks}{$bm}{saved_name} .= ' **';
		}
		if ($self->{bookmarks}{$bm}{default_for_tool} eq 'Yes') {
			$self->{bookmarks}{$bm}{saved_name} .= ' *';
		}

		$self->{bookmarks}{$bm}{tool_name} = $self->{luggage}{session}{tools}{$tool_id}{button_name};
	}

	# we will re-sort the keys to be alphabetical, by tool then bookmark name
	# use method below so we can re-sort if the hash changes
	$self->sort_bookmarks();

}

# method to sort the bookmark hash keys by tool_name (button_name) and then bookmark name
sub sort_bookmarks {
	my $self = shift;

	# no need to proceed if we have not previously loaded the tool bookmarks
	return if !$self->{bookmark_keys}[0];

	@{$self->{bookmark_keys}} = sort {
		$self->{bookmarks}{$a}{tool_name} cmp $self->{bookmarks}{$b}{tool_name}
		||
		$self->{bookmarks}{$a}{saved_name} cmp $self->{bookmarks}{$b}{saved_name}
	} keys %{$self->{bookmarks}};

	# now build an hash of arrays, with keys sorted by tool_id
	my ($tool_id, $bk);
	foreach $bk (@{$self->{bookmark_keys}}) {
		$tool_id = $self->{bookmarks}{$bk}{tool_id}; # sanity
		push(@{ $self->{bookmark_keys_by_tool}{$tool_id} }, $bk);
	}

	# need that sorted too ;)
	@{$self->{bookmarked_tool_keys}} = sort {
		$self->{bookmarks}{$a}{tool_name} cmp $self->{bookmarks}{$b}{tool_name}
	} keys %{$self->{bookmark_keys_by_tool}};

}

# method to create a bookmark
sub create_bookmark {
	my $self = shift;

	# we are going to take a hash for args, as there are a few
	my (%args) = @_;
	# this should include
	#	'new_name' => 'Name for New Bookmark', # required
	#	'tool_id' => 'tool_id', # required
	#	'display_options_hash' => %$display_options_hash, # required
	#	'source_object_name' => 'object_name_from_cached_table', # required
	#	'default_for_tool' => 'Yes' or 'No', # optional -> sets default view for specific tool
	# 	'default_for_instance' => 'Yes' or 'No', # optional -> sets default view for entire instance
	# all but that last one is required.  these are coming from tool_display_options_cached
	# and the running tool driving bookmark_manager.

	# i should put in a lot of logging and testing of these, but tool::bookmark_manager
	# should be smart and call this correctly
	return if !$args{new_name} || !$args{source_object_name} || !$args{tool_id} || !$args{display_options_hash};

	# declare some vars
	my ($opt, $same_name_count, $random_string);

	# default for default_options is 0; this is what sets this as the default config for this tool
	$args{default_for_tool} ||= 'No';
	$args{default_for_instance} ||= 'No';

	# if it's the default for tool/instance, set all the others for this user/tool to not be default
	foreach $opt ('default_for_tool','default_for_instance') {
		if ($args{$opt} eq 'Yes') {
			$self->{db}->do_sql(
				'update '.$self->{bookmarks_table}." set $opt='No' where username=?",
			[
				$self->{luggage}{username}
			]);
		}
	}

	# make sure the name is unique
	($same_name_count) = $self->{db}->quick_select(
		'select count(*) from '.$self->{bookmarks_table}.
		' where username=? and tool_id=? and saved_name like ?',
	[
		$self->{luggage}{username}, $args{tool_id}, $args{new_name}.'%'
	]);
	if ($same_name_count) {
		# append the count; first one wouldn't have this
		$args{new_name} .= ' ('.$same_name_count.')';
	}

	# get a random number to append to the object_name
	$random_string = $self->{luggage}{belt}->random_string(5);

	# let's use our very nice hash-storing feature to do this
	$self->{db}->hash_cache(
		'task' => 'store',
		'hashref' => $args{display_options_hash},
		'object_name' => $args{source_object_name}.'_'.$random_string,
		'db_table' => $self->{bookmarks_table},
		'never_expire' => 1,
		'extra_fields' => {
			'username' => $self->{luggage}{username},
			'tool_id' => $args{tool_id},
			'saved_name' => $args{new_name},
			'default_for_tool' => $args{default_for_tool},
			'default_for_instance' => $args{default_for_instance},
		}
	);

	# if the bookmarks are already loaded, update the hash and re-sort the keys
	if ($self->{bookmark_keys}[0]) {
		$self->fetch_tool_bookmarks(); # taking the easy way out
	}

	# send back very nice status message, along with the new object_name
	return ("'".$args{new_name}."' Bookmark Has Been Created.",
		$args{source_object_name}.'_'.$random_string);
}

# method to remove/delete a bookmark
sub delete_bookmark {
	my $self = shift;

	# the required argument is the object_name for the target bookmark
	my ($target_bookmark) = @_;
	# should put in logging, but will depend on tool::bookmark_manager() to have its act together
	return if !$target_bookmark;

	# remove the bookmark from the database
	$self->{db}->do_sql(
		'delete from '.$self->{bookmarks_table}.' where object_name=?',
		[$target_bookmark]
	);

	# if the bookmarks are loaded, note the old name, change the hash & re-sort the keys
	my ($status_message);
	if ($self->{bookmarks}{$target_bookmark}{saved_name}) {
		# status message with old and new names
		$status_message = "'".$self->{bookmarks}{$target_bookmark}{saved_name}."' Was Deleted.";
		# change hash in place
		delete($self->{bookmarks}{$target_bookmark});
		# re-sort keys
		$self->sort_bookmarks();
	# otherwise, simple status message
	} else {
		$status_message = "Bookmark Deleted.";
	}

	# ship our status message
	return $status_message;

}

# method to rename a bookmark
sub rename_bookmark {
	my $self = shift;

	# the required arguments are the object_name for the target bookmark plus the new name
	my ($target_bookmark, $new_name) = @_;
	# should put in logging, but will depend on tool::bookmark_manager() to have its act together
	return if !$target_bookmark || !$new_name;

	# do the change
	$self->{db}->do_sql(
		'update '.$self->{bookmarks_table}.' set saved_name=? where object_name=?',
		[$new_name, $target_bookmark]
	);

	# if the bookmarks are loaded, note the old name, change the hash & re-sort the keys
	my ($status_message);
	if ($self->{bookmarks}{$target_bookmark}{saved_name}) {
		# status message with old and new names
		$status_message = "'".$self->{bookmarks}{$target_bookmark}{saved_name}."' Renamed to '".$new_name."'.";
		# change hash in place
		$self->{bookmarks}{$target_bookmark}{saved_name} = $new_name;
		# re-sort keys
		$self->sort_bookmarks();
	# otherwise, simple status message
	} else {
		$status_message = "Bookmark Renamed to '".$new_name."'.";
	}

	# ship our status message
	return $status_message;
}

# method to set a bookmark as the default for this tool
sub set_default_bookmark {
	my $self = shift;

	# the arguments is the object_name for the target bookmark
	# if the tool_id for the tool of that bookmark is filled, then we are
	# only setting the default for the tool; otherwise it's for the entire instance
	my ($target_bookmark,$tool_id) = @_;

	# should put in logging, but will depend on tool::bookmark_manager() to have its act together
	return if !$target_bookmark;

	# if tool is filled, set as default for tool
	if ($tool_id) {
		# set all the others for this user/tool to default_options='No'
		$self->{db}->do_sql(
			'update '.$self->{bookmarks_table}." set default_for_tool='No' ".
			'where username=? and tool_id=? and object_name != ?',
		[
			$self->{luggage}{username}, $tool_id, $target_bookmark
		]);

		# and then set this one as the default
		$self->{db}->do_sql(
			'update '.$self->{bookmarks_table}." set default_for_tool='Yes' ".
			'where username=? and tool_id=? and object_name=?',
		[
			$self->{luggage}{username}, $tool_id, $target_bookmark
		]);

	# otherwise, do the whole instance
	} else {
		# set all the others for this user/tool to default_options='No'
		$self->{db}->do_sql(
			'update '.$self->{bookmarks_table}." set default_for_instance='No' ".
			'where username=? and object_name != ?',
		[
			$self->{luggage}{username}, $target_bookmark
		]);

		# and then set this one as the default
		$self->{db}->do_sql(
			'update '.$self->{bookmarks_table}." set default_for_instance='Yes' ".
			'where username=? and object_name= ?',
		[
			$self->{luggage}{username}, $target_bookmark
		]);
	}

	# need a nice status message
	my ($status_message, $tool_name);
	# start it off with the name of the bookmark, if available
	if ($self->{bookmarks}{$target_bookmark}{saved_name}) {
		$status_message = "'".$self->{bookmarks}{$target_bookmark}{saved_name}."'";
		$tool_name = "'".$self->{bookmarks}{$target_bookmark}{tool_name}."'";
	# otherwise, simple status message
	} else {
		$status_message = "Bookmark";
		$tool_name = 'Tool';
	}

	# put together based on action
	if ($tool_id) {	# setting default for one tool
		$status_message .= ' Set As the Default Search/View for '.$tool_name
	} else { # setting default for whole instance
		$status_message .= " Set As the Default Tool/View for '".$self->{luggage}{session}->{app_instance_info}{inst_name}."'";
	}

	# ship our status message
	return $status_message;

}

# routine to grab the uri for the default bookmark, if there is one
sub fetch_default_bookmark_uri {
	my $self = shift;

	my ($object_name,$tool_id) = $self->{db}->quick_select(
		'select object_name,tool_id from '.$self->{bookmarks_table}.
		" where username=? and default_for_instance='Yes'",
		[$self->{luggage}{username}]
	);

	# return text if there is a bookmark for this user, and they still have access to the tool
	if ($object_name && $self->{luggage}{session}{tools}{$tool_id}{uri_path_base}) {
		return '/tools/'.$self->{luggage}{session}{tools}{$tool_id}{uri_path_base}.'/bkmk'.$object_name;
	} else { # return nothing
		return ;
	}

}

1;

__END__

=head1 omnitool::common::bookmark_broker

It's very likely you won't need to use this documentation, unless you are fixing a bug with the
'Bookmark/Share' functions, so thank you in advance ;)

This module exists to save / modify display options records into the 'tools_display_options_saved'
tables in the various intstances' MySQL databases.  This module works in conjunction with
omnitool::tool::bookmark_manager, the 'system_modals.tt' Jemplate and omnitool_bookmarks.js
(both under 'static_files') to provide bookmarking of Tools with display/view criteria within 
the Web UI.  This behavior is described a bit more in the POD notes for tool.pm, under the 'Tool
Display Options and Bookmarks' heading.

The 'bookmark_manager()' routine inside bookmark_manager.pm sends commands to this class.  I
opted to separate these functions out because (a) SQL is only allowed under omnitool::common::
and omnitool::omniclass:: and (b) we should leave the door open to using these is a bit of a
different way later, i.e. perhaps there may be a bookmark-lookup API or tool in the future.  You
would say that this bookmark_broker.pm class is the Model, bookmark_manager.pm and omnitool_bookmarks.js
combine to be the Controller and system_modals.tt is the View.

The interface to create and manage bookmarks is kind of a mini-tool or sub-tool within the system.
It can't be a full-fledged Tool, because we need to note the current active Tool and use its
current display options to save, and thus we can't change the URI hash.  Also, it would be a bit
much for the Tools' saved options to be full-fledged OmniClass datatypes - although it would
probably be pretty cool ;)  In any event, this sub-tool should be the only such monster in
the system; all other UI areas should be configured as Tools in OmniTool Admin.

The Tool Bookmarks created with this class are primarily used in omnitool::common::ui::build_navigation() 
to add a menu for the user's Tool Bookmarks at the very start of the navigation menu.  It does call this 
class specifically to get these bookmarks.  Also, in ui::get_instance_info(), the user's Default Tool 
Bookmark is fetched as well via this class.

The loading of these bookmarks is in omnitool::tool::display_options_manager::load_display_options(),
if the 'display_options_key' PSGI param is filled in. That param will be filled in the Object Factory if the
location hash includes a arg starting with 'bkmk'.  It will make more sense if you look at the 'Bookmark/Share'
menu in the upper-right of the Web UI.

Here is our useage information:

=head2 new()

To create a new instance of this class:

	$bookmark_broker = omnitool::common::bookmark_broker->new(
		'luggage' => $luggage, # required; the usual %$luggage from omnitool::common::pack_luggage
		'db' => $db, # required; a omnitool::common::db object for this instance
		'auto_fetch' => 1, 	# optional; if filled, fetch_tool_bookmarks() will be called to
						# load in the bookmarks (see below)
	);

=head2 fetch_tool_bookmarks()

To load the hash of Tool Bookmarks for this user/app instance combination:

	$bookmark_broker->fetch_tool_bookmarks();

Loads up the bookmarks' names, tool names, and default-for-tool/default-for-instance status ('Yes'
or 'No') into $bookmark_broker->{bookmarks}.

Will automatically call sort_bookmarks() to load an arrayref of keys of $bookmark_broker->{bookmarks}
into $bookmark_broker->{bookmark_keys}, sorted by the {tool_name} then {saved_name} entries, so
that you can easily present the Bookmarks as 'Tool Name: Bookmark name'.  ('saved_name' is the name
of the bookmark).

This hashref is suitable for preparing menus and select options.

=head2 sort_bookmarks()

Automatically used to get sorted keys as per above; only useful in other code if you change the
$bookmark_broker->{bookmarks} hash somewhere in your code.  Usage

	$bookmark_broker->sort_bookmarks();

Loads up sorted keys into @{ $bookmark_broker->{bookmark_keys} }.

=head2 fetch_default_bookmark_uri

Constructs and returns a URI for this user's default Tool Bookmark for the curent Application Instance.
Returns empty if no such default bookmark is set up for this user.

Usage:

	$default_uri = $bookmark_broker->fetch_default_bookmark_uri();

Example of $default_uri might be '/tools/calendar/view/bkmkjdoe_1452997559B045A6167FC6756B82E5_1_1_1338A'.
Notice no hash mark.

=head2 create_bookmark()

Saves the current display options for the current Tool into the 'tools_display_options_saved' table for
the Instance as a Tool Bookmark.  Once it creates the new Tool Bookmark, it will run fetch_tool_bookmarks()
to load up $bookmark_broker->{bookmarks} and return two items:  A status message indicating success and
the object_name value for the newly-created Bookmark.

Example usage:

	($status_message,$new_object_name) = $bookmark_broker->create(
		'new_name' => 'Name for New Bookmark', # required
		'tool_id' => 'primary_key_of_assocatied_tool', # required
		'display_options_hash' => %$display_options_hash, # required; from $self->{display_options} in tool.pm object
		'source_object_name' => 'object_name_from_tools_display_options_cached_table', # required
		'default_for_tool' => 'Yes' or 'No', # optional -> sets default view for specific tool; defailt is 'No'
		'default_for_instance' => 'Yes' or 'No', # optional -> sets default view for entire instance; default is 'No'
	);

All but the last one is required.

=head2 rename_bookmark()

Updates the 'saved_name' column for the desired Tool Bookmark's record in tools_display_options_saved.
Takes 'object_name' for target bookmark and desired new name, both arguments required

Example usage:

	$object_name = 'eric1452997559B045A6167FC6756B82E5_1_1_1338A';
	$new_name = 'Ginger Feats of Strength.';
	$status_message = $bookmark_broker->rename_bookmark($object_name,$new_name);

$status_message will indicate that the bookmark's name had been updated.

=head2 set_default_bookmark()

Used to set a Tool Bookmark as the default view for either its associated Tool or the entire
Application Instance.  If set for the Instance, then the next time the user comes to the Instance
via a plain URI (no location hash), this Tool Bookmark's associated Tool and display
options will be loaded.

Required first argument is the object_name of the target Tool Bookmark, and optional second
argument is the primary key of the Bookmark's associated Tool.  If the second argument is
left off, the Bookmark will be the user's default for the whole Instance; otherwise, set as
user's default just for visiting that Tool.

Example Usage:

	$object_name = 'eric1452997559B045A6167FC6756B82E5_1_1_1338A';

	# To set as default for one Tool:
	$status_message = $bookmark_broker->set_default_bookmark($object_name,'9_1');

	# To set as default for the Instance:
	$status_message = $bookmark_broker->set_default_bookmark($object_name);


=head2 delete_bookmark()

Removes the target Tool Bookmark from the current Instance's tools_display_options_saved table.
Only argument is the target bookmark's object_name value, which is required.  Returns a status
message indicating success.  If fetch_tool_bookmarks() has been called, will remove the
deleted bookmark's sub-hash from $bookmark_broker->{bookmarks} and call the sort_bookmarks()
method again.

Example usage:

	$object_name = 'eric1452997559B045A6167FC6756B82E5_1_1_1338A';
	$status_message = $bookmark_broker->delete_bookmark($object_name);





