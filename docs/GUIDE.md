# Ghost Layer — Working Guide

Personal reference: how this project is planned and built, where things live, and what to do next.

## Where things live

| What | Where |
|---|---|
| Planning map (destination, decisions, fog) | `.scratch/ghost-layer/map.md` |
| Decision tickets | `.scratch/ghost-layer/issues/NN-*.md` |
| Research reports | `.scratch/ghost-layer/research/*.md` |
| Project vocabulary | `GLOSSARY.md` |
| Hard-to-reverse decisions | `docs/adr/` (created when the first one comes up) |
| Agent instructions | `CLAUDE.md`, `docs/agents/` |
| Raw downloads (not imported, not committed) | `_raw/` |

> Godot's FileSystem panel hides folders that start with a dot (`.scratch`) and folders with a `.gdignore` (`_raw`). Open them from Explorer or VS Code.

## The flow

```
/wayfinder (decision tickets)  ← YOU ARE HERE
   └─ prototypes and grillings, one ticket per session
/to-spec      the map collapses into a buildable spec
/to-tickets   the spec splits into build tickets
/implement    one ticket per session (/clear between each)
   └─ /tdd + /code-review inside
/retro        after the build, improve the environment
```

## How to work a ticket

1. `/clear` (a new session for each ticket).
2. `/wayfinder .scratch/ghost-layer/map.md <ticket>`. Leave out the ticket to take the next one on the frontier.
3. Wayfinder calls `/prototype` or the grilling itself. Prototypes are tickets too: **always enter through `/wayfinder`** so the decision gets recorded in the map.
4. At the end the ticket is `Status: resolved` and the map has its pointer.

**Parallel:** yes, if they don't touch the same thing. A prototype (Godot) + a grilling (conversation only) = OK. Two prototypes at once = NO (same editor and project through the MCP).

**Prototypes** live on their own `prototype/<name>` branch. They're throwaway code: the answer gets carried into the real code, not the prototype itself.

## Next steps (as of 2026-10-09)

Done: **Core stealth feel prototype** (`04`), with the prototype on branch `prototype/stealth-core`.

Frontier:
1. **Spoofing prototype** (`05`): unblocked by 04.
2. **PSX look and HUD prototype** (`06`): don't run it alongside 05 (both are prototypes).
3. **Combat verbs and Lethality** (`07`): short, a grilling, so it can run alongside either. It unblocks the profile ticket.

Then: profile (`08`) → five Voices (`09`) and campaign (`10`) → narrative (`11`). When there are no tickets left and the fog is cleared: `/to-spec`.

**Planning budget:** about 4 days. Anything not decided by then gets a default in the spec.

## Assets: the flow of a download

1. Download into `_raw/<source>/` (the zip, the FBX, whatever arrives).
2. Copy **only what you'll use** into `assets/...` (see structure). Godot imports it from there.
3. Add a line to `CREDITS.md` right away: name, author, link, license.

`_raw/` is ignored by both Godot and git. That keeps the import fast and keeps Mixamo/Quaternius raw files out of the repo (their licenses forbid redistributing them).

## Project structure (`res://`)

Organized **by game feature**, with each scene next to its script, as Godot recommends. snake_case for files and folders.

```
res://
├── addons/          plugins (always committed)
├── assets/          third-party and own art, by type
│   ├── characters/<pack>/
│   ├── props/<pack>/
│   ├── textures/
│   ├── fonts/
│   ├── audio/       sfx/, music/
│   └── shaders/     PSX shaders
├── actors/          operative/, guard/, security_camera/   (scene + script together)
├── ai/              Aigis: profile, Voices, Glaukopis. Pure logic, no nodes where possible, so it's testable
├── areas/           one folder per Area: <area>/<area>.tscn + its pieces
├── missions/        a Mission = resource (.tres) pointing at an Area + objectives
├── ui/              hud/, codec/, menus/, free_mode/, debug_overlay/ (autoload)
└── tests/           test suites (godot_ai expects res://tests/)
```

Create folders when they're needed, not before (git doesn't track empty folders anyway).
