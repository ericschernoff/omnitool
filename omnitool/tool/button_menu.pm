package omnitool::tool::button_menu;
# simple tool to provide a screen of buttons for all subordinate menubar tools
# under this tool
# works with ButtonMenu.tt

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;

}

# produce the button json for button_menu.tt
sub perform_action {
	my $self = shift;

	my $child_tool_key;

	my $tool_datacode = $self->{tool_datacode};

	# now cycle through the menubar tools under this tool
	foreach $child_tool_key (@{ $self->{luggage}{session}{tools}{$tool_datacode}{child_tools_keys} }) {
		next if $self->{luggage}{session}{tools}{$child_tool_key}{link_type} ne 'Menubar';

		# add it in without any further delay
		push(@{ $self->{json_results}{buttons} }, {
			'key' => $child_tool_key,
			'text' => $self->{luggage}{session}{tools}{$child_tool_key}{button_name},
			'glyph' => $self->{luggage}{session}{tools}{$child_tool_key}{icon_fa_glyph}, # from font-awesome glyphs
			'uri' => '#/tools/'.$self->{luggage}{session}{tools}{$child_tool_key}{uri_path_base},
		});

	}

	# have to send it back out
	return $self->{json_results};

}


1;
