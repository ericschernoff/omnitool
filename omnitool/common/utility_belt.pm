package omnitool::common::utility_belt;

# please see pod documentation included below
# perldoc omnitool::common::utility_belt

$omnitool::common::utility_belt::VERSION = '6.0';
# first time I've called it this, but many have been around in one form or another

# need some date/time toys
use Date::Format;
use DateTime;
use Date::Manip::Date;

# for show_data_structure
use Data::Dumper;

# for logging via logger()
use File::Slurp;

# for utf8 support
use utf8;
use Encode qw( encode_utf8 );

# for encoding and decoding JSON
use JSON;

# for setting up db objects in get_instance_db_object
use omnitool::common::db;

# for converting ranges of numbers to lists of numbers
use Number::Range;

# for enabling the TemplateToolkit via template_process()
use Template;

# and for putting TemplateToolkit on the client-side :-)
use Jemplate;

# for archiving log files
use Gzip::Faster;

# for testing recaptcha submissions
use WWW::Mechanize;

# for benchmarker routine
use Benchmark ':hireswallclock';

# time to grow up
use strict;

# create ourself; main item we shall include is a JSON de/en-coding object (see below)
sub new {
	my $class = shift;

	my $self = bless {
		'all_hail' => 'ginger', 		# for proof-of-life
		'json' => JSON->new->utf8,		# for json en/de-code
		'created' => time(),			# for verifying the same $belt across requests
		'start_benchmark' => Benchmark->new,	# for benchmarker() below
		# 'request' => $request,		# the Plack request object; will get filled-in by pack_luggage()
		# 'response' => $response,		# the Plack response object; will get filled-in by pack_luggage()
	}, $class;
}

# method to log benchmarks for execution times; useful for debugging and finding chokepoints
sub benchmarker {
	my $self = shift;
	my ($log_message,$log_type) = @_;

	# return if no log message
	return if !$log_message;

	# default log_type to 'benchmarks'
	$log_type ||= 'benchmarks';

	# figure the benchmark for this checkpoint / log-message
	# will be from the creation of $self, which is practically the start of the execution
	my $right_now = Benchmark->new;
	my $benchmark = timediff($right_now, $self->{start_benchmark});

	# now log out the benchmark
	$self->logger($log_message.' at '.timestr($benchmark), $log_type);

	# all done
}

# start routine to turn an array (reference) to flat string, separated by commas (or whatever)
sub comma_list {
	my $self = shift;

	# declar vars
	my ($delimiter, $list, $nice_list, $piece, $real_list);

	# grab args
	($list,$delimiter) = @_;

	# default delimiter is a comma
	$delimiter ||= ',';

	# make it sort, no dups
	$real_list = $self->uniquify_list($list);

	# turn that list into a nice comma-separated list
	$nice_list = join($delimiter, @$real_list);

	# send it out
	return $nice_list;
}

# subroutine to give numbers commas, like dollars
# ripped off of the Perl Cookbook, page 85
sub commaify_number {
	my $self = shift;
	my $num = $_[0];
	return '0' if !$num;
	# round to two decimels
	$num = sprintf("%.2f", $num) if $num =~ /\./;
	# convert 1000 to 1,000
	$num = reverse $num;
	$num =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	# send it out
	return scalar reverse $num;
}

# prepare SQL logic to search against standard data_code values
sub datacode_query {
	my $self = shift;
	my ($data_codes,$negative) = @_;

	return '' if !$$data_codes[0]; # stop if empty

	# this way might be faster, although it doesn't make any sense
	# use it when there is more than 2500 entries (for now)
	if (!$negative && scalar(@$data_codes) > 2500) {
		my $q_marks = $self->q_mark_list(scalar(@$data_codes));
		return (qq{concat(code,'_',server_id) in ($q_marks)},$data_codes);
	}

	# this way uses the primary key:

	my ($dc, $code, $server_id, $searches, $search_logic, $q_marks, $bind_values);

	foreach $dc (@{$data_codes}) {
		($code,$server_id) = split /_/, $dc;
		push(@$searches,qq{(code=? and server_id=?)});
		push(@$bind_values,$code,$server_id);
	}
	if ($$searches[1]) { # combine them
		$search_logic =  join(' or ', @$searches); # comma_list likes to uniquify lists, and that don't work
		$search_logic = '('.$search_logic.')';
	} else {
		$search_logic = $$searches[0];
	}

	if ($negative) { # they want this to be a 'not in' type of query
		$search_logic = '(0 = '.$search_logic.')';
	}

	return ($search_logic,$bind_values);

}

# start the dateFix subroutine, where we humanify database dates
sub date_fix {
	my $self = shift;
	my ($date,$year,$month,$day,$dt);
	($date) = @_; # will be in YYYY-MM-DD format

	# no wise-guys
	return 'Sept. 4, 1976' if $date !~ /[0-9]{4}\-[0-9]{2}\-[0-9]{2}/;

	# we used to use mysql, but let's use perl instead

	$dt = $self->get_datetime_object($date.' 00:00');

	# simple enough
	if ($dt->month_abbr eq 'May') {
		return 'May '.$dt->day.', '.$dt->year;
	} else {
		return $dt->month_abbr.'. '.$dt->day.', '.$dt->year;
	}
}


# start the diff_percent subroutine, where we calculate the growth/shrink percentage between two numbers
sub diff_percent {
	my $self = shift;

	# declare vars and grab args
	my ($difference, $first, $second);

	($first,$second) = @_; # first number is 'base'

	if ($first > 0) { # calculate the growth, and leave one decimel
		$difference = 100 * (($second - $first) / $first);
		$difference = sprintf("%.1f", $difference);
	} else { # not applicable
		$difference = qq{N/A};
	}

	# send it out
	return $difference;

}

# subroutine to calculate the number of days, hours, or minutes SINCE an epoch
sub figure_age {
	my $self = shift;

	my ($past_epoch, $delta, $minutes, $hours, $days, $weeks, $dt1, $dt2, $dur, $months);

	# required argument is the epoch to test against
	($past_epoch) = @_;

	# the argument they sent must be an integar, before the current timetamp
	if (!$past_epoch || $past_epoch =~ /\D/ || $past_epoch > time()) {
		return 'Unknown';
	}

	# get the delta and proceed accordingly
	$delta = time() - $past_epoch;

	# less than two minutes is really just now
	if ($delta < 120) {
		return 'Just now';

	# less than two hours: minutes
	} elsif ($delta < 7200) {
		$minutes = int($delta/60); # do whole numbers for this
		return $minutes.' minutes ago';

	# less than a day: hours
	} elsif ($delta < 86400) {
		$hours = sprintf("%.1f", ($delta/3600)); # one digit after decimel
		return $hours.' hours ago';

	# less than two weeks, get days
	} elsif ($delta < 1209600) {
		$days = sprintf("%.2f", ($delta/86400)); # two digits after decimel
		return $days.' days ago';

	# less than nine weeks, get weeks
	} elsif ($delta < 5443200) {
		$weeks = sprintf("%.2f", ($delta/604800)); # two digits after decimel
		return $weeks.' weeks ago';

	# otherwise, months
	} else {
		# DateTime.pm should have done this for us, but it seems to be a little buggy,
		# so we will presume 30.4 days in a month.  makes ense since months starts after 9 weeks
		$months = sprintf("%.1f", ($delta/2626560)); # one digit after decimel
		return $months.' months ago';

	}

}

# subroutine to calculate the number of days, hours, or minutes UNTIL an epoch
# i made the decision not munge figure_age to try and do both
sub figure_delay_time {
	my $self = shift;

	my ($delta, $minutes, $hours, $days, $weeks, $dt1, $dt2, $dur, $months);

	# required argument is the epoch to test against
	my ($future_epoch) = @_;

	# the argument they sent must be an integar, before the current timetamp
	if (!$future_epoch || $future_epoch =~ /\D/ || $future_epoch < time()) {
		return 'Unknown';
	}

	# get the delta and proceed accordingly
	$delta = $future_epoch - time();

	# less than two minutes is really just now
	if ($delta < 120) {
		return 'Right now';

	# less than two hours: minutes
	} elsif ($delta < 7200) {
		$minutes = int($delta/60); # do whole numbers for this
		return 'In '.$minutes.' minutes';

	# less than a day: hours
	} elsif ($delta < 86400) {
		$hours = sprintf("%.1f", ($delta/3600)); # one digit after decimel
		return 'In '.$hours.' hours';

	# less than two weeks, get days
	} elsif ($delta < 1209600) {
		$days = sprintf("%.2f", ($delta/86400)); # two digits after decimel
		return 'In '.$days.' days';

	# less than nine weeks, get weeks
	} elsif ($delta < 5443200) {
		$weeks = sprintf("%.2f", ($delta/604800)); # two digits after decimel
		return 'In '.$weeks.' weeks';

	# otherwise, months
	} else {
		# DateTime.pm should have done this for us, but it seems to be a little buggy,
		# so we will presume 30.4 days in a month.  makes ense since months starts after 9 weeks
		$months = sprintf("%.1f", ($delta/2626560)); # one digit after decimel
		return 'In '.$months.' months';

	}

}


# start subroutine for generating easily-sortable keys for a hash, up to the max number provided
sub get_sort_keys {
	my $self = shift;

	# declare vars
	my ($i, $number, @sort_keys);

	# grab arg -- the greatest number of our sort keys
	$number = $_[0];
	$number ||= 1000; # don't allow empty strings to create endless loops

	for ($i = 0; $i < $number; $i++) {
		while (length($i) < length($number)) { $i = '0'.$i; }
		push(@sort_keys,$i);
	}

	# send out arrayref
	return \@sort_keys;
}

# method to retrieve a database connection object for a specific instance
sub get_instance_db_object {
	my $self = shift;
	my ($instance_data_code, $db, $omnitool_admin_db) = @_;
	# needs to be primary key of instance, current omnitool::common::db object
	# and name of omnitool admin database which holds the instance
	# first two required, and if third is not filled, will assume provided
	# db object's current working DB --> REALLY SHOULD FILL THAT IN

	my ($right_db_obj, $database_hostname, $database_server_id);

	# first two are required
	return if !$instance_data_code || !$db->{created};

	# set default for $omnitool_admin_db
	$omnitool_admin_db ||= $db->{current_database};

	# use the method below to find this instance's database server hostname
	$database_hostname = $self->get_instance_db_hostname($instance_data_code,$omnitool_admin_db,$db);

	# even if the current connection is to the right server, we want a new $db object, keyed to the right omnitool admin DB
	$right_db_obj = omnitool::common::db->new($database_hostname,$omnitool_admin_db);

	# send it back
	return $right_db_obj;
}
# companion method to get_instance_db_object() to get the database server's hostname from the instance ID
# this is one spot we do raw SQL since the database_server_id is just the 'code' from the database_servers table
# separating out in case we need this elsewhere (like omnitool::applications::otadmin::tools::deploy_admin_database)
# i am not publicizing this one
sub get_instance_db_hostname {
	my $self = shift;

	# required arg are the data_code of the instance and the name of the omnitool admin db we are currently within
	my ($instance_data_code,$omnitool_admin_db,$db) = @_;
	return '' if !$instance_data_code || !$omnitool_admin_db;

	# do the lookup via (yikes) raw sql
	my ($database_server_id) = $db->quick_select(
		'select database_server_id from '.$omnitool_admin_db.qq{.instances where concat(code,'_',server_id)=?},
	[$instance_data_code]);

	# and the hostname
	my ($database_hostname) = $db->quick_select(
		'select hostname from '.$omnitool_admin_db.'.database_servers where code=?',
	[$database_server_id]);

	# ship it out
	return $database_hostname;
}

# simple routine to get a DateTime object for a MySQL date/time, e.g. 2016-09-04 16:30
sub get_datetime_object {
	my $self = shift;

	my ($time_string, $timezone_name) = @_;

	# default timezone is GMT
	$timezone_name ||= 'Etc/GMT';

	my ($dt, $year, $month, $day, $hour, $minute, $second);

	# be willing to just accept the date and presume midnight
	if ($time_string =~ /^\d{4}-\d{2}-\d{2}$/) {
		$time_string .= ' 00:00:00';
	}

	# i will generally just send minutes; we want to support seconds too, and default to 00 seconds
	if ($time_string =~ /\s\d{2}:\d{2}$/) {
		$time_string .= ':00';
	}

	# if that timestring is not right, just get one for 'now'
	if ($time_string !~ /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}$/) {

		$dt = DateTime->from_epoch(
			epoch => time(),
			time_zone	=> $timezone_name,
		);

	#  otherwise, get a custom datetime object
	} else {

		# have to slice-and-dice it a bit to make sure DateTime is happy
		$time_string =~ s/-0/-/g;
		($year,$month,$day,$hour,$minute,$second) = split /-|\s|:/, $time_string;
		$hour =~ s/^0//;
		$minute =~ s/^0//;

		# try to set up the DateTime object, wrapping in eval in case they send an invalid time
		# (which happens if you go for 2am on a 'spring-forward' day
		eval {
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day			=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				time_zone	=> $timezone_name,
			);
		};

		if ($@) { # if they called for an invalid time, just move ahead and hour and try again
			$hour++;
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day			=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				time_zone	=> $timezone_name,
			);
		}

	}

	# send it out
	return $dt;
}

# this method is meant to get an epoch for the occurance of a given time,
# localized to a time zone.  So for instance, the next time it will be 11am in
# America/Chicago.  That could be later today or it could be tomorrow morning.
# this is handy for scheduling jobs that need to run after a certain time in
# a certain location (i.e. turn off all lights in Albuquerque at 9pm)
sub get_epoch_for_next_local_time {
	my ($self) = shift;

	# required arg is the target time, in military format
	# optional arg is the time zone name
	# other optional arg tells us eitther to send the object out or
	# not to worry about making sure it's in the future; today is fine
	my ($target_time, $timezone_name, $dont_worry_about_the_future) = @_;

	my ($day, $dt, $hour, $minute, $month, $our_epoch, $today, $year);

	# fail if incorrect target time
	return '0' if !$target_time || $target_time !~ /^\d+:\d\d$/;

	# get the current date so we can build a DateTime
	$today = $self->todays_date();

	# default timezone for this is GMT
	$timezone_name ||= 'Etc/GMT';

	# use our central method to get the datetime object
	$dt = $self->get_datetime_object($today.' '.$target_time, $timezone_name);

	# turn that into an epocH
	$our_epoch = $dt->epoch;

	# if they do not care about making sure it's in the future, return it
	if ($dont_worry_about_the_future) {
		return $our_epoch;
	}

	# if that already came by, we mean tomorrow.  may have to move forward more than once
	# depending on the time / offset combination
	while (time() > $our_epoch) { # already passed, so they mean tomorrow
		$our_epoch += 86400;
	}

	# send out our finished product
	return $our_epoch;

}


# subroutine to take template toolkit templates and turn them into
# one javascript template, compiled and ready run in the web browser
# please see rant below on why this is so wonderful
sub jemplate_process {
	# gather myself up
	my $self = shift;
	my (%args) = @_;
	# %args could/should include:
	# $args{template_file_paths} = []; # array of paths to template toolkit files
	# $args{template_content} = ''; # scalar filled with a template toolkit template
							   # handy if you processed a base template first
	# $args{template_name} = '';	# scalar with name of the template for the Jemplate() javascript command
							# used in conjunction with 'template_content' and is required for that route
							# must have either something in $args{template_content} or in $args{template_file_paths}[0]
							# yes, you can have both
	# $args{stop_here} = 1; # optional; if filled, will send out to the browser
	#							otherwise, return the generated javascript text

	# declare some vars
	my (@template_files, $file, $js_compiled_template);

	# allow for the files in that array to be by default under
	# $ENV{OTHOME}/code/omnitool/static_files/templates if there is no filepath
	# at the same time, make sure there is at least one file which exists
	foreach $file (@{$args{template_file_paths}}) {
		if ($file !~ /\//) {
			$file = $ENV{OTHOME}.'/code/omnitool/static_files/system_wide_jemplates/'.$file;
		}
		# only process if it exists
		if (-e $file) {
			push(@template_files,$file);
		}
	}

	# make sure we have 'template_name' filled if we are using 'template_content'
	$args{template_content} = '' if !$args{template_name};

	# log an error if no process-able template files found
	if (!$template_files[0] && !$args{template_content}) {
		$args{template_file_paths}[0] = 'NO FILES SENT' if !$args{template_file_paths}[0];
		$self->logger("Did not receive anything in 'template_content' or any valid files in 'template_file_paths'. ".$self->comma_list($args{template_file_paths}),'jemplate');
		return;
	}

	# Jemplate.pm has many 'die' statements in there, and we want to trap those errors
	# likely to make this system-wide eventually
	local $SIG{'__DIE__'} = sub {
		$self->logger('Processing error: '.$_[0],'jemplate');
	};

	# alright, do the magic: try to compile the file(s)
	if ($template_files[0]) {
		eval {
			$js_compiled_template = Jemplate->compile_template_files(@template_files);
		};
	}

	# also see if there was any content sent
	if ($args{template_content} && $args{template_name}) {
		eval {
			$js_compiled_template .= "\n".Jemplate->compile_template_content($args{template_content}, $args{template_name});
		}
	}

	# trap any errors
	if ($js_compiled_template !~ /generated by Jemplate|Jemplate.templateMap/) {
		return 'No jemplates processed';
	}

	# flag it as JS for mr_zebra(), either now or later
	$js_compiled_template = "// This is Javascript, Mr. Zebra.\n".$js_compiled_template;

	# send it out to the client or return to the caller
	if ($args{send_out}) {
		$self->mr_zebra($js_compiled_template);
		# don't use mr_zebra to exit, as he will log as if an error
		exit if $args{stop_here};
	} else {
		return $js_compiled_template;
	}
}


# two json translating subroutines using the great JSON module
# First, make perl data structures into JSON objects
sub json_from_perl {
	my $self = shift;
	my ($data_ref) = @_;

	# for this, we shall go UTF8
	return $self->{json}->encode( $data_ref );
}

# Second, make JSON objects into Perl structures
sub json_to_perl {
	my $self = shift;
	my ($json_text) = @_;

	# first, let's try via UTF-8 decoding
	my $json_text_ut8 = encode_utf8( $json_text );
	my $perl_hashref = {};
	eval {
		$perl_hashref = $self->{json}->decode( $json_text_ut8 );
	};

	# failing that, use the plain style
	if ($@) {
		$perl_hashref = from_json( $json_text );
	}

	return $perl_hashref;
}
# see notes below for more details

# subroutine to log messages under the 'omnitool_logs' directory
sub logger {
	my $self = shift;

	# takes two args: the message itself (required), the log_type (optional, one word),
	my ($log_message,$log_type) = @_;
	# maybe in the future, we will offer an optional logs directory, but for now, let's keep it simple

	# return if no message sent; no point
	return if !$log_message;

	# default is 'errors' log type
	$log_type ||= 'errors';

	# no spaces or special chars in that $log_type
	$log_type =~ s/[^a-z0-9\_]//gi;

	my ($todays_date, $current_time, $log_file, $now);

	# what is today's date and current time
	$now = time(); # this is the unix epoch / also a quick-find id of the error
	$todays_date = $self->time_to_date($now,'to_date_db','utc');

	$current_time = $self->time_to_date($now,'to_datetime_iso','utc');
		$current_time =~ s/\s//g; # no spaces

	# target log file
	$log_file = $ENV{OTHOME}.'/log/'.$log_type.'-'.$todays_date.'.log';

	# sometimes time() adds a \n
	$log_message =~ s/\n//;

	# if they sent a hash or array, it's a developer doing testing.  use Dumper() to output it
	if (ref($log_message) eq 'HASH' || ref($log_message) eq 'ARRAY') {
		$log_message = Dumper($log_message);
	}

	# if we have the plack object (created via pack_luggage()), append to the $log_message
	if ($self->{request}) {
		$log_message .= ' | https://'.$self->{request}->env->{HTTP_HOST}.$self->{request}->request_uri();
	}

	# append to our log file via File::Slurp
	write_file( $log_file, {append => 1}, 'ID: '.$now.' | '.$current_time.': '.$log_message."\n" ) ;

	# if running in script mode (outside of plack), archive any logs older than a week
	my ($archive_directory, $log_directory_match, @log_files, $log_file, $file_age, $archive_file, $gzipped_log);
	if (!$self->{request}) {
		# where they are and where they go
		$archive_directory = $ENV{OTHOME}.'/log/archive';
		$log_directory_match = $ENV{OTHOME}.'/log';
		# make the archive directory if it does not exist
		mkdir $archive_directory if !(-d $archive_directory);
		# find the current/active logs
		@log_files = <$log_directory_match/*.lo*>; # get the starlet logs in there too
		foreach $log_file (@log_files) {
			# only affect logs older than a week
			$file_age = time() - (stat($log_file))[10];
			next if $file_age < 608400;
			# figure the new name under 'archive'
			($archive_file = $log_file) =~ s/\/log\//\/log\/archive\//;
			$archive_file .= '.gz';
			# gzip the file without using system commands
			eval {
				$gzipped_log = gzip_file ($log_file);
				write_file($archive_file, $gzipped_log);
				# delete the old files
				unlink($log_file);
			}; # sometimes, you get a little bit of a race
		}
	}

	# return the code/epoch for an innocent-looking display and for fast lookup
	return $now;
}

# method to get a list of month names, based on number of months back and forward
sub month_name_list {
	my $self = shift;

	my ($months_back, $months_forward) = @_;

	my ($dt, $total_interval, $n, $months_list);

	# reasonable defaults
	$months_back ||= 24;
	$months_forward ||= 12;

	# make sure they are integers
	$months_back = int($months_back);
	$months_forward = int($months_forward);

	# what's our total interval
	$total_interval = $months_back + $months_forward;

	# get a DateTime object based on the current time zone
	$dt = $self->get_datetime_object( $self->todays_date(), $self->{timezone_name} );

	# go back to the first month then want
	$dt->subtract( months => $months_back);

	# add in the first month
	$months_list = [ $dt->month_name().' '.$dt->year() ];

	# now increment one month until we have done the total interval
	$n = 1;
	while ($n < $total_interval) {
		# add one month
		$dt->add( months => 1);

		# add to list
		push( @$months_list, $dt->month_name().' '.$dt->year() );

		# increment
		$n++;
	}

	# ship it out
	return $months_list;
}

# subroutine to deliver html & json out to the client; I am sorry for the cutesy name
# if the argument is a string, send as either HTML or text; if a ARRAY or HASH reference, send
# as a json object
sub mr_zebra {
	my $self = shift;
	my ($content,$stop_here,$content_type,$content_filename) = @_;

	# if not in Plack/PSGI land, we will skip working with $self->{response}

	# $content needs to be one of a text/html string, an ARRAYREF or a HASHREF
	my $ref_type = ref($content);

	my ($error_id, $die_text);

	if ($stop_here == 1) { # if $stop_here is a 1, we are stopping due to an error condition
		# if it is plain text, we should most likely log the error message sent to us
		# and just present the error ID
		# exception is if you're an OT developer running a script; in that case,
		# set the 'OT_DEVELOPER' in your environmental vars

		if (!$ENV{OT_DEVELOPER} && length($content)) { # it is plain text
			$error_id = $self->logger($content,'fatals'); # 'these errors go into the 'fatals' log
			# present the error ID instead
			$content = 'Execution failed; error ID: '.$error_id."\n";
			$ref_type = ''; # make sure it gets treated as plain text;
		# otherwise, send the text with 'Execution failed' to try and pop the error modal.
		# this works nicely in 'dev' mode
		} elsif ($ENV{OT_DEVELOPER} && length($content)) {
			$content = 'Execution failed: '.$content;
		}
	}

	# if they sent a valid content type, no need to change it
	if ($content_type =~ /\//) {
		# nothing to do here
	} elsif ($ref_type eq "HASH" || $ref_type eq "ARRAY") { # make it into json
		$content_type = 'application/json';
		$content = $self->json_from_perl($content);

	} elsif ($content =~ /^\/\/ This is Javascript, Mr. Zebra./) { # it is 99% likely to be Javascript
		$content_type = 'text/javascript';

	} elsif ($content =~ /^\/\* This is CSS, Mr. Zebra./) { # it is 99% likely to be CSS
		$content_type = 'text/css';

	} elsif ($content =~ /<\S+>/) { # it is 99% likely to be HTML
		$content_type = 'text/html';

	} elsif (!$ref_type && length($content)) { # it is plain text
		$content_type = 'text/plain';

	} else { # anything else? something of a mistake, panic a little
		$content_type = 'text/plain';
		$content = 'ERROR: The resulting content was not deliverable.';

	}

	# if in Plack, pack the response for delivery
	if ($self->{response}) {
		$self->{response}->content_type($content_type);
		if ($content_filename) {
			$self->{response}->header('Content-Disposition' => 'attachment; filename="'.$content_filename.'"');
		}
		$self->{response}->body($content);
	} else { # print to stdout
		print $content;
	}

	if ($stop_here) { # if they want us to stop here, do so; we should be in an eval{} loop to catch this
		$die_text = "Execution stopped.";
		$die_text .= '; Error ID: '.$error_id if $error_id;
		die $die_text;
	}

}

# subroutine to prepare a comma-separated list of X number of question marks
# useful when readying an INSERT or UPDATE with placeholders
sub q_mark_list {
	my $self = shift;
	my ($num) = @_;

	my ($count,$q_marks);

	$num ||= 1; # at least one

	# easy enough ;)
	$count = 1;
	while ($count <= $num) {
		$q_marks .= '?,';
		$count++;
	}

	# delete last ,
	chop($q_marks);

	return $q_marks;

}

# subroutine for generating a random string
# stolen from http://stackoverflow.com/questions/10336660/in-perl-how-can-i-generate-random-strings-consisting-of-eight-hex-digits
sub random_string {
	my $self = shift;
	my ($length) = @_;
	# default that to 10
	$length ||= 10;

	my (@chars,$string);

	@chars = ('0'..'9', 'A'..'F');
	while($length--){
		$string .= $chars[rand @chars]
	};

	return $string;
}

# method to convert a comma-list of numbers and ranges to a proper list of numbers
sub range_list {
	my $self = shift;

	my ($list_of_numbers) = @_;

	# no bad chars
	$list_of_numbers =~ s/[^0-9\-\,]//g;

	# return if that leaves nothing
	return qq{Bad string sent.  Send something like '1,2,3,5-8,10'} if $list_of_numbers !~ /\d/;

	# Number::Range likes 1..10 instead of 1-10
	$list_of_numbers =~ s/-/../g;

	# new favorite perl module ;)
	my $range = Number::Range->new($list_of_numbers);
	my @numbers = $range->range;

	# send out our comma-separated list
	return $self->comma_list(\@numbers);

}

# subroutine to check to see if a value is included in a delimited list
sub really_in_list {
	my $self = shift;
	# declare vars
	my ($delimiter, $end, $list, $middle, $start, $string);

	# grab args
	($string,$list,$delimiter) = @_;
	# the string to check for, the delimiter of the string, and the delimited list to check in

	# default $delimiter to a comma
	$delimiter ||= ',';

	# different versions for different modes
	# prep for any weird chars in the vars they sent
	$start = quotemeta($string.$delimiter);
	$middle = quotemeta($delimiter.$string.$delimiter);
	$end = quotemeta($delimiter.$string);

	if ($list eq $string || $list =~ /$middle|^$start|$end\Z/) {
		return (1);
	} else {
		return (0);
	}
}

# method to verify recaptcha fields in form submissions
# returns a 1 for success / 0 for fail
sub recaptcha_verify {
	my $self = shift;

	# step zero: make sure they checked the box
	my $recaptcha_val = $self->{request}->param('g-recaptcha-response');
	if (!$recaptcha_val) {
		return 0;
	}

	# step one: launch Mechanize
	my $mech = WWW::Mechanize->new(
		timeout => 60,
		cookie_jar => {},
		keep_alive => 1,
		ssl_opts => {
			verify_hostname => 0,
		},
		'agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36',
	);

	# step two: send the rquest
	my $res = $mech->post( 'https://www.google.com/recaptcha/api/siteverify', [
		'secret' => $ENV{RECAPTCHA_SECRET},
		'remoteip' => $self->{request}->address,
		'response' => $recaptcha_val,
	]);

	# decode results
	my $content = $mech->content();
	if ($content =~ /success\"\: true/) { #person!
		return 1;
	} else { # dman robot
		return 0;
	}

}

# handy routine for debugging: show the contents of a hashref (anything really)
sub show_data_structure {
	my $self = shift;
	my ($data) = $_[0];

	# this is really just an alias for Data::Dumper with some 'pre' thrown in
	return "<pre>\n".Dumper($data)."\n</pre>";
}

# start subroutine to turn an array into a cool sql IN list, i.e 'a','b','c'
# use comma_list for lists of integers
sub sql_list {
	my $self = shift;

	# declar vars
	my ($list, $real_list, $piece, $nice_list,@my_list);

	# grab args
	$list = $_[0];	# reference to array, probably un-sorted array full of duplicates

	# or it could be a scalar of comma-delimited items
	if (!ref($list)) {
		@my_list = split /\,/, $list;
		shift @my_list if $my_list[0] !~ /[0-9a-z]/i; # shift off first if blank
		$list = \@my_list;
	}

	# make it sort, no dups
	$real_list = $self->uniquify_list($list);

	# turn that list into a nice sql-list
	$nice_list = qq{'}.join(qq{','}, @$real_list).qq{'};

	# send it out
	return $nice_list;
}


# subroutine to process a template via template toolkit
# this is for server-side processing of templates
sub template_process {
	my $self = shift;

	my (%args) = @_;
	# can contain: include_path, template_file, template_vars, send_out, save_file, stop_here

	# declare vars
	my ($output, $tt, $tt_error);

	# default include path
	if (!$args{include_path}) {
		$args{include_path} = $ENV{OTHOME}.'/code/omnitool/static_files/server_side_templates/';
	} elsif ($args{include_path} !~ /\/$/) { # make sure of trailing /
		$args{include_path} .= '/';
	}

	# $args{tag_style} = 'star', 'template' or similiar
	# see http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template/Manual/Config.pod#TAG_STYLE
	# useful when processing templates to generate jemplates
	# [* *] for server-side processing; [% %] for client-side
	# just use [% %] for server-side-only templates

	# default tag_style to regular, [% %]
	$args{tag_style} ||= 'template';

	# crank up the template toolkit object, and set it up to save to the $output variable
	$output = '';
	$tt = Template->new({
		ENCODING => 'utf8',
		INCLUDE_PATH => $args{include_path},
		OUTPUT => \$output,
		TAG_STYLE => $args{tag_style},
	}) || $self->mr_zebra("$Template::ERROR",1);

	# bit for debugging
	# $self->logger("Looking for $args{template_file} in $args{include_path}",'eric');

	# process the template
	$tt->process($args{template_file},$args{template_vars}, $output, {binmode => ':encoding(utf8)'});

	# make sure to throw error if there is one
	$tt_error = $tt->error();
	$self->mr_zebra("Template Error in $args{template_file}: $tt_error",1) if $tt_error;

	# send it out to the client, save to the filesystem, or return to the caller
	if ($args{send_out}) { # output to the client
		$self->mr_zebra($output,2);
		# the '2' tells mr_zebra to avoid logging an error

	} elsif ($args{save_file}) { # save to the filesystem
		write_file( $args{save_file}, $output);
		return $args{save_file}; # just kick back the file name

	} else { # just return
		return $output;
	}
}

# start the timeToDate subroutine, where we convert between UNIX timestamps and human-friendly dates
sub time_to_date {
	my $self = shift;
	# declare vars & grab args
	my ($day, $dt, $diff, $month, $templ, $year);
	my ($timestamp, $task, $timezone_name) = @_;

	# luggage::pack_luggage() tries to set the 'timezone_name' attribute
	# try to use that if no $timezone_name arg was sent
	$timezone_name ||= $self->{timezone_name};

	# of they sent a 'utc', force it to be Etc/GMT -- this is for the logger
	$timezone_name = 'Etc/GMT' if $timezone_name eq 'utc';

	# default timezone to UTC/GMT if no timezone sent or set
	$timezone_name ||= 'Etc/GMT';

	# fix up timestamp as necessary
	if (!$timestamp) { # empty timestamp --> default to current timestamp
		$timestamp = time();
	} elsif ($timestamp =~ /\,/) { # human date...make it YYYY-MM-DD
		($month,$day,$year) = split /\s/, $timestamp; # get its pieces
		# turn the month into a proper number
		if ($month =~ /Jan/) { $month = "1";
		} elsif ($month =~ /Feb/) { $month = "2";
		} elsif ($month =~ /Mar/) { $month = "3";
		} elsif ($month =~ /Apr/) { $month = "4";
		} elsif ($month =~ /May/) { $month = "5";
		} elsif ($month =~ /Jun/) { $month = "6";
		} elsif ($month =~ /Jul/) { $month = "7";
		} elsif ($month =~ /Aug/) { $month = "8";
		} elsif ($month =~ /Sep/) { $month = "9";
		} elsif ($month =~ /Oct/) { $month = "10";
		} elsif ($month =~ /Nov/) { $month = "11";
		} elsif ($month =~ /Dec/) { $month = "12"; }
		# remove the comma from the date and make sure it has two digits
		$day =~ s/\,//;

		# we'll convert the epoch below via DateTime, one more check...
		$day = '0'.$day if $day < 10;
		$timestamp = $year.'-'.$month.'-'.$day;

	}
	# if they passed a YYYY-MM-DD date, also we will get a DateTime object

	# need that epoch if a date string was set / parsed
	if ($month || $timestamp =~ /-/) {
		$dt = $self->get_datetime_object($timestamp.' 00:00',$timezone_name);
		$timestamp = $dt->epoch;
		$timezone_name = 'Etc/GMT'; # don't offset dates, only timestamps
	}

	# default task is the epoch for the first second of the day
	$task ||= 'to_unix_start';

	# proceed based on $task
	if ($task eq "to_unix_start") { # date to unix timestamp -- start of the day
		return $timestamp; # already done above
	} elsif ($task eq "to_unix_end") { # date to unix timestamp -- end of the day
		return ($timestamp + 86399); # most done above
	} elsif ($task eq "to_date_db") { # unix timestamp to db-date (YYYY-MM-DD)
		$templ = '%Y-%m-%d';
	} elsif (!$task || $task eq "to_date_human") { # unix timestamp to human date (Mon DD, YYYY)
		($diff) = ($timestamp - time())/15552000; # drop the year if within the last six months
		if ($diff > -1 && $diff < 1) {
			$templ = '%b %e';
		} else {
			$templ = '%b %e, %Y';
		}
	} elsif (!$task || $task eq "to_date_human_dayname") { # unix timestamp to human date (DayOfWeekName, Mon DD, YYYY)
		($diff) = ($timestamp - time())/15552000; # drop the year if within the last six months
		if ($diff > -1 && $diff < 1) {
			$templ = '%A, %b %e';
		} else {
			$templ = '%A, %b %e, %Y';
		}
	} elsif ($task eq "to_year") { # just want year
		$templ = '%Y';
	} elsif ($task eq "to_month" || $task eq "to_month_name") { # unix timestamp to month name (Month YYYY)
		$templ = '%B %Y';
	} elsif ($task eq "to_month_abbrev") { # unix timestamp to month abreviation (MonYY, i.e. Sep15)
		$templ = '%b%y';
	} elsif ($task eq "to_date_human_time") { # unix timestamp to human date with time (Mon DD, YYYY<br>HH:MM:SS XM)
		($diff) = ($timestamp - time())/31536000;
		if ($diff >= -1 && $diff <= 1) {
			$templ = '%Z %b %e - %l:%M%P';
		} else {
			$templ = '%Z %b %e, %Y - %l:%M%P';
		}
	} elsif ($task eq "to_just_human_time") { # unix timestamp to humantime (HH:MM:SS XM)
		$templ = '%l:%M%P';
	} elsif ($task eq "to_just_military_time") { # unix timestamp to military time
		$templ = '%R';
	} elsif ($task eq "to_datetime_iso") { # ISO-formatted timestamp, i.e. 2016-09-04T16:12:00+00:00
		$templ = '%Y-%m-%dT%X%z';
	} elsif ($task eq "to_month_abbrev") { # epoch to abbreviation, like 'MonYY'
		$templ = '%b%y';
	} elsif ($task eq "to_day_of_week") { # epoch to day of the week, like 'Saturday'
		$templ = '%A';
	}

	# if they sent a time zone, offset the timestamp epoch appropriately
	if ($timezone_name ne 'Etc/GMT') {
		$dt = DateTime->from_epoch(
			epoch		=> $timestamp,
			time_zone	=> $timezone_name,
		);
		$timestamp += $dt->offset;
	}

	# now run the conversion
	$timestamp = time2str($templ, $timestamp,'GMT');
	$timestamp =~ s/  / /g; # remove double spaces;
	$timestamp =~ s/GMT //;
	return $timestamp;
}

# very easy method to get today's date in DB format from time_to_date
sub todays_date {
	my $self = shift;

	return $self->time_to_date(time(),'to_date_db');
}

# start subroutine to uniquify a list
sub uniquify_list {
	my $self = shift;

	# declare vars
	my ($list, %seen, @u_list);

	# grab arg
	$list = $_[0];	# reference to un-sorted array full of duplicates

	# stolen from perl cookbook, page 124
	%seen = ();
	@u_list = grep { ! $seen{$_} ++ } @$list;

	# send back reference
	return \@u_list;
}

###### START UNDOCUMENTED FEATURES ######

# quick method to pack some text into Hex and save to a file
# useful in very limited situations
sub stash_some_text {
	my $self = shift;

	my ($text_to_stash,$file_location) = @_;

	# return if no text or $file_location
	if (!$text_to_stash || !$file_location) {
		$self->mr_zebra('Error: both args required for stash_text()',1);
	}

	# garble it up
	my $obfuscated = unpack "h*", $text_to_stash;
	# get this out like:
	# 	$obfuscated = read_file($file_location);
	# 	my $stashed_text = pack "h*", $obfuscated;
	# 	print $stashed_text."\n";
	# This is 0.0000001% of what pack() can do, please see: http://perldoc.perl.org/functions/pack.html

	# stash it out
	write_file( $file_location, $obfuscated);

	return 1;
}

1;

__END__

=head1 omnitool::common::utility_belt

A set of very handy routines, which combine to be a very critical component of this system.  Just
about everything else depends on this package.

This class is automatically placed into $$luggage{belt} by pack_luggage(), which adds in the 'request'
and 'response' Plack handlers for communicating with the HTTPS client.  These are not needed for simple
script use, and you just simply new() with no arguments to set it up:

	$belt = omnitool::common::utility_belt->new();

Here are the included methods, in alphabetical order:

=head2 benchmarker()

For troubleshooting choke-points / speed issues.  Will log out messages showing the number of seconds, out
to five decimel places, to get to the chosen spot in your code execution.  First arg is the message indicating
the place in your code, and the second is the base name for your log file.  Second arg is optional, and will
default to 'benchmarks'.

For most usefulness, you will call this twice, like so:

	$belt->benchmarker('Started my process');

	...some code here...

	$belt->benchmarker('Finished my process');

And if today is 09/04/2016, you could look in $OTHOME/log/benchmarks-2016-09-04.log and see something like:

	ID: 1473294347 | 2016-09-04T00:25:47+0000: Started my process at 0.871639 wallclock secs ( 0.78 usr +  0.03 sys =  0.81 CPU) | https://some.omnitool-server.org/tools/your/tool/send_json_data
	ID: 1473294348 | 2016-09-04T00:25:48+0000: Finished my process at 1.68132 wallclock secs ( 1.41 usr +  0.10 sys =  1.51 CPU) | https://some.omnitool-server.org/tools/your/tool/send_json_data

You can use this for permanent logging of execution times for various routines.  In that case, please pass the
second argument to create a specialized log file.

=head2 comma_list()

Takes a reference to an array plus an optional delimiter, runs the arrayref through our 'uniquify_list'
method to take out duplicates, then turns it into a simple string of the values, separated by the delimiter,
which defaults to a comma.  Seems like I could have explained that more simply.

Example:

	$comma_separated_string = $belt->comma_list(['eric','ginger','pepper','eric']);

	$comma_separated_string now equals 'eric,ginger,pepper'.

	Example Two;

	$comma_separated_string = $belt->comma_list(['eric','ginger','pepper','eric'],'==');

	$comma_separated_string now equals 'eric==ginger==pepper'.

=head2 commaify_number()

Turns 1976 to 1,976 or 36000000 to 36,000,000.

Example:

	$pretty_number = $belt->commaify_number(25000);

	$pretty_number is now '25,000'.

=head2 datacode_query()

Builds a nice SQL logic fragment to query the primary key (code,server_id combo) of a datatype table.
Do NOT use for querying against a relationship column like metainfo.data_code.  This is really here for omniclass::loader.

Example:

	($sql_fragment,$bind_variables) = $belt->datacode_query('3_10','19_10','25_10');

	$sql_fragment is now:  ((code=? and server_id=?) or (code=? and server_id=?) or (code=? and server_id=?))

	$bind_variables is now [3,10,19,10,25,10]

=head2 date_fix()

Takes MySQL-provided dates (YYYY-MM-DD) and makes them readable: Jun. 27, 1998

Example:

	$nice_date = $belt->date_fix('1999-08-01');

	$nice_date is now 'August 1, 1999'

=head2 diff_percent()

Calculates the amount of growth (or shrinkage) from one number to the next.

Example:

	$diff = $belt->diff_percent(10,12);

	$diff is now 20.  No percent sign included.

=head2 figure_age()

Returns a somewhat-friendly string showing how long ago this UNIX epoch was current.
Set it an epoch from before now.

If your epoch was less than a minute ago, you will receive back 'Just now', and
otherwise, you will get a string like so:

	'40 minutes ago'
	'2.1 days ago'
	'3.6 weeks ago'
	'10 months ago'

Example:

	$phrase = $belt->figure_age( time() - 3600 );

	$phrase is now '60 minutes ago'.

=head2 figure_delay_time();

Does the opposite of figure_age().  It display a somewhat-friendly string showing
how far into the future this UNIX epoch will occur.  Send it an epoch value for
after now.

If your epoch is less than a minute from now, you will receive back 'Right now', and
otherwise, you will get a string like so:

	'In 20 minutes'
	'In 3.5 days'
	'In 7.2 weeks'
	'In 11 months'

Example:

	$phrase = $belt->figure_delay_time( time() + 3600 );

	$phrase is now 'In 60 minutes'.

=head2 get_datetime_object()

Creates a DateTime object from a MySQL date/time, e.g. 2016-09-04 16:30.  DateTime is
integral to all the time-calculation functions in this package/system, and this method
is the central location to set up a DateTime object.

First arg is the MySQL date/time string, and the optional second arg is the tzdata
time zone name (https://en.wikipedia.org/wiki/Tz_database). The default time zone is
Etc/GMT, which is UTC+0.

More information on the excellent DateTime library is available at
http://search.cpan.org/~drolsky/DateTime-1.43/lib/DateTime.pm

You can use the returned object for anything DateTime can do, but please use the other
time-related methods here whenever possible, as they bring in the user's
$self->{luggage}{timezone_name} as much as possible -- and that is snatched from the
browser and cached for other modes.

Example:

	$datetime_object = $belt->get_datetime_object('2018-09-04 16:20:00','America/New_York');

	# get a DateTime object for my 42nd birthday on the East Coast.

=head2 get_epoch_for_next_local_time()

Method to get an epoch for the occurrence of a given time, localized to a time zone name.
Really meant to find the epoch of the 'next' incidence of that time -- so if you say '11am,'
that could meant tomorrow morning.  If you pass the 'stick_to_day' third argument, it will
stick with the 'today' epoch for that time.

This is handy for scheduling jobs that need to run after a certain time in
a certain location (i.e. turn off all lights in Albuquerque at 9pm)

Requires one argument:  a military-style time value, i.e. 14:30 for 2:30pm.

Optional second arg is the tzdata time zone name, i.e. America/New_York or Europe/Brussels
The default here would be UTC+0.

Optional third arg tells us to not to make sure it's in the future.

Usage:

	$epoch = $belt->get_epoch_for_next_local_time('15:00','America/Los_Angeles');

	$epoch is now the epoch for the next time it will be 3pm on the West Coast.

=head2 get_instance_db_object()

Returns a omnitool::common::db object for a database connection to the database server
for the specified Application Instance.  First argument is the data code of the
Application Instance, second argument is an active omnitool::common::db database object.
Third argument is optional, the OmniTool Admin database which contains the definitions
of this Application Instance.  If the third option is not provided, it will assume
the current working database for the $db object.

If the passed-in omnitool::common::db object is connected to the right DB server already,
we will just return that.

Usage:

	$new_db_obj = $belt->get_instance_db_object($instance_data_code, $old_db_obj);

=head2 get_sort_keys()

One of my favorites. Sends back a reference to an array of numbers which can be used to
key a hash so that it can be reliably sorted by those keys.  Prepends '0's so that all number
keys are the same length and easily sortable.

Example:

	$arrayref = $belt->get_sort_keys(10);

	$arrayref is now ['00','01','02','03','04','05','06','07','08','09']

=head2 jemplate_process()

This is my FAVORITE.  Using this, you process a Template-Toolkit template (http://www.template-toolkit.org/)
and turn it into a JavaScript library, which can be processed on the client side using a JSON object as
its variables.  This absolutely fantastic, because:

	1. We can use one language / syntax for both server-side and client-side templating.
	2. We can potentially use the same template file on both sides.  Think creating PDF's, emails, printing, etc.
	3. Template-Toolkit is extremely nice and intuitive.

Please see the jemplate_binding() function/constructor in omnitool_routines.js.  You can use that code to
bind compiled Jemplate templates to elements in the DOM and URI's to JSON feeds, and then process and
re-process those templates, updating the client's view.  You can also pass in JSON data, pre-fetched
for a one-time processing.

Yes, there are many JavaScript frameworks out there who can accomplish this, not the least of which
is AngularJS and Backbone.  I almost used JSRender/JSViews, in fact.  The problem with all these is
that (a) they introduce a whole other syntax (of dubious quality) and (b) most of these frameworks
dictate quite a bit about how your application is designed, and they aren't necessary written with
a meta-tool like OmniTool in mind.  Also, honestly, these people act as if they invented science itself
and their hipster jargon is just exhausting. </oldman-rant>

For this method, pass in %args, which could/should include:

	$args{template_file_paths} = []; # array of paths to template toolkit files
						   # accepts full paths, but if only filenames sent, will look
						   # for them in $ENV{OTHOME}/code/omnitool/static_files/system_wide_jemplates
	$args{template_content} = ''; # use this if you created the template file first, instead of
								  # 'template_file_paths'.
								  # handy if you processed a base template first
	$args{template_name} = '';	# scalar with name of the template for the Jemplate() javascript command
						# used in conjunction with 'template_content' and is required for that route
						# must have either something in $args{template_content} or in $args{template_file_paths}[0]
						# yes, you can have both
	$args{stop_here} => 1; # optional; if filled, will send out to the browser
				# otherwise, return the generated javascript text

Examples:

	$javascript_text = $belt->jemplate_process(
		'template_file_paths' => ['file1.tt','file2.tt'],
	);

	$javascript_text now contains the compiled JavaScript templates; send out at your discretion.

	$belt->jemplate_process(
		'template_content' => $template_content_text,
		'stop_here' => 1
	);

Sends the compiled template (a 'jemplate') out to the client browser as Javascript via mr_zebra().

=head2 json_from_perl() / json_to_perl()

For creating JSON from Perl or receiving JSON data into Perl.

The first method takes a reference to an array or a hash/data-structure and returns a JSON sting
in UTF-8.  The second method takes a JSON string, converts it into a perl data structure, and
returns a reference to that structure.

Examples:

	$json_string = $belt->json_from_perl($perl_hashref);

	$perl_hashref = $belt->json_to_perl($json_string);

Note that we set up a JSON object in new(), so you can also call the native methods like so:

	$json_text = $belt->{json}->encode($hashref);
	$hash_ref = $belt->{json}->decode($json_text);

That way, all of the JSON modules options are available as described here:
http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm

=head2 logger()

Appends log messages on to files under $ENV{OTHOME}/logs. These files are named fram today's
YYYY-MM-DD date plus the log type.  Marks the message with the UNIX epoch for easy grep'ing.
Returns that epoch value to the calling routine.  Works well with mr_zebra() when you do not
want to show an actual error message to the user.

Example of usage, if you ran this at 3:20am on March 11, 2016:

	$epoch = $belt->logger('Reached 4th Birthday.','lorelei');

	The following line would get added to $ENV{OTHOME}/code/omnitool_logs/lorelei-2016-03-11.log:

		ID: 1457684400 | 2016-09-04T16:12:00+00:00: Reached 4th Birthday.

If $log_type is left blank, it will default to 'errors'.

Bonus: If you send a hashref or arrayref, it will be logged-out via Data::Dumper(), but please
just use that for testing your apps, not in real-world logging.

=head2 month_name_list()

Method to get a list of month names given a range of months before/ahead of now.

Let's say today is September 4, 2017, and you do this:

	$month_list = $belt->month_name_list(6,2);

Now, $month_list will be:

	$month_list = [
		'March 2017','April 2017','May 2017','June 2017','July 2017','August 2017',
		'September 2017','October 2017','November 2017'
	];

The months will change depending on your current date at time of execute.  It does try to
account for the user's time zone, when executed via the Web UI.

If you pass nothing, the defaults are 24 months back, and 12 months forward.

This is used for tool::html_sender::build_filter_menu_options() when building options for
'Month Chooser' menus, but maybe it has other applications, so included here.

=head2 mr_zebra()

This is our one and only method to deliver content to the client.  I am really sorry for breaking my
own rule and picking a cutsie name.  It's just that this is a key subroutine and I am not a robot.
Mr. Zebra the postman in the Peppa Pig universe, and I have a little girl.

Anyhow, the argument sent to mr_zebra() should be one of: a reference to an array, a reference to
a hash, or a scalar of content, usually a string of plain text or a string of HTML.  That content
could also be the binary content of a file, but usually it's some type of text. If it's an arrayref
or hashref, mr_zebra() uses json_from_perl() to send it as a JSON string to the browser.  Otherwise,
the right content header will be sent and the string will be printed out to the client.

When you send out a Javascript file, which should only really happen in ui.pm, you will make
the very first line '// This is Javascript, Mr. Zebra.' with no leading space.  That saves
me from writing a probably-buggy regexp to test for JavaScript, especially since your JS code
probably contains HTML fragments.

Outputting to the client relies on the 'response' Plack handler being added to the $belt
object by pack_luggage().  If the 'response' handler is not present, mr_zebra() will just
print to stdout.

The '$stop_here' variable is optional, and will tell this subroutine that we want to
end execution after outputting the content.  If it's set to a 1 and the $content is plain text,
mr_zebra will attempt to send the message to logger(), saving it to the fatals logs.
In production, the user will see a message with the error ID, and you could use this ID to grep
to find the error.  If $ENV{OT_DEVELOPER} is filled, the error message will be shown plainly
a modal in the Web UI.

If you just want to stop without an error into the 'fatals' log, set $stop_here to 2 (or anything
but 1).

The third argument, $content_type, is optional, and allows you to specify the mime / content-type
of the content being served.  Make sure it's valid!  See retrieve_file() in omnitool::common::file_manager.

The fourth argument, $content_filename, is also optional and must be used with $content_type.  This
is to specify that we are sending a file for downloading; please see send_file() in tool::center_stage.pm

Examples:

	$belt->mr_zebra($hashref,2);
	# sends out a JSON version of the data structure in hashref, and then end execution.

	$belt->mr_zebra('An insightful error message.',1);
	# logs out 'An insightful error message.' to the 'fatals' log under $OTLOG.

	$belt->mr_zebra($file_contents,2,'application/octet-stream','filename.bin');
	# sends the 'filename.bin' file to the browser.

=head2 q_mark_list()

Generates X-number of ? marks, separated by commas.  This is useful for preparing INSERT
and UPDATE SQL with placeholders.

Example:

	$q_marks = $belt->q_mark_list(3);

	$q_marks is now '?,?,?'

=head2 random_string()

Generates a random alphanumeric string, $length chars long (defaults to 10)

Example:

	$rand_string = $belt->random_string(5);

	$rand_string will now be a crazy five-character alphanumeric string.

=head2 recaptcha_verify()

Use this from your post_validate_form() Tool.pm methods to validate any reCAPTCHA / I am not a robot
fields.

To use this, you must first visit https://www.google.com/recaptcha/admin and get a site key to cover
all the domains served via this Plack service.  Then edit $OTHOME/configs/start_omnitool.bash to
put those values into the lines for RECAPTCHA_SITEKEY and RECAPTCHA_SECRET.

To present a reCAPTCHA field, add a field subhash to your %$form like so:

	'recaptcha' => {
		'title' => 'Please Verify',
		'name' => 'recaptcha',
		'field_type' => 'recaptcha',
		'recaptcha_key' => $ENV{RECAPTCHA_SITEKEY},
	},

You can only change the 'title' value there.

Then, in post_validate_form(), have this code:

	# recaptcha verification is in the utility_belt
	my $they_are_a_person = $self->{belt}->recaptcha_verify();

	# stop the form submission in its tracks
	if (!$they_are_a_person) {
		$self->{stop_form_action} = 1;
		$self->{json_results}{form}{fields}{recaptcha}{field_error} = 1;
	}

I am putting this method here and not in tool.pm, because it is also used in the Login page, outside of
the Tool.pm world.

=head2 really_in_list()

Checks to see if a string is PROPERLY in a delimited list; that is, 'jdo' should not return
success in 'jblow,jdoe,jsmith' but should return true for 'jblow,jdo,jsmith'.

Returns a 1 or a 0.  Default $delimiter is a comma, so you can often leave it off.

Examples:

	if ($belt->really_in_list('d','a,b,c')) {
		...this code won't happen...
	}

	if ($belt->really_in_list('b','a|b|c','|')) {
		...this code will happen...
	}


=head2 show_data_structure()

Debugging rountine to run a structure through Data::Dumper and display the results.

Example:

	print $belt->show_data_structure($hashref);

=head2 range_list()

Takes a comma-separated list of numbers and ranges and converts to a plain comma-separated
list of numbers.  Honestly, this may not be the most popular kid in school, but neither was I.

Example:

	$number_list = $belt->('1-10,12,18,20-22');

	$number_list is now going to be:  1,2,3,4,5,6,7,8,9,10,12,18,20,21,22

=head2 sql_list()

Accepts an array reference (or a scalar of a comma-delimited string) and formats it for
doing IN queries with mysql, i.e. 'a','b','c' -- doesn't give you the ()'s.
Really for strings; if you have integers, you can rely on comma_list().

Example:

	$in_list = $belt->sql_list(['pepper','ginger']);

	$in_list is now qq{'pepper','ginger'}

Best not to use this at all; use q_mark_list and pass the array as bind variables.

=head2 template_process()

Processes a template via Template-Toolkit - http://www.template-toolkit.org/
Very key part of this system.  Used in ui.pm, login_system.pm and all the tools.

The argument should be in the form of a hash, whould should/can contain the following keys:
	template_file = required: the filename of the template to process
	template_vars = highly-recommended: the data structure of the variables to use in the processing
	include_path = optional: the template file's directory; defaults to $ENV{OTHOME}/code/omnitool/static_files/server_side_templates/
	send_out = optional; if filled, will send to the client via mr_zebra(); if empty, will return a variable
	stop_here = optional; if filled along with 'send_out', will stop executing after sending out
	save_file = optional; if filled with a filepath, will save the output to that filepath and return filepath back

Examples:

	$login_html = $belt->template_process(
		'template_file' => 'login_page.tt',
		'template_vars' => \%vars,
	);

	Places the generated HTML into $login_html.

	$belt->template_process(
		'template_file' => 'login_page.tt',
		'template_vars' => \%vars,
		'send_out' => 1,
		'stop_here' => 1,
	);

Sends that HTML out to the web client.

BTW, does not have to generate HTML; Template-Toolkit can do anything ;)

=head2 time_to_date()

Takes a Unix epoch, YYYY-MM-DD date or even a 'June 27, 1998' date and formats it based on
the task given in second arg.  The tasks 'to_unix_start' and 'to_unix_end' give epoch values
for the start/end time of the date; all the others change to a readable format.

Optional third arg is the tzdata time zone name, e.g. America/New_York. You can also pass 'utc'
 to force the time zone to be 'Etc/GMT', which is good since it will default to what is
loaded in $self->{luggage}{timezone_name} by the Web authentication.

Addtional options are: 'to_date_human', 'to_date_db', 'to_month', 'to_date_human_time',
'to_date_human_dayname', 'to_datetime_iso','to_month_abbrev', 'to_just_human_time',
'to_just_military_time', and 'to_day_of_week'

Examples:

	$month_name = $belt->time_to_date(933480000,'to_month');

	$momth_name is now 'August 1999'

	$human_date = $belt->time_to_date('2012-03-11','to_date_human');

	$human_date is now 'March 11, 2012'

The 'to_datetime_iso' option generates strings line 2016-09-04T16:12:00+00:00.

=head2 todays_date()

Returns the current date in MySQL format:  YYYY-MM-DD

Example:

	$today = $belt->todays_date();

=head2 uniquify_list()

Send in an array reference, which could include duplicate values. Returns an array reference with
unique values.

Example:

	$new_list = $belt->uniquify(['a','d','a']);

	$new_list is now ['a','d'];
