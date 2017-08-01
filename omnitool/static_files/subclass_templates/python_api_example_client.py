#Import our url library
import urllib.request
from urllib.parse import urlparse, urlencode
import ssl
import json

class Client:
    def __init__(self):
        """
        Change self.api_key to your api key. You can find your api keys at /tools/user_api_keys
        """
        self.api_key = 'FAFB47ADB512657AD1B2F72611FF2BD67E293E5A60462C49351467898283'
        self.uri = 'https://instance_hostname.yourdomain.com'
        self.uri_base = 'instance_path_base'
        self.connection_id = ''
        """
        Connection_id is what we must sent to OT6 with each request for auth purposes.
        """
        self.get_client_connection_id()

    """
    api should be the OT6 api you wish to use
    params should be a hash object that you wish to pass to the api
    returns the JSON response
    """
    def perform_request(self, api, params={}):
        #Craft our URL
        url = self.create_request_uri(api, params)

        #SSL Settings
        gcontext = ssl.SSLContext(ssl.PROTOCOL_TLSv1)

        #The request
        response = urllib.request.urlopen(url, context=gcontext).read()

        #Decode our data into a JSON object
        data = json.loads(response.decode('utf-8'))
        return data

    def get_client_connection_id(self):
        #If our connection id is blank then go get one else return it
        if self.connection_id == '':
            response_json = self.perform_request('/ui/get_instance_info')
            self.connection_id = response_json['client_connection_id']
        else:
            return self.connection_id

    def create_request_uri(self, api, params={}):
        #Append the api url to the base
        url = self.uri + api

        #Set our basic params
        params['api_key'] = self.api_key
        params['client_connection_id'] = self.connection_id
        params['uri_base'] = self.uri_base

        #Craft our url
        url += ('&' if urlparse(url).query else '?') + urlencode(params)
        return url


"""
Example Requests
"""

# Example of a price lookup
part = 'gingers-love-080199'
result = Client().perform_request('/tools/store/price_lookup/send_json_data',
                         {'form_submitted': 1, 'part_numbers': part })
print('The price of %s is %s' % (part, result['results'][part] ))

#Creating a case
result = Client().perform_request('/tools/case_queue/open_case/send_json_data',
                                  {
                                    'form_submitted': 1, # <-- key to submitting an OT web form;
                                    'name': 'Case Created from API Client',
                                    'service_request': 'Feature Request',
                                    'target_queue': '1_1',
                                    'client_username': 'myusername', ## <-- PLEASE EDIT THIS
                                    'priority': 'P4',
                                    'request_description': 'Please disregard this case'
                                    }
                                )
print(result['title'])
print('New Case ID is %s' % result['altcode'])
