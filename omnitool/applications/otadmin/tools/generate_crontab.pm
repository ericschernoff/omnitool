package omnitool::applications::otadmin::tools::generate_crontab;
# generates an example crontab file to go on worker nods for an instance

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# pretty basic: geneate a cron file (for Linux) to run the background_tasks.pl script
# X times every minute for each datatype which supports background tasks/email
# X = The number of concurrent processes allowed for that datatype, minus two if the
# allowed count is over three, and minus two if it is three; the script will exit out if
# there are too many threads
sub perform_action {
	my $self = shift;

	my ($instance_database_server, $datatypes_object, $instance_hostname, $dt, $start_script_count, $n);

	# now load up the datatypes process-counts (which support background tasks)
	# we are display line items, so we need a line items object
	$datatypes_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'datatypes',
	);
	# now load the datatypes which support background tasks
	$datatypes_object->search(
		'search_options' => [
			{
				'match_column' => 'parent',
				'match_value' => $self->{omniclass_object}->{data}{metainfo}{parent},
			},
			{
				'match_column' => 'support_email_and_tasks',
				'operator' => '!=',
				'match_value' => 'No',
			},
		],
		'auto_load' => 1,
		'load_fields' => 'name,support_email_and_tasks'
	);

	# if none found, display error
	if (! $datatypes_object->{records_keys}[0] ) {
		$self->{json_results}{error_message} = 'No Datatypes for Application Support Background Tasks';

	# otherwise, display the cron table
	} else {
		# some sanity
		$instance_hostname =  $self->{omniclass_object}->{data}{hostname};

		# top comment
		push(@{ $self->{json_results}{paragraphs} },qq{# OMNITOOL BACKGROUND TASKS FOR $instance_hostname});

		# reduce emails per job
		push(@{ $self->{json_results}{paragraphs} },qq{# Do not receive an email for every execute.}."\n".'MAILTO=""');

		# env var setting for worker node ID
		push(@{ $self->{json_results}{paragraphs} },qq{# Set this to a unique integer ID (0-999) for this worker node.}."\n".'WORKER_ID=1');

		# key OT6 stuff
		$instance_database_server = $self->{belt}->get_instance_db_hostname($self->{omniclass_object}->{data_code}, $self->{luggage}{database_name}, $self->{db});
		push(@{ $self->{json_results}{paragraphs} },'# omnitool environment'."\n"
			.'OTHOME='.$ENV{OTHOME}."\n"
			.'PERL5LIB='.$ENV{OTHOME}.'/code'."\n"
			.'DATABASE_SERVER='.$instance_database_server."\n"
			.'OMNITOOL_ADMIN='.$self->{omniclass_object}->{data}{contact_email}."\n"
			.'OMNITOOL_ADMIN_USERNAME='.$self->{luggage}{username}."\n"
			.'# SWIFTSTACK_NO_HOSTNAME_VERIFY=1');

		# dev machine flag
		push(@{ $self->{json_results}{paragraphs} },'# uncomment to prevent email from going out'."\n".'# OT_DEVELOPER=1');

		# tmp file maintenance
		push(@{ $self->{json_results}{paragraphs} },'# need this on any/all OT6 workers an app servers:  delete temp files older than 7 days'."\n".qq{30 4 * * * find /opt/omnitool/tmp -type f -mtime +7 -execdir rm -- '{}' \;});

		# instance-wide maintenance tasks notes
		push(@{ $self->{json_results}{paragraphs} }, "# To run Instance-wide daily cron routines, please see comments in omnitool::applications::otadmin::datatypes::instances above daily_routines() \n".
			"# and set up an instance sub-class like omnitool::applications::ciscolabs::common::daily_routines.");

		# cycle through each datatype and show X entries, where X = support_email_and_tasks-2 if support_email_and_tasks > 4
		foreach $dt (@{$datatypes_object->{records_keys}}) {
			# what's an appropriate number to start?  remember, the script runs for 3-4 minutes, and it will
			# keep tabs on how many are open

			# 1 or 2, just run that many
			if ($datatypes_object->{records}{$dt}{support_email_and_tasks} < 3) {
				$start_script_count = $datatypes_object->{records}{$dt}{support_email_and_tasks};

			# if 3, run 2 copies each minute
			} elsif ($datatypes_object->{records}{$dt}{support_email_and_tasks} == 3) {
				$start_script_count = 2;

			# over 3: N -2
			} else {
				$start_script_count = $datatypes_object->{records}{$dt}{support_email_and_tasks} - 2;
			}

			for ($n = 1; $n <= $start_script_count; $n++) {
				push(@{ $self->{json_results}{paragraphs} },qq{# Copy $n of worker script for }.$datatypes_object->{records}{$dt}{name}
					."\n".qq{* * * * * $ENV{OTHOME}/code/omnitool/scripts/background_tasks.pl $instance_hostname $dt});
			}
		}
	}
}


1;
