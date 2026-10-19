# 15: Rifle + suppressor + resupply crate

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The Operative carries a suppressed assault rifle whose suppressor breaks after 10 shots. After that, shots are loud and send guards to investigate, and a resupply crate restores ammo and the suppressor.

**Blocked by:** 09

**Status:** done

- [x] Key 2 selects the rifle; 30-round magazines, 60 total; one headshot or two body hits kill
- [x] The suppressor breaks after 10 shots (count on the weapon card); loud shots are heard at 40 m and send guards straight to suspicion at the shot position, never alert
- [x] Killed guards are Down; a guard who checks a dead body radios an alert
- [x] The rifle destroys security cameras
- [ ] A destroyed camera counts as a missing guard (blocked: no HQ poll exists yet; `SecurityCamera.destroyed` is ready to read)
- [x] E at the resupply crate restores ammo and the suppressor
- [ ] ...and item counts (blocked: items join with the Scanner and Magazine)
- [x] Aiming shows a crosshair at the screen centre (Pizza Doggy vol. 14, `assets/textures/crosshair_4_small.png`)
- [x] A different crosshair per weapon; the rifle is automatic (600 rpm) with camera recoil
