# Core stealth feel prototype

Type: prototype
Status: resolved
Blocked by:

## Question

With a Peace Walker-style third-person camera, does the stealth read well and feel good? Specifically: a camera that doesn't get stuck on walls, guards with readable vision/hearing, alert states (patrol → suspicion → alert → evasion → back), and whether the player understands why they were spotted. Includes testing an MGSV-style detection indicator.

## Comments

- 2026-10-09: playable prototype at `res://areas/proto_stealth/` (open `proto_stealth.tscn`, F6). Throwaway; it moves to branch `prototype/stealth-core` once the verdict is in. The alert state machine is node-free in `proto_alert.gd`, so it can be lifted out later. Waiting for the playtest.
- 2026-10-09: playtested. Prototype captured on branch `prototype/stealth-core` and removed from main.

## Answer

Yes: the stealth reads well and feels good with the Peace Walker-style camera. Validated as the baseline for the spec:

- **Camera:** over the shoulder, built from two `SpringArm3D`s (a sideways shoulder arm, then the back arm, each with a sphere shape and the Operative excluded). Tab swaps the shoulder, and that's enough to handle walls that crowd one side. The body hides when the camera gets very close.
- **Vision:** a front cone (30° half-angle, 16 m) plus a short peripheral cone (60°, 6 m, half the fill rate). Line of sight is a ray to the chest, so crouching behind low cover hides you. The meter fills faster with distance, stance (crouched ×0.5) and motion (still ×0.6, walking ×1, running ×1.5), and up close (<3 m) it fills ×4. Guards are understandable **without** visible vision cones.
- **Hearing:** running footsteps carry 6 m, and a knock carries 10 m (no wall occlusion). Noise only makes a guard suspicious, never alerts it.
- **Alert states:** patrol → suspicion ("?", a 1 s turn-and-look beat, then investigate, 5 s look-around) → alert ("!", red screen-edge flash, a radio call puts every guard on alert) → evasion (search the last known position for 12 s; sight there means alert again) → patrol. The timings felt right as they are (meter at 0.35 = suspicion, drains 0.25/s, alert lost after 3 s unseen).
- **Detection indicator:** **MGSV arc + head marks.** Arcs around the screen centre point at each guard that is filling its meter, growing and warming in colour as it fills, and turn red on alert. Also "?" and "!" over guards' heads. Beat the head-meter and marks-only versions.
- **Why you were spotted:** the player understands it even without the reason feed, so the feed stays a debug-overlay feature, not a HUD requirement.
- **Logic shape:** the alert state machine is a pure, node-free module (`proto_alert.gd` on the prototype branch: `tick(delta, seen_rate, seen_pos, why, at_target)`, `hear()`, `radio()`, each returning a reason string). It can be lifted into the real guard.
- **New idea (fog, not decided):** visible vision cones as a HUD **gadget** the Operative can use, instead of always on.
- **Godot gotcha:** a NavigationAgent3D's `path_desired_distance` must be greater than the navmesh's height above the floor (~0.5 m), or the agent never advances along its path.
- **Known issue, guard pathing (build work, not a decision):** guards that are alerted or searching hug walls and obstacles and sometimes try to walk through them. Likely cause (not verified): the prototype works around the height gotcha with a 1 m `path_desired_distance`, so guards jump to the next path corner early and cut diagonally into obstacles, worse at alert speed (4.5 m/s). The navmesh is also baked at runtime for a 0.5 m radius while the body is 0.35 m, and avoidance is off. For the real guard: use `path_height_offset` instead of a large desired distance, bake the navmesh in the editor with a radius margin above the body, and consider turning on avoidance. Built-in navigation is enough; no addon needed.
