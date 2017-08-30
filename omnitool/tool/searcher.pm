package omnitool::tool::searcher;
# provides the method to commit searches via omniclass's search() method
# basically powers the 'Search' Tools

# another one which feels like 1,000.0
$omnitool::tool::searcher::VERSION = '6.0';

# put your big kid shoes on
use strict;

# for keyword searching against whole hashes
use Data::Dumper;

# for wide-search warning errors
use Lingua::EN::Numbers qw(num2en num2en_ordinal);

sub search {
	my $self = shift;

	# declare vars
	my ($dt_obj, $search_opts_key, $target_datatype, $tool_datacode, $tool_mode_id, $include_fields, $advanced_sort_options, $display_option);

	# target our target datatype
	$self->{target_datatype} = $self->{attributes}{target_datatype};

	# the omniclass object was already grabbed in our caller,
	# send_json_data(), but just in case
	if (!$self->{omniclass_object}->{table_name}) {
		# this is up in center_stage.pm
		$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
	}

	# trim leading/trailing spaces from the quick_search keyword
	$self->{display_options}{quick_keyword} =~ s/^\s+|\s+$//g;

	# if a keyword is required but not provided, throw an error
	if (!$self->{display_options}{quick_keyword} && $self->{attributes}{require_quick_search_keyword} eq 'Yes') {
		$self->{json_results} = {
			'error_message' => 'Keyword is Required for this Search.  Please Enter Above.',
			'datatype_name' => $self->{omniclass_object}{datatype_info}{name},
		};
		return;

	}

	# let's allow for a pre_search_build() hook; for modifying filters or adding special logic
	if ($self->can('pre_search_build')) {
		$self->pre_search_build();
	}

	# need to construct our search
	$self->build_search();

	# let's allow for a pre_search_build() hook; for further modifying search criteria
	if ($self->can('pre_search_execute')) {
		$self->pre_search_execute();
	}

	# if at least one search choice is required and none is chosen, throw an error (detected in build_search())
	if ($self->{wide_search_blocked}) {
		# use Lingua::EN::Numbers to pretty up the numbers

		# pluralize the word 'choice'?
		my $choice_word;
		if ($self->{attributes}{menus_required_for_search} == 1) {
			$choice_word = 'choice';
		} else {
			$choice_word = 'choices';
		}

		# let them append this in pre_search()
		$choice_word .= $self->{custom_search_error} if $self->{custom_search_error};

		$self->{json_results} = {
			'error_message' => 'This search requires at least '.
				num2en( $self->{attributes}{menus_required_for_search} ).
				' menu/keyword '.$choice_word.".\nPlease adjust search above.",
			'datatype_name' => $self->{omniclass_object}{datatype_info}{name},
		};
		return;
	}

	# choose our sorting field/key and direction
	# if none sent, choose the defaults for the this Tool View Mode
	if (!$self->{display_options}{sort_column}) {
		$tool_mode_id = $self->{display_options}{tool_mode};
		$self->{display_options}{sort_column} = $self->{tool_configs}{tool_mode_configs}{$tool_mode_id}{default_sort_column};
		$self->{display_options}{sort_direction} = $self->{tool_configs}{tool_mode_configs}{$tool_mode_id}{default_sort_direction};
	}

	# finally, run the search
	$self->{omniclass_object}->search(
		# 'log_search' => 1,
		'search_options' => $self->{searches},
		'auto_load' => 1,
		'sort_column' => $self->{display_options}{sort_column},
		'sort_direction' => $self->{display_options}{sort_direction},
		'limit_results' => 500, # hard limit to prevent memory issues
	);
	
	# debug code
	# $self->{belt}->benchmarker('Search run');
	# $self->{belt}->logger($self->{searches},'eric');

	# if they want tree-mode, give it to them
	if ($self->{omniclass_object}->{search_found_count} && $self->{attributes}{load_trees} eq 'Yes') {
		$self->{luggage}{object_factory}->omniclass_tree($self->{omniclass_object});
	}

	# if they specified a global keyword, apply it here, to the already built data
	# so hopefully our search is tight and we do not have too many results
	if ($self->{display_options}{quick_keyword}) {
		# use method below, which will remove the records from omniclass_object which do not match
		$self->quick_search_keyword_match();
	}

	# are we using advanced sorting?
	# try to find them
	foreach $display_option (sort { $a cmp $b } keys %{ $self->{display_options} }) {
		next if $display_option !~ /advanced_sort_/ || $self->{display_options}{$display_option} eq '-' || $self->{display_options}{$display_option} eq 'none'; # skip blanks
		push(@$advanced_sort_options, $self->{display_options}{$display_option});
	}
	if ($$advanced_sort_options[0]) { # found at least one; do the complex search
		$self->{omniclass_object}->complex_sort($advanced_sort_options);
	}

	# does this view want us to limit results?
	if ($self->{tool_configs}{tool_mode_configs}{$tool_mode_id}{max_results} ne 'No Max') {
		$self->limit_results( $self->{tool_configs}{tool_mode_configs}{$tool_mode_id}{max_results} );
	}

	# if there are record coloring rules, evaluate them
	if ($self->{tool_configs_keys}{record_coloring_rules}[0]) {
		$self->record_coloring_rules(); # use method below, which will add a 'record_color' entry to the metainfo sub-hash
	}

	# get the inline actions, if some results were found
	if ($self->{omniclass_object}->{search_found_count}) {
		$self->get_inline_actions();
	}

	# let's allow for a post_search_execute() hook; for modifying the records list
	if ($self->can('post_search_execute')) {
		$self->post_search_execute();
	}

	# method below to get subordinate/inline actions and add them to $self->{omniclass_object}->{records}{actions}[]

	# we will want the list of altcodes
	$self->{omniclass_object}->get_altcodes_keys();

	# we utilzie those altcodes on the front-end for the subordinate action tools' prev/next buttons
	# let's also stash them in this tool's display options so we can have batch-operator tools which
	# act on our search results
	$self->{display_options}{altcodes_keys} = $self->{omniclass_object}{altcodes_keys};

	# finally, convert that to a very nice hashref for sending out as JSON via mr_zebra()
	# pass $self->{attributes}{load_trees} in as a instruction to be recursive or not
	$self->{json_results} = $self->{luggage}{object_factory}->omniclass_data_extractor($self->{omniclass_object},{},$self->{attributes}{load_trees});

	# need the datatype's name for the jemplate, in case thereare no results
	$self->{json_results}{datatype_name} = $self->{omniclass_object}{datatype_info}{name};

	# tell the template if inline actions where found
	$self->{json_results}{found_inline_actions} = $self->{found_inline_actions};

	# provide the search column / direction for JS reference
	$self->{json_results}{sort_column} = $self->{display_options}{sort_column};
	$self->{json_results}{sort_direction} = $self->{display_options}{sort_direction};

	# limit notice?
	if ($self->{limit_notice}) {
		$self->{json_results}{limit_notice} = $self->{limit_notice};
	}

	# report the number of uses of advanced search menus & advanced_sort_options
	$self->{json_results}{advanced_search_filters} = $self->{advanced_search_filters};
	$self->{json_results}{advanced_sort_options} = $advanced_sort_options; # send whole array for setting up arrows

	# to indicate use of either:
	if ($self->{json_results}{advanced_search_filters} || $self->{json_results}{advanced_sort_options}[0]) {
		$self->{json_results}{advanced_features} = 'On';
	}

	# final hook to allow for playing with / adding-to $self->{json_results}
	if ($self->can('json_results_modify')) {
		$self->json_results_modify();
	}
	
}

# if we are refreshing one record in our results list, we may need to load a single, specific result
# works like https://your.omnitool_server.com/tools/tool_base_uri/load_one_record/RECORD_ALTCODE
sub load_one_record {
	my $self = shift;

	# target our target datatype
	$self->{target_datatype} = $self->{attributes}{target_datatype};

	# certain tools may actually override this when loading sub-records under sub-records in ComplexDetails
	# set this in your custom init() method
	if ($self->{target_datatype_for_load_one_record}) {
		$self->{target_datatype} = $self->{target_datatype_for_load_one_record};
	}

	# the omniclass object maybe was already grabbed in our caller, but just in case
	if (!$self->{omniclass_object}->{table_name}) {
		# this is up in center_stage.pm
		$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
	}

	# they are sending the target record's data code via the 'one_data_code' parameter

	# if it found a record, load it up
	if ($self->{display_options}{one_data_code}) {
		$self->{omniclass_object}->load('data_codes' => [ $self->{display_options}{one_data_code} ]);

		# color the record
		$self->record_coloring_rules();
		# and get the inline actions
		$self->get_inline_actions();

		# let's allow for a post_search_execute() hook; for modifying the records list
		if ($self->can('post_search_execute')) {
			$self->post_search_execute();
		}

		# convert to a plain hash
		$self->{json_results} = $self->{luggage}{object_factory}->omniclass_data_extractor($self->{omniclass_object},{},$self->{attributes}{load_trees});

		# tell the template if inline actions where found
		$self->{json_results}{found_inline_actions} = $self->{found_inline_actions};

	# if no record found, throw them an error
	} else {
		$self->{json_results}{error_message} = $self->{display_options}{altcode}.' was not found.';
	}

	# final hook to allow for playing with / adding-to $self->{json_results}
	if ($self->can('json_results_modify')) {
		$self->json_results_modify();
	}

	# add the 'session_created' value
	$self->{json_results}{session_created} = $self->{luggage}{session}->{created};

	# for our post_data_fetch_operations function to work
	$self->{json_results}{the_tool_id} = $self->{tool_and_instance};
	$self->{json_results}{one_record_mode} = 1;

	# sepcial methods require am explicit return
	return $self->{json_results};
}

# method for performing the quick keyword matching &
sub quick_search_keyword_match {
	my $self = shift;
	my ($n, $remove, $record, $kw, $remove_key, @tested_keys);

	$n = 0;
	foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {
		$remove = 0;

		foreach $kw (split /;|&/, $self->{display_options}{quick_keyword}) {
			if ($kw =~ /^\!/) { # 'not' operator
				$kw =~ s/^\!//;
				if (Dumper($self->{omniclass_object}->{records}{$record}) =~ /$kw/i) { # matches, remove element
					$remove = 1;
					last;
				}
			 # 'is' operator: make sure it matches
			} elsif (Dumper($self->{omniclass_object}->{records}{$record}) !~ /$kw/i) {
				$remove = 1;
				last;
			}
		}
		# if it failed a keyword test, take out this record
		if ($remove) {
			delete($self->{omniclass_object}->{records}{$record});
			delete($self->{omniclass_object}->{metainfo}{$record});
			$self->{omniclass_object}->{search_found_count}--;
			# if i were only smarter...
			# $remove_key = splice(@{ $self->{omniclass_object}->{records_keys} },$n,1);
		} else {
			# keep this record in the keys
			push(@tested_keys,$record);
		}
		$n++;
	}

	# the now-good keys set...wish i had gotten split to work
	$self->{omniclass_object}->{records_keys} = \@tested_keys;
}

# method to truncate the results by the view mode's limit, if exists
sub limit_results {
	my $self = shift;
	my ($limit_number) = @_;

	# skip if blank
	return if !$limit_number;

	my ($n, $record, @tested_keys, $search_found_count, $limit_results_formatted);

	# make sure to send a notice back to the UI
	if ($self->{omniclass_object}->{search_found_count} > $limit_number) {
		$search_found_count = $self->{belt}->commaify_number( $self->{omniclass_object}->{search_found_count} );
		$limit_results_formatted = $self->{belt}->commaify_number( $limit_number );

		$self->{limit_notice} = qq{
			Found $search_found_count results but this view is limited to $limit_results_formatted records.
			Please adjust your search as necessary.
		};
	}

	$n = 0;
	foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {
		if ($n >= $limit_number) {
			delete($self->{omniclass_object}->{records}{$record});
			delete($self->{omniclass_object}->{metainfo}{$record});
			$self->{omniclass_object}->{search_found_count}--;
		} else {
			# keep this record in the keys
			push(@tested_keys,$record);
		}
		$n++;
	}
	# the now-good keys set...wish i had gotten split to work
	$self->{omniclass_object}->{records_keys} = \@tested_keys;

}

# method to apply the record coloring rules; will not get here if there are no rules for this tool
sub record_coloring_rules {
	my $self = shift;

	my ($record, $rule, $dtf, $match_col, $match_string);

	# cycle through the records
	foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {
		# go through each rule and stop if one is matched
		foreach $rule (@{ $self->{tool_configs_keys}{record_coloring_rules} }) {
			# sanity
			$dtf = $self->{tool_configs}{record_coloring_rules}{$rule}{match_field};
			$match_col = $self->{luggage}{datatypes}{ $self->{target_datatype} }{fields}{$dtf}{table_column};
			$match_string = $self->{tool_configs}{record_coloring_rules}{$rule}{match_string};

			# skip if that field is blank
			next if !$self->{omniclass_object}->{records}{$record}{$match_col};

			# does-match and actually matches
			if ($self->{tool_configs}{record_coloring_rules}{$rule}{match_type} eq 'Does Match' && $self->{omniclass_object}->{records}{$record}{$match_col} =~ /$match_string/i) {
				$self->{omniclass_object}->{metainfo}{$record}{record_color} = $self->{tool_configs}{record_coloring_rules}{$rule}{apply_color};
				$self->{omniclass_object}->{metainfo}{$record}{record_color_column} = $match_col;
				last; # no need to continue

			# does-not-match and actually doesn't match
			} elsif ($self->{tool_configs}{record_coloring_rules}{$rule}{match_type} eq 'Does Not Match' && $self->{omniclass_object}->{records}{$record}{$match_col} !~ /$match_string/i) {
				$self->{omniclass_object}->{metainfo}{$record}{record_color} = $self->{tool_configs}{record_coloring_rules}{$rule}{apply_color};
				$self->{omniclass_object}->{metainfo}{$record}{record_color_column} = $match_col;
				last; # no need to continue
			}
		}
	}

}


# method for putting the in-line actions under $self->{omniclass_object}->{records}{actions}[]
sub get_inline_actions {
	my $self = shift;

	my ($this_record_id, $this_match, $record, $tool_datacode, $child_tool_key, $match_col, $lock_user,$lock_remaining_minutes, $parent_tool_datatype, $parent_tool_datacode, $actions_found_count);

	# in 99.9% of cases, the inline actions are Action Tools linked directly below the current tool...
	$tool_datacode = $self->{tool_datacode};

	# but 'Action - Screen' tools can actually use their parent search's inline actions.
	if ($self->{attributes}{share_parent_inline_action_tools} eq 'Yes' && $self->{attributes}{tool_type} eq 'Action - Screen') {

		($parent_tool_datacode = $self->{luggage}{session}{tools}{$tool_datacode}{parent}) =~ s/8_1://;

		# dig out the target datatype of that parent tool from the session; i am sorry for how complex this ios
		$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_tool_datacode}{target_datatype};

		# the parent's datatype must be the same as the current tool's datatype
		if ($parent_tool_datatype eq $self->{attributes}{target_datatype}) {
			# safe to use the parent's inline actions
			$tool_datacode = $parent_tool_datacode;
		}
	}

	# if all those tests fail, we shall just stick with  $self->{tool_datacode};

	# go through each found record and try to add the inline tools
	# starting with the record on the outside so we can check the locks right before figuring these tools
	foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {

		# check to see if this data is locked; may get slow for large data sets, but we can optimize later
		($lock_user,$lock_remaining_minutes) = $self->{omniclass_object}->check_data_lock($record);

		# if it's locked, we shall tell the jemplate
		if ($lock_user) {
			$self->{omniclass_object}->{metainfo}{$record}{lock_user} = $lock_user;
			$self->{omniclass_object}->{metainfo}{$record}{lock_remaining_minutes} = $lock_remaining_minutes;
		}

		# now cycle through the inline tools under this tool
		foreach $child_tool_key (@{ $self->{luggage}{session}{tools}{$tool_datacode}{child_tools_keys} }) {
			next if $self->{luggage}{session}{tools}{$child_tool_key}{link_type} ne 'Inline / Data Row';

			# test if they have defined a 'link_match_string' / 'link_match_field'
			if ($self->{luggage}{session}{tools}{$child_tool_key}{link_match_string} && $self->{luggage}{session}{tools}{$child_tool_key}{link_match_field}) {
				# resolve down the $match_col for sanity; two-step process
				$match_col = $self->{luggage}{session}{tools}{$child_tool_key}{link_match_field};
					$match_col = $self->{omniclass_object}->{datatype_info}{fields}{$match_col}{table_column};

				# do the match - positive or negative
				if ($self->{luggage}{session}{tools}{$child_tool_key}{link_match_string} =~ /^\!/) { # negative match
					($this_match = $self->{luggage}{session}{tools}{$child_tool_key}{link_match_string}) =~ s/^\!//;
					next if Dumper($self->{omniclass_object}->{records}{$record}{$match_col}) =~ /$this_match/i;
				} else { # positive match
					next if Dumper($self->{omniclass_object}->{records}{$record}{$match_col}) !~ /$self->{luggage}{session}{tools}{$child_tool_key}{link_match_string}/i;
				}
			}

			# if this is a locking action, do not allow it if someone else has it locked
			next if $self->{luggage}{session}{tools}{$child_tool_key}{is_locking} eq 'Yes' && $lock_user;

			# so we can only use altcodes if they can be trusted to be unique, which is controlled by the 'Altcodes are Unique'
			# setting for the datatype.  We *want* to use altcodes for friendlier URIs, and we will in 99% of situations
			if ($self->{omniclass_object}->{datatype_info}{altcodes_are_unique} eq 'No') { # only the data_codes are safe
				$this_record_id = $record;

			# otherwise, use the altcode
			} else {
				$this_record_id = $self->{omniclass_object}->{metainfo}{$record}{altcode};
			}

			# add it in without any further delay
			push(@{ $self->{omniclass_object}->{records}{$record}{inline_actions} }, {
				'key' => $child_tool_key,
				'button_name' => $self->{luggage}{session}{tools}{$child_tool_key}{button_name},
				'icon_fa_glyph' => $self->{luggage}{session}{tools}{$child_tool_key}{icon_fa_glyph}, # from font-awesome glyphs
				'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$child_tool_key}{uri_path_base}.'/'.$this_record_id,
			});

			# if it's the current tool, which happens when we are showing the parent tool's inline actions,
			# then tell the jemplate to just refresh the data on click
			if ($child_tool_key eq $self->{tool_datacode}) {
				$self->{omniclass_object}->{records}{$record}{inline_actions}[-1]{refresh_link} = 1;
			}

			# note that there are some inline-actions for the template
			$self->{found_inline_actions} = 1 if !$self->{found_inline_actions};
		}
		
		# keep track of the maximum number of inline actions for records in this tool
		$actions_found_count = scalar(@{ $self->{omniclass_object}->{records}{$record}{inline_actions} });
		$self->{max_actions_per_record} = $actions_found_count if $self->{max_actions_per_record} < $actions_found_count;
		# this is used in Table.tt to determine what type of action menu to show

		# set the first inline tool's uri as the 'default' tool uri for this record
		$self->{omniclass_object}->{records}{$record}{default_inline_tool} = $self->{omniclass_object}->{records}{$record}{inline_actions}[0]{uri};

	}
}


# here is the method where we will interpret our search/filter menus to build our search_options
# array for omniclass->search()
# NOTE: The standard Tool Filter Menu can only test against one column, which the value coming from
# the menu selection.  If you need to test a different DB column based on a menu selection, then
# please set up a pre_search_execute() hook to tinker with the search criteria after this method runs
sub build_search {
	my $self = shift;

	my ($parent_string, $filter_menu, $keyword_key, $parent_datacode, $tool_datacode, $parent_tool_datatype, $keyword_operator_key, $n, $searches, $this_tool_filter_menu, $value_key, @apply_to_table_col_parts, @searches, $start_key, $end_key);

	# go through each filter menu
	$n = 0;
	foreach $filter_menu ( @{ $self->{tool_configs_keys}{tool_filter_menus} }) {

		# shorten our hashref variable for sanity here
		$this_tool_filter_menu = $self->{tool_configs}{tool_filter_menus}{$filter_menu};

		# the possible value / display_options keys for the menu
		$value_key = 'menu_'.$filter_menu;
		# for keyword menus
		$keyword_key = 'keyword_'.$filter_menu;
		$keyword_operator_key = 'keyword_operator_'.$filter_menu;
		# for date range menus
		$start_key = 'start_'.$filter_menu;
		$end_key = 'end_'.$filter_menu;

		# if it's 'Any', skip and don't search
		next if $self->{display_options}{$value_key} eq 'Any' && $$this_tool_filter_menu{menu_type} ne 'Date Range';

		# we need to tie the searches to the menus for possible doctoring in pre_search_execute()
		$$this_tool_filter_menu{which_search} = $n;

		# keyword menus let you select the field-to-match with the menu and specify a keyword
		# only use if sent both a selected field and a keyword value
		if ($$this_tool_filter_menu{menu_type} eq 'Keyword' && $self->{display_options}{$value_key} && $self->{display_options}{$keyword_key} && $self->{display_options}{$value_key} ne 'Skip') {

			$$searches[$n]{match_column} = $self->{display_options}{$value_key};

			$$searches[$n]{match_value} = $self->{display_options}{$keyword_key};

			# positive or negative match?
			if ( $self->{display_options}{$keyword_operator_key} =~ /not/i) {
				$$searches[$n]{operator} = 'not regexp';
			} else {
				$$searches[$n]{operator} = 'regexp';
			}
			# note that these are all regular expressions

			if ($$this_tool_filter_menu{matches_relate_to_tool_dt} ne 'Direct') {
				$$searches[$n]{relationship_column} = $$this_tool_filter_menu{matches_relate_to_tool_dt};
			}

		# date ranges are also kind of fun
		} elsif ($$this_tool_filter_menu{menu_type} eq 'Date Range' && $self->{display_options}{$start_key} && $self->{display_options}{$end_key}) {
			# for omniclass::searcher()
			$$searches[$n]{operator} = 'between';

			# omniclass::searcher() will break this up
			$$searches[$n]{match_value} = $self->{display_options}{$start_key}.'---'.$self->{display_options}{$end_key};

			# where to match and relationship
			$$searches[$n]{match_column} = $$this_tool_filter_menu{applies_to_table_column};
			if ($$this_tool_filter_menu{matches_relate_to_tool_dt} ne 'Direct') {
				$$searches[$n]{relationship_column} = $$this_tool_filter_menu{matches_relate_to_tool_dt};
			}

		# month-chooser?  have to adjust the 'match_column' based on the target column's name
		} elsif ($self->{display_options}{$value_key} && $$this_tool_filter_menu{menu_type} eq 'Month Chooser') {
			
			if ($$this_tool_filter_menu{applies_to_table_column} =~ /date/) { # YYYY-MM-DD date
				$$searches[$n]{match_column} = 'date_format('.$$this_tool_filter_menu{applies_to_table_column}.qq{,'%M %Y')};
			} else { # going to be a unix epoch
				$$searches[$n]{match_column} = 'from_unixtime('.$$this_tool_filter_menu{applies_to_table_column}.qq{,'%M %Y')};
			}
			
			# can only be = or != operators for this
			if ($$searches[$n]{operator} ne '=' && $$searches[$n]{operator} ne '!=') {
				$$searches[$n]{operator} = '=';
			}
			
			# going to need this
			$$searches[$n]{match_value} = $self->{display_options}{$value_key};

			if ($$this_tool_filter_menu{matches_relate_to_tool_dt} ne 'Direct') {
				$$searches[$n]{relationship_column} = $$this_tool_filter_menu{matches_relate_to_tool_dt};
			}


		# maybe just a regular menu?  proceed if there is a value
		} elsif ($self->{display_options}{$value_key} && $$this_tool_filter_menu{menu_type} =~ /Select|Keyword Tags/) {

			# multi-selects should work the same, except their operator must be 'in' or 'not in'
			if ($$this_tool_filter_menu{menu_type} eq 'Multi-Select' && $self->{display_options}{$value_key}) {
				# it needs to be IN or NOT IN
				if ($$this_tool_filter_menu{search_operator} !~ /in/i) {
					$$searches[$n]{operator} = 'in';
				} else {
					$$searches[$n]{operator} = $$this_tool_filter_menu{search_operator};
				}

				# make it an INable list
				$$searches[$n]{match_value} = $self->{display_options}{$value_key};

			# key word tags are always 'in'
			} elsif ($$this_tool_filter_menu{menu_type} eq 'Keyword Tags' && $self->{display_options}{$value_key}) {
				$$searches[$n]{operator} = 'in';
				$$searches[$n]{match_value} = $self->{display_options}{$value_key};

			} else { # single select can be any operator
				$$searches[$n]{operator} = $$this_tool_filter_menu{search_operator};
				# value is just the option value
				$$searches[$n]{match_value} = $self->{display_options}{$value_key};
			}

			# no special gymnastics to assign these values
			$$searches[$n]{match_column} = $$this_tool_filter_menu{applies_to_table_column};

			if ($$this_tool_filter_menu{matches_relate_to_tool_dt} ne 'Direct') {
				$$searches[$n]{relationship_column} = $$this_tool_filter_menu{matches_relate_to_tool_dt};
			}
		}

		# if we have a value, three more quick tasks
		if ($$searches[$n]{match_value}) {
			# figure 'applies_to_table_column' into the DB, table, and relationship_column
			(@apply_to_table_col_parts) = split /\./, $$this_tool_filter_menu{matches_relate_to_tool_dt};
			if ($apply_to_table_col_parts[2]) { # has DB + table + column
				$$searches[$n]{database_name} = $apply_to_table_col_parts[0];
				$$searches[$n]{table_name} = $apply_to_table_col_parts[1];
				$$searches[$n]{relationship_column} = $apply_to_table_col_parts[2];

			} elsif ($apply_to_table_col_parts[1]) { # just table + column
				$$searches[$n]{table_name} = $apply_to_table_col_parts[0];
				$$searches[$n]{relationship_column} = $apply_to_table_col_parts[1];

			} elsif ($apply_to_table_col_parts[0]) { # will be column only
				$$searches[$n]{relationship_column} = $apply_to_table_col_parts[0];

			}

			# we need to track the number of advanced search menus which we are using
			# to report via $self->{json_results}{advanced_search_filters} and use in the JS/UI
			if ($$this_tool_filter_menu{display_area} eq 'Advanced Search') {
				$self->{advanced_search_filters}++;
			}

			# advance for the array
			$n++;
		}

	}

	# if we have a $self->{display_options}{altcode} then we need to search based on parentage
	if ($self->{display_options}{altcode}) {
		# need my parent tool's datatype to properly figure out the parent_string from the 'altcode' display option
		$tool_datacode = $self->{tool_datacode}; # sanity
		($parent_datacode = $self->{luggage}{session}{tools}{$tool_datacode}{parent}) =~ s/8_1://;
		$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_datacode}{target_datatype};

		$parent_string = $self->{altcode_decoder}->parent_string_from_altcode($self->{display_options}{altcode}, $parent_tool_datatype);
		$$searches[$n]{match_column} = 'parent';
		$$searches[$n]{operator} = '=';
		$$searches[$n]{match_value} = $parent_string;

		# TEST CODE:
		# $self->{belt}->logger('Parent string is '.$parent_string.' for '.$self->{display_options}{altcode},'searches');
		$n++ if !$n; # so below tests work
	}

	# what if no searches found?
	# this search tool may require at least one search be defined
	if ($n < $self->{attributes}{menus_required_for_search} && !$$searches[$n]{match_value} && $self->{attributes}{menus_required_for_search}) {
		$self->{wide_search_blocked} = 1;
	# otherwise, it allows super-wide searching, we'll match all records and limit to 500 items
	} elsif (!$$searches[$n]{match_value} && $n == 0) {
		$$searches[$n]{match_column} = 'code';
		$$searches[$n]{operator} = '>';
		$$searches[$n]{match_value} = '0';
		$self->{limit_results} = 500; # will pass to omniclass->search()
	}

	# assign the searches to $self for use above
	$self->{searches} = $searches;

	# $self->{belt}->logger($self->{searches}, 'eric');

}



# method to prepare JSON to render a basic 2-D chart via the Chart.js above the tool display
# will return the data that you can use here;  var myChart = new Chart(ctx, THIS_DATA_GOES_HERE);
# see http://www.chartjs.org/docs/latest/
# THIS IS THE BASIC VERSION: Please see example_tool_subclass.tt for an example of overriding this.
# USE THIS FOR SEARCHING TOOLS ONLY!!  Definitely override for Action Tools.
# To use this, set 'Display a Chart' to something other than No in your Tool View Mode Config,
# then set the 'Fields to Include' so that your desired X-axis (name) field is first an your
# Y-axis (values) field is second.
# Using charts in this way is really meant for Search Tools.
sub charting_json {
	my $self = shift;

	my ($backgroundColors, $chart_type, $labels, $n, $possible_colors, $record, $the_data, $first_field, $second_field, $chart_data_keys, $chart_data, $label);
	# re-run the search with the criteria they submitted
	# and that will put the results in $self->{json_results}{records} and
	# $self->{json_results}{records_keys} for you to build up 'datasets' below
	$self->search();

	# abort if none found
	if (!$self->{json_results}{records_keys}[0]) {
		$self->{json_results}{no_chart} = 1;
		return $self->{json_results};
	}

	# start with eight good colors
	$possible_colors = ['113BA4','A4114F','11A423','6611A4','D68212','D0D423','050000','D4239E',];

	# handy site for hex color codes: http://htmlcolorcodes.com/

	# we need the current view mode config in $self->{this_mode_config}
	# as well as the field names into $self->{included_field_names}, and
	# this nice method from center_stage.pm will handle all that for us:
	$self->prep_fields_to_include();

	# get the first and second included fields
	$first_field = $self->{included_records_fields}[0];
	$second_field = $self->{included_records_fields}[1];

	# determine the chart type based on the tool view mode name
	if ($self->{this_mode_config}{display_a_chart} =~ /line/i) {
		$chart_type = 'line';
	} elsif ($self->{this_mode_config}{display_a_chart} =~ /bar/i) {
		$chart_type = 'bar';
	} else {
		$chart_type = 'pie';
	}

	# now cycle throw each record and build CUMULATIVE data for the chart, so
	# records with duplicate first fields get combined
	foreach $record (@{ $self->{json_results}{records_keys} }) {
		$label = $self->{json_results}{records}{$record}{$first_field};
		push(@$chart_data_keys, $label) if !$$chart_data{$label};
		$$chart_data{$label} += $self->{json_results}{records}{$record}{$second_field};
	}

	# and then load that into the chart
	$n = 0; # for the colors array
	foreach $label (@$chart_data_keys) {
		# add the first column to the labels
		push(@$labels, $label );
		# second column is the actual data
		push(@$the_data, $$chart_data{$label} );
		# third is the background colors
		push(@$backgroundColors, '#'.$$possible_colors[$n]);

		$n++;
		$n = 0 if !$$possible_colors[$n];
	}

	# put toghether our data structure for the chart
	$self->{json_results} = {
		type => $chart_type,
		data => {
			labels => $labels,
			datasets => [{
				label => $self->{included_field_names}[0],
				data => $the_data,
				backgroundColor => $backgroundColors,
				borderColor => 'rgb(75, 192, 192)',
				lineTension => 0.1
			}]
		},
		options =>  {}
	};

	# certain options are for certain types of charts
	if ($chart_type =~ /line|bar/) { # start the yaxes at 0,0
		$self->{json_results}{options}{scales}{yAxes}[0] = {
			ticks => {
				beginAtZero => 1
			}
		};
	}

	# line charts need a bit of tweaking
	if ($chart_type eq 'line') {
		$self->{json_results}{data}{datasets}[0]{showLine} = 1;
		$self->{json_results}{data}{datasets}[0]{borderWidth} = 4;
		$self->{json_results}{data}{datasets}[0]{fill} = 0;
	}

	# have to send it out explicitly
	return $self->{json_results};

}


1;

