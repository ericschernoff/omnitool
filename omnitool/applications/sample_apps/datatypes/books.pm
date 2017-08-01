package omnitool::applications::sample_apps::datatypes::books;

# is a sub-class of OmniClass, aka an 'OmniClass Package'
use parent 'omnitool::omniclass';

# primary key of datatype
$omnitool::applications::sample_apps::datatypes::books::dt = '2_1';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# generate options for selecting the author for a new book
sub options_author {
	my $self = shift;
	my ($data_code) = @_;

	# load up all the authors in one action
	# this is reasonably fast because there are only 125 of them
	my $authors_object = $self->get_omniclass_object(
		'dt' => 'authors',
		'data_codes' => ['all'],
		'skip_metainfo' => 1,
	);

	# use our handy method meant for just this sort of task
	my ($options, $options_keys) = $authors_object->prep_menu_options();

    # return those menu options
    return ($options,$options_keys);

}

# load in the authors' names from the related datatype
sub field_author_name {
	my $self = shift;
	my ($args) = @_; # args passed to load()

	my ($authors_object, $author, $r);

	# load up all the authors in one action
	# this is reasonably fast because there are only 125 of them
	$authors_object = $self->get_omniclass_object(
		'dt' => 'authors',
		'data_codes' => ['all'],
		'skip_metainfo' => 1,
	);

	# now assign those names to the records
	foreach $r (@{$self->{records_keys}}) {
		$author = $self->{records}{$r}{author};
		$self->{records}{$r}{author_name} = $authors_object->{records}{$author}{name};
	}

}

# method to produce a hashref to display details via complex_details
sub view_details {
	my $self = shift;

	my ($details_hash, $author_object);

	# put the main part of the hash together
	$$details_hash{tab_info} = {
		1 => ['main','Main Info'],
	};
	$$details_hash{tab_keys} = [1];

	# default description
	$self->{data}{description} ||= 'Not Available';

	# load up the author
	$author_object = $self->get_omniclass_object(
		'dt' => 'authors',
		'data_codes' => [$self->{data}{author}]
	);

	# and our single tab
	$$details_hash{tabs} = {
		1 => {
			'type' => 'info_groups',
			'data' => [
				[
					[ 'Author', $author_object->{data}{name} ],
					[ 'Purchased From', $self->{data}{purchased_from} ],
					[ 'Have Owned', $self->{data}{metainfo}{nice_create_age} ],
				],
				[
					[ 'ISBN Number', $self->{data}{isbn_number} ],
					[ 'Pub Date', $self->{data}{pubdate} ],
					[ 'Volume', $self->{data}{volume} ],
				],
			],
			'text_blocks' => [
				[ 'Description', $self->{data}{description}],
			],
		},
	};

	# return the detalls hash
	return $details_hash;

}

1;
