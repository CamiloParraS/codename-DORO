# Polish: making Ghost Layer feel like a real MGS

## Destination

A polish spec: ranked decisions that become build tickets under `.scratch/polish/`, ending in a **polish bar** (acceptance checklist) every Mission 1-3 must meet. No code is written by this map.

## Notes

- Constraints: solo, deadline ~2026-11-19, game AI not ML, at least 3 Missions (see `GLOSSARY.md`, `docs/adr/0001`).
- Scope: full 3+ Mission campaign at consistent quality; fallback is a Harbour (+ one) vertical slice.
- Pillars, in order: alert loop, Aigis adaptation readable in-world, audio. Camera and PSX look are settled (build tickets 02, 03).
- Harbour (Mission 1) is the feel benchmark; later Missions inherit it.
- Audio: CC0 packs in `_raw/`, PSX-processed (bitcrush, low sample rate), each logged in `CREDITS.md`. Repo currently has no audio assets or code.
- Alert loop leans classic MGS: `!` hit-stop (~0.2 s), sting, music track, countdown via existing phase chips.
- Aigis adaptation: one or two telegraphed in-world behaviours per Countermeasure.
- Animation priority: guard startle + search sweep, then `locomotion.gd` tuning.

## Decisions so far

- [Audio direction](issues/02-audio-direction.md): ambience on patrol, one track each for Alert and Evasion, three stings, highest-guard-state wins, 4-bus mix with codec ducking, per-Voice text blips.
- [Aigis world behaviours](issues/04-aigis-world-behaviours.md): one cyan-telegraphed guard behaviour per Habit family (Stealth head-check, Spoofing radio callback, Combat flank arrival), 25-75% weighted, named in Briefing and by Metis.
- [Alert loop prototype](issues/03-alert-loop-prototype.md): beat structure kept; stings too creepy, re-pick (see stings re-pick research).
- [Guard reactions prototype](issues/05-guard-reactions-prototype.md): startle cut to a very short flinch or dropped; other reactions unobjected.
- [Locomotion feel](issues/06-locomotion-feel.md): tuned values feel right; keep them.
- [Stings re-pick research](research/stings.md): Kenney `question_001`, `twoTone1` (trimmed), `confirmation_002` as bright replacements; unheard, audition before locking.
- [Polish bar](issues/07-polish-bar.md): seven pass/fail items per Mission, Harbour first, 7-day polish time box, audio (34) moved ahead of Missions 2 and 3.
- [Audio packs research](research/audio-packs.md): all CC0; SRG774 Dark Sci-Fi pack for the three music beds, Kenney + OpenGameArt for SFX; PSX look via Max Rate import + `AudioEffectDistortion` LOFI bus (Godot has no bitcrush).

## Not yet specified
(Nothing left: codec presentation, readability and menus/pause/frame-rate are covered by the polish bar.) World noise-ring cue for thrown Magazine and knock is a deferred nice-to-have.


## Out of scope

- Wall-hug, CQC, controller support: not fitting 6 weeks solo.
- New Missions or systems beyond the build tickets.

## Build tickets

Written to `.scratch/polish-build/issues/` (13 tickets, ready-for-agent except the cold playtest which is ready-for-human). Time box: last 7 days before ~2026-11-19; build ticket 34 (sounds) moves ahead of 25/26, now covered by polish-build 01.
