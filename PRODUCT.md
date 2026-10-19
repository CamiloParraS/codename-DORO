# Product

<!-- impeccable:product-schema 1 -->

## Platform

desktop

Not a web product: a Godot 4.7 3D game (Jolt, Forward Plus) delivered as a Windows build. All UI is Godot `Control` nodes, not HTML/CSS. Scope of this file is the in-game UI only (HUD, radial radio, codec and subtitles, briefing, post-mission, pause, free mode, debug overlay).

## Stack

Godot 4.7, GDScript, `Control` scenes under `ui/<feature>/` (see `docs/GUIDE.md`). HUD laid out on a 640×360 logical canvas over 3D rendered at 854×480.

## Users

The player controls one Operative of Metis, a mercenary team investigating Palladion, in third-person stealth. Moment to moment they are sneaking past guards and need to read danger at a glance. The second audience is an evaluator at a live presentation (about 2026-11-19) who must be able to see the enemy AI adapting.

## Product Purpose

Ghost Layer is a short stealth game where an enemy AI, Aigis, profiles the Operative's habits and adapts its forces between Missions. It is a solo, six-week project (from 2026-10-08) and the AI is game AI (behaviour trees, utility AI, profiling), not ML. Success is a playable build in which the adaptation is visibly legible rather than reading as "the game got harder".

## Positioning

The UI is where Aigis's adaptation becomes visible: briefing where the Voices name the player's habit, post-Mission profile, debug overlay with profile and Voice weights. Another stealth game's HUD would not carry that.

## Operating Context

- Third-person over-the-shoulder camera, PSone-era "modern-retro" look: 15-bit banded colour, nearest-neighbour upscaling, 128 px textures.
- HUD E (Peace Walker style side strips) plus MGSV detection arcs and ?/! marks; radial radio menu with time slowed for Spoofing; full-screen codec for paused calls, subtitles over a `CALL >>` bar for calls during play.
- Free mode with Presets and a debug overlay exist for the live presentation.

## Capabilities and Constraints

- HUD crisp at native resolution on a 640×360 logical canvas.
- Fonts: Press Start 2P (labels) and VT323 (text, subtitles), both OFL, in `assets/fonts/`.
- No radar and no compass or minimap (removed: it served no purpose in stealth); the top-right corner is reserved for Aigis cues and voiceprints.
- Profile Habits (Stealth, Combat, Headshots, Takedowns, Downs, Spoofing) shown as a 0–3 icon strip with rise/fall arrows, no raw numbers.
- No voice acting: text plus PSone-style radio beeps. English first, Spanish translation later.
- Glossary terms in `GLOSSARY.md` are binding (Operative, Aigis, Voice, Mission, Briefing, Codec call, etc.).
- Undecided: final HUD palette. HUD E was white/grey; the `prototype/hud-redesign` branch tries an amber/red tactical palette across three layouts.

## Brand Commitments

Name: Ghost Layer (repo codename-doro). Aigis's five Voices: Promachos, Nike, Pallas, Gorgo, Glaukopis. Palette is not yet a commitment.

## Evidence on Hand

Existing HUD code and tests: `ui/hud/`, `tests/test_hud_model.gd`, prototypes in `ui/hud/prototype/`. Design history in `.scratch/ghost-layer/issues/06-psx-look-and-hud-prototype.md` and `.scratch/ghost-layer-build/issues/07-hud-e-detection-arcs.md`. No player-testing data exists.

## Product Principles

1. Read danger at a glance: the HUD's first job is stealth readability during play, in any Area's lighting.
2. Make the AI's adaptation visible on screen; every Aigis decision needs a way to show up.
3. Never act as radar or show raw numbers; information is iconic and earned.
4. Stay inside the PSone-era, text-and-beeps world; no voice acting, no modern UI chrome.

## Accessibility & Inclusion

Readability in play is the stated driver for the redesign: contrast against varied scenes and legibility at a glance. Do not rely on red/amber hue alone to separate states (use shape, motion or text too). Two languages (English, Spanish) must fit the layouts.
