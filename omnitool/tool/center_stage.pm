package omnitool::tool::center_stage;
# OK, I could not help myself.  We should call this 'display_content_producer',
# but this class is where we fill the reason that we are here: Provide the content
# to go in the main tools display area; the actual Tool view.

# Specifically, this package / class provides the send_jemplate() and
# send_json_data() methods.  All tools will have a Jemplate Template file for
# handling the content from server.  All search tools will rely onsend_json_data()
# for producing the JSON data for that template; but if you try to call another
# method from the URI, that should produce JSON for the Jemplate.

# By the way, every Tool should have one Jemplate, with all the logic and Block
# definitions to handle everything you expect it to do.

# first time doing it this way, but have allowed this many times before
$omnitool::tool::center_stage::VERSION = '6.0';

# put your big kid shoes on
use strict;

# method to load, process, and send out jemplates to be processed by the client using
# the json data from send_json_data(). We shall start with a regular template-toolkit template,
# process it on the server side for this tool' needs, and the client will re-process it
# again with the json.  So these are 'double template' files really;
# this is where the magic really happens ;)
sub send_jemplate {
	my $self = shift;

	# declare vars
	my ($tool_mode_id, $app_inst, $app_code_directory, $tool_jemplate, $tool_jemplate_processed, $tool_datacode, $search_opts_key);

	# first off, run the 'pre_prep_jemplate()' hook, if this class is able to do so.
	# This should update the variables under $self, and would be most useful for Action Tools.
	if ($self->can('pre_prep_jemplate')) {
		$self->pre_prep_jemplate();
	}

	# we will load the tool from the 'tool mode' we are in, which was set in
	# load_display_options() and can be changed via ui buttons
	# $self->{display_options}{tool_mode}

	# sanity for addressing the tool mode
	$self->get_mode_config();
	# now in $self->{this_mode_config}

	# every tool should have a target datatype, not just Searching Tools
	$self->{target_datatype} = $self->{attributes}{target_datatype};
	if ($self->{target_datatype} =~ /\d\_\d/) {
		# we grab an omniclass object for this datatype from the object_factory
		# use a method which allows for a override / hook
		$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
		# was saved into $self->{omniclass_object} by get_omniclass_object()
	}

	# if this is a searching tool, go ahead and get the omniclass object, and
	# then let's massage the 'fields_to_include' a bit.
	if ($self->{attributes}{tool_type} =~ /Search/) {

		# Searching Tools should fail if no target_datatype
		if ($self->{target_datatype} !~ /\d\_\d/) {
			$self->{belt}->mr_zebra("ERROR: Searching Tool ".$self->{attributes}{name}." has no defined 'target_datatype'.",1);
		}

		# this is in a method below so the action tools have utilize if necessary, but don't forget your omniclass obj
		$self->prep_fields_to_include();
	}

	# is this a custom view?  if so, the template will be under $ENV{OTHOME}/code/omnitool/applications/APP_DIRECTORY/templates
	# the 'custom_template' value should be the full filename under that directory
	if ($self->{this_mode_config}{custom_template}) {

		# isolate the directory / sanity for below
		$app_inst = $self->{luggage}{app_inst};
		$app_code_directory = $self->{luggage}{session}{app_instance_info}{app_code_directory};

		# filter the template through template-toolkit, and get out the results in a scalar for below
		# the template will be under $ENV{OTHOME}/code/omnitool/static_files/templates
		# allow them to INCLUDE templates under the main 'tool_mode_jemplates' directory in their files
		$tool_jemplate = $self->{belt}->template_process(
			'template_file' => $self->{this_mode_config}{custom_template},
			'include_path' => $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/jemplates/:'.$ENV{OTHOME}.'/code/omnitool/static_files/tool_mode_jemplates/',
			'template_vars' => $self,
			'tag_style' => 'star', # need this so the template can be processed on the back-end
								   # The [* *] tags are server-side; [% %] for client
		);

	# other wise, use the value for 'mode_type' and add '_tool_mode.tt'
	} else {
		# filter the template through template-toolkit, and get out the results in a scalar for below
		# the template will be under $ENV{OTHOME}/code/omnitool/static_files/templates
		$tool_jemplate = $self->{belt}->template_process(
			'template_file' => $self->{this_mode_config}{mode_type}.'.tt',
			'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/tool_mode_jemplates/',
			'template_vars' => $self,
			'tag_style' => 'star', # need this so the template can be processed on the back-end
								   # The [* *] tags are server-side; [% %] for client
		);
	}

	# and how about a hook to modify that jemplate text just in case?
	if ($self->can('pre_send_jemplate')) {
		$tool_jemplate = $self->pre_send_jemplate($tool_jemplate);
	}

	# now process it into javascript via Jemplate and name it for the display area DIV in the client
	$tool_jemplate_processed = $self->{belt}->jemplate_process(
		'template_content' => $tool_jemplate,
		'template_name' => 'tool_display_'.$self->{tool_and_instance}.'.tt',
	);

	# send out; dispatcher.pm will throw to mr_zebra(), who will send out as javascript
	return $tool_jemplate_processed;

}

# Here is our primary method to gather up and send out JSON data to go into the Jemplate
# templates driving the tool_display area in the client (or going to our API command ;>)
# This method is going to be a bit of a traffic-director between two other modules/sub-classes.
#
# If this is a Searching tool, we will call out to 'search()' within omnitool::tool::searcher.
# search() allows variety of hooks are available for your Tool's sub-class (see main tool.pm).
#
# If this is an Action tool, this method will call out to 'run_action()' in omnitool::tool::action_tool.
# run_action() is meant to add a little structure to Action tools by calling methods it expects
# to find in your sub-class.
sub send_json_data {
	my $self = shift;

	# every tool should have a target datatype, not just Searching Tools
	$self->{target_datatype} = $self->{attributes}{target_datatype};
	if ($self->{target_datatype} =~ /\d\_\d/) {
		# we grab an omniclass object for this datatype from the object_factory
		# use a method which allows for a override / hook
		$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
		# was placed into $self->{omniclass_object} by get_omniclass_object()
	}

	# both the search() and run_action() methods will place the JSON hashref into $self->{json_results},
	# and we will add the 'session_created' key so the web client can check for a new session

	# if it's a search tool, call out to our sibling
	if ($self->{attributes}{tool_type} =~ /Search/) {

		# run the search -- this method allows for all of our hooks, see its comments
		$self->search();
		# $self->{json_results} should now have a 'records' and 'metainfo' sub-hashref's with
		# the result records and 'records_key' arrayref with the ordered results keys
		# straight from omniclass_data_extractor() in the object_factory ;)

		# if we are in Calendar mode, we need to send out the 'fields to include'
		# and the first one should be the value for 'Name', the second one is the calendar date
		$self->get_mode_config();
		if ($self->{this_mode_config}{mode_type} eq 'Calendar') {
			$self->prep_fields_to_include();
			$self->{json_results}{included_records_fields} = $self->{included_records_fields};
		}

	# if it's an action, go to 'run_action()'; it will decide if an error needs to be thrown
	} else {

		# this lives in  omnitool::tool::action_tool
		$self->run_action();

		# if using any of the search display templates, $self->{json_results} should now have
		# a 'records' and 'metainfo' sub-hashref's with the result records and 'records_key'
		# arrayref with the ordered results keys
	}

	# finally, we will need to add some system-stuff for our post_data_fetch_operations() client function to utilize

	# add the 'session_created' value
	$self->{json_results}{session_created} = $self->{luggage}{session}->{created};
	# suppress 'session refreshed' message if in serious developer mode
	$self->{json_results}{session_dev_mode} = $ENV{FORCE_FRESH_SESSIONS} if $ENV{FORCE_FRESH_SESSIONS};

	$self->get_mode_config(); # populates  $self->{this_mode_config}

	# if we want to execute a JS function when the data loads, add that to our JSON response
	# this will happen in post_data_fetch_operations() in omnitool_routines.js
	if ($self->{this_mode_config}{execute_function_on_load} && $self->{this_mode_config}{execute_function_on_load} ne 'None') {
		$self->{json_results}{execute_function_on_load} =  $self->{this_mode_config}{execute_function_on_load};

	# If the view mode's Jemplate has 'form' in the name, default 'execute_function_on_load' to 'interactive_form_elements'
	} elsif ($self->{this_mode_config}{mode_type}.$self->{this_mode_config}{custom_template} =~ /form/i) {
		$self->{json_results}{execute_function_on_load} = 'interactive_form_elements';
	}

	# also, tell the UI if there is a 'Single-Record Jemplate Block' settings for this view mode
	# if that is filled, closing subordinate modals and message tools will only reload the parent tool
	$self->{json_results}{single_record_jemplate_block} = $self->{this_mode_config}{single_record_jemplate_block} if $self->{this_mode_config}{single_record_jemplate_block};
	# and tell the UI (post_data_fetch_operations
	if ($self->{this_mode_config}{display_a_chart} =~ /Chart/) {
		$self->{json_results}{display_a_chart} = $self->{this_mode_config}{display_a_chart};
	}

	# will need this for passing into the 'execute_function_on_load' function
	$self->{json_results}{the_tool_id} = $self->{tool_and_instance};

	# send out; dispatcher.pm will throw to mr_zebra(), who will send out as json
	return $self->{json_results};
}

# method to make 'fields_to_include' info much easier to handle in template-toolkit
sub prep_fields_to_include {
	my $self = shift;

	my ($tool_mode_id, $field, $field_name);

	# we need an array of the field names, plus an array of the results which will be in
	# the 'records' or 'metainfo' hashes under the omniclass object

	# make sure we have sanity for addressing the tool mode
	# should already have this, but just in case
	$self->get_mode_config(); # poplates  $self->{this_mode_config}

	foreach $field (split /,/, $self->{this_mode_config}{fields_to_include}) {
		# if it's 'name,' then they want the title
		if ($field eq 'Name') {
			push( @{ $self->{included_field_names} }, 'Name' );
			push( @{ $self->{included_records_fields} }, 'name');

		# external ID / altcode
		} elsif ($field eq 'altcode') {
			push( @{ $self->{included_field_names} }, 'ID' );
			push( @{ $self->{included_records_fields} }, 'altcode');

		# otherwise, will be the datatype_field's primary key
		} else {
			# did they specify a alternative heading name
			if ($self->{omniclass_object}->{datatype_info}{fields}{$field}{search_tool_heading}) {
				push( @{ $self->{included_field_names} }, $self->{omniclass_object}->{datatype_info}{fields}{$field}{search_tool_heading} );

			# otherwise, default to the name
			} else {
				push( @{ $self->{included_field_names} }, $self->{omniclass_object}->{datatype_info}{fields}{$field}{name} );

			}

			push( @{ $self->{included_records_fields} }, $self->{omniclass_object}->{datatype_info}{fields}{$field}{table_column} );
		}

	}
}

# sanity method for putting the current tool mode data info $self->{this_mode_config}
sub get_mode_config {
	my $self = shift;

	my $tool_mode_id;

	# only act if we don't have it set already
	if (!$self->{this_mode_config}) {
		# sanity for addressing the tool mode ID
		$tool_mode_id = $self->{display_options}{tool_mode};

		# easy shortcut for within the template/jemplate
		$self->{this_mode_config} = $self->{tool_configs}{tool_mode_configs}{$tool_mode_id};

		if (!$self->{this_mode_config}{name} && ref($self->{tool_configs_keys}) eq 'ARRAY') { # maybe got deleted?  go with the first one we have
			$tool_mode_id = $self->{tool_configs_keys}[0];
			$self->{this_mode_config} = $self->{tool_configs}{tool_mode_configs}{$tool_mode_id};
		}
	}

	# all done: just don't want to repeat myself everywhere
}

# method to send a file out from a record; the ID of the record will be in the 'altcode'
# value and we will assume the first file_upload field, or you could specify the field
# via the 'file_field' parameter
# please see omnitool::applications::my_family::datatypes::work_projects::field_attachment_link()
# for a working example
sub send_file {
	my $self = shift;

	my ($data_code);

	# every tool should have a target datatype, not just Searching Tools
	$self->{target_datatype} = $self->{attributes}{target_datatype};

	# they may have set a specific datatype ID to use a record other than the target
	if ($self->{display_options}{datatype} =~ /\d\_\d/) {
		$self->{target_datatype} = $self->{display_options}{datatype};
	}

	if ($self->{target_datatype} =~ /\d\_\d/) {
		# we grab an omniclass object for this datatype from the object_factory
		# use a method which allows for a override / hook
		$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
		# was saved into $self->{omniclass_object} by get_omniclass_object()
	} else { # no need to continue
		$self->{belt}->mr_zebra("ERROR: Cannot use send_file() as ".$self->{attributes}{name}." has no defined 'target_datatype'.",1);
	}

	if ($self->{display_options}{data_altcode}) {
		($data_code) = $self->{omniclass_object}->altcode_to_data_code( $self->{display_options}{data_altcode} );
		# if it found a record, load it up
		if ($data_code) {
			$self->{omniclass_object}->load('data_codes' => [$data_code]);
			# should be the only record in there, so it'll be available under $self->{omniclass_object}->{data}
		}
	}
	# if no data record found, we have to abort
	if (!$data_code) {
		$self->{belt}->mr_zebra("ERROR: Cannot use tool->send_file() with ".$self->{attributes}{name}." without a valid data record / altcode.",1);
	}

	# if they want to specify the field, it will be in $self->{luggage}{params}{file_field}
	# otherwise, omniclass->send_file() will use the first file upload
	# and it will error out if there is no file upload
	$self->{omniclass_object}->send_file($data_code);
	# that routine will take it from here

}

# utility method for API programmers to see the display options for a Searching tool
sub show_display_options {
	my $self = shift;

	# i can't believe i get paid real money for this
	$self->{json_results} = $self->{display_options};

}

# avoid autoloading if this method is not available in your sub-class
# also a cheap way to test in development
sub prepare_json {
	my $self = shift;

=cut

	Example form below.

	Note: You do NOT have to use numbers for your field keys.

	$form = {
		'target_url' => '/tools/some/action/method',
		'title' => 'How Great is Ginger?',
		'show_title' => 1, # fill if you want ModalForm.tt to show the form title; otherwise unnecessary
		'instructions' => 'Info to appear below title and above fields.',
		'submit_button_text' => 'Text for Submit Button',
		'hidden_fields' => {
			'field_name1' => 'field_value',
		},
		'field_keys' => [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],
		'fields' => { # integer keys, easily sorted
			1 => {
				'title' => 'Color of Ginger',
				'name' => 'ginger_color',
				'preset' => 'Perfect',
				'field_type' => 'short_text',
				'instructions' => 'Color of Heaven.',
				'is_required' => 1, # will be required for form submit; works for text fields
				'max_length' => 200, # allow up to 200 characters,
				'readonly' => 'readonly', # include this to lock the field, otherwise leave out
			},
			2 => {
				'title' => 'Is Ginger Wonderful?',
				'name' => 'is_ginger_wonderful',
				'preset' => 'Yes',
				'field_type' => 'yes_no_select',
				'instructions' => 'I hope it appears',
			},
			3 => {
				'title' => 'How is Ginger Wonderful?',
				'name' => 'how_is_ginger_wonderful',
				'preset' => 'She is sooo wonderful!',
				'field_type' => 'long_text',
				'instructions' => 'I hope it appears',
			},
			4 => {
				'title' => "Ginger's Birthday",
				'name' => 'gingers_birthday',
				'preset' => '1999-08-01',
				'field_type' => 'simple_date',
			},
			5 => {  # NOTE: THIS IS NOT SUPPORTED IN OMNICLASS; only here for example / usable in search dialogs
					# if you need a date-range, use two simple_date fields.  Possible future support, later, much later.
				'title' => "Ginger's Reign of Glory",
				'start_name' => 'gingers_reign_start',
				'end_name' => 'gingers_reign_end',
				'preset_start' => '1999-08-01',
				'preset_end' => '2019-08-01',
				'field_type' => 'date_range',
			},
			6 => {
				'title' => "Ginger's Phone Number",
				'name' => 'gingers_phone',
				'preset' => '9192706916',
				'field_type' => 'phone_number',
			},
			7 => {
				'title' => "Ginger's Password",
				'name' => 'gingers_pw',
				'preset' => 'hail',
				'field_type' => 'password',
			},
			8 => {
				'title' => "Ginger's Status",
				'name' => 'gingers_status',
				'preset' => 'Active',
				'field_type' => 'active_status_select',
			},
			9 => {
				'title' => "Who is the Best?",
				'name' => 'gingers_chooser',
				'preset' => 'ging',
				'options_keys' => ['lb','mel','ging','pep','eric'],
				'options' => {
					'ging' => 'Ginger',
					'pep' => 'Pepper',
					'lb' => 'Lorelei',
					'eric' => 'Eric',
					'mel' => 'Melanie',
				},
				'field_type' => 'single_select', # use 'single_select_plain' for non-chosen / regular menu's
				'onchange' => qq{SOME_JAVASCRIPT_CODE}, # optional: JS to execute for 'onchange' event
														# better to use jquery to add via selectors
			},
			10 => {
				'title' => "What Powers Does Ginger Have?",
				'name' => 'gingers_powers',
				'presets' => {
					'speed' => 1,
					'healing' => 1,
					'strength' => 1
				},
				'options_keys' => ['strength','mercy','healing','patience','speed'],
				'options' => {
					'patience' => 'Great Patience',
					'mercy' => 'Kindness and Mercy',
					'strength' => 'Infinite Strength',
					'healing' => 'Instant Healing',
					'speed' => 'Unimaginable Speed',
				},
				'field_type' => 'multi_select_ordered',
				# 'multi_select_ordered' allows-for and preserves ordering of options
				# 'multi_select_plain' uses jquery.chosen and is pretty, but no ordering
			},
			11 => {
				'title' => "Ginger's Home Address",
				'name' => 'gingers_address',
				'presets' => {
					'street_one' => '5213 Greyfield Blvd',
					'city' => 'Durham',
					'state' => 'NC',
					'zip' => '27713',
					'country' => 'USA',
				},
				'field_type' => 'street_address',
			},
			12 => {
				'title' => "Ginger's Best Trait",
				'name' => 'gingers_best_trait',
				'preset' => 'beauty',
				'options_keys' => ['brains','beauty','cunning','smell','mercy'],
				'options' => {
					'brains' => 'Her Brains',
					'beauty' => 'Her Beauty',
					'cunning' => 'Her Cunning',
					'smell' => 'Her Smell',
					'mercy' => 'Her Mercy',
				},
				'field_type' => 'radio_buttons',
			},
			13 => {
				'title' => "Ginger's Email Address",
				'name' => 'gingers_email',
				'presets' => {
					'username' => 'ginger',
					'domain' => 'chernoff.org'
				},
				'field_type' => 'email_address',
			},
			14 => {
				'title' => "Ginger's Tolerance for Idiots",
				'name' => 'gingers_tolerance_idiots',
				'preset' => 10,
				'field_type' => 'low_integer',
			},
			15 => {
				'title' => "Ginger's IQ",
				'name' => 'gingers_iq',
				'preset' => 876876,
				'field_type' => 'high_integer',
			},
			16 => {
				'title' => "Ginger's Thoughts per Second",
				'name' => 'gingers_thoughts_per_second',
				'preset' => '75839.65,
				'field_type' => 'low_decimal',
			},
			17 => {
				'title' => "Ginger's Monetary Value",
				'name' => 'gingers_value',
				'preset' => '999999999999.99',
				'field_type' => 'high_decimal',
			},
			18 => {
				'title' => "Ginger's Home Page",
				'name' => 'gingers_home_page',
				# 'preset' => 876876,
				'field_type' => 'web_url',
			},
			19 => {
				'title' => "Ginger's Birth Month",
				'name' => 'gingers_birth_month',
				'preset' => 'August 1999',
				'field_type' => 'month_name',
			},
			20 => {
				'title' => "Ginger's Talents",
				'name' => 'gingers_talents',
				'presets' => {
					'eating' => 1,
					'healing' => 1,
				},
				'options_keys' => ['healing','running','killing','eating'],
				'options' => {
					'healing' => 'Healing',
					'running' => 'Running',
					'killing' => 'Killing',
					'eating' => 'Eating',
				},
				'field_type' => 'check_boxes',
			},
			21 => {
				'title' => "Ginger's Picture",
				'name' => 'gingers_picture',
				'preset' => 'ginger.jpg',
				'field_type' => 'file_upload',
			},
			22 => {
				'title' => "Ginger's Life Story",
				'name' => 'gingers_life',
				'field_type' => 'rich_long_text',
			},
			23 => {
				'title' => "Ginger's Access Control",
				'name' => 'gingers_access',
				'field_type' => 'access_roles_select',
			},
			24 => {
				'title' => "Font Awesome Icon",
				'name' => 'ginger_icon',
				'field_type' => 'font_awesome_select',
				'preset' => 'fa-wrench',
			},
			25 => {
				'title' => "Display Text",
				'name' => 'plain_text_to_show',
				'field_type' => 'just_text',
				'preset' => 'These words would be displayed.',
			},
			26 => {
				'title' => "Tags Field",
				'name' => 'facets_of_ginger',
				'field_type' => 'short_text_tags',
				'preset' => 'Great,Wonderful,Magnificent',
				# this one will send back a comma-selected list; you will need an
				# 'options_' method to power the auto-suggester for this field
			},
			27 => { # for "I am not a robot" Google ReCaptcha.  Do not change, and look at https://www.google.com/recaptcha/admin
				'title' => 'Please Verify',
				'name' => 'recaptcha',
				'field_type' => 'recaptcha',
				'recaptcha_key' => $ENV{RECAPTCHA_SITEKEY},
			},

		},
	};

=cut
}

1;
