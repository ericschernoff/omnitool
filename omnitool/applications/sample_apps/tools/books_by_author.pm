package omnitool::applications::sample_apps::tools::books_by_author;
# meant to demonstrate an action tool that displays results separated into multiple tables
# in this case, it will let you search our books by author(s), purchased-from vendors, and keyword
# and then display one table per author who has results

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# show the filtering fields:  Authors(s), Purchased-From, Keyword
sub generate_form {
	my $self = shift;

	my ($param, $authors_object, $field, $preset);

	# load up any previously-used display options
	foreach $param ('authors','purchased_from','keyword') {
		$self->{luggage}{params}{$param} = $self->{display_options}{$param};
	}

	# default for purchased-form
	$self->{luggage}{params}{purchased_from} ||= 'Amazon,B&N,Unknown';
	$self->{luggage}{params}{keyword} ||= '%';

	# if we have an author and form_submitted=0, toggle it
	if (!$self->{luggage}{params}{form_submitted} && $self->{luggage}{params}{authors}) {
		$self->{luggage}{params}{form_submitted} = 1;
	}

	# here is the form structure
	$self->{json_results}{form} = {
		'title' => 'Display Options',
		'submit_button_text' => 'Display Books for Selected Authors',
		'field_keys' => ['authors','purchased_from','keyword'],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => {
			'authors' => {
				'title' => 'Select Authors',
				'placeholder' => 'Select one',
				'name' => 'authors',
				'field_type' => 'multi_select_plain',
				'preset' => $self->{luggage}{params}{authors},
				'is_required' => 1,
				'instructions' => qq{
					Select at least one.
				},
			},
			'purchased_from' => {
				'title' => 'Purchased From',
				'placeholder' => 'Select one',
				'name' => 'purchased_from',
				'field_type' => 'multi_select_plain',
				'preset' => $self->{luggage}{params}{purchased_from},
				'options' => {
					'Amazon' => 'Amazon',
					'B&N' => 'B&N',
					'Unknown' => 'Unknown',
				},
				'options_keys' => ['Amazon','B&N','Unknown'],
				'is_required' => 1,
				'instructions' => qq{
					Select at least one.
				},
			},
			'keyword' => {
				'title' => 'Keyword',
				'placeholder' => 'Optional',
				'name' => 'keyword',
				'field_type' => 'short_text',
				'instructions' => qq{
					Set to '%' for no keyword.
				},
				'preset' => $self->{luggage}{params}{keyword}
			},
		}
	};

	# load in authors options

	# load up all the authors in one action
	# this is reasonably fast because there are only 125 of them
	# pack this in $self, since we need the object in perform_form_action
	$self->{authors_object} = $self->{omniclass_object}->get_omniclass_object(
		'dt' => 'authors',
		'data_codes' => ['all'],
		'skip_metainfo' => 1,
	);

	# somewhat long data structures
	($self->{json_results}{form}{fields}{authors}{options}, $self->{json_results}{form}{fields}{authors}{options_keys}) =
		$self->{authors_object}->prep_menu_options();

	# proper presets for multi-select fields
	foreach $field ('authors','purchased_from') {
		foreach $preset (split /,/, $self->{json_results}{form}{fields}{$field}{preset}) {
			$self->{json_results}{form}{fields}{$field}{presets}{$preset} = 1;
		}
	}

}

# action to perform the search based on form options
sub perform_form_action {
	my $self = shift;

	# no matter what happens...
	# make sure the form shows ;)
	$self->{redisplay_form} = 1;
	# and keep the options
	$self->{do_not_clear_display_options} = 1;

	my ($author, $authors, $book, $books_object, $isbn);

	# we are going to use the omniclass search to do the keyword matching, so
	# need to set a wide default
	$self->{luggage}{params}{keyword} ||= '%';

	# account for any leading blanks in the multi-selects
	$self->{luggage}{params}{author} =~ s/^,//;
	$self->{luggage}{params}{purchased_from} =~ s/^,//;

	# now load up the books which match their search
	$books_object = $self->{omniclass_object}->get_omniclass_object(
		'dt' => 'books',
		'search_options' => [
			{
				'match_column' => 'author',
				'operator' => 'in',
				'match_value' => $self->{luggage}{params}{authors},
			},
			{
				'match_column' => 'purchased_from',
				'operator' => 'in',
				'match_value' => $self->{luggage}{params}{purchased_from},
			},
			{
				'match_column' => 'concat(name,description)',
				'operator' => 'like',
				'match_value' => $self->{luggage}{params}{keyword},
			},
		],
		'resolver_hash_field' => 'author', # so we know which author(s) have at least one book
		'sort_column' => 'name',
	);

	# load up the requested authors, sorted by name
	@$authors = split /,/, $self->{luggage}{params}{authors};
	$self->{authors_object}->load(
		'do_clear' => 1,
		'data_codes' => $authors,
		'sort_column' => 'name',
	);

	# if none found show an error:
	if (!$books_object->{search_found_count}) {
		$self->{json_results}{error_title} = 'No Results Found; Please Adjust Search';
		return;
	}

	# headings for these books
	$self->{json_results}{result_tables_headings} = [
		'ISBN Number','Title','Purchased From','Pub Date'
	];

	foreach $author (@{ $self->{authors_object}->{records_keys} }) { # use sorted keys
		# only if at least one book was found
		next if !$books_object->{resolver_hash}{$author};

		# add this author to our list of tables
		push(@{ $self->{json_results}{result_tables_keys} }, $author);

		# set up the structure of this result table -- YES, EVERY TABLE COULD BE DIFFERENT
		$self->{json_results}{result_tables}{$author} = {
			'name' => $self->{authors_object}->{records}{$author}{name},
			'results_keys' => [], # will be filled the keys of the found books
			'results_sub_keys' => [ # the keys for the columns under $self->{json_results}{result_tables}{$author}{results}{$book}
				'title','purchased_from','pubdate'
			],
			'results' => {},
		};

		foreach $book (@{ $books_object->{records_keys} }) {

			# only for this author
			next if $author ne $books_object->{records}{$book}{author};

			# will use isbn as ID
			$isbn = $books_object->{records}{$book}{isbn_number};

			# add this book to the table's keys
			push(@{ $self->{json_results}{result_tables}{$author}{results_keys} }, $isbn);

			# load in the book
			$self->{json_results}{result_tables}{$author}{results}{$isbn} = {
				'title' => $books_object->{records}{$book}{name},
				'purchased_from' =>$books_object->{records}{$book}{purchased_from},
				'pubdate' => $books_object->{records}{$book}{pubdate},
			};
		}

	}


	# $self->{json_results}{result_tables} and $self->{json_results}{result_tables_keys} should now be filled and ready
	# to go towards the budget_viewer.tt jemplate

}

1;

