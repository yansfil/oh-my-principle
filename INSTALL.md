# Install

Wires the principles into a coding agent so they arrive on their own, instead of
waiting to be read.

## What it does

`hooks/inject-principles.sh` reads `engineering.md` and emits the rule list as hook
output. Two events run it.

| Event | Why |
| --- | --- |
| Session start | The rules are present from the first prompt. Re-runs after a context compaction, so a long session never loses them. |
| Subagent start | A subagent does not inherit the parent thread's context. Without this, the agent that actually writes the code runs without the rules. |

Only the rule sentences and the practice index are injected, roughly 350 tokens.
The examples and the violation signals stay in the files and are read on demand.

The script re-reads `engineering.md` on every run, so adding a principle changes
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
run, or the hook is registered but never executes. Editing the script changes the hash
and asks again.

### Agent instruction file

Hooks cover the runtimes above. For anything else, and to say when the full document
is worth opening, add a pointer to the always-loaded instruction file
(`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `AGENTS.md`, whichever applies).

```markdown
## Engineering Principles

Engineering work follows `~/projects/oh-my-principle/engineering.md`.
Read it before proposing an architecture, adding a dependency, designing an error path,
or writing anything that can run twice.
`practices/env.md` and `practices/test.md` carry the enforcement detail; read the relevant
one before touching environment variables or tests.
```

Do not paste the eleven rules into that file. A second copy drifts from the first, which
is the failure `practices/env.md` exists to prevent.

## Verify

Start a new session and ask the agent what engineering principles are in force. It should
list the eleven without opening a file.

For the subagent path, have it dispatch a subagent and ask the same question there.

If nothing arrives, run the script by hand. A missing `engineering.md` reports itself
through `systemMessage` rather than failing quietly, so check the session for that
message first.

## Uninstall

Remove the entries from `~/.claude/settings.json` and `~/.codex/hooks.json`.
Nothing else is written outside the repository, and Codex's recorded trust hashes become
inert once the entries are gone.
