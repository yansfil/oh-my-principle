# Install

Wires the principles into a coding agent so they arrive on their own, instead of
waiting to be read.

## What it does

`hooks/inject-principles.sh` reads `ROOT.md`'s domain table and each domain's `principles.md`, and emits the rule titles as hook
output. Two events run it.

| Event | Why |
| --- | --- |
| Session start | The rules are present from the first prompt. Re-runs after a context compaction, so a long session never loses them. |
| Subagent start | A subagent does not inherit the parent thread's context. Without this, the agent that actually writes the code runs without the rules. |

Only the rule sentences and the practice index are injected, roughly 350 tokens.
The examples and the violation signals stay in the files and are read on demand.

The script re-reads `ROOT.md` and the domain documents on every run, so adding a domain or a principle changes
what gets injected with no further edits.

## Requirements

`bash` and `jq`. The script reads no stdin, so it cannot stall an agent spawn.

## Setup

Clone the repository somewhere stable and note the absolute path.

```bash
git clone https://github.com/yansfil/oh-my-principle.git ~/projects/oh-my-principle
cd ~/projects/oh-my-principle && chmod +x hooks/inject-principles.sh
```

Confirm it produces the injection before wiring anything up.

```bash
./hooks/inject-principles.sh SessionStart | jq -r '.hookSpecificOutput.additionalContext'
```

### Claude Code

Merge into `~/.claude/settings.json`. Keep any hooks already there; add these
entries to the arrays rather than replacing the `hooks` object.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/oh-my-principle/hooks/inject-principles.sh SessionStart",
            "timeout": 5,
            "statusMessage": "Loading engineering principles..."
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/oh-my-principle/hooks/inject-principles.sh SubagentStart",
            "timeout": 5,
            "statusMessage": "Loading engineering principles..."
          }
        ]
      }
    ]
  }
}
```

`SubagentStart` takes a `matcher` on the agent type. It is left off on purpose, so
every subagent gets the rules. Narrow it only once there is a reason to.

`compact` in the `SessionStart` matcher is what keeps the rules alive in a long
session. Without it, a compaction can summarize them away and nothing puts them back.

### Codex

Merge into `~/.codex/hooks.json`, using the same event names and the same script.
Append to the arrays if the events are already present.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/oh-my-principle/hooks/inject-principles.sh SessionStart",
            "timeout": 5
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/oh-my-principle/hooks/inject-principles.sh SubagentStart",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Codex asks for trust on a hook it has not seen before and records the approval as a
`trusted_hash` under `[hooks.state]` in `~/.codex/config.toml`. Approve it on the next
run, or the hook is registered but never executes. **Editing `inject-principles.sh` changes the
hash and asks again**, so a `git pull` here means the next Codex session prompts for trust and
injects nothing until it is granted.

### Agent instruction file

Hooks cover the runtimes above. For anything else, and to say when the full document
is worth opening, add a pointer to the always-loaded instruction file
(`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `AGENTS.md`, whichever applies).

```markdown
## Engineering Principles

Work follows the principle system at `~/projects/oh-my-principle/ROOT.md`.
Its domain table says which document to read before which kind of work
(engineering, design, and whatever domains exist by then).
Each domain's `practices/` carries the enforcement detail; read the relevant
one before touching that area.
```

Do not paste the rules into that file. A second copy drifts from the first, which
is the failure `engineering/practices/env.md` exists to prevent.

### The `principle` skill

Adding and reviewing principles is itself a flow this repository ships. Link it in so it is
invocable as `/principle`; it reads `ROOT.md` at run time, so it never carries a copy of the contract.

```bash
ln -sfn ~/projects/oh-my-principle/skills/principle ~/.claude/skills/principle
ln -sfn ~/projects/oh-my-principle/skills/principle ~/.codex/skills/principle
```

Link the **directory**, not the `SKILL.md` inside it. Codex omits a symlinked `SKILL.md` from the
list the model sees, but a symlinked skill directory containing a real `SKILL.md` is listed
normally - verified with `codex debug prompt-input`. Linking the directory keeps one copy of the
skill; copying it into each runtime is the drift `engineering/practices/env.md` exists to prevent.

## Verify

Start a new session and ask the agent what principles are in force. It should list every
domain's rules without opening a file.

For the subagent path, have it dispatch a subagent and ask the same question there.

If nothing arrives, run the script by hand. Every departure from `ROOT.md`'s `## The contract` -
a missing document, an empty table cell, no table at all - reports itself through `systemMessage`
rather than failing quietly, so check the session for that message first.

## Uninstall

Remove the entries from `~/.claude/settings.json` and `~/.codex/hooks.json`, and the
`~/.claude/skills/principle` link if it was created.
Nothing else is written outside the repository, and Codex's recorded trust hashes become
inert once the entries are gone.
