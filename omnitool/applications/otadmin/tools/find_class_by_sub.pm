package omnitool::applications::otadmin::tools::find_class_by_sub;

# allows developers to find subroutines in the vast library of OT6 modules
# probably your IDE does this for you, but I like to keep my code on a remote server

# depends on running this on a semi-regular basis
# /usr/local/bin/umlclass.pl -o /opt/omnitool/configs/ot6_modules.yml -r /opt/omnitool/code/omnitool/

# for that to work, you will need to do this first:
# 	sudo apt-get install libxml2-dev graphviz
#	sudo cpanm --force UML::Class::Simple
#	rm /opt/omnitool/configs/ot6_modules.yml

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use YAML::Syck;

use strict;

# any special new() routines
sub init {
	my $self = shift;
}


sub generate_form {
	my $self = shift;

	$self->{luggage}{params}{form_submitted} = 1;

	# put together a form to search out the module
	$self->{json_results}{form} = {
		'title' => "Find Perl Class by Subroutine / Method Name",
		'submit_button_text' => 'Lookup Module',
		'field_keys' => [1],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'instructions' => 'Must be exact name. Only searches OT6 modules.',
		'fields' => {
			1 => {
				'title' => 'Sub/Method Name',
				'name' => 'subroutine_name',
				'field_type' => 'short_text',
				'preset' => $self->{luggage}{params}{subroutine_name},
			},
		}
	};
}

# display modules for viewing POD's
sub perform_form_action {
	my $self = shift;

	my ($module_information, $class_info, $method, $module);

	# make sure the form shows ;)
	$self->{redisplay_form} = 1;

	return if !$self->{luggage}{params}{subroutine_name};

	# this is not a terribly efficient way to run this search, but it is fast and probably
	# not hevily used
	# /usr/local/bin/umlclass.pl -o /opt/omnitool/tmp/docs/ot6_modules.yml -r /opt/omnitool/code/omnitool/

	$module_information = LoadFile('/opt/omnitool/configs/ot6_modules.yml');

	$self->{json_results}{results_headings} = ['Found in Perl Class','View Docs','Subclasses'];

	my $documentation_base_uri = '/tools/view_module_docs/generate_pod2html?client_connection_id='.$self->{client_connection_id}.'&uri_base='.$self->{luggage}{params}{uri_base}.'&perl_module=';

	foreach $class_info (@{$$module_information{classes}}) {
		foreach $method (@{$$class_info{methods}}) {
			next if $method ne $self->{luggage}{params}{subroutine_name};

			$module = $$class_info{name};
			push(@{$self->{json_results}{results_keys}},$module);

			$self->{json_results}{results}{$module}{subclasses} = $$class_info{subclasses}[0];
			$self->{json_results}{results}{$module}{doc_link} = '<a href="'.$documentation_base_uri.$module.'" target="_blank">View</a>';


		}
	}

	$self->{json_results}{results_sub_keys} = [
		'doc_link', 'subclasses'
	];

	# display 'no matches found' as appropriate
	if (!$self->{json_results}{results_keys}[0]) {
		$self->{json_results}{error_message} = 'No Classes Found Containing a "'.$self->{luggage}{params}{subroutine_name}.'" Method';
	}

}

1;
