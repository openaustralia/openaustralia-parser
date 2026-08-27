# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`AGENTS.md`** at the repo root. It is the canonical guidance for this repo; `CLAUDE.md` only points at it.
- **`CONTEXT.md`** at the repo root, if it exists.
- **`docs/adr/`**, if it exists. Read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them
upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`)
creates them lazily when terms or decisions actually get resolved.

## Layout: single-context

This repo is **single-context**: one `CONTEXT.md` and one `docs/adr/` at the root.

```
/
├── AGENTS.md
├── CONTEXT.md                         ← created lazily by /domain-modeling
└── docs/
    ├── adr/                           ← created lazily by /domain-modeling
    │   ├── 0001-....md
    │   └── 0002-....md
    └── agents/                        ← this directory
```

This repo is checked out as a submodule of the umbrella repository,
[`openaustralia/openaustralia`](https://github.com/openaustralia/openaustralia), but it is a separate repository
with its own domain docs. They belong here, in this repo — not in the umbrella checkout.

If this repo ever does need per-context docs, the multi-context form is a root `CONTEXT-MAP.md` pointing at one
`CONTEXT.md` per context, with context-scoped ADRs alongside each.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use
the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal. Either you're inventing language the project
doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

Use the exact service names in prose: Planning Alerts, Right to Know, They Vote for You, OpenAustralia.org.au and
morph.io. Never invent variants.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0003 (...), but worth reopening because..._
