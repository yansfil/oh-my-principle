#!/bin/bash
#
# Injects the engineering principles into an agent session.
#
# Wired to SessionStart and SubagentStart. Subagents do not inherit the parent
# thread's context, so without the SubagentStart entry the agent that actually
# writes the code runs without the principles.
#
# The rule list is read out of engineering.md on every run rather than kept as a
# copy here. Adding a principle changes what gets injected with no edit to this
# script and no second file to keep in sync.
#
# Usage: inject-principles.sh <EventName>
#
set -euo pipefail

EVENT="${1:-SessionStart}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DOC="$REPO_ROOT/engineering.md"

# A missing document means the whole mechanism is dead. Say so rather than
# exiting quietly, or the principles stop being injected and nobody notices.
if [ ! -f "$DOC" ]; then
  jq -n --arg doc "$DOC" \
    '{systemMessage: ("Engineering principles not injected: " + $doc + " is missing")}'
  exit 0
fi

RULES=$(grep '^### ' "$DOC" | sed 's/^### //')

# Practice links are relative to the repository. Rewrite them to absolute paths
# so the agent can open them without guessing where the repository lives.
PRACTICES=$(
  awk '/^## Practices/{f=1;next} f' "$DOC" |
    sed '/^[[:space:]]*$/d' |
    sed "s|→ \[[^]]*\](\([^)]*\))|-> $REPO_ROOT/\1|"
)

# Other domain documents in the repository root are indexed with one line each,
# not injected in full. The rule bodies load only when the agent enters that
# domain, which keeps the always-on cost flat as domains are added.
DOMAINS=$(
  for f in "$REPO_ROOT"/*.md; do
    base="$(basename "$f")"
    # bash 3.2 (macOS default) cannot parse `case` inside command substitution
    if [ "$base" = "engineering.md" ] || [ "$base" = "README.md" ] || [ "$base" = "INSTALL.md" ]; then
      continue
    fi
    title="$(grep -m1 '^# ' "$f" | sed 's/^# //')"
    printf -- "- %s apply to their domain with the same force. Read %s before starting work in that domain.\n" "$title" "$f"
  done
)

jq -n \
  --arg event "$EVENT" \
  --arg rules "$RULES" \
  --arg practices "$PRACTICES" \
  --arg domains "$DOMAINS" \
  --arg doc "$DOC" \
  '{
    suppressOutput: true,
    hookSpecificOutput: {
      hookEventName: $event,
      additionalContext: (
        "Engineering principles in force. These override your default behavior.\n\n" +
        $rules + "\n\n" +
        $practices + "\n\n" +
        (if $domains == "" then "" else $domains + "\n\n" end) +
        "Before writing or changing code, check the change against these rules. " +
        "When one is in play, name it and say how the change satisfies it. " +
        "Read " + $doc + " for the examples and the violation signals before " +
        "proposing an architecture or choosing a dependency."
      )
    }
  }'
