package omnitool::applications::otadmin::tools::view_module_documentation;

# tool to run pod2html on perl modules within this system and output them to the screen
# first bit is to display a form for them to enter the module name
# second bit is to actually load the HTML output in a new window

# leverages files in $OTHOME/code/omnitool/static_files/subclass_templates

use parent 'omnitool::tool';

use strict;

# core module that we need
use Pod::Html;

# my best friend
use File::Slurp;

# perform_action() will prepare the values for the 'generate_subclasses.tt' Jemplate
# to display the modal; will present a link to open a new tab to run generate_subclass()
# below directly and get the output
sub generate_form {
	my $self = shift;

	$self->{luggage}{params}{form_submitted} = 1;

	# put together a form to search out the module
	$self->{json_results}{form} = {
		'title' => "View Documentation for a Perl Module",
		'submit_button_text' => 'Display Module',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'instructions' => 'Will be displayed at top of table above. Example: omnitool::applications::otadmin::tools::view_module_documentation.',
		'fields' => {
			1 => {
				'title' => 'Display Another Module',
				'name' => 'perl_module',
				'field_type' => 'short_text',
				'preset' => $self->{luggage}{params}{perl_module},
			},
		}
	};
}

# display modules for viewing POD's
sub perform_form_action {
	my $self = shift;

	my ($module, $this_module_uri, $perl_module);

	my $documentation_base_uri = $self->{my_base_uri}.'/generate_pod2html?client_connection_id='.$self->{client_connection_id}.'&uri_base='.$self->{luggage}{params}{uri_base}.'&perl_module=';

	$self->{json_results}{results_keys} = [
		'omnitool','omnitool::omniclass','omnitool::tool',
		'omnitool::common::db','omnitool::common::utility_belt','omnitool::common::luggage',
		'omnitool::common::object_factory','omnitool::main.psgi','omnitool::dispatcher'
	];
	$self->{json_results}{results_headings} = ['Perl Module','View Link'];

	# include standard modules by default
	foreach $module (@{ $self->{json_results}{results_keys} }) {
		$this_module_uri = $documentation_base_uri.$module;
		$self->{json_results}{results}{$module} = qq{<a href="$this_module_uri" target="_blank">View</a>};
	}

	# did they send one to view?
	if ($self->{luggage}{params}{perl_module}) {
		# and does it exist?
		($perl_module = $self->{luggage}{params}{perl_module}) =~ s/\:\:/\//g;
		$perl_module = $ENV{OTHOME}.'/code/'.$perl_module;
		$perl_module .= '.pm' if $perl_module !~ /(psgi|pm)$/;

		# either way, put it in the keys
		unshift (@{ $self->{json_results}{results_keys} }, $self->{luggage}{params}{perl_module});

		if (-e "$perl_module") {
			$this_module_uri = $documentation_base_uri.$self->{luggage}{params}{perl_module};
			$self->{json_results}{results}{  $self->{luggage}{params}{perl_module} } = qq{<a href="$this_module_uri" target="_blank">View</a>};

		# if not, yell at them
		} else {
			$self->{json_results}{results}{  $self->{luggage}{params}{perl_module} } = 'NOT FOUND';
		}
	}

	# make sure the form shows ;)
	$self->{redisplay_form} = 1;

}

# method to run pod2html
sub generate_pod2html {
	my $self = shift;

	my ($perl_module, $pod_html, $destination_file, $cache_dir);

	# convert the module name into a real system path
	($perl_module = $self->{luggage}{params}{perl_module}) =~ s/\:\:/\//g;
	$perl_module = $ENV{OTHOME}.'/code/'.$perl_module;
	$perl_module .= '.pm' if $perl_module !~ /.psgi$/;

	# run the conversion - output to file to save ourselves some pain
	$destination_file = $ENV{OTHOME}.'/tmp/docs/'.$self->{luggage}{username}.'_doc.html';
	$pod_html = pod2html($perl_module, "--outfile=".$destination_file);

	# clean up the temp file
	unlink($ENV{OTHOME}.'/code/omnitool/'.'pod2htmd.tmp');

	# read it in
	$pod_html = read_file($destination_file);

	# and send it out
	$self->{belt}->mr_zebra($pod_html,2);

}


1;
