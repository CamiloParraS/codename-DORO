# Operator profile and countermeasures

Type: grilling
Status: resolved
Blocked by: 01, 07

## Question

Which habits of the Operative does Aigis track (going loud, headshots, night infiltration, favorite flank, use of Spoofing, etc.), how are they measured, and which countermeasure does each one trigger? How does each countermeasure become visible to the player (the four channels in Notes)?

## Comments

- 2026-10-09 (from Combat verbs and Lethality): candidates handed over: guards alerting on sight once too many bodies have been found; radio checks for missing guards; a night/light counter (only if light ever becomes a stealth factor). Profile counters should roll back with checkpoints like Lethality. Keep the profile separate from Lethality.

## Answer

Settled in a grilling session (2026-10-09). New glossary terms: **Profile**, **Habit**, **Countermeasure** ("Operator" is dropped; the player is the Operative).

**Profile model (MGSV Revenge, shrunk)**

- The Profile holds one level (0–3) per Habit, at 100 points per level. Triggers add points during the Mission. Point values are tuned during the build and checked by a unit test that simulates several Missions.
- Levels are recomputed only when a Mission is completed. The Mission's points are saved with checkpoints and roll back on death; an aborted Mission applies nothing. Nothing in the Profile changes during a Mission.
- The level cap rises with the campaign: Mission 1 caps at 0, Mission 2 at 1, Mission 3 at 2, and the core at 3. Points are clamped MGSV style to cap × 100 + 99, so at most 99 points carry out of Mission 1, enough for the warning chatter in Mission 2.
- Decay is at most ½ level per Mission for every Habit except Stealth and Combat.
- **Stealth and Combat pull against each other.** Each Mission decides one tendency (whichever side leads by a margin), which adds to one side and takes away from the other. A Mission completed without an alert counts as a Stealth tendency, even with no Downs.
- **Levels unlock Countermeasures; they don't deploy them.** The Voices choose which unlocked Countermeasures to deploy in each Mission, with one rule: the Operative's strongest Habit is always answered.
- **No counter item or action** (no Chicken Hat, no dispatch missions). Changing your style is the counterplay; decay and the tug of war do the rest.

**Habits and Countermeasure ladders**

| Habit | Measured by | L1 | L2 | L3 |
|---|---|---|---|---|
| Stealth | guards put Down while no alert is active; a Mission with no alert | security cameras | one extra patrol | overwatch sentries (stationary guards on high points) |
| Combat | alerts raised, loud shots, kills during an alert | vests | more guards | 2 reinforcements from the Area's entry point, once per alert |
| Headshots | tranq or rifle headshots | helmets on 33% | 66% | 100% |
| Takedowns | chokes and kills from behind | guards turn around more often | guards patrol in pairs | the choke takes 3 s instead of 2 and the struggle makes noise that carries 6 m (the kill stays at 0.5 s) |
| Downs | Down guards found, Neutralized guards woken | random HQ poll | a found Down guard means an instant alert, with no check | targeted HQ poll |
| Spoofing | Spoofed transmissions sent, with extra weight if exposed | Glaukopis's threshold drops from 40 to 25 | callback | single-use Voiceprints |

**Countermeasure rules**

- **Helmet:** a headshot counts as a body hit (the tranq takes the slow ~3 s; the rifle needs 2 hits).
- **Vest:** stops tranq body shots completely; rifle body hits go from 2 to 4.
- **Security camera:** sweeps back and forth with the same vision meter as a guard's front cone. A full meter means a radio alert, with no suspicion step. The rifle destroys it and the tranq does nothing. A destroyed camera is treated like a missing guard.
- **HQ poll (Downs):** there is one kind of guard; every guard keeps the spontaneous check-ins from the Spoofing prototype, which are only flavour and a Voiceprint source, with no consequence if missed.
  - L1: about every 45 s, HQ radios "<X>, report" to one random living guard. The more guards are Down, the likelier the call lands on one of them. If X doesn't answer within ~10 s, the nearest guard goes to X's last position in suspicion.
  - L3: HQ polls the guard no one has seen for the longest time ("Nobody's seen <X> in a while. <X>, report."). It reuses the guards' sight check, run at a low rate on each other. If that turns out too expensive in the build, the fallback is a random poll every 20 s.
- **"Report in":** a fourth radio order. It answers a pending HQ poll as X, needs X's Voiceprint, and is judged by Glaukopis like any other order.
- **Callback (Spoofing L2):** after a Spoofed transmission, the recipient radios the speaker to confirm. If the real speaker is alive and up, they deny it and the transmission is exposed. If the speaker is Down, there's no answer, and the +60 rule applies only if some guard knows they're Down. To spoof at L2, take the speaker Down first and hide them, which feeds Downs.
- **Single use (Spoofing L3):** a Voiceprint is flagged after one use, whether or not the transmission was exposed.

**Visibility (the four channels)**

- **In the world:** every Countermeasure is visible or audible (gear, cameras, pairs, sentries, HQ polls and callbacks on the radio). One that can't be seen gets cut.
- **Pre-Mission briefing:** the Voices name the Operative's top one or two Habits and hint at the answer.
- **Post-Mission screen:** a strip of 0–3 icons, one per Habit, with arrows for what rose or fell. No raw numbers.
- **Guard chatter:** at 50 points before a level, guards in the next Mission hint at the Habit; once a Countermeasure is deployed, they confirm it. Spoofing ladder changes are announced the same way ("Command wants a callback on every order now.").
- **Debug overlay:** raw points, levels, this Mission's tally, and what's unlocked and deployed.

**Left out:** night (no light model; it stays in the Light and night fog), long range (no sniper verb), favourite flank (only meaningful when an Area is revisited; it moves to the Extra Missions fog).

**Handed to other tickets**

- Architecture of the five Voices: the per-Mission deployment budget, applying the strongest-Habit rule, which Voice speaks in the briefing, and comments on lethal takedowns (Takedowns L3 pushes toward the kill).
- Campaign plan: where the cap rises, an entry point in each Area for reinforcements, high points for sentries and spots for cameras, and preset profiles expressed as Habit levels.
- PSX look and HUD prototype: the post-Mission icon strip (6 Habits, 0–3, arrows).
- Narrative delivery: about 24 sets of chatter lines (a warning and a confirmation per Countermeasure step).
