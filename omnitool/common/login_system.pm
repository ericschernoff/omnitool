package omnitool::common::login_system;

# please see pod documentation included below
# perldoc omnitool::common::login_system

# truth be told, this should be 12.0
$omnitool::common::login_system::VERSION = '6.0';

# load exporter module and export the subroutines
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( web_authentication );

# time to grow up
use strict;

# for printing the no-access page
use omnitool::common::ui;

# for creating sessions
use omnitool::common::session;

# let's be an OO module for re-usability and extensibility
sub new {
	my $class = shift;

	# need at least the %$luggage, which will have the Plack request and response handles
	# if we are planning to anything except for test_their_credentials()
	my ($luggage) = @_;

	if (!$luggage) {
		die 'Cannot use login_system without %$luggage.';
	}

	# pack up myself and return
	my $self = bless {
		'luggage' => $luggage,
		'http_host' => lc($$luggage{belt}->{request}->env->{HTTP_HOST}), # hostnames should always be lower-case
		'cookie_id' => 'omnitool_ticket_'.$ENV{OT_COOKIE_ID}, # suffix allows for multiple cookies / systems
														  # that $ENV var set in start_omnitool.bash
	}, $class;

	return $self;
	# kick off web_authentication() to get the web login tests going
}

# method to authenticate via an API key, which should be set in $$luggage{params}{api_key}
# we won't get here unless $$luggage{params}{api_key} is filled
sub api_key_athentication {
	my $self = shift;

	my ($remote_ip, $session_username,$tied_to_ip_address);

	# need the client IP for the key to verify
	$remote_ip = $self->{luggage}{belt}->{request}->address;

	# test the key
	($session_username,$tied_to_ip_address) = $self->{luggage}{db}->quick_select(qq{
		select username,tied_to_ip_address from user_api_keys where api_key_string=?
		and expiration_date >= curdate() and status='Active'
	},[ $self->{luggage}{params}{api_key}]);

	# if user not found, we have an error
	if (!$session_username) {
		$self->{luggage}{belt}->mr_zebra('ERROR: '.$self->{luggage}{params}{api_key}.' is not a valid/active API key.',2);

	# make sure it's tied to this IP address -- allow for multiple IPs
	# allow for 'Any' option - available to admins only
	} elsif ($tied_to_ip_address ne 'Any' && !$self->{luggage}{belt}->really_in_list($remote_ip, $tied_to_ip_address, "\n")) {
		$self->{luggage}{belt}->mr_zebra('ERROR: '.$self->{luggage}{params}{api_key}.' is not tied to '.$remote_ip.'.',2);

	# otherwise, we have a ticket to fly!
	} else {
		# sessions.pm should not create a session for this user/instance if they do not have access
		$self->{luggage}{session} = omnitool::common::session->new(
			'username' => $session_username,
			'db' => $self->{luggage}{db},
			'app_instance' => lc($self->{luggage}{hostname}),
			'hostname' => $self->{luggage}{hostname},
			'belt' => $self->{luggage}{belt}
		);

		# see if they have a timezone name from a previous web authentication
		($self->{luggage}{timezone_name}) = $self->{luggage}{db}->quick_select(qq{
			select timezone_name from otstatedata.authenticated_users where username=?
			and timezone_name like '%/%' order by code desc limit 1
		},[ $session_username]);

		# final test to make sure they have access
		if (!$self->{luggage}{session}->{tools_keys}[0] || $self->{luggage}{session}->{no_access}) {
			$self->{luggage}{belt}->mr_zebra('ERROR: You have no access rights in this Application Instance.',2);
		}
		# otherwise, we are good to go and can return silently
	}

}

# subroutine to drive the web browser authenatication process
# checks to see if they are authenticated, and set up the session here if they are
# if session finds no keys, they have no access and we need to inform them via show_login_screen()
# if they aren't authenticated, call show_login_screen() to show the login form
sub web_authentication {
	my ($cookies, $authentication_code, $c, $conn, $hostname, $j, $luggage, $timezone_name, $session_username, $our_output, $require_password_change, $ui);

	# myself has my parameters
	my $self = shift;

	# need the client IP for a variety of purposes
	$self->{luggage}{remote_ip} = $self->{luggage}{belt}->{request}->address;
	# I was tying cookies to remote IP addresses, but I took that out for
	# being too unwiedly, especially when you have TWCWIFI changing up your IP every 5 min.
	# Still used for limiting login attempts to 10.

	# if they sent a username and password, test their credentials
	if ($self->{luggage}{params}{username} && $self->{luggage}{params}{password}) {
		$self->test_their_credentials();
	}

	# grab the cookie
	$authentication_code = $self->{luggage}{belt}->{request}->cookies->{ $self->{cookie_id} };

	if ($authentication_code) { # has cookie, is it still a valid session for this client's IP address?

		# have they successfully authenticated already?
		# and what are their password-status variables?
		($session_username,$timezone_name,$require_password_change) = $self->{luggage}{db}->quick_select(qq{
			select username,timezone_name,require_password_change from otstatedata.authenticated_users
			where concat(rand_string,'_',code)=?
		},[$authentication_code]);
		# also grab any previously-set timezone_name which they may have
		# sent (via their browser)

		# taking out IP restriction: and remote_ip=? / $self->{luggage}{remote_ip}
		# we will save it to the table though, for possible login checks

		# if they have authenticated already, we should check to see that they have access to this instance
		if ($session_username) {
			# sessions.pm should not create a session for this user/instance if they do not have access
			$self->{luggage}{session} = omnitool::common::session->new(
				'username' => $session_username,
				'db' => $self->{luggage}{db},
				'app_instance' => lc($self->{luggage}{hostname}),
				'hostname' => $self->{luggage}{hostname},
				'belt' => $self->{luggage}{belt}
			);

			# did they or their browser send a timezone_name?
			# update the table and add it to our luggage
			if ($self->{luggage}{params}{set_timezone_name}) {

				# update the DB:
				$self->{luggage}{db}->do_sql(qq{
					update otstatedata.authenticated_users
					set timezone_name=? where concat(rand_string,'_',code)=?
				},[$self->{luggage}{params}{set_timezone_name}, $authentication_code]);

			}

			# get it into the luggage
			if (!$timezone_name && $self->{luggage}{params}{set_timezone_name}) {
				$self->{luggage}{timezone_name} = $self->{luggage}{params}{set_timezone_name};
			} else {
				$self->{luggage}{timezone_name} = $timezone_name;
			}
			# default to GMT
			$self->{luggage}{timezone_name} ||= 'Etc/UTC';

			# need to have access to at least one tool to have access to this application instance
			# stop them for having no access to this instance if that is the case
			$self->{luggage}{no_access} = 1 if !$self->{luggage}{session}->{tools_keys}[0] || $self->{luggage}{session}->{no_access};
		}
	}

	# if they don't have access or have not authenticated, we need to instruct them to authenticate
	if ($self->{luggage}{no_access} || !$self->{luggage}{session}->{username}) {
		# where are we trying to get to?
		$self->{luggage}{params}{requested_uri} = $self->{luggage}{uri} if !$self->{luggage}{params}{requested_uri};
		# if they are calling for main.pm (or another handler), then we can present the main login screen
		if ($self->{luggage}{params}{requested_uri} =~ /^\/(ui|tool)/) {
			$self->{luggage}{belt}->mr_zebra('Authenication needed.',2);

		} elsif ($self->{luggage}{no_access}) {

			# use Data::Dumper;
			# $self->{luggage}{belt}->mr_zebra(Dumper($self->{luggage}),2);
			# $self->{luggage}{belt}->mr_zebra('You do not have access to this area.',2);
			$ui = omnitool::common::ui->new(
				'luggage' => $self->{luggage},
			);
			$our_output = $ui->error_no_access();
			$self->{luggage}{belt}->mr_zebra($our_output);

		# if they just authenticated and are getting the cookie, avoid showing the login form
		} elsif ($self->{just_authenticated}) {
			$self->show_redirection_page();

		# otherwise, plain text telling omnitool_routines.js to re-authenticate
		} else {
			# use the subroutine below to show the login form
			$self->show_login_screen();
		}

	# if we know who they are, but they want or need to change their password, show the change-password screen
	} elsif ($self->{luggage}{params}{change_my_password} || $require_password_change ne 'No') {
		$self->show_password_change_screen($require_password_change);
	}

}

# subroutine to check the user's credentials; returns 0 if authentication failure;
# otherwise sets cookie and reloads the page
sub test_their_credentials {
	my ($valid_user, $random_string, $code, $now);

	# myself has my parameters
	my $self = shift;

	# if they have recaptcha enabled, test that portion of the form
	if ($ENV{RECAPTCHA_SITEKEY} && $ENV{RECAPTCHA_SECRET}) {
		my $recaptcha_verify = $self->{luggage}{belt}->recaptcha_verify();
		if (!$recaptcha_verify) { # recaptcha fail = authentication fail
			return 0;
		}
	}

	# can pass an argument to tell it not to set cookie & redirect
	# useful when you want to utilize this module only for credential-testing
	my ($skip_cookie) = @_;

	my ($password_is_expired, $require_password_change);

	# default: do not require password change
	$require_password_change = 'No';

	# notice how nicely-encrypted that password is
	($valid_user) = $self->{luggage}{db}->quick_select(qq{
		select count(*) from omnitool_users
		where username=? and password=SHA2(?,224)
	},[$self->{luggage}{params}{username}, $self->{luggage}{params}{password}]);

	# if they don't exist in the main/basic user database, see if there is an
	# system-specific authentication plugin/helper installed for this application
	if (!$valid_user) {
		# this will be saved directly under applications, as users authenticate system-wide
		if (eval "require omnitool::applications::auth_helper") { # it exists and loaded
			# notice that it requires the %$luggage and returns a 1 for success or 0 for fail
			$valid_user = omnitool::applications::auth_helper::authentication_helper($self->{luggage});
		}

	# if we authenticated them via the omnitool_users table, check their password status
	} else {
		($password_is_expired, $require_password_change) = $self->{luggage}{db}->quick_select(qq{
			select (password_set_date < date_sub(curdate(),interval 90 day)),
			require_password_change from omnitool_users
			where username=?
		},[$self->{luggage}{params}{username}]);

		# we will put a value into the otstatedata.authenticated_users table below.
		$require_password_change = 'Expired' if $password_is_expired;

	}

	# if they are valid, and we are not in plack (or want to skip the cookie), return the positive value
	if ($valid_user && ($skip_cookie || !$self->{luggage}{belt}->{response})) {
		return $valid_user;
	# if we are in plack world, log their authentication success and send them on their way
	} elsif ($self->{luggage}{belt}->{response} && $valid_user) {

		# $self->{luggage}{belt}->logger('Trying to set the cookie - '.$valid_user.' - '.$self->{luggage}{belt}->{response},'login_errors');

		# we need a random string; this makes the cookie more secure so that it doesn't just have a set of incremental values
		# so that someone could guess a probable next value...they'd need a client's IP address too.  I am sure I am missing
		# something here; use the utility_belt, as it is a reliable subroutine
		$random_string = $self->{luggage}{belt}->random_string(16);

		# save the successful authentication into the database
		$self->{luggage}{db}->do_sql(qq{
			insert into otstatedata.authenticated_users
			(login_time,rand_string,username,remote_ip,require_password_change)
			values (unix_timestamp(),?,?,?,?)
		},[$random_string, $self->{luggage}{params}{username}, $self->{luggage}{remote_ip}, $require_password_change]);
		$code = $self->{luggage}{db}->{last_insert_id}; # for cookie

		# no more than every 100 seconds, clear any records for them older than 48 hours
		$now = time();
		if ($now =~ /30$/) {
			$self->{luggage}{db}->do_sql(qq{
				delete from otstatedata.authenticated_users
				where username=? and login_time < (unix_timestamp()-172800)
			},[$self->{luggage}{params}{username}]);
		}

		# cookie domain is set in environmental vars; default to primary domain
		$ENV{OT_COOKIE_DOMAIN} ||= '.omnitool.org';

		# reset their login attempt counter. useful for testing and if they are on multiple browsers
		$self->{luggage}{db}->do_sql(qq{
			delete from otstatedata.login_attempts_counter where remote_ip=?
		},[$self->{luggage}{remote_ip}]);

		# bon voyage - have a nice cookie with the authenication ID for the road
		$self->{luggage}{params}{requested_uri} ||= '/'; # default to root
		$self->{luggage}{belt}->{response}->cookies->{ $self->{cookie_id} } = {
			value => $random_string.'_'.$code,
			domain  => $ENV{OT_COOKIE_DOMAIN},
			path => '/',
			expires => '+24h'
		};
		# useing the redirect with the cookie is the most reliable way to set it
		$self->{luggage}{belt}->{response}->redirect($self->{luggage}{params}{requested_uri});

		# tell web_authentication() to not present login form
		$self->{just_authenticated} = 1;
		# otherwise, if they are not valid, web_authentication() will present the login form
	}
}

# subroutine to prepare and display the login form screen
sub show_login_screen {
	my ($attempts_count, $belt, $c, $code, $hostname, $login_attempts_so_far, $new_session, $random_string, $remaining_attempts, $requested_uri, $tt, $username, $valid_user, %tt_vars);

	# myself has my parameters
	my $self = shift;

	# i am going to allow you to load this page 10 times in a 5-minute period without logging in
	($login_attempts_so_far) = $self->{luggage}{db}->quick_select(qq{
		select attempts_count from otstatedata.login_attempts_counter
		where remote_ip=? and last_attempt_time > unix_timestamp()-300
	},[$self->{luggage}{remote_ip}]);
	# note that if last_attempt_time is before five minutes ago, $login_attempts_so_far should be 0

	# add one to that count
	$attempts_count = $login_attempts_so_far + 1;
	$self->{luggage}{db}->do_sql(
		qq{replace into otstatedata.login_attempts_counter
		(remote_ip,last_attempt_time,attempts_count) values (?,unix_timestamp(),?)
	},[$self->{luggage}{remote_ip}, $attempts_count]);

	# for our message on the screen
	$remaining_attempts = 10 - $attempts_count;

	# if they have no access, we will print a nice message via login_page_html(); $no_access is the $session_username from above
	if ($self->{luggage}{no_access}) {
		$tt_vars{no_access} = 'No Access';

		# log this issue
		$tt_vars{error_id} = $self->{luggage}{belt}->logger($self->{luggage}{remote_ip}.' not permitted access to '.$self->{http_host},'login_errors');

	# if they sent both and are here, their password or username is incorrect
	} elsif ($self->{luggage}{params}{username} && $self->{luggage}{params}{password}) {
		$tt_vars{password_message} = 'Incorrect Password <br/> '.$remaining_attempts.' attempts remaining.';
		$tt_vars{error_id} = $self->{luggage}{belt}->logger('Incorrect password for '.$self->{luggage}{params}{username},'login_errors');

	# maybe they didn't sent both?
	} elsif ($self->{luggage}{params}{username}) {
		$tt_vars{password_message} = 'Please provide both a username and a password. '.$remaining_attempts.' attempts remaining.';
	}

	# if they have loaded this page 10 times without successfully logging-in, we need to lock them out
	if ($remaining_attempts < 1) { # frozen out for five minutes
		$tt_vars{locked_out} = 'Locked Out';
		$tt_vars{error_id} = $self->{luggage}{belt}->logger($self->{luggage}{remote_ip}. ' locked out due to too many login attempts.','login_errors');
	}

	# at this point, we need to present the HTML for the login page, which is
	# quite extensive, but thankfully we have a template for template-toolkit

	# we need the name of the application
	($tt_vars{instance_name}, $tt_vars{instance_contact_email}, $tt_vars{ui_logo}) = $self->{luggage}{db}->quick_select(
		'select name,contact_email, ui_logo from instances where hostname=?',
	[$self->{luggage}{hostname}]);

	# don't let that be blank
	$tt_vars{instance_contact_email} ||= $ENV{OMNITOOL_ADMIN};

	# some other variables needed for template toolkit to process login_page.html
	$tt_vars{omnitool_version} = $self->{luggage}{omnitool_version};
	$tt_vars{username} = $self->{luggage}{params}{username};
	$tt_vars{requested_uri} = $self->{luggage}{params}{requested_uri};
	$tt_vars{ui_logo} ||= 'ginger_face.png';

	# support for recaptcha?  only if the vars are filled in
	$tt_vars{recaptcha_sitekey} = $ENV{RECAPTCHA_SITEKEY};

	# if they are not locked out and aren't designated as having no access, then show the login box
	$tt_vars{login_box} = 1 if !$tt_vars{locked_out} && !$tt_vars{no_access};

	# use the template toolkit via the utility belt to process our login page and send it out
	$self->{luggage}{belt}->template_process(
		'template_file' => 'login_page.tt',
		'template_vars' => \%tt_vars,
		'send_out' => 1,
		'stop_here' => 1,
	);
}

# subroutine to prepare and show the password-change screen
sub show_password_change_screen {
	my ($attempts_count, $belt, $c, $code, $hostname, $login_attempts_so_far, $new_session, $random_string, $remaining_attempts, $requested_uri, $tt, $username, $valid_user, %tt_vars);

	# myself has my parameters
	my $self = shift;

	my ($require_password_change) = @_;

	my (%tt_vars, $is_current_password);

	# default mode is to show the change-password box
	$tt_vars{change_my_password} = 1;

	# we need the name of the application
	($tt_vars{instance_name}, $tt_vars{instance_contact_email}, $tt_vars{ui_logo}) = $self->{luggage}{db}->quick_select(
		'select name,contact_email, ui_logo from instances where hostname=?',
	[$self->{luggage}{hostname}]);

	# don't let that be blank
	$tt_vars{instance_contact_email} ||= $ENV{OMNITOOL_ADMIN};

	# some other variables needed for template toolkit to process login_page.html
	$tt_vars{omnitool_version} = $self->{luggage}{omnitool_version};
	$tt_vars{requested_uri} = $self->{luggage}{uri};
	$tt_vars{ui_logo} ||= 'ginger_face.png';

	# explain the reason they are here, if being forced
	if (!$self->{luggage}{params}{change_my_password} && $require_password_change eq 'Expired') {
		$tt_vars{password_message} = 'Your password is over 90 days old and must be changed.';

	} elsif (!$self->{luggage}{params}{change_my_password} && $require_password_change eq 'Yes') {
		$tt_vars{password_message} = 'The Admin is requiring a password change at this time.';
	}

	# do the passowrd/confirm password values match?
	if ($self->{luggage}{params}{new_password} ne $self->{luggage}{params}{confirm_new_password}) {
		$tt_vars{password_message} = 'Supplied passwords do not match.  Please try again.';

	# require longer password with mixed-case and numbers
	} elsif ($self->{luggage}{params}{new_password} && (length($self->{luggage}{params}{new_password}) < 10 || $self->{luggage}{params}{new_password} !~ /[A-Z]/ || $self->{luggage}{params}{new_password} !~ /[a-z]/ || $self->{luggage}{params}{new_password} !~ /\d/)) {
		$tt_vars{password_message} = 'New password must be at least 10 characters with at least one upper-case letter, one lower-case letter, and one number.';

	# make sure the password is not the same as the old one
	} elsif ($self->{luggage}{params}{new_password}) {
		($is_current_password) = $self->{luggage}{db}->quick_select(qq{
			select count(*) from omnitool_users
			where username=? and password=SHA2(?,224)
		},[$self->{luggage}{session}{username}, $self->{luggage}{params}{new_password}]);

		# tsk, tsk
		if ($is_current_password) {
			$tt_vars{password_message} = 'You can not re-use the current password.  Please select a NEW password.';

		# otherwise, update the password for them
		} else {

			# make it so they are up to date on pasword changes
			$self->{luggage}{db}->do_sql(qq{
				update omnitool_users set password=SHA2(?,224), require_password_change='No',
				password_set_date=curdate() where username=?
			},[$self->{luggage}{params}{new_password}, $self->{luggage}{session}{username}]);

			# no endless looping please
			$self->{luggage}{db}->do_sql(qq{
				update otstatedata.authenticated_users
				set require_password_change='No' where username=?
			},[$self->{luggage}{session}{username}]);

			# cancel showing the password box and instead show the success message
			$tt_vars{change_my_password} = 0;
			$tt_vars{password_was_changed} = 1;

			$tt_vars{requested_uri} =~ s/\/\?change_my_password\=1//;
		}
	}


	# use the template toolkit via the utility belt to process our login page and send it out
	$self->{luggage}{belt}->template_process(
		'template_file' => 'login_page.tt',
		'template_vars' => \%tt_vars,
		'send_out' => 1,
		'stop_here' => 1,
	);
}

# very simple subroutine to print 'Redirecting...' after they authenticated
sub show_redirection_page {
	my $self = shift;
	$self->{luggage}{belt}->mr_zebra('Authentication Successful.  Redirecting...',2);
}

1;

__END__

=head1 omnitool::common::login_system

The general way this module works is to provide and power the authentication / login page for the Web
UI of OmniTool.  It gets called from 'step seven' in luggage.pm's pack_luggage() routine, and acts
as follows:

1. pack_luggage() calls web_authentication() above.  If a username and password were sent,
that means the login form was completed, and we get sent to step two below.

Otherwise, it will check for the 'omnitool_ticket_X' cookie and resolve that to their username in
otstatedata.  The 'X' in 'omnitool_ticket_X' defaults to $ENV{OT_COOKIE_ID}, which is set in
'start_omnitool.bash'.  If that all checks out, a session will be created in $self->{luggage}{session}.
If they have at least one tool for this session's application instance, they are good to go (no
further action here). If they did not authenticate, have no cookie, or have no tools
in there session (and no access), we go to step three.

2. web_authentication() calls test_their_credentials(); this happens close to the top,
if $self->{luggage}{params}{username} and $self->{luggage}{params}{password} are filled in,
indicating the login form was submitted. If those credentials pass the test, the cookie
is set and the client is redirected to the URI they were attempting to access.  Otherwise,
web_athentication() continues execution (which may involve testing the new cookie).

Regarding 'pass the test' on the username/password; that means first looking in the
'omnitool_users' table in the current OmniTool Admin database, and if that fails, then
checking for a omnitool::applications::auth_helper Perl module with an authenticate()
subroutine.  This is your system-wide authentication helper, where you can write a custom
routine to authenicate users.  It accepts the %$luggage hash and returns a 1 for success
or 0 for authentication failure.

3. web_authentication calls show_login_screen() if there was no cookie or the user
has no access.  This routine will prepare variables to send to the login_page.tt
template-toolkit template, and instruct the utility_belt to display that processed
template.  It also attempts to prevent the same client IP from submitting this login
form more than 10 times in five minutes.

Other key points

1. Users must have cookies enabled for this to work.
2. They do have to authenticate to see they do not have access to this instance.  Sadly,
the only way to determine that situation for a valid user.

API CLIENT MODE

If a client is accessing OmniTool programmatically outside of the Web UI, they will authenticate
by providing an API Key obtained from 'Manage User API Keys' in the OmniTool Admin Instance driving
their target Application.  This key will be tied to their username and client machine's IP address.
It will also have an Expiration date.  The key will be in $$luggage{params}, and for this we have the
api_key_athentication() method above.  It's very straightforward, and essentially tests that their key
is valid.  API keys work very similiarly to the cookies for the login screen.

Please see the notes in Tool.pm for more details on API mode.
