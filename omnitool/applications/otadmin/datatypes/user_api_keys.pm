package omnitool::applications::otadmin::datatypes::user_api_keys;

# is a sub-class of OmniClass
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::otadmin::datatypes::user_api_keys::dt = '18_1';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to run at the start of save(), before creating or updating the record(s).
# pre-fills some values if left blank
sub pre_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

	# make sure those api keys do not contain the username
	$self->{luggage}{params}{api_key_string} =~ s/$self->{luggage}{params}{username}//;

	# do not set defaults if we have 'skip_blanks' on
	return if $$args{skip_blanks};

	# if it's blank, make the api_key_string a long random string tied to their username
	if (!$self->{luggage}{params}{api_key_string}) {

		$self->{luggage}{params}{api_key_string} = $self->{belt}->random_string(50);

	}

	# make sure it's unique by adding the epoch - if in create mode
	if (!$self->{luggage}{params}{record}) {
		$self->{luggage}{params}{api_key_string} .= time();
	}

	# if the 'expiration_date' is blank, set it for 90 days from now
	if (!$self->{luggage}{params}{expiration_date}) {

		$self->{luggage}{params}{expiration_date} = $self->{belt}->time_to_date( time() + 7776000, 'to_date_db');

	}

}

# simple field to do a join() on the tied-to ip addresses
sub field_tied_to_ip_address_display {
	my $self = shift;
	my ($args) = @_; # args passed to load()
	
	my ($r);
	foreach $r (@{$self->{records_keys}}) {
		($self->{records}{$r}{tied_to_ip_address_display} = $self->{records}{$r}{tied_to_ip_address}) =~ s/\n/, /g;
	}
}

1;

__END__

Possible / example routines are below.  Please copy and paste them above the '1;' above
to make use of them.  See Pod documentation at the end of omniclass.pm to see usage suggestions.

Also, please be sure to save this file as $OTHOME/code/omnitool/applications/otadmin/datatypes/.pm

# routine to run at start of load() before loading records from the database.
sub pre_load {
	my $self = shift;
	my ($args) = @_; # args passed to load()

}

# virtual field hook subroutine; should be named 'field_' + 'table_column' val
# likely will have more than one of these
sub field_XYZ {
	my $self = shift;
	my ($args) = @_; # args passed to load()

=cut
	Quick example - not for real use.
	foreach $r (@{$self->{records_keys}}) {
		$self->{records}{$r}{enhanced_name}[0] = {
			'text' => $self->{records}{$r}{name},
			'uri' => '#/tools/ot_admin/tools_mgr/'.$self->{metainfo}{$r}{altcode},
			'glyph' => $self->{records}{$r}{icon_fa_glyph}
		};
	}
=cut

}

# routine to run at the end of load(), after loading records from the database.
sub post_load {
	my $self = shift;
	my ($args) = @_; # args passed to load()

}

# routine to run at the start of save(), before creating or updating the record(s).
sub pre_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

}

# routine to run at the end of save().  Good for any clean-up actions or sending notices.
sub post_save {
	my $self = shift;
	my ($args) = @_; # args passed to save()

}

# routine to run at the start of search(), before setting up and executing a search
sub pre_search {
	my $self = shift;
	my ($args) = @_; # args passed to search()

	# uncomment to stop the search
	# $$args{cancel_search} = 1;
}

# routine to run towards the end of search(), after the search was executed but before
# the records are auto-loaded
sub post_search {
	my $self = shift;
	my ($args) = @_; # args passed to search()

	# where primary keys of matched records will be
	# @{ $self->{search_results} }
}

# routine to run before a record is deleted, but after the data lock is checked
sub pre_delete {
	my $self = shift;
	my ($args) = @_; # args passed to delete()

	# uncomment to stop the delete
	# $$args{cancel_delete} = 1;
}

# routine to run after the deletion has occurred
sub post_delete {
	my $self = shift;
	my ($args) = @_; # args passed to delete()

}

# routine to run in form() before we prepare the individual fields
sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # arguments passed to form() plus the current form structure data

}

# example routine to generate options for a select / radio / checkboxes field
# should be named 'options_' + 'table_column' val, where table_column is from target Datatype Field
# likely will have more than one of these
sub options_XYZ {
	my $self = shift;
	my ($data_code) = @_; # primary key for recording updating, if applicable

=cut
	Example of setting options from JavaScript files in from directory

	my $js_directory = $ENV{OTHOME}.'/code/omnitool/applications/'.$self->{parent_application_code_dir}.'/javascript/';
	($options,$options_keys) = $self->options_from_directory($js_directory,'js');

	Example of just hard-setting it

	$options = {
		'ginger' => 'Perfect',
		'pepper' => 'Loyal',
		'lorelei' => 'Brilliant',
	};
	$options_keys = ['ginger','pepper',lorelei'];
=cut

    # return results
    return ($options,$options_keys);
}

# example of hook to call after running form() and building a create/update form
# useful for modifying that form structure
sub post_form_operations {
	my $self = shift;
	my ($form) = @_; # the complete form structure

	# easy / uncessary change:
	# $$form{instructions} .= 'This text was added to the form instrutions.';

}

# example hook to run after create/update form was submitted and it passed basic
# validation; perform additional validation logic
sub post_validate_form {
	my $self = shift;
	my ($form) = @_; # the complete form structure

	# to stop the form submission from going through:

	# first, mark the field as error:
	# $$form{fields}{$field}{field_error} = 1;

	# then, give a reason in the offending form field
	# $$form{fields}{$field}{error_instructions} = 'Some reason';

	# then return a '1'
	# return 1;

	# to let it submit without problem, return 0;
}

# example of a method which would be called from the background_task_manager via
# do_task() to do some work in the background
sub example_background_task {
	my $self = shift;
	my ($args) = @_; # args passed to load()
	# this can contain:
	#	- data_code: a specific record's primary key
	#	- any arguments sent in by your add_task() call
	# it WILL contain
	#	- task_id: the primary key of the currently-running task in background_table

	# you may want to load the data
	$self->load(
		'data_codes' => [$$args{data_code}]
	);

	# do some stuff here

	# if it was successful
	return ('Success', 'Some results output');
	# or if it failed, do
	return ('Error', 'An information error message');

}

