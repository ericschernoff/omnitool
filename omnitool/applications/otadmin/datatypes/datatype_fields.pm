package omnitool::applications::otadmin::datatypes::datatype_fields;
# support module for the 'datatype_fields' datatype object.

# who raised me ;)
use parent 'omnitool::omniclass';
# and how they raised me
use strict;

# and my ID
$omnitool::applications::otadmin::datatypes::datatype_fields::dt = '7_1';

# for grabbing the datatype hash for options_target_datatypes
use omnitool::common::datatype_hash;

# special new() routines
sub init {
	my $self = shift;

}

# need a pre-save so we can make suere that the datatype field name is lower case;
# probably should add this as a feature of omniclass / datatype definitions if it comes up a lot
sub pre_save {
	my $self = shift;

	# i receive the args sent into omniclass
	my ($args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key('table_column',$args);

	# and make it lower case:
	$self->{luggage}{params}{$params_key} = lc($self->{luggage}{params}{$params_key});

	# also, no double-quotes in instructions; messes up the javascript
	$params_key = $self->figure_the_key('instructions',$args);
	$self->{luggage}{params}{$params_key} =~ s/\"/\'/g;

}

1;
