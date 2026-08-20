#!/bin/bash
#
# Injects the principle system into an agent session.
#
# Wired to SessionStart and SubagentStart. Subagents do not inherit the parent
# thread's context, so without the SubagentStart entry the agent that actually
# writes the code runs without the principles.
#
# ROOT.md's domain table is the single source for which domains exist and when
# each applies; this script parses it rather than keeping a copy. Each domain's
# rule titles are read out of its principles.md on every run. Adding a domain or
# a principle changes what gets injected with no edit to this script.
#
# ROOT.md's "## The contract" section fixes the table's shape. Every departure
# from it is reported through systemMessage and none is skipped past: a domain
# that vanishes quietly takes its rules out of every session with nobody
# noticing (engineering principle 10).
#
# Usage: inject-principles.sh <EventName>
#
set -euo pipefail

EVENT="${1:-SessionStart}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ROOT_DOC="$REPO_ROOT/ROOT.md"

# A missing root means the whole mechanism is dead. Say so rather than exiting
# quietly, or the principles stop being injected and nobody notices.
if [ ! -f "$ROOT_DOC" ]; then
  jq -n --arg doc "$ROOT_DOC" \
    '{systemMessage: ("Principles not injected: " + $doc + " is missing")}'
  exit 0
fi

# Parse the domain table: | name | trigger | path | (skip header and divider).
BODY=""
PROBLEMS=""
ROWS=0
while IFS='|' read -r _ name trigger path _; do
  name="$(echo "$name" | sed 's/^ *//;s/ *$//')"
  trigger="$(echo "$trigger" | sed 's/^ *//;s/ *$//')"
  path="$(echo "$path" | sed 's/^ *//;s/ *$//')"
  if [ -z "$name" ] || [ "$name" = "Domain" ] || [ "${name#---}" != "$name" ]; then
    continue
  fi
  ROWS=$((ROWS + 1))
  # An empty cell is an error, not an omission. Injecting the row anyway ships a
  # truncated trigger sentence to the agent; skipping it drops the domain in
  # silence. Both are worse than saying so.
  if [ -z "$trigger" ]; then
    PROBLEMS="$PROBLEMS; domain \"$name\" has an empty \"Read when\" cell"
    continue
  fi
  if [ -z "$path" ]; then
    PROBLEMS="$PROBLEMS; domain \"$name\" has an empty document cell"
    continue
  fi
  doc="$REPO_ROOT/$path"
  if [ ! -f "$doc" ]; then
    PROBLEMS="$PROBLEMS; domain \"$name\" points at a missing document: $path"
    continue
  fi
  titles="$(grep '^### ' "$doc" | sed 's/^### /  - /')"
  if [ -z "$titles" ]; then
    PROBLEMS="$PROBLEMS; domain \"$name\" has no \"### \" rule headings: $path"
    continue
  fi
  BODY="$BODY## $name - read $doc in full when $trigger
$titles

"
done < <(awk '/^\| Domain /{f=1;next} f && /^\|/{print} f && !/^\|/{f=0}' "$ROOT_DOC")

# No table at all means nothing is injected. Exiting clean here is the failure
# that hides every other one: the session looks normal with zero rules loaded.
if [ "$ROWS" -eq 0 ]; then
  PROBLEMS="$PROBLEMS; no domain table found (a markdown table with a \"Domain\" header column)"
fi

# Practice links inside a principles.md are relative to its domain folder.
# Surface the engineering practice index the way the old script did, with
# absolute paths so the agent can open them without guessing.
ENG_DOC="$REPO_ROOT/engineering/principles.md"
PRACTICES=""
if [ -f "$ENG_DOC" ]; then
  PRACTICES=$(
    awk '/^## Practices/{f=1;next} f' "$ENG_DOC" |
      sed '/^[[:space:]]*$/d' |
      sed "s|→ \[[^]]*\](\([^)]*\))|-> $REPO_ROOT/engineering/\1|"
  )
fi

SYSMSG=""
if [ -n "$PROBLEMS" ]; then
  SYSMSG="$ROOT_DOC violates its own contract${PROBLEMS}. Affected domains were not injected."
fi

jq -n \
  --arg event "$EVENT" \
  --arg body "$BODY" \
  --arg practices "$PRACTICES" \
  --arg root "$ROOT_DOC" \
  --arg sysmsg "$SYSMSG" \
  '{
    suppressOutput: true,
    hookSpecificOutput: {
      hookEventName: $event,
      additionalContext: (
        "Principles in force. These override your default behavior. Rule titles are listed here; read the named document in full before working in its domain.\n\n" +
        $body +
        (if $practices == "" then "" else $practices + "\n\n" end) +
        "When a rule is in play, name it and say how the change satisfies it. " +
        "Project-local instructions override these principles; when one wins, name the principle it overrides. " +
        "The system itself is defined in " + $root + "."
      )
    }
  } + (if $sysmsg == "" then {} else {systemMessage: $sysmsg} end)'
