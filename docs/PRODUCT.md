# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

Not a web product: a Godot 4.7 3D game (Jolt, Forward Plus) delivered as a Windows desktop build. `web` is the closest valid value because the UI follows no native OS design language. All shipped UI is Godot `Control` nodes; HTML mocks are used only to explore layout and direction before the Godot build. This file covers the in-game UI only.

## Stack

Godot 4.7, GDScript, `Control` scenes under `ui/<feature>/` (see `docs/GUIDE.md`). Node-free rules sit beside the scenes (`hud_model.gd`, `radar_model.gd`) and are covered by `tests/`.

## Users

The player controls one Operative of Metis, a mercenary team investigating Palladion, in third-person stealth. Moment to moment they are sneaking past guards and need to read danger at a glance. The second audience is an evaluator at a live presentation (about 2026-11-19) who must be able to see the enemy AI adapting.

## Product Purpose

Ghost Layer is a short stealth game where an enemy AI, Aigis, profiles the Operative's habits and adapts its forces between Missions. It is a solo project (started 2026-10-08, deadline 2026-11-11) and the AI is game AI (behaviour trees, utility AI, profiling), not ML. Success is a playable build in which the adaptation is visibly legible rather than reading as "the game got harder".

## Positioning

The UI is where Aigis's adaptation becomes visible: the Briefing where the Voices name the player's habit, the post-Mission profile, the debug overlay with profile and Voice weights. Another stealth game's HUD would not carry that.

## Operating Context

- Third-person over-the-shoulder camera. The 3D keeps its PSone-era look (15-bit banded colour, 854×480 render, 128 px textures).
- UI revamp (branch `feat/ui-revamp`, from 2026-10-29): every UI surface is being replaced. The UI is no longer bound to the PSX look and will render at full resolution (1920×1080 logical) over the low-res 3D.
- Surfaces in scope: HUD (life, Radar, item and weapon selectors, detection arcs and ?/! marks, contextual prompts), radio menu, Codec calls (full-screen paused and subtitle bar during play), Briefing, mission card, post-Mission results, Requisition, pause, settings, main menu, free mode, game over, finale, debug overlay.
- Free mode with Presets and the debug overlay exist for the live presentation; the debug overlay gets the new look too.

## Capabilities and Constraints

- Radar: north-up square, 30 m to the edge, guards beyond pinned to the edge, jammed while the phase is ALERT or EVASION; a guard with a pending Radio call flashes red (`ui/radar/radar_model.gd`). There is no compass or minimap.
- Radio menu: radial, time slowed while open (used for Spoofing and Hints).
- Profile Habits (Stealth, Combat, Headshots, Takedowns, Downs, Spoofing) shown as a 0–3 icon strip with rise/fall arrows, no raw numbers.
- Requisition spends Recruit points (one per Fultoned guard, first clears only) on permanent gear upgrades.
- Codec portraits exist for analyst, chief, director, handler, operative, researcher (two frames each, `ui/codec/portraits/`).
- No voice acting: text plus radio beeps. English first, Spanish translation later.
- Glossary terms in `docs/GLOSSARY.md` are binding (Operative, Aigis, Voice, Mission, Briefing, Codec call, Requisition, Recruit, Radar, etc.).
- Current fonts (Press Start 2P, VT323, both OFL, `assets/fonts/`) are not binding for the revamp.
- No Konami assets ship: no MGS portraits, MSF logo, item icons or screen captures. Every emblem, portrait and icon is original.

## Brand Commitments

Name: Ghost Layer (repo codename-doro). Team: Metis; it needs its own original emblem. Aigis's five Voices: Promachos, Nike, Pallas, Gorgo, Glaukopis.

Visual direction (chosen 2026-10-29 over bolder alternatives): the genre standard, an MGSV-style tactical HUD at that craft level, arranged on the Peace Walker layout. Quality bar: MGSV and Peace Walker. HTML mocks in `docs/ui-mock/`.

References the user named (inspiration only, reference images in `.scratch/MGSUI-INSPIRATION/`):
- HUD: MGSV's modern holographic/parallax feel; a Peace Walker style item and weapon selector, scaled down so it doesn't cover the screen; a Radar like Peace Walker's.
- Radio menu: MGSV weapon wheel.
- Interactions (hold-up, choke, Fulton, doors, carry): MGSV-style contextual button prompts, a button glyph plus an action icon next to the target, no text (`Metal-Gear-Solid-V-The-Phantom-Pain-ButtonPrompts(contextual).jpg`).
- Menus: Peace Walker menu graphics adapted to a more modern style, including item iconography in the background and a team emblem the way PW uses the MSF logo.
- Codec calls: portrait framing like Peace Walker's staff screen (`Metal-Gear-Solid-Peace-Walker-maintenanceandmanagement.jpg`), with original portraits in that halftone treatment.
- Requisition: like Peace Walker's R&D screen (`Metal-Gear-Solid-Peace-Walker-PurchaseUpgrades.jpg`), plus images that guide the player.

## Evidence on Hand

Existing UI code: `ui/*/`, HUD model tests in `tests/test_hud_model.gd`, Radar tests. Design history in `.scratch/ghost-layer/issues/06-psx-look-and-hud-prototype.md` and `.scratch/ghost-layer-build/issues/07-hud-e-detection-arcs.md`. No player-testing data exists.

## Product Principles

1. Read danger at a glance: the HUD's first job is stealth readability during play, in any Area's lighting.
2. Make the AI's adaptation visible on screen; every Aigis decision needs a way to show up.
3. Information is iconic and earned: no raw numbers for the profile; the Radar shows nearby guards only and goes dark under alert.
4. The HUD stays out of the way; selectors and the radio menu appear only when called, never covering the play space for long.

## Accessibility & Inclusion

Readability in play is the stated driver: contrast against varied scenes and legibility at a glance. Do not rely on red/amber hue alone to separate states (use shape, motion or text too). Two languages (English, Spanish) must fit the layouts.
