# 04: Guard reactions

**Spec:** decisions in [polish map](../../polish/map.md); see [guard reactions prototype](../../polish/issues/05-guard-reactions-prototype.md).

**What to build:** Guards visibly react: a quick flinch (well under half a second) when they go to alert, and a look-around sweep at the search spot during Evasion. The flinch never delays the guard's actual response.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Flinch shorter than 0.5 s and does not hold up movement or shooting; if it reads as a stall in play, it is dropped
- [ ] Look-around plays at the search spot
- [ ] Both read from the game camera in Harbour
- [ ] Guard alert, tree and vision tests pass
