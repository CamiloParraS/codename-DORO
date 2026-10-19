# 02: Alert beat

**Spec:** decisions in [polish map](../../polish/map.md); see [alert loop prototype](../../polish/issues/03-alert-loop-prototype.md) and [stings research](../../polish/research/stings.md). Prototype branch `prototype/alert-loop` is throwaway reference.

**What to build:** Going from patrol to suspicion, alert, evasion and back reads instantly: a ~0.2 s hit-stop on the alert, a "?" blip on suspicion, a "!" sting on alert, and a relief cue when Evasion ends, with the existing phase chips as the countdown.

**Blocked by:** 01

**Status:** resolved

- [ ] Auditioned and approved CC0 stings (Kenney picks or alternates) replace the rejected ones; nothing horror-toned
- [ ] Hit-stop restores time scale reliably, including on death or pause during it
- [ ] Each of the four beats is distinct by sound alone
- [ ] `CREDITS.md` updated for every file used

## Answer

`ai/alert_beat.gd` (node-free) watches the Mission's highest guard state: "?" on Patrol to Suspicion, "!" plus a 0.2 s real-time hit-stop (`Engine.time_scale` 0.05) on reaching Alert, relief when Evasion ends; Evasion back to Alert re-fires "!". The `Mixer` autoload plays the stings on the UI bus and applies the scale; it now runs while paused, and pause, Operative death and leaving the tree all restore time scale 1. Tests: `tests/test_alert_beat.gd`.

Stings are the provisional Kenney picks from the stings research, copied untrimmed into `assets/audio/` (`sting_question` = question_002, `sting_alert` = twoTone1, `sting_relief` = confirmation_002), credited in `CREDITS.md`. **Nobody has listened to them: the "auditioned and approved" checkbox stays open for the human**, as does "distinct by sound alone". Audio is independent of `Engine.time_scale` per Godot docs, so the "!" plays at normal pitch during the stop; confirm by ear. Not done: trimming `twoTone1` to ~0.4 s, a PSX pass on the stings.
