package omnitool::tool::setup_diagram;

=cut
Attempt at a generic tool.pm sub-class for editing network diagrams
with omnitool_diagram_obj.js

depends on certain methods being in the omniclass package:
	- load_diagram_data
	- save_diagram_data

Also, make sure your application has a 'saved_network_diagrams' datatype
with a 'diagram_data' long_text field for stashing the JSON data for the diagram.

=cut

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine for performing complex actions and adding information to $self->{json_results}
# you can cheat and use it to prepare messages
sub perform_action {
	my $self = shift;

	$self->{json_results}{title} = 'Editing Diagram for '.$self->{omniclass_object}{data}{name};
	
	# the omnitool_diagram_obj.js class will do much of the rest 

	# if they sent a method name in 'diagram_action', it means they want to load and save, 
	# and we should direct them to network_diagram_data() below
	# handling this way so we get all the action_tool.pm goodies
	if ($self->{luggage}{params}{diagram_action}) {
		$self->network_diagram_data();
	}
}


# custom/direct method omnitool_diagram_obj's 'load_network_data' and
# 'save_network_data' methods to do their work of loading and saving the diagram 
# depends on the omniclass object having methods with those same names
sub network_diagram_data {
	my $self = shift;

	# what do they want to do?  this will be either 'load_network_data' or 'save_network_data' 
	my $call_method = $self->{luggage}{params}{diagram_action};
	# default to the loader
	$call_method ||= 'load_network_data';
	
	# if you have a custom 'save_network_data' method, it should just return 'success'
	
	# we are going to need a 'saved_network_diagrams' omniclass object for either function
	# stash that in 'luggage' for easy transport to the omniclass package
	$self->{luggage}{saved_network_diagrams} = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'saved_network_diagrams',
		'search_options' => [
			{
				'match_column' => 'parent',
				'match_value' => $self->{omniclass_object}->{parent_string}
			},
			# will be named for the tool datacode, so each record could have different types
			# of diagrams, i.e. cases have a 'request diagram' and a 'booking diagram'
			{
				'match_column' => 'name',
				'match_value' => $self->{tool_datacode}
			},
		],
		'auto_load' => 1,
	);
	
	# okay, they really, really should have a 'load_network_data' method
	# in their omniclass package.  i am not covering for that
	# but if they do not want to write a 'save_network_data', 
	# then we can do this:
	if ($call_method eq 'save_network_data' && !$self->{omniclass_object}->can($call_method)) {
		$self->{luggage}{saved_network_diagrams}->save(
			'data_code' => $self->{luggage}{saved_network_diagrams}{data_code},
			'parent' => $self->{omniclass_object}->{parent_string},
			'params' => {
				'name' => $self->{tool_datacode},
				'diagram_data' => $self->{luggage}{params}{diagram_data}
			},
			'skip_blanks' => 1,
		);
		
		# perhaps they would just like a hook?
		if ($self->{omniclass_object}->can('post_save_network_data')) {
			$self->{omniclass_object}->post_save_network_data();
		}
				
		$self->{json_results}{result} = 'Success';
		

	# okay dorks, if you can't manage to write a 'load_network_data' method, i'll just spit
	# back the JSON
	} elsif ($call_method eq 'load_network_data' && !$self->{omniclass_object}->can($call_method)) {

		$self->{json_results}{diagram_data} = $self->{luggage}{saved_network_diagrams}->{data}{diagram_data};

	# otherwise, if they can call the desired method, do it
	} elsif ($self->{omniclass_object}->can($call_method)) {
		# run it and return results
		$self->{json_results}{diagram_data} = $self->{omniclass_object}->$call_method();
	
	# and if they cannot call that method, croak an error
	} else {
		$self->{belt}->mr_zebra(qq{ERROR: $call_method is not available to setup_diagrams.pm},1);
	}
	


} 

1;
