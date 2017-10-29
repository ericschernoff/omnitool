package omnitool::applications::otadmin::tools::health_check;
# present the health / status of bacground task and email processing for this instance

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to get the background task/email status for each datatype in this instance
sub perform_action {
	my $self = shift;

	my ($dt, $email_address, $task, $tasks_keys, $tasks);

	# load in the datatypes which support background tasks
	$self->{datatypes_object} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'datatypes',
		'search_options' => [{
			'support_email_and_tasks' => 'No',
			'operator' => '!=',
		}],
		'simple_query_mode' => 'name,incoming_email_account',
	);

	# prep our headings
	$self->{json_results}{results_headings} = [
		'Datatype','Completed Tasks','Error Tasks','Task Backlog',
		'Sent Emails','Error Emails','Pending Emails','Incoming Email Backlog'
	];
	$self->{json_results}{results_sub_keys} = [
		'datatype_name', 'completed_tasks', 'error_tasks', 'task_backlog',
		'sent_emails','error_emails','email_backlog','incoming_email_backlog',
	];

	# put the main omniclass object db connection onto the database for the target instance
	$self->{omniclass_object}->change_options(
		'save_to_server' => $self->{omniclass_object}->{data}{database_server_id},
		'database_name' => $self->{omniclass_object}->{data}{database_name},
	);

	# do not show the datatype data_code
	$self->{json_results}{hide_keys} = 1;

	# if no datatypes support email or background tasks, throw an error
	if (!$self->{datatypes_object}{records_keys}[0]) {
		$self->{json_results}{error_title} = 'No Datatypes Configured to Support Background Tasks and Email for this Application Instance.';
	}

	# now get this information for each of these datatypes
	foreach $dt (@{$self->{datatypes_object}->{records_keys}}) {

		# initial results values
		$self->{json_results}{results}{$dt} = {
			'datatype_name' => $self->{datatypes_object}->{records}{$dt}{name},
			'completed_tasks' => 0,
			'error_tasks' => 0,
			'task_backlog' => 0,
			'sent_emails' => 0,
			'error_emails' => 0,
			'email_backlog' => 0,
			'incoming_email_backlog' => 0,
		};

		# find the completed/error tasks for the past hour
		($tasks, $tasks_keys) = $self->{omniclass_object}->retrieve_task_details(
			'target_datatype' => $dt,
			'run_status' =>  'has_run',
			'update_time_age' => 3600,
		);
		foreach $task (@$tasks_keys) {
			if ($$tasks{$task}{status} eq 'Error') {
				$self->{json_results}{results}{$dt}{error_tasks}++;
			} else {
				$self->{json_results}{results}{$dt}{completed_tasks}++;
			}
		}

		# get the pending tasks
		($tasks, $tasks_keys) = $self->{omniclass_object}->retrieve_task_details(
			'target_datatype' => $dt,
			'run_status' =>  'will_run',
			'not_before_time' => time(),
		);
		$self->{json_results}{results}{$dt}{task_backlog} = scalar(@$tasks_keys);

		# now for emails. we do not have any fancy abstracted library for retrieving that info, so we will
		# have to do it the old-fashioned way:
		($self->{json_results}{results}{$dt}{sent_emails}) = $self->{omniclass_object}->{db}->quick_select(
			'select count(*) from '.$self->{database_name}.'.email_outbound'.qq{
			where status='Success' and target_datatype='$dt' and send_timestamp < (unix_timestamp()-3600)
		});
		($self->{json_results}{results}{$dt}{error_emails}) = $self->{omniclass_object}->{db}->quick_select(
			'select count(*) from '.$self->{database_name}.'.email_outbound'.qq{
			where status='Error' and target_datatype='$dt' and send_timestamp < (unix_timestamp()-3600)
		});
		($self->{json_results}{results}{$dt}{email_backlog}) = $self->{omniclass_object}->{db}->quick_select(
			'select count(*) from '.$self->{database_name}.'.email_outbound'.qq{
			where status='Pending' and target_datatype='$dt'
		});

		# this is the oddball: incoming emails -- most datatypes won't have this
		# determine the complete email for this datatype + app instance
		$email_address = $self->{datatypes_object}{$dt}{incoming_email_account}.'@'.$self->{omniclass_object}->{data}{hostname};
		# now do the lookup
		($self->{json_results}{results}{$dt}{incoming_email_backlog}) = $self->{omniclass_object}->{db}->quick_select(
			'select count(*) from '.$self->{database_name}.'.email_incoming'.qq{
			where status='New' and recipient = ?
		},[$email_address]);


		push(@{$self->{json_results}{results_keys}}, $dt);

	}



}

1;
