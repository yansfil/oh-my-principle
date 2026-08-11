# oh-my-principle

Engineering principles applied across projects, written to be read by coding agents.

## Contents

- **[engineering.md](engineering.md)** - the principles. Short, absolute, meant to sit in context at all times.
- **[practices/](practices/)** - areas where a principle has concrete enforcement. Read on demand.
  - [env.md](practices/env.md) - environment variables
  - [test.md](practices/test.md) - testing

## The split

A **principle** is a call an agent gets wrong by default. It is stated as a rule with no rationale
attached, because a rationale is something to negotiate against, and a violation of it is visible.

A **practice** is a principle that has grown a mechanism - a registry, a contract test, a boot check.
It carries its reasoning, because moving it to another stack means rebuilding the mechanism, and you
cannot rebuild what you do not understand the purpose of.

Nothing goes in the root document unless an agent would do the opposite without it.
