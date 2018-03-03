# Please see extensive comments in the example Perl script.

# Import our request library for sending HTTPS calls
import requests
requests.packages.urllib3.disable_warnings()

# Here is our client class.  You will need to modify 'YOUR_API_STRING'
class Client:
	def __init__(self):
		# Change self.api_key to your api key. You can find your api keys at /tools/user_api_keys
		self.api_key = 'YOUR_API_STRING'
		self.uri = 'https://your-omnitool-server.yourdomain.com/'
		self.uri_base = 'your_instances_uri_base'
		# leave the connection id blank
		self.connection_id = ''
		self.get_client_connection_id()

	def perform_request(self, uri, params={}):
		# Craft our URL
		request_url = self.uri + uri;

		# Always set our basic params
		params['api_key'] = self.api_key
		params['client_connection_id'] = self.connection_id
		params['uri_base'] = self.uri_base

		# Do the request, getting back a JSON string (hopefully)
		results = requests.post(
			request_url,
			data=params,
			verify=False
		)

		# if it told us 'Error' throw up an Exception
		if 'ERROR' in results.text:
			raise Exception('OT6 API Error: %s' % results.text)

		# return our data structure
		return results.json()

	# initiator called to get a connection ID from OT6
	def get_client_connection_id(self):
		# If our connection id is blank then go get one else return it
		if self.connection_id == '':
			response_json = self.perform_request('/ui/get_instance_info')
			self.connection_id = response_json['client_connection_id']
		else:
			return self.connection_id



# Example Request

# Example of a price lookup
part = 'Gingers_Love'
result = Client().perform_request('/tools/store/price_lookup/send_json_data',
									{'form_submitted': 1, 'part_numbers': part })
print('The price of %s is %s' % (part, result['results'][part] ))

