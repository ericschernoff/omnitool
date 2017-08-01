package omnitool::tool::basic_data_view;
# Acts as a tool.pm sub-class, providing a very basic data-display functions for Action Tools.
# This means providing a perform_actiom() method to build the data to feed into the very
# simple 'BasicDetails.tt' template.
#
# Most tool.pm sub-classes will live within an Application's Perl Modules directory, but this
# is a core feature of OmniTool and will available as a tool.pm class for any Application/Tool.

$omnitool::tool::basic_data_view::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# start our basic routine to gather up the data to display in Jemplate
sub perform_action {
	my $self = shift;

	my ($dt, $dtf, $table_column);

	# we need the field keys and names for this datatype
	my $dt = $self->{target_datatype}; # sanity
	foreach $dtf (@{ $self->{luggage}{datatypes}{$dt}{fields_key} }) {
		# sanity
		$table_column = $self->{luggage}{datatypes}{$dt}{fields}{$dtf}{table_column};
		# add to the key
		push(@{ $self->{json_results}{field_keys} }, $table_column );
		# get the name in there
		$self->{json_results}{fields}{$table_column} = $self->{luggage}{datatypes}{$dt}{fields}{$dtf}{name};
	}

	# we also need the data fetched for the record
	$self->{json_results}{data} = $self->{omniclass_object}{data};

	# not too hard ;)
}

1;
