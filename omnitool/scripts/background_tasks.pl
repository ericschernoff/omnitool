#!/usr/bin/env perl
# Background task worker script meant to run as a cron script
# to run background tasks for a datatype which supports them.
#
# Please see the 'Generate Crontab' tool under the Manage Instances tool in OT admin
# to see how to run this via cron.  The basic idea is to set up some important
# environmental vars and then run an apprpriate number of scripts for each datatype
# set to support background tasks & email.
# Please definitely use 'Generate Crontab' to set up your worker nodes -- but don't
# forget to update the 'WORKER_ID' variable.

# Trying to find these processes?  'ps -fC perl' works quite nicely

# some standard facts about our servers
$ENV{OTHOME} ||= '/opt/omnitool/';
$ENV{OMNITOOL_ADMIN_USERNAME} ||= 'echernof';
$ENV{WORKER_ID} ||= '1';
# set these via the SystemD service config

# i wish i was a better person
use strict;

# prevent infinite tasks from wrecking our background processes; time out after 90 minutes
# we allow for so long because of the lab-syncing; maybe should be instance-configurable
local $SIG{ ALRM } = sub { die "Background Script Timed Out After 90 Minutes" };
alarm 60 * 90;

# for watching out for my sister processes
use Proc::ProcessTable;

# for grabbing our full OT platform
use omnitool::common::luggage;

# declare local variables
my ($timestamp, $return_value, $three_minutes_from_now, $target_datatype, $t, $p, $omniclass_object, $n, $my_command_line, $luggage, $instance_hostname);

# required arguments are the instance hostname and the target datatype (DT_ID or table_name)
$instance_hostname = $ARGV[0];
$target_datatype = $ARGV[1];
# fail if it was not provided
if (!$instance_hostname || !$target_datatype) {
	print "Usage $ENV{OTHOME}/code/omnitool/scripts/background_tasks.pl TARGET_APPLICATION_INSTANCE_HOSTNAME TARGET_DATATYPE_ID_OR_TABLE_NAME\n";
	exit;
}

# set the developer env var for stage/dev instances
if ($instance_hostname =~ /dev|stage|staging/i) {
	$ENV{OT_DEVELOPER} = 1;
}

# import the OT platform for this app instance
$luggage = pack_luggage(
	'username' => $ENV{OMNITOOL_ADMIN_USERNAME},
	'hostname' => $instance_hostname,
);

# abd get an omniclass object for our target datatype
$omniclass_object = $$luggage{object_factory}->omniclass_object(
	'dt' => $target_datatype,
);

# are we running some instance-wide daily routines via 'pure-ish' cron?
# example cron entry:
# 0 23 * * * /opt/omnitool/code/omnitool/scripts/background_tasks.pl OT_ADMIN_INSTANCE_HOSTNAME 5_1 daily_routines TARGET_INSTANCE_ALTCODE
# I like 23, which is 11pm, because the servers are on UTC time and that's 6-9pm in the US
if ($ARGV[2] eq 'daily_routines' && $target_datatype eq '5_1' && $ARGV[3]) {
	$omniclass_object->simple_load($ARGV[3]);
	$omniclass_object->daily_routines();
	# do not do the rest of this stuff
	exit;
}

# check to see if there are more than the allowed number of scripts running for this instance/datatype combo per worker
# use the very cool Proc::ProcessTable module to avoid the need for another DB table

# get current processes
$t = new Proc::ProcessTable;

# get my command line
foreach $p (@{$t->table}) {
	next if $$p{pid} ne $$; # skip if it's not me
	$my_command_line = $$p{cmndline};
}

# now look for my twins
$n = 0;
foreach $p (@{$t->table}) {
	next if $$p{pid} eq $$; # skip if it's me
	next if $$p{cmndline} ne $my_command_line; # or if it's just like me
	$n++; # keep count
}

# OK, exit out of $n >= the number of processes allowed per worker
exit if $omniclass_object->{datatype_info}{support_email_and_tasks} eq 'No' || $n >= $omniclass_object->{datatype_info}{support_email_and_tasks};

# now it's time to get to the business of processing emails and running background tasks

# 1. Retry any zombie background tasks which were running under a now-crashed process
$omniclass_object->retry_zombies();

# 2. Receive/process up to 20 emails
$omniclass_object->email_receiver();

# 3. Run background tasks for at least three minutes
$timestamp = time();
$three_minutes_from_now = time() + 180;
while ($timestamp < $three_minutes_from_now) {
	# run the next background task
	$return_value = $omniclass_object->do_task();
	# print "here: $return_value\n";
	# if it succeeded, that return_value will be empty
	if ($return_value eq 'None found') { # break out, there are no tasks available
		last;
	}

	# stagger these to limit race conditions
	sleep(rand(int(20)+1));

	# watch the clock
	$timestamp = time();
}

# 4. Send out 20 emails
$omniclass_object->send_outbound_email();

# all done
exit;
