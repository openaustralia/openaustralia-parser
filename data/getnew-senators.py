import csv

oldsample = ['284', '', 'Matt Thistlethwaite', '', 'NSW', '11.3.2009', 'section_15', '', 'still_in_office', 'ALP']
newsample = ['state','id','name','fax','office','phone','party','dob']
peoplesample = ['person count','aph id','name','birthday','alt name']


senators = {}
for i in csv.DictReader(file('senators.csv')):
	if i['member count'][0] == '#':
		continue
	cid = int(i['member count'])
	senators[i['name']] = cid

people = {}
for i in csv.DictReader(file('people.csv')):
	if i['person count'][0] == '#':
		continue
	people[i['aph id']] = i['name']
	person_count = int(i['person count'])

new_senators = file('new-senators.csv', 'w')
new_peoples = file('new-people.csv', 'w')

import urllib
new = urllib.urlopen('https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=csv&name=australian_senators&query=select+*+from+`swdata`')
for i in csv.DictReader(new):
	if len(i) != len(newsample):
		continue
	if i['name'].startswith('Hon '):
		i['name'] = i['name'][4:]

	found = False
	for name in senators:
		regex = i['name'].replace(' ', '.*')
		import re
		if re.match(regex, name):
			found = True
			break

	if not found:
		new_senate = list(oldsample)
		cid += 1
		new_senate[0] = str(cid)
		new_senate[2] = i['name']

		state = ''.join(x[0] for x in i['state'].strip().split())
		if len(state) == 1:
		  state = i['state'].strip()
		new_senate[4] = state
		i['party'] = i['party'].strip()
		if i['party'] == 'Australian Labor Party':
			party = 'ALP'
		elif i['party'] == 'Independent':
			party = 'IND'
		elif i['party'] == 'Australian Greens':
			party = 'GRN'
		elif i['party'] == 'The Nationals':
			party = 'NP'
		elif i['party'] == 'Country Liberal Party':
			party = 'CLP'
		elif i['party'] == 'Liberal Party of Australia':
			party = 'LIB'
		elif i['party'] == 'Democratic Labor Party':
			party = 'DLP'
		else:
			print "Unknown party '%s'" % i['party']
			continue
		new_senate[-1] = party
		print >>new_senators, ",".join(new_senate)

		if i['id'] not in people:
			found = False
			for name in people.items():
				regex = i['name'].replace(' ', '.*')
				import re
				if re.match(regex, i['name'].strip()):
					found = True
					break

			new_people = list(peoplesample)
			person_count += 1
			new_people[0] = str(person_count)
			new_people[1] = i['id'].strip()
			new_people[2] = i['name'].strip()
			new_people[3] = ''
			new_people[4] = ''
			if found:
				print >>new_peoples, "# ID changed!"
				print >>new_peoples, ",".join(new_people)
			else:
				print ",".join(new_people)
