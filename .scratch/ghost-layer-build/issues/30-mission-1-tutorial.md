# 30: Mission 1 tutorial

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Mission 1 teaches the game: the first time each verb is relevant, a contextual prompt appears with one Metis radio line, and a pre-placed eavesdrop spot teaches Spoofing.

**Blocked by:** 28, 22

**Status:** done

- [x] First-use prompts with a handler live line for: crouch, takedown, carry, tranq, eavesdrop for a Voiceprint, radio menu, Scanner, Magazine
- [x] A pre-placed eavesdrop spot near a guard's check-in route
- [x] Prompts appear only in the campaign's Mission 1

## Comments

2026-10-19: Built `missions/tutorial.gd` (node-free rules, tests/test_tutorial.gd), wired into MissionRun and a HUD tip line; EavesdropSpot marker added to Harbour via tools/build_harbour.gd. Boxes ticked on tests plus a headless Harbour run (Free mode, no errors). Left for a playtest: tip distances/spacing (8 s) feel, that the HUD tip and Metis line read well in the real window, and that a guard actually checks in while the player stands at the spot.
