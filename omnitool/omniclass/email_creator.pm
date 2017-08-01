package omnitool::omniclass::email_creator;
=cut

Provides functions to send email. Outgoing emails are queued up in the 'email_outbound'
table within an App Instance's database, and then sent in the background via a script,
alongside the OmniClass bacgkround task scripts.

This lives under OmniClass so that you can call from within an object, but the emails
are organized instance-wide so that you just need one email-sending script.

These methods are provided:

	add_outbound_email()
	send_outbound_email()

This is designed so that you have Template-Toolkit templates for your email bodies,
which are HTML-only.

Please see more notes within the omniclass.pm docs.

=cut

# seventy-seventh time is the charm
$omnitool::omniclass::email_creator::VERSION = '6.0';

# for sending out email
use Email::Stuff;
use Net::Domain qw(hostdomain);

# time to grow up
use strict;

# subroutine to schedule an outbound email
sub add_outbound_email {
	my $self = shift;

	# grab arguments
	my (%args) = @_;
	# looks like
	# 'to_addresses' => 'list,of,email,addresses', # required, comma-separated list of valid email addresses
												   # you can just send base names, and we will add the suffix from $ENV{OT_COOKIE_DOMAIN}
	# 'subject' => 'Subject Line', # required, the subject line of the email
	# 'from_address' => 'someone@email-domain.com', # optional; sender's email address; defaults to contact email for this app instance
													# and then fails over to application contact, finally to $ENV{OTADMIN}
	# 'template_filename' => 'email_template.tt', # optional/recommended; a template-toolkit template which will should be under either
												  # $OTPERL/static_files/email_templates or $OTPERL/applications/$app_code_directory/email_templates
												  # if blank, defaults to very-basic $OTPERL/static_files/email_templates/non_template.tt, which
												  # expects a glob of HTML in $self->{email_vars}{message_body}
	# 'data_code' => $record_id, # optional/recommended, a primary key for a target data record for your email template to utilize
	# 'email_vars' => {}, # optional/recommended; extra variables to send into your email template.  If you are using the plain / pass-through
						  # non_template.tt, then put a glob of HTML into the 'message_body' key under here;
						  # this gets put into $self->{email_vars} for the template
	# 'attached_files' => 'list,of,file,ids', # optional; a comma-separted list of primary keys from the stored_files DB table for this app instance

	my ($data_code, $include_path, $app_code_directory, $message_body, $logfile);

	# target logging location
	$logfile = 'email_errors_'.$self->{database_name};

	# only allow the email if this datatype supports them
	if ($self->{datatype_info}{support_email_and_tasks} eq 'No') {
		$self->{belt}->logger('ERROR: Could not add email. '.$self->{datatype_info}{name}.' does not support background tasks and email.',$logfile);
		return;
	}

	# fail out of we did not get a subject line or at least one email address
	if (!$args{subject}) {
		$self->{belt}->logger('ERROR: Could not create email without valid subject line. ('.$self->{datatype_info}{name}.' Datatype)',$logfile);
		return;
	} elsif (!$args{to_addresses} || $args{to_addresses} eq 'none') {
		$self->{belt}->logger('ERROR: Could not create email without at least one "send-to" email address. ('.$self->{datatype_info}{name}.' Datatype)',$logfile);
		return;
	}

	# uncomment for debugging
	# $args{to_addresses} = 'echernof';

	# if they did not specify a 'from_address', try a few options for the default
	if (!$args{from_address}) {

		# does this datatype have an incoming email address?  use that then
		if ($self->{datatype_info}{incoming_email_account}) {
			$args{from_address} = $self->{datatype_info}{incoming_email_account}.'@'.$self->{luggage}{session}->{app_instance_info}{hostname};

		# otherwise, does the instance have a contact?
		} elsif ($self->{luggage}{session}{app_instance_info}{inst_contact}) {
			$args{from_address} = $self->{luggage}{session}{app_instance_info}{inst_contact};

		# or maybe the application has a contact
		} elsif ($self->{luggage}{session}{app_instance_info}{app_contact}) {
			$args{from_address} = $self->{luggage}{session}{app_instance_info}{app_contact};

		# all else fails, use OT Admin
		} elsif ($ENV{OMNITOOL_ADMIN}) {
			$args{from_address} = $ENV{OMNITOOL_ADMIN};

		}
	}

	# if they sent an email_vars hashref, load that into $self->{email_vars} for now
	$self->{email_vars} = $args{email_vars};

	# if they sent a data_code, add that to $self->{email_vars}, and make sure the record is loaded
	if ($args{data_code}) {
		$data_code = $args{data_code}; # sanity
		$self->{email_vars}{data_code} = $data_code;
		# is it loaded?
		if (!$self->{records}{$data_code}{name}) { # nope, grab it in
			$self->load(
				'data_codes' => [$data_code]
			);
		}
	}

	# if they did not pass in a template, default to 'non_template.tt' under $OTPERL/static_files/email_templates
	if (!$args{template_filename}) {
		$args{template_filename} = 'non_template.tt';
	}

	# does the desired template live the in system-wide email_templates directory?
	if (-e $ENV{OTHOME}.'/code/omnitool/static_files/email_templates/'.$args{template_filename}) {
		$include_path = $ENV{OTHOME}.'/code/omnitool/static_files/email_templates/';
	} else {
		# isolate the directory / sanity for below
		$app_code_directory = $self->{luggage}{session}{app_instance_info}{app_code_directory};

		# try to find it in the app-specific directory
		if (-e $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/email_templates/'.$args{template_filename}) {
			$include_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/email_templates/';

		# it could not be found, die out
		} else {
			$self->{belt}->logger('ERROR: Could not locate email template "'.$args{template_filename}/'". ('.$self->{datatype_info}{name}.' Datatype)',$logfile);
			return;

		}
	}

	# now we can generate the email body via template toolkit
	$message_body = $self->{belt}->template_process(
		'template_file' => $args{template_filename},
		'include_path' => $include_path,
		'template_vars' => $self,
	);

	# clear out $self->{email_vars} to not pollute any other run-throughs
	delete($self->{email_vars});

	# now let's add the record to the 'email_outbound' table
	$self->{db}->do_sql(
		'insert into '.$self->{database_name}.'.email_outbound '.
		qq{
			(server_id,create_timestamp,target_datatype,status,from_address,to_addresses,subject,message_body,attached_files)
			values (?,unix_timestamp(),'$self->{dt}','Pending',?,?,?,?,?)
		},
		[
			$self->{server_id}, $args{from_address}, $args{to_addresses}, $args{subject},
			$message_body,  $args{attached_files}
		]
	);

	# log success in the status hash
	$self->work_history(1,"add_outbound_email() succeeded.",qq{Email subject '$args{subject}' going to $args{to_addresses}.});

	# return the new email's ID
	return  $self->{db}->{last_insert_id}.'_'.$self->{server_id};
}

# subroutine to actually send an email; meant to be running in the background
sub send_outbound_email {
	my $self = shift;

	# optional argument is the ID of the email to attempt to send
	my ($email_id) = @_;
	# if it's blank, we shall try to send the next 20 queued emails

	# declare our vars
	my ($pause_background_tasks, @driver_options, $db_status, $default_domain, $driver_name, $email_ids_list, $email_ids, $email_key, $email_keys, $email_password, $email_sending_info_encrypted, $email_sending_info, $email_username, $emails_to_send, $error_logfile, $file_contents, $file_id, $file_info, $mailer, $now, $protocol, $q_marks_list, $recipient, $send_logfile, $server_hostname);

	# support multiple worker nodes, defaulting to 1
	$ENV{WORKER_ID} ||= 1;

	# if they sent an $email_id, we shall go with that one email
	if ($email_id) {
		# mark this email as running so that other threads will not grab it
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_outbound set status='Running', worker_id=? }.
			qq{where concat(code,'_',server_id)=?},
			[$ENV{WORKER_ID}, $email_id]
		);
		# set our array to this one email ID
		$$email_ids[0] = $email_id;

	# otherwise, let's grab the next (up to) 20 emails
	} else {

		# first things first, make sure that background tasks are not paused for this instance
		($pause_background_tasks) = $self->{db}->quick_select(qq{
			select pause_background_tasks from instances where concat(code,'_',server_id)=?
		},[	$self->{luggage}{app_instance} ]);
		# return if it's 'yes'
		return if $pause_background_tasks eq 'Yes';

		# we need to retry any 'zombies', which are emails that were processing before a process crashed
		# the background tasks retry_zombies() is the 'right' way to do this, but for emails, we can
		# be simpler and presume that any email should be sent within 90 minutes of create
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_outbound set status='Retry', create_timestamp=unix_timestamp()
			where status='Running' and create_timestamp < (unix_timestamp()-5400)
		});
		# we may have to make that more robust in the future ;)

		# now update the next 1-20 pending / retry emails for the parent datatype, and
		# save the matched IDs into this @email_ids mysql variable; we are doing this in
		# one fell-swoop to try and avoid concurrency by not depending on weak SELECT locks
		# Note: we do it a bit differently in background_tasks.pm.  This seems to work
		# better at the moment for the emails, though we may have to change to a process_pid
		# marker later.
		$self->{db}->do_sql(
			'update '.$self->{database_name}.qq{.email_outbound set status='Running', worker_id=?, process_pid=?
				where status in ('Pending','Retry') and target_datatype=?
				order by create_timestamp limit 20
			},
			[$ENV{WORKER_ID}, $$, $self->{dt}]
		);

		# retrieve any found outgoing email ids
		$email_ids = $self->{db}->list_select(qq{
			select concat(code,'_',server_id) from }.$self->{database_name}.'.email_outbound'.qq{
			where process_pid=? and worker_id=? and status='Running' and target_datatype=?
			order by create_timestamp limit 20
		},[$$, $ENV{WORKER_ID}, $self->{dt}]);

		# if none found, let's kick out
		return if !$$email_ids[0];

	}

	# target logging locations
	$error_logfile = 'email_errors_'.$self->{database_name};
	$send_logfile = 'email_sends_'.$self->{database_name};

	# now pull out the information about those found emails
	$q_marks_list = $self->{belt}->q_mark_list(scalar(@$email_ids));
	($emails_to_send,$email_keys) = $self->{db}->sql_hash(qq{
		select concat(code,'_',server_id),create_timestamp,from_address,to_addresses,subject,message_body,attached_files
		from }.$self->{database_name}.qq{.email_outbound where concat(code,'_',server_id) in ($q_marks_list)
	}, ( 'bind_values' => $email_ids ) );


	# double-check that some emails were found
	if (!$$email_keys[0]) {
		return;
	}

	# otherwise, we need to prepare to send the email(s)

	# we need to fetch & decrypt this instance's 'email_sending_info'
	($email_sending_info_encrypted) = $self->{db}->quick_select(qq{
		select email_sending_info from instances where concat(code,'_',server_id)=?
	}, [ $self->{luggage}{session}{app_instance} ]);
	$email_sending_info = $self->{db}->decrypt_string($email_sending_info_encrypted,'135_1');

	# break up that system, and default the server hostname to localhost
	($server_hostname,$email_username,$email_password,$protocol) = split /\|/, $email_sending_info;
	$server_hostname ||= '127.0.0.1';

	# set up the email-send object
	$mailer = Email::Stuff->new;

	# set up our 'using' send options
	# using Gmail?
	if ($server_hostname eq 'Gmail') {
		# requires username and password
		if ($email_username && $email_password) {
			$driver_name = 'Gmail';
			@driver_options = ( username => $email_username, password => $email_password );

		# error out if not provided
		} else {
			# prevent a million error messages
			$self->{db}->do_sql('update '.$self->{database_name}.qq{.email_outbound set status='Paused'});

			# log error and return
			$self->{belt}->logger(qq{ERROR: Using Gmail to send email requires a username & password; all Pending emails set to 'Paused'.  Please fix and retry emails.},$error_logfile);
			return;
		}

	# other server with username/password?
	} elsif ($email_username && $email_password) {
		$driver_name = 'SMTP';
		@driver_options = ( Host => $server_hostname, username => $email_username, password => $email_password );

	# just plain server
	} else {
		$driver_name = 'SMTP';
		@driver_options = ( Host => $server_hostname );

	}

	# for non-Gmail, $protocol might be SSL or TLS
	if ($protocol =~ /ssl/i) {
		push(@driver_options, ssl => 1);
	} elsif ($protocol =~ /tls/i) {
		push(@driver_options, tls => 1);
	}

	# grab system domain name for any needed defaulting of sender/recipient email addresses
	$default_domain = hostdomain();

	# now work through the emails we've fetched
	foreach $email_key (@$email_keys) {
		# blank out the DB status
		$db_status = '';

		# if the sender does not have a domain name, add that in from the system hostname
		if ($$emails_to_send{$email_key}{from_address} !~ /\@/) {
			$$emails_to_send{$email_key}{from_address} .= '@'.$default_domain;
		}

		# we shall create a separate email per recipient
		$$emails_to_send{$email_key}{to_addresses} =~ s/\s//gi; # no spaces
		foreach $recipient (split /,/, $$emails_to_send{$email_key}{to_addresses}) {
			next if $recipient eq 'none';

			# do it oo style so that we can have multiple attachments
			$mailer = Email::Stuff->new;

			# start off the email with basic parts
			$mailer->from( $$emails_to_send{$email_key}{from_address} );
			$mailer->subject( $$emails_to_send{$email_key}{subject} );
			$mailer->html_body( $$emails_to_send{$email_key}{message_body} );

			# if the recipient does have a suffix, apply the default system domain
			if ($recipient !~ /\@/) {
				$recipient .= '@'.$default_domain;
			}

			# if this is development, redirect all emails to the OMNITOOL_ADMIN
			if ($ENV{OT_DEVELOPER}) {
				$recipient = $ENV{OMNITOOL_ADMIN};
			}

			# add that recipient
			$mailer->to( $recipient );


			# attach any files?
			$$emails_to_send{$email_key}{attached_files} =~ s/\s//gi; # no spaces
			foreach $file_id (split /,/, $$emails_to_send{$email_key}{attached_files}) {
				# load file and its info; would prefer to do this just once above,
				# but a bit afraid about making that work reliably
				$file_contents = $self->{file_manager}->retrieve_file($file_id);
				$file_info = $self->load_file_info($file_id);
				$mailer->attach( $file_contents, filename => $$file_info{filename}, content_type => $$file_info{mime_type} );
			}

			# now try to send the message
			eval {
				$mailer->using( $driver_name, @driver_options );
				$mailer->send;
			};

			# log as appropriate
			if ($@) { # it failed to send
				# to logfile
				$self->{belt}->logger(qq{ERROR: Unable to send email $email_key '$$emails_to_send{$email_key}{subject}' to $recipient; $@},$error_logfile);

				# for logging to the database
				$db_status = 'Error';

			} else {
				$self->{belt}->logger(qq{Sent email '$$emails_to_send{$email_key}{subject}' to $recipient.},$send_logfile);

				# for logging to the database; note that all recipients to succeed to see 'Success'
				$db_status = 'Success' if $db_status ne 'Error';

			}

		# recipients done
		}

		# update email record status
		$self->{db}->do_sql('update '.$self->{database_name}.qq{.email_outbound set status='$db_status',
			send_timestamp=unix_timestamp() where concat(code,'_',server_id)='$email_key'});
	}

	# little house-keeping: no more than every 500 seconds, clear any outgoing emails
	# in this database which are completed for longer than 30 days
	$now = time();
	if ($now =~ /(650|150)$/) {
		$self->{db}->do_sql(
			'delete from '.$self->{database_name}.'.email_outbound '.
			qq{where send_timestamp < (unix_timestamp()-2592000) and status in ('Success','Error') }
		);
	}

}


1;
