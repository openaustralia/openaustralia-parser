# Issue tracker: GitHub (umbrella repo)

Issues and specs for this repo live as GitHub issues in the umbrella repository,
[`openaustralia/openaustralia`](https://github.com/openaustralia/openaustralia) — GitHub Issues are **disabled**
on `openaustralia/openaustralia-parser`. Use the `gh` CLI with an explicit `-R openaustralia/openaustralia` for every issue
operation; `gh`'s automatic repo inference from this clone would target the wrong repo.

When an issue is specific to this repo, name it (`openaustralia-parser`) in the title or body so it's findable among the
umbrella repo's cross-cutting issues.

## Conventions

- **Create an issue**: `gh issue create -R openaustralia/openaustralia --title "..." --body "..."`. Use a heredoc
  for multi-line bodies. Follow the org issue templates in
  [`openaustralia/.github`](https://github.com/openaustralia/.github/tree/main/.github/ISSUE_TEMPLATE).
- **Read an issue**: `gh issue view <number> -R openaustralia/openaustralia --comments`, filtering comments by
  `jq` and also fetching labels.
- **List issues**: `gh issue list -R openaustralia/openaustralia --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> -R openaustralia/openaustralia --body "..."`
- **Apply / remove labels**: `gh issue edit <number> -R openaustralia/openaustralia --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> -R openaustralia/openaustralia --comment "..."`

Never bulk-close issues. Present a not-reproducible or stale verdict as evidence and let a human decide, except
for outright duplicates and issues whose context no longer exists.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage`
reads this flag.)_

Pull requests live on **this** repo (`openaustralia/openaustralia-parser`) — only issues are centralised. When the flag is
set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents against this
repo (no `-R` needed inside the clone):

- **Read a PR**: `gh pr view <number> --comments` and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` then keep only `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (drop `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

Dependabot PRs are automated maintenance, not requests; keep them out of any triage queue.

## When a skill says "publish to the issue tracker"

Create a GitHub issue in `openaustralia/openaustralia` (with `-R openaustralia/openaustralia`).

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> -R openaustralia/openaustralia --comments`.

## Opening pull requests

Open PRs on this repo. Use the org pull request template from
[`openaustralia/.github`](https://github.com/openaustralia/.github/blob/main/.github/PULL_REQUEST_TEMPLATE.md),
and assign yourself: `gh pr create --assignee @me`. Note AI involvement and the model in the PR body.

After merging a change here, the umbrella repository's submodule pointer must be bumped before production picks
it up.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets. All wayfinding issue
commands target the umbrella repo — pass `-R openaustralia/openaustralia` (or `repos/openaustralia/openaustralia`
paths for `gh api`) throughout.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `gh issue create -R openaustralia/openaustralia --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies**, the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/openaustralia/openaustralia/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/openaustralia/openaustralia/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only, the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list -R openaustralia/openaustralia --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> -R openaustralia/openaustralia --add-assignee @me`, the session's first write.
- **Resolve**: `gh issue comment <n> -R openaustralia/openaustralia --body "<answer>"`, then `gh issue close <n> -R openaustralia/openaustralia`, then append a context pointer (gist + link) to the map's Decisions-so-far.
