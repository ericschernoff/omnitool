package omnitool::omniclass::field_grabber;

=cut
	Our job is to make sure that the %$params key named for a table column contains the
	desired value for that table column, so we are just massaging the CGI params
	this is not necessary for fields which are:

	email_address, font_awesome_select, high_decimal, high_integer, long_text,
	low_decimal, low_integer, month_name, phone_number, radio_buttons,
	short_text, short_text_tags, simple_date, single_select, and web_url

	active_status_select and yes_no_select are just specially-prepared single-selects.

	Here are the special field types we need to accomodate:
		- access_roles_select
		- active_status_select
		- check_boxes
		- file_upload ** this is a TODO
		- multi_select_plain / multi_select_ordered
		- password
		- short_text_clean (only alphanumeric chars plus dashes, decimels, and underscores)
		- short_text_encrypted - short text which gets encrypted into the DB, using the field's primary key
		- street_address
		- yes_no_select

	Each of these special fields will get a method below to transform what is expected in the
	CGI %$params into something that can be stuffed in a single database field.  These methods
	have to be named exactly as the 'field_type' value for the corresponding datatype field.
	(i.e. the value of omnitool.datatype_fields.field_type).

	Each method takes expects the $table_column variable, which is the name of the destination
	column in the record's table for this bit of data; it will also either be the whole %$params key
	or follow a custom prefix (i.e. the piece in $$args{params_key} for saver(); that is why
	we also get %$args sent into saver(). Third argument is the key of the current Datatype field.
	Everything else should be in $self.  These methods are mainly useful in the context of saver(),
	but never say never ;)

=cut

# access_roles are really multi-selects, which are just like checkboxes
sub access_roles_select {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# if more than one was sent, it will be stored in @{$$luggage{params}{multi}{$params_key}}
	# MAKE NOTE: Will have to build that for scripts
	$self->{luggage}{params}{$params_key} = $self->{belt}->comma_list($self->{luggage}{params}{multi}{$params_key},';;;');
}

# active-status selects via the Ace toggles
sub active_status_select {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's filled at all, that will mean 'Active'
	if ($self->{luggage}{params}{$params_key} && $self->{luggage}{params}{$params_key} ne 'Inactive') { # ace could set to 'on'
		$self->{luggage}{params}{$params_key} = 'Active';
	# otherwise, no (adjust to make skip_blank work
	} elsif (!$$args{skip_blanks} || $self->{luggage}{params}{$params_key}) {
		$self->{luggage}{params}{$params_key} = 'Inactive';
	}

	# default is 'Inactive'
	if (!$$args{skip_blanks}) {
		$self->{luggage}{params}{$params_key} ||= 'Inactive';
	}

}

# checkboxes and multi-select allow for multiple values for one field name
sub check_boxes {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# if more than one was sent, it will be stored in @{$$luggage{params}{multi}{$params_key}}
	# MAKE NOTE: Will have to build that for scripts
	$self->{luggage}{params}{$params_key} = $self->{belt}->comma_list($self->{luggage}{params}{multi}{$params_key},';;;');
}

# Color-picker: remove the '#' that has to be in the forms
sub color_picker {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# just pluck out that '#'
	$self->{luggage}{params}{$params_key} =~ s/\#//gi;
}

# accept file uploads either as path/url text or plack form uploads
# works with omnitool::common::file_manager to pull in the file, make a record in the 'stored_files'
# table and return the primary key for that file; update the previous record if there is one
sub file_upload {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# if this is an update, we want the previous value
	my ($previous_value); # we want it to be blank if it's non-existent
	if ($$args{data_code}) {
		($code,$server_id) = split /_/, $$args{data_code};

		($previous_value) = $self->{db}->quick_select(
			"select $table_column from ".$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?', [$code, $server_id]);
	}

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if they uploaded a file via the web ui or they provided a path/url to a file,
	# use 'store_file' to receive the file, store it as per the instance, and return a
	# pointer to the file's record in the 'stored_files' table for this instance

	if ($self->{belt}->{request} && $self->{belt}->{request}->uploads->{$params_key}) { # just need the $params_key

		$self->{luggage}{params}{$params_key} = $self->{file_manager}->store_file($params_key,$previous_value);

	} elsif ($self->{luggage}{params}{$params_key}) { # need the value they provided
		
		$self->{luggage}{params}{$params_key} = $self->{file_manager}->store_file($self->{luggage}{params}{$params_key},$previous_value);

	# if no file provided, but there was a previous value, for an update, go with that
	} elsif ($previous_value) {

		$self->{luggage}{params}{$params_key} = $previous_value;

	}

}

=cut
# multi_select menus are just like checkboxes
sub multi_select {
	my $self = shift;
	my ($table_column,$args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# if more than one was sent, it will be stored in @{$$luggage{params}{multi}{$params_key}}
	# MAKE NOTE: Will have to build that for scripts
	$self->{luggage}{params}{$params_key} = $self->{belt}->comma_list($self->{luggage}{params}{multi}{$params_key},';;;');
}
=cut

# passwords are short-text fields which need to be hashed via SHA2; and if no value was sent, we use a previously-set value for an update
sub password {
	my $self = shift;
	my ($table_column,$args,$field) = @_;
	my ($code,$server_id,$match_data_code);

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it is filled, encrypt/hash via SHA2
	if ($self->{luggage}{params}{$params_key}) {
		($self->{luggage}{params}{$params_key}) = $self->{db}->quick_select('select sha2(?,224)',[$self->{luggage}{params}{$params_key}]);

	# if an update and no value, use previous value
	} elsif ($$args{data_code}) {
		($code,$server_id) = split /_/, $$args{data_code};

		($self->{luggage}{params}{$params_key}) = $self->{db}->quick_select(
			"select $table_column from ".$self->{database_name}.'.'.$self->{table_name}.
			' where code=? and server_id=?', [$code, $server_id]);
	}
}

# 'clean' short text; only alphanumeric spaces, dashes, decimels and underscores
sub short_text_clean {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# it should be already filled, we just need to do a regexp cleaning
	$self->{luggage}{params}{$params_key} =~ s/[^0-9a-z\_\-\.]//gi;
}

# encrypted short text: use $db->encrypt_string
sub short_text_encrypted {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# use the $db->encrypt_string() method to utilize the encryption features of mysql
	$self->{luggage}{params}{$params_key} = $self->{db}->encrypt_string($self->{luggage}{params}{$params_key}, $field);

	## NOTE:  This is NOT hard security.  It is only meant to help you secure your
	# database dumps a bit better than plain text.
}

# street addresses
sub street_address {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# a street address is made up of six parts, which we shall place on six separate lines into our record
	# not easy for searching, but easy for rebuilding
	$self->{luggage}{params}{$params_key} = ''; # just to be sure
	my $part;
	foreach $part ('street_one','street_two','city','state','zip','country') {
		$self->{luggage}{params}{$params_key} .= $self->{luggage}{params}{$params_key.'_'.$part}."\n";
	}
	# get rid of that last \n
	$self->{luggage}{params}{$params_key} =~ s/\n$//;

	# some lines will be blank, and we are OK with that

}

# yes/no selects via the Ace toggles
sub yes_no_select {
	my $self = shift;
	my ($table_column,$args,$field) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my ($params_key);
	$params_key = $self->figure_the_key($table_column,$args);

	# if it's filled at all, that will mean 'yes'
	if ($self->{luggage}{params}{$params_key} && $self->{luggage}{params}{$params_key} ne 'No') { # ace could set to 'on'
		$self->{luggage}{params}{$params_key} = 'Yes';
	# otherwise, no (adjust to make skip_blank work
	} elsif (!$$args{skip_blanks} || $self->{luggage}{params}{$params_key}) {
		$self->{luggage}{params}{$params_key} = 'No';
	}
	# default is 'No'
	if (!$$args{skip_blanks}) {
		$self->{luggage}{params}{$params_key} ||= 'No';
	}
}

1;


__END__

Due to the magic of JQuery, we really do not need these any more.  Storing here for safe-keeping

# month name is not hard
sub month_name {
	my $self = shift;
	my ($table_column,$args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# otherwise, put it together; expecting year, month, date sub-keys in there
	$self->{luggage}{params}{$params_key} = $self->{luggage}{params}{$params_key.'_monthname'}.' '.$self->{luggage}{params}{$params_key.'_year'};
}

# phone number is not too bad ;)
sub phone_number {
	my $self = shift;
	my ($table_column,$args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# otherwise, put it together; expecting area_code, prefix (co number), and line_number (last four)
	# we are going to format it as 555-123-4567; US-only numbers; may support other countries via
	# other field types later
	$self->{luggage}{params}{$params_key} = $self->{luggage}{params}{$params_key.'_area_code'}.'-'.$self->{luggage}{params}{$params_key.'_prefix'}.'-'.$self->{luggage}{params}{$params_key.'_line_number'};
}

# simple date is pretty easy
sub simple_date {
	my $self = shift;
	my ($table_column,$args) = @_;

	# what is the base %$params keys; this will also be the destination of the data
	my $params_key = $self->figure_the_key($table_column,$args);

	# if it's already filled, no reason to continue
	return if $self->{luggage}{params}{$params_key};

	# otherwise, put it together; expecting year, month, date sub-keys in there
	$self->{luggage}{params}{$params_key} = $self->{luggage}{params}{$params_key.'_year'}.'-'.$self->{luggage}{params}{$params_key.'_month'}.'-'.$self->{luggage}{params}{$params_key.'_date'};
}
