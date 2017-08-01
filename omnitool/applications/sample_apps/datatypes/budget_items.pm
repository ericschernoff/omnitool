package omnitool::applications::sample_apps::datatypes::budget_items;

# is a sub-class of OmniClass, aka an 'OmniClass Package'
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::sample_apps::datatypes::budget_items::dt = '8_1';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# example autocomplete for the 'spending-category'
sub autocomplete_dependent {
	my $self = shift;

	my ($current_altcode) = @_; # action_tool.pm will tell you about the current record

	# look for their current search term in $self->{luggage}{params}{term}
	# and do some searching with that (snark) and return a flat arrayref

	my ($names, $dependent_object);

	$dependent_object = $self->get_omniclass_object(
		'dt' => 'dependents',
		'search_options' => [{
			'name' => $self->{luggage}{params}{term},
			'operator' => 'like',
		}],
		'load_fields' => 'name',
	);

	# where some found?
	if ($dependent_object->{search_found_count}) {

		# put the names into the keys for another hash to return
		$dependent_object->create_resolver_hash(
			'field_name' => 'name',
			'already_loaded' => 1,
		);

		@$names = sort keys %{$dependent_object->{resolver_hash}};

		return $names;

	} else { # return empty
		return [];
	}
}

# simple virtual field to color-code expense-types
sub field_expense_type_styled {
	my $self = shift;
	my ($args) = @_; # args passed to load()

	my ($r, $class);

	# go thru each record
	foreach $r (@{$self->{records_keys}}) {

		# luxury is red
		if ($self->{records}{$r}{expense_type} eq 'Luxury') {
			$class = 'red';
		} else {
			$class = 'green';
		}

		# put it together
		$self->{records}{$r}{expense_type_styled}[0] = {
			'text' => $self->{records}{$r}{expense_type},
			'class' => $class,
		};

		# contracts get alarms
		if ($self->{records}{$r}{contract} eq 'Yes') {
			$self->{records}{$r}{expense_type_styled}[0]{glyph} = 'fa-exclamation';
		};
	}

}

# example of getting options from another datatype
sub options_vendor {
	my $self = shift;
	my ($data_code, $new_parent_value) = @_; # primary key for record updating, if applicable
										# plus the new parent value (should always be filled)

	# load up all vendors
	my $vendors_object = $self->get_omniclass_object(
		'dt' => 'vendors',
		'load_all' => 1,
		'load_fields' => 'name',
	);

	# and use the utility menthod for the options
	my ($options,$options_keys) = $vendors_object->prep_menu_options();

    # return results
    return ($options,$options_keys);
}


1;
