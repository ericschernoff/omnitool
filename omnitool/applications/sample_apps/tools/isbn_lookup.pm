package omnitool::applications::sample_apps::tools::isbn_lookup;
# Searches GoogleBooks for an ISBN number and shows the results.
# Reasonable demo of Results_SearchForm.tt

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# enables book lookups
use omnitool::applications::sample_apps::common::book_finder;

# any special new() routines
sub init {
	my $self = shift;
}

# generates the form above the results table
sub generate_form {
	my $self = shift;

	$self->{luggage}{params}{form_submitted} = 1;

	# put together a form to search out the module
	$self->{json_results}{form} = {
		'title' => "Find a Book in Google Books by ISBN Number",
		'submit_button_text' => 'Find Books',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => {
			1 => {
				'title' => 'ISBN Number',
				'name' => 'isbn_number',
				'field_type' => 'short_text',
				'preset' => $self->{luggage}{params}{isbn_number},
			},
		}
	};
}

# search and display book found for an ISBN number in google books
sub perform_form_action {
	my $self = shift;

	# look up the book
	my $book_finder = omnitool::applications::sample_apps::common::book_finder->new();
	my $results = $book_finder->lookup_book_by_isbn_number($self->{luggage}{params}{isbn_number});

	# no book?
	if (!$$results{title} && $self->{luggage}{params}{isbn_number}) {
		$self->{json_results}{error_message} = 'No Books Found for '.$self->{luggage}{params}{isbn_number};
	}
	
	# otherwise, show the book

	# table headings
	$self->{json_results}{results_headings} = [
		'Title', 'Author', 'Pub Date', 'Volume'
	];
	# sub-keys = keys for column values --> the first one is the key to the {results} hash
	$self->{json_results}{results_sub_keys} = [
		'author', 'pubdate', 'volume',
	];
	
	# there would normally be more than one of these, but this only shows one result
	$self->{json_results}{results_keys}[0] = $$results{title};

	# the main content hash for the row
	$self->{json_results}{results}{ $$results{title} } = {
		'author' => $$results{author},
		'pubdate' => $$results{pubdate},
		'volume' => $$results{volume},		
	};


	# make sure the form shows ;)
	$self->{redisplay_form} = 1;

}

1;
