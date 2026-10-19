Type: grilling
Status: resolved
Blocked by: -

## Question

What is the audio direction? One music cue per alert state? Which sounds are gameplay (footsteps/knocks heard by guards, already in ticket 06) vs. mood? Bus layout and mix priorities. Input: audio-packs research if finished.

## Answer

- **Music:** patrol is ambience only (sea, wind, hum). Alert and Evasion get one music track each. Suspicion gets a sting only, no music change. Two music files total.
- **Multiple guards:** the highest guard state drives music; a state change holds at least ~2 s to stop flicker.
- **Stings:** suspicion "?" blip, alert hard `!` sting, and a relief cue when Evasion ends. The `!` sting pairs with the hit-stop prototyped in the alert-loop ticket.
- **Sound tiers:** (1) gameplay sounds guards hear: running footsteps, knock, Magazine landing, loud shot; (2) player-only feedback: UI clicks, codec beeps, pickups; (3) ambience. Only tier 1 feeds guard hearing. A world noise-ring cue at the source (thrown Magazine, knock) is deferred to a later ticket.
- **Mix:** Master → Music, SFX, UI/Codec, Ambience. Music ducks ~6 dB during a codec call. PSX bitcrush on SFX only. Per-bus sliders feed the settings ticket (build 33).
- **Voices:** text with a per-character blip, a different pitch per Voice (Promachos, Nike, Pallas, Gorgo, Glaukopis). No recorded or TTS voice.
