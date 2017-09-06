package omnitool::applications::otadmin::tools::flush_datatype_hashes;
# drive the Flush Datatype Hashes action tool under Manage Instances
# as well as under 'Manage Datatypes'

use parent 'omnitool::tool';

use strict;

# this is a read-only action, so we shall use 'prepare_message,' which
# will be picked up by action_tool.pm automatically.
sub prepare_message {
	my $self = shift;
	my ($right_db_obj, $parent_app, $parent_string, $app_omniclass_object);

	# are we in instance mode?
	if ($self->{target_datatype} eq '5_1') { # easy
		# boil down to the parent application for this instance
		($parent_app = $self->{omniclass_object}->{data}{metainfo}{parent}) =~ s/1_1://;
		# and perform the flush using our method below
		$self->flush_datatype_hashes($parent_app,$self->{omniclass_object});

		# fill in the needed info for the return object
		$self->{json_results}{title} = 'Flushed Datatype Hash for '.$self->{omniclass_object}->{data}{name}.' ('.$self->{omniclass_object}->{data}{hostname}.')';

	# if in Manage Datatypes, we need to get the instances of the parent application
	} else {
		# since the target datatype is Datatype and the 'altcode' is the app,
		# we need to find the instances under this appl
		$parent_string = $self->{altcode_decoder}->parent_string_from_altcode($self->{display_options}{altcode}, '1_1');

		# now load them up
		$self->{instances_omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => '5_1',
			'skip_hooks' => 1,
			'search_options' => [
				{
					'parent' => $parent_string,
				},
				{
					'database_server_id' => $self->{db}->{server_id}
				},
			],
		);

		# and perform the flush using our method below
		($parent_app = $parent_string) =~ s/1_1://;
		$self->flush_datatype_hashes($parent_app,$self->{instances_omniclass_object});

		# load the application name
		$app_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => '1_1',
			'skip_hooks' => 1,
			'data_codes' => [$parent_app]
		);

		# fill in the needed info for the return object
		$self->{json_results}{title} = 'Flushed Datatype Hash for '.$app_omniclass_object->{data}{name};
		$self->{json_results}{message} = 'NOTE: If the Datatypes are shared with another Application, you will need to flush the DT Hash for those other Instances.';

	}
}

sub flush_datatype_hashes {
	my $self = shift;
	# two args: the parent application and the object containing the instance(s) we
	# need to flush sessions on
	my ($parent_app,$instance_object) = @_;

	my ($right_db_obj, $instance);

	# flush the datatype hashes for each instance / db server for the application
	foreach $instance (@{ $instance_object->{records_keys} }) {
		# we need to make sure we are connected to the right database server
		# we have that in the utility $self->{belt} for frequent use
		$right_db_obj = $self->{belt}->get_instance_db_object($instance, $self->{db}, $self->{luggage}{database_name});
		# this is fairly simple
		$right_db_obj->do_sql(
			'delete from otstatedata.datatype_hashes where hostname=?',
			[ $instance_object->{records}{$instance}{hostname} ]
		);
	}

}

1;
