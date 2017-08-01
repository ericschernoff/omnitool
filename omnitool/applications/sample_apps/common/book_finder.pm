package omnitool::applications::sample_apps::common::book_finder;
# simple class to look-up book data by isbn number
# needed for 'Add Book By ISBN Number' and 'Lookup Book by ISBN' tools

# enables book lookups - we installed this and WWW::Scraper::ISBN::GoogleBooks_Driver
use WWW::Scraper::ISBN;

sub new {
	my $class = shift;

	my ($scraper, @drivers, $self);

	# initialize the scraper using the GoogleBooks driver
	$scraper = WWW::Scraper::ISBN->new();
	@drivers = $scraper->available_drivers();
	$scraper->drivers("GoogleBooks");

	# make the object
	$self = bless {
		'scraper' => $scraper,
	}, $class;

	# send it out
	return $self;

}

# the reason we are here: to fetch book data from an ISBN number
sub lookup_book_by_isbn_number {
	my $self = shift;

	my ($isbn_number) = @_;

	# no dashes or other special characters
	$isbn_number =~ s/\D//g;

	# reject if invalid
	if (length($isbn_number) != 13) {
		return {
			'error' => 'Invalid ISBN Number Sent.'
		};
	}

	my ($record, $book, $key);

	# do the search, safely
	eval {
		$record = $self->{scraper}->search($isbn_number);
	};

	# if found, clean up and send out the results
	if ($record->found) {
		$book = $record->book;
		foreach $key ('title','author','description','pubdate','volume') {
			$$book{$key} =~ s/[^[:ascii:]]/_/g;
		}
		$$book{status} = 'Record Found.';

		# send it out
		return $book;

	# otherwise, return not found
	} else {
		return {
			'error' => $isbn_number. ' Not Found'
		};
	}
}


1;
