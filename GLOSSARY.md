# Hansard Parser

The parser that turns the Australian Parliament's published Hansard into structured XML and loads it into the
OpenAustralia.org database, matching every speech and vote to the person who made it.

## Language

### People and service

**Person**:
A human who serves or served in parliament, identified by a permanent `person count` in `data/people.csv`. One
Person can have many stints and many ministerial positions.

**Stint**:
One continuous period of service in a single house — one row in `data/representatives.csv` or `data/senators.csv`,
identified by a `member count`. A party change ends one stint and starts another.
_Avoid_: membership record, period (the code's `Period` class models a stint, but "period" is too generic in prose)

**person count**:
The permanent identifier of a Person. Despite the name it is not a count: gaps are tolerated and numbers are never
reused.
_Avoid_: person id (in prose about the CSV files; the column is literally named "person count")

**member count**:
The permanent identifier of a stint. Same caveat: an identifier, not a count.

**aph id**:
The identifier aph.gov.au assigns to a parliamentarian, visible in their APH profile URL. Used to match Hansard
speakers to People.

**alt name**:
An alternative name for a Person (full legal name or a variant Hansard uses), recorded in `data/people.csv` so the
parser can match them.

### Houses and roles

**House**:
One of the two chambers: the House of Representatives or the Senate.

**Division (electorate)**:
The geographic seat a representative holds, e.g. Fadden. The `Division` column in the members CSVs.

**division (vote)**:
A formal recorded vote in a chamber. The classic parser failure — "Couldn't figure out who X is in division" —
uses this sense, not the electorate sense.

**pseudo-party**:
A party-column value that encodes a presiding office rather than a party: `SPK` (Speaker), `CWM` (Deputy Speaker /
Chairman of Committees), `PRES` (President of the Senate), `DPRES` (Deputy President), plus the historical
`ANTI-SOC`. Taking or leaving such an office is modelled as a party change.

**position**:
A ministerial or shadow-ministerial role held by a Person for a period — one row in `data/ministers.csv` or
`data/shadow-ministers.csv`.
_Avoid_: moffice (the downstream XML/database name for the same concept)

### Parsing artefacts

**patch**:
A hand-made diff in `data/patches/` applied to cached Hansard XML/HTML to fix source errors too painful to handle
in code.

**gid**:
The global identifier assigned to each parsed item (speech, division, etc.) in the emitted XML; downstream systems
(database loading, search indexing, email alerts) key off it.
