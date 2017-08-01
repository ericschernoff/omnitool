/*
	This class contains all the features we will use to support Network Diagram display, creation,
	and editing as part of the OT6 user interface.

	Highly tempted to just make this a set of functions, but I'll be a good boy and make it
	and object, and then hook at object into the Tools objects
*/

// some links I need to refer to
// http://visjs.org/docs/data/dataset.html
// view-source:http://visjs.org/examples/network/other/saveAndLoad.html

var the_active_diagram_objects = new Array(); // see below

// controller function to run our diagram objects w/o editing enabled
// suited for one or more, hence the 'multiple'...other way didn't work w/o modifications
function initialize_diagram_multiple_no_editing () {
	the_active_diagram_objects = [];
	$('.network_diagram').each(function(){
		var needed_bits = this.id.replace('network_diagram_','').split('-');
		var tool_id = needed_bits[0];
		var diagram_data_code = needed_bits[1];
		
		var network_diagram = new omnitool_network_diagram(tool_id, diagram_data_code);

		// easy access to the rest of the JS world
		the_active_diagram_objects.push(network_diagram);

		network_diagram['options']['interaction'] = {
			dragNodes: false,
		};
	
		// first, load the data, then do the rest
		network_diagram.load_network_data();
	});
}

// controller function to run our diagram objects with 'edge' (connection) editing enabled
function initialize_diagram_edge_editing (tool_id) {
	var network_diagram = new omnitool_network_diagram(tool_id);

	// easy access to the rest of the JS world
	the_active_diagram_objects = [];
	the_active_diagram_objects.push(network_diagram);

	// enable edge / connection editing
	network_diagram.add_manipulation_options();

	// first, load the data, then do the rest
	network_diagram.load_network_data();

}

// start our class for controlling and running network diagrams
function omnitool_network_diagram (tool_id, diagram_data_code) {

	// always handy
	this['tool_id'] = tool_id;
	
	// if they passed it
	this['diagram_data_code'] = diagram_data_code;

	// if it's undefined, use the usual containers
	if (this['diagram_data_code'] == undefined) {
		this['diagram_data_code'] = 'none';

		// our target elements
		this['diagram_container'] = document.getElementById('network_diagram_'+tool_id);
		this['instructions_container'] = document.getElementById('network_diagram_instructions_'+tool_id);

	// otherwise, containers are going to have the diagram_data_code
	} else {
		// our target elements
		this['diagram_container'] = document.getElementById('network_diagram_'+tool_id+'-'+this['diagram_data_code']);
		this['instructions_container'] = document.getElementById('network_diagram_instructions_'+tool_id+'-'+this['diagram_data_code']);
	}

	// where our images live
	this['images_directory'] = '/non_ace_assets/vis/dist/img/refresh-cl/';

	// uri's for loading and saving diagram data
	this['tool_json_uri'] = tool_objects[tool_id]['tool_uri'] + '/send_json_data';

	// our initial display options
	this['options'] = {
		"physics": { // none of that bouncy stuff
			"enabled": false,
			"minVelocity": 0.75
		},
		"interaction":{
			"dragView": true,
			"zoomView": false,
		},
		"layout": {
			randomSeed: 2
        },
	};

	// keep myself handy
	var self = this;

	// method to add manipulation of edges only
	this.add_manipulation_options = function () {
		this['options']['manipulation'] = { // allow adding connections (edges) but not nodes
			initiallyActive: true,
			addNode: false,
			//editNode: false,
			deleteNode: true,
			addEdge: function (data, callback) {
				if (data.from == data.to) {
					var r = confirm("Do you want to connect the node to itself?");
					if (r != true) {
						callback(null);
						return;
					}
				}
				$('#edge-operation').html("Add Edge");
				editEdgeWithoutDrag(data, callback);
			},
			editEdge: {
				editWithoutDrag: function(data, callback) {
					$('#edge-operation').html("Edit Edge");
					editEdgeWithoutDrag(data,callback);
				}
			}
		};
	}

	// method to grab the dataset from omnitool
	this.load_network_data = function () {

		// post it to our tool
		// looks for the json in a 'diagram_data' param
		$.when( query_tool(this['tool_json_uri'],{
			diagram_action: 'load_network_data',
			load_network_diagram: self['diagram_data_code'],
		}) ).done(function(json_data) {
			// parse that JSON back to data
			var diagram_data = JSON.parse(json_data.diagram_data);

			// convert the nodes and edges objects back to arrays of objects
			var nodes_array = $.map(diagram_data.nodes._data, function(value, index) {
				return [value];
			});
			if (diagram_data.edges == undefined) { // blank edges
				var edges_array = [];
			} else {
				var edges_array = $.map(diagram_data.edges._data, function(value, index) {
					return [value];
				});
			}

			// reset the diagram's data
			self['diagram_data'] = {
				nodes: new vis.DataSet(nodes_array),
				edges: new vis.DataSet(edges_array),
				links: [],
				javascript: [],
			};

			// diagram instructions?
			if (diagram_data.instructions != undefined) {
				self['diagram_data'].instructions = diagram_data.instructions;
			}

			// if they sent 'click_links,' make it a glorified image map
			if (diagram_data.click_links != undefined) {
				self['diagram_data'].click_links = 1;
			} else {
				self['diagram_data'].click_links = 0;
			}

			// or if they sent 'click_javascript,' make it call those functions
			if (diagram_data.click_javascript != undefined) {
				self['diagram_data'].click_javascript = 1;
			} else {
				self['diagram_data'].click_javascript = 0;
			}

			// map any onclick associations with those nodes
			for (var i = 0; i < nodes_array.length; i++) {
				var node_id = nodes_array[i].id;
				if (nodes_array[i].onclick_link != undefined) {
					self['diagram_data']['links'][node_id] = nodes_array[i].onclick_link;
				// javascript instead?
				} else if (nodes_array[i].onclick_javascript != undefined) {
					self['diagram_data']['javascript'][node_id] = nodes_array[i].onclick_javascript;
				}
			}

			// was the view positon saved?
			if (diagram_data.view_position != undefined) { // yes, try to restore it
				self['diagram_data'].x = diagram_data.view_position.x;
				self['diagram_data'].y = diagram_data.view_position.y;
			}

			// now initialize
			self.initialize_diagram();
		});

	}

	// method to initialize (run) the diagram
	this.initialize_diagram = function () {
		// initialize and display the diagram
		this['network_diagram'] = new vis.Network(this['diagram_container'], this['diagram_data'], this['options']);

		// clean up / organize the initiate elments
		//this['network_diagram'].stabilize();
		//this['network_diagram'].storePositions();

		// do we want to make this a glorified image map?
		if (this['diagram_data'].click_links == 1) {
			this['network_diagram'].on("click", function (params) {
				var node = params.nodes[0];
				var new_uri = self['diagram_data']['links'][node];
				if (new_uri != undefined) {
					window.open(new_uri);
				}
			});
		}
		// or maybe some on-clicks?
		if (this['diagram_data'].click_javascript == 1) {
			this['network_diagram'].on("click", function (params) {
				var node = params.nodes[0];
				eval( self['diagram_data']['javascript'][node] );
			});
		}

		// instructions for this diagram?
		if (this['diagram_data'].instructions != undefined) {
			this.instructions_container.innerHTML = this['diagram_data'].instructions ;
		}

		// make it nice
		this['network_diagram'].fit();
	}

	// method to export diagram data to JSON and save it back to omnitool
	this.save_diagram = function () {
		window.scrollTo(0,0);
		$('#diagram_save_button_'+this['tool_id']).html('Saving...');

		// save the positions of the nodes
		this['network_diagram'].storePositions();

		// convert the who darn thing to JSON
		var diagram_data_json = JSON.stringify(this['diagram_data'], undefined, 2);

		// post it to our tool
		// looks for the json in a 'diagram_data' param
		$.when( query_tool(this['tool_json_uri'],{
			diagram_data: diagram_data_json,
			diagram_action: 'save_network_data'
		}) ).done(function(json_data) {
			$('#diagram_save_button_'+self['tool_id']).html('Diagram Saved!  Click to Save Again');
		});

	}

}

// our hook methods, largely un-changed from vis.js example
function editEdgeWithoutDrag(data, callback) { // filling in the popup DOM elements
	document.getElementById('edge-label').value = data.label;
	document.getElementById('edge-saveButton').onclick = saveEdgeData.bind(this, data, callback);
	document.getElementById('edge-cancelButton').onclick = cancelEdgeEdit.bind(this,callback);
	document.getElementById('edge-popUp').style.display = 'block';
}

function objectToArray(obj) {
	return Object.keys(obj).map(function (key) { return obj[key]; });
}

function clearEdgePopUp() {
	document.getElementById('edge-saveButton').onclick = null;
	document.getElementById('edge-cancelButton').onclick = null;
	document.getElementById('edge-popUp').style.display = 'none';
}

function cancelEdgeEdit(callback) {
	clearEdgePopUp();
	callback(null);
}

function saveEdgeData(data, callback) {
	if (typeof data.to === 'object')
		data.to = data.to.id
	if (typeof data.from === 'object')
		data.from = data.from.id
		data.label = document.getElementById('edge-label').value;
	clearEdgePopUp();
	callback(data);
}

