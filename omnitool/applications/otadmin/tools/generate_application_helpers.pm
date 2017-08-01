package omnitool::applications::otadmin::tools::generate_application_helpers;

# generates application-wide classes from packaged templates
# leverages files in $OTHOME/code/omnitool/static_files/subclass_templates

use parent 'omnitool::tool';

use strict;

# my best friend
use File::Slurp;

# diplay available classes
sub perform_action {
	my $self = shift;

	my ($module, $this_generate_url, $purposes);

	my $generate_base_uri = $self->{my_base_uri}.'/generate_helper_module?client_connection_id='.$self->{client_connection_id}.'&uri_base='.$self->{luggage}{params}{uri_base}.'&helper_module=';

	$self->{json_results}{results_keys} = [
		'auth_helper.pm','custom_session.pm','daily_routines.pm','extra_luggage.pm'
	];
	$self->{json_results}{results_headings} = ['Application Helper Module','Purpose','Generate'];

	$self->{json_results}{results_sub_keys} = [
		'purpose','generate_link'
	];

	$purposes = {
		'auth_helper.pm' => 'Provide additional username/password checking for your OT6 System.',
		'custom_session.pm' => 'Augment the OT6 session for your Application.  Useful for adding logic for testing Access Roles.',
		'daily_routines.pm' => 'Provide a daily "cron script" type background task to broadly support your Application.',
		'extra_luggage.pm' => 'Augment the %$luggage structure for your Application. Useful to add data/methods needed throughout the Application.',
	};

	# include standard modules by default
	foreach $module (@{ $self->{json_results}{results_keys} }) {
		$this_generate_url = $generate_base_uri.$module;
		$self->{json_results}{results}{$module}{purpose} = $$purposes{$module};
		$self->{json_results}{results}{$module}{generate_link} = qq{<a href="$this_generate_url" target="_blank">Generate</a>};
	}
}

# method to run generate the helper module
sub generate_helper_module {
	my $self = shift;

	# declare vars
	my ($applications_omniclass_object, $lineage, $parent_application_id, $template_file);

	# turn the 'helper_module' param to a proper file name
	($template_file = $self->{luggage}{params}{helper_module}) =~ s/\.pm/.tt/;

	# for either one, we need the parent application's App Code Directory and Name

	# we need to get an omniclass object and load up that record
	$self->get_omniclass_object( 'dt' => $self->{attributes}{target_datatype} );

	# load up the record for $self->{display_options}{altcode}
	$self->{omniclass_object}->load('altcodes' => [$self->{display_options}{altcode}]);

	# and isolate the app code directory
	$self->{app_code_directory} = $self->{omniclass_object}->{data}{app_code_directory};
	$self->{app_name} = $self->{omniclass_object}->{data}{name};

	# book it and cook it!
	$self->{belt}->template_process(
		'template_file' => $template_file,
		'include_path' => $ENV{OTHOME}.'/code/omnitool/static_files/subclass_templates/',
		'template_vars' => $self,
		'send_out' => 1
	);

}


1;
