# 07: HUD E + detection arcs

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The player reads danger from HUD E: MGSV arcs pointing at each guard filling its meter, a red edge flash on alert, an ALERT/EVASION timer, plus HUD E's life bar, stance silhouette and compass.

**Blocked by:** 05

**Status:** done

- [x] Arcs around the screen centre per noticing guard, growing and warming with the meter, red on alert (lifted widget from the prototype)
- [x] Red screen-edge flash when an alert is raised
- [x] Right strip: ALERT/EVASION with its timer in red vertical text, stance silhouette, empty item and weapon card slots
- [x] Left: vertical life bar with "OPERATIVE" (the compass ring was later removed: it served no purpose)
- [x] Laid out on a 640×360 logical canvas, crisp at native resolution, white/grey palette
