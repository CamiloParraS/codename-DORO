# 09: Harbour polish pass

**Spec:** decisions in [polish map](../../polish/map.md); the bar is in [polish bar](../../polish/issues/07-polish-bar.md).

**What to build:** Harbour meets all seven polish bar items: audio, Countermeasure telegraphs (via Free mode Presets), readability from the game camera, guard reactions, 60 fps, a full flow with no log errors, and no placeholder text or debug UI.

**Blocked by:** 01, 02, 03, 04

**Status:** ready-for-agent

- [ ] All seven bar items checked off in a per-Mission checklist file
- [ ] Failing items are fixed or logged as known issues
- [ ] No errors in the log across a full Mission run

## Answer

Checklist: `docs/polish/harbour.md`. No box is fully met: tests and headless runs cover the logic of items 1, 2, 4 and 6, but listening, the game camera, 60 fps and a complete Mission run in a real window need a human. Fixed a real flow bug: `ui/briefing/briefing.gd` did not parse (a comment swallowed a closing paren), and added `tests/test_scripts_load.gd`. Known issues logged in the checklist, not fixed: nothing calls `Mixer.codec_call`; the Briefing shows raw `brief.*` keys; the Free mode footer and the `INTEL` radio line are placeholder; Mixamo-bake-dependent errors on a fresh clone. A 600-frame headless Harbour run logged no errors, which is not yet a full Mission run.
