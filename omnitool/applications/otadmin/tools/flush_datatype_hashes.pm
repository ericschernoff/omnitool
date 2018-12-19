package omnitool::applications::otadmin::tools::flush_datatype_hashes;
# drive the Flush Datatype Hashes action tool under Manage Instances
# as well as under 'Manage Datatypes'

use parent 'omnitool::tool';

use strict;

# this is a read-only action, so we shall use 'prepare_message,' which
# will be picked up by action_tool.pm automatically.
sub prepare_message {
	my $self = shift;

	# i used to do this by instance and try to play smart, but let's not play games
	# we are going to force-clear the datatypes on the current database server
	$self->{db}->do_sql(
		'delete from otstatedata.datatype_hashes'
	);	

	# tell them all about it
	$self->{json_results}{title} = 'Flushed Datatype Hash on the Current DB Server';
	$self->{json_results}{message} = 'You may need to clear otstatedata.datatype_hashes on other DB Servers';

}

1;
