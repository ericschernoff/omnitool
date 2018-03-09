package omnitool::common::object_factory;
# class meant to figure out which tool or datatype class we need to use
# for creating objects.  Meant to be initiated by main handler / root of script
# and passed to the tool object.
# See perldoc info below for more details

$omnitool::common::object_factory::VERSION = '1.0';

# load base modules
use omnitool::omniclass;
use omnitool::tool;
use omnitool::tool::standard_data_actions; # for the standard create/update functions
use omnitool::tool::singleton_data_actions; # for the singleton create/update functions
use omnitool::tool::standard_delete; # for the standard delete function
use omnitool::tool::subform_data_actions; # for the subforms create/update functions
use omnitool::tool::basic_data_view; # for the standard view functions
use omnitool::tool::view_details; # for displaying complex data details via complex_details_tabs_shared.tt
use omnitool::tool::basic_calendar; # for a super-basic calendar
use omnitool::tool::setup_diagram; # for vis.js network diagrams
use omnitool::tool::call_named_method; # runs a action-message tool using an omniclass method named for the tool's uri_base_path
use omnitool::tool::button_menu; # very simple panel to display buttons for subordinate menubar tools

# time to grow up, wheneve possible
use strict;

use Storable qw(dclone);
$Storable::forgive_me = 1;

sub new {
	my $class = shift;
	# main thing we need is a packed luggage, though we can use an alternative $db object
	# if they want; luggage will have the user session, which is pretty key
	my ($luggage,$db) = @_;

	# die without proper $luggage or $db
	if (!$$luggage{belt}->{all_hail}) {
		# have to die here, and kind of have to do it without mr_zebra, as they probably
		# passed no $$luggage for a reason
		print qq{Can't create a Class Factory without my luggage.'};
		exit;
	}

	# did they provide a $db? if not, use $self->{luggage}{db}
	if (!$db) {
		$db = $$luggage{$db};
	}

	my $self = bless {
		'db' => $db,
		'luggage' => $luggage,
	}, $class;
}

# subroutine to load a datatype/omniclass class based on the datatype_id
sub omniclass_object {
	my $self = shift;

	# we will accept the same arguments as omniclass->new() will accept, as those will
	# be passed to our new omniclass/datatype object
	my (%args) = @_;

	# declare local vars
	my ($parent, $dt, $possible_table_name, $omniclass_object, $app_instance, $just_the_data, $app_code_directory, $class_name, $class_path);

	if (!$args{dt}) {
		$self->{luggage}{belt}->mr_zebra(qq{Can't create an OmniClass without a datatype ID. (DT: $dt)},1);
	}

	# sanity
	$dt = $args{dt};

	# make sure we have the luggage in the args
	if (!$args{luggage}) {
		$args{luggage} = $self->{luggage};
	}

	# perhaps they provided a table name for the 'dt', in which case we resolve that
	# to the datatype; makes it easier as you might know the table name rather than the
	# datatype ID
	if ($dt =~ /[a-z]/i) {
		$possible_table_name = lc($args{dt});
		$dt = $self->{luggage}{datatypes}{table_names_to_ids}{$possible_table_name};
	}

	# make 100% sure they passed a valid datatype ID
	if (!$self->{luggage}{datatypes}{$dt}{table_name}) {
		$self->{luggage}{belt}->mr_zebra(qq{Can't create an OmniClass without a valid datatype ID. (DT: $dt)},1);
	}

	# does this datatype have a perl module specified?
	if ($self->{luggage}{datatypes}{$dt}{perl_module} && $self->{luggage}{datatypes}{$dt}{perl_module} ne 'None') { # yes, load it up

		# figure out the perl module durectory for the current application/instance
		$app_instance = $self->{luggage}{app_instance}; # sanity
		$app_code_directory = $self->{luggage}{session}{app_instance_info}{app_code_directory};

		# now the module's name in perl-space
		$class_name = 'omnitool::applications::'.$app_code_directory.'::datatypes::'.$self->{luggage}{datatypes}{$dt}{perl_module};
		# and in the file system
		$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/datatypes/'.$self->{luggage}{datatypes}{$dt}{perl_module}.'.pm';

		# load it in - log out if error
		unless (eval "require $class_name") {
			$self->{luggage}{belt}->mr_zebra("Could not import $class_name: ".$@,1);
		}
		# require $class_path;

		# and create the object
		$omniclass_object = $class_name->new(%args);

	} else { # easy omniclass module
		$omniclass_object = omnitool::omniclass->new(%args);
	}

	# if they want to go into tree mode, call datatype_tree; see notes in perldoc below
	if ($args{tree_mode}) {
		$args{tree_mode} = 0; # only do this at top level
		$self->omniclass_tree($omniclass_object,%args);
	}

	# maybe they just want the data?
	$parent = ( caller(1) )[3]; # make sure we are not doing this from within the tree-building
	if ($parent !~ /omniclass_tree/ && $omniclass_object->{records_keys}[0] && ($args{return_extracted_data} || $args{cache_extracted_data})) {
		# do they want to skip metainfo for this?
		if ($args{extractor_skip_metainfo}) {
			$self->{extractor_skip_metainfo} = 1;
		}

		# take out the data
		$just_the_data = $self->omniclass_data_extractor($omniclass_object);

		# reset for next run
		$self->{extractor_skip_metainfo} = 0;

		# they want to cache the data somewhere; see notes in omnitool::common::db
		if ($args{cache_extracted_data}) {
			$$just_the_data{build_time} = time(); # so we know how old it is
			$self->{luggage}{db}->hash_cache(
				'task' => 'store',
				'hashref' => $just_the_data,
				'object_name' => $args{cache_extracted_data},
				'location' => $args{cache_extracted_data_location},
				'directory' => $args{cache_extracted_data_directory},
				'db_table' => $args{cache_extracted_data_db_table},
			);
		}

		# they just want the plain hash back
		if ($args{return_extracted_data}) {
			return $just_the_data;
		}

		# see notes below; it's possible to cache the data and get the real object too
	}

	# ship it out
	return $omniclass_object;
}

# method to create a tree of omniclass objects
sub omniclass_tree {
	my $self = shift;

	# we will accept the all the same arguments as omniclass->new() will accept, as those will
	# be passed to our new omniclass/datatype object
	# the exception is that we expect a 'parent_object' argument, which is the omniclass object
	# of the record under which we want to build our tree
	my ($parent_object,%args) = @_;

	# they may have loaded the first / top object with search_options, but that would really mess us up down here, so...
	$args{search_options} = '';

	# declare our variables
	my (%all_children_by_type, %all_records_by_type, $child_data_code, $child_record, $cloning_objects, $child_table, $child_type, $child, $loader_objects, $possible_table_name, $r, $record, $translated_tree_dts, $tree_datatype, $tree_dt);

	# return silently if there is no parent object
	return if !$parent_object;
	return if !($parent_object->isa("omnitool::omniclass"));

	# they can have a 'tree_datatypes' arg to limit which datatypes we will tree into
	# allow that to be a table name or datatype code
	if ($args{tree_datatypes}) {
		foreach $tree_dt (split /,/, $args{tree_datatypes}) {
			# go so far as to allow some to be codes and others to be table names
			if ($tree_dt =~ /[a-z]/i) {
				$possible_table_name = lc($tree_dt);
				push(@$translated_tree_dts,$self->{luggage}{datatypes}{table_names_to_ids}{$possible_table_name});
			} else { # plain codes
				push(@$translated_tree_dts,$tree_dt);
			}
		}
		# replace the arg with the new list
		$args{tree_datatypes} = $self->{luggage}{belt}->comma_list($translated_tree_dts);
	}

	# Let us attempt to make this faster. We want to load all data for each tree_datatype
	# at once, and then assign it into the appropriate objects within the tree below

	# first, get the complete list of children records for each record and tree_datatype
	foreach $record (@{$parent_object->{records_keys}}) {
		foreach $child (split /,/, $parent_object->{metainfo}{$record}{children}) {
			($child_type,$child_data_code) = split /:/, $child;
			# all_children_by_type is where we will keep the children sorted by parent and type
			push(@{$all_children_by_type{$record}{$child_type}}, $child_data_code);
			# and all_records_by_type is where we will keep all children, just sorted by type
			push(@{$all_records_by_type{$child_type}}, $child_data_code);
		}
	}

	# now load up the records for each tree type
	foreach $tree_datatype (split /,/, $args{tree_datatypes}) {
		next if !$all_records_by_type{$child_type}[0];

		# load up these records all at once
		$args{dt} = $tree_datatype;
		$args{data_codes} = $all_records_by_type{$tree_datatype};

		$$loader_objects{$tree_datatype} = $self->omniclass_object(%args);

	}

	# avoid re-loading all these
	$args{data_codes} = [];

	# and now create a tree object under each record, for each child-type, and transport
	# the child records
	foreach $record (@{$parent_object->{records_keys}}) {
		foreach $tree_datatype (split /,/, $args{tree_datatypes}) {
			$args{dt} = $tree_datatype;
			next if !$all_children_by_type{$record}{$tree_datatype}[0];

			# if we do not have a plain 'clone-from' object, create one here
			if (!$$cloning_objects{$tree_datatype}) {
				$$cloning_objects{$tree_datatype} = $self->omniclass_object(%args);
			}
			# we are going to use the 'clone' method in there to dup them off and try to save some time
			$parent_object->{children_objects}{$record}{$tree_datatype} = $$cloning_objects{$tree_datatype}->clone();

			# load the found records into this new object
			# first the record_keys
			$parent_object->{children_objects}{$record}{$tree_datatype}->{records_keys} = $all_children_by_type{$record}{$tree_datatype};
			# then the records themselves
			foreach $child_record (@{ $all_children_by_type{$record}{$tree_datatype} }) {
				# main record
				$parent_object->{children_objects}{$record}{$tree_datatype}->{records}{$child_record}
					 = $$loader_objects{$tree_datatype}->{records}{$child_record};
				# metainfo
				$parent_object->{children_objects}{$record}{$tree_datatype}->{metainfo}{$child_record}
					 = $$loader_objects{$tree_datatype}->{metainfo}{$child_record};
			}

			# now put the first one in it's privileged spot
			$r = $parent_object->{children_objects}{$record}{$tree_datatype}->{records_keys}[0];
			$parent_object->{children_objects}{$record}{$tree_datatype}->{data} = $parent_object->{children_objects}{$record}{$tree_datatype}->{records}{$r};
			$parent_object->{children_objects}{$record}{$tree_datatype}->{data}{metainfo} = $parent_object->{children_objects}{$record}{$tree_datatype}->{metainfo}{$r};
			# convenience: the data_code of that first record
			$parent_object->{children_objects}{$record}{$tree_datatype}->{data_code} = $r;
			# and HYPER-convenience: the parent_string value of that first record
			$parent_object->{children_objects}{$record}{$tree_datatype}->{parent_string} = $tree_datatype.':'.$r;


			# let's alias that to the name of the table, for sanity's sake when coding elsewhere
			$child_table = $parent_object->{children_objects}{$record}{$tree_datatype}->{table_name};
			$parent_object->{children_objects}{$record}{$child_table} = $parent_object->{children_objects}{$record}{$tree_datatype};

			# go recursive to get the children's objects
			# $child_object = $parent_object->{children_objects}{$record}{$tree_datatype};
			# $args{current_children} = $parent_object->{metainfo}{$record}{children};
			$self->omniclass_tree($parent_object->{children_objects}{$record}{$tree_datatype},%args);

		}
	}


}

# recursive method to convert a omniclass object (which could be a tree of objects)
# into a plain old hash with the data from the 'records', 'metainfo' and 'records_keys'
# structures; best used when you are using omniclass to grab a complex data structure
# and plan to store and re-use that data
sub omniclass_data_extractor {
	my $self = shift;
	my ($omniclass_object,$plain_data,$recurse_into_child_objects) = @_;

	# if they set $recurse_into_child_objects to 'No,' then we won't go down the tree
	$recurse_into_child_objects ||= 'Yes'; # but we are defaulting it to Yes

	my ($r, $child_object);

	# put the data bits into a plain hash
	$$plain_data{records} = $omniclass_object->{records};
	$$plain_data{records_keys} = $omniclass_object->{records_keys};
	$$plain_data{altcodes_keys} = $omniclass_object->{altcodes_keys};

	# if they don't want the 'metainfo', skip it
	if (!$self->{extractor_skip_metainfo}) { # setting via attribute because the args above get a bit wonky
		$$plain_data{metainfo} = $omniclass_object->{metainfo};
	}

	# either way, we don't want it in there twice
	foreach $r (@{ $omniclass_object->{records_keys} }) {
		$$plain_data{records}{$r}{metainfo} = '';
	}

	# look for children-objects under each record, if this is a omniclass-tree
	if ($recurse_into_child_objects eq 'Yes') { # only if we want to do this
		foreach $r (@{ $omniclass_object->{records_keys} }) {
			foreach $child_object (keys %{ $omniclass_object->{children_objects}{$r} }) {
				next if $child_object !~ /[a-z]/; # only use the table-alias keys

				# call myself
				$$plain_data{records}{$r}{$child_object} = $self->omniclass_data_extractor($omniclass_object->{children_objects}{$r}{$child_object}, $$plain_data{records}{$r}{$child_object});
			}
		}
	}

	# return the data reference
	return $plain_data;
}


# object generator for the tools, except we are going to work off the URI path
sub tool_object {
	my $self = shift;

	# declare local vars
	my (@uri_parts, $special_params, $end_part, $app_inst, $application_id, $class_name, $class_path, $app_code_directory, $the_class_name, $tool_datacode, $tool_object, @tool_args);

	# our default is to figure out the tool to use based on $self->{luggage}{uri}
	# however, they can override this by sending an argument
	my ($tool_uri) = @_;

	# default that to what is in luggage
	$tool_uri ||= $self->{luggage}{uri};

	# still blank: stop here
	$self->{luggage}{belt}->mr_zebra("OBJ. FACTORY ERROR: No URI sent to create a tool object.",1) if !$tool_uri;

	# first, noodle out the application instance and application ID (data_code) which we are in
	# already figured out in %$luggage
	$app_inst = $self->{luggage}{app_inst}; # sanity
	$application_id = $self->{luggage}{session}{app_instances}{$app_inst}{application_id};

	# fortunately, we have a very lovely 'uris_to_tools' resolution hash in our omnitool session
	# however, our uri's can have two additional arguments at the end, either a method_name
	# (for the new tool) or an altcode (human-friendly ID) or regular ID of a piece of data
	# for example:
	#	/tools/otadmin 				easy, that's the omnitool admin tool
	#	/tools/otadmin/load_html			the 'load_html' method under the omnitool admin tool
	# 	/tools/otadmin/update/Eric1976	call to the 'update' method on the 'Eric1976' data in the omnitool admin tool
	# And it gets worse:
	#	/tools/otadmin/session_flusher				the session flusher tool, underneath ot admin but a separate tool
	#	/tools/otadmin/session_flusher/load_html		load_html() for the session flusher until ot admin
	#	/tools/otadmin/session_flusher/flush/4873489	call flush() on session 4873489
	#
	# So here is what we shall do:

	# remove any GET params from our uri
	$tool_uri =~ s/\?.*// if $tool_uri =~ /\?/;

	# clear out '/tools' and '/tool' -- account for a possible /tools// in case I got sloppy
	$tool_uri =~ s/\/tools?\/\/?//;
	# no trailing / either
	$tool_uri =~ s/\/$//;

	# now use 'uris_to_tools' to see if that was enough to get a match (no special args at the end)
	$tool_datacode = $self->{luggage}{session}{uris_to_tools}{$tool_uri};

	# if nothing found, pop off parts until we find one
	if (!$tool_datacode) {
		@uri_parts = split /\//, $tool_uri;  # the regex way didn't work so great for me
		while ($tool_uri && !$tool_datacode) {
			# work from the end backwards
			$end_part = pop(@uri_parts);
			$tool_uri =~ s/(^|\/)$end_part$//;

			# maybe we snuck in a parameter?
			if ($end_part =~ /^param/) {
				($self->{luggage}{params}{special_param} = $end_part) =~ s/param//;
			}

			# add what we removed to an arguments array; for now, we just care about
			# the first two - here, at least.  The tool's method may make use of the full uri
			# put on the end, since we are working from end of the uri backwards
			push(@tool_args,$end_part) if !$tool_args[1] && $end_part;
			# try again with newly-trimmed uri
			$tool_datacode = $self->{luggage}{session}{uris_to_tools}{$tool_uri};
		}
	}

	# if we couldn't find a tool to load, they sent an invalid URL or tried to
	# access a tool which is not available in application / instance
	# send back a 'TOOL_NOT_FOUND' to tell omnitool_controller() to use the default tool
	if (!$tool_datacode) {
		$self->{luggage}{belt}->logger("ERROR: No tool definition found for ".$self->{luggage}{uri},'fatals');
		$self->{luggage}{belt}->mr_zebra("TOOL_NOT_FOUND",2);
	}

	# still here?  good, we can figure out the class to use

	# where do the modules for this application live?
	$app_code_directory = $self->{luggage}{session}{app_instance_info}{app_code_directory};

	# what class is assigned to this tool?
	$class_name = $self->{luggage}{session}{tools}{$tool_datacode}{perl_module};
	# default to omnitool::tools
	if (!$class_name || $class_name eq 'None') {
		# create our tool using the luggage
		$tool_object = omnitool::tool->new($tool_datacode,$self->{luggage});

	# there are a few standard Tool.pm sub-classes which provides the core
	# create/update/delete/display functions, and it loads straight from
	# omnitool::tool::standard_data_actions = create/update
	# omnitool::tool::singleton_data_actions = create/update when there can be only one!
	# omnitool::tool::subform_data_actions = create/update when there will be sub-data forms
	# omnitool::tool::standard_delete = deletes
	# omnitool::tool::basic_data_view = display
	# omnitool::tool::basic_calendar = calendar --> action tool, very basic
	# omnitool::tool::setup_diagram --> framework for our network diagram tools
	# omnitool::tool::call_named_method --> runs a action-message tool using an omniclass method named for the tool's uri_base_path
	# omnitool::tool::button_menu --> button screen for subordinate menubar tools
	} elsif ($class_name =~ /^(standard_data_actions|subform_data_actions|singleton_data_actions|standard_delete|basic_data_view|basic_calendar|setup_diagram|view_details|call_named_method|button_menu)$/) {

		# already loaded above, so we just need to create the object with the proper luggage
		$the_class_name = 'omnitool::tool::'.$class_name;
		$tool_object = $the_class_name->new($tool_datacode,$self->{luggage});

	# otherwise, it is an application-specific sub-class
	} else {
		# first the module's name in perl-space
		$the_class_name = 'omnitool::applications::'.$app_code_directory.'::tools::'.$class_name;
		# and in the file system
		$class_path = $ENV{OTHOME}.'/code/omnitool/applications/'.$app_code_directory.'/tools/'.$class_name.'.pm';

		# load it in - log out if error
		unless (eval "require $the_class_name") {
			$self->{luggage}{belt}->mr_zebra("Could not import $the_class_name: ".$@,1);
		}
		# require $class_path;

		# and create the object with the proper luggage
		$tool_object = $the_class_name->new($tool_datacode,$self->{luggage});
	}

	# last bit: let's figure out our arguments
	if ($tool_args[0]) {

		# regexp to test if argument is an altcode or a special params
		$special_params = qr/^(tool_mode|bkmk)/;

		# is the first argument a method?
		if ($tool_object->can($tool_args[0])) { # yes! make it count
			$tool_object->{run_method} = $tool_args[0];
			# make the second arg the altcode for our active data record if there is one
			$self->{luggage}{params}{altcode} = $tool_args[1] if $tool_args[1] && $tool_args[1] !~ $special_params;

		# is the second argument a method?
		} elsif ($tool_object->can($tool_args[1])) { # yes! make it count
			$tool_object->{run_method} = $tool_args[1];
			# make the first arg the data_id if there is one
			$self->{luggage}{params}{altcode} = $tool_args[0] if $tool_args[0] && $tool_args[0] !~ $special_params;

		# if it can run neither arg as a menu, the first one is definitely the altcode
		} elsif ($tool_args[0] && $tool_args[0] !~ $special_params) {
			$self->{luggage}{params}{altcode} = $tool_args[0];
		}

		# is either argument an instruction to change the view?
		if ($tool_args[0] =~ /tool_mode/) { # yes!
			($self->{luggage}{params}{tool_mode} = $tool_args[0]) =~ s/tool_mode//;
		} elsif ($tool_args[1] =~ /tool_mode/) { # second one
			($self->{luggage}{params}{tool_mode} = $tool_args[1]) =~ s/tool_mode//;
		# is either arg a bookmark instruction
		} elsif ($tool_args[0] =~ /bkmk/) { # yes!
			($self->{luggage}{params}{display_options_key} = $tool_args[0]) =~ s/bkmk//;
		} elsif ($tool_args[1] =~ /bkmk/) { # second one
			($self->{luggage}{params}{display_options_key} = $tool_args[1]) =~ s/bkmk//;

		} # there must be a one-liner to do this ;)
	}

	# we placed the run_method and altcode into the object itself for easy transfer
	# the tool.pm objects should have a default 'run_method attribute for dispatcher.pm
	# to execute; usually that will be 'send_attributes' but you can ovverride in
	# your subclasses' _init() methods

	# fyi, the altcode should always come last, so that this would be bad form:
	#	/tools/data_viewer/Ginger1999/view
	# and never, ever include a parent ID in a URL to a sub-action!

	# having said all that, a 'altcode' PSGI param will take precendence
	$tool_object->{altcode} = $self->{luggage}{params}{altcode} if $self->{luggage}{params}{altcode};

	# ship it out back out
	return $tool_object;

}


1;

__END__

=head1 omnitool::common::object_factory

This module exists so we can easily utilize sub-classes to work with datatypes or tools on the fly.
When the time comes to create an object for OmniClass or Tool.pm, this module will decide which
Perl module to call to create the object.

In the case of Tool.pm, this module will (almost) always get called in dispatcher.pm to run the
tool's code and output to the client's browser.

OmniClass Datatypes are trickier.  They will often be called during the Tool's execution, usually
via get_omniclass_object() portion of Tool.pm class, but these objects could be built virtually
anywhere under omniclass::applications or in your custom scripts, so we will stash an object_factory
class in our $$luggage, built by pack_luggage.  (That's turning out to be a pretty key part of this
little setup.)

Our methods for object_factory are:

=head2 new()

Creates an object_factory object, and requires a $$lugggage hashref to work.  You can optionally
send an alternative $db object, and the use case for that would be when you're using the 'home'
database sever for the 'omnitool' database and operating on data stored on another server.  This
would probably be very rare.

Usage:  $object_factory = omnitool::common::object_factory->new($luggage[,$db]);

=head2 omniclass_object()

Creates the OmniClass object to work with a specific Datatype. If there is a custom Package built
mnitool::applications::APPLICATION_CODE_DIR::datatype_modules::THIS_DATATPYPES_MODULE, that
will get instantiated and returned.  Otherwise, omniclass_object() will return a 'plain'
omnitool::omniclass object for that Datatype.

Pass the same %args arguments which will be used for omnitool::omniclass.  The one required entry
will be for the 'dt' key, which tells us which datatype we want.  Please see the notes within
omnitool::omniclass to learn what else can go in here.

There are a few options available here but not in the regular OmniClass new(). One *very powerful*
option available here is $args{tree_mode}.  If that is set to '1', then the omniclass_tree() method
will be invoked, and you can read all about that fun below.

Usage: $omniclass_object = $object_factory->omniclass_object(%args);

In practice, it will look like this:

	$omniclass_object = $$luggage{object_factory}->omniclass_object(%args);

Or even more likely, within a tool object/class:

	$omniclass_object = $self->{luggage}{object_factory}->omniclass_object(%args);

For the args, you have some handy options (in additional to all the omniclass options):

	$omniclass_object_or_plain_hash = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => DT_ID, # required; ID of the datatype to build the omniclass for; can also
						# the table_name for the datatype (in omnitool.datatypes.table_name)
		'data_codes' => [LIST_OF_IDS], # optional; list of data codes to load up in records/metainfo/records_keys
		'altcodes' => [@list_of_altcodes], # optional, alternative way to call $self->load() on records, and probably
											# much easier for writing scripts; do not use if you are sending data_codes

		...any/all other OmniClass arguments can go here...

		'tree_mode' => 1, # optional, tells us to invoke 'omniclass_tree', see below'
		'tree_datatypes' => 'list,of,dts', # optional; comma-separated list of datatypes (or datatype tables names)
											# for which we want to include in our omniclass tree; used to limit trees
											# default is to include objects for all child data
		'return_extracted_data' => 1, # optional, run omniclass_data_extractor() (below) and return hashref to just data
									  # of loaded records; 'data_codes' must be filled
		'cache_extracted_data' => 'unique_object_name', # optional, run omniclass_data_extractor() for the loaded
														# data and then cache the hash via $db->hash_cache()
		'cache_extracted_data_location' => 'db' or 'file', # optional; where to cache that hash; default is db / database
		'cache_extracted_data_directory' => 'some_path', # optional; if caching to file, a directory other than the default
		'cache_extracted_data_db_table' => 'some_db.some_table', # optional; if caching to database, a table other than the default
		'extractor_skip_metainfo' => 1, # if doing data-extraction, will skip loading the 'metainfo' sub-hashes; useful to keep
										# cache sizes down
	);

Quick examples of those extra options:

	To get a live OmniClass object but also cache the plain data:

	$omniclass_object = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => '2_1',
		'data_codes' => ['5_1','1_1','4_1'],
		'tree_mode' => 1,
		'cache_extracted_data' => 'example_data_cache',
	);

	To just receive the plain hashref:

	$plain_hash = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'family_members', # using the table name for the DT
		'data_codes' => ['5_1','1_1','4_1'],
		'tree_mode' => 1,
		'return_extracted_data' => 1,
	);

	To receive the plain hashref and cache the data:

	$plain_hash = $self->{luggage}{object_factory}->omniclass_object(
		'dt' => 'family_members',
		'data_codes' => ['5_1','1_1','4_1'],
		'tree_mode' => 1,
		'return_extracted_data' => 1,
		'cache_extracted_data' => 'example_data_cache',
	);

=head2 omniclass_tree();

I am very excited about this one.  It multiples the power of the OmniClass code by turning the 'parent'
OmniClass object into a 'tree' of objects, with each object having a 'children_objects' hash, which
contains the OmniClass objects for the children of the loaded data for the parent.  This is recursive,
so you can build a 'super' object capable of manipulating very complex data.

For example, let's say you have a 'Table' Datatype, and Tables can contain records of the Datatype
'Chairs'.  Using this, you can build am object like so:

	$tables = {
		...all the OmniClass goodies included for the loaded tables...
		'children_objects' => {
			'table_1_data_code' => {
				'chair_data_type_id' => ...OmniClass Object for Chairs Here, with table_1's chairs' data loaded in...
				'table_cloth_data_type_id' => ...OmniClass Object for Table Cloths Here, with table_1's table cloths' data loaded in...
			},
			'table_2_data_code' => {
				'chair_data_type_id' => ...OmniClass Object for Chairs Here, with table_2's chairs' data loaded in...
				'table_cloth_data_type_id' => ...OmniClass Object for Table Cloths Here, with table_2's table cloths' data loaded in...
			}
		}
	};

For convenience, the objects are also tied to the subordinate data type's table name, so real usage would be like so:

		$table_name = $tables->{records}{$record_1}{name};
		$chair_one_name = $tables->{children_objects}{$record_1}{chairs}->{records}{$chair_1_code}{name};

You can use all the functions of OmniClass, so you can save a change like so:

		$tables->{children_objects}{$record_1}{tables}->save();

There are two ways to use this:

	1. Less fun, in two steps:

	$omniclass_object = $$luggage{object_factory}->omniclass_object(
		'dt' => '2_1',
		'data_codes' => ['5_1','1_1','4_1'],
	);
	$omniclass_object = $$luggage{object_factory}->omniclass_tree($omniclass_object);

	This is useful if you want to defer the tree-building, and the best example would
	be if you are performing a search in OmniClass and then need the subordinate data
	for the results found.

	2. More fun and easy, with 'tree_mode' argument to datatype_factory():

	$omniclass_tree = $$luggage{object_factory}->omniclass_object(
		'dt' => 'tables',
		'data_codes' => ['5_1','1_1','4_1'],
		'tree_mode' => 1
		'tree_datatypes' => '10_1,11_1',
	);

The idea/hope behind this is for OmniTool to enjoy some of the benefits of a document (NoSQL)
database while still using MySQL and its benefits. This allows us to retrieve and manipulate
complex data while maintaining that data as discrete records in the DB.

=head2 omniclass_data_extractor

Creates a plain hashref of the just the data bits (records, metainfo, and records_keys)
of an omniclass object, going recursive if it's a tree of omniclass objects.  Useful if
you use omniclass to build a (complex) data set which you want to store via $db->hash_cache()
and re-use on subsequent executions.

Usage:
	$plain_hash_ref = $$luggage{object_factory}->omniclass_data_extractor($omniclass_object);

Pretty simple, check out the results via:
	print $$luggage{belt}->show_data_structure($plain_hash_ref);

Most likely use of this method is via an arg to omniclass_object(), so you can pull out
the data, extract to hash, and cache it all in one action.

=head2 tool_object();

Creates the appropriate object to execute a Tool's code.  Will either be a plain omnitool::tools
object or built from a custom Tool.pm sub-class at
omnitool::applications::APPLICATION_CODE_DIR::tools::THIS_TOOLS_MODULE

Can accept one optional argument, which is a URI that would represent a Tool.  If that's not
filled, it will use the URI found in $self->{luggage}{uri}, and that would be set by Plack
based on the request.  One could also set this within a script if so inclined, but this
method is meant to be used in the context of a Web/API request.

With that URI, we will first take off the '/tools' (or '/tool') part in the front, then
find the tool which matches the URI.  Since this URI could include the name of a method
to execute as well as an Altcode for target data, we have to trim off the end pieces one at
a time to find the right tool.  So for example:

	/tools/db_servers				- Easy, start up the DB Servers tool
	/tools/db_servers/load_html 	- Run the 'load_html()' method in the DB Servers too
	/tools/db_servers/update/ginger423	- Run the 'update()' method in the DB Servers too on
											record ginger423

Either way, it *should* figure out to use the DB Servers tool.  The magic is in the 'uris_to_tools'
hash within $$luggage{session}{uris_to_tools}.

Usage:
	$tool_object = $$luggage{object_factory}->tool_object();  # use uri in %$luggage
		or
	$tool_object = $$luggage{object_factory}->tool_object($uri);

This method should always get called from dispatcher.pm or in the root area of a script.  I
have yet to use it in another context.
