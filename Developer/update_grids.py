#! /usr/bin/env python3
# Requires ParsePy from https://github.com/dgrtwo/ParsePy

from parse_rest.connection import register
from parse_rest.datatypes import Object
from parse_rest.datatypes import Function
from parse_rest.user import User
from parse_rest.connection import SessionToken
import sys

is_prod = len(sys.argv) > 1 and sys.argv[1] == 'prod'

if is_prod:
	facilityId = '44SpXTtzUl'
	register('5pYOx25qvyg4IVXyu128IuRlbnJtwLgwCTsHXCpO', 'xkuupM8jCHRcR15G0WJ1BjAixZEzf8vrTiyWrUjr',
			master_key='2xUvmLlh5L0oh7SE7XrlFxtaLkA8kUxP0vI8sFjl')
else:
	facilityId = 'ZsFlRbIPqy'
	register('jjQlIo5A3HWAMRMCkH8SnOfimVfCi6QlOV9ZNO2T', 'Fe2miwj6i5iAKC9Pyzl6KdRRk9QmV9lt7BmbqP4E', 
			master_key='bswubKWU9MvLuQdh8tYbAt9qXu5guxaZBIMTmHsc')

u = User.login("admin@test.com", "test")

shifts = {
	'Charge Nurse': [
		[0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	],
	'NA': [
		[0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3],
		[0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3],
		[0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3],
		[0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3]
	],
	'Nurse': [
		[0,0,0,0,0,0,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6],
		[0,0,0,0,0,0,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6],
		[0,0,0,0,0,0,2,2,2,2,2,2,2,2,3,3,3,3,3,3,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6],
		[0,0,0,0,0,0,2,2,2,2,2,2,2,2,3,3,3,3,3,3,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6]
	],
	'SEC': [
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	]
}

class Unit(Object):
	pass

class Facility(Object):
	pass

updateGrid = Function('updateGrid')
facility = Facility(objectId=facilityId)

with SessionToken(u.sessionToken):
	units = Unit.Query.filter(facility=facility)

	total_count = len(units) * len(shifts)
	index = 0

	for unit in units:
		for staffTitle in shifts:
			percent = int((index * 100)/total_count)
			index += 1

			print('{}%\t  Updating {} for {}'.format(percent, staffTitle, unit.name))
			json = {
				'staffTitle': staffTitle,
				'unitId': unit.objectId,
				'grids': shifts[staffTitle]
			}

			updateGrid(**json)
