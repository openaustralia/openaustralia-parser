# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings
used in this repo's issue tracker — the umbrella repo, `openaustralia/openaustralia` (see
`docs/agents/issue-tracker.md`). That tracker keeps the default vocabulary, so both columns match.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (for example "apply the AFK-ready triage label"), use the corresponding label string
from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

All five labels exist on `openaustralia/openaustralia`. Two were renamed from earlier labels rather than created,
so older issues and comments may still refer to them by the old name: `needs-info` was `needs-reproduction`, and
`ready-for-human` was `ready`.

## Other labels on the tracker

The umbrella repo also carries labels outside the five canonical roles — type and area labels such as `bug`,
`task`, `New feature`, `improvement`, `parser`, `web app`, `votes`, `API`, plus `needs-dev-env` and `stale`. The
skills don't read them; leave them alone unless you are deliberately triaging with them.
