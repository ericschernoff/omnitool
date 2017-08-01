package omnitool::applications::sample_apps::tools::search_books;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# generate options for authors names for advanced search
sub author_filter_menu {
	my $self = shift;

	# arg is the reference to the menu for which we are building options
	my ($this_tool_filter_menu) = @_;

	# load up all the authors in one action
	# this is reasonably fast because there are only 125 of them
	my $authors_object = $self->get_omniclass_object(
		'dt' => 'authors',
		'data_codes' => ['all'],
		'skip_metainfo' => 1,
	);
	

	($$this_tool_filter_menu{options}, $$this_tool_filter_menu{options_keys}) =
		$authors_object->prep_menu_options();
	
	# $this_tool_filter_menu memory reference updated in place, no need to return

}


1;
