---
name: principle
description: >
  Add a principle to the oh-my-principle repository, and review the set while doing it.
  Use when the user invokes "/principle", says "이거 원칙으로 추가해줘", "원칙에 넣어줘",
  "add this as a principle", "이 원칙 중복 아니야?", "원칙 정리해줘", or hands over an
  incident they want turned into a rule. Adding and reviewing are one flow: the same pass
  that judges a candidate also reports the duplicates, conflicts, and dead rules it met on
  the way. Not for project-local rules or lessons - that is the `remember` skill.
---

# principle

The repository is at `~/projects/oh-my-principle`. Read `ROOT.md` first, every time.
It defines the layers, the entry bar, the precedence order, and `## The contract` - the
machine-readable shape two consumers parse. Do not restate any of it here; read it.

The user brings the candidate. You judge it, place it, and report what the judging turned up.

## Why adding and reviewing are one flow

To know whether a candidate is new, you have to read the whole domain anyway. The duplicates,
the conflicting pairs, and the rules nothing has ever violated are all visible from inside
that read. A separate cleanup pass would redo the same work later, and later never comes.

## The default is not "add"

Four outcomes. Ordered by how often each is correct:

| Outcome | When |
| --- | --- |
| **Amend an existing rule** | the candidate sharpens, bounds, or extends a rule already there |
| **Reject** | it fails the entry bar in `ROOT.md` |
| **Demote** | it is real but belongs in `practices/` (it has a mechanism) or `references/` (it is an asset to imitate, not a rule) |
| **Add a new rule** | none of the above fits |

A run that ends in "amend" or "reject" is a successful run. Say which outcome you chose and
why the other three did not fit - all three, briefly. Skipping that comparison is how the
count grows.

## Procedure

### 1. Load

Read `ROOT.md`, then the target domain's `principles.md` **in full**, then the titles of that
domain's `practices/`. If the domain is not obvious from the candidate, ask - do not guess,
and do not invent a domain. A new domain is a separate decision the user makes explicitly.

### 2. Apply the entry bar

`ROOT.md` states it; these are the questions that operationalize it. All three must pass.

- **Would an agent do the opposite without this?** If a competent agent already does it by
  default, it is taste. Reject or demote to `references/`.
- **Is a violation visible?** Name where - a diff, a file tree, a log line, a screen. A rule
  whose breach cannot be pointed at cannot be enforced, only invoked.
- **Is it not a restatement?** Quote the closest existing rule and say what this adds. If the
  answer is "it says it more clearly", that is an amend, not an add.

Ask the user for what you are missing. A candidate with no concrete incident behind it usually
fails the second question, and the incident is the fastest way to find out.

### 3. Write it to the contract

Only for **amend** and **add**.

The rule is the `### ` heading and nothing else - consumers take the heading text alone.
Write it as an absolute imperative, no rationale in the heading. Then the body: at most a
line or two that bounds the rule, and a `✗`/`✓` pair showing the shape of a violation
concrete enough to recognize in a diff. Match the surrounding document's voice and example
style; do not introduce a new format.

For a **demote**, follow the shape of the existing documents in that folder - `env.md` and
`test.md` are the worked examples. Add its one-line pointer to the domain's `## Practices`.

### 4. Report the review

Same response, not a separate run. From the full read you just did:

- **Duplicate or subsumed pairs** - rule N and rule M, and which one absorbs the other
- **Conflicting pairs** - two rules that pull opposite ways on the same call. A real conflict
  is either resolved in one rule's body or it is unresolved; say which. (Engineering #3 vs #8
  is the worked example of a resolved one.)
- **Dead rules** - no incident has ever invoked them. Flag, do not remove; ask.
- **Contract breaks** - a heading that does not stand alone, a domain missing from the table.

Report the review even when the outcome was "reject". That is the run where you read
everything and changed nothing, so it is the cheapest review you will get.

### 5. Hand over a diff

Show the diff and the review, and stop. **You do not commit.** The user decides.

## Guardrails

- Never edit `ROOT.md` from this skill. That document governs the system, not a domain; a
  candidate that seems to need a ROOT.md change is a signal the system itself is being changed,
  which is a conversation, not an edit.
- Never add a domain. Rule 1 of step 1.
- Never grow a principles document past what a session can carry. Every rule added is injected
  into every session forever; if the domain is nearing that limit, say so and propose a demotion
  before adding.
