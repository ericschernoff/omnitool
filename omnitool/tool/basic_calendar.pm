package omnitool::tool::basic_calendar;
# Acts as a tool.pm sub-class, providing a very basic data-display functions for Action Tools.
# This means providing a perform_actiom() method to build the data to feed into the very
# simple 'Calendar.tt' template.  
#
# Most tool.pm sub-classes will live within an Application's Perl Modules directory, but this
# is a core feature of OmniTool and will available as a tool.pm class for any Application/Tool.

$omnitool::tool::basic_calendar::VERSION = '6.0';

# make sure it's a sub-class of tool.pm, just like if it were in the application app code directory
use parent 'omnitool::tool';

# time to grow up, old man
use strict;

# start our basic routine to gather up the data to display in Jemplate
sub perform_action {
	my $self = shift;
	
	my ($dt, $dtf, $n, $dc, $simple_date_column);
	
	# we need the first simple date for this datatype
	$dt = $self->{target_datatype}; # sanity
	foreach $dtf (@{ $self->{luggage}{datatypes}{$dt}{fields_key} }) {
		if ($self->{luggage}{datatypes}{$dt}{fields}{$dtf}{field_type} eq 'simple_date') {
			$simple_date_column = $self->{luggage}{datatypes}{$dt}{fields}{$dtf}{table_column};
			last;
		}
	}

	# load all records of this type
	$self->{omniclass_object}->load(
		'data_codes'=>['all'],
		'sort_column' => 'birthdate'
	);

	# build our array of events
	$n = 0;
	foreach $dc (@{ $self->{omniclass_object}->{records_keys} }) {

		$self->{json_results}{events}[$n] = {
			'title' => $self->{omniclass_object}->{records}{$dc}{name},
			'id' => $dc,
			'start' => $self->{omniclass_object}->{records}{$dc}{$simple_date_column},
			'url' => $self->{my_base_uri}.'/view/'.$self->{omniclass_object}->{metainfo}{$dc}{altcode}
		};

		$n++;
	}

	# not too hard ;)
}

1;
