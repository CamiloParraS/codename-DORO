# Metal Gear mechanics: gaps and changes (2026-10-28)

Compares classic Metal Gear stealth mechanics with what the game already does (read from the code and `.scratch/pw-feel/`), and lists what was applied. Series facts are from memory plus two general sources (GAMBIT Lab's Metal Gear design write-up, Giant Bomb's MGS page); they are not a rigorous study.

## Already in the game

Radar (sound-only), Codec and Hints, Knock, thrown Magazine, Scanner, Alert → Evasion → Caution chain with a stoppable Radio call, Partner reaction, Hold-up, Fulton and Recruits, Rank with Continue and Mission select, metal-floor footsteps, crouch/walk/run noise tiers, Crawlspaces.

## Suggestions

| # | Suggestion | Why it makes the game more Metal Gear | Status |
|---|---|---|---|
| 1 | First-person look: hold `Z`, camera to eye level, feet planted | A series signature. Lets the player read a guard's facing and patrol gaps before committing; it costs time because you cannot move. | Applied (`actors/operative/operative.gd`) |
| 2 | "zZz" over Neutralized guards | Sleeping guards read as asleep, so alive and due to wake in 90 s, instead of looking dead. Tells the player when to Fulton. | Applied (`actors/guard/guard.gd`) |
| 3 | Rank codenames: S Fox, A Doberman, B Jackal, C Pigeon | The series names ranks with animals; a name is a better reason to replay than a letter. | Applied (`ai/rank.gd`, `ui/post_mission/post_mission.gd`, test in `tests/test_rank.gd`) |
| 4 | Wall-hug and corner peek | The strongest remaining signature move; makes geometry matter. Needs wall detection, a pose and a peek camera. | Not applied: too risky before 2026-11-11; do it after |
| 5 | Guard item drops (rations, ammo) | Rewards non-lethal play. Needs pickup scenes and balancing; Requisition already covers rewards. | Not applied |
| 6 | Cardboard box, CQC, lockers, bosses | Very Metal Gear, but ruled out in `.scratch/pw-feel/map.md` (out of scope). | Not applied |

## Verification

`godot --headless --path . tools/run_tests.tscn`: 608 passed, 0 failed. Look and feel not play-tested; the first-person camera in particular is untested beyond the code paths running.

## Sources

- https://gambit.mit.edu/updates/2010/03/metal_gear_game_design_matryos_1.php
- https://www.giantbomb.com/wd/3030-16140
