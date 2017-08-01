#!/usr/bin/env perl
# Example of a forking background task worker script meant to work with SystemD or Monit
# NOT RECOMMENDED: One bad task can hold up your whole worker; use the background_tasks.pl
# script via cron instead for more fun.  THIS IS PROVIDED FOR REFERENCE ONLY.
#
# accepts / requires:
#	--pidfile to define the full file path for the PID file. Will usually
# 	 	go within $OTHOME/tmp/pids
#
#	--instance to define the hostname of the target application instance
#
# Will fork off the number of processes specified for each datatype which
# support/allow for background tasks and outbound email
#
# Run like so:
#	Run like so:
#		$SIX/scripts/background_tasks_forking.pl --pidfile=/opt/omnitool/tmp/pids/bg_script --instance=calo-labmgrdev.cisco.com &
#	or
#		$SIX/scripts/background_tasks_forking.pl --pidfile=/opt/omnitool/tmp/pids/bg_script_calo2 --instance=calo-dev2.cisco.com &
#
#
# To gracefully stop all processes, send a HUP signal to the parent process PID
# (in pidfile value, i.e. /opt/omnitool/tmp/pids/bg_script)

# some standard facts about our servers
$ENV{OTHOME} ||= '/opt/omnitool/';
$ENV{OMNITOOL_ADMIN_USERNAME} ||= 'echernof';

# import needed modules
use Getopt::Long; 	# option-grabbing
use File::Slurp;	# pidfile-writing
use Parallel::ForkManager; # fork-managing
use strict; # going to be 40 this year

# prevent infinite tasks from wrecking our background processes; time out after 30 minutes
local $SIG{ ALRM } = sub { die "Background Script Timed Out After 30 Minutes" };
alarm 60 * 30;

# for grabbing our full OT platform
use omnitool::common::luggage;

my ($pidfile, $application_instance, $n, $datatype, @target_datatypes);

# retrieve the options args
GetOptions (
	'pidfile=s' => \$pidfile,
	'instance=s' => \$application_instance
);

# fail if any were not provided
if (!$pidfile || !$application_instance) {
	print "Usage $ENV{OTHOME}/code/omnitool/scripts/background_tasks_forking.pl --pidfile=PID_FILE_PATH --instance=TARGET_APPLICATION_INSTANCE\n";
	exit;
}

# import the full OT platform: right now, we need datatype hash, from an appropriate DB handle
my $parent_luggage = pack_luggage(
	'username' => $ENV{OMNITOOL_ADMIN_USERNAME},
	'hostname' => $application_instance,
);

# log that we started
$$parent_luggage{belt}->logger($application_instance.' background script started.',$application_instance.'_background_script');

# figure out the datatypes which support background tasks, and how many processes they each need
foreach $datatype (split /,/, $$parent_luggage{datatypes}{all_datatypes}) {
	# skip if this DT does not have background tasks
	next if $$parent_luggage{datatypes}{$datatype}{support_email_and_tasks} eq 'No';

	$n = 0;
	while ($n < $$parent_luggage{datatypes}{$datatype}{support_email_and_tasks}) {
		push(@target_datatypes, $$parent_luggage{datatypes}{$datatype}{table_name});
		$n++;
	}
}

# please note that @target_datatypes contains duplicate entries for those datatypes
# which have been set to have more than one background worker process

# exit if no target datatypes found
exit if !$target_datatypes[0];

# little house-keeping: retry any zombies
my $parent_omniclass_object = $$parent_luggage{object_factory}->omniclass_object(
	'dt' => $target_datatypes[0],
);
$parent_omniclass_object->retry_zombies();

# be nice with the parent DB handle
$$parent_luggage{db}{dbh}->disconnect;

# write out our pid file
write_file($pidfile,$$);

# vars we will need from here on
my ($pm, @fork_pids, $datatype, $pid, @pidfiles, $file);

# start the improved fork manager (which drives fork() operations),
# supporting the needed number of processes
$pm = new Parallel::ForkManager(scalar(@target_datatypes));

# array for the pids we will be creating
@fork_pids = ();

# fork off for each target datatype background process
$n = 0;
foreach $datatype (@target_datatypes) {
	# stagger these to further limit race conditions
	# commenting out for now due to the sleep() below and improvements to DB locking
	# sleep(rand(int(10)+1));

	# spawn the fork and add to the array of PIDs
	$n++; # kind of weird to have to track $n first
	$fork_pids[$n-1] = $pm->start and next;

	# rest of this foreach loop happens within the child processes

	# so long as this is 0, we will continu within the child
	my $stop_requested = 0;
	my $time_to_stop = 0;

	# expect the instruction to stop gracefully when the parent gets a HUP
	local $SIG{HUP} = sub {
		$stop_requested = 1;
	};

	# now log into omnitool again, getting %$luggage in the child
	my $luggage = pack_luggage(
		'username' => $ENV{OMNITOOL_ADMIN_USERNAME},
		'hostname' => $application_instance,
	);

	# grab an omniclass object for the target datatype
	my $omniclass_object = $$luggage{object_factory}->omniclass_object(
		'dt' => $datatype,
	);

	# start the perpetual loop / see below
	# we are going to limit 'perpetual' to 15 minutes
	my $start_time = time();
	while ($time_to_stop == 0) {

		# receive up to 20 emails
		$omniclass_object->email_receiver();

		# run the next background task
		$omniclass_object->do_task();

		# send out 20 emails
		$omniclass_object->send_outbound_email();

		# OK, so if the parent process got "kill -9'ed," we gotta go
		my $ppid = getppid;
		if ($ppid == 1) {
			$omniclass_object->{luggage}{belt}->logger('kill -9 Called on '.$application_instance.' background script',$application_instance.'_background_script');
			exit;
		}

		# take a breath, in case we are paused, we don't want to thrash
		# again, stagger these to further limit race conditions
		sleep(rand(int(20)+1));

		# assign the current value of $stop_requested to $time_to_stop; if a HUP is sent
		# that value will be 1 and will break our loop
		$time_to_stop = $stop_requested;
		if (!$time_to_stop) { # set $time_to_stop to 1 if 20 minutes have gone by
			$time_to_stop = time() > ($start_time+1200);
		}
	}

	# if we go here, we they sent the HUP and we can stop
	$pm->finish;

}

# track the PIDs for each datatype's process(es)
$n = 0;
foreach $datatype (@target_datatypes) {
	push(@pidfiles,$pidfile.'_'.$datatype.'_'.$n);
	write_file($pidfiles[$n],$fork_pids[$n]);
	$n++;
}

# handle the HUP signal and tell the children processes to terminate
$SIG{HUP} = sub {
	$n = 0;
	foreach $file (@pidfiles) {
		# remove the child's pid file
		unlink($file);
		# kill the process
		kill HUP => $fork_pids[$n];
		# advance
		$n++;
	}
};

# block until all children are done
$pm->wait_all_children;

# how did we get past $pm->wait_all_children ?
# if the pidfiles exist (at least one), the script ran out of time
if (-e $pidfiles[0]) {
	foreach $file (@pidfiles) { # remove the children's pid files
		unlink($file);
	}
	# log that we ended naturally
	$$parent_luggage{belt}->logger($application_instance.' background script exited normally after 15 minutes of execution.',$application_instance.'_background_script');

# if the files not longer exist, it's because of a HUP and should log that
} else {
	$$parent_luggage{belt}->logger('HUP Called on '.$application_instance.' background script',$application_instance.'_background_script');
}


# remove the pid file
unlink($pidfile);

# all done
exit;
