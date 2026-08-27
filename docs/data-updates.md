# Updating the data files

While speech parsing is automated, the parliamentary calendar and the people records (and their ministerial roles)
are updated by hand. This is a routine workflow, not an anomaly: every by-election, resignation, party change,
general election and ministerial reshuffle lands here as an edit to a CSV file in `data/`.

This guide describes each workflow and the file formats. The conventions are distilled from the ~90 data-update PRs
merged since 2018, and from the parser code that reads these files (`lib/people_csv_reader.rb`, `lib/name.rb`).

## The files

| File | One row per | Date format |
|---|---|---|
| `data/people.csv` | person | `d.m.yyyy` |
| `data/representatives.csv` | period of service (stint) in the House | `d.m.yyyy` |
| `data/senators.csv` | period of service (stint) in the Senate | `d.m.yyyy` |
| `data/ministers.csv` | person-portfolio period in the ministry | `dd/mm/yyyy` |
| `data/shadow-ministers.csv` | person-portfolio period in the shadow ministry | `dd/mm/yyyy` |

**The two date formats are different.** Members files use dots (`21.5.2022`); ministers files use slashes
(`13/05/2025`). Always use 4-digit years: the date parser accepts `14.2.18` silently and produces the year 18
(this bug reached the live site once).

Lines starting with `#` in the members files are comments, used to delimit election cohorts
(e.g. `# New reps from 2025 election`).

### data/people.csv

Columns: `person count, aph id, name, birthday, alt name` (plus extra unnamed alt-name columns).

- **person count** — the person's permanent identifier, *not* a count (see Gotchas in the README). Append new
  people at the bottom with the next sequential number. Gaps are tolerated (1030 was skipped historically) but never
  create one deliberately, and never reuse a skipped or removed number.
- **aph id** — the identifier assigned by aph.gov.au, found in the URL of the person's APH profile page, e.g.
  `https://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=8GH` gives `8GH`. Older IDs are short
  alphanumerics; modern ones are 6-digit numbers.
- **name** — the person's preferred/common name, as Hansard uses it.
- **alt name** — full legal name(s) and any variants Hansard uses (e.g. `Sean Bell` with alt `Sean Frederick Bell`;
  `Raff Ciccone` with alt `Rafael Ciccone`). Add alt names retroactively when the parser fails to match a variant.

### data/representatives.csv and data/senators.csv

Columns: `member count, person count, name, Division, State/Territory, Date of election, Type of election,
Date ceased to be a Member, reason, Most recent party`.

- **member count** — the stint's permanent identifier. Append-only, next sequential number.
- **person count** — leave blank unless two people share a name; it is only read to disambiguate name matches
  against `people.csv` (`lib/people_csv_reader.rb`).
- **Division** — the electorate (House only; blank for senators, who get State/Territory instead).
- **Date of election / Type of election** — when and how the stint began. A blank type means general election;
  otherwise: `by_election`, `section_15` (Senate casual vacancy), `changed_party`, and rarer ones such as
  `declared_elected`, `recount`, `high_court`.
- **Date ceased to be a Member / reason** — how the stint ended. A blank end date means still serving. Reasons in
  use: `resigned`, `retired`, `defeated`, `died`, `changed_party`, `still_in_office`.
- **Most recent party** — an abbreviation mapped to a full party name in `lib/people_csv_reader.rb` (`ALP`, `LIB`,
  `NPA`, `GRN`, `PHON`, `IND`, ...). **A new party means a code change** — see below.

Presiding officers are modelled as pseudo-parties: when someone becomes Speaker, Deputy Speaker, President or
Deputy President of the Senate, close their party stint with reason `changed_party` and open a new stint with
"party" `SPK`, `CWM` (Chairman of Committees, i.e. Deputy Speaker), `PRES` or `DPRES` respectively — and reverse
it when they cease. (`ANTI-SOC` is a historical pseudo-party that also passes through.)

### data/ministers.csv and data/shadow-ministers.csv

Columns: `Name, From, To, Position`.

- **Name** must match the official ministry list formatting *including honorifics*: `The Hon Anthony Albanese MP`,
  `Senator the Hon Penny Wong`, `The Hon Dr Andrew Leigh MP`. The name parser accepts `The Hon` but **not** bare
  `Hon`, and post-nominals (`AM`, `CSC`, `KC`, ...) must be in the whitelist in `lib/name.rb` — an unknown one
  crashes the parse.
- One row per person per position: a person holding four portfolios gets four rows. "Positions" include roles like
  *Leader of the House*, *Manager of Opposition Business* and *Minister for X in the Senate*.
- A blank **To** date means they still hold the position.
- Row order doesn't matter to the parser. Convention: keep a person's rows together — add new rows adjacent to
  their existing block; there is no global ordering.

## Workflows

### Someone leaves parliament

Fill in the end date and reason on their existing row in `data/representatives.csv` or `data/senators.csv`. That's
the whole change. If they were a minister, also close their rows in the ministers file (usually as part of the
consequent reshuffle).

### Someone enters parliament (by-election, Senate casual vacancy)

Two records:

1. A new person row at the bottom of `data/people.csv` (next `person count`, their `aph id`, name, birthday,
   alt names).
2. A new stint row at the bottom of the chamber file with `Type of election` set to `by_election` or `section_15`.

Make both edits in the same PR so the data can't land half-applied.

### Someone changes party (or becomes Speaker/President)

In the chamber file: fill the end date on their current stint with reason `changed_party`, and append a new stint
starting the same date with `Type of election` `changed_party` and the new party (or pseudo-party — see above).

### General election

Lots of the above at once, plus a hard ordering constraint: the files are parsed as people → members → ministers,
and each layer must name-match against the previous one. Land the changes in this order:

1. `data/people.csv` — all new entrants
2. `data/representatives.csv` and `data/senators.csv` — closed and new stints
3. `data/ministers.csv` / `data/shadow-ministers.csv` — the new ministry, once sworn in

A ministry PR that names people whose election results haven't been merged yet cannot parse.

### Ministerial reshuffle

The authoritative sources are the *Ministerial Arrangements* / *Shadow Ministerial Arrangements* documents tabled
in parliament (findable in Hansard via ParlInfo), the PM&C ministry list, and the APH shadow ministry list.
Reconcile the relevant CSV against the new list: fill `To` dates (the reshuffle date) on every position that
changed hands or was abolished, and add new rows starting that date. Note the official lists sometimes lag
reality by days — it's fine to wait for them.

### Updating recess and sitting dates in the calendar

The calendar on OpenAustralia.org is driven by `recess.php` in the
[web application's repository](https://github.com/openaustralia/twfy/) (`www/includes/easyparliament/recess.php`),
not by this repo. Specify the date ranges parliament is in *recess* — i.e. NOT sitting. This is unintuitive and
easy to get the wrong way around, so take care. Check by viewing the calendar page for that year on a development
copy: non-sitting dates should be grey and say "recess" on hover.

## When a data update needs a code change

- **New party**: add the abbreviation → full-name mapping to `parse_party` in `lib/people_csv_reader.rb`. An
  unmapped abbreviation raises `Unrecognised party` when the files are parsed.
- **New post-nominal honour** (e.g. someone with `CSC` joins the ministry list): add it to `valid_post_titles` in
  `lib/name.rb`, or the parse crashes with `Can't find <name>`.

## Checking your changes

Required before opening a PR touching these files:

```
bundle exec ./parse-members.rb --no-load
```

This parses all five CSV files and generates the members XML without writing to the database — it catches
unmatchable names, bad dates, unknown parties and honorific problems. If you've touched postcode data, also run
`bundle exec ./postcodes.rb --no-load`.

Optionally, run the test suite (`bundle exec rake`) for extra assurance, and if you have a local development copy
of OpenAustralia.org, run `./parse-members.rb` without flags and check the changes loaded correctly.

## PR conventions

- One PR per event (a by-election, a resignation, a reshuffle), touching whichever files that event requires.
- Cite your sources in the PR description: the APH profile page, the tabled Ministerial Arrangements document,
  the PM&C ministry list, or a news report.
- Respect the general-election ordering above across PRs.
- After a PR merges here, the umbrella repository's (`openaustralia/openaustralia`) submodule pointer must be
  bumped before production picks the change up.

## Pitfalls

- `d.m.yyyy` in members files vs `dd/mm/yyyy` in ministers files; 2-digit years parse silently as the literal
  year (`18`, not `2018`).
- `Hon` without `The` is rejected by the name parser.
- Regenerating the members XML can renumber ministerial-office (`moffice`) IDs consumed downstream; ministry
  changes are riskier than member changes and historically get an extra verification pass before deployment.
- A closed PR doesn't mean rejected — maintainers sometimes commit the same change directly.
- The most common production failure ("Couldn't figure out who X is in division") is fixed by adding the missing
  person or alt name using the workflows above, then re-running the parser for the missing days (see "Failures"
  in the README).
