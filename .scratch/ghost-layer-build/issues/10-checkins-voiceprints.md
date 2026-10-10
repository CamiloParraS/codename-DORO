# 10: Check-ins + Voiceprint capture

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Guards radio routine check-ins, which show as subtitles and a ((·)) mark, and the Operative records a guard's Voiceprint by staying close during one.

**Blocked by:** 05, 07

**Status:** done

- [x] Every guard checks in every 20–30 s; ((·)) over the head while talking
- [x] Radio lines show as bottom subtitles with the speaker's name: the last two lines, fading after ~6 s
- [x] Staying within 6 m for 2.5 s of check-in audio records the Voiceprint; partial progress carries over between check-ins
- [x] HUD "VP" line under the compass lists the held Voiceprints
