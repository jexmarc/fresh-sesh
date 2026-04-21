---
name: fresh-sesh
description: Summarize the current session context into a handoff file so you can /clear and resume with /next. Use when the user wants to checkpoint the current session before clearing context, or when the context window is getting large.
---

# Fresh Session Handoff (/fresh-sesh)

Summarize the current session into a markdown handoff file. Replaces any existing handoff for this project. After saving, the user runs `/clear` and then `/next` in this same directory to resume.

## Instructions

When this skill is invoked:

### 1. Compute the output path

The handoff file goes in this project's CC session folder:

```bash
PROJECT_DIR="$HOME/.claude/projects/$(pwd | tr '/' '-')"
OUT="$PROJECT_DIR/session-context.md"
```

If `$PROJECT_DIR` doesn't exist, create it with `mkdir -p`.

### 2. Build the summary

Summarize the current session with these sections, **in this order**, weighting the most recent exchanges most heavily (recent > middle > early):

1. **Current Task** — What the user is actively working on right now. One paragraph.
2. **Open Todos / Pending Work** — Bulleted list of unfinished items. Pull from any active todo list in this session plus anything the user explicitly said still needs doing.
3. **Files in Play** — Absolute paths of files modified, created, or actively being edited in this session. One bullet per file with a short note on what changed or why it matters.
4. **Open Questions / Unresolved Issues** — Anything the user and Claude haven't resolved yet: pending decisions, bugs being investigated, ambiguous requirements, blocking errors.
5. **Recent Context** — A tight recap of the last several exchanges with emphasis on decisions made, approaches chosen, and things Claude learned about the user's intent. Weight toward the last 5–10 turns.

**Summary, not compaction.** Don't try to preserve every tool call, file read, or intermediate step. Preserve *intent and state* — enough that a fresh Claude can read this file and continue without asking the user to re-explain.

**No hashtags, no emoji headers.** Plain markdown. Use `##` for section headers.

### 3. Write the file

The file must start with this header so a human reading it knows what it is and how to resume:

```markdown
# Session Context Handoff

_Saved by `/fresh-sesh` on {ISO-8601 timestamp}._
_CWD: {absolute path}_

**To resume this session**, run `/clear` and then `/next` in this same directory. Claude will read this file and pick up where the previous session left off.

---
```

Follow the header with the five numbered sections above. Replace any existing file content entirely — do not append.

Use the Write tool (not Edit) since we're fully replacing.

### 4. Confirm to the user

After writing, tell the user in one short line:

```
Session summary saved to <path>. Run /clear and then /next to continue fresh.
```

## Important

- Overwrite silently — the user knows what they're asking for.
- Don't ask clarifying questions; just summarize what you have.
- If the session is extremely short (e.g., under ~5 turns), still write the file but keep it terse.
- Never include secrets, `.env` contents, or credentials in the summary.
