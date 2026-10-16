# 21: Spoofing Countermeasures

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Spoofing ladder makes deception need more preparation: a stricter Glaukopis, radio callbacks to the speaker, and single-use Voiceprints.

**Blocked by:** 11, 13

**Status:** ready-for-agent

- [x] L1 drops the exposure threshold from 40 to 25 (tested)
- [x] L2: after a transmission, the recipient radios the speaker; a speaker who is alive and up denies it, which exposes the transmission; a Down speaker doesn't answer (the +60 rule only if some guard knows)
- [x] L3: a Voiceprint is flagged after one use, exposed or not (tested)
