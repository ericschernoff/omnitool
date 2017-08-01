package omnitool::tool::bookmark_manager;
# routines to support the bookmarking of screen tools.  Doesn't work well at all
# with messages or modals, and we really care about bookmarking searches more than
# anything.
# This is sort of a sub-tool, but it must be universal and not actually change the
# location.hash.  Will drive a modal (and jemplate) triggered from a link in the 
# top navbar, next to the instance-changing menu.  

# kind of the third time around for this one
$omnitool::tools::bookmark_manager::VERSION = '6.0';

# this common package does the heavy lifting
use omnitool::common::bookmark_broker;

# time to grow up
use strict;

sub bookmark_manager {
	my $self = shift;
	
	# dev code, to be deleted
	# $self->{json_results}{facts} = ['Ginger is the best!','Pepper is a good dog too.','I love Lorelei'];

	# declare your vars
	my ($bookmark_broker, $status_msg,$new_bookmark_object_name, $opt);

	# we are going to let the jemplate do its part
	# we want to respond to the save / share / rename / delete / make-default requests
	# and then just provide a list of the bookmarks for this instance
	
	# we need the bookmark_broker under common
	$bookmark_broker = omnitool::common::bookmark_broker->new(
		'luggage' => $self->{luggage},
		'db' => $self->{db},
	);
	
	# first, save off a new bookmark if they provided the name
	# use separate routine below
	if ($self->{luggage}{params}{new_bookmark_name}) {
		# default for make default choices is No
		foreach $opt ('new_bookmark_make_default_tool','new_bookmark_make_default_instance') {
			if (!$self->{luggage}{params}{$opt} || $self->{luggage}{params}{$opt} eq 'false') {
				$self->{luggage}{params}{$opt} = 'No';
			} else {
				$self->{luggage}{params}{$opt} = 'Yes';			
			}
		}
		
		($status_msg,$new_bookmark_object_name) = $bookmark_broker->create_bookmark(
			'new_name' => $self->{luggage}{params}{new_bookmark_name},
			'tool_id' => $self->{tool_datacode},
			'display_options_hash' => $self->{display_options},
			'source_object_name' => $self->{display_options_key},
			'default_for_tool' => $self->{luggage}{params}{new_bookmark_make_default_tool},
			'default_for_instance' => $self->{luggage}{params}{new_bookmark_make_default_instance},
		);
		$self->{json_results}{new_bookmark_object_name} = $new_bookmark_object_name;
	}
	
	# rename a bookmark if they requested as such
	if ($self->{luggage}{params}{rename_bookmark} && $self->{luggage}{params}{bookmark_name}) {
		$bookmark_broker->rename_bookmark($self->{luggage}{params}{rename_bookmark},$self->{luggage}{params}{bookmark_name});
		$self->{json_results}{rename_result} = "Bookmark Renamed to '".$self->{luggage}{params}{bookmark_name}."'.";
	}
	
	# make a new bookmark the default for an user/instance
	if ($self->{luggage}{params}{form_action} eq 'make_default_for_instance') {
		$self->{json_results}{status_message} = $bookmark_broker->set_default_bookmark($self->{luggage}{params}{target_bookmark});
	}
	# or for the individual tool
	if ($self->{luggage}{params}{form_action} eq 'make_default_for_tool') {
		$self->{json_results}{status_message} = $bookmark_broker->set_default_bookmark($self->{luggage}{params}{target_bookmark}, $self->{tool_datacode});
	}

	
	# delete a bookmark if they requested (and confirmed) that
	if ($self->{luggage}{params}{delete_bookmark}) {
		$self->{json_results}{delete_result} = $bookmark_broker->delete_bookmark($self->{luggage}{params}{delete_bookmark});
	}

	# if they passed 'fetch_bookmarks', then they need the bookmarks/keys for the manage bookmarks dialog
	# do this last, in case we got some instruction above
	if ($self->{luggage}{params}{fetch_bookmarks}) {
		$bookmark_broker->fetch_tool_bookmarks();
		# prepare for shipping
		$self->{json_results}{bookmarks} = $bookmark_broker->{bookmarks};
		$self->{json_results}{bookmark_keys} = $bookmark_broker->{bookmark_keys};
	}

	# will need this for passing into the 'execute_function_on_load' function
	$self->{json_results}{the_tool_id} = $self->{tool_and_instance};
	
	# send out; dispatcher.pm will throw to mr_zebra(), who will send out as json
	return $self->{json_results};
	
}

1;
