#!/usr/bin/env perl
=cut

Email-accepting script to run on MTA / SMTP-in servers for OmniTool.
Meant to run using a 'plain' system Perl, 5.8+, with just DBI and DBD::MySQL.

Simply drops the incoming MIME message into the 'email_incoming' table with a 'New'
status.  This 'email_incoming' table is a baseline table created when you use
'Setup MySQL Tables' for an App Instance.

The background tasks script should parse these emails from 'email_incoming', setting
'New' to 'Working' to claim the email / lock-out other threads, and then delete
the emails as the work is complete.

For security, we have a very simple / limited user for this:

grant insert on YOUR_APP_INSTANCE_DATABASE.email_incoming to email_in@'%' identified by 'SOME_PASSWORD';

And the table looks like:

	CREATE TABLE email_incoming (
		code int(11) unsigned NOT NULL AUTO_INCREMENT,
		server_id int(11) unsigned NOT NULL DEFAULT '1',
		mime_message longblob,
		status enum('New','Locked','Done','Error') DEFAULT NULL,
		error_message varchar(1000) DEFAULT NULL,
		create_time int(11) unsigned DEFAULT NULL,
		recipient varchar(100) DEFAULT NULL,
		PRIMARY KEY (code,server_id),
		KEY status (status,recipient)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8


But OT Admin sets that up for you -- no need to worry about that.  Only manual bit
is issuing the 'grant' command for the target database.

The idea here is that you'd have one catchall email address per application instance,
and email sent in via that account would write to the instance's database.

=cut

use DBI; # core module for database ops
use strict; # i wish i were a better person.

my ($resolver, $account, $db_username, $db_password, $dsn, $dbh, $email);

# configuration hash for system users to database servers / DB's
$resolver = {
	'DATATYPE_RECEIVING_EMAIL@YOUR-OMNITOOL-DOMONE.COM' => { # make that lower-case
		'hostname' => 'HOSTNAME_OR_IP', # the database server hostname, not the instance
		'connect_to_database' => 'TARGET_APPLICATION_INSTANCE_HOSTNAME',
	},
};

# current account determines where to resolve
$account = $ENV{RECIPIENT};
	# $account ||= (sort(keys %$resolver))[0];

# hard-code the user / password (for now)
$db_username = 'email_in';
$db_password = 'SOME_PASSWORD'; # make sure to change this on your accepting server

# connect to the database with those credentials
$dsn = 'DBI:mysql:database='.$$resolver{$account}{connect_to_database}.';host='.$$resolver{$account}{hostname}.';port=3306';
$dbh = DBI->connect($dsn, $db_username, $db_password,{ PrintError => 1, RaiseError=>1 });

# set really long reads, but this is likely unncessary
$dbh->{LongReadLen} = 10000000;

# pull in the email via STDIN
$email = do { local $/; <> };

# reject auto-responder messages - MODIFY TO SUIT YOUR ORGANIZATION
exit if ($email =~ /X-Mailer\:\svacation|Out.of.Office|AutoReply|I\'m on vacation/
	|| $email =~ /Out.of.Office|AutoReply|I\'m on vacation/
	|| $email =~ /auto-submitted\: auto-generated/i 
	|| $email =~ /Auto-Submitted: auto-replied/i
);

# debug code
# use Data::Dumper;
# $email .= Dumper(\%ENV);

# now insert it into the database
$dbh->do(qq{
	insert into email_incoming (mime_message,status,create_time,recipient)
	values (?,'New',unix_timestamp(),?)
}, {}, ($email, $account) );

# let go of the database connection
$dbh->disconnect;


# and close out
exit;
