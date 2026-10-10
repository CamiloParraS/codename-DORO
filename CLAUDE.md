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

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `<type>[optional scope]: <description>`, then an optional body and optional footer(s). Common types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`. Planning changes (map, tickets, research) are `docs(ghost-layer)`. Throwaway prototypes use `feat(prototype)` on their `prototype/<name>` branch.

Branches are `<type>/<kebab-name>` named after the work, never the ticket: `feat/guard-alert-chain`, not `feat/05-guard-alert-chain` or `fix/issue-12`. Ticket numbers stay out of branch names and commit headers.

`.githooks/commit-msg` enforces both rules. Enable it once per clone with `git config core.hooksPath .githooks`.
