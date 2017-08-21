package omnitool::common::aws_s3_client;
# class to interact with AWS S3 for file storage, in concert with
# omnitool::common::file_manager's "_aws_s3" methods

# AWS S3 Home:
#	https://aws.amazon.com/s3/
# Once you're signed up, to set up your access keys
# 	https://s3.console.aws.amazon.com/s3/home

# Really great CPAN from Lee Johnson makes this work:
use AWS::S3;

use strict;

# constructor; sets up connection to the SwiftStack server
sub new {
	my $class = shift;

	# required arguments as a hash
	my (%args) = @_;
	# looks like (all required):
	#	'access_key_id' => 'your_aws_access_key_id', 
	#	'secret_access_key' => 'your_aws_access_key_secret', 
	#	'luggage' => $luggage, 

	# fail if no %$luggage provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an omnitool::common::file_manager object without my luggage.'});
	}

	# return an error if any of the other required arguments were not provided
	if (!$args{access_key_id} || !$args{secret_access_key}) {
		$args{luggage}{belt}->mr_zebra(qq{Error: Cannot set up omnitool::common::aws_s3_client without 'access_key_id' and 'secret_access_key' arguments.},1);
	}

	# try to set up the client connection
	my ($s3, $bucket_name, $the_bucket);
	eval {
		$s3 = AWS::S3->new(
			'access_key_id' => $args{access_key_id},
			'secret_access_key' => $args{secret_access_key},
		);
	};
	if ($@) { # log out if failed
		$args{luggage}{belt}->mr_zebra(qq{Error connecting to AWS S3: }.$@,1);
	}

	# safe to continue:  try to get the bucket for this instance
	$bucket_name = 'omnitool_'.$args{luggage}{session}->{app_instance};
	$the_bucket = $s3->bucket();
	if (!$the_bucket) {
		$the_bucket = $s3->add_bucket(
			'name' => $bucket_name,
		);
	}

	# otherwise, bless and return our object, with the needed bits
	my $self = bless {
		'luggage' => $args{luggage},
		's3' => $s3,
		'the_bucket' => $the_bucket,
	}, $class;

	return $self;
}

# method to get a file from AWS S3
sub get_file {
	my $self = shift;
	
	# required arguments are the directory and the file names
	my ($directory,$filename) = @_;

	my ($the_file, $file_reference);

	# fail without those two arguments
	if (!$directory || !$filename) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: aws_s3_client->get_file() requires two arguments: the directory and file name.},1);
	}
	
	eval {
		$the_file = $self->{the_bucket}->file($directory.'/'.$filename);
	};
	
	if ($@) { # log out if failed
		$self->{luggage}{belt}->mr_zebra('Error retrieving '.$directory.'/'.$filename.' from AWS S3: '.$@,1);
	}
	
	# if we can get the reference to the file contents
	if ($the_file) {
		$file_reference = $the_file->contents;
	}

	# and return that reference
	return $file_reference;

}

# method to save a file to the AWS S3 store
sub put_file {
	my $self = shift;
	
	# required arguments are the directory name, the filename, 
	# and a reference to the object contents
	my ($directory,$filename,$the_file_contents) = @_;
	
	# fail without those arguments
	if (!$directory || !$filename || !$the_file_contents) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: aws_s3_client->put_file() requires three arguments: the directory, the file, and the contents for the new file.},1);
	}

	# try in eval{} and log out if error
	eval {
		my $new_file = $self->{the_bucket}->add_file(
			'key' => $directory.'/'.$filename,
			'contents' => $the_file_contents,	
		);
	};
	if ($@) { # log out if failed
		$self->{luggage}{belt}->mr_zebra('Error saving '.$directory.'/'.$filename.' from AWS S3: '.$@,1);
	}

	
	# return success
	return 1;
}

# method to delete a file from S3
sub delete_file {
	my $self = shift;
	
	# required arguments are the directory name and the filename, 
	my ($directory,$filename) = @_;
	
	# get and squash the file
	my $the_file = $self->{the_bucket}->file( $directory.'/'.$filename );
	if ($the_file) {
		$the_file->delete();
	}

	# return success
	return 1;
}

1;

__END__

=head1 omnitool::common::aws_s3_client

This is a basic client to save and retrieve files to and from Amazon Web Services'
Simple Storage Service (S3). This is meant to work with the the file_manager.pm class 
for storing and retrieving (and sometimes deleting) files associated
with OmniClass records.  

This should not be used outside of file_manager.pm, so I am not going to document the 
methods in hopes of discouraging any extracurricular activity.