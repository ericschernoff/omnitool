package omnitool::omniclass::email_receiver;
# faciliate the parsing of incoming emails sent into your datatypes
# executed as part of the background tasks process, see scripts/background_tasks_forking.pl
# expects your custom OmniClass Packages to have a email_unpack() method that returns
# 'Success' or 'Error' with a message
# emails are received via scripts/email_receive.pl - please see that for notes

$omnitool::omniclass::loader::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# time to grow up
use strict;

# for un-packing emails
use omnitool::common::email_unpack;

# subroutine to load / process emails from
sub email_receiver {
	my $self = shift;

	# optional argument is the ID of the email to attempt to receive
	my ($email_id) = @_;
	# if it's blank, we shall try to receive the next 20 queued emails

	# fail if there is no set email accoung or no email_processor() method in our sub-class
	return if !$self->{datatype_info}{incoming_email_account} || !($self->can('email_processor'));

	my ($pause_background_tasks, $email_address, $email_ids_list, $email_ids, $email_key, $email_keys, $email_unpacker, $email, $error_logfile, $message, $mime_message, $new_status, $parse_logfile, $status);

	# target logging locations
	$error_logfile = 'email_errors_'.$self->{database_name};
	$parse_logfile = 'email_parsing_'.$self->{database_name};

	# determine the complete email for this datatype + app instance
	$email_address = $self->{datatype_info}{incoming_email_account}.'@'.$self->{luggage}{session}->{app_instance_info}{hostname};

	# support multiple worker nodes, defaulting to 1
	$ENV{WORKER_ID} ||= 1;

	# if they sent an $email_id, we shall go with that one email
	if ($email_id) {
		# mark this email as running so that other threads will not grab it
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_incoming set status='Locked', worker_id=?, process_id=? }.
			qq{where concat(code,'_',server_id)=?},
			[$$, $ENV{WORKER_ID}, $email_id]
		);
		# set our array to this one email ID
		$$email_ids[0] = $email_id;

	# otherwise, let's operate under the background-task cycle, and grab the next (up to) 20 emails
	} else {
		# first things first, make sure that background tasks are not paused for this instance
		($pause_background_tasks) = $self->{db}->quick_select(qq{
			select pause_background_tasks from instances where concat(code,'_',server_id)=?
		},[	$self->{luggage}{app_instance} ]);
		# return if it's 'yes'
		return if $pause_background_tasks eq 'Yes';

		# we need to retry any 'zombies', which are emails that were processing before a process crashed
		# the background tasks retry_zombies() is the 'right' way to do this, but for emails, we can
		# be simpler and presume that any email should be sent within one hour of create
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_incoming set status='New'
			where status='Locked' and create_time < (unix_timestamp()-3600)}
		);
		# we may have to make that more robust in the future ;)

		# now update the next 1-20 pending / retry emails for the parent datatype, and
		# save the matched IDs into this @email_ids mysql variable; we are doing this in
		# one fell-swoop to try and avoid concurrency by not depending on weak SELECT locks
		# (see background_tasks.pm)
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_incoming set status='Locked', worker_id=?, process_pid=? }.
			qq{	where status ='New' and recipient=? order by create_time limit 20 },
			[$ENV{WORKER_ID}, $$, $email_address]
		);

		# retrieve any found incoming email ids
		$email_keys = $self->{db}->list_select(qq{
			select concat(code,'_',server_id) from }.$self->{database_name}.'.email_incoming'.qq{
			where process_pid=? and worker_id=? and status='Locked' and recipient=?
			order by create_time limit 20
		},[$$, $ENV{WORKER_ID}, $email_address]);
	}

	# double-check that some emails were found
	if (!$$email_keys[0]) {
		return;
	}

	# initialize our nice mime parser
	$email_unpacker = omnitool::common::email_unpack->new();

	# now work through the emails we've fetched
	foreach $email_key (@$email_keys) {

		# make sure the %$params hash is fresh for each email
		$self->{luggage}{params} = {};

		# retrieve the mime message (the email itself)
		($mime_message) = $self->{db}->quick_select(
			'select mime_message from  '.$self->{database_name}.
			qq{.email_incoming where concat(code,'_',server_id)=?},
			[$email_key]
		);

		# un-pack the email and retrieve the info hash
		$email = $email_unpacker->open_email(\$mime_message);

		# block any rejected / disk-full emails
		if ($$email{subject} =~ /Rejected:/ && $$email{text_body} =~ /Not enough disk space/i) {

			$status = 'Error';
			$message = 'Email is a bounce/rejected message.';

		# otherwise run the email_processor() method in our sub-class to handle the message
		} else {
			($status,$message) = $self->email_processor($email);
		}

		# if successful, log it and tag the message as done
		if ($status eq 'Success') {

			$self->{belt}->logger(qq{Successfully processed email to $$email{to} from $$email{from} - $email_key},$parse_logfile);

			$new_status = 'Done';

		# if fail, mark error and log as such
		} else {

			$self->{belt}->logger(qq{ERROR processing email to $$email{to} from $$email{from} | Message: $message},$error_logfile);

			$new_status = 'Error';

		}

		# update the database with the status
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_incoming set status=?, error_message=? }.
			qq{where concat(code,'_',server_id)=?},
			[$new_status, $message, $email_key]
		);

		# clean up the email files
		$email_unpacker->clean( $$email{save_directory} );

	}

	# little house-keeping: no more than every 500 seconds, clear any incoming emails
	# in this database which are completed for longer than 30 days
	my $now = time();
	if ($now =~ /(350|850)$/) {
		$self->{db}->do_sql(
			'delete from '.$self->{database_name}.'.email_incoming '.
			qq{where send_timestamp < (unix_timestamp()-2592000) and status in ('Done','Error') }
		);
	}


}

1;
