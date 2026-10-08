# MGSV Revenge System (enemy preparedness) and AI readability

Researched 2026-10-08 for ticket `issues/01-revenge-system-research.md`.

## Source key and trust

| ID | Source | Trust |
|---|---|---|
| **[L1]** | `TppRevenge.lua`, TinManTex/mgsv-deminified-lua: https://github.com/TinManTex/mgsv-deminified-lua/blob/master/data1/Assets/tpp/script/lib/TppRevenge.lua | **Highest.** Deminified game script. Raw URL: `raw.githubusercontent.com/TinManTex/mgsv-deminified-lua/master/data1/Assets/tpp/script/lib/TppRevenge.lua`. It is the Infinite Heaven (mod) fork. Lines marked `--tex` are mod edits and are ignored here. Retail behavior is kept in `--ORIG` and `RETAILBUG` comments. |
| **[L2]** | `TppEnemy.lua`, same repo: https://github.com/TinManTex/mgsv-deminified-lua/blob/master/data1/Assets/tpp/script/lib/TppEnemy.lua (`SetOccasionalChatList`, ~L1581-1830) | Highest, same caveats |
| **[L3]** | `TppDefine.lua`, same repo (`STORY_SEQUENCE_LIST`, ~L355) | Highest |
| **[MW]** | MGSV Modding Wiki, Revenge System: https://mgsvmoddingwiki.github.io/Revenge_System/ | Medium-high. Community notes from reading [L1]. Self-described as partly speculative. |
| **[GG]** | Gamer Guides, "Dynamic Difficulty": https://www.gamerguides.com/metal-gear-solid-v-the-phantom-pain/guide/the-basics-6/gameplay-9/dynamic-difficulty | Medium. Third-party guide. |
| **[ST]** | Steam forum, icon explanation (user moistalicious): https://steamcommunity.com/app/287700/discussions/0/527274088384666861 | Low. One player's reading. |
| **[ST2]** | Steam forum, user Trygger, 2017: https://steamcommunity.com/app/287700/discussions/0/1458455461482376811/ | Low. Player claims. |
| **[RE]** | ResetEra thread: https://www.resetera.com/threads/metal-gear-solid-v-revenge-system-apprectiation.173200/ | Low, but useful as player reception. |
| **[MGI-1]** | Metal Gear Informer on Kojima Productions Alert podcast 007 (Sean Eyestone): https://www.metalgearinformer.com/metal-gear-solid-vs-marking-system-is-not-comparable-to-splinter-cells-mark-execute-kojima-productions-says/ | Medium. Secondhand summary of a developer podcast. |
| **[MGI-2]** | Metal Gear Informer, Eyestone gameplay commentary (Dec 2013): https://www.metalgearinformer.com/new-mgsv-ground-zeroes-info-marking-system-can-be-switched-off-improved-ai-on-hard-difficulty-and-more/ | Medium |
| **[MGI-3]** | Metal Gear Informer, reflex mode can be switched off: https://www.metalgearinformer.com/metal-gear-solid-v-slow-motion-mechanic-can-be-switched-off | Medium |
| **[WP-GZ]** | Wikipedia, MGSV: Ground Zeroes (Gameplay): https://en.wikipedia.org/wiki/Metal_Gear_Solid_V:_Ground_Zeroes | Medium. Cites reviews. |
| **[WP-TPP]** | Wikipedia, MGSV: TPP (Gameplay): https://en.wikipedia.org/wiki/Metal_Gear_Solid_V:_The_Phantom_Pain | Medium |
| **[SW]** | StrategyWiki, Peace Walker gameplay: https://strategywiki.org/wiki/Metal_Gear_Solid:_Peace_Walker/Gameplay | Medium-low. Seen only as a search-result excerpt, not fetched in full. |

**Not reachable:** the Metal Gear Fandom wiki (HTTP 402) and GameFAQs (403). Claims quoted from them via search-result excerpts are marked "unverified". I found no GDC or CEDEC talk on MGSV enemy AI. I found no Kojima quote describing the revenge system's design intent. The only developer-side material is the Eyestone podcast and commentary summaries above.

---

## 1. What the system tracks

Retail code defines **12 meaningful counters** ("revenge types") [L1 `REVENGE_TYPE_NAME`]:

`STEALTH, NIGHT_S, COMBAT, NIGHT_C, LONG_RANGE, VEHICLE, HEAD_SHOT, TRANQ, FULTON, SMOKE`, plus two per-mission scratch counters, `M_STEALTH` and `M_COMBAT`. Four more entries (`DUMMY`...) are unused.

Each counter holds **revenge points (RP)**. **100 RP = 1 level** [L1 `REVENGE_POINT_PER_LV`]. Points are clamped to `maxLevel*100 + 99` [L1 `SetRevengePoint`].

### Triggers (event to RP) [L1 `REVENGE_POINT_TABLE`, handlers at end of file]

| Event | Counter | RP |
|---|---|---|
| Headshot that knocks a soldier unconscious (`IS_JUST_UNCONSCIOUS` flag). Per the code this is the non-lethal headshot case. | HEAD_SHOT | +5 |
| Enemy eliminated or knocked out while player is in Sneak phase | M_STEALTH (mission scratch) | +5 |
| Enemy eliminated while player is in any non-Sneak phase | M_COMBAT (mission scratch) | +5 |
| Whole base annihilated in sneak / in combat | M_STEALTH / M_COMBAT | +15 |
| Enemy eliminated at night | NIGHT_C | +10 |
| Phase changes to Alert at night | NIGHT_S | +15 |
| Soldier discovers a Fultoned comrade | FULTON | +15 |
| Smoke or sleeping gas damage, or a soldier sees smoke | SMOKE | +15 each |
| `AntiSniperNoticed` (soldier notices he is being sniped) | LONG_RANGE | **+30** |
| Killed by vehicle, walker gear, or player in a vehicle | VEHICLE | +10 |
| Killed by helicopter | VEHICLE | +10 |
| A sleeping or downed comrade is woken by another soldier | TRANQ | +5 |

Sources of disagreement:

- [MW] says triggers are "5 to 15". The code has one 30 (sniping). This is minor.
- [MW] says "Being smoked / seeing smoke" matches the code.

### Stealth vs combat is a tug of war, not a tally

- During a mission, kills feed only the scratch counters `M_STEALTH` and `M_COMBAT` [L1 `AddRevengePointByEliminationType`].
- At mission clear or abort, the scratch counters pick a **tendency** [L1 `_GetMissionTendency`, `ApplyMissionTendency`]:
  - If one side is zero, the other wins.
  - Otherwise the side that leads by at least `max(10, 30% of total)` wins.
  - Otherwise it is a DRAW.
- The tendency then adds to the persistent STEALTH and COMBAT levels from a table indexed by the *current level* [L1 `MISSION_TENDENCY_POINT_TABLE`]. The table has six entries per row, indexed by the current level (0-5):
  - Stealth tendency: STEALTH `+25,+25,+25,+25,+50,+50`; COMBAT `0,0,-5,-10,-50,-50`.
  - Combat tendency: the mirror image.
  - Draw: both `+20,+20,+20,0,-25,-10`.
- So a mission adds about a quarter level per tendency at low levels. At high levels the opposite type is pushed back down hard. A draw at high levels reduces both.
- Free-roam missions (30010, 30020) and free Mother Base (30050) are excluded from stealth/combat tendency [L1 `NO_STEALTH_COMBAT_REVENGE_MISSION_LIST`].
- [ST2] describes the same idea from play ("tug of war", counted by alert state at mission end). The detail that outposts count as five guards is a player guess. I could not confirm it in [L1].

### Which player behaviors map to which categories

| Behavior | Counter | Maximum level at end-game |
|---|---|---|
| Headshots | HEAD_SHOT | 7 |
| Sneak kills / combat kills | STEALTH / COMBAT | 5 each |
| Repeated night alerts | NIGHT_S | 3 |
| Night combat kills | NIGHT_C | 1 |
| Sniping from range | LONG_RANGE | 2 |
| Vehicle or heli kills | VEHICLE | 3 |
| Fulton extraction seen | FULTON | 3 |
| Smoke / gas use | SMOKE | 3 |
| Tranquilizer use (soldiers waking comrades) | TRANQ | 1 |

(Max levels from [L1 `REVENGE_LV_MAX`], rank-6 column.)

---

## 2. Levels, caps, timing

- **Level cap rises with story progress** in 6 steps [L1 `GetRevengeLvLimitRank`, `REVENGE_LV_MAX`, story names from L3]:
  - Rank 1: before `CLEARD_FIND_THE_SECRET_WEAPON`
  - Rank 2: before `CLEARD_RESCUE_HUEY`
  - Rank 3: before `CLEARD_ELIMINATE_THE_POWS`
  - Rank 4: before `CLEARD_WHITE_MAMBA`
  - Rank 5: before `CLEARD_OKB_ZERO`
  - Rank 6: afterwards
- Example: HEAD_SHOT caps are `0,1,2,3,5,7` across the six ranks; COMBAT and STEALTH are `0,1,2,3,4,5`; NIGHT_C is `0,1,1,1,1,1`.
- [MW] says some missions disable the system. This is confirmed: 16 mission IDs are in `NO_REVENGE_MISSION_LIST` (prologue, boss and setpiece missions, and so on).
- **Hard missions** ignore the player's levels and use the maximum for the rank-6 column plus `IGNORE_BLOCKED` [L1 `GetRevengeLv`, `revengeDefine.HARD_MISSION`].
- **When it updates:**
  - RP changes live during the mission.
  - Levels are recomputed and the tendency is applied only at **mission clear or abort** (`OnMissionClearOrAbort`, `UpdateRevengeLv`).
  - At the next mission start the enemy loadout is built from the *levels* (`DecideRevenge` -> `SelectRevengeType` -> `_CreateRevengeConfig`) and stays fixed for that mission.
  - Corollary: nothing changes mid-mission.
- **Random seed:** a new random value is rolled at each mission clear (`gvars.rev_revengeRandomValue`), and it picks among variants (for example, shotgun or machine-gun variant of COMBAT_n) [L1 `OnMissionClearOrAbort`, `_Random`, `_CreateRevengeConfig`]. This means the loadout is deterministic within a mission but varies between missions.
- **Decay on mission clear** [L1 `_ReduceRevengePointOther`, `REDUCE_POINT_TABLE`]:
  - Every counter except STEALTH, COMBAT and the scratch ones loses points.
  - NIGHT_S, NIGHT_C, SMOKE, LONG_RANGE and VEHICLE lose 10 at level 0 and 50 at higher levels.
  - HEAD_SHOT, TRANQ and FULTON lose `10*(level+1)`, capped at 50.
  - So a half level is the maximum natural decay per mission.
  - **Chicken Hat:** reduces everything else by 100 and also pushes STEALTH/COMBAT down (-20, -25 or -50 by level), and skips the tendency step. [MW] agrees.
- [MW] says "total ghosting (no enemy interaction) slowly decreases the system, rate unconfirmed". Code: the DRAW tendency table reduces levels at high levels. I did not find a separate "no interaction" rule. If both scratch counters are zero the tendency defaults to STEALTH [L1 `_GetMissionTendency`], which adds +25 stealth. That contradicts [MW]'s claim, and it is a point where sources disagree.

---

## 3. Full countermeasure list

All values are from `revengeDefine` [L1] unless noted. "x%" means the share of soldiers that get the item. A number means a count per command post (CP).

### Categories driven by the stealth counter (STEALTH_n)

| Level | Countermeasures |
|---|---|
| 0 | Low stealth state; weak hold-up reaction |
| 1 | Security cameras 100% |
| 2 | Decoys 100% (plus cameras) |
| 3 | Mines 100% (plus decoys, cameras); high stealth state |
| 4 | Plus active decoys, gun cameras, hold-up counter ("holdup high") |
| 5 | Special stealth state plus the above |

The per-level enabling thresholds are also named: `_ENABLE_CAMERA_LV=1`, `_ENABLE_DECOY_LV=2`, `_ENABLE_MINE_LV=3`.

### Categories driven by the combat counter (COMBAT_n)

| Level | Countermeasures |
|---|---|
| 0 | Low combat state |
| 1 | Soft (vest) armor 25%; shotgun x2 *or* machine gun x2 (random variant) |
| 2 | Armor 50%; shield x1; shotgun/MG x2 |
| 3 | Armor 75%; shield x1; heavy armor x1; strong weapons; "super reinforce" (vehicle/heli reinforcement) |
| 4 | Armor 100%; shotgun/MG x4; shield x2; heavy armor x2; 2 reinforcement calls |
| 5 | Armor 100%; shield x4; heavy armor x4; special state; 3 reinforcement calls; "black" super reinforce |

Notes:

- Heavy armor (riot suit) is downgraded to extra shields when the mission cannot show armor models [L1 `CanUseArmor` and the `_CreateRevengeConfig` comment "downgrade armor to shield"].
- Combos are excluded: shotgun excludes MG, shield excludes missile [L1 `revengeComboExclusionList`].
- Super reinforcement vehicles are only enabled in missions 03 and 35 and via heli elsewhere [L1 `USE_SUPER_REINFORCE_VEHICLE_MISSION`]. The player-wiki figure for the same ("missions 03 and 35") agrees.

### Other single-axis counters

| Counter | Levels | Countermeasure |
|---|---|---|
| HEAD_SHOT | 1-10 | Helmet 10% per level (L7 = 70%, L10 = 100%) |
| NIGHT_S | 1-3 | Night-vision goggles 25 / 50 / 75% |
| NIGHT_C | 1 | Gun-mounted flashlight 75% |
| LONG_RANGE | 1-2 | Snipers x2; L2 adds stronger sniper weapon |
| VEHICLE | 1-3 | Anti-vehicle missile launchers x2, x2 (strong), x4 (strong) |
| SMOKE | 1-3 | Gas masks 25 / 50 / 75% |
| FULTON | 1-3 | L1 low balloon shoot-down response, L2 high, L3 special. Retail bug: the table is shifted by one (comment `RETAILBUG` in [L1]). |
| TRANQ | 1 | Soldiers react more strongly to downed comrades (`STRONG_NOTICE_TRANQ`), i.e. they notice and call it in |

Level 7 helmet = 70% matches the Fandom wiki excerpt seen via search (unverified there, confirmed in [L1]). HEAD_SHOT can only reach level 7 in retail (rank-6 cap), so the 80-100% rows are unreachable except potentially in FOB. That is my inference from the cap table.

### Reinforcements (loadout of called-in soldiers) [L1 `ApplyPowerSettingsForReinforce`]

- Helmet chance equals headshot level / 10.
- Soft-armor and shotgun/MG chance is 50% at combat level 1-2, 75% at 3, 99% at 4+.

### Disagreement to flag

- [MW] says "only one category applies per mission: either stealth or combat". The retail loop in [L1 `SelectRevengeType`] iterates **all** counters and adds each one's `NAME_level` entry, so both a STEALTH_n and a COMBAT_n entry can apply together. In practice the tug-of-war table keeps one of them high, which is probably what [MW] observed. Treat [MW]'s "exclusive" claim as an approximation.

---

## 4. Counters the player has (the other half of the loop)

- **Dispatch (Deploy) missions** at Mother Base: each of 14 revenge-specific deploy missions blocks one countermeasure type (gas mask, helmet, camera, decoy, mine, NVG, shotgun, MG, soft armor, shield, armor, gun light, sniper, missile) for **3 missions** [L1 `DEPLOY_REVENGE_MISSION_BLOCKED_LIST`, `BLOCKED_FOR_MISSION_COUNT=3`].
- The block counter ticks down when the player returns to the helicopter space (`_ReduceBlockedCount`, `IsHelicopterSpace`).
- Each deploy mission only becomes available when the matching level has been reached (`DEPLOY_REVENGE_MISSION_CONDITION_LIST`; for example camera at stealth 1, decoy at stealth 2, mine at stealth 3).
- Hard missions ignore blocking.
- [GG] says dispatch missions are the temporary fix and "nothing can directly stop the adaptation". [ST2] says dispatches do not meaningfully lower preparedness. Both are consistent with the 3-mission block, which hides the gear but does not reduce points.
- **Chicken Hat** is the hard reset (see section 2).
- Natural decay plus playing a different style is the soft reset.
- **Wormhole Fulton** counters the balloon shoot-down response (player claim, [ST]).

---

## 5. How the game tells the player

All of the below is confirmed in [L1] / [L2] unless marked.

1. **Visible gear.** Helmets, NVGs, vests, shields, riot suits and gun lights are visible on soldiers once a mission starts. Because loadouts are fixed per mission, the player learns by seeing them.
2. **Map-screen / sortie icons.** `_SetUiParameters` sends six values to the UI, each 0-3: `fulton, headShot, stealth, combat, night, longRange` (`TppUiCommand.RegisterEnemyRevengeParameters`).
   - The 0-3 value is derived from the real level using the rank-4 and rank-5 caps as bands, so it is a coarse approximation [L1 `_GetUiParameterValue`].
   - Night shows the max of NIGHT_S and NIGHT_C.
   - Colors per [GG]: white (1), pink (2), red (3). [ST] says grey / white / red. The two player-written sources disagree. The 0-3 numeric scale is confirmed by code.
   - [GG] says the map icons highlight to show "the enemy have tried to counter your tactics". It also says what triggers each level is not explained anywhere in the guide.
3. **Guard chatter that foreshadows and then confirms.** `SetOccasionalChatList` [L2] builds the pool of idle soldier conversations and gates it on revenge state:
   - `*_revenge_08...12` lines play when a counter has **at least 50 RP but is still at level 0** (headshot, vehicle, long range, night). That is the "warning" phase, at half a level.
   - `*_counter_NN` lines play once the corresponding level is reached **and** the countermeasure is not blocked: mine, helmet, soft armor, shield, NVG, gun light, heavy armor, shotgun/MG, sniper, missile, decoy, and so on.
   - Coverage includes `revenge_01-07` for fulton, combat and stealth levels, and `counter_01-19+`.
   - Chatter is selected by level, so blocking a countermeasure with a dispatch mission silences its line as well. This is a neat trick: the information channel follows the actual state.
   - Each line exists in two variants with `USSR_` and `PF_` prefixes (one per enemy faction/region, my reading of the prefixes).
4. **Interrogation.** `_SetMbInterrogate` unlocks an interrogation topic per active countermeasure (fulton, gas, helmet, flashlight, sniper, missile, night-vision, camera, decoy, mine, shotgun, machine gun, body armor, shield, armor). A captured soldier can tell the player which counters his base has. Only enabled when the level has been reached and the item is not blocked.
5. **Ocelot / Miller briefings.** I found **no evidence** in code or sources that Ocelot or Miller explicitly briefs revenge status. The searched sources describe the map icons, guard chatter and interrogation, not a briefing. Player reception: several players never noticed the system until they felt the difficulty, and a few felt signalling was too weak [RE]. A defender noted "if you pay attention to enemy communications, they will tell you what they're doing and why" [RE].
6. **Preview framing.** Pre-release coverage described it with the helmet-after-headshots example [WP-TPP], which matches the code.

---

## 6. Staff and Mother Base side-effects (probably skip, noted for completeness)

- `_SetEnmityLv` converts max(STEALTH RP, COMBAT RP) into a staff "enmity" level for newly recruited staff (11 buckets, 500 RP -> top bucket) [L1]. Not relevant to Ghost Layer.

---

## 7. AI readability techniques (MGSV / Ground Zeroes / Peace Walker)

Evidence quality is lower here than for the revenge system; there is no first-party talk.

- **Detection indicator that fills with colour.** A Game Informer interview summary (via a secondary source in my search) says the on-screen indicator "fills with color as the enemy becomes more suspicious". Weak evidence: I could not retrieve the original. [WP-GZ] (citing reviews) says Ground Zeroes removed the gauge for alert/evasion/caution and replaced it with subtler visual and audio cues, and directional cues that show where a spotter is coming from.
- **Reflex Mode.** Triggers when an enemy spots the player; the player gets a short slow-motion window to take out the spotter before the alarm is raised [WP-GZ]. It can be turned off in options [MGI-3]. One summary describes a roughly three-second window (SlideShare review, unreliable). Marking is a separate system: marking is for avoiding detection, reflex helps after being spotted [MGI-1].
- **Marking replaces radar.** Per Kojima Productions Alert 007 (as summarized in [MGI-1]) the marking system exists because the Soliton Radar is gone. Players scout with binoculars, tag guards and plan an infiltration. Optional.
- **Alert phases.** [L1] shows the engine's phases: Sneak, and alert-level phases (code references `PHASE_SNEAK` and `PHASE_ALERT`). Only Sneak vs non-Sneak matters to the revenge logic. In Peace Walker the alert phase carried a numeric countdown (100) before dropping to evasion and then caution [SW, unverified excerpt]; Ground Zeroes dropped the on-screen clock in favour of listening to enemy callouts (a reviewer's phrasing, SlideShare repost, low trust).
- **Radio and callouts.** Alert-mode series convention: exclamation mark above the head, music change, request for backup [Metal Gear Wiki "Enemy status" via search excerpt, unverified]. In MGSV, guards' spoken callouts replace the clock.
- **Hard-mode AI.** Per Eyestone commentary, hard mode gives better vision and awareness so players are spotted from further away [MGI-2].
- **Peace Walker:** I found no first-party material on Peace Walker enemy-AI readability beyond [SW]'s phase description. Do not treat anything beyond that as established.

---

## Implications for Ghost Layer

Context: ~6 weeks, solo, PSone-style stealth, 3 Areas plus finale, requirement is classic game AI (no ML).

1. **Copy the core data model: 3-5 behavior counters with a 100-points-per-level scale, trigger table, and a per-level countermeasure table.** [L1] shows the whole thing is just a dictionary of `trigger -> counter +N`, a cap table, and `level -> loadout`. In GDScript this is about 150 lines and a Resource file.
2. **Pick 4-5 counters, not 10.** For example: stealth-kills (-> cameras, then decoys/mines), combat-kills (-> armor, shields), headshots/takedowns (-> helmets), night/dark-cover use (-> flashlights/NVG), and one "ranged" or "ghost layer ability" counter specific to the game's hook. MGSV's 12 are overkill for 3 Areas.
3. **Update only between missions, never mid-mission.** MGSV recomputes levels at mission end and builds the loadout at mission start [L1]. That keeps tuning, saving and debugging simple, and the player always sees a stable board.
4. **Copy the stealth-vs-combat tug of war, simplified.** One tendency decided per Area (by whichever scratch counter leads by a margin) adds points to one side and subtracts from the other. It prevents a "maxed everything" end state and gives a natural equilibrium. Skip the six-row-per-level tables; use two numbers.
5. **Tie caps to story/Area progress.** MGSV caps levels by story rank [L1]. For three Areas, use cap = Area index (or a 3-step table) so Area 1 is never brutal and the finale can force "max" like MGSV's `HARD_MISSION` [L1].
6. **Communicate in three layers, cheap to build:** (a) visible gear on guards, (b) one pre-mission icon strip (4-5 icons, 0-3 levels, same look as MGSV's six map icons [L1][GG]), (c) guard chatter lines gated on levels. Copy the foreshadow trick: play a "warning" line at half a level (50 RP) and a "confirmed" line at the level [L2]. Chatter is the highest value per effort.
7. **Give the player a counter and make it legible.** A single "lay low" action (like Chicken Hat / dispatch missions, for instance a mission modifier or an item) that hides one countermeasure for N missions. MGSV hides both the gear and its chatter together [L1][L2]. Skip a Mother Base-style dispatch economy.
8. **Adopt a spotted-state teaching pattern instead of reflex slow-mo if time is tight.** A color-filling detection meter and a callout plus a short grace window (or Reflex-style slow-mo as an option) is the readable-AI baseline [WP-GZ]. A simple filling meter with 3 discrete states (unaware / suspicious / alert) is enough; do not copy the full Sneak/Caution/Evasion/Alert plus timers set.
9. **Skip:** interrogation topics, staff enmity, FOB loadouts, reinforcement-vehicle tiers, per-CP random variants, hard-mission handling beyond one "finale = max" flag, and the retail-bug-compatible fulton table. Also skip the 10-level helmet curve; 3 levels (0 / 50% / 100%) reads the same to the player.
10. **Test-first on the numbers.** The reasons MGSV feels fair are in the tables (decay of up to half a level per mission, 25 RP/mission tendency). Put those in a small unit test (simulate 5 missions of "all headshots" and confirm the helmet rate climbs, then drops after a style change) so the tuning is checkable without playing.
