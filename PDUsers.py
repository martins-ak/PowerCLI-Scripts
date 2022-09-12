#Export a list of all users to a CSV file.
#This script is not supported by PagerDuty.

#!/usr/bin/env python

import datetime
import requests
import sys
import csv

#Your PagerDuty API key.  A read-only key will work for this.
AUTH_TOKEN = 'u+NmVn8VCkq1iv-R33qQ'
#The API base url, make sure to include the subdomain
BASE_URL = 'https://gracenote.pagerduty.com/api/v1'
csvfile = "/Users/martinaides/Downloads/PDUsers.csv"

HEADERS = {
	'Authorization': 'Token token={0}'.format(AUTH_TOKEN),
	'Content-type': 'application/json',
}

user_count = 0

def get_user_count():
	global user_count
	count = requests.get(
		'{0}/users'.format(BASE_URL),
		headers=HEADERS
	)
	user_count = count.json()['total']

def get_users(offset):
	global user_count

	params = {
		'offset':offset
	}
	all_users = requests.get(
		'{0}/users'.format(BASE_URL),
		headers=HEADERS,
	params=params
	)
	print ("Exporting all users to " + csvfile)
	for user in all_users.json()['users']:
		with open(csvfile, "a") as output:
		    writer = csv.writer(output, lineterminator='\n')
		    writer.writerow( [user['id']] + [user['email']] + [user['name']])

def main(argv=None):
	if argv is None:
		argv = sys.argv

	get_user_count()

	for offset in xrange(0):
		if offset % 25 == 0:
			get_users(offset)

if __name__=='__main__':
	sys.exit(main())
