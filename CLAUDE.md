## Agent skills

### Issue tracker

Issues and specs are local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Project layout

Godot 4.7 project. Organize `res://` by game feature, with each scene next to its script, in snake_case: `actors/`, `ai/` (Aigis logic, kept node-free where possible so it's testable), `areas/`, `missions/`, `ui/`, `assets/<type>/`, `tests/` (godot_ai test suites). Create folders only when they're needed. The full layout is in `docs/GUIDE.md`.

- Raw downloads go in `_raw/` (ignored by both git and Godot). Copy only the files you use into `assets/`.
- Every third-party asset gets a line in `CREDITS.md`: name, author, link, license.
- Planning map: `.scratch/ghost-layer/map.md`.
