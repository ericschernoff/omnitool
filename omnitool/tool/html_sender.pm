package omnitool::tool::html_sender;
# package to prep/deliver the 'mini-skeleton' of the tool view; includes the primary layout divs
# and the search/display controls.  The tool controls are what needs the most work.
# We are going to opt to do much of the work within Perl for easy re-use, rather than
# bury logic in the template

# should be 1.0, but everything starts with six up in here ;)
$omnitool::tools::html_sender::VERSION = '6.0';

# time to grow up
use strict;

# start our method to prepare/process the tool's skeleton divs
sub send_html {
	my $self = shift;

	# this will be filled if they called the 'send_tool_controls' uri
	my ($template) = @_;
	# default use case is the whole tools area
	$template ||= 'tool_area_skeleton.tt'; 

	# allow for a hook prior to the tools_controls, namely to augment $self->{attributes}{description}
	if ($self->can('pre_tool_controls')) {
		$self->pre_tool_controls();
	}

	# use the method below to get ready for the tools_controls area
	$self->tool_controls();

	# we will rely on $OTHOME/code/omnitool/static_files/tool_area_skeleton.tt
	my $tool_html = $self->{belt}->template_process(
		'template_file' => $template,
		'template_vars' => $self,
	);

	# send back; dispatcher.pm will throw to mr_zebra(), who will send out as html
	return $tool_html;
}

# companion method to send only the tools_controls HTML, i.e. for an advanced search submit
sub send_tool_controls {
	my $self = shift;

	# don't repeat yourself ;->
	return $self->send_html('tool_controls.tt');
}

# subroutine to send the breadcrumbs information
sub send_breadcrumbs {
	my $self = shift;

	# use another method to find our breadcrumbs, which will be our path of
	# tools from here to the 'top' tool. builds $self->{breadcrumbs}[]
	# allow for a hook too:
	if ($self->can('special_breadcrumbs')) {
		$self->special_breadcrumbs($self->{display_options}{altcode});
		# that'll be in a specialized class, so won't need 'tool_datacode'
	# our normal way; a little involved; see notes below
	} else {
		$self->find_breadcrumbs($self->{tool_datacode},$self->{display_options}{altcode});
	}

	# the breadcrumbs template needs the uri_path_base for the bookmarks links
	# $self->{bc_store}{bookmark_link} = '/tools/'.$self->{attributes}{uri_path_base}.'/bookmarks';

	# include the 'tool_and_instance'
	$self->{bc_store}{tool_and_instance} = $self->{tool_and_instance};

	# and the app-wide search JS function / name and app-wide quick-start tool, if they are filled
	foreach my $key ('appwide_search_function','appwide_search_name','appwide_quickstart_tool_uri') {
		$self->{bc_store}{$key} = $self->{luggage}{session}->{app_instance_info}{$key};
	}

	# ship them out
	return $self->{bc_store};

}

# method to prepare for the 'tool_controls' portion of the our tool_area_skeleton.tt template
# we are not building this area via jemplate; that is for the tool_display_area
sub tool_controls {
	my $self = shift;

	my ($filter_menu, $menu_cnt, $mode_view, $tk);

	# determine the child-actions which are labeled 'quick actions'
	foreach $tk (@{ $self->{attributes}{child_tools_keys} }) {
		push(@{ $self->{quick_actions} },$tk) if $self->{luggage}{session}{tools}{$tk}{link_type} eq 'Quick Actions';
	}

	# prepare the mode/view options
	# start with the tool mode views
	foreach $mode_view ( @{ $self->{tool_configs_keys}{tool_mode_configs} }) {
		# just need to set the name properly, if it's custom
		if ($self->{tool_configs}{tool_mode_configs}{$mode_view}{custom_type_name}) {
			$self->{tool_configs}{tool_mode_configs}{$mode_view}{mode_type} = $self->{tool_configs}{tool_mode_configs}{$mode_view}{custom_type_name};
		}

		# the uri to load the view
		$self->{tool_configs}{tool_mode_configs}{$mode_view}{uri} = $self->{my_base_uri}.'/tool_mode'.$mode_view;
	}

	# now the quick-search menus; limit to two
	$menu_cnt = 0;
	foreach $filter_menu ( @{ $self->{tool_configs_keys}{tool_filter_menus} }) {

		# just the quick search menus, which must be single-selects
		# limit to four quick-search menus
		next if $self->{quick_search_menus}[3] || $self->{tool_configs}{tool_filter_menus}{$filter_menu}{display_area} ne 'Quick Search' ||
			$self->{tool_configs}{tool_filter_menus}{$filter_menu}{menu_type} !~ /Single-Select|Month Chooser/;

		# add this filter menu to our 1-2 item list for the template processor
		push(@{ $self->{quick_search_menus} },$filter_menu);

	}

	# use method below to fetch the search options
	$self->build_filter_menu_options($self->{quick_search_menus});

	# tell the template if there is just one search menu
	if ($self->{quick_search_menus}[0] && !$self->{quick_search_menus}[1]) {
		$self->{one_search_menu} = 1;
	}

	# if this is a searching tool, we shall provide a text-search box
	if ($self->{attributes}{tool_type} eq 'Search - Screen') {
		$self->{has_search_box} = 1;
	}

	# if there are additional search menus, we shall provide the advanced search option
	if (scalar( @{ $self->{tool_configs_keys}{tool_filter_menus} } ) > scalar( @{ $self->{quick_search_menus} } )) {
		$self->{has_advanced_search} = 1;
	}
}

# method to generate the json for the advanced sort form jemplate modal
# this allows the user to sort their results by multiple columns/directions
sub advanced_sort_form {
	my $self = shift;

	# start the web form
	$self->{json_results}{form} = {
		'target_url' => $self->{my_json_uri},
		'title' => 'Advanced Sort Form',
		'submit_button_text' => 'Submit Advanced Sort Options',
		'hidden_fields' => {
			'client_connection_id' => $self->{client_connection_id},
		},
	};

	# call method from center_stage.pm to prep the field keys / names
	$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
	$self->get_mode_config();
	$self->prep_fields_to_include();

	my (@field_keys, $num, $field);

	# info on the fields
	$self->{json_results}{form}{included_records_fields} = $self->{included_records_fields};
	$self->{json_results}{form}{included_field_names} = $self->{included_field_names};

	# this form is going to a right bit different.  We just need to infom the 'advanced_sort_form'
	# jemplate of how many fields we have to sort, what the field names are, and what our presets might be

	for ($num = 1; $num < 5; $num++) {
		$self->{json_results}{form}{fields}{$num} = {
			'order_number' => $num,
			'preset' => $self->{display_options}{'advanced_sort_'.$num}
		};
		push (@{ $self->{json_results}{form}{field_keys} }, $num);
	}

	# send it out
	return $self->{json_results};
}

# method to generate the form json for the advanced search form jemplate modal.
# includes all filter menus
# FYI: The template for these forms is in system_modals.tt
sub advanced_search_form {
	my $self = shift;

	my ($num, $trigger_menu, $filter_menu, $value_key, $tool_filter_menu, $form_field_type, $keyword_key, $keyword_operator_key, $start_key, $end_key, $opt);

	# use method below to fetch the search options for ALL menus:
	$self->build_filter_menu_options( $self->{tool_configs_keys}{tool_filter_menus} );

	# start the web form
	$self->{json_results}{form} = {
		'target_url' => $self->{my_json_uri},
		'title' => 'Advanced Search Form',
		# 'instructions' => 'To clear keywords or date ranges, simply delete text fields.',
		'submit_button_text' => 'Submit Advanced Search Parameters',
		'hidden_fields' => {
			'client_connection_id' => $self->{client_connection_id},
		},
	};

	# first the quick-search keyword
	$num = 1;
	$self->{json_results}{form}{fields}{$num} = {
		'title' => 'Wide Keyword',
		'name' => 'quick_keyword',
		'both_columns' => 1,
		'preset' => $self->{display_options}{'quick_keyword'},
		'field_type' => 'short_text',
		'instructions' => 'Perl-style regular expressions OK',
	};
	push (@{ $self->{json_results}{form}{field_keys} }, $num);

	# now add the menus to the form hash
	$num = 2;
	foreach $filter_menu (@{ $self->{tool_configs_keys}{tool_filter_menus} }) {

		$value_key = 'menu_'.$filter_menu; # the value / display_options key for the menu

		# some sanity here to access this menu
		$tool_filter_menu = $self->{tool_configs}{tool_filter_menus}{$filter_menu};

		# figure out the default / current option
		$$tool_filter_menu{default_option_value} ||= 'Any'; # 'Any' is our default default option
		if (!$self->{display_options}{$value_key} && $$tool_filter_menu{default_option_value}) {
			$self->{display_options}{$value_key} = $$tool_filter_menu{default_option_value};
			# this will get saved by display_options_manager() when we are done
		}

		# field type is based off 'menu type' option
		if ($$tool_filter_menu{menu_type} eq 'Single-Select') {
			$form_field_type = 'single_select';
		} elsif ($$tool_filter_menu{menu_type} eq 'Multi-Select') {
			$form_field_type = 'advanced_search_multi_select';

		} elsif ($$tool_filter_menu{menu_type} eq 'Date Range') {
			$form_field_type = 'date_range';

		# this will be a special field type for advanced searches
		} elsif ($$tool_filter_menu{menu_type} eq 'Keyword') {
			$form_field_type = 'advanced_search_keyword';

		# this is also a special field
		} elsif ($$tool_filter_menu{menu_type} eq 'Keyword Tags') {
			$form_field_type = 'short_text_tags';

		}

		$self->{json_results}{form}{fields}{$num} = {
			'title' => $$tool_filter_menu{name},
			'name' => $value_key,
			'preset' => $self->{display_options}{$value_key},
			'options_keys' => $$tool_filter_menu{options_keys},
			'options' => $$tool_filter_menu{options},
			'instructions' => $$tool_filter_menu{instructions},
			'field_type' => $form_field_type,
		};
		push (@{ $self->{json_results}{form}{field_keys} }, $num);

		# we need a few extra values for keyword fields
		if ($$tool_filter_menu{menu_type} eq 'Keyword') {
			$keyword_key = 'keyword_'.$filter_menu;
			$keyword_operator_key = 'keyword_operator_'.$filter_menu;

			# this field needs to be wide
			$self->{json_results}{form}{fields}{$num}{both_columns} = 1;

			$self->{json_results}{form}{fields}{$num}{keyword_key} = $keyword_key;
			$self->{json_results}{form}{fields}{$num}{keyword_operator_key} = $keyword_operator_key;

			$self->{json_results}{form}{fields}{$num}{keyword_preset} = $self->{display_options}{$keyword_key};
			$self->{json_results}{form}{fields}{$num}{keyword_operator_preset} = $self->{display_options}{$keyword_operator_key};

		# and the keyword_tags field
		} elsif ($$tool_filter_menu{menu_type} eq 'Keyword Tags') {
			# this field needs to be wide
			$self->{json_results}{form}{fields}{$num}{both_columns} = 1;

		# as well as for date-range fields
		} elsif ($$tool_filter_menu{menu_type} eq 'Date Range') {
			$start_key = 'start_'.$filter_menu;
			$end_key = 'end_'.$filter_menu;

			$self->{json_results}{form}{fields}{$num}{start_name} = $start_key;
			$self->{json_results}{form}{fields}{$num}{end_name} = $end_key;

			$self->{json_results}{form}{fields}{$num}{preset_start} = $self->{display_options}{$start_key};
			$self->{json_results}{form}{fields}{$num}{preset_end} = $self->{display_options}{$end_key};

		# multi-select's need the preset turned into an IN list
		} elsif ($$tool_filter_menu{menu_type} eq 'Multi-Select') {
			foreach $opt (split /,/, $self->{display_options}{$value_key}) {
				$self->{json_results}{form}{fields}{$num}{presets}{$opt} = 1;
			}

			$self->{json_results}{form}{fields}{$num}{placeholder} = 'Select Options';

		# if this is a single-select and they have 'triggers_other_menus' set to 'Yes,' then
		# make the menu reload when something is selected
		} elsif ($$tool_filter_menu{menu_type} eq 'Single-Select' && $$tool_filter_menu{trigger_menu} =~ /\d/) {
			# can actually have more than one
			foreach $trigger_menu (split /,/, $$tool_filter_menu{trigger_menu}) {
				$self->{json_results}{form}{fields}{$num}{onchange}
					.= "tool_objects['" . $self->{tool_and_instance} . "'].trigger_menu('menu_" . $trigger_menu ."',this.options[this.selectedIndex].value);";
			}
		}

		$num++;
	}

	# allow for a hook to play with this form structure
	if ($self->can('advanced_search_form_tweak')) {
		$self->advanced_search_form_tweak();
	}

	# send it out
	return $self->{json_results};
}

# method to return options for a single menu; used for the 'trigger another menu' option
# in the Tool Filter Menus option, such that choosing one option for single-select menu
# will load up options for another menu.  The target menu should have its options
# built by a method, looking at the 'source_menu_ID' param
sub advanced_search_trigger_menu_options {
	my $self = shift;

	# clean out the prefix needed for the JS
	$self->{luggage}{params}{target_menu_id} =~ s/menu_//;

	# use method below to fetch the search options for the target menu.
	$self->build_filter_menu_options([$self->{luggage}{params}{target_menu_id}]);

	# some sanity here to access this menu
	my $tool_filter_menu = $self->{tool_configs}{tool_filter_menus}{ $self->{luggage}{params}{target_menu_id} };

	# start the web form
	$self->{json_results} = {
		'target_menu_id' => $self->{luggage}{params}{target_menu_id},
		'options_keys' => $$tool_filter_menu{options_keys},
		'options' => $$tool_filter_menu{options},
	};

	# done ;)
	return $self->{json_results};
}

# method to build the 'breadcrumbs' list which should be the chain of tools up to the top
# reusable method to build filter menu options for one or more menus
# expects an array of filter menu keys
sub build_filter_menu_options {
	my $self = shift;
	my ($filter_menu_keys) = @_;

	my ($datatype_table_name,$display_field_name,$menu_omniclass_object, $the_value, $current_selected_option, $value_key, $result, $filter_menu, $method, $name, $option, $possible_options, $this_tool_filter_menu, $value, @placeholder_values, @rest, $months_back, $months_forward, $month_names);

	# we shall cycle thru and add the options under $self->{tool_configs}{tool_filter_menus}{$filter_menu}
	# adding sub-keys for 'options' and 'options_keys'

	# how we build these are determined by the values in tool_filter_menus.menu_options_type
	# and tool_filter_menus.menu_options

	# get started
	foreach $filter_menu (@$filter_menu_keys) {

		# shorten our hashref variable for sanity here
		$this_tool_filter_menu = $self->{tool_configs}{tool_filter_menus}{$filter_menu};
		# not sure if that helps, really

		# month-chooser menu type uses utility_belt::month_name_list to generate a list 
		# of months based on the two numbers (of months) supplied in $$this_tool_filter_menu{menu_options}
		if ($$this_tool_filter_menu{menu_type} eq 'Month Chooser') {
			
			# get the months back/forward from $$this_tool_filter_menu{menu_options}
			$$this_tool_filter_menu{menu_options} =~ s/\s//g;
			($months_back, $months_forward) = split /,/, $$this_tool_filter_menu{menu_options};
			# the defaults are 24 months_back and 12 months_forward
			
			# call to the utility-belt method to get the month names
			$month_names = $self->{belt}->month_name_list($months_back, $months_forward);
			
			# and then add them in
			foreach $option (@$month_names) {
				push(@{ $$this_tool_filter_menu{options_keys} }, $option);
				$$this_tool_filter_menu{options}{$option} = $option;
			}			
			
		# proceed based on option definer type
		} elsif ($$this_tool_filter_menu{menu_options_type} eq 'Comma-Separated List') { # easiest of all
			foreach $option (split /,/, $$this_tool_filter_menu{menu_options}) {
				next if !length($option); # skip blanks, allowing for '0'
				# $value = $$this_tool_filter_menu{base_uri}.$option;
				push(@{ $$this_tool_filter_menu{options_keys} }, $option);
				$$this_tool_filter_menu{options}{$option} = $option;
			}

		} elsif ($$this_tool_filter_menu{menu_options_type} eq 'Name/Value Pairs') { # little tougher
			foreach $option (split /\n/, $$this_tool_filter_menu{menu_options}) {
				($name,$value) = split /=/, $option;
				next if !$name || !length($value); # skip blanks, allowing for '0'
				# $value = $$this_tool_filter_menu{base_uri}.$value;
				push(@{ $$this_tool_filter_menu{options_keys} }, $value);
				$$this_tool_filter_menu{options}{$value} = $name;
			}


		} elsif ($$this_tool_filter_menu{menu_options_type} eq 'Method' && $$this_tool_filter_menu{menu_options_method}) {

			# the method should be in the tool-specific class, and it should
			# modify $this_tool_filter_menu in the same way as the above two options
			$method = $$this_tool_filter_menu{menu_options_method};
			# proceed if we can
			if ($self->can($method)) {
				$self->$method($this_tool_filter_menu);
			}

		} elsif ($$this_tool_filter_menu{menu_options_type} eq 'Relationship' && $$this_tool_filter_menu{menu_options_method}) {
			# 'Relationship' means another datatype, and in that case,
			# 'method' will be in the format of 'table_name.display_field_name' where 
			# 'display_field_name' is optional and defaults to 'name'
			($datatype_table_name,$display_field_name) = split /\./, $$this_tool_filter_menu{menu_options_method};
			$display_field_name ||= 'name';
			
			if ($datatype_table_name) {
				$menu_omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
					'dt' => $datatype_table_name,
					'load_all' => 1,
				);
				($$this_tool_filter_menu{options}, $$this_tool_filter_menu{options_keys}) =
					$menu_omniclass_object->prep_menu_options($display_field_name);
			}

		# we really should use the method() approach and not sql logic, but all fun and no play...
		} elsif ($$this_tool_filter_menu{menu_options_type} eq 'SQL Command' && $$this_tool_filter_menu{sql_cmd}) {
			# the placeholders should be comma/semicolon-separated values within $$this_tool_filter_menu{menu_options}
			(@placeholder_values) = split /,|;/, $$this_tool_filter_menu{sql_bind_values};

			# this SQL should include an 'order-by' clause too
			$possible_options = $self->{db}->do_sql(
				$$this_tool_filter_menu{sql_cmd},
				\@placeholder_values
			);
			# make sure we just use the first two values
			foreach $result (@$possible_options) {
				($value,@rest) = @{$result};
				# $the_value = $$this_tool_filter_menu{base_uri}.$value;
				$$this_tool_filter_menu{options}{$value} = $rest[0] if $rest[0];
				push(@{ $$this_tool_filter_menu{options_keys} }, $value);
			}
		}

		# for the record, I should break this up into four methods, I know.
		# probably will do that in the future

		# make sure there is any 'Any/All' option upfront - only for month choosers/single selects and those who allow it
		if ($$this_tool_filter_menu{options_keys}[0] ne 'Any' && $$this_tool_filter_menu{menu_type} =~ /Month Chooser|Single-Select/ && $$this_tool_filter_menu{support_any_all_option} ne 'No') {
			unshift(@{ $$this_tool_filter_menu{options_keys} },'Any');
			$$this_tool_filter_menu{options}{Any} = 'Any/All';
		}

		# figure out current / default value for this menu;
		# do this here rather than in searcher.pn so we can display
		$value_key = 'menu_'.$filter_menu; # the value / display_options key for the menu

		# hate to have nested IF statements, but here goes:
		if (!$self->{display_options}{$value_key}) { # if there is no selected option

			# only look for a default_option_value if one wasn't hard-set in the config
			if (!$$this_tool_filter_menu{default_option_value}) {

				# if the menu supports the 'any' option, use that
				if ($$this_tool_filter_menu{menu_type} eq 'Single-Select' && $$this_tool_filter_menu{support_any_all_option} ne 'No') {
					$$this_tool_filter_menu{default_option_value} = 'Any';

				# otherwise, go with the first available option for the menu (single-select only)
				} elsif ($$this_tool_filter_menu{menu_type} eq 'Single-Select') {
					$$this_tool_filter_menu{default_option_value} = $$this_tool_filter_menu{options_keys}[0];

				}

			}

			# set the chosen option to the default_option_value
			$self->{display_options}{$value_key} = $$this_tool_filter_menu{default_option_value};
			# this will get saved by display_options_manager() when we are done
		}

		# easy-access to the name of the selected option's name for the template
		$current_selected_option = $self->{display_options}{$value_key};
		$$this_tool_filter_menu{current_selected_option_name} = $$this_tool_filter_menu{options}{$current_selected_option};

	}
}

# build the data Jemplate will use to displace our breadcrumbs back to the 'top'
# tool.  It gets a little involved because it needs to go 'recursive' up to the
# top most tool, and it needs to figure the 'altcode' bit for both the uri
# and the display name; we are going to build an aray of hashes with the
# tool name and uri based on the tool and the altcode
sub find_breadcrumbs {
	my $self = shift;

	my ($tool_datacode,$data_id_altcode) = @_;
	return if !$tool_datacode;

	my ($record_name, $parent_altcode, $parent_datacode, $parent_tool_datatype, $search_opts_key);

	# if we are going to try to get the altcode/record-name info, we need to know the target
	# datatype of the parent tool, which should be a searching tool

	# need the datacode of our parent tool, and we shall use this below
	if ($self->{luggage}{session}{tools}{$tool_datacode}{parent} =~ /^8_1:/) {
		($parent_datacode = $self->{luggage}{session}{tools}{$tool_datacode}{parent}) =~ s/8_1://;

		# dig out the target datatype of that parent tool from the session; i am sorry for how complex this ios
		$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_datacode}{target_datatype};

		# if there is a data_id/altcode and parent_tool_datatype, figure out the parent and the record name for that
		if ($data_id_altcode) {
			# fetch the info from common::altcode_decoder
			($record_name, $parent_altcode) = $self->{altcode_decoder}->name_and_parent_from_altcode($data_id_altcode,$parent_tool_datatype);

			# it's a little funny if we are in create mode, as the altcode will actually be from the parent tool
			if ($self->{luggage}{session}{tools}{$tool_datacode}{uri_path_base} =~ /\/create$/) {
				$parent_altcode = $data_id_altcode;
			}
		}
	}

	# if found, include this info in the array of hashes we are building
	if ($record_name) {
		unshift(@{$self->{bc_store}{breadcrumbs}},{
			'tool_name' => $self->{luggage}{session}{tools}{$tool_datacode}{button_name}. ' ('.$record_name.')',
			'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$tool_datacode}{uri_path_base}.'/'.$data_id_altcode,
			'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_datacode}{icon_fa_glyph},
		});
	# otherwise, just the tool's info, no record
	} else {
		unshift(@{$self->{bc_store}{breadcrumbs}},{
			'tool_name' => $self->{luggage}{session}{tools}{$tool_datacode}{button_name},
			'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$tool_datacode}{uri_path_base},
			'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_datacode}{icon_fa_glyph},
		});
	}

	# is current tool a child of another tool? if so, continue upwards
	if ($parent_datacode) {
		$self->find_breadcrumbs($parent_datacode,$parent_altcode);
	}

	# all done
}

1;
