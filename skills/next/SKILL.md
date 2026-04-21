---
name: next
description: Resume a session that was checkpointed with /fresh-sesh. Reads session-context.md from the current project's CC folder and continues where the previous session left off. Use when the user types /next after a /clear.
---

# Resume Session (/next)

Pick up where a previous session left off by reading the handoff file that `/fresh-sesh` wrote for this project.

## Instructions

When this skill is invoked:

### 1. Locate the handoff file

```bash
HANDOFF="$HOME/.claude/projects/$(pwd | tr '/' '-')/session-context.md"
```

### 2. Check that it exists

If the file doesn't exist, tell the user:

```
No session handoff found for this project at <path>. Run /fresh-sesh in a prior session first to create one.
```

Then stop.

### 3. Read it and brief the user

Read the file with the Read tool. Then produce a short briefing (3–6 lines) covering:

- What the previous session was working on
- Any open todos still pending
- What the user most likely wants to do next

End with a single line asking where they'd like to continue — for example: "Want me to pick up with X, or something else?"

Do **not** dump the full handoff file back to the user. They already have it. Synthesize.

### 4. Be ready to work

Treat the handoff content as authoritative context for this session — files in play, decisions already made, open questions — but verify any specific function/file references are still accurate before acting on them (files may have changed since the handoff was written).

## Important

- One handoff per project — the file is overwritten each time `/fresh-sesh` runs.
- If the handoff is stale (timestamp much older than the user expects), flag it: "This handoff is from {date} — does it still reflect what you want to pick up on?"
