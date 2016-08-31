# The OpenAustralia Hansard Parser [![Build Status](https://travis-ci.org/openaustralia/openaustralia-parser.svg?branch=master)](https://travis-ci.org/openaustralia/openaustralia-parser) [![Dependency Status](https://gemnasium.com/openaustralia/openaustralia-parser.png)](https://gemnasium.com/openaustralia/openaustralia-parser)

See for installation instructions http://software.openaustralia.org/install-parser.html

## Data updates

We try to automate data updates to OpenAustralia.org as much as possible but in some circumstances it's not currently possible. This section lists the various bits of data that we need to keep up to date manually.

### Recesses/calendar

#### What

The sitting dates shown on [the calendar](http://www.openaustralia.org.au/debates/?y=2016) on OpenAustralia.org and a little banner on the front page are based on information in [`recess.php`](https://github.com/openaustralia/twfy/blob/master/www/includes/easyparliament/recess.php) in the [web application's repository](https://github.com/openaustralia/twfy/).

#### How

In the `recess.php` file you need to specify the date ranges that the parliament is in _recess_, i.e. NOT sitting. This is a bit unintuitive and it's easy to get the wrong way around so take care.

### Adding or removing people

#### What

During the term of a parliament, for all sorts of reasons, people can leave (e.g. retirement, death) or enter parliament (e.g. by-election, appointed to fill a [casual vacancy](https://en.wikipedia.org/wiki/Australian_Senate#Casual_vacancies)). At a general election lots of people leave and enter parliament as they're elected or not re-elected.

#### How

##### Leaving parliament

When someone leaves parliament you need to update their membership record's end date and reason they left parliament. This could be in [`data/representatives.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/representatives.csv) or [`data/senators.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/senators.csv), depending on which House they were in.

Here's [an example](https://github.com/openaustralia/openaustralia-parser/commit/1b20b321c436c819f256461fa79b4d9c8762f71c#diff-04102f0761533ac76b4dade410634698R39) that was part of the 2016 election where Bruce Billson retired (and Chris Crewther was added as his replacement in the same commit).

##### Changing parties

TODO.

##### Entering parliament

TODO.

### Ministerial reshuffles

#### What

On each person's profile page we show the positions they hold or have held in the past. For example, these could be _Shadow Minister for Health_ or _Prime Minister_. We also show it next to their name in the debates to give some extra context about who is speaking.

These change when there's a ministerial reshuffle. This can happen because the party decides to make a change or because it's forced to, e.g. when someone leaves parliament. In addition to the government's ministry there's also the opposition's shadow ministry.

#### How

These changes are usually tabled in parliament and show up in Hansard under the heading _Ministerial Arrangements_ or _Shadow Ministerial Arrangements_. Here's [an example](http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;db=CHAMBER;id=chamber%2Fhansardr%2F1133bdef-2731-42fb-a226-6522e1a8fec5%2F0025;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansardr,hansardr80%20Date%3A30%2F8%2F2016;rec=0;resCount=Default) of the one from the start of the 2016 parliament.

What you need to do is go through that document and make sure the data that we have in [`data/ministers.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/ministers.csv) or [`data/shadow-ministers.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/shadow-ministers.csv) matches it. This means adding "to" dates to people that are no longer in the list and adding new records for those people that have been added.

## Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
