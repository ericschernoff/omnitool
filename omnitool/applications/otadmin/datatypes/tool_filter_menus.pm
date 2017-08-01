package omnitool::applications::otadmin::datatypes::tool_filter_menus;

# is a sub-class of OmniClass
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::otadmin::datatypes::tool_filter_menus::dt = '15_1';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

sub prepare_for_form_fields {
	my $self = shift;
	my ($form) = @_; # what we have so far

	# we need to determine the parent tool, the other tool_filter menus
	if ($$form{hidden_fields}{new_parent}) {  # create-mode, will be the new parent
		$self->{the_parent} = $$form{hidden_fields}{new_parent};
	} else {
		$self->{the_parent} = $self->{data}{metainfo}{parent};
	}

	# need this for below
	$self->{this_data_code} = $$form{data_code};

}

# allow them to choose another menu to trigger option rebuilding when selecting an option for this menu
sub options_trigger_menu {
	my $self = shift;
	my ($data_code) = @_; # primary key for recording updating, if applicable

	my ($record, $options, $options_keys);

	# load up the other filter menus --> make sure it's not me
	$self->search(
		'search_options' => [
			{
				'match_column' => qq{concat(code,'_',server_id)},
				'operator' => '!=',
				'match_value' => $self->{this_data_code},
			},
			{
				'match_column' => 'parent',
				'operator' => '=',
				'match_value' => $self->{the_parent},
			},
		],
		'auto_load' => 1,
		'sort_column' => 'name',
		'skip_hooks' => 1,
		'load_fields' => 'name',
	);

	# have a 'None' option so people feel better
	$$options{'None'} = 'None';
	push(@$options_keys,'None');

	foreach $record (@{ $self->{records_keys} }) {
		next if $record eq $self->{this_data_code};
		$$options{$record} = $self->{records}{$record}{name};
		push(@$options_keys,$record);
	}

    # return results
    return ($options,$options_keys);
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
	my ($data_code) @_; # primary key for recording updating, if applicable

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

