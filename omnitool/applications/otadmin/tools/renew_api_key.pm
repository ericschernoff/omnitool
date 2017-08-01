package omnitool::applications::otadmin::tools::renew_api_key;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to perform quicker/simpler actions and prepare notification messsages
sub prepare_message {
	my $self = shift;

	# get the new expiration date
	$self->{luggage}{params}{expiration_date} = $self->{belt}->time_to_date( time() + 7776000, 'to_date_db');

	# save the change
	$self->{omniclass_object}->save(
		'data_code' => $self->{omniclass_object}->{data_code},
		'skip_blanks' => 1,
	);

	# for nice message
	my $formatted_date = $self->{belt}->time_to_date($self->{luggage}{params}{expiration_date}, 'to_date_human');

	$self->{json_results}{title} = 'API Key Expiration Date Set to 90 Days from Today';
	$self->{json_results}{message} = qq{Key will no expire on $formatted_date.};

}

1;

