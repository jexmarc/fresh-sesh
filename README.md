# fresh-sesh

A Claude Code plugin for checkpointing and resuming sessions before the context window gets girthy.

Four pieces, one install:

- **`/fresh-sesh`** — summarizes the current session (current task, open todos, files in play, open questions, recent context) and writes it to a handoff file in the project's CC folder.
- **`/next`** — reads the handoff after a `/clear` and picks up where the previous session left off.
- **Stop hook** — watches context usage every turn; when total input+cache tokens cross ~180k on a 1M-context model (opus 4.6 `[1m]`, opus 4.7 `[1m]`), prints a warning suggesting `/fresh-sesh` or `/clear`.
- **SessionStart hook** — on fresh launch or after `/clear`, checks for a handoff file in the current project's CC folder and prints a reminder to run `/next` if one was saved within the last 12 hours.

## Why

Claude Code sessions on 1M-context Opus models stay sharp until roughly 200k tokens, then start to drift. This plugin makes it cheap to snapshot state and continue in a fresh session without losing the thread.

## Install

### Requirements

- `jq` on `$PATH` (used by the Stop hook). macOS: `brew install jq`. Linux: `apt install jq` / `dnf install jq`.
- Claude Code with plugin support enabled.

### Option A — Slash commands (recommended)

Inside any Claude Code session, run:

```
/plugin marketplace add jexmarc/fresh-sesh
/plugin install fresh-sesh@jexmarc
```

The first command registers the marketplace hosted in this repo; the second installs and enables the `fresh-sesh` plugin from it. Skills (`/fresh-sesh`, `/next`) and the Stop hook register automatically — no `/hooks` dance required.

If the Stop hook doesn't fire on the next turn, fully quit and relaunch Claude Code once so the hook registry picks up the new plugin.

### Option B — Declarative (settings.json)

Add this to `~/.claude/settings.json` for an auto-enabled install across every session:

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

Start (or restart) Claude Code — the marketplace is fetched, the plugin is enabled, and the Stop hook is registered on launch.

### Verify the install

```
/plugin list
```

You should see `fresh-sesh@jexmarc` listed as enabled. In a session, typing `/fr` should tab-complete `/fresh-sesh`, and the Stop hook will start silently watching context usage every turn.

### Private repo note

Claude Code clones the marketplace repo using your local `gh` / SSH credentials. If the repo is private, make sure `gh auth status` is green (or your SSH key for `github.com` is loaded) on each machine you install from.

## Usage

When your context gets large, the Stop hook will print:

> ⚠️  Context is getting girthy: 172k tokens used (~17% of 1M window). Consider running /fresh-sesh OR /clear to start fresh and keep responses sharp.

Then:

1. Run `/fresh-sesh` — saves the handoff to `~/.claude/projects/<sanitized-cwd>/session-context.md`.
2. Run `/clear` — drops the current context.
3. Run `/next` — Claude reads the handoff and resumes.

If no handoff exists for the current project, `/next` tells you and stops.

## Configuration

Set a custom context-girth threshold (default 180k) via env var in your `~/.claude/settings.json`:

```json
{
  "env": {
    "FRESH_SESH_THRESHOLD": "200000"
  }
}
```

Set a custom handoff-reminder age window (default 12 hours) the same way — the SessionStart reminder is silent once the handoff is older than this:

```json
{
  "env": {
    "FRESH_SESH_HANDOFF_MAX_AGE_HOURS": "24"
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
  hooks.json                       # registers Stop + SessionStart hooks
  stop-hook-context-check.sh       # context-girth warning
  session-start-resume-check.sh    # handoff reminder on startup/clear
```

## License

MIT.
