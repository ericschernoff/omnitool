package omnitool::omniclass::searcher;

=cut

Provides the search() functions method as described in omniclass.pm's notes.

Takes a associated-array set of search criteria and comes up with a list of
matching data_codes for a datatype.

This does not create some fancy mega-join or otherwise long SQL, but rather
goes through simple (faster) SELECT statements, one-by-one, and then builds an
intersect list; to properly match, the matched records' keys must be
present in each found results list.

=cut

# for testing if something is a number
use Scalar::Util qw(looks_like_number);

$omnitool::omniclass::searcher::VERSION = '1.0';
# kind of the first time we had something like this

# time to grow up
use strict;

# kick off the routine to find our data!
sub search {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;
	my (@table_keys, $key, $foreign_results, $did, $primary_table, $actual_queries_run, $sql_statement_logic, $table_key, $sql_query_plans, $actual_results, $search_result, $limit_count, @match_values, $question_marks, $args_ref, @bind_values, $math_operator_list, $operator_list, $r, $results, $search_count, $so, %found, $dt,$order_by, $conjunction);

	# for this method, we want to save the search_options and other arguments so that search()
	# could be called again with no arguments and execute the same search

	# so if there is nothing in the %args, try to use the prior search arguments first
	if (!%args) {
		%args = %{$self->{prior_search_args}};
	}

	# fail if no search params sent
	if (!$args{search_options}[0]) {
		# how about a useful message?
		$self->work_history(0,qq{Could not search.},
			qq{No search criteria/options sent.  Please define at least one search option.}
		);
		return;
	}

	# save arguments for possible use in next run-thru
	$self->{prior_search_args} = \%args;

	# need another reference to args hash for the hooks
	$args_ref = \%args;

	# if they want the pre_search hook, let's run it here
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('pre_search')) {
		$self->pre_search($args_ref);

		# we might choose to cancel the search in the pre_search hook; if you want to do that, fill '$$args{cancel_search}'
		if ($args{cancel_search}) {
			# how about a useful message?
			$self->work_history(0,qq{Search was canceled.},
				qq{Canceled within 'pre_search' hook.}
			);
			return;
		}

	}

	# for testing valid operator choices below
	$operator_list = '=,!=,<,>,>=,<=,like,not like,regexp,not regexp,in,not in,between';
	$math_operator_list = '=,!=,<,>,>=,<=,between';

	# start cycling through & keep count of each search preformed
	$search_count = 0; # will need this to make sure we only return records which are found in each search
	foreach $so (@{$args{search_options}}) {
		# bonus feature:  allow them to pass the 'match_column' and 'match_value' as
		# 'column_name' => 'some_value' to make the very simple searches really easy
		if (!$$so{match_column}) {
			foreach $key (keys %$so) {
				next if $self->{belt}->really_in_list($key, 'database_name,table_name,relationship_column,primary_table_column,match_column,match_value,operator,additonal_logic,additional_logic');
				next if !$$so{$key};

				$$so{match_column} = $key;
				$$so{match_value} = $$so{$key};
			}
		}

		# skip if they did not provide a match_value
		next if !length($$so{match_value}); # can be '0'

		# figure out our defaults
		# default to object's database & table, unless a DB is set
		$$so{database_name} ||= $self->{database_name};
		$$so{table_name} ||= $self->{table_name};

		# need a clean set of bin_values
		@bind_values = ();

		# if the table is not the object's default table, figure out the relationship column
		if ($$so{table_name} ne $self->{table_name}) {

			if ($$so{table_name} =~ /metainfo/ && !$$so{relationship_column}) {
				$$so{relationship_column} = 'data_code';
				# also, only query metainfo records relating to this type
				$$so{extra_logic} = 'the_type=? and';
				push(@bind_values,$self->{dt});
			}

			# if just blank, default to 'parent' and hope we are right
			$$so{relationship_column} ||= 'parent';

			# any query against 'parent' must start with this dt id
			if ($$so{relationship_column} eq 'parent') {
				$$so{extra_logic} = 'parent like ? and ';
				push(@bind_values,$self->{dt}.':%');
				# note: you wouldn't pull the parent from metainfo, so the above 'extra_logic' is not needed here

				# fix the primary relationship column to match parent
				$$so{primary_table_column} ||= "concat('".$self->{dt}.":',code,'_',server_id)";

			# translate 'data_code' to it's true meaning (but not for metainfo)
			} elsif ($$so{relationship_column} eq 'data_code' && $$so{table_name} !~ /metainfo/) {
				$$so{relationship_column} = qq{concat(code,'_',server_id)};
			}

		} else { # my table, will be the primary key
			$$so{relationship_column} = qq{concat(code,'_',server_id)};
		}

		# no match column? default to 'name'
		$$so{match_column} ||= 'name';

		# make sure the operator is lowercase to match our list
		$$so{operator} = lc($$so{operator});

		# no operator or invalid operator? default to '='
		if (!$$so{operator} || !($self->{belt}->really_in_list($$so{operator},$operator_list))) {
			$$so{operator} = '=';
		}

		# it may be that pre_search_execute() is trying to force us to use a value
		# this would allow the menu to show the proper option even though the match-value is oddball
		if ($$so{real_match_value}) {
			$$so{match_value} = $$so{real_match_value};
		}

		# if the operator is one of the "like's", we wrap in %'s and single-quotes
		if ($$so{operator} =~ /like/) {
			$$so{match_value} = "%".$$so{match_value}."%";
		}

		# IN/NOT-IN lists are tricky
		if ($$so{operator} =~ /in/) {
			# is it already an array or a comma_list?
			if (ref($$so{match_value}) eq 'ARRAY' && $$so{match_value}[0]) { # in array
				@match_values = @{$$so{match_value}};
			} elsif (ref($$so{match_value}) ne 'ARRAY') { # break it up
				(@match_values) = split /\,/, $$so{match_value};
			}

			# get the question marks
			$question_marks = $self->{belt}->q_mark_list(scalar(@match_values));

			# put it together
			$$so{main_logic} = $$so{match_column}.' '.$$so{operator}.' ('.$question_marks.')';
			push(@bind_values,@match_values);

		# 'between' is for date ranges
		} elsif ($$so{operator} eq 'between') {
			(@match_values) = split /---/, $$so{match_value};

			$$so{main_logic} = $$so{match_column}.' '.$$so{operator}.' ? and ?';
			push(@bind_values,@match_values);


		# did they send an array (useful for 'additional_logic')
		} elsif (ref($$so{match_value}) eq 'ARRAY') { # in array
			$$so{main_logic} = $$so{match_column}.' '.$$so{operator}.' ?';
			push(@bind_values,@{$$so{match_value}});

		# all others are fairly normal, just one value
		} else {
			$$so{main_logic} = $$so{match_column}.' '.$$so{operator}.' ?';
			push(@bind_values,$$so{match_value});
		}

		# i had an embarrassing typo before
		$$so{additional_logic} = $$so{additonal_logic} if $$so{additonal_logic};

		# we are going to run one SQL query per database/table combo, so make a plan to put them together
		$table_key = $$so{database_name}.'.'.$$so{table_name};
		$$sql_query_plans{$table_key}{relationship_column} = $$so{relationship_column};
		$$sql_query_plans{$table_key}{primary_table_column} ||= $$so{primary_table_column};
		push (
			@{ $$sql_query_plans{$table_key}{query_logic} },
			qq{ ( $$so{extra_logic} ( $$so{main_logic} $$so{additional_logic} ) )}
		);
		push (
			@{ $$sql_query_plans{$table_key}{bind_values} },
			@bind_values
		);

		# make sure to pass $$so{match_value} as a placeholder
		# also note that the $$so{additional_logic} bit would be passed as an arg to this method and probably
		# generated in your datatype-specific class --> MAKE SURE IT IS SECURE; resolve down to ID's first and pass those

		# track the searches specified
		$search_count++;
	}

	# fail if no searches were done because no 'match_value' bits were set
	if ($search_count == 0) {
		# how about a useful message?
		$self->work_history(0,qq{Could not search.},
			qq{None of the search criteria/options had values for 'match_value'.}
		);
		# reset any previous search results
		$self->{search_results} = [];
		$self->{search_found_count} = 0;

		# done
		return;
	}

	# if we got this far, try to run the combined SQL queries on the target tables
	$primary_table = $self->{database_name}.'.'.$self->{table_name}; # for testing if a query is on the primary table
	$actual_queries_run = 0;
	@table_keys = keys %$sql_query_plans;
	foreach $table_key (@table_keys, $primary_table) {

		# only do the primary_table once, so the $$sql_query_plans{$table_key}{primary_table_column} test
		# can be run below
		$$did{$table_key}++;
		next if $table_key eq $primary_table && $$did{$primary_table} < 2;

		# if we are on the primary table, allow for a 'match-any' attitude
		if ($args{match_any} && $table_key eq $primary_table) {
			$conjunction = ' or ';
		} else { # otherwise, has to be and (match-all)
			$conjunction = ' and ';
		}

		# combine the SQL logic for this targeted table
		$sql_statement_logic = join( $conjunction , @{ $$sql_query_plans{$table_key}{query_logic} } );

		# alright, let's build a nice sql statement & run it too
		# use ()'s for the primary logic and include $$so{additional_logic} in those, as it may be an 'or' value

		$results = $self->{db}->list_select(
			'select '.$$sql_query_plans{$table_key}{relationship_column}.' from '.$table_key.
			' where '.$sql_statement_logic,
			$$sql_query_plans{$table_key}{bind_values}
		);

		# log the search if they asked us to (99% for debug purposes)
		# will log into the 'USERNAME_searches' log file
		if ($args{log_search}) {
			$self->{belt}->logger(
				'select '.$$sql_query_plans{$table_key}{relationship_column}.' from '.$table_key.
				' where '.$sql_statement_logic, $self->{luggage}{username}.'_searches'
			);
			$self->{belt}->logger(
				$$sql_query_plans{$table_key}{bind_values}, $self->{luggage}{username}.'_searches'
			);
		}

		# if we are using a second/foreign table then the 'primary_table_column' tells us how to relate 
		# the results we just found to our datatype's table.
		if ($table_key ne $primary_table && $$sql_query_plans{$table_key}{primary_table_column}) {
			# fail the query if nothing was matched
			$$results[0] ||= 'Ginger_Polly';

			# we need the number of question marks of the results found in this query
			$question_marks = $self->{belt}->q_mark_list(scalar(@$results));

			# okay, so we will pull these into the primary table query, which will run last.
			# Load this into the query plan for that primary table
			$$sql_query_plans{$primary_table}{relationship_column} = qq{concat(code,'_',server_id)};
			push (
				@{ $$sql_query_plans{$primary_table}{query_logic} },
				qq{ $$sql_query_plans{$table_key}{primary_table_column} in ($question_marks) }
			);
			push (
				@{ $$sql_query_plans{$primary_table}{bind_values} },
				@$results
			);

			# now do not add these @$results
			next;
		}

		# make sure the list is unique, since relationship tables can find multiple matches for the same record
		$results = $self->{belt}->uniquify_list($results);

		# for determining the records which match each query
		foreach $r (@$results) {
			if ($$sql_query_plans{$table_key}{relationship_column} eq 'parent') { # remove dt id prefix
				($dt,$r) = split /:/, $r;
			}

			$found{$r}++;
		}

		# track how many queries we ran
		$actual_queries_run++;
	}

	# now, get the records which came up in all the searches / actual_queries_run
	@{$self->{search_results}} = grep { $found{$_} == $actual_queries_run } keys %found;
	$self->{search_found_count} = scalar @{$self->{search_results}};
	if (!$self->{search_found_count}) { # make sure it's an arrayref at least
		$self->{search_results} = [];
	}

	# if they passed in an 'order_by' clause, we need to re-sort the keys for that logic
	if ($args{order_by} && $self->{search_found_count}) {
		$order_by = $args{order_by};
		$order_by = 'order by '.$order_by if $order_by !~ /order by/i;
		# if they passed in 'limit_results', we have to honor that here or it will not work
		# (or at least, i'd have to write a lot more perl
		if ($args{limit_results}) {
			$args{limit_results} = int($args{limit_results});
			$order_by .= ' limit '.$args{limit_results};
			$args{limit_results_done} = 1; # for to skip below and save 0.0000001 of a second.
		}

		# now run the query to get them sorted
		$question_marks = $self->{belt}->q_mark_list($self->{search_found_count});
		$self->{search_results} = $self->{db}->list_select(
			qq{select concat(code,'_',server_id) from }.$primary_table.
			qq{ where concat(code,'_',server_id) in ($question_marks) }.$order_by,
			$self->{search_results}
		);

		# if they limited the results below what was actually found, then 
		# be sure to adjust search_found_count
		$self->{search_found_count} = scalar @{$self->{search_results}};

	}

	# if they want the post_search hook, let's run it here
	if (!$self->{skip_hooks} && !$args{skip_hooks} && $self->can('post_search')) {
		$self->post_search($args_ref);
	}

	# if they passed in a limit number, honor that
	if ($args{limit_results} && !$args{limit_results_done} && $self->{search_found_count} > $args{limit_results}) {
		$args{limit_results} = int($args{limit_results}); # no decimels allowed
		$self->{search_found_count} = $args{limit_results};
		# @{$self->{search_results}} = $self->{search_results}[0..($args{limit_results}-1)];
		$limit_count = 0;
		foreach $search_result (@{$self->{search_results}}) {
			push(@$actual_results,$search_result);
			$limit_count++;
			last if $limit_count == $args{limit_results};
		}
		$self->{search_results} = $actual_results;
	}

	# $self->{belt}->benchmarker('OmniClass Search Run for '.$self->{table_name});

	# OK, do they want to auto-load the search results
	if ($args{auto_load} || $args{simple_query_mode}) { # yep, proceed
		$self->load(
			'data_codes' => $self->{search_results},
			'do_clear' => $args{do_clear},
			'skip_hooks' => $args{skip_hooks},
			'sort_column' => $args{sort_column},
			'sort_direction' => $args{sort_direction},
			'complex_sorting' => $args{complex_sorting},
			'skip_metainfo' => $args{skip_metainfo},
			'load_fields' => $args{load_fields},
			'simple_query_mode' => $args{simple_query_mode},
		);
		$args{already_loaded} = 1; # for below

		# $self->{belt}->benchmarker('OmniClass AutoLoad Done for '.$self->{table_name});
	}

	# and/or would they rather set up a resolver hash
	if ($args{resolver_hash_field}) { # yep, proceed
		$self->create_resolver_hash(
			'data_codes' => $self->{search_results},
			'field_name' => $args{resolver_hash_field},
			'already_loaded' => $args{already_loaded},
		);
	}

	# note that we were successful
	$self->work_history(1,qq{Successfully executed search.},
		"$search_count search criteria matched.\n".$self->{search_found_count}." records matched."
	);

	# all done
}

# utility method to allow you to find records which are duplicate based on one or more fields
# i.e. find all staff with the same birthdate or find the id's of the staff records of the same name
sub find_duplicates {
	my $self = shift;

	my (%args) = @_;
	# looks like:
	#	'fields_to_test' => $fields_to_test, # require; a string with one or more fields, i.e. 'birthdate' or 'first_name,last_name'
	#	'minimum_duplicates' => 2, # (optional) the minimum number of duplicates to count; default is 2
	#	'extra_sql_logic' => $some_sql_logic, # (optional) extra SQL logic to add to the query
	#	'extra_sql_logic_bind_values' => $arrayref, # (optional) bind values to go with 'extra_sql_logic

	# return error without $field_to_test
	return 'ERROR: $args{fields_to_test} is required for find_duplicates()' if !$args{fields_to_test};

	# default to minimum_duplicates to 2
	$args{minimum_duplicates} = 2 if $args{minimum_duplicates} !~ /\d/ || $args{minimum_duplicates} < 2;

	# if there are multiple fields, need to wrap in concat()
	if ($args{fields_to_test} =~ /\,/) {
		$args{fields_to_test} = 'concat('.$args{fields_to_test}.')';
	}

	# make sure the sql logic has a 'where' in it
	$args{extra_sql_logic} = 'where ' if $args{extra_sql_logic} && $args{extra_sql_logic} !~ /^\s*where/;

	# now find the numbers of duplicates and the record keys, by duplicated value
	my ($duplicate_records,$duplicate_records_keys) = $self->{db}->sql_hash(qq{
		select $args{fields_to_test}, group_concat(concat(code,'_',server_id)), count(*) as num from }.
		$self->{database_name}.'.'.$self->{table_name}.
		qq{
			$args{extra_sql_logic}
			group by $args{fields_to_test} having num >= $args{minimum_duplicates}
	},(
		'names' => ['records_keys','count'],
		'bind_values' => $args{extra_sql_logic_bind_values}
	));

	# send out those results
	return ($duplicate_records,$duplicate_records_keys);
}

# utility method to reduce typing for simple searches, which are those where
# all the match_column's are in the primary table and all the operator's are =
# send a hash of match_column=>match_value pairs and it will run the bigger search() for yo
# also include 'auto_load' => 1 in your hash to auto-load the results; use search() if you
# need anything fancier
sub simple_search {
	my $self = shift;
	
	my (%args) = @_;
	
	# fail of they did not send a hash
	if (ref(\%args) ne 'HASH') {
		$self->{search_found_count} = 0;
		$self->{search_results} = [];
		return;
	}
	
	# otherwise, continue
	my ($search_options, $match_column);
	
	# build out our 'search_options' arrays
	foreach $match_column (keys %args) {
		next if $match_column eq 'auto_load' || !$args{$match_column};
		push(@$search_options,{
			$match_column => $args{$match_column}
		});
	}
	
	# fail if they did not send at least one good search
	if (!$$search_options[0]) {
		$self->{search_found_count} = 0;
		$self->{search_results} = [];
		return;	
	}
	
	# now run the search
	$self->search(
		'search_options' => $search_options,
		'auto_load' => $args{auto_load}
	);
	
	# phew! what a long bit of code to write.  time for a break.

}

1;
