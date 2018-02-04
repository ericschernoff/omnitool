/*
	omnitool_toolobj.js

	Provides the Tool Javascript Class / Object which drives all the interactions
	with the Tool UI, including loading, hiding, quick search, data refresh,
	form submissions, and much more.

	Tool objects are kept in the 'tool_objects' associative array for easy re-use of
	loaded attributes and created objects.

	Tool activities are driven by changes to the location.hash, which are caught
	and processed by the omnitool_controller() function in omnitool_routines.js
*/

// Start the very important object constructor for tools
function Tool (tool_attributes) {
	// die if nothing passed in
	if (tool_attributes == undefined || $.isEmptyObject(tool_attributes)) {
		return false;
	}

	// copy the attributes into this object:
	// this is not fast, but as of this writing, setting the prototype of an
	// object is not universally-support; hope to fix this in a year.
	for ( attribute in tool_attributes ) {
		this[attribute] = tool_attributes[attribute];
	};

	// set the div names for this tool
	this['tool_div'] = 'tool_' + this['the_tool_id'];
	this['tool_controls_div'] = 'tool_controls_' + this['the_tool_id'];
	this['tool_display_div'] = 'tool_display_' + this['the_tool_id'];

	// make sure searching is not paused
	this['search_paused'] = 'No'; // will set to 'Yes' to stop searching

	// figure the proper base uri for this tool
	this['tool_uri'] = '/tools/' + this['uri_path_base'];
	// and the json data uri
	this['tool_json_uri'] = '/tools/' + this['uri_path_base'] + '/send_json_data';

	// match the tool_type to get the short-hand just once for use in the functions
	if (this['tool_type'].match(/Screen/)) {
		this['tool_type_short'] = 'screen';
	} else if (this['tool_type'].match(/Modal/)) {
		this['tool_type_short'] = 'modal';
	} else if (this['tool_type'].match(/Message/)) {
		this['tool_type_short'] = 'message';
	} else { // don't want it to be blank
		this['tool_type_short'] = 'other';
	}

	// function to make a tool active and load it up
	this.load_tool = function (reload_jemplate) { // reload_jemplate is set in omnitool_controller when the tool mode changes

		// close / hide any previously-active screen or modal
		if (this['tool_type_short'] == 'screen' && the_active_tool_ids['screen'] != this['the_tool_id'] && the_active_tool_ids['screen'] != 'none') {
			// hide the outgoing screen
			var outgoing_tool_id = the_active_tool_ids['screen'];
			tool_objects[outgoing_tool_id].hide_tool();

			// un-pause my search refreshing
			this['search_paused'] = 'No';

		} else if (this['tool_type_short'] == 'modal' && the_active_tool_ids['modal'] != this['the_tool_id'] && the_active_tool_ids['modal'] != 'none') {
			// hide the outgoing modal
			var outgoing_tool_id = the_active_tool_ids['modal'];
			tool_objects[outgoing_tool_id].hide_tool();

		}

		// make sure any open screen has its search paused
		if (this['tool_type_short'] == 'modal' && the_active_tool_ids['screen'] != 'none') {
			var open_screen_tool_id = the_active_tool_ids['screen'];
			tool_objects[open_screen_tool_id]['search_paused'] = 'Yes';
		}

		// if this is a screen, close any open modals
		this.close_modal_for_screen(); // will test that this is a screen

		// make myself the active tool for this category
		the_active_tool_ids[ this['tool_type_short'] ] = this['the_tool_id'];

		// if it's a "don't keep warm" screen, scroll to top
		if (this['tool_type_short'] == 'screen' && this['keep_warm'] != 'Yes') {
			goToTop();
		}

		// does it have a div already?  that occurs when keep_warm='Yes'
		if ($( "#"+this['tool_div'] ).length) {

			// if a modal, display it
			if (this['tool_type'].match(/Modal/)) {
				$("#"+this['tool_div']).modal({
					backdrop: 'static',
					keyboard: false // can't use escape key for these, as URI needs to change
				});
			// otherwise, show the div
			} else {
				$("#"+this['tool_div']).show();
			}

			// do they want to reload the jemplate?
			if (reload_jemplate == 1) {
				jemplate_bindings[ this['tool_display_div'] ].load_jemplate();
			} else { // no, just load in the json feed to the display area
				//jemplate_bindings[ this['tool_display_div'] ].load_jemplate();
				jemplate_bindings[ this['tool_display_div'] ].process_json_uri();
			}

		// not already there and a modal or screen: we must fetch the HTML skeleton for the tool,
		// which would include any controls
		} else if (this['tool_type_short'] == 'screen' || this['tool_type_short'] == 'modal') {
			// set some variables for access inside this $.when()
			var this_tool_uri = this['tool_uri'];
			var this_tool_display_div = this['tool_display_div'];
			var this_tool_type_short = this['tool_type_short'];
			var this_tool_div = this['tool_div'];
			var this_tool_id = this['the_tool_id'];
			var this_javascript_class = this['javascript_class'];

			$.when( query_tool(this['tool_uri'] + '/send_html',{}) ).done(function(tool_html) {
				// this html will include all the div tags, and we can add it to the 'page-content' div
				$("#page-content").append( tool_html );

				// empower bookmark create links
				bookmark_manager.enable_create_bookmark_buttons();

				// empower the tool search drop-down menus
				enable_chosen_menu('.tool-search-menu');

				// run the routines to enable the quick-search fields
				tool_objects[this_tool_id].quick_search_enable();

				// now grab the Jemplate for the display area
				if (jemplate_bindings[ this_tool_display_div ] == undefined || $.isEmptyObject(jemplate_bindings[ this_tool_display_div ])) {
					jemplate_bindings[ this_tool_display_div ] = new jemplate_binding(
						this_tool_display_div,
						this_tool_uri + '/send_jemplate', //?client_connection_id='+client_connection_id,
						this_tool_display_div+'.tt',
						this_tool_uri + '/send_json_data' // ?client_connection_id='+client_connection_id
					);


				} else if (reload_jemplate == 1 || jemplate_bindings[ this_tool_display_div ].jemplate_loaded == 0) {
					jemplate_bindings[ this_tool_display_div ].load_jemplate();

				} else { // no, just load in the json feed to the display area
					//jemplate_bindings[ this['tool_display_div'] ].load_jemplate();
					// make sure the json_data_uri is right, because many uri's share tools/jemplates
					jemplate_bindings[ this_tool_display_div ].json_data_uri = this_tool_uri + '/send_json_data';
					// and process it again
					jemplate_bindings[ this_tool_display_div ].process_json_uri();
				}

				// if the advanced search form was open earlier in this window's life, re-show it
				if (tool_objects[this_tool_id].advanced_search_open == 1) {
					tool_objects[this_tool_id].show_advanced_search();
				}

				// if it's a modal, show it off
				if (this_tool_type_short == 'modal') {
					$("#"+this_tool_div).modal({
						backdrop: 'static',
						keyboard: false // can't use escape key for these, as URI needs to change
					});
				}
			});

		// if this is a message, we shall use the excellent Gritter library to display
		// no jemplate processing
		} else if (this['tool_type_short'] == 'message') {
			// need the current active screen's url to be displayed up top
			if (the_active_tool_ids['screen'] != 'none') {
				var active_screen_tool_id = the_active_tool_ids['screen'];
				var active_screen_uri = tool_objects[active_screen_tool_id]['tool_uri'];
			}

			// fetch the data and see if we need to authenticate
			// notice that these tools simply work on GET params, no POST, and those
			// params were set when we loaded up the tool initially
			$.when( query_tool(this['tool_json_uri'],{}) ).done(function(data) {
				// use our handy create_gritter_notice() method
				if (data.simple_error == undefined) { // let them short-circuit with an error modal
					create_gritter_notice(data);
				}

				// set the current altcode for this message tool, in case we are reloading that specific result in the search screen
				if (data.altcode) {
					tool_objects[data.the_tool_id]['current_altcode'] = data.altcode;
				} else {
					tool_objects[data.the_tool_id]['current_altcode'] = 'none';
				}

				// having popped up the messages, set the location.hash to the screen uri
				location.hash = data.return_link_uri;
			});
		}

		// get the breadcrumbs right, if in screen mode
		if (this['tool_type_short'] == 'screen') {
			jemplate_bindings['breadcrumbs'].json_data_uri = this['tool_uri'] + '/send_breadcrumbs';
			jemplate_bindings['breadcrumbs'].process_json_uri();
		}

		// if it has a 'query_interval' for the search, set a timer to reload that jemplate
		if (this['query_interval'] > 0) {
			// start the background refresh
			var _this = this;
			this['background_refresher'] = setInterval(
				function() { _this.refresh_json_data(); },
				(_this['query_interval'] * 1000)
			);
			this['search_paused'] = 'No';
		}

		// set the title for screens
		if (this['tool_type_short'] == 'screen') {
			$(document).attr("title", this['name']);
			$('#ot_tool_title').text(this['name']);
		}
	}

	// easy function for making sure loading a screen closes a modal
	// call it from a few spots depending on the situation
	this.close_modal_for_screen = function(force_close) { // force-close is there when the tool itself is a modal
		// close any open modal if we are loading a screen
		var possible_modal_tool_id = the_active_tool_ids['modal'];
		if ((force_close != undefined || this['tool_type_short'] == 'screen') && possible_modal_tool_id != 'none') {
			if ($('#'+tool_objects[possible_modal_tool_id]['tool_div']).hasClass('in')) {
				tool_objects[possible_modal_tool_id].hide_tool();
				the_active_tool_ids['modal'] = 'none';
			}
		}
	}

	// method to change a tool's json uri if changing the hash within the same tool
	// most useful for Action tools
	this.update_json_uri = function (new_json_data_uri) {
		if (new_json_data_uri != undefined) {
			var this_tool_display_div = this['tool_display_div']; // sanity
			// change it
			if (!(new_json_data_uri.match("client_connection_id"))) {
				new_json_data_uri = new_json_data_uri; // + '?client_connection_id='+client_connection_id;
			}
			jemplate_bindings[ this_tool_display_div ].json_data_uri = new_json_data_uri;

			// poll it
			jemplate_bindings[ this_tool_display_div ].process_json_uri();

			// un-pause the search
			this['search_paused'] = 'No';
		}
	}

	// function to refresh the json data in the binding easily, since we already have this['tool_display_div']
	this.refresh_json_data = function (from_button_click) {
		var this_tool_display_div = this['tool_display_div']; // sanity
		var my_json_uri = this['tool_json_uri'];

		// if the counter for active queries in blank, just make it 0
		if (active_queries[my_json_uri] == undefined) {
			active_queries[my_json_uri] = 0;
		}

		// return if it's not bound yet
		if (jemplate_bindings[ this_tool_display_div ] == undefined) {
			return;
		}

		// if this is from a button click, we do this no matter what
		if (from_button_click != undefined) {
			jemplate_bindings[ this_tool_display_div ].process_json_uri('Refreshing Data');
		} else { // otherwise, doing an automation refresh, and we have to pass some tests
			// skip if the search is paused or the mouse has not moved in >120 seconds
			var last_mouse_move = ( Math.floor(Date.now() / 1000) ) - mouse_move_time;
			// we will also skip if the search is paused or if there is 1 or more active queries
			// for this tool's json uri in query_tool()
			if (this['search_paused'] == 'No' && last_mouse_move <= 120 && active_queries[my_json_uri] < 1) {
				jemplate_bindings[ this_tool_display_div ].process_json_uri('Refreshing Data');
			}
		}


		// if the advanced search or sort is still open, then maintain the shrunken table
		var tool_id = this['the_tool_id'];
		if ($('#advanced_search_' + tool_id).is(':visible') || $('#advanced_sort_' + tool_id).is(':visible')) {
			this.shrink_or_grow_tool_display('shrink');
		}

	}

	// function to reload one search result in the UI
	// please note that this requires your tool's Jemplate to have the individual result's HTML
	// in a BLOCK; please see WidgetsV2.tt
	//<a href="javascript:tool_objects['5_1_79_1'].refresh_one_result('35767_2','the_result_widget')>"Refresh One</a>
	// we use the data_code (record key) because it is guaranteed to be unique
	this.refresh_one_result = function (data_code, block_name) {
		var the_url = this['tool_uri'] + '/load_one_record';

		// if the 'block_name' is blank, try to default to any 'single_record_jemplate_block' setting
		if (block_name == undefined || block_name == '') {
			block_name = this['single_record_jemplate_block'];
		}
		// fail if it's still blank
		if (block_name == undefined) {
			return;
		}

		// make sure 'block_name' has the suffix '_tool_and_instance'
		if ( block_name.match('_' + this['the_tool_id']) == undefined ) {
			block_name = block_name + '_' + this['the_tool_id'];
		}

		// now load the single result
		$.when( query_tool(the_url, { one_data_code: data_code }) ).done(function(json_data) {
			if (json_data.records_keys[0] != undefined) {
				json_data.block_name = block_name;
				json_data.record_key = json_data.records_keys[0];
				jemplate_bindings['process_any_div'].element_id = '#' + json_data.records_keys[0] + '_result';
				jemplate_bindings['process_any_div'].process_json_data(json_data);
				// re-enable any pop-overs
				enable_popovers();
				// hide the loading modal
				loading_modal_display('hide');
			}
		});
	}

	// function to change the simple-sort column / directory for the displayed results
	this.update_sorting = function (sort_column,sort_direction) {
		// do not continue if no sort_column sent
		if (sort_column == undefined || sort_column == '') {
			return;
		}
		// default direction is up / ascending
		if (sort_direction == undefined || sort_direction == '') {
			sort_direction = 'Up';
		}

		// prepare to query the json uri with the new sort options
		var post_object = {
			'sort_column': sort_column,
			'sort_direction': sort_direction
		};
		var this_tool_display_div = this['tool_display_div']; // for use below
		var this_tool_id = this['the_tool_id'];

		// if this is a DataTable-enabled table, we are just saving the info for
		// the next reload, on another machine; so be silent in the query
		if ( $.fn.DataTable.isDataTable( '#tool_results_' + this_tool_id ) ) {
			var sorting_promise = query_tool(jemplate_bindings[ this_tool_display_div ].json_data_uri, post_object);

		// otherwise, we need to actually load and process the results
		} else {
			// display the loading modal
			loading_modal_display('Sorting Results...');
			// preform the query
			$.when( query_tool(jemplate_bindings[ this_tool_display_div ].json_data_uri, post_object) ).done(function(json_data) {
				jemplate_bindings[ this_tool_display_div ].process_json_data(json_data);

				// reveal the page
				loading_modal_display('hide');
			});
		}
	}

	// function to send in quick-search menu / keyword changes
	// expects the field name / value for sending into query_tool
	this.process_quick_search = function(field_name,field_value) {
		var this_tool_display_div = this['tool_display_div']; // for use below
		loading_modal_display('Running Search...');
		var post_object = {};
			post_object[field_name] = field_value;
			post_object['via_quick_search'] = 1; // tells the tool.pm sub-class how it got this variable, in case there is a special need
			if (field_name == 'quick_keyword' && field_value == '') { // instruct ot6 to clear out this field
				post_object[field_name] = 'DO_CLEAR';
			}

		$.when( query_tool(jemplate_bindings[ this_tool_display_div ].json_data_uri, post_object) ).done(function(json_data) {
			// process the jemplate with any new information
			jemplate_bindings[ this_tool_display_div ].process_json_data(json_data);
			loading_modal_display('hide');
		});
	}

	// easy utility method to process quick action links in Tabe.tt and tool_area_skeleton.tt
	this.quick_action_link = function(action_menu) {
		if (action_menu.val() == 'refresh_json_data') { // allow for refresh link
			this.refresh_json_data();
		} else if (action_menu.val() != '') { // only if it's filled
			location.hash = action_menu.val();
			// may do more later on
		}
	}

	// function support empowering auto-complete fields
	// looks for two args:  the name of the method to run on the server-side (which should return a JSON array),
	// and the actual field objecc (not an identifier, pass in $('#field')
	this.auto_complete_fields = function(server_side_method_name,field) {
		// set up the autocomplete, point it at the server-side tool method and respond with the data
		// jquery.ui makes this quite easy
		var this_tool_url = this['tool_uri'];
		var spinner_icon_id = field.attr('id') + '-spinner';
		field.autocomplete({
			source: function( request, response ) {
				$('#'+spinner_icon_id).show();
				$.when( query_tool(this_tool_url + '/autocomplete_suggester', {term: request.term, server_side_method_name: server_side_method_name }) ).done(function(data) {
					response( data );
					$('#'+spinner_icon_id).hide();
				});
			},
			minLength: 3,
		});
	}

	// and provide similar support for 'tag' fields with autocomplete
	this.tag_auto_complete_fields = function(server_side_method_name,field) {
		// set up the autocomplete, point it at the server-side tool method and respond with the data
		// jquery.ui makes this quite easy
		var this_tool_url = this['tool_uri'];
		var spinner_icon_id = field.attr('id') + '-spinner';
		field.tag({
			placeholder: $(this).attr('placeholder'),
			source: function(query_term, process) {
				if (query_term.length > 3) {
					$('#'+spinner_icon_id).show();
					$.when( query_tool(this_tool_url + '/autocomplete_suggester', {term: query_term, server_side_method_name: server_side_method_name }) ).done(function(data) {
						process( data );
						$('#'+spinner_icon_id).hide();
					});
				}
			},
		});
	}


	// function to support the clear-quick-keyword button
	this.clear_quick_keyword = function(skip_reload) {
		$('#quick_keyword_'+this['the_tool_id']).val('');
		$('#clear_quick_search_button_'+this['the_tool_id']).hide();
		if (skip_reload == undefined) {
			this.process_quick_search('quick_keyword','');
		}
	}

	// function to support allowing one menu to trigger another, sending the source menu's value
	// created for the 'advanced search' form, and expanded to other uses
	this.trigger_menu = function(trigger_menu,source_value,method_name,alternative_field_div) {

		var trigger_menu_param = trigger_menu.replace('quick_','');
		var post_data_object = {
			target_menu_id: trigger_menu_param,
			source_value: source_value
		};

		// default use is for the advanced search form
		if (method_name == undefined || method_name == '') {
			method_name = 'advanced_search_trigger_menu_options';
		}

		// clear the target menu's options
		$("#"+trigger_menu).empty();

		// if there's an alternative field, hide it
		if (alternative_field_div != undefined) {
			$('#'+alternative_field_div).hide();
		}

		// show the modal if another one is not already open
		var showed_modal = 0;
		if (!($("#modal-loading").hasClass('in'))) {
			loading_modal_display('Loading Menu...');
			showed_modal = 1;
		}

		// fetch the options from the server and put them into that target menu
		$.when( query_tool(this['tool_uri'] + '/' + method_name ,post_data_object) ).done(function(data) {
			if (data.options_keys != null && data.options_keys.length > 0) {
				for (var i = 0; i < data.options_keys.length; i++) {
					var key = data.options_keys[i];
					$("#"+trigger_menu).append($("<option></option>").val(key).html(data.options[key]));
				}

				// if it's hidden, be sure to show it
				if ($("#field_div_"+trigger_menu).is(":hidden") == true && data.options_keys.length > 0) {
					$("#field_div_"+trigger_menu).show();
				}

				// if this is a chosen menu, update it
				$("#"+trigger_menu).trigger("chosen:updated");

				// if this target menu triggers another menu (i.e. three menus in a chain), call that
				// change routine to reset the next menu's options
				if (!($("#"+trigger_menu).hasClass('tool-search-menu'))) {
					$("#"+trigger_menu).change();
				}

			// if it's not for the advanced search and there are no options, re-hide the menu
			} else if (method_name != 'advanced_search_trigger_menu_options') {
				$("#field_div_"+trigger_menu).hide();

				// if nothing found, and there was an alternative field, show it
				if (alternative_field_div != undefined) {
					$('#'+alternative_field_div).show();
				}
			}

			// hide that modal
			if (showed_modal == 1) {
				loading_modal_display('hide');
			}
		});
	}


	// function to submit this forms via jquery.form - http://malsup.com/jquery/form/
	// would like to use Mozilla's FormData, but it won't play nice with IE<10
	this.submit_form = function(form_id) {
		var this_tool_id = this['the_tool_id']; // for easy use & traveling

		// if the form_id is blank, presume there is just one form for this tool
		if (form_id == undefined) {
			form_id = this['the_tool_id'] + '_form';

		// advanced search/sort forms have a few special requirements
		} else if (form_id.match('advanced')) {
			// set any blank keywords to 'DO_CLEAR' so they get cleared
			$(".advanced_search_keyword_textbox").each(function() {
				if ($(this).val() == '') {
					$(this).val('DO_CLEAR');
				}
			});
			// set any blank multi-selects to 'DO_CLEAR' so they get cleared
			$(".advanced_search_multiselect").each(function() {
				if ($(this).val() == undefined) {
					$(this).val(['DO_CLEAR']);
				}
			});
			// same for the quick keyword
			if ($('#form-field-1').val() == '') {
				$('#form-field-1').val('DO_CLEAR');
			}

		}

		// have these expose for use in the nested function below
		var this_tool_display_div = this['tool_display_div'];
		var this_tool_uri = this['tool_uri'];
		var this_tool_json_uri = this['tool_json_uri'];

		// submit the form and send the results data back into our display area's jemplate
		loading_modal_display('Submitting Form...');
		// jump to the top, in case there are errors - skip if a modal/message where the parent tool is just refreshing the target data
		if (form_id.match('advanced_search') == undefined) { // only if not advanced search
			if (this['tool_type_short'] == 'screen' || tool_objects[ the_active_tool_ids['screen'] ]['single_record_jemplate_block'] == undefined || tool_objects[ the_active_tool_ids['screen'] ]['single_record_jemplate_block'] == 0) {
				goToTop();
			}
		}

		// if there is a wysiwig editor, transfer its text into the hidden variable (and trim leading/ending whitespace)
		if ($('#'+this_tool_id+'_wyiswig').length > 0) {
			$('#' + this_tool_id + '_wyiswig_transporter').val( $.trim( $('#'+this_tool_id+'_wyiswig').html() ) );
		}

		// features to stop other calls from overriding this one
		// note that this is now the latest call
		if (query_tool_calls[this_tool_json_uri] == undefined) {
			query_tool_calls[this_tool_json_uri] = 0;
		}
		query_tool_calls[this_tool_json_uri] += 1;

		// we need to make sure the tool.refresh_json_data knows this send_json uri is already active
		if (active_queries[this_tool_json_uri] == undefined) { // this is the first one
			active_queries[this_tool_json_uri] = 1;
		} else {
			active_queries[this_tool_json_uri] += 1;
		}

		// let's time this transfer
		var start = new Date();

		// submit the form
		$('#' + form_id).ajaxSubmit({
			//dataType: 'json', // interferes with error-checking functions
			data: {
				uri_base: uri_base,
				client_connection_id: client_connection_id
			},
			success: function(json_data, textStatus, jqXHR) {
				// make the json uri no longer active
				active_queries[this_tool_json_uri] -= 1;

				// use the check_for_errors function to see if the server sent back an error message
				var is_error = check_for_errors(json_data);
				if (is_error == 1) { // error found, stop here
					loading_modal_display('hide');
					return false;
				}

				// how to display results
				if (json_data.show_gritter_notice) { // was successful, just pop it up and load the previous tool
					create_gritter_notice(json_data);
					location.hash = json_data.return_link_uri;
					loading_modal_display('hide');

				} else { // omnitool wants you to see the form again, or maybe this is a multiple part form?
					if (form_id.match('advanced_search')) { // reload the tools controls

						// for our response-time tracking
						var end  = new Date();
						// pack that up as seconds
						json_data.response_time = (end.getTime() - start.getTime()) / 1000;

						// postpone the post_data_fetch_operations function
						json_data.skip_post_data_ops = 1;
						// process the results
						jemplate_bindings[ this_tool_display_div ].process_json_data(json_data);
						// call in the new tools controls
						$.when( tool_objects[this_tool_id].reload_tool_controls(1) ).done(function() {
							// and then call post_data_fetch_operations()
							post_data_fetch_operations(json_data);
							// keep the display sized correctly
							tool_objects[this_tool_id].shrink_or_grow_tool_display('shrink');
							// scroll to top and close the modal
							goToTop();
							loading_modal_display('hide');
						});

						// fix the keywords and multi-selects back to blank
						$(".advanced_search_keyword_textbox").each(function() {
							if ($(this).val() == 'DO_CLEAR') {
								$(this).val('');
							}
						});
						$(".advanced_search_multiselect").each(function() {
							if ($(this).val()[0] == 'DO_CLEAR') {
								$(this).val([]);
							}
						});

						// same for the quick keyword
						if ($('#form-field-1').val() == 'DO_CLEAR') {
							$('#form-field-1').val('');
						}

					// regular display of results in the screen
					} else {
						jemplate_bindings[ this_tool_display_div ].process_json_data(json_data);

						// if adv. sort, keep the display sized correctly
						if (form_id.match('advanced_sort')) {
							tool_objects[this_tool_id].shrink_or_grow_tool_display('shrink');
						}

						loading_modal_display('hide');
					}
				}
			}
		});
	}

	// simple function sending GET commands into tools and reprocessing the jemplate
	// useful for when you want to commit an action, but not update the jemplate binding uri
	// this expects the full json data for the tool, plus an extra 'message' indicating results
	this.process_action_uri = function(action_uri) {
		var this_tool_display_div = this['tool_display_div']; // for use below
		loading_modal_display('Updating...');
		$.when( query_tool(action_uri,{}) ).done(function(json_data) {
			if (json_data.message && json_data.no_gritter == undefined) {
				create_gritter_notice(json_data);
			}
			if (json_data.show_gritter_notice) { // close the modal and go back
				location.hash = json_data.return_link_uri;
			} else { // process the jemplate with any new information
				jemplate_bindings[ this_tool_display_div ].process_json_data(json_data);
			}
			loading_modal_display('hide');
		});
	}

	// simple function to invoke the 'send_file' tool method to download an uploaded file
	this.fetch_uploaded_file = function(altcode,file_field,datatype,new_window) {
		// build our URL for the download
		var the_url = this['tool_uri'] + '/send_file/?data_altcode=' + altcode + '&client_connection_id=' + client_connection_id;
		if (file_field != undefined) {
			the_url = the_url + '&file_field=' + file_field;
		}
		if (datatype != undefined) {
			the_url = the_url + '&datatype=' + datatype;
		}

		// if we are using a 'uri_base', pass that back to the server
		if (uri_base != undefined && uri_base != '') {
			the_url = the_url + '&uri_base=' + uri_base;
		}

		// unfortunately, ajax call won't trigger the download
		if (new_window != undefined) { // if they passed a fourth argument, open a new window
			window.open( the_url );
		} else { // otherwise, should download
			location.href = the_url;
		}
	}

	// routine to handle opening the advanced search modal
	this.show_advanced_search = function() {
		// prepare some vars for travel into the blocks
		var adv_search_name = this['name'] + ': Advanced Searching';
		var adv_search_url = this['tool_uri'] + '/advanced_search_form';
		var tool_id = this['the_tool_id'];
		var form_display_div = $('#advanced_search_' + tool_id);

		// jump to the top
		goToTop();

		if (form_display_div.is(':visible')) { // already visible, disappear it
			form_display_div.html('');
			form_display_div.hide();

			// re-expand the tool main display area to full size on large screens
			tool_objects[tool_id].shrink_or_grow_tool_display('grow');

			$('#search-controls_'+tool_id).show();
			$('#quick_keyword_controls_'+tool_id).show();

			// make sure the advanced item badges are shown as needed -- use the class way
			// because there may be a few in the DOM by now
			if ($('#advanced_sort_options_badge').html().length > 0) {
				$('.advanced_sort_options_badge').show();
			}
			if ($('#advanced_search_filters_badge').html().length > 0) {
				$('.advanced_search_filters_badge').show();
			}

			// make note that the form is now closed
			tool_objects[tool_id].advanced_search_open = 0;

		} else { // otherwise, load and show!

			// only one of sort and search can be shown at once
			if ($('#advanced_sort_' + tool_id).is(':visible')) {
				this.show_advanced_sort();
			}

			// query for the advanced search form and send into the modal
			loading_modal_display('Opening Advanced Search...');
			$.when( query_tool(adv_search_url,{}) ).done(function(json_data) {
				json_data.modal_title_icon = 'fa-binoculars';
				json_data.modal_title = adv_search_name;
				json_data.advanced_search_mode = 1;
				json_data.no_close_button = 1;
				json_data.tool_and_instance = tool_id;
				// open it up
				json_data.block_name = 'advanced_search_form';
				jemplate_bindings['process_any_div'].element_id = '#advanced_search_' + tool_id;
				jemplate_bindings['process_any_div'].process_json_data(json_data); // advanced_search_form

				// shrink the tool main display area to half size on large screens
				tool_objects[tool_id].shrink_or_grow_tool_display('shrink');

				// now toggle it
				form_display_div.show();
				$('#search-controls_'+tool_id).hide();
				$('#quick_keyword_controls_'+tool_id).hide();

				// make note of the fact that this form is open for return to this tool
				tool_objects[tool_id].advanced_search_open = 1;

				// enliven the form and popovers
				interactive_form_elements(tool_id,'advanced_search_form');
				enable_popovers();
				loading_modal_display('hide');
			});

		}
	}

	// routine to handle opening the advanced sort form modal
	this.show_advanced_sort = function() {
		// prepare some vars for travel into the blocks
		var adv_sort_name = this['name'] + ': Advanced Sorting';
		var adv_sort_url = this['tool_uri'] + '/advanced_sort_form';
		var tool_id = this['the_tool_id'];

		// jump to the top
		goToTop();

		// sanity
		var form_display_div = $('#advanced_sort_' + tool_id);

		if (form_display_div.is(':visible')) { // already visible, disappear it
			form_display_div.html('');
			form_display_div.hide();

			// re-expand the tool main display area to full size on large screens
			tool_objects[tool_id].shrink_or_grow_tool_display('grow');

		} else {

			// only one of sort and search can be shown at once
			if ($('#advanced_search_' + tool_id).is(':visible')) {
				this.show_advanced_search();
				this.shrink_or_grow_tool_display('shrink');
			}

			// query for the advanced search form and send into the modal
			loading_modal_display('Opening Advanced Sort...');
			$.when( query_tool(adv_sort_url,{}) ).done(function(json_data) {
				json_data.modal_title_icon = 'fa-arrows';
				json_data.modal_title = adv_sort_name;
				json_data.advanced_sort_mode = 1;
				json_data.no_close_button = 1;
				json_data.tool_and_instance = tool_id;

				// open it up
				json_data.block_name = 'advanced_sort_form';
				jemplate_bindings['process_any_div'].element_id = '#advanced_sort_' + tool_id;
				jemplate_bindings['process_any_div'].process_json_data(json_data); // advanced_search_form

				// shrink the tool main display area to half size on large screens
				tool_objects[tool_id].shrink_or_grow_tool_display('shrink');

				// now toggle it
				form_display_div.show();

				// enliven the form and popovers
				interactive_form_elements(tool_id,'advanced_sort_form');
				enable_popovers();
				loading_modal_display('hide');
			});
		}
	}

	// support method to shrink/expand the main tool area for displaying the forms next-door
	this.shrink_or_grow_tool_display = function(action) {
		// gather up the main area
		var tool_id = this['the_tool_id'];
		var main_display_div = $('#tool_display_' + tool_id);

		if (action == 'shrink') { // squash it down
			// change the main area
			main_display_div.addClass('col-lg-6').removeClass('col-lg-12');
			// if it is in Table.tt mode, hide all but the first two columns
			$( '.hidden-advanced-search').each(function() {
				$(this).hide();
			});

		} else { // grow it back
			// change the main area
			main_display_div.addClass('col-lg-12').removeClass('col-lg-6');
			// if it is in Table.tt mode, reveal all columns
			$( '.hidden-advanced-search').each(function() {
				$(this).show();
			});

		}
	}

	// validation routine for that advanced sort form
	this.advanced_sort_validate = function() {
		$('#advanced_sort_warning').hide();
		var chosen_choices = new Array();
		$('#'+ this['the_tool_id'] + '_advanced_sort_form').find('select').each(function(){
			if (this.value != '-' && chosen_choices[ this.value ] == 1) {
				$('#advanced_sort_warning').show();
			} else {
				chosen_choices[ this.value ] = 1;
			}
		});
	}

	// routine to facilitate easy modal-opening for special subroutines
	this.simple_message_modal = function (message_url) {
		$.when( query_tool(message_url,{}) ).done(function(json_data) {
			open_system_modal(json_data);
		});
	}

	// function to reload the tool_controls area if needed
	this.reload_tool_controls = function (adv_search_mode) {
		var this_tool_id = this['the_tool_id'];

		// use a promise so that we can make sure to return a waiting task
		// NOTE: this is how I should handle nested promises!
		var post_promise = query_tool(
			this['tool_uri'] + '/send_tool_controls',{}
		).done(function (tool_controls_html) {
			// load them in
			$('#tool_controls_'+this_tool_id).html(tool_controls_html);
			// empower the tool search drop-down menus
			enable_chosen_menu('.tool-search-menu');
			// empower the quick search keyword
			tool_objects[this_tool_id].quick_search_enable();
			// empower bookmark create links
			bookmark_manager.enable_create_bookmark_buttons();
			// but keep it hidden, if we are in advanced search mode
			if (adv_search_mode != undefined) {
				$('#search-controls_'+this_tool_id).hide();
				$('#quick_keyword_controls_'+this_tool_id).hide();
			}
		});

		// return to caller
		return post_promise;

	}

	// function to reset search options (for searching tools)
	this.reset_search_options = function () {
		var this_tool_id = this['the_tool_id'];

		// sadly, a sequential job
		loading_modal_display('Resetting Search Options...');

		// first, call the 'clear_search_options' method from the back-end
		$.when( query_tool( this['tool_uri'] + '/reset_search_options' ,{}) ).done(function(json_data) {
			// then reload the tools controls
			$.when( tool_objects[this_tool_id].reload_tool_controls() ).done(function() {
				// and finally, reload the search results
				tool_objects[this_tool_id].refresh_json_data();
			});
		});

	}

	// function to power the quick-search keyword search - screens only
	this.quick_search_enable = function () {
		var this_tool_id = this['the_tool_id'];

		if (this['tool_type_short'] == 'screen') {
			// 1. Pause any search refreshing while we are working in the quick search field
			$('.quick_keyword_fields').focusin(function(e) {
				this['search_paused'] = 'Yes';
			});
			$('.quick_keyword_fields').blur(function(e) {
				this['search_paused'] = 'No';
			});

			// 2. Use the enter key to submit the keyword search
			$('.quick_keyword_fields').keyup(function(e) {
				if (e.which == 13) { // that's the enter key
					tool_objects[this_tool_id].process_quick_search('quick_keyword',this.value);
				}
				// show or hide the 'clear' link based on field value
				if (this.value != '') {
					$('#clear_quick_search_button_'+this_tool_id).show();
				} else {
					$('#clear_quick_search_button_'+this_tool_id).hide();
				}
			});

			// hide the clear keyword button by default?
			if ($('#quick_keyword_'+this_tool_id).val() == '') {
				$('#clear_quick_search_button_'+this_tool_id).hide();
			}

			// support allowing them to make the quick-search field an auto-suggest
			// field by naming a function $JS_CLASS_NAME + '_auto_suggest'
			var quick_select_auto_suggest = this['javascript_class'] + '_auto_suggest';
			if (typeof window[quick_select_auto_suggest] == 'function') {
				window[quick_select_auto_suggest]();
			}
		}
	}

	// function to power the Previous / Next links in action screen tools
	this.prev_next_links = function (navigation_to_altcode) {
		// make sure to lift the current lock first
		var this_tool_uri = this['tool_uri']; // pack for faraway trip
		$.when( query_tool(this['tool_uri'] + '/unlock_data',{}) ).done(function(json_data) {
			// then change the uri to trigger omnitool_controller
			location.hash = this_tool_uri + '/' + navigation_to_altcode;
		});
	}

	// function to hide the tool when it is designated as outgoing
	this.hide_tool = function () {

		// if this is a locking tool, we need to call out to its unlock_data method
		if (this['is_locking'] == 'Yes') {
			// the target altcode should be in the display_otions in the DB; otherwise, will respond with harmless error
			var response_data = query_tool(this['tool_uri'] + '/unlock_data',{});
		}

		// make sure to pause any searching going on for that tool
		this['search_paused'] = 'Yes';
		clearInterval(this['background_refresher']);

		// if it's a locking too, we need to stop that as well
		var timer_element_id = this['the_tool_id'] + '_countdown';
		// check to make 100% sure that countdown element is visible, as sometimes locking tools do not lock
		if ( $('#'+timer_element_id).is(':visible') && $('#'+timer_element_id).length && this['is_locking'] == 'Yes' ) {
			$('#'+timer_element_id).countdown("stop");
		}

		// screens and modals can be kept 'warm' in the background, so see if we need to hide them or delete
		if (this['tool_type_short'] == 'screen') {
			// delete if keep_warm=No/Never
			if (this['keep_warm'] == 'No' || this['keep_warm'] == 'Never') {
				$( "#"+this['tool_div'] ).remove();

			// hide if keep_warm=Yes
			} else {
				$( "#"+this['tool_div'] ).hide();
			}
			// set the active screen to 'none' again; almost certainly getting reset by load_tool() in another tool
			the_active_tool_ids['screen'] = 'none';

		} else if (this['tool_type_short'] == 'modal') {
			// delete if keep_warm=No/Never
			if (this['keep_warm'] == 'No' || this['keep_warm'] == 'Never') {
				// make sure to hide before removing (these are asynchronus)
				var this_tool_div = this['tool_div'];
				var this_tool_display_div = this['tool_display_div'];
				$.when( $( "#"+this['tool_div'] ).modal('toggle') ).done(function() {
					// really kill it dead, all the way
					$( "#"+this_tool_display_div ).empty();
					$( "#"+this_tool_div ).remove();
					$('body').removeClass('modal-open');
					$('.modal-backdrop').remove();
				});
			// hide if keep_warm=Yes
			} else {
				$( "#"+this['tool_div'] ).modal('toggle');
			}

			// set the active modal to 'none' again; probably getting reset by load_tool() in another tool
			the_active_tool_ids['modal'] = 'none';

		// all other types, we just remove
		} else {
			$( "#"+this['tool_div'] ).remove();
		}
	}
} // end Tool()
