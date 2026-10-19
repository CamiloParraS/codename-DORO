Type: grilling
Status: resolved
Blocked by: -

## Question

Define the polish bar: concrete pass/fail checklist (audio coverage, reaction animations, readability, frame rate, menus/pause) each of Missions 1-3 must meet, and the order Missions get polished in.

## Answer

**Polish bar**, pass/fail per Mission:
1. Audio: alert beat, footsteps, ambience, codec with ~6 dB music ducking all present (per issues/02 and 08).
2. Feedback: every Countermeasure in that Mission has its telegraph (cyan icon plus a Metis radio line; issues/04).
3. Readability: from the game camera, a first-time tester can find guard facing, cover and the Extraction point without the debug overlay.
4. Reactions: guards show the short flinch / look-around on the alert and search beats (issues/05).
5. Performance: 60 fps in Harbour; floor of 45 fps in the busiest Mission.
6. Flow: briefing, play, pause, death and Checkpoint resume, post-Mission all run with no errors in the log.
7. No placeholder text or debug UI visible. (The PSX look is not on the bar; it is settled.)

**Verification:** self-check with a short per-Mission checklist; one cold 10-minute playtest of Mission 1 near the end, noting what confuses the tester.

**Order:** Harbour fully, then Relay station, then Research annex; Core gets only audio and flow. A Harbour + one Mission slice always exists as the fallback.

**Time box:** last 7 days before ~2026-11-19 are polish plus demo write-up. Earlier, polish only what blocks build tickets. Items still failing on day 7 are logged as known issues, not fixed.

**Build order change:** move build ticket 34 (sounds) ahead of Missions 2 and 3 content (25, 26); fold guard reactions and Aigis behaviours into the existing guard tickets; Core and finale stay where they are.
