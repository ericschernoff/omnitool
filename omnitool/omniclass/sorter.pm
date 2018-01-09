package omnitool::omniclass::sorter;

=cut

Provides the data-sorting capabilities of the omniclass module, including the
simple_sort() method for sorting on one field and complex_sort() for sorting on
multiple fields.  More notes in the Pod docs in omniclass.pm

=cut

$omnitool::omniclass::sorter::VERSION = '6.0';
# really first time doing it this way, but replacing original design

# time to grow up
use strict;

sub simple_sort {
	my $self = shift;

	# likely the args passed into load(), but can just be:
	#	'sort_column' => table_column_to_sort_on
	#	'sort_direction' => 'Up' or 'Down' or 'Ascending' or 'Descending' --> defaults to 'Up'
	my ($args) = @_;

	my ($which, $table_column, $sort_column, $first_col, $field);

	# use sort column/direction from last time if not changed this time (and actually was set before)
	# example would be a search update or reloading a just-updated record
	$$args{sort_column} = $self->{sort_column} if !$$args{sort_column} && $self->{sort_column};
	$$args{sort_direction} = $self->{sort_direction} if !$$args{sort_direction} && $self->{sort_direction};

	# virtual fields need to rely on a real DB-table column for sorting, since they are a bit of a mess
	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		$table_column = $self->{datatype_info}{fields}{$field}{table_column}; # sanity
		if ($self->{datatype_info}{fields}{$field}{sort_column} && ($$args{sort_column} eq $table_column || $self->{sort_column} eq $table_column)) {
			$$args{sort_column} = $self->{datatype_info}{fields}{$field}{sort_column};
		}
	}

	# now for sorting, only if sorting was specified
	# we are doing it here so that we could sort after any data_massaging via the 'colXYZ()' hooks
	if ($$args{sort_column}) {
		$sort_column = $$args{sort_column}; # sanity
		if ($sort_column =~ /^metainfo./i) { # operate on the metainfo records
			$sort_column =~ s/metainfo\.//i;
			$first_col = 'create_time'; # fallback is creation time
			$which = 'metainfo';
		} else { # sorting on main records
			$first_col = 'name'; # fallback is name
			$which = 'records';
		}

		# now dow the sorting
		if (!$$args{sort_direction} || $$args{sort_direction} =~ /up|asc/i) { # sort upwards
			@{$self->{records_keys}} = sort {
				$self->{$which}{$a}{$sort_column} <=> $self->{$which}{$b}{$sort_column}
				|| $self->{$which}{$a}{$sort_column} cmp $self->{$which}{$b}{$sort_column}
				|| $self->{$which}{$a}{$first_col} <=> $self->{$which}{$b}{$first_col}
				|| $self->{$which}{$a}{$first_col} cmp $self->{$which}{$b}{$first_col}
			} keys %{$self->{$which}};

		} else { # sort downwards
			@{$self->{records_keys}} = sort {
				$self->{$which}{$b}{$sort_column} <=> $self->{$which}{$a}{$sort_column}
				|| $self->{$which}{$b}{$sort_column} cmp $self->{$which}{$a}{$sort_column}
				|| $self->{$which}{$b}{$first_col} <=> $self->{$which}{$a}{$first_col}
				|| $self->{$which}{$b}{$first_col} cmp $self->{$which}{$a}{$first_col}
			} keys %{$self->{$which}};
		}
	}

	# remember the sort column / direction for next time, if they sent it
	$self->{sort_column} = $$args{sort_column} if $$args{sort_column};
	$self->{sort_direction} = $$args{sort_direction} if $$args{sort_direction};

}

# the complex sort allows them to sort by multiple columns / directions
# expects an arrayref, with 'field_name | direction' format for the values
sub complex_sort {
	my $self = shift;

	my ($complex_sort_list) = @_;

	my ($numeric_sort, $which, $table_column, $field, $sorter, $sort_logic_string, $sort_column, $sort_column_direction_pair, $second_key, $first_key, $direction, @sort_logics);

	# can't be blank
	return if !$$complex_sort_list[0];

	# return if no point
	return if !$self->{records_keys}[0];

	# It's about to get pretty nasty in here folks.
	# We are going to build an anonymous subroutine to sort the results based on the
	# (unlimited) number of instructions they sent.

	# cycle thru the list
	foreach $sort_column_direction_pair (@$complex_sort_list) {
		next if $sort_column_direction_pair !~ / \| / || !$sort_column_direction_pair; # skip blanks

		# get the parts out
		($sort_column, $direction) = split / \| /, $sort_column_direction_pair;

		# no bad data!!
		next if !$sort_column;

		# which table does this field use?
		if ($sort_column =~ /^metainfo./i) { # operate on the metainfo records
			$sort_column =~ s/metainfo\.//i;
			$which = 'metainfo';
		} else { # sorting on main records
			$which = 'records';
		}

		# virtual fields need to rely on a real DB-table column for sorting, since they are a bit of a mess
		foreach $field (@{ $self->{datatype_info}{fields_key} }) {
			$table_column = $self->{datatype_info}{fields}{$field}{table_column}; # sanity

			# only if it's this current field
			next if $sort_column ne $table_column;

			# vitual field with a defined sort column
			if ($self->{datatype_info}{fields}{$field}{sort_column}) {
				$sort_column = $self->{datatype_info}{fields}{$field}{sort_column};
			}

			# also, is this field a numeric type?  determines the type of sort to do below (no sense to do both)
			if ($self->{datatype_info}{fields}{$field}{field_type} =~ /decimal|integer/) { # yes
				$numeric_sort = 1;
			} else {
				$numeric_sort = 0;
			}
		}

		# which direction?
		if (!$direction || $direction =~ /up|asc/i) {
			$first_key = '$a';
			$second_key = '$b';
		} else { # descending / down
			$first_key = '$b';
			$second_key = '$a';
		}

		# let's make an array of logic; first numeric sort then fall back to alphabetic
		if ($numeric_sort) { # sort numerically
			push(@sort_logics,'$self->{'.$which.'}{'.$first_key.'}{'.$sort_column.'} <=> $self->{'.$which.'}{'.$second_key.'}{'.$sort_column.'}');
		} else { # otherwise alphabetically
			push(@sort_logics,'$self->{'.$which.'}{'.$first_key.'}{'.$sort_column.'} cmp $self->{'.$which.'}{'.$second_key.'}{'.$sort_column.'}');
		}
	}

	# put that together
	$sort_logic_string = join(' || ',@sort_logics);

	# and make our sorting subroutine
	$sorter = sub {
		eval $sort_logic_string;
	};

	# now sort these records
	@{$self->{records_keys}} = sort $sorter keys %{$self->{records}};
}

1;
