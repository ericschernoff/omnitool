package omnitool::applications::otadmin::tools::background_tasks;
# Admin tool to search / review / retry background tasks

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# method to handle the Retry and Cancel Options
sub perform_action {
	my $self = shift;

	# set some defaults
	$self->{luggage}{params}{display_limit} ||= $self->{display_options}{display_limit};
		$self->{luggage}{params}{display_limit} ||= '20';

	$self->{luggage}{params}{target_datatype} ||= $self->{display_options}{target_datatype};
		$self->{luggage}{params}{target_datatype} ||= 'all';

	$self->{luggage}{params}{record_id} ||= $self->{display_options}{record_id};
		$self->{luggage}{params}{record_id} ||= 'None';

	$self->{luggage}{params}{method_name} ||= $self->{display_options}{method_name};
		$self->{luggage}{params}{method_name} ||= 'None';

	$self->{luggage}{params}{run_status} ||= $self->{display_options}{run_status};
		$self->{luggage}{params}{run_status} ||= 'all';


	# the background_task_manager routines built into our omniclass object will power
	# this function, but the one we have is for the current instance of the OT Admin
	# database.  let's re-cycle it to work with the target database
	$self->{omniclass_object}->change_options(
		'save_to_server' => $self->{omniclass_object}->{data}{database_server_id},
		'database_name' => $self->{omniclass_object}->{data}{database_name},
	);

	# load in the datatypes which support background tasks
	$self->{datatypes_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '6_1',
		'skip_hooks' => 1,
		'search_options' => [{
			'match_column' => 'support_email_and_tasks',
			'operator' => '!=',
			'match_value' => 'No',
		}],
		'sort_column' => 'name',
		'auto_load'	=> 1,
		'load_fields' => 'name',
	);

	# if they sent a command to retry or cancel or start now, enforce it and send a nice message
	if ($self->{luggage}{params}{task} && $self->{luggage}{params}{new_status}) {

		if ($self->{luggage}{params}{new_status} eq 'Cancel') {

			$self->{omniclass_object}->cancel_task($self->{luggage}{params}{task});
			$self->{json_results}{message} = 'The Task Has Been Cancelled.';

		} elsif ($self->{luggage}{params}{new_status} eq 'Retry') {

			$self->{omniclass_object}->task_status($self->{luggage}{params}{task},'Retry');
			$self->{json_results}{message} = 'The Task Will Be Retried.';

		} elsif ($self->{luggage}{params}{new_status} eq 'Start') {

			$self->{omniclass_object}->start_now($self->{luggage}{params}{task});
			$self->{json_results}{message} = 'The Task Will Be Started Immediately.';

		}

		$self->{json_results}{gritter_skip_title} = 1;

	}

	# make sure the search executes no matter what
	$self->perform_form_action() if !$self->{luggage}{params}{form_submitted};

}

# easy method to show the error message for a task
sub view_error_message {
	my $self = shift;

	$self->{omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '5_1',
		'skip_hooks' => 1,
		'altcodes' => [$self->{display_options}{altcode}]
	);
	$self->{omniclass_object}->change_options(
		'save_to_server' => $self->{omniclass_object}->{data}{database_server_id},
		'database_name' => $self->{omniclass_object}->{data}{database_name},
	);

	my ($tasks, $tasks_keys) = $self->{omniclass_object}->retrieve_task_details(
		'task_id' => $self->{luggage}{params}{task},
	);

	my $task = $self->{luggage}{params}{task};

	my $results = {
		'modal_title' => 'Message for Task ID '.$task,
		'simple_message' => $$tasks{$task}{error_message},
	};


	return $results;
}

# let's do everything in perform_form_action();
sub perform_form_action {
	my $self = shift;

	my ($task, $dt_id, $tasks, $tasks_keys, $status, $status_styles, $delay_string, $run_time);

	# now find the tasks
	($tasks, $tasks_keys) = $self->{omniclass_object}->retrieve_task_details(
		'target_datatype' => $self->{luggage}{params}{target_datatype},
		'limit' => $self->{luggage}{params}{display_limit},
		'altcode' => $self->{luggage}{params}{record_id},
		'method' => $self->{luggage}{params}{method_name},
		'run_status' =>  $self->{luggage}{params}{run_status},
	);

	# if looking at the current / future tasks, we need to sort by soonest-to-start
	if ($self->{luggage}{params}{run_status} =~ /will_run|running/) {
		@$tasks_keys = sort {
			$$tasks{$a}{not_before_time} <=> $$tasks{$b}{not_before_time}
		} keys %$tasks;
	} # otherwise, the default order of furtherest-to-soonest is best

	# error message if no tasks
	if (!$self->{datatypes_object}->{records_keys}[0]) {
		$self->{json_results}{error_message} = 'No Datatypes Configured for Background Tasks Under This App ';
	} elsif (!$$tasks_keys[0]) {
		$self->{json_results}{error_message} = 'No Tasks Found';
	}

	$self->{json_results}{results_headings} = [
		'Task ID','Datatype','Record','For User','Method to Run','Created','Starts/ed','Status'
	];
	$self->{json_results}{results_sub_keys} = [
		'datatype_name', 'altcode', 'username', 'method', 'created','ran','status_info'
	];

	$self->{json_results}{results_keys} = $tasks_keys;

	# glyph / colors for status types
	$status_styles = {
		'Pending' => ['hourglass-start','yellow','Cancel'],
		'Retry' => ['retweet','yellow','Cancel'],
		'Running' => ['cogs','green'],
		'Completed' => ['check-square-o','blue'],
		'Cancelled' => ['times-circle','blue','Retry'],
		'Error' => ['exclamation-circle','red','Retry'],
		'Warn' => ['info-circle','orange','Retry'],
	};

	# go through each task and prepare for display
	foreach $task (@$tasks_keys) {

		# datatype name
		$dt_id = $$tasks{$task}{target_datatype};
		$$tasks{$task}{datatype_name} = $self->{datatypes_object}->{records}{$dt_id}{name};

		# display code
		$$tasks{$task}{data_code} ||= '-';

		# determine styles
		$status = $$tasks{$task}{status};

		# style the first line
		$$tasks{$task}{status_info}[0] = {
			'text' => $status,
			'glyph' => 'fa-'.$$status_styles{$status}[0],
			'class' => $$status_styles{$status}[1],
		};
		if ($status eq 'Retry' && $$tasks{$task}{auto_retried}) {
			$$tasks{$task}{status_info}[0]{text} = 'Auto-Retry';
		}

		# if it's running, show the worker and process ID's
		if ($status eq 'Running') {
			$$tasks{$task}{status_info}[1]{text} = 'Worker: '.$$tasks{$task}{worker_id};
			$$tasks{$task}{status_info}[2]{text} = 'Process: '.$$tasks{$task}{process_pid};

		# if it's completed, show how long it took to run
		} elsif ($status eq 'Completed') {
			if ($$tasks{$task}{run_seconds} > 60) { # minutes
				$run_time = sprintf("%.1f", ($$tasks{$task}{run_seconds}/60)).' mins';

			} else { # seconds
				$run_time = $$tasks{$task}{run_seconds}.' secs';
			}
			$$tasks{$task}{status_info}[1]{text} = 'Run time: '.$run_time;

		}



		# error message
		# $$tasks{$task}{status_info}[1]{text} = $$tasks{$task}{error_message} if $$tasks{$task}{error_message};
		if ($$tasks{$task}{error_message}) {
			push(@{$$tasks{$task}{status_info}},{
				'text' => 'View Message',
				'message_uri' => $self->{my_base_uri}.'/view_error_message?task='.$task,
			});
		}

		# let them retry / cancel the task?
		if ($$status_styles{$status}[2]) {
			push(@{$$tasks{$task}{status_info}},{
				'text' => 'Click to '.$$status_styles{$status}[2],
				'action_uri' => $self->{my_json_uri}.'?task='.$task.'&new_status='.$$status_styles{$status}[2]
			});
		}

		# $self->{json_results}{gritter_skip_title} = 1;

		# create and run age
		$$tasks{$task}{created} = $self->{belt}->figure_age( $$tasks{$task}{create_time} );
		if ($$tasks{$task}{update_time} && $status !~ /Pending|Retry/) {
			$$tasks{$task}{ran} = $self->{belt}->figure_age( $$tasks{$task}{update_time} );

		} elsif ($status =~ /Pending|Retry/ && $$tasks{$task}{not_before_time} >= $$tasks{$task}{update_time}) {
			$delay_string = $self->{belt}->figure_delay_time( $$tasks{$task}{not_before_time});
			$delay_string = 'Any second now...' if $delay_string eq 'Unknown';

			if ($delay_string eq 'Right now') {
				$$tasks{$task}{ran} = $delay_string;
			} else {
				$$tasks{$task}{ran}[0] = {
					'text' => $delay_string,
				};
				$$tasks{$task}{ran}[1] = {
					'text' => 'Start Now',
					'action_uri' => $self->{my_json_uri}.'?task='.$task.'&new_status=Start'
				} if $delay_string ne 'Any second now...';
			}

		} else {
			$$tasks{$task}{ran} = '-';
		}

		# add to the outgoing hash
		$self->{json_results}{results}{ $task } = $$tasks{$task};
	}

	# show the form again
	$self->{redisplay_form} = 1;

	# keep the display options
	$self->{do_not_clear_display_options} = 1;
}

# routine to prepare a form data structure and load it into $self->{json_results}
sub generate_form {
	my $self = shift;

	$self->{json_results}{form} = {
		'title' => 'Filter Background Tasks',
		'submit_button_text' => 'Search Tasks',
		# 'instructions' => qq{},
		'field_keys' => [1,2,3,4,5],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => {
			1 => {
				'title' => 'Datatype',
				'name' => 'target_datatype',
				'field_type' => 'single_select',
				'options' => {
					'all' => 'All With Background Tasks',
				},
				'options_keys' => ['all'],
				'preset' => $self->{luggage}{params}{target_datatype}
			},
			2 => {
				'title' => qq{Method Name},
				'name' => 'method_name',
				'field_type' => 'short_text',
				'instructions' => qq{'None' for all methods.},
				'preset' => $self->{luggage}{params}{method_name},
			},
			3 => {
				'title' => 'Display',
				'name' => 'display_limit',
				'field_type' => 'single_select',
				'options' => {
					'20' => '20 Tasks',
					'50' => '50 Tasks',
					'100' => '100 Tasks',
					'200' => '200 Tasks',
					'500' => '500 Tasks',
				},
				'options_keys' => ['20','50','100','200','500'],
				'preset' => $self->{luggage}{params}{display_limit}
			},
			4 => {
				'break_here' => 1,
				'title' => 'Status',
				'name' => 'run_status',
				'field_type' => 'single_select',
				'options' => {
					'all' => 'All',
					'will_run' => 'Running / Upcoming',
					'running' => 'Running Now',
					'has_run' => 'Completed / Error',
					'error' => 'Error Only',
					'warn' => 'Warn Only',
				},
				'options_keys' => ['all','will_run','running','has_run','error','warn'],
				'preset' => $self->{luggage}{params}{run_status}
			},
			5 => {
				'title' => qq{Record ID},
				'name' => 'record_id',
				'field_type' => 'short_text',
				'instructions' => qq{'None' for all records.},
				'preset' => $self->{luggage}{params}{record_id},
			},
		}
	};

	# now load those into the second field in our form
	my $dt_id;
	foreach $dt_id (@{ $self->{datatypes_object}->{records_keys} }) {
		$self->{json_results}{form}{fields}{1}{options}{$dt_id} = $self->{datatypes_object}->{records}{$dt_id}{name};
		push(@{ $self->{json_results}{form}{fields}{1}{options_keys} },$dt_id);
	}

}

1;
