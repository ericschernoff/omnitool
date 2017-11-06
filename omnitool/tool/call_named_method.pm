package omnitool::tool::call_named_method;
# this runs a action-message tool using an omniclass method named for the tool's uri_base_path

## THIS IS ONLY APPROPRIATE FOR THE ACTION - MESSAGE DISPLAY TOOLS!

$omnitool::tool::call_named_method::VERSION = '1.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# run a action-message tool using an omniclass method named for the tool's uri_base_path
sub prepare_message {
	my $self = shift;

	my $tool_datacode = $self->{tool_datacode};
	my (@uri_bits) = split /\//, $self->{attributes}{uri_path_base};
	my $uri_path_base = $uri_bits[-1];

	# run the method if the omniclass package has it
	if ($self->{omniclass_object}->can($uri_path_base)) {

		# run this from the omniclass object to get our result
		$self->{json_results}{title} = $self->{omniclass_object}->$uri_path_base();

	# otherwise, throw an error
	} else {
		
		$self->{json_results}{title} = $uri_path_base.'() method not available for '.$self->{omniclass_object}->{datatype_info}{name}.' objects.';

	}



}

1;