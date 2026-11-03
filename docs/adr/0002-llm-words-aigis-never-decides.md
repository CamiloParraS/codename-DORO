# An LLM words Aigis's comments and never decides anything

After each Mission a language model (Gemini, through `missions/llm_client.gd`) writes Aigis's comment on the run: up to three lines in one Voice. It is shown on the post-Mission "What Aigis saw" page and opens the next Briefing. The model is given only what Aigis already decided (`AigisVoice.facts`: the tally, the Dossier's hotspot, bet and dropped Habit, the callsign, and the next plan's Countermeasures). It changes nothing: `Aigis.plan_mission`, the Dossier, guards and Glaukopis stay the only sources of what happens. We chose this over letting a model steer the plan or the guards because a model's answer is slow (seconds), differs from run to run, and can't be unit-tested. Running it between Missions keeps the slow call behind the outro and the Rank page, and keeps ADR 0001's rule that nothing changes during a Mission.

## Consequences

- The game is complete without the model. A Dossier fallback (`AigisVoice.fallback`) is written into `record.last.analysis` before the request is sent. The model's reply replaces it only if it passes `AigisVoice.parse`: valid JSON, one of the five Voices, 1–3 short lines, and no number the facts don't hold. If there is no key, no network, a timeout, or the suite or a playthrough is running headless, the fallback stays.
- The suite stays deterministic: tests cover the facts, the checks, the fallback and the Gemini request and reply shapes, never the network.
- The key is the player's own (Settings, or `GEMINI_API_KEY` on a developer's machine), stored in plain text in `user://settings.json`; it is never in the repo or an exported build. Gemini's free tier may use the prompt, which holds only game stats.
- Adding a second provider means one more body/text pair in `LlmClient`. Letting the model touch the plan or the guards later would reverse this ADR, not extend it.
