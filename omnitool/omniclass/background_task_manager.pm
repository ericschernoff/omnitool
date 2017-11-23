package omnitool::omniclass::background_task_manager;
=cut

Manages and performs background tasks to be completed for objects.
These background tasks are to be handled by methods in your OmniClass Packages,
and the methods below simply create / track / complete these instructions,
which are stored in the 'background_tasks' table in the app's database.

These methods are provided:

	add_task()
	cancel_task()
	task_status()
	do_task()
	get_next_task_info()

More notes on how to use these are in omniclass.pm.  Please also see background_tasks_forking.pl
under $OTPERL/scripts

=cut

# TODO: Add wisecrack
$omnitool::omniclass::background_task_manager::VERSION = '6.0';

# for storing / retrieving data structures via the hash_cache() method
use Storable qw( nfreeze thaw dclone );

# time to grow up
use strict;

# for re-packing luggage when changing users
use omnitool::common::luggage;

# method to create a task
sub add_task {
	my $self = shift;

	# grab arguments
	my (%args) = @_;
	# looks like
	# 'method' => the method in your OmniClass Package which will be performed in the background
	# 'data_code' => the primary key of the target data record; optional, as maybe you
	#					need to affect all data of a certain type within an application
	# 'delay_hours' => number of hours from now to wait before performing task; the background
	#					script may perform it a bit later than these number of hours due to a
	#					backlog, but it will not do so before these hours have past
	#					optional, and default is 0; can be a decimel (i.e. .25 for 15 minutes)
	# 'not_before_time' => optional; unix epoch for the earliest time this task should run; overrides
	#						'delay_hours' argument
	# 'args_hash' => a hash reference of arguments to pass to the method we are calling; optional

	# only allow the background task if this datatype supports them
	if ($self->{datatype_info}{support_email_and_tasks} eq 'No') {
		$self->{belt}->logger('ERROR: Could not add task. '.$self->{datatype_info}{name}.' does not support background tasks and email.','task_errors');
		return;
	}

	# fail out if we did not get a valid 'method' argument
	if (!$args{method} || !$self->can($args{method})) {
		$self->{belt}->logger('ERROR: Could not add task. Invalid method: '.$args{method},'task_errors');
		return;
	}

	# really set delay_hours to 0 if blank
	$args{delay_hours} ||= 0;

	# if they passed a unix epoch in the future for 'not_before_time,' use that
	if ($args{not_before_time} < time()) { # otherwise, calculate
		$args{not_before_time} =  time() + ($args{delay_hours} * 3600);
	}

	# if they passed an args_hash, serialize it
	my ($serialized_hash, $cloned_hash);
	if ($args{args_hash}) {
		$cloned_hash = dclone($args{args_hash});
		$serialized_hash = nfreeze($cloned_hash);
		# could be anything in there, i know.  that's ok
	} else {
		# set to blank
		$serialized_hash = 'None';
	}

	# if there's a data-code, we also want the altcode for making admins' lives easier
	my $this_altcode = 'None'; # default
	if ($args{data_code}) {
		$this_altcode = $self->data_code_to_altcode($args{data_code});
	}

	# we need to avoid duplicate tasks scheduled in the future for the same record
	if ($args{data_code}) {
		my ($tasks,$tkeys) = $self->retrieve_task_details(
			'target_datatype' => $self->{dt},
			'altcode' => $this_altcode,
			'method' => $args{method},
			'run_status' => 'will_run',
		);
		foreach my $task (@$tkeys) {
			$self->cancel_task($task);
		}
	}

	# now add it in to our background_tasks table
	$self->{db}->do_sql(
		'insert into '.$self->{database_name}.'.background_tasks'.
		qq{(server_id, create_time, username, status, not_before_time, target_datatype, method, data_code, altcode, args_hash)}.
		qq{ values (?, unix_timestamp(), ?, 'Pending', ?, ?, ?, ?, ?, ? ) },
		[ $self->{server_id}, $self->{luggage}{username}, $args{not_before_time}, $self->{dt},
			$args{method}, $args{data_code}, $this_altcode, $serialized_hash ]
	);

	# return the new task ID
	return  $self->{db}->{last_insert_id}.'_'.$self->{server_id};
}

# method to cancel a task
sub cancel_task {
	my $self = shift;

	# one required argument is the primary key of the task to cancel
	my ($cancel_task_id) = @_;

	# fail without that
	if (!$cancel_task_id) {
		$self->{belt}->logger('ERROR: No task sent to cancel_task()','task_errors');
		return;
	}

	# do the update
	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.background_tasks'.
		qq{ set status='Cancelled' where concat(code,'_',server_id)=?},
		[$cancel_task_id]
	);

	# success!
	return 1;
}

# nice method to cancel all future occurrences of a background task for a particular record
# requires two args: data_code and method_name
# will only cancel tasks that are Pending and Retry status, to keep the historical record
sub cancel_task_for_record_and_method {
	my $self = shift;

	# botharguments are required
	my ($data_code, $method_name) = @_;

	# fail without those
	if (!$data_code || !$method_name) {
		$self->{belt}->logger('ERROR: Unable to run cancel_task_for_record_and_method() without data_code and method_name.','task_errors');
		return;
	}

	my ($task, $upcoming_task_ids);

	# get the task ID's
	$upcoming_task_ids = $self->{db}->list_select(
		qq{select concat(code,'_',server_id) from }.$self->{database_name}.'.background_tasks'.
		qq{
			where status in ('Pending','Retry') and target_datatype=?
			and data_code=? and method=?
		},
		[ $self->{dt}, $data_code, $method_name ]
	);

	# go through and cancel them
	foreach $task (@$upcoming_task_ids) {
		$self->cancel_task($task);
	}

	# just that easy
}


# method to get the task ID and method name for the next task to be executed for a specific record
# either pass in a $data_code or looks for one loaded record.
sub get_next_task_info {
	my $self = shift;

	my ($data_code,$include_running) = @_;

	# if no $data_code was sent, see if we have one record loaded
	if (!$data_code && $self->{data_code}) {
		$data_code = $self->{data_code};
	}

	# no $data_code? then no nothing
	return ('ERROR: Data Code Required') if !$data_code;

	# if they want the running tasks, they are doing a check for UI purposes
	my $statuses = qq{'Pending','Retry'};
	if ($include_running) {
		$statuses .= qq{,'Running'};
	} # otherwise, it's the script looking for its next job

	# do the query
	my ($task_id,$method) = $self->{db}->quick_select(
		qq{select concat(code,'_',server_id), method from }.$self->{database_name}.'.background_tasks'.
		qq{
			where status in ($statuses) and not_before_time <= unix_timestamp()
			and target_datatype=? and data_code=? order by code limit 1
		},
		[$self->{dt}, $data_code]
	);

	# and send it out
	return ($task_id,$method);
}

# method to get a hashref of tasks in our database; useful for the Admin Background Tasks screen
sub retrieve_task_details {
	my $self = shift;

	my (%args) = @_;
	# looks like:
	#	'target_datatype' => $id_of_datatype_to_filter_by, # default = none
	#	'limit' => $number_of_records_to_return, # default = 20
	#	'altcode' => $record_altcode, # optional: use to limit to tasks for one record
	#	'method' => $method_name, # optional: use to limit to tasks by name of method to run
	#	'run_status' => 'will_run', 'has_run', 'running', or 'error'
	# 						# leave blank for all; 'will_run' indicates running or future tasks
	#						# 'has_run' indicates Completed/Cancelled/Error tasks
	#	'update_time_age' => $number_of_seconds, # optional, use to find tasks that have been (attempted to)
	#											 # run within a certain number if seconds, i.e. 86400 for the past
	#											 # 24 hours
	#	'not_before_time' => unix_epoch_value, # optional, task 'not_berfore_time' value would be less than this epoch
	#											# makes it easier to look at items set to execute in the past vs. the future

	my ($sql, $bind_values, $tasks, $tasks_keys);

	# set detault limit if non-existent or not an integer
	$args{limit} = 20 if !$args{limit} || $args{limit} =~ /\D/;

	# design our SQL
	$sql = qq{
		select concat(code,'_',server_id), create_time, username, update_time, status,
		error_message, run_seconds, not_before_time, target_datatype, method,
		data_code, altcode, process_pid, worker_id, auto_retried from }.
	$self->{database_name}.'.background_tasks ';

	# filter by datatype?
	if ($args{target_datatype} =~ /\d\_\d/) {
		$sql .= qq{where target_datatype=? };
		$$bind_values[0] = $args{target_datatype};

	# or by task id?
	} elsif ($args{task_id} =~ /\d\_\d/) {
		$sql .= qq{where concat(code,'_',server_id)=? };
		$$bind_values[0] = $args{task_id};
	}

	# filter by record altcode?
	if ($args{altcode} && $args{altcode} ne 'None') {
		$sql .= qq{ and altcode=? };
		push(@$bind_values, $args{altcode});
	}

	# filter by run-status?
	if ($args{run_status} eq 'will_run') {
		$sql .= qq{ and status in ('Pending','Retry','Running') };
	} elsif ($args{run_status} eq 'has_run') {
		$sql .= qq{ and status in ('Completed','Error','Cancelled','Warn') };
	} elsif ($args{run_status} eq 'running') {
		$sql .= qq{ and status = 'Running' };
	} elsif ($args{run_status} eq 'error') {
		$sql .= qq{ and status = 'Error' };
	} elsif ($args{run_status} eq 'warn') {
		$sql .= qq{ and status = 'Warn' };
	}

	# filter by method?
	if ($args{method} && $args{method} ne 'None') {
		$sql .= qq{ and method =? };
		push(@$bind_values, $args{method});
	}

	# filter by update_time age?
	if ($args{update_time_age} =~ /\d/) {
		$sql .= qq{ and update_time >= (unix_timestamp() - $args{update_time_age}) };
	}

	# filter by not_before_time epoch?
	if ($args{not_before_time} =~ /\d/) {
		$sql .= qq{ and not_before_time <= $args{not_before_time} };
	}

	# the logic above could lead to ugly SQL
	if ($sql !~ / where /) {
		$sql =~ s/ and / where /;
	}

	# apply the limit and sort by soonest-to-start first
	$sql .= qq{order by not_before_time desc limit $args{limit}};

	# run the SQL
	($tasks, $tasks_keys) = $self->{db}->sql_hash(
		$sql, 'bind_values' => $bind_values,
	);

	# return the results
	return ($tasks, $tasks_keys);
}

# method to get or set the status of a task by ID
sub task_status {
	my $self = shift;

	# one required argument is the primary key of the task to cancel
	# first optional argument is the new status
	# second optional argument is a status message to put into the error_message column
	my ($task_id, $new_status, $error_message) = @_;

	my ($current_task_status);

	# fail without that
	if (!$task_id) {
		$self->{belt}->logger('ERROR: No task sent to task_status()','task_errors');
		return;
	}

	# get the current status either way
	($current_task_status) = $self->{db}->quick_select(
		'select status from '.$self->{database_name}.'.background_tasks'.
		qq{ where concat(code,'_',server_id)=?},
		[$task_id]
	);

	# new status?
	if ($new_status) {
		# if it is being marked Completed or Error, set the run_seconds
		if ($new_status eq 'Completed' || $new_status eq 'Error') {
			$self->{db}->do_sql(
				'update '.$self->{database_name}.'.background_tasks'.
				qq{
					set run_seconds=(unix_timestamp() - update_time)
					where concat(code,'_',server_id)=?
				},
				[$task_id]
			);
		}

		# do the status update
		$self->{db}->do_sql(
			'update '.$self->{database_name}.'.background_tasks'.
			qq{
				set status=?, error_message=?, update_time=unix_timestamp()
				where concat(code,'_',server_id)=?
			},
			[$new_status, $error_message, $task_id]
		);

		# if setting to 'Running,' mark down the worker_id and process pid
		if ($new_status eq 'Running') {
			$ENV{WORKER_ID} ||= 1; # support multiple worker nodes, defaulting to 1
			$self->{db}->do_sql(
				'update '.$self->{database_name}.'.background_tasks'.
				qq{
					set worker_id=?, process_pid=?
					where concat(code,'_',server_id)=?
				},
				[$ENV{WORKER_ID}, $$, $task_id]
			);
		}

		# success!
		return 1;

	# nope, just give them the current status
	} else {
		return $current_task_status;
	}

}

# method to move up a delayed task to now
sub start_now {
	my $self = shift;

	# required arg is the task ID
	my ($task_id) = @_;

	# fail without that
	if (!$task_id) {
		$self->{belt}->logger('ERROR: No task sent to start_now()','task_errors');
		return;
	}

	# very straight-forward
	$self->{db}->do_sql(
		'update '.$self->{database_name}.'.background_tasks'.
		qq{
			set not_before_time=unix_timestamp(), update_time=unix_timestamp()
			where concat(code,'_',server_id)=?
		},
		[$task_id]
	);

	# done, not real need to return

}

# method to actually do a task
sub do_task {
	my $self = shift;

	# optional argument is the ID of the task to attempt
	# if that's blank, we go with the next one
	my ($task_id) = @_;

	# declare our vars
	my ($status_change, $auto_retried, $human_time, $result, $method, $now, $data_code, $args_hash, $arguments, $status_message, $pause_background_tasks, $username);

	# first things first, make sure that background tasks are not paused for this instance
	($pause_background_tasks) = $self->{db}->quick_select(qq{
		select pause_background_tasks from instances where concat(code,'_',server_id)=?
	},[	$self->{luggage}{app_instance} ]);
	# return if it's 'yes'
	return if $pause_background_tasks eq 'Yes';

	# if they sent a task ID, pull out that one
	if ($task_id =~ /\d/) {

		($method,$data_code,$username,$args_hash, $auto_retried) = $self->{db}->quick_select(
			'select method, data_code, username args_hash, auto_retried from '.$self->{database_name}.'.background_tasks'.
			qq{ where concat(code,'_',server_id)=?},
			[$task_id]
		);

		# exit out if none found
		if (!$method) {
			$self->{belt}->logger(qq{ERROR: Task $task_id could not be found for do_task()},'task_errors');
			return;
		}

		# mark this task as running so no other scripts / worker nodes can grab it
		$status_change = $self->task_status($task_id, 'Running');

	# otherwise, we need to try and grab the next 'eligible' task, meaning it has a status
	# of 'Pending' or 'Retry' and the not_before_time column is earlier than this moment.
	# Note that we are absolutely doing the wrong thing by using MySQL as a job queue
	# as per https://blog.engineyard.com/2011/5-subtle-ways-youre-using-mysql-as-a-queue-and-why-itll-bite-you
	# but I do have it working really nicely nonetheless ;)
	} else {

		# so the problem is that two or more forks/threads might be trying to grab the
		# same task at the same time.  We are already trying to combat this with randomly (1-10 sec)
		# timed sleep() calls, but we will try to do the status-change and code-fetch in one
		# single UPDATE command in hopes that MySQL's locking can do the work for us.

		# support multiple worker nodes, defaulting to 1
		$ENV{WORKER_ID} ||= 1;

		# do the update-plus-ID-grab
		$self->{db}->do_sql(
			'update '.$self->{database_name}.'.background_tasks '.
			qq{
				set status='Running', process_pid=?, worker_id=?, update_time=unix_timestamp()
				where status in ('Pending','Retry') and not_before_time < unix_timestamp()
				and target_datatype=? order by not_before_time limit 1
			},
			[$$, $ENV{WORKER_ID}, $self->{dt}]
		);

		# see if that update matched any logic
		#($task_id) = $self->{db}->quick_select('select @found_task_id');
		($task_id) = $self->{db}->quick_select(qq{
			select concat(code,'_',server_id) from }.$self->{database_name}.'.background_tasks'.qq{
			where process_pid=? and worker_id=? and status='Running' and target_datatype=?
			order by not_before_time limit 1
		},[$$, $ENV{WORKER_ID}, $self->{dt}]);

		# if no task to run right now, then no need to continue
		return 'None found' if !$task_id;

		# $self->{belt}->logger('trying to run '.$task_id,'eric');

		# now we should be safe to get the details for that task
		($method,$data_code,$username,$args_hash,$auto_retried) = $self->{db}->quick_select(
			qq{select method, data_code, username, args_hash, auto_retried from }.$self->{database_name}.'.background_tasks'.
				qq{ where concat(code,'_',server_id)=?},
			[$task_id]
		);
	}

	# if there are no new tasks (or the task they sent was not found), return, and indicate why
	return 'None found' if !$task_id;

	# if the returned value from task_status is 'Running,' then another thread or worker
	# grabbed this task at the exact same time, so we need to bow out
	return if $status_change eq 'Running';

	# if we have a frozen arguments hash, thaw it out
	if ($args_hash && $args_hash ne 'None') {
		eval {
			$arguments = thaw($args_hash);
		};
		# if it hit an eval{} error, then we failed and have a message to log
		if ($@) {
			$self->task_status($task_id, 'Error', 'Error un-packing args hash: '.$@);
			$self->clear_records();
			return;
		}
	}

	# if there is a data_code, add it to our $arguments hashref, which may have nothing else
	if ($data_code) {
		$$arguments{data_code} = $data_code;

		# and load up the target record
		$self->load( 'data_codes' => [$data_code] );
	}

	# if there is a for-username (which is likely if triggered via the web) and it's
	# not the current user, which is likely, because this script was started by the
	# OT Admin, then switch the session to be for that user
	# This is only safe when in script mode, not Plack-land, because we do not want
	# to permanently shift the user for the rest of the web-response; so fail-out
	# when trying to run for another user when in Plack-land
	if ($username && $username ne $self->{luggage}{username}) {
		# okay, we know we need to switch users
		# but is it safe...
		if ($self->{belt}->{request}) { # no, it is not
			$self->task_status($task_id, 'Error', 'Not able to run task as '.$username.' via Web UI. Current User: '.$self->{luggage}{username});
			$self->clear_records();
			return;

		} else { # yes, it is.  do it; we trust our scripts
			# handy subroutine in omnitool::common::luggage
			&omnitool::common::luggage::change_user_session($self->{luggage}, $username);

			# NOTE TO FUTURE ERIC:  If you are here because the lab map and datatype hash needs
			# to be refreshed without a background task script restart, then the change_user_session()
			# routine should allow for those things to be refreshed as the username changes

			# My expectation is that the username will change frequently during real-world use,
			# so flushing out those caches should take effect within a few minutes.  If you get into
			# a situation where the same user runs tasks after task, it may not work perfectly.
			# But it will work well enough, all things considered.

		}
	}

	# pass in the task_id so this method may update the status if it prefers
	$$arguments{task_id} = $task_id;

	# make sure the %$params hash is fresh for each task-run
	$self->{luggage}{params} = {}; # just in case
	$self->{luggage}{stash_params} = {}; # mandatory because omniclass might 'restore' old params

	# call it and expect a 1 if success / error-message on fail
	# wrap in an eval to attempt to catch fatal errors

	my ($result, $status_message, $not_before_time, $do_auto_retry);
	eval {
		($result,$status_message) = $self->$method($arguments);
	};
	# if it hit an eval{} error, then we failed and have a message to log
	if ($@) {
		$result = 0;
		$status_message = $@;
		$status_message .= ' (eval message)';
		$do_auto_retry = 1; # since we had a hard-error, try a retry in an hour
	} elsif (!length($result)) { # didn't get a result, do auto retry
		$do_auto_retry = 1;
	}

	# if $result starts with "ERROR: No", then the method does not exist and
	# they got the AUTOLOAD routine in omniclass.pm
	if ($result =~ /^ERROR: No/) {
		# noodle out the meaningful status message
		($status_message = $result) =~ s/^ERROR: //;
		$result = 'Error';
		$do_auto_retry = 0; # no reason to try this
	}

	# print "$result - $status_message - $task_id\n";

	# get the current time, for logging purposes
	$human_time = $self->{belt}->time_to_date(time(),'to_date_human_time');

	if ($result eq '1' || $result eq 'Success' || $result eq 'Warn') { # be flexibile in life
		# it can only be 'Completed' or 'Warn'
		$result = 'Completed' if $result ne 'Warn';

		$self->task_status($task_id, $result, $status_message);

		# we want to also log to $OTHOME/log
		$status_message = 'Warn: '.$status_message if $result eq 'Warn';
		$self->{belt}->logger(qq{$human_time | Task $task_id | $method() | $data_code | $status_message},'task_execute_success_'.$self->{database_name});

	# otherwise, it failed and we may need to auto-try it in four hours or just log the status message

	} else {

		# if it failed due to a hard-error (probably due to connectivity) give it another
		# shot in one hour; only do this once (and check that via the 'auto_retried' column)
		if (!$auto_retried && $do_auto_retry) {

			$not_before_time =  time() + 3600;

			$self->{db}->do_sql(
				'update '.$self->{database_name}.'.background_tasks '.
				qq{
					set status='Retry', auto_retried=1, not_before_time=?
					where concat(code,'_',server_id)=?
				},
				[$not_before_time, $task_id]
			);

		# otherwise, let's mark the item as error
		} else {

			$self->task_status($task_id, 'Error', $status_message);

		}

		# either way, we want to also log to $OTHOME/log
		$self->{belt}->logger(qq{$human_time | Task $task_id | $method() | $data_code | }.$status_message,'task_execute_errors_'.$self->{database_name});

	}

	# clean up any loaded records
	$self->clear_records();

	# little house-keeping: no more than every 100 seconds, clear any tasks
	# in this database which are completed for longer than 30 days
	$now = time();
	if ($now =~ /10$/) {
		$self->{db}->do_sql(
			'delete from '.$self->{database_name}.'.background_tasks '.
			qq{where update_time < (unix_timestamp()-2592000) and status='Completed'}
		);
	}


	# all done, we shall not log this in work history
}

# utility method to retry any tasks asscoiated with a dead process / background_task script
# meant to run at the first start of every background_task script, and offsets the 'reboot' problem
sub retry_zombies {
	my $self = shift;

	# support multiple worker nodes, but default to node #1
	$ENV{WORKER_ID} ||= 1;

	# fetch the process PID's and task ID's or any taks currently-running on this worker node
	my ($processes,$running_pids) = $self->{db}->sql_hash(qq{
		select process_pid, concat(code,'_',server_id) from }.$self->{database_name}.'.background_tasks'.qq{
		where status='Running' and worker_id=?
	},(
		'names' => ['task_id'],
		'bind_values' => [$ENV{WORKER_ID}],
    ));

	my ($pid, $exists);

	# cycle through our results
	foreach $pid (@$running_pids) {
		$exists = kill 0, $pid; # check to see if it's alive
		next if $exists; # nothing to do if it is alive
		$self->task_status($$processes{$pid}{task_id}, 'Retry'); # if that process is dead, retry the task with a new process
	}

}


1;
