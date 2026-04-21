#!/usr/bin/env bash
# Resume-from-handoff Reminder
#
# Runs at SessionStart. If a fresh-sesh handoff exists for this project and is
# younger than FRESH_SESH_HANDOFF_MAX_AGE_HOURS (default 12), emits a system
# message reminding the user they can run /next to resume.
#
# Fires on source=startup and source=clear only; silent on resume and compact.
# Silent also when no handoff exists or the existing handoff is stale.
#
# Requires: jq

set -eo pipefail

MAX_AGE_HOURS="${FRESH_SESH_HANDOFF_MAX_AGE_HOURS:-12}"

input="$(cat)"
[ -z "$input" ] && exit 0

source="$(printf '%s' "$input" | jq -r '.source // empty')"
case "$source" in
  startup|clear) ;;
  *) exit 0 ;;
esac

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[ -z "$cwd" ] && cwd="$(pwd)"

sanitized="$(printf '%s' "$cwd" | tr '/' '-')"
handoff="$HOME/.claude/projects/${sanitized}/session-context.md"
[ -f "$handoff" ] || exit 0

# Cross-platform mtime (macOS stat -f vs GNU stat -c)
if ! mtime="$(stat -f %m "$handoff" 2>/dev/null)"; then
  mtime="$(stat -c %Y "$handoff" 2>/dev/null || echo 0)"
fi
[ "$mtime" -gt 0 ] || exit 0

now="$(date +%s)"
age=$((now - mtime))
max_age=$((MAX_AGE_HOURS * 3600))
[ "$age" -le "$max_age" ] || exit 0

if [ "$age" -lt 3600 ]; then
  age_label="$((age / 60))m"
elif [ "$age" -lt 86400 ]; then
  age_label="$((age / 3600))h"
else
  age_label="$((age / 86400))d"
fi

jq -n \
  --arg msg "📂 Fresh-sesh handoff found for this project (saved ${age_label} ago). Run /next to resume, or ignore to start fresh." \
  '{systemMessage: $msg}'
