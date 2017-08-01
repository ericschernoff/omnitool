package omnitool::applications::otadmin::datatypes::database_servers;

# is a sub-class of OmniClass
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::otadmin::datatypes::database_servers::dt = '4_1';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# post_form_validation for create/update form submissions
# make sure there are no db servers with the same hostname
sub post_validate_form {
	my $self = shift;
	my ($form) = @_; # the complete form structure
		
	my ($fk, $field, $hostname_conflict, $conflict_type, $instance_obj, $status_conflict, $server_id);	
		
	# see if any instances for other applications share this server's proposed hostname
	$self->search(
		'search_options' => [
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $$form{data_code},
			},
			{
				'match_column' => 'hostname',
				'operator' => '=',
				'match_value' => $self->{luggage}{params}{hostname},
			},
		],
		'auto_load' => 1,
		'skip_hooks' => 1,
	);
	
	# save off the hostname conflict, if there is one	
	if ($self->{search_results}[0]) {
		$hostname_conflict = $self->{search_results}[0];
		$conflict_type = 'hostname';
		
	# if no conflict found, make sure they cannot mark a DB server inactive if it has active instances attached
	} elsif ($self->{luggage}{params}{status} ne 'on' && $$form{data_code} && $$form{action} eq 'update') {	
		($server_id = $$form{data_code}) =~ s/\_\d+//;
		$instance_obj = $self->{luggage}{object_factory}->omniclass_object(
			'dt' => '5_1',
			'skip_hooks' => 1,
		);	
		$instance_obj->search(
			'search_options' => [
				{
				'match_column' => 'database_server_id',
				'match_value' => $server_id
				},
				{
				'match_column' => 'status',
				'match_value' => 'Active'
				}
			],
			'auto_load' => 1,
			'skip_hooks' => 1
		);		
		if ($instance_obj->{search_results}[0]) {
			$status_conflict = $instance_obj->{search_results}[0];
			$conflict_type = 'status';
		}
	}

	# if there is a conflict, then we have a problem
	# handle it this sort of obfuscated way so we can add other conflict checks later
	if ($conflict_type) {
		
		# figure out which field this is for
		foreach $fk (@{$$form{field_keys}}) {
			if ($$form{fields}{$fk}{name} eq $conflict_type) {
				$field = $fk;
				last;
			}
		}
		
		# first, mark the field as error:
		$$form{fields}{$field}{field_error} = 1;
	
		# then, give a reason in the offending form field
		if ($conflict_type eq 'hostname') {
			$$form{fields}{$field}{error_instructions} = "ERROR: Hostname is duplicate to another DB Server: ".$self->{records}{$hostname_conflict}{name};
		} else {
			$$form{fields}{$field}{error_instructions} = "ERROR: DB Server must remain Active, as there is at least one active App Instance tied to it: ".$instance_obj->{records}{$status_conflict}{name};
		}

		# then return a '1'
		return 1;
	
	# otherwise, we are good
	} else {
		return 0;
	}
}



1;
