import sys
othertype = sys.argv[1]


import csv

if othertype == "senators":
	oldsample = ["member count","person count","name","Division","State/Territory","Date of election","Type of election","Date ceased to be a Member","reason","Most recent party"]
	oldsample = ['284', '', 'Matt Thistlethwaite', '', 'NSW', '11.3.2009', 'section_15', '', 'still_in_office', 'ALP']

elif othertype == "representatives":
	oldsample = ["member count","person count","name","Division","State/Territory","Date of election","Type of election","Date ceased to be a Member","reason","Most recent party"]
	oldsample = ['284', '', 'Matt Thistlethwaite', '', 'NSW', '11.3.2009', 'section_15', '', 'still_in_office', 'ALP']
else:
	raise Exception('Unknown %s' % othertype)

newsample = ['state','id','name','party']
peoplesample = ['person count','aph id','name','birthday','alt name']

def strip_title(a):
	a = a.strip()
	while True:
		if a.startswith('The '):
			a = a[4:]
			continue
		if a.startswith('Hon '):
			a = a[4:]
			continue
		if a.startswith('Mr '):
			a = a[3:]
			continue
		if a.startswith('Ms '):
			a = a[3:]
			continue
		if a.startswith('Mrs '):
			a = a[4:]
			continue
		if a.startswith('Dr '):
			a = a[3:]
			continue
		break
	return a

def match_names(a, b):
	a = strip_title(a)
	b = strip_title(b)

	import re
	if re.match(a.replace(' ', '.*'), b) is not None:
		return True
	if re.match(b.replace(' ', '.*'), a) is not None:
		return True
	return False


other_by_name = {}
other_by_area = {}
other_max_count = -1
for i in csv.DictReader(file(othertype+'.csv')):
	text = i['member count']
	if text.startswith('#'):
		if text.startswith("# Next"):
			new_other_max_count = int(text.split(' ')[-1])
			if new_other_max_count > other_max_count:
				other_max_count = new_other_max_count
		continue
	cid = int(text)
	other_by_name[i['name']] = cid
	#print i.get('Division', None), i['name']
	if i['reason'] == 'still_in_office':
		other_by_area[i.get('Division', None)] = i['name']
	if cid > other_max_count:
		other_max_count = cid

people_by_aphid = {}
people_by_pcount = {}
person_max_count = -1
for i in csv.DictReader(file('people.csv')):
	text = i['person count']
	if text.startswith('#'):
		if text.startswith("# Next"):
			new_person_max_count = int(text.split(' ')[-1])
			if new_person_max_count > person_max_count:
				person_max_count = new_person_max_count
		continue
	people_by_aphid[i['aph id']] = i['name']
	people_by_pcount[int(text)] = i['name']

	new_person_max_count = int(i['person count'])
	if new_person_max_count > person_max_count:
		person_max_count = new_person_max_count

new_other = file('new-%s.csv' % othertype, 'w')
new_peoples = file('new-people.csv', 'w')

import urllib
if othertype == "senators":
	new = urllib.urlopen('https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=csv&name=australian_senators&query=select+*+from+`swdata`')
elif othertype == "representatives":
	new = urllib.urlopen('https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=csv&name=australian_members_of_parliament&query=select+*+from+`swdata`')
else:
	raise Exception('Unknown %s' % othertype)

for i in csv.DictReader(new):
	if len(i) < len(newsample):
		continue

	found = False
	for name in other_by_name:
		if match_names(name, i['name']):
			if i.get('area', None) is None:
				found = True
				break
			
			if match_names(other_by_area[i['area']], i['name']):
				found = True
				break

	if not found:
		new_otherline = list(oldsample)
		other_max_count += 1
		new_otherline[0] = str(other_max_count)
		new_otherline[2] = i['name']
		new_otherline[3] = i.get('area', '')

		state = ''.join(x[0] for x in i['state'].strip().split())
		if len(state) == 1:
			state = i['state'].strip()
		if state == 'Qld':
			state = 'Queensland'
		elif state == 'Vic':
			state = 'Victoria'
		elif state == 'Tas':
			state = 'Tasmania'

		new_otherline[4] = state
		i['party'] = i['party'].strip()
		if i['party'] == 'Australian Labor Party':
			party = 'ALP'
		elif i['party'] == 'Independent':
			party = 'IND'
		elif i['party'] == 'Australian Greens':
			party = 'GRN'
		elif i['party'].startswith('The Nationals'):
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
		new_otherline[-1] = party
		print >>new_other, ",".join(new_otherline)

	if i['id'] not in people_by_aphid:
		found = False
		for oldpcount, name in people_by_pcount.items():
			if match_names(name, i['name']):
				found = True
				break

		new_people = list(peoplesample)
		if not found:
			person_max_count += 1
			new_people[0] = str(person_max_count)
		else:
			new_people[0] = str(oldpcount)
		new_people[1] = i['id'].strip().upper()
		new_people[2] = i['name'].strip()
		new_people[3] = ''
		new_people[4] = ''
		if found:
			print >>new_peoples, "# ID changed!"
			print >>new_peoples, '#' + ",".join(new_people)
		else:
			print >>new_peoples, ",".join(new_people)
