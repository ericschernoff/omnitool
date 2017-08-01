package omnitool::applications::sample_apps::tools::present_web_documents;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to present one of the pages of the www.omnitool.org site, which are
# stashed in the tool description
sub perform_action {
	my $self = shift;

	# return the title and content
	$self->{json_results}{title} = $self->{omniclass_object}->{data}{name};
	$self->{json_results}{html_content} = $self->{attributes}{description};

	# hide the title
	$self->{json_results}{no_title} = 1;

}

1;

