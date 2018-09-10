/*
	omnitool_routines.js

	Javascript/jQuery routines required to make the OmniTool UI work
*/

// declare some vars here so that they are available everywhere
var session_created;	// will hold the timestamp on their omnitool session
// we need a fingerprint for this window to be used in tools queries
var client_connection_id; // will be filled from the json retrieved from /ui/get_instance_info

// We will tie jemplate templates to specific DOM elements and JSON feed uri's for easy refreshing
var jemplate_bindings = new Array();

// We will also keep our Tool objects in a global assoc. array for easy access
var tool_objects = new Array();

// And we will need to keep track of calls in query_tool()
var query_tool_calls = new Array(); // used so that we always use the latest one
var active_queries = new Array(); // used to track active queries to the server, by uri

// keep track of the active screen and modal tools so we can close when appropriate
var the_active_tool_ids = new Array();
	the_active_tool_ids['modal'] = 'none';
	the_active_tool_ids['screen'] = 'none';
// need to know the ID of which tool is in front, maintained in omnitool_controller()
var the_current_active_tool_id = 'none';

// var to hold the contact email and title fetched just below
var instance_contact_email = '';
var instance_title = '';

// a var to hold the search-refresh set-timeout, for searching tools with background refreshing
var background_refresher;

// a var to let us know when we are in 'API Explorer Mode,' which shows the user the POST requests
// for searching, form, and message tools.  
var api_explorer_mode = 0;
// for managing the view_details displays of the API explorer
var post_data_fetch_do_api_explorer = 0;

// variable to hold the bookmark manager code
var bookmark_manager;

// variable to hold mobile device status
var mobile_device;

// default for whethere or not to run upper_right_autocomplete() / set in your application_wide_functions.js file
var upper_right_search_autocomplete = 0;

// variable to hold timestamp of latest mouse movement
var mouse_move_time = Math.floor(Date.now() / 1000);

// when page is ready, load the instance-info and navigation in
$( document ).ready(function() {
	// show the page-is-loading modal ASAP, before the page is ready
	loading_modal_display('Preparing Interface');

	// figure out the browser's utc offset and time zone name
	// and the server will use that for this connect
	var utc_offset = new Date().getTimezoneOffset();
	var timezone_name = moment.tz.guess();
	// yes, this follows the user's computer time and/or desires.  that's OK, it should

	// extremely ugly hack by a Bootstrap newbie to make the navbar-collapse work with .navbar-fixed-top
	$(window).on('resize', function(){
		if ($(window).width() < 768 && $('#navbar').hasClass('navbar-fixed-top')) {
			$('#navbar').removeClass('navbar-fixed-top');
		} else if (!($('#navbar').hasClass('navbar-fixed-top'))) {
			$('#navbar').addClass('navbar-fixed-top');
		}
	});
	if ($(window).width() < 768) {
		$('#navbar').removeClass('navbar-fixed-top');
	}

	// first, grab the instance information, passing in the utc_offset value
	$.when( query_tool("/ui/get_instance_info?set_utc_offset=" + utc_offset + '&set_timezone_name=' + timezone_name,{}) ).done(function(json) {
		// we are using template toolkit on the server side now to populate
		// this information in the skeleton; however, we will still fetch
		// the instance info for other valuable startup info

		// store instance contact email for fatal error modal
		instance_contact_email = json.contact_email;

		// instance title is nice too
		instance_title = json.instance_title;

		// keep track of session timestamp
		session_created = json.session_created;

		// definitely need the client-connection (read: browser window) ID
		client_connection_id = json.client_connection_id;

		// we need to see if we are in a mobile device
		if ( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
			mobile_device = 1;
		} else {
			mobile_device = 0;
		}

		// set up binding for tools breadcrumbs area, but set the feed URL to 'none' so it won't fire
		jemplate_bindings['breadcrumbs'] = new jemplate_binding('breadcrumbs', '/ui/breadcrumbs_template', 'breadcrumbs.tt', 'none');

		// and also set up the binding for the system modals, but again set the feed URL to 'none' so it won't fire
		jemplate_bindings['system_modal'] = new jemplate_binding('system_modal', '/ui/system_modals_template', 'system_modals.tt', 'none');

		// and a very small Jemplate to allow processing of any DIV with a block from a pre-loaded Jemplate file
		jemplate_bindings['process_any_div'] = new jemplate_binding('process_any_div', '/ui/process_any_div', 'process_any_div.tt', 'none');

		// keep the default tool handy in case we load a bad url
		default_tool = json.default_tool;

		// initiate this copy-to-clipboard class
		var clipboard = new Clipboard('.clipboard_copier');

		// if they did not specify a starting tool, use the 'default_tool' from the instance info
		if (location.hash.length == 0) {
			location.hash = '#' + json.default_tool;

		// if they have pasted in a URL, honor that; do here to make sure we have client_connection_id
		} else {
			omnitool_controller();
		}

		// fire up the bookmark manager js routines
		bookmark_manager = new Bookmark_Manager();
		// empower bookmark create and manage links
		bookmark_manager.enable_create_bookmark_buttons();
		bookmark_manager.enable_manage_bookmarks_button();

		// start the very-important monitoring of the change to the hash / loaction
		$(window).bind('hashchange',omnitool_controller);

	});

	// next, let's build the navigation menu
	// we want to bind the menu bar to our JSON feed and jemplate
	jemplate_bindings['ot_menubar'] = new jemplate_binding('ot_menubar', '/ui/menubar_template', 'ui_menu.tt', '/ui/build_navigation');

	// bind event to track latest mouse movement time, to make sure the search-refreshing
	// does not happen if the mouse has not moved in two minutes
	$( "#main-container" ).mousemove(function( event ) {
		mouse_move_time = Math.floor(Date.now() / 1000);
	});

	// set up the notifications binding in the navbar
	jemplate_bindings['ot_navbar_notifications'] = new jemplate_binding('navbar_notification_area', '/ui/navbar_notifications_template', 'navbar_notifications.tt', '/ui/notifications');
	// refresh those notifications every 90 seconds
	var ot_navbar_notifications_refresh = setInterval(
		function() { 
			// refresh these notifications if the mouse has moved in the past two minutes
			var last_mouse_move = ( Math.floor(Date.now() / 1000) ) - mouse_move_time;
			if (last_mouse_move < 120) {
				jemplate_bindings['ot_navbar_notifications'].process_json_uri();
			}
		},
		90000
	);
	

	// close the modal
	loading_modal_display('hide');

});

// constructor function to create bindings between DOM elements, jemplate templates, and JSON resources
// requires ID of the element, URI of the jemplate (JS form, prepared in utility_belt.pm's jemplate_process() method),
// the name of the jemplate (should be unique, like tool ID) and the URI for the JSON which will fill in the jemplate
// FYI: We do not delete these once created and try to keep them in memory, since the Jemplate is already loaded / executed.
function jemplate_binding (element_id, jemplate_uri, jemplate_name, json_data_uri) {
	// require all four arguments
	if (arguments.length < 4 ) {
		return false;
	}

	// assign the attributes
	this.element_id = '#' + element_id;
	this.jemplate_uri = jemplate_uri;		// if 'preloaded' then it was loaded somewhere else
	this.jemplate_name = jemplate_name;		// need this either way
	this.json_data_uri = json_data_uri; 	// set to 'none' to avoid auto-processing and just send json into process_json_data
	// prevent attempting to process jemplate if ajax not completed below
	this.jemplate_loaded = 0;

	// method to load / reload the jemplate uri
	this.load_jemplate = function () {
		// append the needful to this.jemplate_uri
		var params_connector = '?';
		if (this.jemplate_uri.match('\\?')) {
			params_connector = '&';
		}

		$.ajax({
			url:this.jemplate_uri + params_connector + 'client_connection_id='+client_connection_id + '&uri_base=' + uri_base,
			dataType: "script",
			parent_obj: this, // pass in parent object; it is horrible that you have to do this
			//async:false
			success: function(js_script, textStatus, jqXHR) {
				// check for errors
				var is_error = check_for_errors(js_script);
				if (is_error == 0) { // ok to continue
					// allow processing to occur now on this jemplate
					this.parent_obj.jemplate_loaded = 1;
					// process the jemplate now unless json_data_uri is set to 'none'
					if (this.parent_obj.json_data_uri != 'none') {
						this.parent_obj.process_json_uri();
					}
				}
			}
		});
	};

	// function to render the template
	// calling this again will re-fresh the json_data_uri
	this.process_json_uri = function (modal_text) {
		if (this.jemplate_loaded == 1 && this.json_data_uri != 'none') {
			// oh jquery, you are a pest
			var my_jemplate_name = this.jemplate_name;
			var my_element_id = this.element_id;

			// fetch the data and see if we need to authenticate
			if (this.json_data_uri.match('/ui') && !(this.json_data_uri.match('notifications'))) {
				loading_modal_display('Preparing Interface...');
			} else if (modal_text != undefined && modal_text != 'none') {
				loading_modal_display(modal_text + '...');
			// do not show a modal for breadcrumbs / navbar_notification_area
			} else if (my_element_id != '#breadcrumbs' && my_element_id != '#navbar_notification_area' && modal_text != 'none') {
				loading_modal_display('Retrieving Data...');
			}

			$.when( query_tool(this.json_data_uri,{}) ).done(function(data) {
				if (my_element_id != '#breadcrumbs' && my_element_id != '#navbar_notification_area' && modal_text != 'none') { // they may not want to see this
					loading_modal_display('Processing Data...');
				}

				// process the jemplate
				if ($.isEmptyObject(data) == false) {
					// do the actual process
					Jemplate.process(my_jemplate_name, data, my_element_id);
				}
				// we also need to call 'post_data_fetch_operations()' with this JSON
				// data, as it may contain post-jemplate behavior instructions
				if (data.one_record_mode == undefined && data.skip_post_data_ops == undefined) { // but not in one-data mode, as that's just very minimal JSON
					post_data_fetch_operations(data);
				}
				if (my_element_id != '#breadcrumbs' && my_element_id != '#navbar_notification_area' && modal_text != 'none') { // only chose a modal if we opened one
					loading_modal_display('hide');
				} else {
					if (upper_right_search_autocomplete != 0) {
						upper_right_autocomplete();
					}
				}
			});
		}
	};

	// special function to pass in JSON data to render rather than pull the JSON uri
	this.process_json_data = function (json_data) {
		if (this.jemplate_loaded == 1 && $.isEmptyObject(json_data) == false) {
			Jemplate.process(this.jemplate_name, json_data, this.element_id);
			// we also need to call 'post_data_fetch_operations()' with this JSON
			// data, as it may contain post-jemplate behavior instructions
			// but not in one-data mode, as that's just very minimal JSON
			if (json_data.one_record_mode == undefined && json_data.skip_post_data_ops == undefined) {
				post_data_fetch_operations(json_data);
			}
		}
	};

	// on create, grab the jemplate template script from the server & process it
	// if not pre-loaded
	if (this.jemplate_uri != 'preloaded') {
		// use the method above
		this.load_jemplate();

	// otherwise, assume we already have it
	} else {
		this.jemplate_loaded = 1;
		// process the jemplate now unless json_data_uri is set to 'none'
		if (this.json_data_uri != 'none') {
			this.process_json_uri();
		}
	}

}

// function to follow instructions embedded within JSON data from tools
// lots of magic happens here
function post_data_fetch_operations (data) {
	// make the sidebar links work even when clicking on the active tool
	// have to do it here, so that the menubar gets played-with during tool load-up
	if (data['menu'] != undefined && data['menu'][0]['button_name'] != undefined) { // it's the menubar
		$( ".menubar_tool_link" ).click(function() {
			if ( $(this).attr("href") != '#' && $(this).attr("href") == location.hash ) {

				omnitool_controller({},$(this).attr("href"));

				// it's going to be a screen if they can see the menubar and the link appears in the menubar
				// var the_tool_id = the_active_tool_ids['screen'];

				// refresh the data and the jemplate
				// tool_objects[the_tool_id].refresh_json_data();
			}
		});

		// also make sure the bookmark links are enabled
		bookmark_manager.enable_create_bookmark_buttons();
		bookmark_manager.enable_manage_bookmarks_button();
	}

	// breadcrumbs mode: empower the app-wide search box which will appear in the breadcrumbs area
	if (data.appwide_search_function != undefined && data.appwide_search_function != 'None') {
		$('.appwide-search').submit(function( event ) {
			event.preventDefault();
			window[data.appwide_search_function]();
		});
	}

	// NOTIFICATIONS ONLY: urgent/dager notice?
	if (data.notification_count != undefined) {
		show_or_hide_element('urgent_notification', data.urgent_notification);
	}

	// stash the server-reported response_epoch
	if (data.response_epoch != undefined) {
		tool_objects[data.the_tool_id]['response_epoch'] = data.response_epoch;
	}

	// the rest is for Tools' JSON only, so return if no data provided
	if (data.session_created == undefined) {
		return;
	}

	// enable any pop-overs that were just loaded up
	enable_popovers();
	
	// attach the sent altcode/data_code to the tool, for possible un-locking purposes -- and maybe refreshing that targeted record
	if (data.altcode) {
		tool_objects[data.the_tool_id]['current_altcode'] = data.altcode;
	} else {
		tool_objects[data.the_tool_id]['current_altcode'] = 'none';
	}
	if (data.data_code) {
		tool_objects[data.the_tool_id]['current_data_code'] = data.data_code;
	} else {
		tool_objects[data.the_tool_id]['current_data_code'] = 'none';
	}	
 	
	// reveal the 'return to tool' link, if one was provided
	$('.return_link').hide();
	if (data.the_tool_id == the_active_tool_ids['screen'] && data.return_link_uri && data.return_link_title) {
		$('.return_link').html('<i class="fa fa-arrow-left blue"></i> Return to ' + data.return_link_title);
		$('.return_link').attr("href", data.return_link_uri);
		$('.return_link').show();
	} else if (data.the_tool_id == the_active_tool_ids['screen']) {
		$('.return_link').hide();
	}

	// if this is a searching tool, keep track of the list of altcodes found, for previous/next buttons in sub-tools
	// also sneak in the advanced_search_filters_badge number ;)
	if (tool_objects[data.the_tool_id]['tool_type'] == 'Search - Screen' && !data.one_record_mode) {
		localStorage.setItem("altcodes_keys_" + data.the_tool_id , data.altcodes_keys);

		// we need to stash the sent records_keys into the tool_object
		tool_objects[data.the_tool_id]['records_keys'] = data.records_keys;

		// be sure to always hide the next/previous buttons for these
		$('.next_link').hide();
		$('.previous_link').hide();
		// use our little utility function to show and hide some indicator badges / text:
		// 1. How many advanced search filters we are using
		show_or_hide_element('advanced_search_filters_badge_'+data.the_tool_id, data.advanced_search_filters);
		// 2. and how many advanced sort options
		if (data.advanced_sort_options != undefined) {
			show_or_hide_element('advanced_sort_options_badge_'+data.the_tool_id, data.advanced_sort_options.length);
		} else {
			show_or_hide_element('advanced_sort_options_badge_'+data.the_tool_id, 0);
		}
		// 3. search-is-limited notice?
		show_or_hide_element('top_notice_'+data.the_tool_id, data.limit_notice);

		if (data.breadcrumbs_notice) { // some filters used, show that number
			$('#breadcrumbs_area').html( data.breadcrumbs_notice );
			$('#breadcrumbs_area').addClass( 'center bigger-125 bolder' );
		}

		// show the results and time took to load -- including transfer, as this was calcuated in query_tool
		if (data.records_found_count) {
			var records_word;
			if (data.records_found_count == 1) {
				records_word = 'record';			
			} else {
				records_word = 'records';			
			}
			$('#above_tool_display_'+ data.the_tool_id).html('<i>Found ' + data.records_found_count + ' ' + records_word + ' in ' + data.response_time + ' seconds.</i>');
		} else {
			$('#above_tool_display_'+ data.the_tool_id).html('');
		}

		// if the advanced search screen is open, be sure to shrink the main area
		if (tool_objects[data.the_tool_id].advanced_search_open == 1) {
			tool_objects[data.the_tool_id].shrink_or_grow_tool_display('shrink');
		}

	// if it is an action screen, we shall show previous & next buttons plus any inline actions
	} else if (tool_objects[data.the_tool_id]['tool_type'] == 'Action - Screen') {
		if (localStorage.getItem("altcodes_keys_" + data.parent_tool_id)) {
			var parent_tools_results = localStorage.getItem("altcodes_keys_" + data.parent_tool_id).split(',');
			for (var i = 0; i < parent_tools_results.length; i++) {
				if (data.altcode == parent_tools_results[i] || data.data_code == parent_tools_results[i]) {
					var previous_altcode = parent_tools_results[i-1];
					var next_altcode = parent_tools_results[i+1];
				}
			}
		}

		// default is to hide these next / previous buttons
		$('.next_link').hide();
		$('.previous_link').show();
		$('.previous_link').css('visibility','hidden');

		// if there's a previous record, link to this action for that record
		if (previous_altcode != undefined) {
			$('.previous_link').html('<i class="fa fa-fast-backward blue"></i> Previous ' + data.datatype_name);
			$('.previous_link').attr("onclick", "tool_objects['" + data.the_tool_id + "'].prev_next_links('" + previous_altcode + "')");
			$('.previous_link').css('visibility','visible');
		}
		// same deal for the next records
		if (next_altcode != undefined) {
			$('.next_link').html('Next ' + data.datatype_name + ' <i class="fa fa-fast-forward blue"></i>');
			$('.next_link').attr("onclick", "tool_objects['" + data.the_tool_id + "'].prev_next_links('" + next_altcode + "')");
			$('.next_link').show();
		}

		// if there are inline actions, show the secondary 'quick actions' drop-down
		if (data['inline_actions'] != undefined && data['inline_actions'][0]['button_name']) {
			Jemplate.process('inline_action_menu.tt', data, '#quick_inline_actions_menu_' + data.the_tool_id);
			$('#quick_inline_actions_menu_' + data.the_tool_id).show();
		} else {
			$('#quick_inline_actions_menu_' + data.the_tool_id).hide();
		}

		// show a top notice?
		show_or_hide_element('top_notice_'+data.the_tool_id, data.top_notice);

	}
	
	// see Tool.load_tool(), but the short story is that we will need to allow for the
	// API explorer for view_details tools
	if (post_data_fetch_do_api_explorer == 1) {
		open_api_explorer_modal({
			'uri':tool_objects[data.the_tool_id]['called_via_uri']+'/send_json_data',
			'post_parameters': data.search_parameters,
			'results_data': data,
			'tool_name': tool_objects[data.the_tool_id]['name'],
		});
		// one time per created Tool
		post_data_fetch_do_api_explorer = 0;
	}

	// empower any tool quick/inline actions drop-down menus - do async for speed's sake
	enable_chosen_menu('.tool-action-menu');

	// if their session was flushed since we last checked
	// reload the menubar, clear the backgrounded tools,
	// and suggest reloading the current tool
	if (session_created < data.session_created) {
		// reload the menubar
		jemplate_bindings['ot_menubar'].process_json_uri();

		// clear background/warm tools, as they very well could have been reloaded
		for (var the_tool_id in tool_objects) {
			// only screens and modals which are not active
			if (the_active_tool_ids['screen'] != the_tool_id && the_active_tool_ids['modal'] != the_tool_id) {
				// only if it is set to be kept warm and they already have the div loaded
				if (tool_objects[the_tool_id]['keep_warm'] == 'Yes' && $( "#"+tool_objects[the_tool_id]['tool_div'] ).length > 0) {
					$( "#"+tool_objects[the_tool_id]['tool_div'] ).remove();
				}
			}
		}

		// notify them that things might get weird and they may want to reload
		if (data.session_dev_mode == undefined) { // suppress this in dev mode
			create_gritter_notice({
				title: 'Session Refreshed - Consider Reloading',
				message: 'Your OmniTool session has been refreshed, most likely due to changes deployed by the developers.  Please reload the page if you encounter strange behavior.'
			});
		}

		// update session_created with the new value
		session_created = data.session_created;
	}

	// if a 'execute_function_on_load' was sent, that means this tool_mode
	// has a function associated with it which we should call
	if (data.execute_function_on_load != undefined) {
		// will have a 'the_tool_id' attribute too, which the function will likely need
		window[data.execute_function_on_load](data.the_tool_id);
	}

	// if there is a 'single_record_jemplate_block' setting, please make sure that is saved to the tool's object,
	// so that we can just refresh the target result when a modal or message tool closes
	if (data.single_record_jemplate_block != undefined) {
		tool_objects[data.the_tool_id]['single_record_jemplate_block'] = data.single_record_jemplate_block;

		// auto-refreshing on a single-record basis?
		if (data.single_record_refresh_mode != undefined) {
			tool_objects[data.the_tool_id]['single_record_refresh_mode'] = data.single_record_refresh_mode;
		} else { // make it No
			tool_objects[data.the_tool_id]['single_record_refresh_mode'] = 'No';
		}

	// if that is missing, make sure to clear it out, if this request was in service to a tool
	} else if (data.single_record_jemplate_block == undefined && data.the_tool_id != undefined) {
		tool_objects[data.the_tool_id]['single_record_jemplate_block'] = 0;
	}

	// if the current tool view mode wants to display a chart above the tool results, call render_tool_chart()
	if (data.display_a_chart != undefined) {
		render_tool_chart(data.the_tool_id);
	} else { // otherwise, make sure any charts are hidden
		$("div[id^='chartarea_']").hide();
	}

	// bind column-sorting to column headings
	$( ".omnitool-heading" ).click(function() {
		// if this tool has advanced search & advanced sort available, and we are not in the
		// enhanced table let's open advanced sort
		if ( ! $.fn.DataTable.isDataTable( '#tool_results_' + data.the_tool_id ) && $('#advanced_sort_features_'+the_tool_id).length ) {
			tool_objects[data.the_tool_id].show_advanced_sort();

		// otherwise, standard one-column sort
		} else {
			// determine the new direction
			var new_sort_direction;
			if (data.sort_direction == 'Up') {
				new_sort_direction = 'Down';
			} else {
				new_sort_direction = 'Up';
			}

			// use tool's function to handle sorting
			tool_objects[data.the_tool_id].update_sorting( $(this).data('otsortcol'), new_sort_direction );
		}
	});

	// show the proper sort icon, if not in datatable mode
	$( ".omnitool-heading" ).find('.fa').hide();
	if ( ! $.fn.DataTable.isDataTable( '#tool_results_' + data.the_tool_id ) ) {
		if (data.advanced_sort_options!= undefined && data.advanced_sort_options.length) {
			for (i = 0; i < data.advanced_sort_options.length; i++) {
				var advaced_sort_choices = data.advanced_sort_options[i].split(' | ');
				// first one is the sort column, second is the direction
				// use utility method below
				show_sort_arrow(advaced_sort_choices[0], advaced_sort_choices[1]);
			}

		// simple / single search, just use method below
		} else {
			show_sort_arrow(data.sort_column, data.sort_direction);
		}
	}

	// empower any timers which may be embedded within content we just loaded
	// specificially for tools which time out due to locks
	var timer_element_id = data.the_tool_id + '_countdown';
	var timer_home_element_id = data.the_tool_id + '_countdown_area';
	// proceed if we are a locking tool, the countdown is there & we have a return link -- also, not 'create a tool' as that will have 'lock_lifetime' as form param
	if (data.the_tool_id != '1_1_16_1' && data.lock_lifetime && $('#'+timer_element_id).length && data.return_link_uri != undefined) {

		// how many seconds to run? default to 'lock_lifetime'
		if (data.lock_lifetime) {
			var countdown_seconds = data.lock_lifetime * 60;
		} else { // default to five minutes
			var countdown_seconds = 300;
		}
		
		// use the countdown timer routines in the Tool object for this timer
		tool_objects[data.the_tool_id].start_lock_countdown(countdown_seconds, data.return_link_uri);


	// otherwise, hide the countdown area if it exists
	} else if ($('#'+timer_home_element_id).length) {
		$('#'+timer_home_element_id).hide();
	}

	// are they asking to see the (or some) JSON displayed?
	if ($('#'+data.the_tool_id+'_show_json').length) {
		$('#'+data.the_tool_id+'_show_json').html('<pre>'+JSON.stringify(data, undefined, 2)+'</pre>');
	} else if ($('#'+data.the_tool_id+'_show_json_results').length && data.results != undefined) {
		$('#'+data.the_tool_id+'_show_json_results').html('<pre>'+JSON.stringify(data.results, undefined, 2)+'</pre>');
	}

	// if we are in calendar mode, feed the calendar our 'events' sub-hash
	if ($('#'+data.the_tool_id+'_calendar').length) {
		// if it's an action tool, data.events[] will be filled
		if (data.events != undefined) {
			$('#'+data.the_tool_id+'_calendar').fullCalendar( 'removeEvents');
			$('#'+data.the_tool_id+'_calendar').fullCalendar( 'addEventSource', data.events );

		// otherwise, we are in search mode and need to jury-rig data.records in there
		} else if (data.records_keys.length) {
			// start our new array to hold the objects
			data.events = [];

			// center_stage.pm->send_json_data() is smart enough to include a 'included_records_fields'
			// array for the JSON so we know which fields to use: the first one will be the name for the
			// calendar event and the second one is the date to place it on
			// the 'url' will be the first inline action, if any

			var name_key = data.included_records_fields[0];
			var date_key = data.included_records_fields[1];

			for (i = 0; i < data.records_keys.length; ++i) {
				var key = data.records_keys[i];
				data.events.push({
					title: data.records[key][name_key],
					id: key,
					start: data.records[key][date_key],
					url: data.records[key].inline_actions[0].uri
				});
			}

			// load the calendar
			$('#'+data.the_tool_id+'_calendar').fullCalendar( 'removeEvents');
			$('#'+data.the_tool_id+'_calendar').fullCalendar( 'addEventSource', data.events );

		}
	}
	
}

// utility function to either show an element with html or hide it
function show_or_hide_element (element_id, some_content) {
	if (some_content != undefined && some_content != 0) { // something to show, then show it
		$('#' + element_id).html( some_content );
		$('#' + element_id).show();
	} else { // no filters, hide it out
		$('#' + element_id).html('');
		$('#' + element_id).hide();
	}
}

// utility function to show/hide sort arrows in table headings; used in post_data_fetch_operations
function show_sort_arrow(sort_column, sort_direction) {
	var new_sort_icon;
	var old_sort_icon;
	if (sort_direction == 'Up') {
		new_sort_icon = 'fa-arrow-up';
		old_sort_icon = 'fa-arrow-down';
	} else {
		new_sort_icon = 'fa-arrow-down';
		old_sort_icon = 'fa-arrow-up';
	}

	// update the classes
	$(".omnitool-heading[data-otsortcol='" + sort_column +"']").find('.fa').removeClass(old_sort_icon);
	$(".omnitool-heading[data-otsortcol='" + sort_column +"']").find('.fa').addClass(new_sort_icon);
	$(".omnitool-heading[data-otsortcol='" + sort_column +"']").find('.fa').show();
}

// function enable popovers on page change; called from post_data_fetch_operations()
// and when reloading a single result (and maybe more spots later ;>)
function enable_popovers () {
	// first, hide any open popovers
	$('.popover').remove();
	// then re-enable any which have just loaded
	$('[data-rel=popover]').popover({
		'container': 'body',
		'html': true,
	});
}

// function to show/hide the 'content loading' modal
function loading_modal_display (display_text) {
	// if the loading modal is already open and they want to change the display text, do that
	if ($("#modal-loading").hasClass('in') && display_text != undefined && display_text != 'hide') {
		// $("#modal-loading").modal('hide');
		$('#modal-loading-text').text(display_text + '...');
	// if it's not shown and there is display text, show the modal
	} else if (display_text != undefined && display_text != 'hide') {
		$('#modal-loading').modal({
			backdrop: false,
			keyboard: true,
		});
		$('#modal-loading-text').text(display_text + '...');
	// otherwise, hide it
	} else if ($("#modal-loading").hasClass('in')) {
		$("#modal-loading").modal('hide');
	}
}

// this function manages the Tool objects and displays/hides them based on
// the location hash; Works with the tool_objects assoc. array and Tool below
// as per ready() function above, it is triggered by changes in the location hash
// or you can pass the uri you want as an argument, if using JS (be careful)
function omnitool_controller (event,target_tool_uri) {
	if (target_tool_uri == undefined || target_tool_uri == '') {
		// find the base-uri for the desired tool
		var tool_uri = location.hash.replace( /^#/, '' );
		if (tool_uri == '') { // was only '#'
			location.hash = '#' + default_tool;
			return; // no need to continue
		}
	} else {
		var tool_uri = target_tool_uri.replace( /^#/, '' );
	}

	// tell the user we are loading -- take this out later
	if (event == undefined || event.message_tool == undefined) {
		loading_modal_display('Loading...');
	}
	
	// no double slashes
	var tool_uri = tool_uri.replace( /\/\//, '/' );

	// first step is to resolve that uri to a tool ID (app-inst + tool_id)
	// we do it this way because a specific tool may have multiple uri's, and
	// we don't want to build objects on a per-uri basis, but rather per-tool_id
	$.when( get_tool_id_for_uri(tool_uri) ).done(function(tool_attributes) {
		
		var the_tool_id = tool_attributes.the_tool_id;
		
		// if the tool was not found, jump to the default
		if (the_tool_id == 'TOOL_NOT_FOUND') {
			location.hash = '#' + default_tool;
			return; // no need to continue
		}

		// if they are loading a bookmark, force reload the whole tool
		var loading_bookmark = 0;
		if (tool_uri.match(/\/bkmk[^\/]*/)) {
			loading_bookmark = 1;
			// clean off the bookmark portion of the URL
			tool_uri = tool_uri.replace(/\/bkmk[^\/]*/,'');
			// location.hash = '#' + tool_uri;
		}

		// now see if it is the active tool
		var this_active_tool = 'Not Found';
		for (var tool_type in the_active_tool_ids) {
			if (tool_type !='message' && the_active_tool_ids[tool_type] == the_tool_id) {
				this_active_tool = the_tool_id;
				break; // no need to continue
			}
		}

		// will need to know the tool we are discarding, for the record refreshing below
		var outgoing_tool_id = the_current_active_tool_id;

		// if they are moving to a new phase/method of the active tool, update that tool's jemplate binding
		if (this_active_tool != 'Not Found') {
			// if keep-warm = Never, we need to always start fresh
			if (tool_objects[the_tool_id]['keep_warm'] == 'Never' || loading_bookmark == 1) {
				if ($( "#"+tool_objects[the_tool_id]['tool_div'] ).length > 0) {
					// first delete
					$( "#"+tool_objects[the_tool_id]['tool_div'] ).remove();
					// then reload
					tool_objects[the_tool_id].load_tool();
				}
			} else if (tool_uri.match('tool_mode')) { // changing tool mode; reload the jemplate
				jemplate_bindings[ tool_objects[the_tool_id]['tool_display_div'] ].load_jemplate();

			// re-opening modals are fairly straight-forward
			} else if (tool_objects[the_tool_id]['tool_type_short'] == 'modal') {
				tool_objects[the_tool_id].load_tool();

			// screens have a lot of caveats
			} else if (tool_objects[the_tool_id]['tool_type_short'] == 'screen') { // basically just need to re-load the JSON feed, since they almost certainly changed the data-id arg
				// if it's a screen tool, and has a setting for 'single_record_jemplate_block', then just refresh the target
				if (tool_objects[the_tool_id]['single_record_jemplate_block'] != undefined && tool_objects[the_tool_id]['single_record_jemplate_block'] != 0) {

					// if there was a current altcode for the outgoing tool, refresh that record
					if (tool_objects[outgoing_tool_id] != undefined && tool_objects[outgoing_tool_id]['current_altcode'] != undefined && tool_objects[outgoing_tool_id]['current_altcode'] != 'none') {
						tool_objects[the_tool_id].refresh_one_result( tool_objects[outgoing_tool_id]['current_altcode'] );
 						// and make sure it is the active tool
						the_active_tool_ids['screen'] = the_tool_id;
						tool_objects[the_tool_id]['search_paused'] = 'No';

					// otherwise, refresh all the records
					} else {
						// also reload the tool_controls, in case the keyword changed
						$.when( tool_objects[the_tool_id].reload_tool_controls() ).done(function() {
							// then re-run the process_json_uri
							jemplate_bindings[ tool_objects[the_tool_id]['tool_display_div'] ].process_json_uri();
							// hide the advanced search?
							if ($('#advanced_search_' + the_tool_id).is(':visible')) {
								tool_objects[the_tool_id].show_advanced_search();
							}
						});
					}

				// and if it's a screen without a single_record_jemplate_block, just reload all the displayed results for this tool
				} else {
					// first reload the tool_controls, in case the keyword changed
					$.when( tool_objects[the_tool_id].reload_tool_controls() ).done(function() {
						// then re-run the process_json_uri
						jemplate_bindings[ tool_objects[the_tool_id]['tool_display_div'] ].process_json_uri();
						// and un-pause the search
						tool_objects[the_tool_id]['search_paused'] = 'No';
						// hide the advanced search?
						if ($('#advanced_search_' + the_tool_id).is(':visible')) {
							tool_objects[the_tool_id].show_advanced_search();
						}
					});
				}
			}
			// your jemplate should be all-inclusive for this tool's needs

			// get the breadcrumbs right, if in screen mode
			if (tool_objects[the_tool_id]['tool_type_short'] == 'screen') {
				jemplate_bindings['breadcrumbs'].json_data_uri = tool_uri + '/send_breadcrumbs'; // ?client_connection_id='+client_connection_id;
				jemplate_bindings['breadcrumbs'].process_json_uri();

				// close any open modals when reloading this screen
				tool_objects[the_tool_id].close_modal_for_screen();
			}

		// do we already have a tool object?
		} else if (tool_objects[the_tool_id] == undefined) { // no, need to create
			// create the object with the attributes we already have
			
			// we need to know the 'starting' uri for this tool for api_explorer_mode
			tool_attributes.called_via_uri = tool_uri;
			// construct the new Tool object and call load_tool() to trigger the message
			tool_objects[the_tool_id] = new Tool(tool_attributes);
			tool_objects[the_tool_id].load_tool();

		} else { // yes, just load it up
			// if keep-warm = Never, we need to always start fresh
			if (tool_objects[the_tool_id]['keep_warm'] == 'Never') {
				$( "#"+tool_objects[the_tool_id]['tool_div'] ).remove();
			}

			// load it up at last
			if (tool_uri.match('tool_mode')) { // force the jemplate to reload
				tool_objects[the_tool_id].load_tool(1);

			} else { // normal re-load of previous-inactive tool

				$.when( tool_objects[the_tool_id].load_tool(0,1) ).done(function() {

					// does it qualify for a single-item reload?  if so, just do that
					if (tool_objects[the_tool_id]['tool_type_short'] == 'screen' && tool_objects[the_tool_id]['single_record_jemplate_block'] != undefined && tool_objects[the_tool_id]['single_record_jemplate_block'] != 0
					&& tool_objects[outgoing_tool_id] != undefined && tool_objects[outgoing_tool_id]['current_data_code'] != undefined && tool_objects[outgoing_tool_id]['current_data_code'] != 'none') {
						tool_objects[the_tool_id].refresh_one_result( tool_objects[outgoing_tool_id]['current_data_code'] );

					// otherwise, reload the tool controls and the json
					} else {
						// also reload the tool_controls, in case the keyword changed
						$.when( tool_objects[the_tool_id].reload_tool_controls() ).done(function() {
							// then re-run the process_json_uri
							jemplate_bindings[ tool_objects[the_tool_id]['tool_display_div'] ].process_json_uri();
							// hide the advanced search?
							if ($('#advanced_search_' + the_tool_id).is(':visible')) {
								tool_objects[the_tool_id].show_advanced_search();
							}
						});
					}
				});

			}

		}

		// set the actual current active tool id
		the_current_active_tool_id = the_tool_id;

	});
	// we will rely on the Tool object from here on

}

// simple func to get tool id's from the server for the requested uri
function get_tool_id_for_uri (tool_uri) {
	// must have an argument
	if (tool_uri == undefined) {
		return false;
	}

	// try to use the current tool as the 'return' link
	var return_tool_id = the_active_tool_ids['screen'];

	// can't cache it because you may be changing back and forth between data-id bits,
	// such as how the tools_mgr does or when opening update forms over and over
	// so instead of boring 'send_tool_id', grab the attributes in hopes of skipping a step
	return $.when( query_tool(tool_uri + '/send_attributes',{return_tool_id: return_tool_id}) ).done(function(tool_attributes) {

		check_for_errors (tool_attributes);

		return tool_attributes;
	});
}

// re-usable function to send a post query to a tool's uri
// will auto-include the client_connection_id for us
// need this outside of the Tool object, as we rely on it
// to figure out those objects
// usage: response_data = query_tool('/tools/some_tool/method',post_data_object);
function query_tool (tool_uri,post_data_object) {
	// uri is required
	if (tool_uri == undefined) {
		return false ;
	}

	// make sure client_connection_id is in there
	if (client_connection_id != '') {
		post_data_object.client_connection_id = client_connection_id;
	}

	// if we are using a 'uri_base', pass that back to the server
	if (uri_base != undefined && uri_base != '') {
		post_data_object.uri_base = uri_base;
	}

	// note that this is now the latest call
	if (query_tool_calls[tool_uri] == undefined) {
		query_tool_calls[tool_uri] = 0;
	}
	query_tool_calls[tool_uri] += 1;

	// and for testing below (the above would have been updated in the later call)
	var this_calls_counter = query_tool_calls[tool_uri];

	// we need to make sure the tool.refresh_json_data knows this send_json uri is already active
	if (tool_uri.match('send_json_data')) { // will raise and lower the number in this array accordingly
		if (active_queries[tool_uri] == undefined) { // this is the first one
			active_queries[tool_uri] = 1;
		} else {
			active_queries[tool_uri] += 1;
		}
	}

	// let's time this transfer
	var start = new Date();

	// all ourselves to send arrays via the post object
	jQuery.ajaxSettings.traditional = true;

	// use a promise so that we can make sure to return the value
	var post_promise = $.post(
		tool_uri, post_data_object
	).done(function (response) {
		// check response for errors using function below
		var is_error = check_for_errors(response);

		// we are tracking the number of active send_json_data calls to prevent
		// automatic refreshes from overriding user-initiated queries
		if (tool_uri.match('send_json_data')) {
			active_queries[tool_uri] -= 1;
		}

		if (is_error == 1) { // failed, return false
			return false;

		// if it is not the latest call for this uri, return an empty object
		} else if (tool_uri.match('send_json_data') && query_tool_calls[tool_uri] > this_calls_counter) {
			return {};

		} else { // success, send the response out to our parent scope
			// for our response-time tracking
			var end  = new Date();
			// pack that up as seconds
			response.response_time = (end.getTime() - start.getTime()) / 1000;

			// now return it
			return response;
		}
	})
	.fail(function (jqXHR, textStatus, errorThrown) {
		var is_error = check_for_errors(jqXHR.responseText);
		return false;
	});

	// return to caller
	return post_promise;
}

// function to check the results of a query to the server, and alert the user as needed
function check_for_errors (response) {
	
	if (response == undefined) { // nothing to do here
		return 0;
	}	

	// did it indicate they need to log in?
	if (typeof response == 'string' && response == 'Authentication needed.') { // send them to login page
		location.reload();
		return 1; // indicate error is found

	// did the request timeout?
	} else if ( typeof response == 'string' && response.match(/Execution failed due to timeout/) ) { // show the error
		var data = {
			modal_title_icon: 'fa-clock',
			modal_title:  'Request Timed Out',
			instance_contact_email: instance_contact_email,
			instance_title: instance_title,
			fatal_error_message: 'Your request has timed-out.  Please adjust your parameters and re-submit.',
			simple_error: 1,
			timeout_error: 1,
			is_maintenance: response.match(/Execution/), // this works the opposite of how you'd expect
		};
		open_system_modal(data);
		return 1; // indicate error is found

	// did it receive a fatal error notice?  or maybe a 'undergoing maintenance' notice
	} else if ( typeof response == 'string' && response.match(/Execution failed|undergoing maintenance/) ) { // show the error
		var data = {
			modal_title_icon: 'fa-exclamation-circle',
			modal_title:  'Action Could Not Be Completed',
			instance_contact_email: instance_contact_email,
			instance_title: instance_title,
			fatal_error_message: response,
			fatal_error_message_encoded: encodeURIComponent(response),
			is_maintenance: response.match(/Execution/), // this works the opposite of how you'd expect
		};
		open_system_modal(data);
		return 1; // indicate error is found

	// did the tool command us to throw an error modal?
	} else if (response.show_error_modal != undefined) { // show the error
		var data = {
			modal_title_icon: 'fa-exclamation-circle',
			modal_title:  response.error_title,
			instance_contact_email: instance_contact_email,
			fatal_error_message: response.error_message,
			fatal_error_message_encoded: encodeURIComponent(response.error_message),
			is_maintenance: true, // this works the opposite of how you'd expect
			simple_error: response.simple_error, // will suppress the 'please report' bit if true
		};
		open_system_modal(data);
		return 1; // indicate error is found

	// otherwise, no errors found
	} else {
		return 0;
	}
}

// method to load the system modals via jemplate - system_modals.tt under static_files
function open_system_modal (data) {
	// push the data into it
	jemplate_bindings['system_modal'].process_json_data(data);

	// then show it
	$.when( $('#system_modal').modal({
		backdrop: 'static',
		keyboard: true
	}) ).done(function() {
		// if this is the extend-lock modal, don't let them close it with the Escape key
		if (data.lock_timeout_warning == 1) {
			$('#system_modal').data('bs.modal').options.keyboard = false;
			$('#system_modal').off('keydown.dismiss.bs.modal');
		} else {
			$('#system_modal').data('bs.modal').options.keyboard = true;
			$('#system_modal').data('bs.modal').escape();
		}
	
		loading_modal_display('hide');
	});
}

// method to display the terms of service; accessed via username drop-down in UI
// link should only be visible if terms_of_service.tt exists in $CODE_DIR/jemplates
function open_terms_of_service (data) {
	
	// open the modal
	$.when( open_system_modal({
		terms_of_service: 1,
		modal_title: instance_title + ' Terms of Service',
		modal_title_icon: 'fa-legal'
	}) ).done(function() {
		
		// and then load and render the terms of service for this application instance
		jemplate_bindings[ 'terms_of_service' ] = new jemplate_binding(
			'terms_of_service',
			'/ui/send_jemplate?jemplate=jemplates/terms_of_service.tt',
			'terms_of_service.tt',
			'/ui/get_instance_info'
		);
	
	});
		
}

// method to open up the API Information modal
function open_api_info_modal (data) {
	// open the modal
	open_system_modal({
		api_info: 1,
		api_explorer_mode_on: api_explorer_mode,
		modal_title: instance_title + ' API Information',
		instance_contact_email: instance_contact_email,
		system_uri_base: system_uri_base, // got that from bottom_javascript.tt
		modal_title_icon: 'fa-code'
	});
}

// support the toggling of api explorer mode
function toggle_api_explorer_mode () {
	if (api_explorer_mode > 0) {
		api_explorer_mode = 0;
	} else {
		api_explorer_mode = 1;
	}
}

// support for the actual API explorer; will get called if api_explorer_mode = 1, when
// we (a) submit a tool's form, (b) access a Message Action Tool, (c) run process_quick_search()
// for a Searching tool or (d) submit the Advanced Search form
// relies on the api_explorer part of system_modals.tt
function open_api_explorer_modal (data) {
	// that data struct will have: 
	// 	uri = the URI to post to
	//	post_parameters = either an array of the form's data or the search_parameters from Tool::searcher()
	// 	results_data = the json_data that was sent back from the OT6 server
	//	tool_name = the name of the Tool that was just queried, for which this query will work
	
	// do not do this if the explorer modal is already open, i.e. when a message tool fires and then underlying search tool right behind it
	if ($("#system_modal").hasClass('in')) {
		return;
	}

	// add in the instance's base URI
	data.uri_base = uri_base;

	// need the hostname for the uri
	data.hostname = location.hostname;

	// tell system_modals.tt to show this
	data.api_explorer_mode = 1;
	
	// pass the title / icon info / instance contact
	data.modal_title = 'API / POST Query Details for ' + data.tool_name;
	data.modal_title_icon = 'fa-code';
	data.instance_contact_email = instance_contact_email;
	data.system_uri_base = system_uri_base;
	
	data.post_parameters_string = JSON.stringify(data.post_parameters, undefined, 2);
	
	// form submits will have post_parameters as a list of hash
	if (Array.isArray(data.post_parameters)) {
		data.form_submission = 1;
	}
	
	// stringified version of the data sent back from the OT6 server
	data.results_data_string = JSON.stringify(data.results_data, undefined, 2);
	
	// open the modal
	open_system_modal(data);
}


// class-level method to call for gritter, since both load_tool and submit_form uses it
// just pass the json_results in; outside of Tool to simplify calling from within callback
create_gritter_notice = function(data) {
	if (data == undefined) {
		return;
	}

	// start from blanks
	var this_tool_title = '';
	var this_tool_message = '';
	var this_tool_class = '';

	// process our result
	if (data.error_message != undefined) { // we have an error to display
		if (data.error_title == undefined || data.error_title == '') {
			this_tool_title = 'Error';
		} else {
			this_tool_title = data.error_title;
		}
		this_tool_message = data.error_message;
		this_tool_class = 'gritter-warning';
	} else { // display what's in data.message
		if (data.title == undefined || data.title == '' || data.gritter_skip_title != undefined) {
			this_tool_title = 'Success!';
		} else {
			this_tool_title = data.title;
		}
		this_tool_message = data.message;
		if (data.title == undefined) { // may just have a title
			this_tool_message = ' ';
		}
		this_tool_class = 'gritter-success';
	}

	// leave it up there
	var is_sticky = false;
	var message_time = 10000; // default time is 10 seconds
	if (data.message_is_sticky == 'Yes') {
		is_sticky = true;
	// how long to leave up there
	} else if (data.message_time != undefined) {
		message_time = data.message_time;
	}

	$.extend($.gritter.options, {
	    position: 'bottom-right', // possibilities: bottom-left, bottom-right, top-left, top-right
		fade_in_speed: 100, // how fast notifications fade in (string or int)
		fade_out_speed: 100, // how fast the notices fade out
		time: 3000 // hang on the screen for...
	});

	// limit our open gritters 
	if ($('.gritter-item-wrapper').length > 3) {
		var delete_this_id = $('.gritter-item-wrapper').first().attr('id').replace('gritter-item-','');
		$.gritter.remove( delete_this_id );
	}

	// show our message
	$.gritter.add({
		title: this_tool_title,
		text: this_tool_message,
		sticky: is_sticky,
		time: message_time,
		class_name: this_tool_class + ' gritter-light'
	});
}

/* Start functions to assist the core tools: create/update, delete, standard display views */

// function 'enliven' our HTML forms by attaching jquery/bootstrap magic to the fields.
// We have to do it on-demand since we are a single-page application which loads in
// forms dynamically.  All of this depends on the plugins and goodies which come with
// Ace Admin; if the second arg is sent, we are handling a special form;
// otherwise, it's a tool action form
function interactive_form_elements (tool_id,form_type) {
	// default that second arg to just 'form' for basic forms
	if (form_type == '' || form_type == undefined) {
		form_type = 'form';
	}

	// start up the bootstrap date-picker
	$('.input-date-picker').datepicker({
		format: "yyyy-mm-dd",
		autoclose: true,
		todayHighlight: true,
		orientation: "bottom auto",
	})
	// with icon support
	.next().on(ace.click_event, function(){
		$(this).prev().focus();
	});

	// use that same bootstrap date-picker for selection months
	$('.input-month-picker').datepicker({
		format: "MM yyyy",
		startView: "months",
		minViewMode: "months",
		autoclose: true,
		todayHighlight: true,
		orientation: "bottom auto",
	})
	// also with icon support
	.next().on(ace.click_event, function(){
		$(this).prev().focus();
	});

	// this simplified date-picker is for the date-range chooser
	$('.input-datechooser').datepicker({
		format: "yyyy-mm-dd",
	});

	// rely on jquery.maskedinput.js for supporting:
	$('.input-mask-phone').mask('(999) 999-9999'); // phone numbers
	$('.input-low-integer').mask('9?99');// low integers, up to 999
	$('.input-high-integer').mask('9?99999999'); // high integers, up to 999,999,999

	//$('.input-low-integer').ace_spinner({value:0,min:0,max:999,step:1, on_sides: true, icon_up:'ace-icon fa fa-plus bigger-110', icon_down:'ace-icon fa fa-minus bigger-110', btn_up_class:'btn-success' , btn_down_class:'btn-danger'});
	//$('.input-high-integer').ace_spinner({value:0,min:0,max:999999999,step:1, on_sides: true, icon_up:'ace-icon fa fa-plus bigger-110', icon_down:'ace-icon fa fa-minus bigger-110', btn_up_class:'btn-success' , btn_down_class:'btn-danger'});

	$('.input-low-decimal').numeric({ allow:'-.'});
	$('.input-high-decimal').numeric({ allow:'-.'});

	// use jquery.alphanumeric for keeping short_text_clean's alphanumeric (decimels OK)
	$('.input-alphanumeric').alphanumeric({ allow:'_-.'});

	// special numbers-only fields
	$('.input-numeric').numeric({allow:"."});

	// very cool chosen.jquery.js for options menus
	if (tool_objects[tool_id]['tool_type_short'] == 'modal' || form_type == 'advanced_search_form') {
		// modal select needs to be the width of the widest option to work
		enable_chosen_menu('.chosen-select', '95%');
	} else { // otherwise, natural width
		enable_chosen_menu('.chosen-select');
	}

	// let's make radio buttons highlight their area when they are clicked / selected
	$('.radio-highligter').click(function() {
		$('.radio').removeClass('alert-info');
		$(this).parent().parent().addClass('alert-info');
	});
	// if one is already checked, highlight it
	$(".radio-highligter").filter(':checked').parent().parent().addClass('alert-info');

	// if they included tag inputs in an advanced_search_form, their tool's sub-class
	// should have a advanced_search_form_tag_suggest() method
	if (form_type == 'advanced_search_form') {
		$( '#' + tool_id + '_advanced_search_form' + ' .tag_input' ).each(function() {
			tool_objects[tool_id].tag_auto_complete_fields('advanced_search_form_tag_suggest',$( this ));
		});
	}

	// support the fancy active/inactive and yes/no switches
	$( '.ot-switch' ).change(function() {
		var on_value = 'Yes';
		var off_value = 'No';
		if ($( this ).hasClass('ace-switch-4')) {
			on_value = 'Active';
			off_value = 'Inactive';
		}
		if ($( this ).prop('checked') == false) {
			$(this).closest("div").find('.ot-switch-transporter').val(off_value);
		} else {
			$(this).closest("div").find('.ot-switch-transporter').val(on_value);
		}
	});

	// support any recaptcha fields
	$( '.g-recaptcha-fields' ).each(function() {
		grecaptcha.render($(this).attr('id'), {
			'sitekey' : $(this).data("sitekey")
		});
	});

	// advanced searches and sorts will not have these fields

	if (form_type != 'advanced_search_form' && form_type != 'advanced_sort_form') {
		// file-upload field enhancements
		$('.input-file').ace_file_input({
			no_file:'No File ...',
			btn_choose:'Choose',
			btn_change:'Change',
			droppable:false,
			onchange:null,
			thumbnail:false //| true | large
		});

		// enable rich-text editors
		$('#'+tool_id+'_wyiswig').ace_wysiwyg({
			speech_button: true,
			toolbar: [
				{
					name: 'font',
					title: 'Change Font',
				},
				{
					name: 'fontSize',
					title: 'Change Font Size',
				},
				{
					name: 'bold',
					title: 'Toggle Bold Style',
				},		
				{
					name: 'italic',
					title: 'Toggle Italic Style',
				},
				{
					name: 'underline',
					title: 'Toggle Underline Style',
				},		
				{
					name: 'strikethrough',
					title: 'Toggle Strike-Through Style',
				},		
				null,
				{
					name: 'foreColor',
					title: 'Change Text Color',
				},		
				null,
				{
					name: 'insertunorderedlist',
					title: 'Inset Unordered List',
				},		
				{
					name: 'insertorderedlist',
					title: 'Inset Ordered List',
				},		
				{
					name: 'outdent',
					title: 'Add outdent',
				},		
				{
					name: 'indent',
					title: 'Add indent',
				},		
				{
					name: 'justifyleft',
					title: 'Justify Left',
				},		
				{
					name: 'justifycenter',
					title: 'Justify Center',
				},		
				{
					name: 'justifyright',
					title: 'Justify Right',
				},		
				null,
				{
					name: 'createLink',
					title: 'Create Link',
				},		
				{
					name: 'unlink',
					title: 'Unlink',
				},		
				{
					name: 'insertImage',
					title: 'Inset Image',
				},		
				null,
				{
					name: 'undo',
					title: 'Undo Last Change',
				},		
				{
					name: 'redo',
					title: 'Redo Last Change',
				},		
				null,
				{
					name: 'viewSource',
					title: 'View Source',
				},		
			],
			wysiwyg: {
				hotKeys: {
					'ctrl+b meta+b': 'bold',
					'ctrl+i meta+i': 'italic',
					'ctrl+u meta+u': 'underline',
					'ctrl+z meta+z': 'undo',
					'ctrl+y meta+y meta+shift+z': 'redo',
					'ctrl+l meta+l': 'justifyleft',
					'ctrl+r meta+r': 'justifyright',
					'ctrl+e meta+e': 'justifycenter',
					'ctrl+j meta+j': 'justifyfull',
				}
			}
		});
		//$('#'+tool_id+'_wyiswig').addClass('wysiwyg-style2');

		// enable color-choosing, if they have such a field (only supports one per form)
		if ($('#'+tool_id+'_color_picker').length > 0) {
			$('#'+tool_id+'_color_picker').ace_colorpicker();
		}

		// empower tag input fields for omniclass-generated forms
		// make sure your omniclass package has a 'autocomple_FIELD_NAME' method
		$( '#' + tool_id + '_' + form_type + ' .tag_input' ).each(function() {
			tool_objects[tool_id].tag_auto_complete_fields($( this ).attr('name'),$( this ));
		});

		// empower the base 'autocomplete' short text fields for omniclass-generated form
		$( '#' + tool_id + '_' + form_type + ' .autocomplete_input' ).each(function() {
			tool_objects[tool_id].auto_complete_fields($( this ).attr('name'),$( this ));
		});

	// run the validation routine on our sort form
	} else if (form_type == 'advanced_sort_form') {
		tool_objects[tool_id].advanced_sort_validate();
	}

	// use our custom 'submit_form()' for forms submissions
	// the ID for the form will be the tool_id.'_'.form_type
	$( '#' + tool_id + '_' + form_type ).off( "submit" ); // clear, in case we are re-running after form change
	$( '#' + tool_id + '_' + form_type ).submit(function( event ) {
		event.preventDefault();
		tool_objects[tool_id].submit_form(event.target.id); // that function will need a few tricks to handle special forms
	});

}

// support form-appending in spreadsheet-forms
var count_of_new_forms = 1;
function append_spreadsheet_form (the_tool_id, source_row_id) {
	count_of_new_forms = count_of_new_forms + 1;
	var new_html = $( '#new_item_form_entry_storage' ).html();
	var new_form_html = new_html.replace(/new_item_form_entry/g,'new_item_form_entry'+count_of_new_forms);

	// if we cloning an existing row, we will want to insert the new row after the source...
	if (source_row_id != undefined) {
		$.when( $('#' + source_row_id).after( new_form_html ) ).done(function() {

			// ..and then get all the valus in there
			$('#'+source_row_id+' input[type=text]').each(function(i,v) {
				var target_field = $( '#new_item_form_entry'+count_of_new_forms+' input[type=text]')[i];
				$(target_field).val( $(this).val() );
			});
			$('#'+source_row_id+' select').each(function(i,v) {
				var target_field = $( '#new_item_form_entry'+count_of_new_forms+' select')[i];
				$(target_field).val( $(this).val() );
			});

			// re-empower the form once the new bits are added
			interactive_form_elements(the_tool_id);
		});

	// or just appending a new form?
	} else {
		$.when( $('#' + the_tool_id + '_form_area').append( new_form_html ) ).done(function() {
			// re-empower the form once the new bits are added
			interactive_form_elements(the_tool_id);
		});
	}
}

// routine to add advanced keyword search fields
// it's a bit ugly, because we aren't keeping one in storage
function add_advanced_search_keyword_field (tool_id) {
	var adv_keyword_field_selector = tool_id+'_advanced_search_keyword';

	// crazy copy command
	$('.'+adv_keyword_field_selector).last().after( $('.'+adv_keyword_field_selector).last().clone() );

	// show the plus only on the last one
	$('.'+adv_keyword_field_selector).find( "a" ).hide();
	$('.'+adv_keyword_field_selector).last().find( "a" ).show();

}

// routine to clear a form, most likely an advanced search or sort form
function reset_form (form_id) {
	var $form = $('#'+form_id);
	$form.find('input:text, input:password, input:file, textarea').val('');

  //  $form.find('select option:selected').removeAttr('selected');
	$form.find('select').each(function(i, v) {
		// select menus can be funny -- grab the first one with a valid option

		if ($(v).attr('multiple') != undefined) {
			$(v).val([]);
		} else {
			$(v).prop("selectedIndex", 0);
			if ($(v).val() == '') {
				$(v).prop("selectedIndex", 1);
			}
		}
		$(v).trigger("chosen:updated");
	});

    //	$form.find('select').trigger('chosen:updated');
    $form.find('input:checkbox, input:radio').removeAttr('checked');

	// bootstrap-tags is less fun ;)  this is the way i got it to work, since each time you removed
	// an entry, it would change the lenght of the array (duh)
	$('#'+form_id + " .tag_input").each(function(){
		var tag_count = $(this).data('tag').values.length;
		for (var i = 0; i < tag_count; i++) {
			$(this).data('tag').remove(0);
		}
		$(this).data('tag').add('Any');

	});
}

// Javascript routines related to the Calendar_tool_mode.tt Jemplate / Tool Mode
function start_calendar (tool_id) {
	$('#'+tool_id+'_calendar').fullCalendar({
		// put your options and callbacks here
		buttonHtml: {
			prev: '<i class="ace-icon fa fa-chevron-left"></i>',
			next: '<i class="ace-icon fa fa-chevron-right"></i>'
		},
		//events: calendar_events_array,
		height: 450,
		header: {
			left: 'prev,next today',
			center: 'title',
			right: 'month,agendaWeek,agendaDay'
		},
		eventBackgroundColor: '#ff0000',
		eventClick: function(calEvent, jsEvent, view) {
	        location.hash=calEvent.link;
	    },
	});
}

// routine to support select / de-select all options in chosen menus
function chosen_select_deselect_all (menu_id,action) {
	var menu_obj = document.getElementById(menu_id);
	for (var i=0; i < menu_obj.options.length; i++) {
		if (action == 'select_all' || menu_obj.options[i].value == 'Any') {
			menu_obj.options[i].selected = true;
		} else {
			menu_obj.options[i].selected = false;
		}
	}
	// update chosen and trigger any on-change's
	$('#'+menu_id).trigger('chosen:updated');
	$('#'+menu_id).trigger('change');
}


// routine to turn a results table into a nice datatable
function make_data_table (tool_id, no_export_buttons) {
	// uncomment this to block for mobile devices
	/*
	if (mobile_device == 1) {
		return;
	}
	*/

	if ($('#tool_results_' + tool_id +' tr').length == 0) {
		return;
	}

	// present export buttons?
	if (no_export_buttons == undefined) { // yes
		var the_dom = '<"toolbar">Bfrtip';
	} else { // no
		var the_dom = '<"toolbar">frtip';
	}
	// use 'make_data_table_no_export_buttons' in your tool view mode config to send the argument

	// make it a datatable, with export buttons that do not include the actions column
	var table = $('#tool_results_' + tool_id).dataTable( {
		"oLanguage": {
			"sSearch": "Filter:"
		},
		"stateSave": true,
		dom: the_dom,
		buttons: [
			{
				extend: 'excelHtml5',
				orientation: 'landscape',
				exportOptions: {
					columns: [ '.omnitool-data' ],
					format: {
						body: function ( data, column, row, node ) {
							return data.replace( /[$,]/g, '' );
						}
					}
				}
			},
			{
				extend: 'csvHtml5',
				exportOptions: {
					columns: [ '.omnitool-data' ]
				}
			},
			/*
			{
				extend: 'copyHtml5',
				exportOptions: {
					columns: [ '.omnitool-data' ]
				}
			},
			{
			extend: 'pdfHtml5',
				message: 'PDF Generated from https://' + location.href,
				exportOptions: {
					columns: [ '.omnitool-data' ]
				}
			},
			*/
		]
	} );

	// default length is 25
	table.fnSettings()._iDisplayLength = 25;
	table.fnDraw();

	/*
	$('#example').on( 'order.dt', function () {
    	var order = table.order();
    	$('#orderInfo').html( 'Ordering on column '+order[0][0]+' ('+order[0][1]+')' );
	} );
	*/
}

// add-on function to present the datatables without the excel / csv export buttons
// good for complex tools; just calls the main function with the extra arg
function make_data_table_no_export_buttons (tool_id) {
	make_data_table(tool_id,1);
}

// utility function to do interactive_form_elements plus make_data_table all at once
function form_plus_data_table (tool_id) {
	interactive_form_elements(tool_id);
	make_data_table(tool_id);
}

// utility function to do interactive_form_elements plus make_inline_data_tables all at once
// for Results_SearchForm_MultiTables.tt and Results_SearchForm_MultiTables_Horizantial.tt
function form_plus_data_tables (tool_id) {
	interactive_form_elements(tool_id);
	make_inline_data_tables();
}

// Javascript routine to turn one or more inline (non-results) tables into datatables
// these tables should have a class named 'datatable_ready'
function make_inline_data_tables (no_export_buttons) {

	/* var target_tables = $('.datatable_ready.').map(function() {
		return this.id;
	}).get(); */

	// present export buttons?
	if (no_export_buttons == undefined) { // yes
		var the_dom = '<"toolbar">Bfrt';
	} else { // no
		var the_dom = '<"toolbar">frt';
	}

	// cycle through the 'datatable_ready' tables
	$('.datatable_ready').each(function( index ) {
		// make it a datatable, with export buttons
		// leave off the pagination (ip)
		var table = $( this ).dataTable({
			"bSort": false,
			"oLanguage": {
				"sSearch": "Filter:"
			},
			"stateSave": true,
			"bPaginate": false,
			dom: the_dom,
			buttons: [
				{
					extend: 'excelHtml5',
					orientation: 'landscape',
					exportOptions: {
						columns: [ '.omnitool-data' ],
						format: {
							body: function ( data, column, row, node ) {
								return data.replace( /[$,]/g, '' );
							}
						}
					}
				},
				{
					extend: 'csvHtml5',
					exportOptions: {
						columns: [ '.omnitool-data' ]
					}
				},
			]
		} );
	} );
}

// function to render a chart for your tool; it gets called automatically if you set 'Display a Chart' in your Tool View Mode
// it simply calls your custom charting_json() tool method for the Tool.pm sub-class, and that will return
// a JSON object suitable for Chart.js -- see http://www.chartjs.org/docs/latest/getting-started/
var myCharts = new Array(); // so we can have multiple charts
function render_tool_chart (tool_id, alternative_chart_id) {
	if (alternative_chart_id != undefined) { // they want to use an alternative div
		var chartarea_div = $('#chartarea_'+alternative_chart_id);
	} else { // use the standard
		var chartarea_div = $('#chartarea_'+tool_id);
	}

	// where do the charts go
	var chartarea_div = $('#chartarea_'+tool_id);
	// call for the chart data JSON
	$.when( query_tool(tool_objects[tool_id]['tool_uri'] + '/charting_json', { alternative_chart_id: alternative_chart_id } ) ).done(function(data) {
		// keep it looking nice
		data.options.responsive=true;
		data.options.maintainAspectRatio=true;

		// clear out any pre-existing chart for this tool ID
		if (myCharts[tool_id] != null) {
	        myCharts[tool_id].destroy();
    	}

		// to make sure it does not grow large on re-load, we have to destroy and recreate the canvas every time
    	chartarea_div.empty();
    	chartarea_div.append('<canvas id="chart_'+tool_id+'"  style="height:40vh; width:80vw"></canvas>');
    	var ctx = $('#chart_'+tool_id);

    	// now build and show the new chart - unless they explicitly said 'no
    	if (data.no_chart == undefined) {
			myCharts[tool_id] = new Chart(ctx, data);
			chartarea_div.show();
		} else {
			chartarea_div.hide();
		}
	});
}

// Function to go with the complex_details_tabs_shared.tt template,
// to remember the tab you were on last for this particular tool
var tab_value_holder = new Array();
function complex_data_tab_remembering (tool_id) {
	make_inline_data_tables();

	$('#tab_info a').click(function (e) {
		e.preventDefault();
		$(this).tab('show');
	});

    // on load of the page: switch to the currently selected tab
    if (tab_value_holder[tool_id] != undefined) {
        $('#tab_info a[href="#' + tab_value_holder[tool_id] + '"]').tab('show');
    }

	// store the currently selected tab in the hash value
	$("ul.nav-tabs > li > a").on("shown.bs.tab", function (e) {
		var id = $(e.target).attr("href").substr(1);
		tab_value_holder[tool_id] = id;
	});

}

// reusable command to go to the top
function goToTop () {
	$("html, body").animate({ scrollTop: 0 }, "slow");
}

// function to enable chosen menus properly, based on the type of device
function enable_chosen_menu (jquery_identifier, custom_width) {
	if (jquery_identifier == undefined) { // can't do much without this
		return;
	}

	// chosen is un-supported on a mobile browser
	if (mobile_device == 1) {
		return;
	}


	// chosen is slow, so let's go async on this
	setTimeout(function () {

		// set up our options object
		var chosen_options = new Array;
		if (custom_width != undefined) { // make sure to send it with percent sign at the end
			chosen_options.width = custom_width;
		}

		// show search if there are 4+ options
		chosen_options.search_contains = true;
		chosen_options.disable_search_threshold = 4;

		// alright enable the menu(s)
		$(jquery_identifier).chosen(chosen_options);

	}, 0);
}

// small ui function to support the 'Search Controls' button to reveal the search controls in XS mode
function xs_show_search_controls (tool_id) {
	// show the controls
	$('#search-controls_'+tool_id).removeClass('hidden-xs');
	// hide the button
	$('#search-controls-toggle_'+tool_id).hide();
	// fix the menus - if on desktop, chosen is un-supported on a mobile browser
	if (mobile_device != 1) {
		$('.tool-search-menu').chosen('destroy');
		enable_chosen_menu('.tool-search-menu');
	}
}

// support for sub-data widgets (within widgets) in WidgetsV3.tt
// if you drink enough coffee, you maybe can get this to work for lots of jemplates
function show_sub_data_widgets ( sub_data_container_id, clicked_button_id ) {

	// reveal the div containing the device rows
	$('#' + sub_data_container_id).show();

	$('#' + clicked_button_id).html('Loading...');

	// know which tool we are in
	var current_tool_id = the_active_tool_ids['screen'];

	// pause the search refreshing for this tool, as that would remove these inserted div's
	tool_objects[current_tool_id]['search_paused'] = 'Yes';

	// get the number of available slots for sub-data
	var number_of_sub_divs = $( '#' + sub_data_container_id + ' .sub_data_widget' ).length;

	// go through each device in th pod
	var num = 0;
	$( '#' + sub_data_container_id + ' .sub_data_widget' ).each(function() {

		// pass the device_id back to the tool method
		var this_device_id = $( this ).attr('id');
		var this_post_object = new Object();
		this_post_object.one_data_code = $( this ).attr('id').replace('sub_data_','');

		// run the query
		$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/load_one_record' , this_post_object ) ).done(function(data) {

			// behold, the magic of the Jemplates and our 'process any div' feature
			jemplate_bindings['process_any_div'].element_id = '#' + this_device_id;
				data.block_name = 'sub_data_widget_' + current_tool_id;
			jemplate_bindings['process_any_div'].process_json_data(data);

			num = num + 1;
			if (num == number_of_sub_divs) { // last one: safe to hide the button
				$('#' + clicked_button_id).hide();
			}
		});

	});

}
