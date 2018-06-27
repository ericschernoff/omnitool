package omnitool::tool::display_options_manager;
# provides the functions needed to keep the display options (really PSGI params)
# between each execution and phase of a tool's display

# first time doing it this way, but have allowed this many times before
$omnitool::tool::display_options_manager::VERSION = '6.0';

# put your big kid shoes on
use strict;

# method to load-up, set-up, and re-save the display options
sub load_display_options {
	my $self = shift;

	my ($display_options_obj_name, $p);

	# did they send a saved display_option set to use?
	if ($self->{luggage}{params}{display_options_key}) { # yes, loading a saved search, from long-term table
		$self->load_display_options_hash($self->{luggage}{params}{display_options_key},'saved');
	} else { # see if we have a previously-saved options set for this window
		$self->load_display_options_hash($self->{display_options_key});
	}
	# that method populates into %{$self->{display_options}}

	# if nothing was retrieved, try to find one that works
	if (!keys %{$self->{display_options}}) {
		# see if they have a default display options set for this tool
		($display_options_obj_name) = $self->{db}->quick_select(
			'select object_name from '.$self->{display_options_saved}.
			" where username=? and tool_id=? and default_for_tool='Yes'".
			" order by expiration_time desc limit 1",
		[ $self->{luggage}{username}, $self->{tool_datacode} ] );

		if ($display_options_obj_name) { # a default search was found; load from 'saved' table
			$self->load_display_options_hash($display_options_obj_name,'saved');

		# if no default found, try to find their last-used display options
		# NOTE: This is why we clear it out for most tools
		} elsif (!$display_options_obj_name) {
			($display_options_obj_name) = $self->{db}->quick_select(
				'select object_name from '.$self->{display_options_cached}.
				" where username=? and tool_id=?".
				" order by expiration_time desc limit 1",
			[ $self->{luggage}{username}, $self->{tool_datacode} ] );

			# attempt to load if found
			if ($display_options_obj_name) {
				$self->load_display_options_hash($display_options_obj_name);
			}
		}
	}

	# at this point, load in any sent params to this %{$self->{display_options}}
	# so as to update this display options set
	foreach $p (keys %{ $self->{luggage}{params} } ) {
		next if !$self->{luggage}{params}{$p} && !$self->{luggage}{params}{multi}{$p}[0]; # skip blanks
		next if $p eq 'saved_name'; # skip the option to save the search
		next if $p eq 'via_quick_search'; # skip the notice that a quick search menu was used

		if ($self->{luggage}{params}{$p} eq 'DO_CLEAR') { # clearing out the preset
			delete($self->{display_options}{$p});
		} else { # just use the plain value
			$self->{display_options}{$p} = $self->{luggage}{params}{$p};
		}

	}
	# can't use $self->{belt}->{request}->parameters->keys because
	# that won't let me add in params in object_factory, which is the most fun

	# the data_id might get placed in there after the fact by object factory
	# but only on the first call to this tool
	if ($self->{altcode}) {
		$self->{display_options}{altcode} = $self->{altcode};
	}

	# we need to determine the current mode.  If they sent a 'tool_mode' param
	# (via the ui), it would be set; otherwise choose the default
	if (!$self->{display_options}{tool_mode}) {
		# use the default mode
		if ($self->{attributes}{default_mode}) {
			$self->{display_options}{tool_mode} = $self->{attributes}{default_mode};
		# maybe our admin didn't set a default mode; find the first one available
		} else {
			$self->{display_options}{tool_mode} = $self->{tool_configs_keys}{tool_mode_configs}[0];
		}
		# if no tool configue is specifed, there is going to be an error
	}

	# now save out that update display options set; pass the 'saved_name' param
	# in case they are looking to bookmark this search (will be blank otherwise)
	$self->save_display_options_hash($self->{luggage}{params}{saved_name});

}

# subroutine to load display options set in a standard way to reduce redundant code
sub load_display_options_hash {
	my $self = shift;
	my ($display_options_obj_name,$from_saved) = @_;

	# if $from_saved is filled, use our more long-term storage table
	my ($display_options_table);
	if ($from_saved) {
		$display_options_table = $self->{display_options_saved};
	# otherwise, the shorter-term (7-day) cache:
	} else {
		$display_options_table = $self->{display_options_cached};
	}

	# load it into my designated attribute
	$self->{display_options} = $self->{db}->hash_cache(
		'task' => 'retrieve',
		'object_name' => $display_options_obj_name,
		'db_table' => $display_options_table,
	);
}

# subroutine to save display options set back to the otstatedata database
sub save_display_options_hash {
	my $self = shift;

	# pass an argument to reset the display_options altogether
	my ($reset_display_options) = @_;

	if ($reset_display_options) { # they want to reset, see reset_search_options() in tool.pm
		$self->{display_options} = {
			'options_were_reset' => 1, # prevents defaulting to any default bookmark
		};
	} else { # clear that option in a regular save
		$self->{display_options}{options_were_reset} = 0;
	}

	# removed all the bookmark / save-out code as the bookmark sub-system handles
	# this with bookmark_broker.pm
	# commit the save now
	$self->{db}->hash_cache(
		'task' => 'store',
		'hashref' => $self->{display_options},
		'object_name' => $self->{display_options_key},
		'db_table' => $self->{display_options_cached},
		'max_lifetime' => 604800, # one week time to live
		'extra_fields' => {
			'username' => $self->{luggage}{username},
			'tool_id' => $self->{tool_datacode},
		}
	);

}

# subroutine to clear out the display options set from cache only
sub clear_display_options_hash {
	my $self = shift;

	# we are going to destroy everything except the altcode, in case they come back
	if (!$self->{display_options}{altcode}) { # safe to just delete
		# pretty straightforward
		$self->{db}->do_sql(
			'delete from '.$self->{display_options_cached}.' where username=? and tool_id=? and object_name=?',
			[$self->{luggage}{username}, $self->{tool_datacode}, $self->{display_options_key}]
		);

	# otherwise, save the altcode
	} else {
		my $altcode = $self->{display_options}{altcode};
		$self->{display_options} = {};
		$self->{display_options}{altcode} = $altcode;
		# i am sure there is a one-liner for this

		# do the save, above
		$self->save_display_options_hash();
	}

}

# utility method to get my parent tool's last-saved display options; useful when preparing certain
# form fields based on selections above the current level
sub get_parent_tools_display_options {
	my $self = shift;

	my ($this_tool_data_code, $parent_tool_datacode, $display_options_obj_name, $display_options);

	# get my data_code
	($this_tool_data_code = $self->{tool_and_instance}) =~ s/$self->{luggage}{app_instance}_//;

	# get my parent tool's data_code
	($parent_tool_datacode = $self->{luggage}{session}{tools}{$this_tool_data_code}{parent}) =~ s/8_1://;

	# construct the object name for the parent tool's saved display options
	$display_options_obj_name = $self->{luggage}{params}{client_connection_id}.'_'.$parent_tool_datacode,

	# retrieve those options
	$display_options = $self->{db}->hash_cache(
		'task' => 'retrieve',
		'object_name' => $display_options_obj_name,
		'db_table' => $self->{luggage}{database_name}.'.tools_display_options_cached',
	);

	# ship them back
	return $display_options;
}

1;
