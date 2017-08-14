package omnitool::common::swiftstack_client;
# class to interact with a SwiftStack object store
# works with a V1 swiftstack, and meant to work with 
# omnitool::common::file_manager's "_swift" methods

# Note:  This works for our internal OpenStack server,
# and that's the only one I have available for testing.
# This is not the most complete client.

# CPAN modules to facilitate HTTP/S requests
use HTTP::Request;
use HTTP::Request::Common;
use WWW::Mechanize;

use strict;

# constructor; sets up connection to the SwiftStack server
sub new {
	my $class = shift;

	# required arguments as a hash
	my (%args) = @_;
	# looks like (all required):
	#	'luggage' => $luggage, 
	#	'auth_url' => 'https://your.swiftstack-server.net/auth/v1.0',
	#	'username' => 'username',
	#	'password' => 'password',

	# fail if no %$luggage provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an omnitool::common::file_manager object without my luggage.'});
	}

	# return an error if any of the required arguments were not provided
	if (!$args{auth_url} || $args{auth_url} !~ /^https.*auth/) {
		$args{luggage}{belt}->mr_zebra(qq{Error: Cannot set up omnitool::common::swiftstack_client with a valid 'auth_url' argument.},1);
	} elsif (!$args{username} || !$args{password}) {
		$args{luggage}{belt}->mr_zebra(qq{Error: Cannot set up omnitool::common::swiftstack_client with valid 'username' and 'password' arguments.},1);
	}
	
	# declare vars
	my ($mech, $req, $res, $auth_token, $storage_url);

	# set up a WWW::Mechanize object, and look for 'SWIFTSTACK_NO_HOSTNAME_VERIFY'
	# environmental variable to see if we want to set verify_hostname => 0,
	if ($ENV{SWIFTSTACK_NO_HOSTNAME_VERIFY}) {
		$mech = WWW::Mechanize->new(
			ssl_opts => {
				verify_hostname => 0,
			},
		);
	} else { # regular object
		$mech = WWW::Mechanize->new();
	}
	
	# set up a request to authenticate on this server
	$req = HTTP::Request->new(GET => $args{auth_url});
		$req->header( 'X-Auth-User' => $args{username} );
		$req->header( 'X-Auth-Key' => $args{password} );

	# send that request
	$res = $mech->request($req);

	# get the auth_token and storage_url values 
	$auth_token = $mech->res->headers->{'x-auth-token'};
	$storage_url = $mech->res->headers->{'x-storage-url'};

	# bless and return our object, with the needed bits
	my $self = bless {
		'luggage' => $args{luggage},
		'mech' => $mech,
		'auth_token' => $auth_token,
		'storage_url' => $storage_url,
	}, $class;

	return $self;
}

# method to get a file/object from the object store
sub get_object {
	my $self = shift;
	
	# required arguments are the container and the object name (filename)
	my ($container_name,$object_name) = @_;

	# fail without those two arguments
	if (!$container_name || !$object_name) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: swiftstack_client->get_object() requires two arguments: the container and object_name.},1);
	}

	# set up and execute the request, returning the results
	my $req = HTTP::Request->new(GET => $self->{storage_url}.'/'.$container_name.'/'.$object_name);
		$req->header( 'X-Auth-Token' => $self->{auth_token} );

	my $res = $self->{mech}->request( $req );
	if (!$res) { # nothing found
		return 'File not found.';
	}

	my $results = $self->{mech}->content();
	return $results;

}

# method to save a file/object into the object store
sub put_object {
	my $self = shift;
	
	# required arguments are the container name, the object name (filename), 
	# and a reference to the object contents
	my ($container_name,$object_name,$the_actual_object) = @_;
	
	# fail without those arguments
	if (!$container_name || !$object_name || !$the_actual_object) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: swiftstack_client->put_object() requires three arguments: the container, the object_name, and the contents for the new object.},1);
	}

	# prepare the request
	my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container_name.'/'.$object_name);
		$req->header( 'X-Auth-Token' => $self->{auth_token} );
		$req->header( 'Content-Type'   => 'application/octet-stream' );
		$req->header( 'Content-Length' => length($the_actual_object) );
	$req->content(${$the_actual_object});

	# execute the request and return a 1 or 0
	my $res = $self->{mech}->request( $req );
	return $res->is_success;

}

# method to delete a file/object from the object store
sub delete_object {
	my $self = shift;
	
	# required arguments are the container name and the object name (filename)
	my ($container_name,$object_name) = @_;
	
	# fail without those arguments
	if (!$container_name || !$object_name) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: swiftstack_client->delete_object() requires two arguments: the containerand  object_name.},1);
	}

	# prepare the request
	my $req = HTTP::Request->new(DELETE => $self->{storage_url}.'/'.$container_name.'/'.$object_name);
		$req->header( 'X-Auth-Token' => $self->{auth_token} );

	# execute the request and return a 1 or 0
	my $res = $self->{mech}->request( $req );
	return $res->is_success;

}

# method to put a container (directory) into the object stack
# calling this ensures the container is there
sub put_container {
	my $self = shift;
	
	# required argument is the container name
	my ($container_name) = @_;
	
	# fail without those arguments
	if (!$container_name) {
		$self->{luggage}{belt}->mr_zebra(qq{Error: swiftstack_client->delete_object() requires two arguments: the containerand  object_name.},1);
	}

	# prepare the reuqest
	my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container_name);
		$req->header( 'X-Auth-Token' => $self->{auth_token} );
		$req->header( 'Content-Type'   => 'application/directory' );
		$req->header( 'Content-Length' => 0 );

	# execute the request and return a 1 or 0
	my $res = $self->{mech}->request( $req );
	return $res->is_success;

}

1;

__END__

=head1 omnitool::common::swiftstack_client

This is a basic client to get and put objects into a SwiftStack object store.  
For our purposes, an 'object' is a saved file.  This is meant to work with the the
file_manager.pm class for storing and retrieving (and sometimes deleting) files associated
with OmniClass records.  

OmniClass does want to store files into 'locations' also known as 'containers', so containers
will get created, named by the Instance's base URI plus a monthYear, i.e. ginger_Aug17.  
This is not usually encouraged for object stores, but I may have to sometimes go into that
store via CyberDuck, and I would like there not to be 10,000,000 files in the listing.  Also,
the file names are normalized to codes by OmniClass, and we want to support multiple instances
(so there may be code overlap, which this unique-container situation supports).

This should not be used outside of file_manager.pm, so I am not going to document the 
methods in hopes of discouraging any extracurricular activity.