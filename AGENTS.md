# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot, and others) when working with code in
this repository. `CLAUDE.md` and `.github/copilot-instructions.md` point here so the guidance lives in one place.

## What this repository is

The OpenAustralia Hansard parser: Ruby scripts that parse Hansard from the Australian Parliament and load it into
the OpenAustralia.org.au database. It is consumed as a git submodule of
[`openaustralia/openaustralia`](https://github.com/openaustralia/openaustralia) (the umbrella repository), and in
production is driven by the `twfy` app's cron scripts (`dailyupdate` runs `parse-member-links.rb` nightly;
`morningupdate` runs `parse-speeches.rb previous-working-day` then `sitemap.rb` on weekdays).

## Setup

Ruby 3.4.9 (`.ruby-version`).

```
mise install
bundle install
cp configuration.yml.example configuration.yml
```

- `configuration.yml` is gitignored and **required before anything runs, including `bundle exec rake`** - the
  Rakefile loads `lib/configuration.rb`, which reads it unconditionally.
- Its defaults assume a sibling umbrella checkout (`web_root: "../openaustralia"`) and reach into
  `rblib/config.rb` and `twfy/conf/general` there. For standalone development, uncomment the "Standalone
  development override" keys in the example so you don't need twfy or PHP at all (see README).
- The example file has placeholder `morph_api_key` / `theyvoteforyou_api_key` values; real keys belong only in the
  gitignored `configuration.yml`, never in a commit.
- The `hpricot` gem needs a compiler workaround on modern toolchains, and `.bundle/` is gitignored, so on a fresh
  clone run `bundle config build.hpricot --with-cflags=-Wno-error=incompatible-function-pointer-types` before
  `bundle install`.
- A local MySQL database is needed for the load scripts; the exact `CREATE DATABASE`/`CREATE USER` statements are
  in the README.

## Commands

```
bundle exec rake                     # default task: the RSpec suite
bundle exec rspec spec/lib/name_spec.rb
bundle exec rubocop
bundle exec ruby-audit / bundle exec bundle-audit
bundle exec ./parse-members.rb --no-load   # data-file sanity checks, no DB writes
bundle exec ./postcodes.rb --no-load
bundle exec rake db:stats / db:backup / db:validate_encoding
script/console                       # loads lib/**/*.rb into IRB
```

`bin/run <script>` is the production wrapper (picks the Ruby manager, dispatches .rb/.pl/.php); you don't need it
locally.

## Structure

- Top-level `*.rb` scripts are the entry points; the daily ones are `parse-speeches.rb`, `parse-member-links.rb`
  and `sitemap.rb`. `lib/` holds the parser proper (`hansard_parser.rb`, `hansard_rewriter.rb`, `people.rb`, ...).
- `data/*.csv` (people, representatives, senators, ministers, shadow-ministers) are **maintained by hand** for
  by-elections, party changes and reshuffles - a routine workflow here, not an anomaly. The full workflows and file
  formats are in `docs/data-updates.md`. The most common parser failure is an unrecognised person in a division;
  the fix is usually a data file edit.
- `xml_schemas/*.rnc` are RELAX NG schemas for the XML the parser emits; `spec/` uses RSpec with VCR cassettes.
- `docs/` holds `docs/data-updates.md` (the data-maintenance guide) and `docs/agents/`, the configuration the
  engineering skills read (see "Agent skills" below). There is no other prose documentation outside the README.

## Gotchas

- **Hpricot is gone, Nokogiri is the HTML parser throughout** (PR #253 converted it fully, not just
  `parse-member-links.rb` as earlier noted here). Titles/subtitles built by hand for raw XML insertion (eg
  `lib/hansard_day.rb`'s `title`/`subtitle`/`title_tag_value`) go through `numeric_entities` before use - Nokogiri's
  entity output is inconsistent (numeric ref, named HTML entity, or literal UTF-8 char depending on the surrounding
  markup), and raw-appended text has to be deterministically XML-safe regardless.
- **No CI runs yet.** There is no `.github/workflows/`; the checked-in `.travis.yml` is dead (pins Ruby 2.7.2
  against `.ruby-version` 3.4.9) and draft PR #252 adds GitHub Actions. A green local run is currently the only
  gate, so run the spec suite and RuboCop yourself.
- `APP_ENV` is inferred from the working directory path (`/production/` or `/staging/` in `Dir.pwd`), defaulting to
  development; specs force `test`.
- `export-comments.rb` / `import-comments.rb` `require "mysql"`, which isn't in the Gemfile (`mysql2` is), and
  refuse to run without the `BE-DANGEROUS` env var - treat them as broken until fixed.
- `wikipedia.rb` is an empty file; nothing references it any more.
- **Data-file traps** (full detail in `docs/data-updates.md`): members CSVs use `d.m.yyyy` dates but ministers CSVs
  use `dd/mm/yyyy`, always with 4-digit years; a new party abbreviation needs a mapping added to
  `lib/people_csv_reader.rb`; honorifics in ministers files must be `The Hon` (never bare `Hon`) with post-nominals
  whitelisted in `lib/name.rb`; after elections the merge order is people.csv, then representatives/senators.csv,
  then ministers/shadow-ministers.csv. Check any data edit with `bundle exec ./parse-members.rb --no-load`.
- Scripts that load the database write to production-shaped tables; anything run with a real `configuration.yml`
  pointed at production paths is a live action needing an explicit go-ahead.

## Contributing

This repository has no `CONTRIBUTING.md` or templates of its own; the org-wide ones in
[`openaustralia/.github`](https://github.com/openaustralia/.github) apply. Fetch the current versions rather than
relying on a copy:

`curl -fsSL https://raw.githubusercontent.com/openaustralia/.github/main/.github/CONTRIBUTING.md`

`curl -fsSL https://raw.githubusercontent.com/openaustralia/.github/main/AGENTS.md`

Any equivalent fetch of those URLs works (web fetch, or `gh api` if the GitHub CLI
is installed); don't assume a particular tool is present.

After merging a change here, the umbrella repository's submodule pointer needs bumping before production picks it
up.

## Agent skills

Configuration the engineering skills read. These files describe how this repo works; edit them directly rather
than re-running the setup skill.

### Issue tracker

Issues live as GitHub issues in the umbrella repo, `openaustralia/openaustralia` — issues are disabled on this
repo. Driven by the `gh` CLI with `-R openaustralia/openaustralia`. See `docs/agents/issue-tracker.md`.

### Triage labels

The default five-label vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and one `docs/adr/` at the root, both created lazily. See `docs/agents/domain.md`.
