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
├── ai/              Aigis (campaign module), Glaukopis, mission_tally. Pure logic, no nodes where possible, so it's testable. Also finale.gd (the ending) and voice_lines.gd (line keys)
├── areas/           one folder per Area: <area>/<area>.tscn + its pieces
├── missions/        campaign.gd (every Mission as data: Area, objective steps, Targets, by index), mission_run.gd, deployment.gd, save_slots.gd (campaign slots), tutorial.gd
├── text/            lines.csv (keys,en,es): every spoken/shown line; imports to .translation (git-ignored, `godot --headless --import`)
├── ui/              hud/, radio/, pause/, briefing/, post_mission/, psx_look/, radar/, codec/, main_menu/, settings/, finale/, free_mode/, debug_overlay/ (autoload)
├── tests/           test suites (godot_ai expects res://tests/)
└── tools/           area builders and bake scripts; run_tests.tscn runs every suite headless: `godot --headless --path . tools/run_tests.tscn`
```

Create folders when they're needed, not before (git doesn't track empty folders anyway).
