# The OpenAustralia Hansard Parser [![Build Status](https://travis-ci.org/openaustralia/openaustralia-parser.svg?branch=master)](https://travis-ci.org/openaustralia/openaustralia-parser) [![Dependency Status](https://gemnasium.com/openaustralia/openaustralia-parser.png)](https://gemnasium.com/openaustralia/openaustralia-parser)

See for installation instructions http://software.openaustralia.org/install-parser.html

## Data updates

While we have largely automated data updates to [OpenAustralia.org](http://www.openaustralia.org.au/), the parliamentary calendar and people records (and their ministerial roles) must be updated manually. This section explains how you can update these bits and check your changes.

### Updating recess and sitting dates in the calendar

The parliamentary sitting dates are shown on [the calendar](http://www.openaustralia.org.au/debates/?y=2016) on OpenAustralia.org and as a little banner on the front page.
These are both based on information in [`recess.php`](https://github.com/openaustralia/twfy/blob/master/www/includes/easyparliament/recess.php) in the [web application's repository](https://github.com/openaustralia/twfy/).

#### How

In the `recess.php` file you need to specify the date ranges that the parliament is in _recess_, i.e. NOT sitting. This is a bit unintuitive and it's easy to get the wrong way around so take care.

#### Checking

After you've made these changes open your development copy of OpenAustralia.org and visit the [calendar page](http://www.openaustralia.org.au/debates/?y=2016) for the year you've changed to see if it looks OK. Non-sitting dates should be grey and should say "recess" when you hover over them.

### Adding or removing people

During the term of a parliament, for all sorts of reasons, people can leave (e.g. retirement, death) or enter parliament (e.g. by-election, appointed to fill a [casual vacancy](https://en.wikipedia.org/wiki/Australian_Senate#Casual_vacancies)). At a general election lots of people leave and enter parliament as they're elected or not re-elected.

#### How

##### Leaving parliament

When someone leaves parliament you need to update their membership record's end date and reason they left parliament. This could be in [`data/representatives.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/representatives.csv) or [`data/senators.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/senators.csv), depending on which House they were in.

Here's [an example](https://github.com/openaustralia/openaustralia-parser/commit/1b20b321c436c819f256461fa79b4d9c8762f71c#diff-04102f0761533ac76b4dade410634698R39) that was part of the 2016 election where Bruce Billson retired (and Chris Crewther was added as his replacement in the same commit).

##### Changing parties

When someone [changes parties](https://github.com/openaustralia/openaustralia-parser/commit/41838814d7b51059d6ba56c0f1a4c74aece2cba6), or [becomes Speaker](https://github.com/openaustralia/openaustralia-parser/commit/2f6990bb8da5e5452103c649ac92c18709fadf3e), you need to update their membership record's end date and reason (to `changed_party`), and create a new one for their new party membership.

##### Entering parliament

When a new person enters parliament, you need to create **two kinds of records** for them.

Firstly, you need to add a new Person record at the end of [`data/people.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/people.csv).
The "APH ID" referred to in this file is the one you can find in the URL string of the person's APH profile page.
For example, [Linda Burney's](http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=8GH) is `8GH` as you can see in the URL of her APH page http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=<strong>8GH</strong> and also in [the commit](https://github.com/openaustralia/openaustralia-parser/commit/8c286a12f5cc00682a011b4159d821ccc7b3b245#diff-b66a2e76ccb4627268b1733ec86424e8R887) that added her to OpenAustralia.org.

Secondly, you need to create a membership record for them, just like [when a person changes parties](https://github.com/openaustralia/openaustralia-parser#changing-parties).

See [commit ee9d91c](https://github.com/openaustralia/openaustralia-parser/commit/ee9d91c7250688200217cb47b51aa43c45f3b8e1) for an example of making both the required changes for new MP Malarndirri McCarthy.

#### Checking

After making changes to the data files, you can run `bundle exec ./postcodes.rb --test` and `bundle exec ./parse-members.rb --test`. In test mode, these scripts will simply verify that the data files can be correctly parsed, without writing to the database.

These checks are also run by Travis when your changes are pushed to github.

If you have a local development copy of OpenAustralia.org, you can also run [`./parse-members.rb`](https://github.com/openaustralia/openaustralia-parser/blob/master/parse-members.rb), and check that it's loaded your changes correctly into your development copy of OpenAustralia.org.

### Ministerial reshuffles

On each person's profile page we show the positions they hold or have held in the past. For example, these could be _Shadow Minister for Health_ or _Prime Minister_. We also show it next to their name in the debates to give some extra context about who is speaking.

These change when there's a ministerial reshuffle. This can happen because the party decides to make a change or because it's forced to, e.g. when someone leaves parliament. In addition to the government's ministry there's also the opposition's shadow ministry.

#### How

These changes are usually tabled in parliament and show up in Hansard under the heading _Ministerial Arrangements_ or _Shadow Ministerial Arrangements_. Here's [an example](http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;db=CHAMBER;id=chamber%2Fhansardr%2F1133bdef-2731-42fb-a226-6522e1a8fec5%2F0025;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansardr,hansardr80%20Date%3A30%2F8%2F2016;rec=0;resCount=Default) of the one from the start of the 2016 parliament.

What you need to do is go through that document and make sure the data that we have in [`data/ministers.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/ministers.csv) or [`data/shadow-ministers.csv`](https://github.com/openaustralia/openaustralia-parser/blob/master/data/shadow-ministers.csv) matches it. This means adding "to" dates to people that are no longer in the list and adding new records for those people that have been added.

#### Checking

After making changes run [`./parse-members.rb`](https://github.com/openaustralia/openaustralia-parser/blob/master/parse-members.rb), check the output, and also check that it's loaded your changes correctly into your development copy of OpenAustralia.org.

## Failures

Every weekday the `./parse-speeches.rb` script gets run by cron to parse and import new speeches into OpenAustralia.org. From time to time this fails. We can see this when there's a missing day of debates on OpenAustralia.org on the calendar, e.g. http://www.openaustralia.org.au/debates/?y=2017

![Probably a parser failure](https://user-images.githubusercontent.com/48945/31870296-ed69eb78-b7f8-11e7-93e7-9fe1c9b51337.png)

Or by checking the cron output which is emailed to the OAF `web-administrators` Google Group and posted in the `#openaustralia-log` Slack channel. It will look something like this:

```
Start time: 2017-09-05 09:05:01 AEST
Parsing from APH to XML and loading into the database


parse-speeche:   0% |                                          | ETA:  --:--:--
parse-speeche:  50% |ooooooooooooooooooooo                     | ETA:  00:00:19
./../openaustralia-parser/lib/hansard_parser.rb:197:in `throw': uncaught throw `2017-09-04 senate: Couldn't figure out who Brockman, S is in division (voting no)' (NameError)
        from ../../openaustralia-parser/lib/hansard_parser.rb:197:in `parse_date_house'
        from ../../openaustralia-parser/lib/hansard_parser.rb:193:in `map'
        from ../../openaustralia-parser/lib/hansard_parser.rb:193:in `parse_date_house'
        from ../../openaustralia-parser/lib/hansard_parser.rb:159:in `each'
        from ../../openaustralia-parser/lib/hansard_parser.rb:159:in `parse_date_house'
        from ../../openaustralia-parser/parse-speeches.rb:94
Xapian indexing
Running rssgenerate
./sitemap.rb:386:in `notify_search_engines': uninitialized constant Sitemap::PINGMYMAP_API_URL (NameError)
        from ./sitemap.rb:453
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap1.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap2.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap3.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap4.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap5.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap6.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap7.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap8.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap9.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap10.xml.gz)...
Writing sitemap file (/srv/www/www.openaustralia.org/current/twfy/www/docs/sitemaps/sitemap11.xml.gz)...
Whole thing done time: 2017-09-05 10:40:40
```

You can see in the output above there's an exception thrown by the parser. It's complaining about not being able to figure out who the person is that's voted in a division. This is one of the most common failures. The fix is to [add the person](#adding-or-removing-people) using the instructions above and run the parser again for the missing days.

The other most common failure is that APH has published something wacky. To fix this you need to delete the cache for that day and run the parser again.

Once you've loaded the speeches, you'll need to [index](#Indexing)
the days you just loaded.

### Indexing

After you've fixed a parsing issue and loaded in data from the missing
days, you may need to manually add those dates to the index. The
`morningupdate` cron job normally indexes yesterday's speeches, but if
that's missed we don't have anything that will autoamaticall find and
index the missing days.

However, this is fairly easy to do. To index all speeches between the
25th June 2018 and 17th August 2018:

```
export XAPIANDB=/srv/www/production/shared/search/searchdb
/srv/www/production/current/twfy/search/index.pl $XAPIANDB daterange2018-06-25 2018-08-17
xapian indexing debate 2018-06-25
xapian indexing lords 2018-06-25
xapian indexing debate 2018-06-26
xapian indexing lords 2018-06-26
xapian indexing debate 2018-06-27
xapian indexing lords 2018-06-27
xapian indexing debate 2018-06-28
xapian indexing lords 2018-06-28
xapian indexing debate 2018-08-13
xapian indexing lords 2018-08-13
xapian indexing debate 2018-08-14
xapian indexing lords 2018-08-14
xapian indexing debate 2018-08-15
xapian indexing lords 2018-08-15
xapian indexing debate 2018-08-16
xapian indexing lords 2018-08-16

```

### Skipping email alerts after fixing a scraper failure

If you've fixed a failure and you load lots of missing data into OpenAustralia.org it will automatically send lots of email alerts the next day. This probably isn't what the subscribers want so you need a way to skip sending email alerts for the data you've just loaded.

**tl;dr** Bump the timestamp and batch number in `alerts-lastsent` which is in `twfy/scripts`.

The `alerts-lastsent` file has two lines, the first is a Unix timestamp and the second is a batch ID.

After you've loaded debates into the DB and run [indexing](#Indexing) update the first line to the current time as this will be later than the index you just did - you can find out the time with `date +%s`. Then increment the batch ID on the second line and save the file.

Now when you run `alertmailer.php` it shouldn't send out alerts for any of the debates you've just loaded. There's more detail in this helpful email from mySociety's Matthew Somerville.

>> I've never quite understood the relationship between the alert
>> emailer and the xapian index. Unfortunately, looking through the code
>> hasn't helped me much. :-(
>
> Sorry, it's all a bit strewn about. I'll try and explain below.
>
>> Let's say I make some fixes to the parser and I regenerate all the xml
>> files. I then reload this into the database and do a xapian reindex on
>> everything. How can I do this without generating spurious email alerts
>> the next day for any pages that have changed?
>
> Unbelievably, it might just work, although there are a number of extra things you can do if you're worried about it (or just test it better than we ever did ;) ). Here's the full process of how email alerts runs, then some history, and then some actually maybe useful stuff ;)
>
> 1. Firstly, the database. When you load data with xml2db.pl, a brand new GID gets new created and modified timestamps set to NOW(). When you reload data, if the GID is the same then only the modified timestamp is updated to NOW(), the created doesn't change ever.
>
> 2. When running a Xapian index with index.pl, if you use "sincefile" as we do, then it only indexes GIDs that have a modified column dated since the last time it ran. If you run Xapian index with a date range etc., then it will index or reindex everything on those dates.
>
> 3. Whatever is decided to be indexed, each gets a new batch number (that goes up 1 each time you run Xapian indexing and it indexes something), and also gets a "created" value consisting of its hansard created column concatenated with its hpos.
>
> 4. When you run the alert email script, it only fetches those GIDs that have: a) a *batch number* larger than the highest batch number last time the script was run; b) a *created* higher than the last time the script was run; c) is later than the manual date given in the script (line 174ish).
>
>
> So let's do a worked example. You've fixed a parser bug which has caused 10 GIDs on 2001-01-01 to change, and 5 new GIDs to appear on 2002-02-02. You ran the email alert script yesterday, before doing this, up to batch 100. You reload the XML for those two days, the 10 GIDs on 2001-01-01 get their modified column updated, the 5 new GIDS on 2002-02-02 get inserted. You reindex with sincefile, and those 15 GIDs get indexed (or you reindex with those two dates and everything on those 2 days gets indexed), with batch ID 101. You run the email alert script, which will only return things: * in batch ID 101 * created since yesterday - ie the 5 new GIDs from 2002-02-02, but not the 10 from 2001-01-01.
>
>
> Hope that makes sense. Now, the original theory was that people would want to be alerted to new stuff even if it was old. But it turns out that a) they don't (they'll complain saying why have they got an alert for old stuff), b) all of our old "new" stuff wasn't actually new, but was because of parser fixes or because they make spelling corrections and our model means everything on that day gets a new GID in that case - which is awful but it's too late to change now...
>
> So what we do. I try to make sure any changing of old content isn't added/indexed along with new stuff - ie. run major changes during holidays etc.. Then when the loading/indexing is done, I can manually bump the batch number/ timestamp in the alerts-lastsent file so that the alert script thinks it's been run on that data already and will just ignore it.
>
> If there's some new stuff indexed as well, which you do want to send alerts for, then that's what the manual date in the alert script is for, to just say "ignore anything before this date completely". Bit yucky, I know, but then so's everything.
>
>
> Phew, hope that's of use to you, and happy Easter!
>
> ATB,
> Matthew

## Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
