# Combat verbs and Lethality

Type: grilling
Status: resolved
Blocked by:

## Question

What can the Operative do to guards, and how does each action count toward Lethality? Starting hypothesis: tranquilizer pistol, lethal weapon, takedown from behind (lethal or non-lethal), hiding bodies. What counts as lethal (deaths caused indirectly? alarms?), and is Lethality a single number or several categories?

## Answer

Settled in a grilling session (2026-10-09). New glossary terms: **Takedown**, **Neutralized**, **Down**; **Lethality** sharpened to a weighted tally.

**Weapons and verbs**

- **Loadout (MGSV starting-loadout style):** a suppressed tranquilizer pistol (~8 darts; its suppressor never breaks) and a suppressed assault rifle (~60 rounds; the suppressor breaks after 10 shots and the rifle is loud from then on). Each Mission has resupply crates that restore ammo and the suppressor. No other weapons; a loud weapon, if ever needed, goes to the Gadgets/items fog.
- **Aiming:** hold right mouse to aim over the shoulder; shots are hitscan.
- **Tranq hits:** a headshot neutralizes instantly; a body shot neutralizes after ~3 s, during which the guard stumbles and is suspicious but can't radio.
- **Rifle hits:** one headshot or two body hits kill.
- **Loud shots:** heard 30 m away. Guards who hear one skip the meter and go straight to suspicion, investigating where the shot was fired (no radio alert). Fits the stealth prototype's rule that noise never alerts on its own.
- **Takedown:** possible on a guard who is not in alert, within ~1.5 m, with the Operative outside their front cone. The choke takes 2 s (the Operative is exposed) and neutralizes; the kill takes 0.5 s.
- **Carry (MGSV style, not drag):** the guard rides over the shoulder in a fixed pose attached to the shoulder bone (no ragdoll). Movement is capped at walk speed, or a slower crouch, and detection treats the Operative as standing and walking. The tranq pistol can be fired one-handed with worse accuracy. Releasing the button drops the guard. Chosen over dragging because it is cheaper to build and keeps a better pace for hauling targets.
- **Hiding bodies:** means getting them out of sight lines. There is no light model.

**Down guards**

- A Neutralized guard wakes after ~90 s. Choking them again resets the timer.
- Guards spot a Down guard with the same vision cones and meter used for the Operative. The finder goes to suspicion, walks over and checks, then radios an alert if the guard is dead or wakes them if Neutralized. A woken guard joins the checker in suspicion and remembers nothing. The checker can be taken down on the way.

**Open combat:** viable but costly.

- Guards shoot back, and their hit chance drops with distance and when the Operative is running.
- The Operative dies after 4 hits and regenerates after 5 s without taking damage.
- Death restarts the Mission from the last checkpoint.

**Lethality**

- A single, silent, **weighted tally** of deaths the Operative caused: an ordinary guard counts 1, a Mission's Eliminate target counts 3. Killing a Neutralized guard counts in full.
- Only deaths caused by the Operative's own actions count; there are no environmental hazards or explosives. Alarms and going loud never count; they are profile habits.
- It is kept separate from the profile counters: the profile is "how I fight", Lethality is "how many I killed".
- It is saved at checkpoints and at the end of the Mission, so a restart rolls it back.
- Nothing on the HUD and no number on the post-Mission screen. The player senses it only through how the Voices talk about them; the debug overlay shows the number.

**Missions:** no Mission requires a death. An Eliminate target can be killed (the objective completes on the spot) or neutralized and carried to an extraction point. Killing is the deliberate shortcut, and the target's weight makes it the biggest single Lethality decision in a Mission.

**Handed to other tickets**

- Operator profile and countermeasures: guards alerting on sight once too many bodies have been found; radio checks for missing guards; night/light play as an optional counter; checkpoint rollback for the profile counters too.
- Architecture of the five Voices: the Lethality thresholds for the three endings.
- Campaign plan: whether Eliminate Missions exist.
- Spoofing prototype: how a Voiceprint is captured (a hold-up was considered and left out of the verb set).

## Comments

- 2026-10-09 (from [Input](14-input.md)): carrying is a toggle on E (press to pick up, press to drop), not hold-to-carry. No reloading while carrying.
