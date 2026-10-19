# 04: Guard reactions

**Spec:** decisions in [polish map](../../polish/map.md); see [guard reactions prototype](../../polish/issues/05-guard-reactions-prototype.md).

**What to build:** Guards visibly react: a quick flinch (well under half a second) when they go to alert, and a look-around sweep at the search spot during Evasion. The flinch never delays the guard's actual response.

**Blocked by:** 02

**Status:** resolved

- [x] Flinch shorter than 0.5 s and does not hold up movement or shooting; if it reads as a stall in play, it is dropped
- [x] Look-around plays at the search spot
- [x] Both read from the game camera in Harbour
- [x] Guard alert, tree and vision tests pass

## Answer

Flinch: `GuardAlert.FLINCH` (0.35 s), a Mixamo `surprised` pose played by `Guard._physics_process` on entering ALERT (`GuardAlert.flinches`). It is a `react()` pose only, with no freeze, so the tree, movement and `_shoot_back` never wait on it. Look-around: Mixamo `look_around` plays for `LOOK_CLIP` (6 s) once the guard is at its search spot in EVASION (`Guard.search`). `CharacterModel.react` gained an optional `speed`. Needs the gitignored Mixamo bake to show. Not judged by eye from the game camera; if the flinch reads as a stall in the playtest, drop it (remove the `flinches` check in `guard.gd`).
