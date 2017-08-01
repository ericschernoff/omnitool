package omnitool::applications::otadmin::tools::flush_sessions;
# flushes active all user sessions for a whole application or instance
# can be used from Manage Instances or Manage Tools

use parent 'omnitool::tool';

# this is a read-only action, so we shall use 'prepare_message,' which
# will be picked up by action_tool.pm automatically.
sub perform_action {
	my $self = shift;

	# local vars
	my ($lineage);

	# are we in instance mode?
	if ($self->{target_datatype} eq '5_1') { # easy
		$self->flush_the_sessions($self->{omniclass_object}->{data_code}, $self->{omniclass_object}{data}{hostname});

		# fill in the needed info for the return object
		$self->{json_results}{title} = 'Flushed Sessions for '.$self->{omniclass_object}->{data}{name}.' ('.$self->{omniclass_object}->{data}{hostname}.')';
		$self->{json_results}{message} = 'Flushed '.$self->{flushed_count}.' sessions in this App Instance.'

	# tool mode is a little tougher; have to determine parent app
	# then flush for each instance of that app
	} else {
		# get my lineage, and the parent app will be $$lineage[1]
		$lineage = $self->{omniclass_object}->get_lineage(
			'data_code' => $self->{omniclass_object}->{data_code},
		);
		# now load up the instances of that app
		$self->{instances_omniclass_object} = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => '5_1',
			'skip_hooks' => 1,
		);
		$self->{instances_omniclass_object}->search(
			'search_options' => [
				{
					'match_column' => 'parent',
					'match_value' => $$lineage[1]
				},
				{
				'match_column' => 'database_server_id',
				'match_value' => $self->{db}->{server_id}
				},
			],
			'auto_load' => 1,
			'skip_hooks' => 1
		);
		foreach $instance (@{ $self->{instances_omniclass_object}{records_keys} }) {
			# use subroutine below; will save total count to $self->{flushed_count}
			$self->flush_the_sessions( $instance, $self->{instances_omniclass_object}->{records}{$instance}{hostname} );
		}

		# fill in the needed info for the return object
		$self->{json_results}{title} = 'Flushed Sessions for '.$self->{omniclass_object}->{data}{name};
		$self->{json_results}{message} = 'Flushed '.$self->{flushed_count}.qq{ sessions for the parent App's Instances};

	}

	# clear the lock
	# $self->{unlock} = 1;
}

# method to flush sessions per instances
sub flush_the_sessions {
	my $self = shift;
	# two args: the instance ID and the target instance hostname
	my ($target_instance, $target_instance_hostname) = @_;
	# both are requird
	return if !$target_instance || !$target_instance_hostname;

	# local vars
	my ($right_db_obj, $active_session_count);

	# we need to make sure we are connected to the right database server
	# we have that in the utility $self->{belt} for frequent use
	$right_db_obj = $self->{belt}->get_instance_db_object($target_instance, $self->{db}, $self->{luggage}{database_name});

	# retrieve the active session count for this application instance
	($active_session_count) = $right_db_obj->quick_select(
		'select count(*) from otstatedata.omnitool_sessions where hostname=?',
		[$target_instance_hostname]
	);

	# keep track of that count
	$self->{flushed_count} += $active_session_count;

	# actually clear those sessions
	$right_db_obj->do_sql(
		'delete from otstatedata.omnitool_sessions where hostname=?',
		[$target_instance_hostname]
	);

}

1;
