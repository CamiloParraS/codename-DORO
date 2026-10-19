# 34: Sounds

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The game sounds right: radio and codec beeps, footsteps, shots (suppressed and loud), takedowns, knock and Magazine landing, alert sting, UI clicks.

**Blocked by:** 28

**Status:** ready-for-agent

- [ ] CC0 sounds (Kenney/OpenGameArt) imported from `_raw/` with `CREDITS.md` lines
- [x] The master volume setting drives the master bus (`Mixer.set_volume(Mix.MASTER, v)`, tested in test_mix; a settings screen is not part of this ticket)

## Comments

2026-10-19: Hooks wired and tested, CC0 import NOT done (no `_raw/` in the worktree). `Mix.STREAMS` has `shot_quiet`, `shot_loud`, `takedown`, `mag_land`, `ui_click` pointing at existing Kenney files as stand-ins; hooks live in `operative.gd` (`_fire`, choke end, `_throw_magazine`) and `pause.gd` (`Mixer.click()`). Radio/codec beeps (`Mixer.blip`), footsteps, knock and alert stings were already in. To finish, download into `_raw/` and copy only what you use into `assets/audio/`, then repoint those five paths and add `CREDITS.md` lines:
- Kenney Impact Sounds (https://kenney.nl/assets/impact-sounds): takedown thud, Magazine landing.
- Kenney Sci-fi Sounds (https://kenney.nl/assets/sci-fi-sounds): `laserSmall_*` for the suppressed shot, `laserLarge_*` or `explosionCrunch_*` for the loud shot.
- Kenney Interface Sounds (https://kenney.nl/assets/interface-sounds): `click_*` for the UI click.
