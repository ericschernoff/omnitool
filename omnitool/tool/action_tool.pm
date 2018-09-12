package omnitool::tool::action_tool;
# Tries to create some structure / order for your custom Action Tool sub-classes
# All Action Tools must have a proper sub-class chosen to work.  We provide some
# 'core' ones (create, update, delete, display), and you will surely need many
# more...assuming you don't just use Catalyst instead
#
# run_action() tries to call your methods in the order in which they be called
# based on what they *should* do.  I say 'should,' because I can only control
# the names; these are custom methods and can get crazy at your discretion.
# Remember that all of the display power is in the Template/Jemplate file for
# our view mode, so
#
# Also includes unlock_data() method which is called when omnitool_routines.js
# hides a locking tool.

$omnitool::tool::action_tool::VERSION = '6.0';

# time to grow up, old man
use strict;

# for tool access testing
use Data::Dumper;

# our main event: execute an action tool properly
sub run_action {
	my $self = shift;

	# declare vars
	my ($link_match_string, $data_code, $parent_tool_type, $lock_result, $parent_type, $lock_user,$lock_remaining_minutes,$record_name, $parent_altcode, $parent_tool_datacode, $parent_tool_datatype, $match_col, $match_col_name, $no_access, $this_match);

	# we need provide the title and uri for jemplate to show a return link, and we should do that first

	# for message/modal tools, we will want to show the URL we came from, the last-used Tool, which is sent via
	# get_tool_id_for_uri() in omnitool_routines.js, and this is most useful when tools share the inline actions
	# with their parent search.  However, we do not want a tool to link back to itself or get caught in a loop,
	# so apply this logic:
	if ($self->{attributes}{tool_type} =~ /Message|Modal/ && $self->{display_options}{return_tool_id} =~ /\d/ && $self->{display_options}{return_tool_id} ne $self->{tool_and_instance}) {
		($parent_tool_datacode = $self->{display_options}{return_tool_id}) =~ s/$self->{luggage}{app_instance}_//;

	# if any tests fail there, get the parent tool's URI.  This is often where they came from anyway.
	} else {
		($parent_tool_datacode = $self->{attributes}{parent}) =~ s/8_1://;
	}

	# the parent tool is the return link, unless there is no parent
	if ($self->{luggage}{session}{tools}{$parent_tool_datacode}{uri_path_base}) {
		$self->{json_results}{return_link_uri} = '#/tools/'.$self->{luggage}{session}{tools}{$parent_tool_datacode}{uri_path_base};
		$self->{json_results}{return_link_title} = $self->{luggage}{session}{tools}{$parent_tool_datacode}{name};

	} else { # in which case, the current tool is the return; think a top-level singleton
		$self->{json_results}{return_link_uri} = '#/tools/'.$self->{attributes}{uri_path_base};
		$self->{json_results}{return_link_title} = $self->{attributes}{name};
	}

	# so the previous/next buttons can work
	$self->{json_results}{parent_tool_id} = $self->{luggage}{app_instance}.'_'.$parent_tool_datacode;
	$self->{json_results}{datatype_name} = $self->{omniclass_object}{datatype_info}{name};
	# also provide a base uri for grabbing json for this tool
	# handy for the jemplates
	$self->{json_results}{my_json_uri} = $self->{my_json_uri};

	# determine the altcode of the target data record for the return link uri
	# if this is a Create Data tool, use the record/toool altcode as the parent for return
	if ($self->{attributes}{uri_path_base} =~ /(create|create_from)$/) {
		$parent_altcode = $self->{display_options}{altcode};

	# if it's a quick-action tool, best bet is to use the current altcode for the return link
	} elsif ($self->{display_options}{altcode} && $self->{attributes}{link_type} eq 'Quick Actions') {
		$self->{json_results}{return_link_uri} .= '/'.$self->{display_options}{altcode};

	# otherwise, figure out the parent of our current data, as we were operating on the parent
	} elsif ($self->{display_options}{altcode}) {

		# dig out the target datatype of that parent tool from the session; i am sorry for how complex this is
		$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_tool_datacode}{target_datatype};
		$parent_tool_type = $self->{luggage}{session}{tools}{$parent_tool_datacode}{tool_type};
		($record_name, $parent_altcode, $parent_type) = $self->{altcode_decoder}->name_and_parent_from_altcode($self->{display_options}{altcode},$parent_tool_datatype);
		# include this altcode with this uri, since we are not in create

		# add that $parent_altcode if it was found
		if ($parent_altcode && $record_name) {
			# if the parent tool is searching, it's type doesn't have to be that of the parent (long story)
			if ($parent_tool_type =~ /Search/ || $parent_tool_datatype eq $parent_type) {
				$self->{json_results}{return_link_uri} .= '/'.$parent_altcode; 
			}
		}
	}

	# if there is a valid altcode (current working data), we need to turn that into a data_code
	# since we have an omniclass-object. we can use its built-in routine
	if ($self->{display_options}{altcode}) {
		($data_code) = $self->{omniclass_object}->altcode_to_data_code( $self->{display_options}{altcode} );
		# if it found a record, load it up
		if ($data_code) {
			$self->{omniclass_object}->load('data_codes' => [$data_code]);
			# should be the only record in there, so it'll be available under $self->{omniclass_object}->{data}

			# we also want to provide info about any current lock
			($lock_user,$lock_remaining_minutes) = $self->{omniclass_object}->check_data_lock($data_code);
			# this is also used below

			# just send the user for now
			$self->{json_results}{lock_user} = $lock_user;

			# test if they have defined a 'link_match_string' value for this tool, and make sure this data still qualifies
			$no_access = 0;
			if ($self->{attributes}{link_match_string}) {
				$link_match_string = $self->{attributes}{link_match_string};
				$no_access = 1 if !$self->{omniclass_object}->{data}{tool_access_strings}{$link_match_string};
			}

			# if they failed the test, block them
			if ($no_access) {
				$self->{json_results}{error_title} = $self->{attributes}{name}.' Unavailable for '.$self->{display_options}{altcode};
				$self->{json_results}{show_error_modal} = 1;
				$self->{json_results}{form_was_submitted} = 1; # blocks the form from showing
				# load any inline actions before we short-circuit (utility method below)
				$self->get_inline_actions_for_action_tool();
				# short-circuit
				return;
			}

		# otherwise, we need to register an error for the jemplate
		} else {
			$self->{json_results}{data_not_found} = 1;
		}
	}

	# if this is a locking tool and there is not lock_lifetime, default to the
	# application, failing that, to the datatype; and failing that, five minutes
	if ($self->{attributes}{is_locking} eq 'Yes' && !$self->{attributes}{lock_lifetime}) {
		if ($self->{luggage}{session}{app_instance_info}{lock_lifetime}) { # try application
			$self->{attributes}{lock_lifetime} = $self->{luggage}{session}{app_instance_info}{lock_lifetime};

		} elsif ( $self->{omniclass_object}{datatype_info}{lock_lifetime} ) { # then datatype
			$self->{attributes}{lock_lifetime} = $self->{omniclass_object}{datatype_info}{lock_lifetime};

		} else { # then default to five minutes
			$self->{attributes}{lock_lifetime} = '5';
		}
	}

	# is this a locking tool with a altcode?  if so, lock it up up here
	# and un-lock below, if so instructed
	if ($self->{attributes}{is_locking} eq 'Yes' && $data_code) {
		$lock_result = $self->{omniclass_object}->lock_data(
			'data_code' => $data_code,
			'lifetime' => $self->{attributes}{lock_lifetime} + 2
		);
		# if it failed to lock, we need to error-out with the problem message
		if (!$lock_result) { # get the user who has it, and how long
			$self->{json_results}{error_title} = $self->{attributes}{name}.' Unavailable for '.$self->{omniclass_object}->{data}{name};
			$self->{json_results}{error_message} = qq{Record is Locked by  $lock_user for Another $lock_remaining_minutes Minutes.};
			$self->{json_results}{form_was_submitted} = 1; # blocks the form from showing
			# load any inline actions before we short-circuit; utility method is below
			$self->get_inline_actions_for_action_tool();
			# short-circuit
			return;
		}
	}

	# the next three method calls are effectively for hooks which should be in your sub-class
	# They *should* do what their title implies, but I trust you to make the right decisions

	# conceiveably, an Action Tool could have all three of these methods, but it is unlikely

	# the 'perform_action' method would be for a 'dumb' action which really does not require
	# any input other than accessing it, i.e. Flushing All Sessions for an Application Instance
	if ($self->can('perform_action')) {
		$self->perform_action();
	}
	# this could/should have filled $self->{json_results}{title} / $self->{json_results}{message},
	# and more at your discretion

	# the 'prepare_message' method would be for a 'lazy' and 'dumb' action, which is for
	# presenting some information about the record in $data_code; I feel like perform_action()
	# is for Action Tools which involve changing data, and prepare_message() is just for
	# reading in (SELECT's)
	# this could just be the results routine for perform_action(), but that seems like overkill
	if ($self->can('prepare_message')) {
		$self->prepare_message();
	}
	# this could/should have filled $self->{json_results}{title} / $self->{json_results}{message},
	# and more at your discretion

	# the 'generate_form' method is for building the %$form structures to describe how Jemplate
	# should render the form; it should be called even if we are accepting the form submission,
	# as it is used by validate_form() below; see the bottom of mnitool::omniclass::form_maker
	# for a complete example of how %$form can look

	if ($self->can('generate_form')) {
		$self->generate_form();
	}
	# this could/should have filled $self->{json_results}{form} with %$form, and more at your discretion

	# if we are accepting a form submission, the 'form_submitted' field should be filled (usually hidden)
	if ($self->{luggage}{params}{form_submitted}) {

		# the stock 'validate_form' method is below, and you can feel free to override it
		# it's job is to check your form to see that the required fields where filled-in
		# and the special fields (email_addres, web_url, phone_number) have valid data.
		# It will mark up $self->{json_results}{form} in place with the notices needed,
		# and will set $self->{stop_form_action} to 1 to block perform_form_action().
		$self->validate_form();

		# and omniclass.pm hook opportunity to un-do/augment the results of validate_form();
		if ($self->{omniclass_object}->can('post_validate_form')) {
			# have to pass in the form hashref and get a return value
			$self->{stop_form_action_dt} = $self->{omniclass_object}->post_validate_form( $self->{json_results}{form} );

			# only overwrite first value if DT routine got angry
			$self->{stop_form_action} = 1 if $self->{stop_form_action_dt};

		}

		# tool.pm hook opportunity to un-do/augment the results of validate_form();
		if ($self->can('post_validate_form')) {
			$self->post_validate_form( $self->{json_results}{form} );
		}

		# $self->{belt}->logger('Past form validation -- '.$self->{stop_form_action},'test');

		# try for 'perform_form_action' to process form, if $self->{stop_form_action}==0
		if (!$self->{stop_form_action} && $self->can('perform_form_action')) {
			$self->perform_form_action();
			# unless they want to show the form again, prevent form re-display
			if (!$self->{redisplay_form}) {
				$self->{json_results}{form} = {};
			}
			# clear the display options so we get a fresh form next time - unless they tell us not to
			$self->{clear_display_options} = 1 if !$self->{do_not_clear_display_options};

		} elsif ($self->{stop_form_action}) {
			# they can specify their own message in post_validate_form()
			$self->{json_results}{form}{error_title} ||= 'Please correct errors below.';

		} elsif (!$self->can('perform_form_action')) {
			$self->{json_results}{form}{error_title} = 'Form Can Not Be Submitted at This Time.';

		}
		# this could/should have filled $self->{json_results}{title} / $self->{json_results}{message},
		# and more at your discretion.
		# NOTE: All Web UI forms should be submitted via the 'submit_form()' JavasScript
		# function in omnitool_routines.js. That has logic such that if you fill
		# $self->{json_results}{make_gritter_notice} in your perform_form_action() method,
		# the modal or screen will go back to the previous / calling Tool, and display
		# $self->{json_results}{title} / $self->{json_results}{message} in a centered gritter notice
	}

	# if this is a message display action, we need to instruct the gritter notification on how
	# long to stay up there.  Please set these in your sub-clss, but just in case
	$self->{json_results}{message_is_sticky} = $self->{attributes}{message_is_sticky};
		$self->{json_results}{message_is_sticky} ||= 'No'; # if 'Yes', stays alive forever
	$self->{json_results}{message_time} = $self->{attributes}{message_time} * 1000;
		$self->{json_results}{message_time} ||= '15000'; # default 15-seconds display

	# if the title is blank, default to the tool name
	$self->{json_results}{title} ||= $self->{attributes}{name};

	# this plays into all kinds of javascript, plus it's a comforting presence in the JSON results
	if (!$self->{skip_primary_record}) { # some tools won't want this for the refreshes
		$self->{json_results}{altcode} ||= $self->{display_options}{altcode};
		$self->{json_results}{data_code} ||= $self->{omniclass_object}->{data_code};
	}
	
	# support the modal mode by default
	$self->{json_results}{modal_title} = $self->{json_results}{title};
	$self->{json_results}{modal_title_icon} = $self->{attributes}{icon_fa_glyph};

	# clean-up time: clear the data lock if $self->{unlock} is set and $data_code is filled
	# 	$self->{unlock} would be set by the custom code
	if ($self->{unlock} && $data_code) {
		$lock_result = $self->{omniclass_object}->unlock_data(
			'data_code' => $data_code,
		);
	# if this is a locking tool but $self->{unlock} was not set, we need to send the lock_lifetime for our timer
	} elsif ($self->{attributes}{is_locking} eq 'Yes' && $data_code) {
		$self->{json_results}{lock_lifetime} = $self->{attributes}{lock_lifetime};
	}

	# lastly, we are going to support inline actions under Action Tools using tool::searcher::get_inline_actions()
	# set up your jemplates as appropriate to support this; I am thinking specifically that this is
	# good for View Details screens via complex_details.tt
	# doing this last because the data may have changed during this execute, and we want the latest
	# and greatest inline actions (which can be displayed / hidden based on the data)

	# load the inline actions via utility method below
	$self->get_inline_actions_for_action_tool();

	# and pack them up
	$self->{json_results}{inline_actions} = $self->{omniclass_object}->{data}{inline_actions};

	# REMEMBER: Set $self->{clear_display_options} to clear the cached display options
	# when is appropriate -- i.e. successful form submission

}

# start standard method to validate the content provided in a form, and mark-up
# $self->{json_results}{form} as needed
sub validate_form {
	my $self = shift;

	# declare vars
	my ($params_key, $param_name, $field_type, $field);

	# is there a special params key?
	if ($self->{luggage}{params}{the_params_key}) {
		$params_key = '_'.$self->{luggage}{params}{the_params_key};
	}

	# go through the fields and look for empty-but-required fields or malformed data
	foreach $field (@{ $self->{json_results}{form}{field_keys} }) {
		# sanity-reduce the params name for this field
		$param_name = $self->{json_results}{form}{fields}{$field}{name};

		# reduce-down the field_type as well
		$field_type = $self->{json_results}{form}{fields}{$field}{field_type};

		# first check the special-formatting fields
		# stealing regexp's from http://www.runningcoder.org/jqueryvalidation/documentation/
		# web address -- only if it's filled
		if ($field_type eq 'web_url' && $self->{luggage}{params}{$param_name} && $self->{luggage}{params}{$param_name} !~ /^(https?:\/\/)?((([a-z0-9]-*)*[a-z0-9]+\.?)*([a-z0-9]+))(\/[\w?=\.-]*)*$/) {
			$self->{json_results}{form}{fields}{$field}{field_error} = 1; # jemplate will handle properly

			# try to block form processing
			$self->{stop_form_action} = 1;

		# email address
		} elsif ($field_type eq 'email_address' && $self->{luggage}{params}{$param_name} && $self->{luggage}{params}{$param_name} !~ /^([^@]+?)@(([a-z0-9]-*)*[a-z0-9]+\.)+([a-z0-9]+)$/i) {
			$self->{json_results}{form}{fields}{$field}{field_error} = 1; # jemplate will handle properly

			# try to block form processing
			$self->{stop_form_action} = 1;

		# phone number is a little softer, for now
		} elsif ($field_type eq 'phone_number' && $self->{luggage}{params}{$param_name} && $self->{luggage}{params}{$param_name} !~ /\d\d\d\d/) {
			$self->{json_results}{form}{fields}{$field}{field_error} = 1; # jemplate will handle properly

			# try to block form processing
			$self->{stop_form_action} = 1;

		# making a street address required means requiring the 'street_one part be filled
		} elsif ($self->{json_results}{form}{fields}{$field}{is_required} && $field_type eq 'street_address' && !$self->{luggage}{params}{$param_name.'_street_one'}) {
			$self->{json_results}{form}{fields}{$field}{field_error} = 1; # jemplate will handle properly

			# try to block form processing
			$self->{stop_form_action} = 1;

		# test all others fields for presence: has to be filled and not just be white space
		} elsif ($self->{json_results}{form}{fields}{$field}{is_required} && (!$self->{luggage}{params}{$param_name} || $self->{luggage}{params}{$param_name} !~ /\S/)) {
			$self->{json_results}{form}{fields}{$field}{field_error} = 1; # jemplate will handle properly

			# try to block form processing
			$self->{stop_form_action} = 1;
		}
	}

}

# utility method for unlocking data; used when hiding a locking tool in omnitool_routines.js
sub unlock_data {
	my $self = shift;
	my ($data_code, $lock_result, $unlock_altcode);

	# was an altcode sent explicitly?
	if ($self->{luggage}{params}{unlock_altcode}) {
		$unlock_altcode = $self->{luggage}{params}{unlock_altcode};

	# or in our display options?
	} elsif ($self->{display_options}{altcode}) {
		$unlock_altcode = $self->{display_options}{altcode};

	}

	# proceed if an altcode was sent, either via URI or GET params
	if ($unlock_altcode) {
		# need an omniclass object, since we came straight from execute_method
		$self->get_omniclass_object( 'dt' => $self->{attributes}{target_datatype} );

		# identify the data_code; maybe not strictly necessary
		($data_code) = $self->{omniclass_object}->altcode_to_data_code( $unlock_altcode );
		# if it found a record, just unlock it, no need to load up
		if ($data_code) {
			$lock_result = $self->{omniclass_object}->unlock_data(
				'data_code' => $data_code,
			);
			# output plain text message
			return qq{Success: $unlock_altcode was unlocked.};
		} else { # return error
			return qq{Error: $unlock_altcode was not found in $self->{luggage}{database_name}.};
		}
	} else { # return error if no altcode sent
		return qq{Error: No data ID / altcode sent.};
	}
}

# uitlity method to extend the lock on this data, to allow them to continue their case updates forever
sub extend_lock {
	my $self = shift;
	
	# we need the omniclass object
	$self->get_omniclass_object( 'dt' => $self->{target_datatype} );	
	
	# translate that altcode to a data-code
	my $data_code = $self->{omniclass_object}->altcode_to_data_code( $self->{luggage}{params}{altcode} );
	
	# extend the lock out and pad the lock by three minutes to accomodate the transfer and the 'lock warning routine'
	my $lock_result = $self->{omniclass_object}->lock_data(
		'data_code' => $data_code,
		'lifetime' => int($self->{luggage}{params}{extend_lock_seconds}/60) + 3,
	);
		
	return {
		'message' => 'Lock was extended.'
	}

}


# utility method to retrieve and pack-up the inline actions information; please see notes towards
# the end of run_action(); this is a two-step process right now, but no need to repeat ourselves
# above (and this may grow)
# this depends on the record being loaded in $self->{omniclass}->{data}, so please don't call before
# loading that up
sub get_inline_actions_for_action_tool {
	my $self = shift;

	# load the inline actions from searcher.pm
	delete($self->{omniclass_object}->{data}{inline_actions}); # make sure they are clear, in case we loaded elsewhere
	$self->get_inline_actions();

	# and pack them up
	$self->{json_results}{inline_actions} = $self->{omniclass_object}->{data}{inline_actions};
}

# and a reusable routine to determine the target parent for new data; mostly used by standard_data_actions
sub figure_new_parent {
	my $self = shift;

	my ($action_arg) = @_; # if it's 'create,' we need the grandparent

	my ($tool_datacode, $parent_tool_datacode, $parent_tool_datatype, $new_parent_string);

	# maybe it goes at the top?
	if ($self->{display_options}{altcode} eq 'null' || !$self->{display_options}{altcode}) {
		$new_parent_string = 'top';

	# if the tool has an altcode, use fetch the info from common::altcode_decoder using
	# our uri's altcode and the datatype of the parent tool
	} elsif ($self->{display_options}{altcode}) {
		# the altcode for this tool is actually the data_code of the proposed parent
		$tool_datacode = $self->{tool_datacode};
		($parent_tool_datacode = $self->{luggage}{session}{tools}{$tool_datacode}{parent}) =~ s/8_1://;
		# dig out the target datatype of that parent tool from the session; i am sorry for how complex this ios
		$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_tool_datacode}{target_datatype};

		# if they sent a data_code, e.g. 423_2, then life is easy
		# this comes into play when you have the single-row-refresh tools
		if ($self->{display_options}{altcode} =~ /^\d+\_\d+$/) {
			$new_parent_string = $parent_tool_datatype.':'.$self->{display_options}{altcode};
		# or if they sent a 'proper' altcode, e.g. Mar17echernofRTP001, then perform the query
		} else {

			# if we are creating, we actually need the grand-parent tool
			if ($action_arg eq 'create') {
				($parent_tool_datacode = $self->{luggage}{session}{tools}{$parent_tool_datacode}{parent}) =~ s/8_1://;
				$parent_tool_datatype = $self->{luggage}{session}{tools}{$parent_tool_datacode}{target_datatype};
			}

			($new_parent_string) = $self->{altcode_decoder}->parent_string_from_altcode($self->{display_options}{altcode}, $parent_tool_datatype);
		}
	}

	# default to top, if all else fails
	$new_parent_string ||= 'top';

	# and return
	return $new_parent_string;
}

# method to power the auto-suggest for autocomplete & tags fields
sub autocomplete_suggester {
	my $self = shift;

	# little kludge to support short_text_tags/short_text_autocomplete fields in spreadsheet mode
	$self->{luggage}{params}{server_side_method_name} =~ s/^(\d+\_\d+\_|new\_)//;

	# what is the actual name of the method we need to call?
	my $method_name = 'autocomplete_'.$self->{luggage}{params}{server_side_method_name};

	# if i have a built-in method, use that
	if ($self->can($method_name)) {
		return $self->$method_name();
	}

	# still here?  try to call the method from the omniclass obkect
	$self->get_omniclass_object( 'dt' => $self->{target_datatype} );
	if ($self->{omniclass_object}->can($method_name)) {
		# tell them about the current altcode, if we have one
		return $self->{omniclass_object}->$method_name( $self->{display_options}{altcode} );
	}

	# if that falls, log out an error and return an empty array
	$self->{belt}->logger('ERROR: '.$method_name.' does not exist.',$self->{log_type});
	return [];
}

# very generic trigger menu handler, which presumes a trigger_menu_options()
# method in your omniclass object; meant for use in the standard create/update form
sub standard_form_trigger_menu_options {
	my $self = shift;

	# we need the omniclass object
	$self->get_omniclass_object( 'dt' => $self->{target_datatype} );

	# and then use the 'trigger_menu_options' method in there
	$self->{json_results} = $self->{omniclass_object}->trigger_menu_options();

	# done ;)
	return $self->{json_results};

}


1;

