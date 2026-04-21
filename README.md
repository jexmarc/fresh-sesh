# fresh-sesh

A Claude Code plugin for checkpointing and resuming sessions before the context window gets girthy.

Three pieces, one install:

- **`/fresh-sesh`** — summarizes the current session (current task, open todos, files in play, open questions, recent context) and writes it to a handoff file in the project's CC folder.
- **`/next`** — reads the handoff after a `/clear` and picks up where the previous session left off.
- **Stop hook** — watches context usage every turn; when total input+cache tokens cross ~150k on a 1M-context model (opus 4.6 `[1m]`, opus 4.7 `[1m]`), prints a warning suggesting `/fresh-sesh` or `/clear`.

## Why

Claude Code sessions on 1M-context Opus models stay sharp until roughly 200k tokens, then start to drift. This plugin makes it cheap to snapshot state and continue in a fresh session without losing the thread.

## Install

Add this to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "jexmarc": {
      "source": {
        "source": "github",
        "repo": "jexmarc/fresh-sesh"
      }
    }
  },
  "enabledPlugins": {
    "fresh-sesh@jexmarc": true
  }
}
```

Restart Claude Code (or open `/hooks` once) so the Stop hook registers.

**Private repo?** Claude Code uses your `gh` / SSH auth to clone. Make sure `gh auth status` is green on each machine.

## Requirements

- `jq` on `$PATH` (used by the Stop hook). macOS: `brew install jq`. Linux: `apt install jq` / `dnf install jq`.

## Usage

When your context gets large, the Stop hook will print:

> ⚠️  Context is getting girthy: 172k tokens used (~17% of 1M window). Consider running /fresh-sesh OR /clear to start fresh and keep responses sharp.

Then:

1. Run `/fresh-sesh` — saves the handoff to `~/.claude/projects/<sanitized-cwd>/session-context.md`.
2. Run `/clear` — drops the current context.
3. Run `/next` — Claude reads the handoff and resumes.

If no handoff exists for the current project, `/next` tells you and stops.

## Configuration

Set a custom threshold (default 150k) via env var in your `~/.claude/settings.json`:

```json
{
  "env": {
    "FRESH_SESH_THRESHOLD": "200000"
  }
}
```

## What gets saved in the handoff

Five sections, in fixed order, recency-weighted:

1. **Current Task** — what you were actively working on.
2. **Open Todos / Pending Work** — unfinished items.
3. **Files in Play** — absolute paths of files touched, with a short why.
4. **Open Questions / Unresolved Issues** — pending decisions, bugs in flight, ambiguous requirements.
5. **Recent Context** — tight recap of the last several turns, emphasizing decisions made.

No secrets, no `.env` contents. Plain markdown. Overwrites any previous handoff for the same project.

## Layout

```
.claude-plugin/
  plugin.json            # plugin manifest
  marketplace.json       # marketplace manifest (self-hosted)
skills/
  fresh-sesh/SKILL.md    # /fresh-sesh
  next/SKILL.md          # /next
hooks/
  hooks.json             # registers the Stop hook
  stop-hook-context-check.sh
```

## License

MIT.
