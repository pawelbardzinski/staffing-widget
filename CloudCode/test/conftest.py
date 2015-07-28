import pytest
import requests

class Parse(object):
	session_token = None
	
	def __init__(self, username, password):
		self.username = username
		self.password = password
		
	def login(self):
		response = self.get('/login', params={'username': self.username, 'password': self.password}, silent=True)
		self.session_token = response.json()['sessionToken']
		
	def post(self, endpoint, params=None, json=None, silent=False):
	    return self.request('POST', endpoint, params, json, silent=silent)
		
	def get(self, endpoint, params=None, json=None, silent=False):
	    return self.request('GET', endpoint, params, json, silent=silent)
		
	def request(self, method, endpoint, params=None, json=None, silent=False):
		headers = {
			'X-Parse-Application-Id': 'jjQlIo5A3HWAMRMCkH8SnOfimVfCi6QlOV9ZNO2T',
			'X-Parse-REST-API-Key': 'Fe2miwj6i5iAKC9Pyzl6KdRRk9QmV9lt7BmbqP4E'
		}
		
		if self.session_token is not None:
			headers['X-Parse-Session-Token'] = self.session_token
		
		response = requests.request(method, 'https://api.parse.com/1' + endpoint,
			 	headers=headers, params=params, json=json)
		
		if not silent:
			print(response.json())
		
		return response
		
@pytest.fixture(scope='module')
def parse():
	parse = Parse('admin@test.com', 'test')
	parse.login()
	return parse