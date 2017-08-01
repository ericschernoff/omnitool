package omnitool::tool::standard_delete;
# Acts as a tool.pm sub-class, providing the standard and very basic delete function.
# Will only delete data which does not have any 'living' children, and presents a modal
# to confirm the delete before proceeding.
#
# Most tool.pm sub-classes will live within an Application's Perl Modules directory, but this
# is a core feature of OmniTool and will available as a tool.pm class for any Application/Tool.
#
# When using this for your tools, make the 'uri_path_base' be 'delete' and be sure the Tool Typre
# is set to 'Action - Modal' Note that

$omnitool::tool::standard_delete::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# we shall do everything in the perform_action() method
sub prepare_message {
	my $self = shift;

	my ($num);

	if ($self->{omniclass_object}->{data}{name} eq 'Not Named') { # does not use name, so substitute datatype name
		$self->{omniclass_object}->{data}{name} = 'This '.$self->{omniclass_object}{datatype_info}{name};
	}

	# first step:  do not allow them to proceed if this record has living children
	if ($self->{omniclass_object}->{data}{metainfo}{children}) {
		# how many children?  will be number of commas plus one
		$num = $self->{omniclass_object}->{data}{metainfo}{children} =~ tr/,//;
		$num++;

		$self->{json_results}{error_title} = 'ERROR: Unable to Delete Record';
		$self->{json_results}{error_message} = "You are unable to delete '".$self->{omniclass_object}->{data}{name}.
			"' at this time because it contains $num subordinate records.";

	# have they confirmed delete?
	} elsif (!$self->{luggage}{params}{confirm}) {

		$self->{json_results}{title} = 'Please Confirm Deletion';
		$self->{json_results}{message} = "Are you sure you wish to delete '".$self->{omniclass_object}->{data}{name}."'?";

		# confirmation button is handled in the jemplate
		$self->{json_results}{confirm_button_text} = 'Confirm';
		$self->{json_results}{confirm_button_uri} = $self->{my_json_uri}.'?confirm=1';

		# no 'close' button in the modal
		$self->{json_results}{no_close_button} = 1;

	} elsif ($self->{luggage}{params}{confirm}) {
		$self->{json_results}{title} = $self->{omniclass_object}->{datatype_info}{name}.' Record Deleted';
		$self->{json_results}{message} = "You have successfully deleted '".$self->{omniclass_object}->{data}{name}."'.";
		# prevent gritter popup
		$self->{json_results}{no_gritter} = 1;

		# actually delete it
		$self->{omniclass_object}->delete(
			'data_code' => $self->{omniclass_object}->{data_code}
		);
	}

}

1;
