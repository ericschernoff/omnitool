package omnitool::applications::otadmin::tools::start_background_tasks;
# kicks off daily background task for an instance; please see 'Instance Daily Taks'
# notes in the omniclass.pm Pod, as well as the daily_routines() method in
# omnitool::applications::otadmin::datatypes::instances

use parent 'omnitool::tool';

use strict;

# this is a read-only action, so we shall use 'prepare_message,' which
# will be picked up by action_tool.pm automatically.
sub perform_action {
	my $self = shift;

	my ($tasks, $tasks_keys, $task_id, $new_task_id);

	# we will first clear any upcoming background tasks for this instance
	# should only be one, but just in case
	($tasks, $tasks_keys) = $self->{omniclass_object}->retrieve_task_details(
		'target_datatype' => $self->{omniclass_object}->{dt},
		'altcode' => $self->{omniclass_object}->{data}{metainfo}{altcode},
		'run_status' => 'will_run',
	);

	# do the cancel(s)
	foreach $task_id (@$tasks_keys) {
		$self->{omniclass_object}->cancel_task($task_id);
	}

	# and now set up the new task and get it to run immediately
	$new_task_id = $self->{omniclass_object}->add_task(
		'method' => 'daily_routines',
		'data_code' => $self->{omniclass_object}->{data_code},
	);

	# send out a nice message
	$self->{json_results}{title} = 'Started Daily Background Tasks for '.$self->{omniclass_object}->{data}{name};
	$self->{json_results}{message} = 'Daily task routines will begin immediately and occur every 24 hours.';
}


1;
