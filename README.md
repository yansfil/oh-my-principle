# oh-my-principle

Engineering principles applied across projects, written to be read by coding agents.

## Contents

- **[ROOT.md](ROOT.md)** - governs the system itself: the layers, the entry bar, the domain table, precedence. Start here.
- **[engineering/](engineering/)** - the engineering domain: [principles.md](engineering/principles.md) plus [practices/](engineering/practices/) (env, test).
- **[design/](design/)** - the design domain for screens where a user performs work: [principles.md](design/principles.md).
- **[INSTALL.md](INSTALL.md)** - wiring the principles into an agent so they arrive on their own.
- **[skills/](skills/)** - the `principle` skill: adds a principle and reviews the set in one flow.
- **[hooks/](hooks/)** - the injection script the install uses. It reads ROOT.md's domain table and each domain's rule titles.

## The split

The layer definitions (principle / practice / reference), the entry bar, and the precedence rules
live in [ROOT.md](ROOT.md), which governs the system itself. In one line: a principle is a call an
agent gets wrong by default, and nothing enters a principles document unless the agent would do the
opposite without it.
