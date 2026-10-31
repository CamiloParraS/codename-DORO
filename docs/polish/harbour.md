# Harbour polish checklist

Bar: `.scratch/polish/issues/07-polish-bar.md`. Checked = verified by tests or a headless run on 2026-10-19. Unchecked = needs a human or is a known issue. Nobody has played or listened to this build for this checklist.

## 1. Audio
- [x] Buses, music-follows-highest-state, 2 s hold, 6 dB duck, per-bus volume: `tests/test_mix.gd`, `tests/test_music_state.gd`
- [x] Footstep, knock, ambience, music and three sting files exist in `assets/audio/` and are credited
- [ ] Listened to: stings distinct by sound alone, nothing horror-toned, "!" plays at normal pitch during the hit-stop (needs ears)
- [ ] Codec ducking in play: **known issue**, nothing calls `Mixer.codec_call(bool)` (no live Codec player exists). Only `VoiceBlip` text blips in the Briefing use the UI bus, and they do not duck.
- [ ] Music and footsteps are Kenney CC0 stand-ins; swap for real tracks (see `docs/CREDITS.md`)

## 2. Feedback (Countermeasure telegraphs, via Free mode Presets)
- [x] Share, flank point, radio-check, head-check, Metis once-per-kind call and Briefing key logic: `tests/test_telegraph.gd`
- [ ] Each telegraph (cyan icon plus Metis line) seen in Harbour through a Free mode Preset (needs a human)

## 3. Readability from the game camera
- [ ] Guard facing, cover and the Extraction point found without F3 by a first-time tester (needs a human). Extraction sits at the pier tip (`tools/build_harbour.gd`, `Extraction`).

## 4. Reactions
- [x] Flinch 0.35 s with no freeze, look-around at the search spot: `tests/test_guard_alert.gd`
- [ ] Seen from the game camera; **needs the gitignored Mixamo bake**. Without it other Missions log `Animation not found: "idle"` (see 6).

## 5. Performance
- [ ] 60 fps in Harbour, measured with the monitor in a real window (not measurable headless)

## 6. Flow
- [x] Headless: main menu loads, Harbour runs 600 frames with no log errors (Preset 1), Briefing builds and types out
- [x] Briefing used to fail to parse (`briefing.gd` line 22, a comment swallowed a `)`), so NEW CAMPAIGN could not reach it. Fixed; `tests/test_scripts_load.gd` loads every runtime script.
- [x] Full test suite headless: 338 pass; only `character_model.test_the_pistol_plays_its_own_clips` fails (needs the Mixamo bake)
- [ ] A complete Mission run (briefing, play to Extraction, pause, death, Checkpoint resume, post-Mission) in a real window: not done, only 600 frames were run
- [ ] Relay station and Research annex headless runs log `Animation not found: "idle"` from `character_model.gd:175` when the Mixamo bake is absent. Not Harbour, but the log is not clean on a fresh clone.

## 7. No placeholder text or debug UI
- [x] F3 debug overlay starts hidden
- [ ] **Known issue**: the Briefing shows raw keys (`brief.pallas.close`) because no Briefing text is written for any `brief.*` key; the file header says "Placeholder Briefing"
- [ ] **Known issue**: Free mode footer reads "EVERY MISSION PLAYS IN THE HARBOUR FOR NOW. F3: DEBUG OVERLAY" (`ui/free_mode/free_mode.gd`). Free mode is a dev screen; hide or remove before the demo.
- [ ] Intel objectives go out as a radio-log line labelled `INTEL` ("placeholder until the live Codec calls", `missions/mission_run.gd`)
