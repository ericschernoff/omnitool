package omnitool::applications::sample_apps::tools::contact_form;

# is a sub-class of Tool.pm
use parent 'omnitool::tool';

use strict;

# any special new() routines
sub init {
	my $self = shift;
}

# routine to generate the contact form
sub generate_form {
	my $self = shift;

	$self->{json_results}{form} = {
		'title' => 'Thank Your for Your Interest in OmniTool',
		'instructions' => qq{
			Please let me know if you are using OmniTool, so I can keep you updated on any enhancements and changes.
			If you have any questions or problems with OmniTool, I will do my best to help.
			It would be terrific to expand this project with more contributors, so please consider getting involved.
			Thanks in advance for your honest feedback.
			<br/><br/>
			This form will send email directly to me at ericschernoff--at--gmail.
		},
		'submit_button_text' => 'Send Message',
		'field_keys' => ['subject','your_name','your_email','message','recaptcha'],
		'hidden_fields' => {
			'form_submitted' => 1,
		},
		'fields' => { # integer keys, easily sorted
			'subject' => {
				'title' => 'Message Subject',
				'name' => 'subject',
				'field_type' => 'short_text',
				'preset' => $self->{luggage}{params}{subject},
				'is_required' => 1,
			},
			'your_name' => {
				'title' => 'Your Name',
				'name' => 'your_name',
				'field_type' => 'short_text',
				'preset' => $self->{luggage}{params}{your_name},
				'is_required' => 1,
			},
			'your_email' => {
				'title' => 'Your Email Address',
				'name' => 'your_email',
				'field_type' => 'email_address',
				'preset' => $self->{luggage}{params}{your_email},
				'instructions' => qq{I will not share your email address with anyone.},
				'is_required' => 1,
			},
			'message' => {
				'title' => 'Message',
				'name' => 'message',
				'field_type' => 'long_text',
				'preset' => $self->{luggage}{params}{message},
				'is_required' => 1,
			},
			'recaptcha' => {
				'title' => 'Please Verify',
				'name' => 'recaptcha',
				'field_type' => 'recaptcha',
				'recaptcha_key' => $ENV{RECAPTCHA_SITEKEY},
			},
		}
	};

}

# process the recaptcha to confirm that they are a person
sub post_validate_form {
	my $self = shift;

	# recaptcha verification is in the utility_belt
	my $they_are_a_person = $self->{belt}->recaptcha_verify();

	# stop the form submission in its tracks
	if (!$they_are_a_person) {
		$self->{stop_form_action} = 1;
		$self->{json_results}{form}{fields}{recaptcha}{field_error} = 1;
	}
}


# routine to send the email
sub perform_form_action {
	my $self = shift;

	# queue up the email
	my $new_email_id = $self->{omniclass_object}->add_outbound_email(
		'to_addresses' => $ENV{OMNITOOL_ADMIN},
		'from_address' => 'omnitool_admin@'.$ENV{OT_COOKIE_DOMAIN},
		'subject' => '[OmniTool.Org Feedback] '.$self->{luggage}{params}{subject},
		'template_filename' => 'paragraphs_plus_a_link.tt',
		'email_vars' => {
			'paragraphs' => [
				'MESSAGE FROM: '.$self->{luggage}{params}{your_name}.' - '.$self->{luggage}{params}{your_email},
				'MESSAGE:',
				$self->{luggage}{params}{message}
			]
		}
	);

	# send this upon successful submit
	$self->{json_results}{form_was_submitted} = 1;

	# if you want to convert to a pop-up notice
	$self->{json_results}{title} = 'Thank You, Your Message Has Been Sent.';
	$self->{json_results}{return_link_uri} = '/#'.$self->{my_base_uri}.'/'.time(),
	$self->{json_results}{return_link_title} = ' the Feedback Form and Send Another Message';

	# otherwise, fill in some values in $self->{json_results} for your Jemplate
}

1;
