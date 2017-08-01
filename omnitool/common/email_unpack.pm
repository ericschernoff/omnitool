package omnitool::common::email_unpack;
# class to un-pack incoming emails into our $OTHOME/tmp/email_incoming
# directory and get them ready for processing by the omniclass modules

# sixth time's the charm
$omnitool::common::email_unpack::VERSION = '6.0';

# time to grow up
use strict;

# use third-party modules to do the real work
use MIME::Parser;
use File::Slurp;
use File::Path qw(remove_tree);
use Archive::Zip;
use HTML::Strip;
use Encoding::FixLatin qw(fix_latin);

# constructor method
sub new {
	my $class = shift;

	# accept an arguments hash
	# right now, our only argument would be 'directory', which is
	# the root of where we unpack these emails
	my (%args) = @_;

	# default that 'directory' to $ENV{OTHOME}/tmp/email_incoming
	$args{directory} ||= $ENV{OTHOME}.'/tmp/email_incoming';

	# initiate the parser
	$args{parser} = new MIME::Parser;

	# bless myself
	my $self = bless \%args, $class;

	# ready to go
	return $self;

}

# main event: method to unpack emails and return a hash containing the header, body
# text, and attachments.  also zip up the attachments for long-term storage
sub open_email {
	my $self = shift;

	my ($save_to_directory, $entity, $key, %email, $my_key, @entries, $num, $f, $testAgainst, $zip, $file_member, $attachment);

	# required argument is a scalar reference to a MIME message
	my ($mime_string_reference) = @_;

	# error-out if nothing in first arg
	if (!$mime_string_reference || ref($mime_string_reference) ne 'SCALAR' || !length($$mime_string_reference)) {
		return 'ERROR: Must provide a reference to a MIME message string';
	}

	# parse the email
	$self->{parser}->output_under($self->{directory});
	$entity = $self->{parser}->parse_data(${$mime_string_reference}) or die "couldn't parse MIME stream";

	# retrieve the parts we care about from the header
	foreach $key ('To','Return-Path','Subject') {
		$my_key = lc($key);
		$email{$my_key} = ${$entity->head->{mail_hdr_hash}{$key}[0]};
		$email{$my_key} =~ s/\n//;
		$email{$my_key} =~ s/$key\: //;
		$email{$my_key} =~ s/^\<|\>$//g; # some perl line noise for you

		# need versions of To and Return-Path without the @suffix.com
		if ($key =~ /Return|To/) {
			($email{$my_key.'_base'} = $email{$my_key}) =~ s/\@.*//;
		}
	}

	# Return-Path is actually From
	$email{from} = $email{'return-path'};
	$email{from_base} = $email{'return-path_base'};

	# where is this message?
	$email{save_directory} = $self->{parser}->output_dir;

	# pack up the parts to this message
	@entries = <$email{save_directory}/*>;
	$num = 0;
	foreach $f (sort @entries) {
		next if $testAgainst eq $f; # skip fake files and duplicates

		if ($f =~ /msg(.+)txt/) { # body file in text

			$email{text_body} = read_file($f);

			if ($$mime_string_reference =~ /charset=\"Windows/) {
				$email{text_body} = fix_latin($email{text_body});
			}

			utf8::decode($email{text_body});

		} elsif ($f =~ /msg(.+)html/) { # body file in HTML

			$email{html_body} = read_file($f);
			utf8::decode($email{html_body});

		} else { # regular attachment
			$email{attachments}[$num] = $f;
			$num++;
		}

		# want to make sure to not have any duplicate files - and the -1 ones should win out
		($testAgainst = $f) =~ s/\-1//;
	}

	# no text alternative to html?  make the text body out of the html
	if (!$email{text_body}) {
		$self->html_body_into_text(\%email);
	}

	# if there is just one attachment, return that file path as the primary attachment
	if ($email{attachments}[0] && !$email{attachments}[1]) {

		$email{the_attachment} = $email{attachments}[0];

	# if there are two or more attachments, make a zip archive
	} elsif ($email{attachments}[1]) {
		chdir  $email{save_directory}; # no long paths in zip file
		$zip = Archive::Zip->new();
		foreach $attachment (@{$email{attachments}}) {
			$attachment =~ s/$email{save_directory}\///;
			$file_member = $zip->addFile( $attachment );
		}
		# save the attachment & call it our main attachment
		$email{the_attachment} = $email{save_directory}.'/attachments.zip';
		$zip->writeToFileNamed($email{the_attachment});
	}

	# finish up our hash
	$email{attachment_list} = join(',',@{$email{attachments}});

	# note that 'save_directory' for possible call to 'clean()' below
	$self->{last_save_directory} = $email{save_directory};

	# send it out
	return \%email;
}

# utility to put the html_body into the text_body if there is no text_body
sub html_body_into_text {
	my $self = shift;

	# required argument is the hash for the email we are operating upon
	my ($email) = @_;

	# kick back if this does not appear to be an email hash
	return if !$$email{html_body};

	# transfer html_body into text_body, swapping out the <br>'s into \n's
	($$email{text_body} = $$email{html_body}) =~ s/<br\/>|<br>/\n/gi;

	# now strip out the rest of the html
	my $hs = HTML::Strip->new();
	$$email{text_body} = $hs->parse( $$email{text_body} );
	$hs->eof;

	# all done
}

# quick method to clean up a previous save-to directory
sub clean {
	my $self = shift;

	# optional arg is the directory to delete; default is whatever was last put into $self->{last_save_directory}
	my ($delete_directory) = @_;
	$delete_directory ||= $self->{last_save_directory};

	# return if blank or not under tmp
	return if !$delete_directory || $delete_directory !~ /$ENV{OTHOME}\/tmp/;

	# use File::Path to delete this
	remove_tree($delete_directory);
}

1;

__END__

=head1 omnitool::common::email_unpack

Class to 'unpack' MIME emails into files under $OTHOME/tmp/email_incoming and return a useful hash of
information about that MIME email.  Meant to be used in concert with $OTPERL/scripts/email_receive.pl .

=head2 new()

Gets a object of this class. Optional argument is the name of the directory to unpack files into.

	$email_unpacker = omnitool::common::email_unpack->new();

	or

	$email_unpacker = omnitool::common::email_unpack->new(
		'directory' => '/some/path'
	);

=head2 open_email()

Main event of this class.  Accepts scalar reference to MIME email, unpacks the message under the target
directory (default: /opt/omnitool/tmp/email_incoming) then returns a very useful hashref about the email
including the 'text_body', 'html_body', 'from', 'to', 'save_directory', 'the_attachment', and
'attachment_list'.

If the email has one attachment, the absolute path to that file will be in the 'the_attachment' key, and if
there are multiple attachments, they will be packed into a Zip file, and the absolute path to that Zip file
will be in 'the_attachment'.

Usually, you would pull the 'mime_message' value from your Instance's 'email_incoming' table.

Usage:

	$email = $email_unpacker->open_email(\$mime_message);

Now %email will look like:

	$VAR1 = {
		'to_base' => 'destination-mailbox',
		'subject' => 'Test message',
		'to' => 'username@this-omnitool-server.net',
		'return-path' => 'emailwriter@somedomain.com',
		'return-path_base' => 'emailwriter',
		'from_base' => 'emailwriter',
		'the_attachment' => '/opt/omnitool/tmp/email_incoming/msg-1470360921-70422-0/attachments.zip',
		'html_body' => '<html><head><style>body{font-family:Helvetica,Arial;font-size:14px}</style></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;"><div id="bloop_customfont" style="font-family:Helvetica,Arial;font-size:14px; color: rgba(0,0,0,1.0); margin: 0px; line-height: auto;">I love my two doggies.</div><br><div id="bloop_sign_1470348718635195904" class="bloop_sign"><div><font face="Helvetica"><span style="font-size: 14px;"><br></span></font></div><div><font face="Helvetica"><span style="font-size: 14px;">-Eric &nbsp;</span></font></div><div><font face="Helvetica"><span style="font-size: 14px;"><br></span></font></div><div><font face="Helvetica"><span style="font-size: 14px;">--&nbsp;<br></span></font><div style="line-height: normal;"><font face="Helvetica"><span style="font-size: 14px;">Eric Chernoff</span></font></div><div style="line-height: normal;"><font face="Helvetica"><span style="font-size: 14px;">984-216-3000</span></font></div><div style="line-height: normal;"><font face="Helvetica"><span style="font-size: 14px;">CA Lab Operations, Applications Architect</span></font></div><font face="helvetica, arial"><img src="cid:D9049E99-5C8C-4D80-8844-4A3D4BD11CC6"></font></div></div></body></html>',
		'from' => 'emailwriter@somedomain.com',
		'attachment_list' => 'IMG_1929.jpg,Screen Shot 2016-08-04 at 12.22.01 PM.png,image001.jpg',
		'attachments' => [
			'IMG_1929.jpg',
			'Screen Shot 2016-08-04 at 12.22.01 PM.png',
			'image001.jpg'
		],
		'save_directory' => '/opt/omnitool/tmp/email_incoming/msg-1470360921-70422-0',
		'text_body' => 'I love my two doggies.

-Eric  

-- 
Eric Chernoff
Marginal Web Developer
        };

=head2 clean()

Method to clean up the files in your save-to directory from open_email().  Just deletes the directory, and will only
work under $OTHOME/tmp.  If you pass an argument, that will be the target; otherwise, it will look in
$self->{last_save_directory} which was set by open_email();

Usage:

	$email_unpacker->clean();
