package omnitool::applications::otadmin::tools::active_sessions;
# drive the Active Sessions Count action tool

use parent 'omnitool::tool';

use strict;

# this is a read-only action, so we shall use 'prepare_message,' which
# will be picked up by action_tool.pm automatically.
sub prepare_message {
	my $self = shift;
	my ($right_db_obj, $active_session_count);

	# we need to make sure we are connected to the right database server
	# we have that in the utility $self->{belt} for frequent use
	$right_db_obj = $self->{belt}->get_instance_db_object($self->{omniclass_object}->{data_code}, $self->{db});

	# retrieve the active session count for this application instance
	($active_session_count) = $right_db_obj->quick_select(
		'select count(*) from otstatedata.omnitool_sessions where app_instance=?',
		[$self->{omniclass_object}->{data_code}]
	);
	
	# fill in the needed info for the return object
	$self->{json_results}{title} = 'Active Session Count for '.$self->{omniclass_object}->{data}{name}.' ('.$self->{omniclass_object}->{data}{hostname}.')';
	$self->{json_results}{message} = 'Currently, there are '.$active_session_count.' active sessions in this App Instance.';
	
}

1;