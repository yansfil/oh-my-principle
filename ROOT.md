# Root

This document governs the principle system itself.
It contains no domain rules; it defines what a rule is, where it lives, when each domain applies, and what wins on conflict.

## The layers

- A **principle** is a call an agent gets wrong by default.
  It is stated as an absolute rule with no rationale attached, because a rationale is something to negotiate against, and a violation of it is visible.
  Principles live in `<domain>/principles.md`.
- A **practice** is a principle that has grown a mechanism - a registry, a contract test, a boot check.
  It carries its reasoning, because moving it to another stack means rebuilding the mechanism, and you cannot rebuild what you do not understand the purpose of.
  Practices live in `<domain>/practices/`.
- A **reference** is not a rule: it is an asset to imitate - an exemplary screen, a palette, a prompt recipe.
  References live in `<domain>/references/` and are read on demand, never injected.

## The entry bar

Nothing enters a `principles.md` unless an agent would do the opposite without it.
Taste, preference, and anything a reasonable agent already does by default stay out - or go to `references/`.

## Domains

Read a domain's `principles.md` in full before starting work in that domain.
The trigger below is the definition of "that domain".

| Domain | Read when | Document |
| --- | --- | --- |
| engineering | writing or changing code, proposing an architecture, choosing a dependency, designing an error path | engineering/principles.md |
| design | building or changing any screen where a user performs work - admin tools, dashboards, forms, settings, on any platform | design/principles.md |

## The contract

The domain table above is not decoration; it is the machine-readable interface of this repository.
Two consumers parse it independently - `hooks/inject-principles.sh` here, and `sasu`'s
`cli/src/principles/commands.ts` - so its shape is fixed and this section is where it is fixed.

- A domain is a table row of exactly three cells: name, the trigger sentence, and the document path
  relative to this file. A domain that is not a row does not exist, however complete its folder is.
- A domain's rules are the `### ` headings of its `principles.md`, in order.
  **A consumer takes the heading text and nothing else**, so a heading that needs its body to make
  sense arrives at the agent broken. The heading is the whole rule.
- An empty cell, a row with fewer than three cells, a path that resolves to no file, and a missing
  table are all errors. None of them is an omission a consumer may skip past: skipping is how a
  domain disappears from every session with nobody noticing (engineering principle 10).

Changing any of the above means changing every consumer. Add to the table; do not reshape it.

## Precedence

1. Project-local instructions and rules (a repository's CLAUDE.md/AGENTS.md, its rules registry) override these principles.
   When a project rule wins, name the principle it overrides.
2. Within this repository, a domain document never overrides another domain's document; when two domains both apply, both apply.

## Growth

- A new domain is a new folder with a `principles.md`, plus one row in the table above, in the shape `## The contract` fixes.
- A principle that grows a mechanism moves its detail to `practices/` and keeps one line in `principles.md` pointing there.
- This document grows only when the system itself changes - never to hold a domain rule.
