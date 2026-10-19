# Implementation Decisions: Guard behaviour and combat rules

- Navigation: bake the navmesh in the editor with a radius margin above the body's 0.35 m radius; use `path_height_offset`, not a large `path_desired_distance` (the prototype's workaround made guards cut corners into obstacles); consider turning on avoidance.
- Takedown: only on a guard who isn't alerted, within ~1.5 m, with the Operative outside the guard's front cone. Choke: 2 s, Operative exposed, Neutralizes. Kill: 0.5 s.
- Tranq: 4-dart magazine, 8 total, suppressor never breaks. Headshot Neutralizes at once; a body shot Neutralizes after ~3 s (the guard stumbles, is suspicious, and can't radio).
- Rifle: 30-round magazine, 60 total. One headshot or two body hits kill. The suppressor breaks after 10 shots; after that, shots are loud. Hitscan. Reload ~1.5 s, silent, automatic when empty; no reload while carrying.
- Neutralized guards wake after ~90 s; choking again resets the timer.
- Carry: E toggles it. A fixed pose attached to the shoulder bone, no ragdoll. Walk speed (slower crouched); one-handed tranq with worse accuracy; no Magazine throw.
- Open combat: guards shoot back, with hit chance falling with distance and when the Operative runs. The Operative dies after 4 hits and regenerates after 5 s without damage. Death restores the last Checkpoint.
- Knock: anywhere, 1 s cooldown.
- Every guard makes spontaneous radio check-ins every 20–30 s. They serve only as flavour and a Voiceprint source.
- All numbers here are tuned during the build.
