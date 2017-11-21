package omnitool::applications::sample_apps::tools::add_via_isbn;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# enables book lookups
use omnitool::applications::sample_apps::common::book_finder;

# any special new() routines
sub init {
	my $self = shift;
}

sub generate_form {
	my $self = shift;

	# simple one-field form

	$self->{json_results}{form} = {
		'title' => 'Add a Book by Its ISBN Number',
		'instructions' => 'Thirteen digits, often starts with 9780, and paperbacks have in front inside cover.',
		'submit_button_text' => 'Add Book',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'ISBN Number',
				'name' => 'isbn_number',
				'field_type' => 'short_text_clean',
				'preset' => $self->{luggage}{params}{isbn_number},
				'instructions' => 'No dashes please.',
				'is_required' => 1,
			},
		}
	};
}

# form validation is to try and validate the ISBN they sent
# only got this far if they filled out the form properly
# routine to add to the standard form validation routines
sub post_validate_form {
	my $self = shift;
	my ($form) = @_;

	# not 100% that last statement above is true, so just in case
	if (!$self->{luggage}{params}{isbn_number}) {
		$self->{stop_form_action} = 1;
		return;
	}

	# otherwise, try to look up the book

	my ($results, $book_finder);

	# look up the book
	$book_finder = omnitool::applications::sample_apps::common::book_finder->new();
	$results = $book_finder->lookup_book_by_isbn_number($self->{luggage}{params}{isbn_number});

	# was there an error?
	if ($$results{error} || !$$results{title} ) {
		$$form{fields}{1}{field_error} = 1;
		$$form{fields}{1}{error_instructions} = 'Invalid ISBN / Not Found';
		$self->{stop_form_action} = 1;
		return;

	# maybe not, stash the results for perform_form_action and move along
	} else {
		$self->{stop_form_action} = '';
		$self->{book} = $results;
	}

}
# routine to perform the action specified by the form from generate_form (goes hand-in-hand with that method)
sub perform_form_action {
	my $self = shift;

	my ($the_author, $authors_object);

	# do we already have a record for this author?
	if (!$self->{book}{author}) { # unknown
		$the_author = '125_1';
		
	} else { # otherwise, lookup
		$authors_object = $self->{luggage}{object_factory}->omniclass_object( 
			'dt' => 'authors',
			'search_options' => [
				{'name' => $self->{book}{author},}
			] 
		);
		
		# if not found, create
		if (!$authors_object->{search_found_count}) {
			
			# create the author
			$authors_object->save(
				'parent' => 'top',
				'params' => {
					'name' => $self->{book}{author},
				}
			);
			
			# this is going to be the author code
			$the_author = $authors_object->{last_saved_data_code};
			
		} else { # use the one we found
			
			$the_author = $authors_object->{search_results}[0];			
			
		}

	}

	# finally, add the book
	$self->{omniclass_object}->save(
		'parent' => 'top',
		'params' => {
			'isbn_number' => $self->{luggage}{params}{isbn_number},
			'name' => $self->{book}{title},
			'author' => $the_author,
			'description' => $self->{book}{description},
			'pubdate' => $self->{book}{pubdate},
			'volume' => $self->{book}{volume},
			'purchased_from' => 'Unknown',
		}
	);

	# send this upon successful submit
	$self->{json_results}{form_was_submitted} = 1;

	# $self->{redisplay_form} = 1;

	# if you want to convert to a pop-up notice
	$self->{json_results}{title} = '"'.$self->{book}{title}.'" Was Added.';
	# $self->{json_results}{message} = $n.' '.$self->{this_omniclass_object}{datatype_info}{name}.' records re-ordered under '.$self->{omniclass_object}{data}{name};
	$self->{json_results}{show_gritter_notice} = 1;

	# otherwise, fill in some values in $self->{json_results} for your Jemplate
}

1;
