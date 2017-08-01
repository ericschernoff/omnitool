/*
	omnitool_bookmarks.js

	Routines related to creating/sharing/managing tool bookmarks.

	Set up as an object for easier use.

	Relies on functions found in omnitool_routines.js, particularly
	open_system_modal() and query_tool() -- and especially jemplate_bindings[]
*/

// our main object; will control the forms & modals related to these functions
function Bookmark_Manager () {

	// this object set up routine is to establish behavior for the create/manage/share
	// bookmarks links in the ui skeleton's navbar

	// empower create link
	$('.bookmark_create').click(function(e){
		e.preventDefault();
		var current_tool_id = the_active_tool_ids['screen'];
		var data = {
			bookmark_mode: 1,
			show_bookmark_create_form: 1,
			modal_title_icon: 'fa-bookmark',
			modal_title:  'Create a Bookmark - ' + tool_objects[current_tool_id]['button_name'],
			current_tool_name: tool_objects[current_tool_id]['button_name'],
			instance_title: instance_title,
		};

		// open it up
		open_system_modal(data);

		// hidden validation span
		$('#new_bookmark_required').hide();
	});

	// keep bookmark manager data in wider scope for re-use
	var manager_data = {
		bookmark_mode: 1,
		show_bookmark_manager: 1,
		modal_title_icon: 'fa-pencil',
		modal_title:  'Manage Bookmarks for ' + instance_title,
		instance_title: instance_title,
		fetch_bookmarks: 1
	};

	// empower manage link
	$('#bookmark_manage').click(function(e){
		e.preventDefault();
		var current_tool_id = the_active_tool_ids['screen'];

		// we need to call on the server to give us the current list of bookmarks for this user before opening the modal
		$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/bookmark_manager',manager_data) ).done(function(json_response) {
			manager_data.bookmark_mode = 1;
			manager_data.bookmark_keys = json_response.bookmark_keys;
			manager_data.bookmarks = json_response.bookmarks;
			manager_data.form_action = 'none'; // set default
			manager_data.selected = new Object();

			manager_data.mobile_device = mobile_device;
			manager_data.status_message = json_response.status_message;

			// open it up & let jemplate handle the rest
			open_system_modal(manager_data);
		});
	});

	// function to submit the new bookmark form
	this.create_bookmark = function () {
		// where are we?
		var current_tool_id = the_active_tool_ids['screen'];

		// alert( $('#new_bookmark_name').val() + ' - ' + tool_objects[current_tool_id]['button_name'] );

		// sanity
		var new_bookmark_name = $('#new_bookmark_name').val();

		// slight form validation
		if (new_bookmark_name == '') {
			$('#new_bookmark_required').show();

		// otherwise safe to continue
		} else {
			// all-in-one object to handle request and resulting info for jemplate
			var data = {
				bookmark_mode: 1,
				show_bookmark_created_status: 1,
				modal_title:  '<i class="fa fa-bookmark white bolder"></i> Bookmark Created- ' + tool_objects[current_tool_id]['button_name'],
				current_tool_name: tool_objects[current_tool_id]['button_name'],
				// new_bookmark_share_uri: 'https://' + window.location.hostname + '/#' + tool_objects[current_tool_id]['tool_uri'] + '/bkmk',
				new_bookmark_name: new_bookmark_name,
				new_bookmark_make_default_tool: $( "#new_bookmark_make_default_tool" ).is(':checked'),
				new_bookmark_make_default_instance: $( "#new_bookmark_make_default_instance" ).is(':checked'),
				mobile_device: mobile_device,
				instance_title: instance_title
			};

			// construct our 'bookmark_share_uri' based on if we are in primary or specific hostname mode
			if (uri_base != undefined && uri_base != '') {
				data.new_bookmark_share_uri = 'https://' + window.location.hostname + '/' + uri_base + '#' + tool_objects[current_tool_id]['tool_uri'] + '/bkmk';
			} else {
				data.new_bookmark_share_uri = 'https://' + window.location.hostname + '/#' + tool_objects[current_tool_id]['tool_uri'] + '/bkmk';
			}

			// show feedback when form is submitted
			$('.book_mark_loading_icon').toggleClass('hidden visible');

			$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/bookmark_manager',data) ).done(function(json_response) {
				// add new object to share uri
				data.new_bookmark_share_uri += json_response.new_bookmark_object_name;

				// push the response into the already-open modal
				jemplate_bindings['system_modal'].process_json_data(data);

				// reload the menubar to reflect the new bookmarks
				jemplate_bindings['ot_menubar'].process_json_uri();
			});
		}
	};

	// function to modify bookmark manager form based on their selection for action
	this.manager_form = function () {
		var current_tool_id = the_active_tool_ids['screen'];

		// grab the menu selection
		manager_data.form_action = $( "#bookmark_form_action" ).val();

		// if sharing, build the uri to share that bookmark
		if (manager_data.form_action == 'share') {
			// where are we?
			var current_tool_id = the_active_tool_ids['screen'];

			// construct our 'bookmark_share_uri' based on if we are in primary or specific hostname mode
			if (uri_base != undefined && uri_base != '') {
				manager_data.bookmark_share_uri = 'https://' + window.location.hostname + '/' + uri_base + '#' + tool_objects[current_tool_id]['tool_uri'] + '/bkmk'
					+ $( "#bookmark_to_manage" ).val();
			} else {
				manager_data.bookmark_share_uri = 'https://' + window.location.hostname + '/#' + tool_objects[current_tool_id]['tool_uri'] + '/bkmk'
					+ $( "#bookmark_to_manage" ).val();
			}

		} else if (manager_data.form_action == 'make_default_for_instance' || manager_data.form_action == 'make_default_for_tool') {
			manager_data.target_bookmark = $( "#bookmark_to_manage" ).val();
			$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/bookmark_manager',manager_data) ).done(function(json_response) {
				manager_data.bookmark_mode = 1;
				manager_data.bookmark_keys = json_response.bookmark_keys;
				manager_data.bookmarks = json_response.bookmarks;
				manager_data.status_message = json_response.status_message;
				// manager_data.form_action = 'renamed'; // already set nicely
				manager_data.selected = new Object();
					manager_data.selected[manager_data.form_action] = 'SELECTED';

				// open it up & let jemplate handle the rest
				open_system_modal(manager_data);
			});

		}

		manager_data.selected = new Object();

		// set some handy vars
		manager_data.selected[manager_data.form_action] = 'SELECTED';
		manager_data.bookmark_name = $("#bookmark_to_manage option:selected").text();
		manager_data.mobile_device = mobile_device;

		// now reprocess
		jemplate_bindings['system_modal'].process_json_data(manager_data);
	}

	// need a function to keep the manager_data.selected_bookmark var in synch with
	// 'bookmark_to_manage' menu; because JS is such a great language
	this.set_selected_bookmark = function () {
		manager_data.selected_bookmark = $( "#bookmark_to_manage" ).val();
	}

	// function to handle bookmark rename
	this.rename_bookmark = function () {
		var current_tool_id = the_active_tool_ids['screen'];

		// sanity
		var bookmark_name = $('#bookmark_name').val();

		// slight form validation
		if (bookmark_name == '') {
			manager_data.rename_required = 'show';
		} else {
			manager_data.rename_required = 'hide';

			manager_data.bookmark_name = bookmark_name;
			manager_data.rename_bookmark = $( "#bookmark_to_manage" ).val();

			// show feedback when form is submitted
			$('.book_mark_loading_icon').toggleClass('hidden visible');

			$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/bookmark_manager',manager_data) ).done(function(json_response) {
				manager_data.bookmark_mode = 1;
				manager_data.bookmark_keys = json_response.bookmark_keys;
				manager_data.bookmarks = json_response.bookmarks;
				manager_data.rename_result = json_response.rename_result;
				manager_data.form_action = 'renamed';
				manager_data.selected = new Object();

				// open it up & let jemplate handle the rest
				open_system_modal(manager_data);

				// reload the menubar to reflect the new name
				jemplate_bindings['ot_menubar'].process_json_uri();
			});

		}

		// now reprocess
		jemplate_bindings['system_modal'].process_json_data(manager_data);

	};

	// function to delete bookmarks
	this.delete_bookmark = function () {

		var current_tool_id = the_active_tool_ids['screen'];

		// give the instruction to delete
		manager_data.delete_bookmark = $( "#bookmark_to_manage" ).val();
		manager_data.delete_bookmark_name = $("#bookmark_to_manage option:selected").text();

		// show feedback when form is submitted
		$('.book_mark_loading_icon').toggleClass('hidden visible');

		// we need to call on the server to perform this action
		$.when( query_tool(tool_objects[current_tool_id]['tool_uri'] + '/bookmark_manager',manager_data) ).done(function(json_response) {
			manager_data.bookmark_mode = 1;
			manager_data.bookmark_keys = json_response.bookmark_keys;
			manager_data.bookmarks = json_response.bookmarks;
			manager_data.form_action = 'deleted'; // set default
			manager_data.selected = new Object();

			// reload the menubar to reflect the deleted bookmarks
			jemplate_bindings['ot_menubar'].process_json_uri();

			// open it up & let jemplate handle the rest
			open_system_modal(manager_data);

		});

		manager_data.form_action = 'deleted';

		// now reprocess
		jemplate_bindings['system_modal'].process_json_data(manager_data);

	};

}
