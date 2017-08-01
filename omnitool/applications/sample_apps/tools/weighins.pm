package omnitool::applications::sample_apps::tools::weighins;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# method to prepare JSON to render a chart via the Chart.js above the tool display
# should return the data that you can use here;  var myChart = new Chart(ctx, THIS_DATA_GOES_HERE);
# see http://www.chartjs.org/docs/latest/
# To use this, set 'Display a Chart' to something other than No in your Tool View Mode Config.
# This method will bring in my weigh-ins for the latest 21 days
sub charting_json {
	my $self = shift;

	# if this is a search tool, you may want to run the search like so:
	# $self->search();
	# and that will put the results in $self->{json_results}{records} and
	# $self->{json_results}{records_keys} for you to build up 'datasets' below

	# handy site for hex color codes: http://htmlcolorcodes.com/

	# grab the omniclass object manually, as this is not a 'core' function
	$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
	# was placed into $self->{omniclass_object} by get_omniclass_object()

	my ($num, $people, $person, $possible_colors, $record, $the_data);

	# start with eight good ones
	$possible_colors = ['113BA4','A4114F','11A423','6611A4','D68212','D0D423','050000','D4239E'];

	# if it's 'Any', we are doing everyone
	if ( $self->{display_options}{'menu_4_1'} eq 'Any') {

		$people = ['Eric','Ginger','Polly'];

	# otherwise, just that person
	} else {

		$people = [$self->{display_options}{'menu_4_1'}];

	}

	# start our data structure for the chart
	$self->{json_results} = {
		type => "line",
		data => {
			labels => [],
			datasets => []
			},
		options => {}
	};


	# now, for each person in people, let's find their last 21 weigh-ins
	# and add them into the datasets
	$num = 0;
	foreach $person (@$people) {

		$self->{omniclass_object}->search(
			'search_options' => [
				{ 'for_whom' => $person, }
			],
			'auto_load' => 1,
			'load_fields' => 'date,weight',
			'sort_column' => 'date',
			'do_clear' => 1,
		);

		$the_data = [];
		foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {
			if ($num == 0) { # on first one, set up labels
				push (@{ $self->{json_results}{data}{labels} }, $self->{omniclass_object}->{records}{$record}{date} );
			}

			# get the actual weights into our data for the line
			push (@$the_data, $self->{omniclass_object}->{records}{$record}{weight});

		}

		# now add the line for this person
		push (@{ $self->{json_results}{data}{datasets} },
			{
				label => $person,
				data => $the_data,
				borderColor => '#'.$$possible_colors[$num],
				backgroundColor => 'rgba(157, 195, 223, 0.1)',
				lineTension => 0.1
			}
		);

		$num++;

	}

	# have to send it out
	return $self->{json_results};

}


1;

