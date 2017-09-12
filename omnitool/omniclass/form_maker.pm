package omnitool::omniclass::form_maker;

=cut

Produces the %$form hash used by our Templates/Jemplates to generate web forms for
creating or updating records within this OmniClass's datatype.  Meant to be sent
out via a Tool.pm subclass / action module via it's prepare_json() method and
fed into one of the 'Form_mode.tt' Jemplates.

Full example of a %$form structure is below with all supported field types. Any other
forms you need to produce outside of this class should adopt that structure.  Also,
make sure your Tool mode calls for the 'interactive_form_elements' function to be
execute on load-up, so that some of the more interactive elements will get activated.

Form elements rendered via the 'form_elements.tt' Jemplated loaded up with by main
HTML skeleton page.

=cut

# feels like 1,000,000.0
$omnitool::omniclass::form_maker::VERSION = '6.0';

# time to grow up
use strict;

# kick off the routine to produce the form-info hash
sub form {
	# need myself and my args
	my $self = shift;
	my (%args) = @_;

	# declare vars
	my ($data_code, $form, $data_code_info, $field, $params_key);

	# Available Arguments:
	#	'action' => 'create' or 'update', defaulting to 'create' unless 'record' is filled
	#	'data_code' => data_code of record to load as presets for form; assumes 'update'
	#	'target_url' => target URI to submit the form into; defaults to $self->{luggage}{uri}
	#   'new_parent' => 'string',	# parent string of the data under which we will create data; for creates only
	#	'title'	 => Text to display above form; defaults to: ucfirst($args{action}.' a '.$self->{datatype_info}{name}
	#				datatype_hash tries to calculate 'a' or 'an'
	#	'submit_button_text'	=> I bet you can gueess; defaults to 'title' without the a/an
	#	'instructions'	=> text to display above form; defaults to $self->{datatype_info}{description}
	#	'hidden_fields'	=> ref to associative array of name=value pairs for the hidden fields
	#					  'record' and 'action' will be included by default
	#	'use_params_key' => if 1, will append record datacode (or 'new1') to field names
	#						useful for multi-record forms; if otherwise filled (not 0), will
	#						append that value to the field names
	#	'show_fields'	=> optional: comma-separated list of data_code ID's for the datatype_fields
	#						to build, and you should have 'name,' at the front to include the name
	#					    If blank, all fields are brought in; use this to create a 'mini' form.
	#						** If you use this, be sure to fill the 'skip_blanks' arg for saver(). **

	# sanity
	$data_code = $args{data_code}; # sanity

	# maybe they sent an altcode and it needs to be turned into a primary key?
	if ($data_code =~ /[a-z]/i) {
		($data_code) = $self->altcode_to_data_code($data_code);
	}

	# load up the record, if one was provided and we don't have it
	if ($args{data_code} && !$self->{records}{$data_code}{name}) {
		$self->load( 'data_codes' => [$data_code] );
	}

	# determine the 'action'
	if ($args{action} !~ /create|update/) { # not filled? determine reasonable default
		if ($self->{records}{$data_code}{name}) { # has a record, presume update
			$args{action} = 'update';
		} else { # no record = update
			$args{action} = 'create';
		}
	# if we are creating and have a record loaded, we are doing a 'create-from-another'
	} elsif ($args{action} eq 'create' && $self->{records}{$data_code}{name}) {
		$args{action} = 'create_from';
	}

	# determine our title
	if (!$args{title}) {
		if ($args{action} eq 'create_from') { # little more complex...make a nice phrase for create-from
			$self->{records}{$data_code}{name} = 'Another' if $self->{records}{$data_code}{name} =~ /^(Not Named|Unnamed)$/;
			$args{title} = 'Create '.$self->{datatype_info}{article}.' '.$self->{datatype_info}{name}.' from '.$self->{records}{$data_code}{name};
			$args{action} = 'create'; # simplify the submission process
		} else { # much simpler
			$args{title} = ucfirst($args{action}).' '.$self->{datatype_info}{article}.' '.$self->{datatype_info}{name};
		}
	}

	# submission button
	if (!$args{submit_button_text}) {
		if ($args{action} =~ /create/) {
			$args{submit_button_text} = 'Create '.$self->{datatype_info}{name};
		} else {
			$args{submit_button_text} = 'Update '.$self->{datatype_info}{name};
		}
	}

	# default instructions
	$args{instructions} = $self->{datatype_info}{description} if !$args{instructions};

	# make sure 'record' and 'action' are properly in the hidden fields
	if (!$args{hidden_fields}{action}) {
		$args{hidden_fields}{action} = $args{action};
	}
	if ($args{action} eq 'update' && !$args{hidden_fields}{record}) {
		$args{hidden_fields}{record} = $data_code;
	}
	if ($args{new_parent}) { # where are we going to place this
		$args{hidden_fields}{new_parent} = $args{new_parent};
	}

	# tell  omnitool::tool::action_tool to process our form
	$args{hidden_fields}{form_submitted} = 1;

	# default target_url to %$luggage{uri}
	$args{target_url} = $self->{luggage}{uri} if !$args{target_url};

	# normally, our field names will just match the table_column for their datatype_field,
	# but we may want to update multiple records in one form, so in that case, we will
	# need the field names tied to the records
	if ($args{use_params_key}) {
		# if it's 1 or 'yes', use the record datacode (or new1)
		if ($args{use_params_key} eq '1' || $args{use_params_key} =~ /^Yes$/i) {
			if ($args{action} =~ /create/ || !$data_code) {
				$args{the_params_key} = 'new1'; # JS may increment that '1'
			} elsif ($data_code) { # put in the proper $data_code ID
				$args{the_params_key} = $data_code;
			}

		# so long as it's not 'No', use that value as the extra bit for the field names
		# notice the flexibilty ;)
		} elsif ($args{use_params_key} !~ /^no$/i) {
			$args{the_params_key} = $args{use_params_key};
		}

		# now put that special key into our hidden fields, w/o the leading _
		$args{hidden_fields}{the_params_key} = $args{the_params_key};

		# make sure it ends with an underscore; modifying here before it gets loaded onto fields
		if ($args{the_params_key} && $args{the_params_key} !~ /^\_/) {
			$args{the_params_key} = $args{the_params_key}.'_';
		}

	}

	# convert %args into the beginning of our $form hashref
	$form = \%args;
	# the superfluous bits will be ignored ;)

	# if it has a parent, attach in the form for use in hooks
	if ($self->{metainfo}{$data_code}{parent}) {
		$$form{new_parent} = $self->{metainfo}{$data_code}{parent};

		# and use this new parent if one was not sent in
		$$form{hidden_fields}{new_parent} = $self->{metainfo}{$data_code}{parent}if !$$form{hidden_fields}{new_parent} ;
	}

	# finally time to add in the fields

	# but first ;) how about a hook opportunity to prepare for preparing the fields ;)
	if ($self->can('prepare_for_form_fields')) {
		$self->prepare_for_form_fields($form);
	}

	# crreate field_keys array reference in there for setup_field() to work properly
	$$form{field_keys} = [];

	# we are going to use a separate method to build them one at a time, for the sake
	# of separating some of this code and the possibility that we may want to build
	# just one field randomly later

	# if filled, $args{show_fields} will be a comma-delimited list of fields to provide
	# which is useful to limit the scope of this form
	# it would have the datatype_fields' data_codes, or perhaps 'name'

	# make sure to not show the name if we have those 'show_fields' and not the name
	if ($args{show_fields} && !$self->{belt}->really_in_list('name',$args{show_fields})) {
		$self->{datatype_info}{show_name} = 'No';
	}

	# alright, show the name first if it's permissible
	if ($self->{datatype_info}{show_name} eq 'Yes') {
		$self->setup_field('name',$form,$data_code);

	# it cannot be null though
	} else {
		$$form{hidden_fields}{name}  = 'Not Named';
	}

	# setup_field() will add to %{ $$form{fields} } and @{ $$form{field_keys} }


	# now go through the rest of the fields and build those
	foreach $field (@{ $self->{datatype_info}{fields_key} }) {
		# skip if 'show_fields' is filled and they didn't specify this field
		next if $args{show_fields} && !$self->{belt}->really_in_list($field,$args{show_fields});

		# skip virtual fields
		next if $self->{datatype_info}{fields}{$field}{virtual_field} eq 'Yes';

		# hidden field?
		if ($self->{datatype_info}{fields}{$field}{field_type} eq 'hidden_field') {

			# we the $params_key is for the field name and possible preset
			$params_key = $$form{the_params_key}.$self->{datatype_info}{fields}{$field}{table_column};

			# include it if there is a preset...
			if ($self->{luggage}{params}{$params_key}) { # PSGI params
				$$form{hidden_fields}{$params_key} = $self->{luggage}{params}{$params_key};
			# ...or a loaded-record preset
			} elsif ($self->{records}{$data_code}{$params_key}) { # loaded-record
				$$form{hidden_fields}{$params_key} = $self->{records}{$data_code}{$params_key};
			}

		# otherwise, call our friendly method again
		} else {
			$self->setup_field($field,$form,$data_code);
		}
	}

	# all for a 'post_form_operations' hook to munge the %$form structure before sending out -- DANGER / BE CAREFUL
	if ($self->can('post_form_operations')) {
		$self->post_form_operations($form);
	}


	# last step is to update the status log
	$data_code_info = ' / Record = '.$data_code if $data_code;
	$self->work_history(1,qq{Generated a form hashref.  Action = '$args{action}'}.$data_code_info);

	# return our form and we are done
	return $form;

}

# utility function to build the options hashref/arrayref based on a file path and file extension
# pass 'dir' for the second arg to look for sub-directories
# fill in third arg if you don't want to remove the file extension
sub options_from_directory {
	my $self = shift;
	my ($directory,$file_ext,$keep_ext) = @_;
	$file_ext ||= 'pm';
	return if !$directory;

	my ($dh, %options, @options_keys, $file, @files);

	# 'None' is first option
	$options{None} = 'None';
	push(@options_keys,'None');

	# ready them in the old fashioned way
	opendir($dh, $directory);
	@files = readdir ($dh);
	closedir $dh;
	foreach $file (sort(@files)) {
		# maybe they are looking for a directory?
		if ($file_ext eq 'dir' && (-d "$directory/$file")) {
			$options{$file} = $file;
			push(@options_keys,$file);
		# or a file with a certain extension
		} elsif ($file =~ /\.$file_ext$/) {
			$file =~ s/\.$file_ext// if !$keep_ext;
			$options{$file} = $file;
			push(@options_keys,$file);
		}
	}


    # return results
    return (\%options,\@options_keys);
}

# separate method to build the field info for a particular field
sub setup_field {
	my $self = shift;

	# declare variables
	my ($preset_value, $delimiter, $params_key, $key, $line, $name, $o, $option_values, $options_hook_method, $table_column, $value, $this_part, $part, @street_address_parts);

	# takes two args: the ID of the datatype_field (or 'name'), the %$form hashref,
	# and the ID for the loaded record we want to use
	# the rest will be in $self
	my ($field,$form,$data_code) = @_;
	return if !$field || !$form; # first two are required

	# we are going to key the %{$$form{fields}} with integers, so figure out which
	# one we are on
	$key = 1 + @{$$form{field_keys}};

	# make sure the keys are unique if in spreadsheet mode
	if ($$form{the_params_key}) {
		$key = $$form{the_params_key}.$key; # no longer an integer ;)
	}

	# add that key to our list
	push(@{$$form{field_keys}}, $key);

	# the name/title field is somewhat easy
	if ($field eq 'name') {

		$$form{fields}{$key} = {
			'title' => $self->{datatype_info}{name}.' Name',
			'name' => $$form{the_params_key}.'name',
			'field_type' => 'short_text',
			'is_required' => 1,
			# 'instructions' => 'Required.',
		};

		# figure name preset; more notes on presets below
		$params_key = $$form{the_params_key}.'name'; # sanity;
		if ($self->{luggage}{params}{$params_key}) { # PSGI params
			$$form{fields}{$key}{preset} = $self->{luggage}{params}{$params_key};

		} elsif ($self->{records}{$data_code}{name}) { # loaded-record
			$$form{fields}{$key}{preset} = $self->{records}{$data_code}{name};
		}

	# the rest is determined by the values set up in the datatype_fields table
	} else {
		# the title is pretty easy
		$$form{fields}{$key}{title} = $self->{datatype_info}{fields}{$field}{name};

		# we will want the table_column at hand for the field name and preset
		$table_column = $self->{datatype_info}{fields}{$field}{table_column};

		# the field name is usually just the table column, and we might include that extra params_key
		$$form{fields}{$key}{name} = $$form{the_params_key}.$table_column;

		# the field_type is very, very easy
		$$form{fields}{$key}{field_type} = $self->{datatype_info}{fields}{$field}{field_type};
		# 'short_text_encrypted' is actually 'short_text', as the encryption stuff happens on the server
		$$form{fields}{$key}{field_type} = 'short_text' if $$form{fields}{$key}{field_type} eq 'short_text_encrypted';

		# same for the instructions
		$$form{fields}{$key}{instructions} = $self->{datatype_info}{fields}{$field}{instructions};

		# whether or not the validate_form should enforce field requirements
		if ($self->{datatype_info}{fields}{$field}{is_required} eq 'Yes') {
			$$form{fields}{$key}{is_required} = 1;
			# $$form{fields}{$key}{instructions} = 'Required. '.$$form{fields}{$key}{instructions};
		}

		# if it's an encrypted field, note in the instructions
		if ($self->{datatype_info}{fields}{$field}{field_type} =~ /encrypt/) {
			$$form{fields}{$key}{instructions} = 'Encrypted Field. '.$$form{fields}{$key}{instructions};
		}

		# max_length is basically for short_text/short_text_clean fields
		$$form{fields}{$key}{max_length} = $self->{datatype_info}{fields}{$field}{max_length};
		# short_text_tags fields are 64KB
		$$form{fields}{$key}{max_length} = 63000 if $$form{fields}{$key}{field_type} eq 'short_text_tags';
		$$form{fields}{$key}{max_length} ||= 100; # default to 100 characters

		# the preset could be, in this order: a value in the PSGI params, the value already in
		# the record, or the default_value for the datatype field.  Something could be in the
		# PSGI params if (a) we previously tried to submit this form, (b) we set up some
		# start values in the calling action-tool method, or (c) we didn't clear out the
		# tool-display-options for this tool on last execute
		$params_key = $$form{the_params_key}.$table_column; # sanity;
		if ($self->{luggage}{params}{$params_key}) { # PSGI params
			$$form{fields}{$key}{preset} = $self->{luggage}{params}{$params_key};

		} elsif ($self->{records}{$data_code}{$table_column}) { # loaded-record
			$$form{fields}{$key}{preset} = $self->{records}{$data_code}{$table_column};

		} else { # default value for datatype field
			$$form{fields}{$key}{preset} = $self->{datatype_info}{fields}{$field}{default_value};
		}

		# if it's a date field with no preset, use today
		if ($$form{fields}{$key}{field_type} eq 'simple_date' && !$$form{fields}{$key}{preset}) {
			$$form{fields}{$key}{preset} = $self->{belt}->todays_date();
		}

		# if this is a street address, we have to break up our preset into the six parts
		# any saved portion will be already combined into one text block, each piece on its own line
		if ($$form{fields}{$key}{field_type} eq 'street_address') {
			(@street_address_parts) = split /\n/, $$form{fields}{$key}{preset};
			foreach $part ('street_one','street_two','city','state','zip','country') {
				$this_part = shift @street_address_parts; # need this whether we use it or not to stay in sync
				if ($self->{luggage}{params}{$params_key.$part}) { # already PSGI params
					$$form{fields}{$key}{presets}{$part} = $self->{luggage}{params}{$params_key.$part};
				} else { # any possible preset (would have been loaded in)
					$$form{fields}{$key}{presets}{$part} = $this_part;
				}
			}
		}

		# access_roles_select, check_boxes and multi_select fields have a little different structure for presets
		# take the comma-delimited list for those values and make a little sub-hash for form_elements.tt
		if ($$form{fields}{$key}{field_type} =~ /check_boxes|multi_select|access_roles_select/) {
			foreach $preset_value (split /,/, $$form{fields}{$key}{preset}) {
				# need it sorted and testable
				push(@{ $$form{fields}{$key}{preset_keys} },$preset_value);
				$$form{fields}{$key}{presets}{$preset_value} = 1;
			}
		}

		# selects, multi-selects, checkboxes, and radio buttons need to have options values
		# set up.  Please see the example field keyed '9' below for how these look.
		# If we are within a datatype subclass with a hook named 'options_'.$table_column,
		# then call that to construct our options info; otherwise, try for the
		# 'option_values' value for this datatype field
		$options_hook_method = 'options_'.$table_column;
		if ($self->can($options_hook_method)) {
			# should not have to pass any args, as $self is pretty rich already; pass target id + probable parent value
			($$form{fields}{$key}{options},$$form{fields}{$key}{options_keys}) = $self->$options_hook_method($data_code, $$form{new_parent});

		# access_roles_select fields rely on the access roles for this application
		} elsif ($$form{fields}{$key}{field_type} eq 'access_roles_select') {
			# use the method in our parent
			($$form{fields}{$key}{options},$$form{fields}{$key}{options_keys}) = $self->get_access_roles();

			# get an 'open' in there
			$$form{fields}{$key}{options}{Open} = 'Open Access';
			unshift(@{$$form{fields}{$key}{options_keys}}, 'Open');

		# otherwise a list in the field specification; could be just comma-separated,
		# double-semicolon-separated, or name=value pairs on separate lines
		} elsif ($self->{datatype_info}{fields}{$field}{option_values}) {
			$option_values = $self->{datatype_info}{fields}{$field}{option_values}; # sanity
			if ($option_values =~ /\n/) { # name=value on separate lines
				# fairly-standard parsing; start by breaking up by lines
				foreach $line (split /\n/, $option_values) {
					# then break by equals sign
					($name,$value) = split /=/, $line;
					# now feed it in
					$$form{fields}{$key}{options}{$name} = $value;
					push(@{ $$form{fields}{$key}{options_keys} }, $name);
					# if I were a real perl programmer, the last 10 lines would have been one line,
					# probably with no alphanumeric characters
				}

			} else { # ;;- or ,-delimited
				# figure out the delimier
				if ($option_values =~ /;;/) { # ;;-delimited
					$delimiter = ';;';
				} else { # assume ,-delimited
					$delimiter = ',';
				}

				# break it up and feed it in
				foreach $o (split /$delimiter/, $option_values) {
					$$form{fields}{$key}{options}{$o} = $o;
					push(@{ $$form{fields}{$key}{options_keys} }, $o);
				}
			}
		}
		# end options-handling
	} # end field-building
} # end method ;)

1;

__END__

Here is an example of a %$form structure which supports one of each of our
supported field types, usable with your form-creating Jemplates:

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
		'field_keys' => [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26],
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
				'class' => 'some_css_class', # for modal and full-screen forms only
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
