# 06: Spoofing behaviour

**Spec:** decisions in [polish map](../../polish/map.md); see [Aigis world behaviours](../../polish/issues/04-aigis-world-behaviours.md).

**What to build:** When a Spoofing Countermeasure is deployed (Glaukopis threshold, radio callback, single-use Voiceprints), guards stop mid-patrol and key the radio to call HQ back, with a visible gesture and the shared cyan telegraph.

**Blocked by:** 05

**Status:** resolved

- [x] Guard pauses and gestures, then resumes patrol
- [x] Weighted trigger as in the Stealth behaviour, tested with a seeded RNG
- [x] Briefing line and first-sighting Metis line exist

## Answer

- Reuses `Guard.telegraph("radio_check", "((?))", "look", mutter)`; `Telegraph.METIS["radio_check"]` is the first-sighting call.
- `Telegraph.radio_check(level, rng)` / `radio_check_share(level)` (same 25-75% clamp), rolled every `Telegraph.RADIO_CHECK_EVERY` (12 s) of patrol in `Guard.patrol`; on a hit the guard stands still 1 s with the cyan telegraph, then resumes. `Deployment.radio_check_level` feeds `Guard.radio_check_level` (Harbour `_equip`), seeded via `Guard.rng`.
- Briefing key `brief.glaukopis.radio_check` whenever Spoofing is deployed (never Mission 1). Tests in `tests/test_telegraph.gd`.
- Open: the `((?))` icon, `look` clip (no radio-handset clip yet), mutter and Metis wording are placeholders.
