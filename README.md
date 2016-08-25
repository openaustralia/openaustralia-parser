# The OpenAustralia Hansard Parser [![Build Status](https://travis-ci.org/openaustralia/openaustralia-parser.svg?branch=master)](https://travis-ci.org/openaustralia/openaustralia-parser) [![Dependency Status](https://gemnasium.com/openaustralia/openaustralia-parser.png)](https://gemnasium.com/openaustralia/openaustralia-parser)

See for installation instructions http://software.openaustralia.org/install-parser.html

## Data updates

We try to automate data updates to OpenAustralia.org as much as possible but in some circumstances it's not currently possible. This section lists the various bits of data that we need to keep up to date manually.

### Recesses/calendar

The sitting dates shown on [the calendar](http://www.openaustralia.org.au/debates/?y=2016) on OpenAustralia.org and a little banner on the front page are based on information in [`recess.php`](https://github.com/openaustralia/twfy/blob/master/www/includes/easyparliament/recess.php) in the [web application's repository](https://github.com/openaustralia/twfy/).

In that file you need to specify the date ranges that the parliament is in _recess_, i.e. NOT sitting. This is a bit unintuitive and it's easy to get the wrong way around so take care.
