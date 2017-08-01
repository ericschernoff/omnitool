package omnitool::applications::otadmin::tools::tool_manager;
# extensions / hooks for the Manage Tools tool

use parent 'omnitool::tool';

use strict;

# need to add in a link for 'Manage Sub-Tools' to refer back to this tool, only under the
# next level of data; basically, this allows for many levels of tools / recursive tools
sub post_search_execute {
	my $self = shift;

	my ($record);

	# go through each found record and try to add 'Manage Tools'
	# can use my own attributes, since we are adding ourself
	foreach $record (@{ $self->{omniclass_object}->{records_keys} }) {
		# add it in without delay
		push(@{ $self->{omniclass_object}->{records}{$record}{inline_actions} }, {
			'button_name' => $self->{attributes}{button_name},
			'icon_fa_glyph' => $self->{attributes}{icon_fa_glyph}, # from font-awesome glyphs
			'uri' => '#'.$self->{my_base_uri}.'/'.$self->{omniclass_object}->{metainfo}{$record}{altcode},
		});
	}
}

# special method for building a proper breadcrumbs trail, considering that the tools manager
# can go down several levels; rare to have one tool climb downwards through a DB
sub special_breadcrumbs {
	my $self = shift;

	my ($data_id_altcode) = @_;

	# will always be myself, except at the top
	my $tool_datacode = $self->{tool_datacode};

	my ($record_name, $parent_altcode, $parent_datacode, $search_opts_key, $parent_tool_datatype);

	# try to find the current browse-point's name and parent altcode
	if ($data_id_altcode) {
		# the datatype of our parent is either 8_1 or 1_1
		# try tools first:
		($record_name, $parent_altcode) = $self->{altcode_decoder}->name_and_parent_from_altcode($data_id_altcode,'8_1');
		# failing that, try apps:
		if (!$record_name) {
			($record_name, $parent_altcode) = $self->{altcode_decoder}->name_and_parent_from_altcode($data_id_altcode,'1_1');
		}
	}

	# if found, include this info in the array of hashes we are building
	if ($record_name) {
		unshift(@{$self->{bc_store}{breadcrumbs}},{
			'tool_name' => $self->{luggage}{session}{tools}{$tool_datacode}{button_name}. ' ('.$record_name.')',
			'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$tool_datacode}{uri_path_base}.'/'.$data_id_altcode,
			'icon_fa_glyph' => $self->{luggage}{session}{tools}{$tool_datacode}{icon_fa_glyph},
		});

		# keep going updwards until we find the top
		$self->special_breadcrumbs($parent_altcode);

	# otherwise, it's the OT Admin
	} else {
		unshift(@{$self->{bc_store}{breadcrumbs}},{
			'tool_name' => $self->{luggage}{session}{tools}{'2_1'}{button_name},
			'uri' => '#/tools/'.$self->{luggage}{session}{tools}{'2_1'}{uri_path_base},
			'icon_fa_glyph' => $self->{luggage}{session}{tools}{'2_1'}{icon_fa_glyph},
		});
	}

	# all donee
}


1;
