# 35: Draft all non-Voice English lines

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Every line not spoken by a Voice exists in English, within the 3,500-word cap: Codec calls, tutorial, guard Profile chatter, HQ radio, Target chatter, intel and story beats, Epilogue, UI strings.

**Blocked by:** 29, 30, 32

**Status:** ready-for-agent

- [ ] Story beats from the spec's table delivered through intel pickups and analyst lines
- [x] Guard chatter: a warning and a confirmation per Countermeasure step, 2 variants each
- [x] Lines that name a Habit get one full line per Habit (no assembled fragments)
- [x] A word count of the en column stays within the cap, leaving room for 36's lines

## Comments

2026-10-19: Drafted the 24 `chatter.*` lines (one full line per Habit, warn/confirm x 2 variants) and the 12 `finale.epi.*` Epilogue lines (Metis profits, per ending). Chatter keys are per Habit, not per step (code picks `chatter.<state>.<habit>.<n>`), so the warn/confirm pair covers each Habit. `tests/test_english_lines.gd` checks no placeholders outside the Voice keys and the 3,500-word cap. Left unchecked: story beats. Codec/live lines from earlier tickets carry the whistleblower, the Core under the Harbour and the dead commanders, but "Synthetic Content Inflation" is only implied (`live.m2.s1.02`) and Aigis getting full authority only appears in `codec.m4.01`; no new intel keys added. HQ radio, Target chatter and most UI strings are hard-coded in code, not in `lines.csv`, so there was nothing to draft; they need externalising first. Ticket 36 keys untouched: `brief.*`, `post.*`, `finale.debate.*`, `finale.end.*`.
