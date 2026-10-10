# 07: HUD E + detection arcs

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The player reads danger from HUD E: MGSV arcs pointing at each guard filling its meter, a red edge flash on alert, an ALERT/EVASION timer, plus HUD E's life bar, stance silhouette and compass.

**Blocked by:** 05

**Status:** done

- [x] Arcs around the screen centre per noticing guard, growing and warming with the meter, red on alert (lifted widget from the prototype)
- [x] Red screen-edge flash when an alert is raised
- [x] Right strip: ALERT/EVASION with its timer in red vertical text, stance silhouette, empty item and weapon card slots
- [x] Left: vertical life bar with "OPERATIVE"; top right: compass ring whose N turns with the camera, no enemy dots
- [x] Laid out on a 640×360 logical canvas, crisp at native resolution, white/grey palette
