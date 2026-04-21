#!/usr/bin/env bash
# Context Window Check
#
# Warns when the current session's context usage crosses THRESHOLD tokens
# on a 1M-context model. A standard 200k-context model can't exceed its own
# limit, so any hit here implies a 1M variant (opus 4.6[1m], opus 4.7[1m]).
#
# Reads the transcript path from the Stop hook's stdin JSON, sums the last
# assistant message's usage (input + cache_read + cache_creation), and emits
# a systemMessage JSON object if over threshold. Otherwise exits silently.
#
# Requires: jq

set -eo pipefail

THRESHOLD="${FRESH_SESH_THRESHOLD:-150000}"

input="$(cat)"
[ -z "$input" ] && exit 0

transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
[ -z "$transcript" ] && exit 0
[ ! -f "$transcript" ] && exit 0

total="$(jq -s '
  map(select(.type == "assistant" and (.message.usage // null) != null))
  | if length == 0 then 0
    else (last | .message.usage
           | (.input_tokens // 0)
           + (.cache_read_input_tokens // 0)
           + (.cache_creation_input_tokens // 0))
    end
' "$transcript" 2>/dev/null || echo 0)"

[ "$total" -gt "$THRESHOLD" ] || exit 0

k=$((total / 1000))
pct=$((total * 100 / 1000000))

jq -n \
  --arg msg "⚠️  Context is getting girthy: ${k}k tokens used (~${pct}% of 1M window). Consider running /fresh-sesh OR /clear to start fresh and keep responses sharp." \
  '{systemMessage: $msg}'
