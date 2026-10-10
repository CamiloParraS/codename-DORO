# Narrative delivery

Type: grilling
Status: resolved
Blocked by: 09

## Question

How is the story told without cinematics: codec (portraits + text), briefings and debriefings, the Voices' comments about the Operative's habits, the final debate among the Voices, and the three endings plus the optional Metis epilogue. How much text is realistic in 6 weeks, and which tool is used (Dialogue Manager or custom)?

## Comments

- 2026-10-09 (from Operator profile and countermeasures): guard chatter carries the Profile: a warning line at 50 points before a level, and a confirmation once a Countermeasure is deployed. That's about 24 sets of lines (6 Habits × 3 steps × warning + confirmation, some shared). Plus HQ polls ("<X>, report"; "Nobody's seen <X> in a while") and Spoofing callbacks on the radio.
- 2026-10-09 (from Architecture of the five Voices): Voices speak only in briefings, on the post-Mission screen and in the ending, never during a Mission. Lines needed: Pallas naming each Habit; a hint from the sponsoring Voice per Countermeasure step; a Dominant Voice briefing close per band (Pallas / Nike / Gorgo); Nike's line when the noisy choke is deployed; 6 post-Mission lines (band × no deaths / deaths this Mission); three endings decided by the Dominant Voice after the core (Pallas doubts its doctrine, Nike's cold calculus, Gorgo's fortress). The final debate can stage the Dominant Voice winning.
- 2026-10-09 (from Campaign plan): premise is a private security contractor's coastal compound defended by Aigis; Metis is hired to find out what Aigis is. Areas: Harbour, Radio relay station, Research annex; the Core sits under the Harbour. Lines needed: intel contents (Mission 1 manifests point to the relay; Mission 3 reveals the Core under the Harbour); HQ's "Relay's offline. All units, sweep the station."; tutorial prompts in Mission 1 with one Metis radio line each; the three Targets as characters (relay chief, lead researcher, Palladion's security director). The ending plays at the Core terminal right after the Operative deals with the director, beside Aigis.

## Answer

Settled in a grilling session (2026-10-09), checked against the draft [pitch](../../../docs/pitch.md). The pitch is a draft: where it disagrees with decisions already on the map (the player leads Metis, the band → Voice mapping), the map wins. New glossary terms: **Briefing**, **Codec call**, **Final debate**, **Epilogue**.

**Language and tooling**

- **English source, Spanish translation.** Godot's built-in CSV translations: one `text/lines.csv` (`keys,en,es`), `tr(key)` everywhere, a language switch in options (default from the OS locale, switchable live for the presentation). Press Start 2P and VT323 already cover every Spanish glyph.
- **No sentences assembled from fragments.** Only proper names are slotted in (`{target}`). A line that names a Habit gets one full line per Habit, because Spanish gender and number agreement breaks templates.
- **No Dialogue Manager.** Nothing branches on player choice. A Codec call is plain data, an ordered list of `[speaker, key]`, played by one small custom codec/subtitle player. Which lines play is chosen in code (`plan_mission`'s briefing keys, band × deaths, Habit variants).
- **Keys are namespaced by use:** `brief.pallas.habit.headshots`, `chatter.headshots.2.warn.a`, `codec.m2.03`, `end.gorgo.04`.

**Cast on the radio**

- Metis has two voices: a **handler** (objectives, tutorial, orders) and an **analyst** (intel, Target dossiers, the "what is Aigis" thread). The Operative gives terse replies in Codec calls and never speaks in the field.
- **Portraits** are in-engine renders of the character models put through the PSX pass, not stock photos of people.
- **Targets:** an analyst dossier in the pre-Mission codec, plus 2–3 lines of chatter with their escort on their route. The director gets one subtitle line when the Operative enters the Core room, said to Aigis, not to the Operative. No "spare me" scene: Lethality stays silent.

**Flow per Mission**

Briefing (non-diegetic: the player overhears Aigis, Metis never does) → full-screen paused Codec call (handler gives the objective, analyst gives the dossier, ~6–10 lines) → Mission → post-Mission screen (Aigis's only; no Metis debrief).

- **In-Mission live calls** (subtitles + CALL bar): Mission 1 tutorial prompts, intel pickups, relay offline, the Core lift opening.
- **Field text:** radio traffic (HQ polls, Report in, callbacks, relay offline) as bottom subtitles with the speaker's name, heard anywhere. Guard-to-guard chatter as subtitles only within hearing range (the existing hearing radius), never floating above heads. 2 variants per set.

**Story beats** (intel pickups + 1–2 analyst lines each, inside the codec budget)

The compound sits on an ungoverned island zone. Metis was hired by a Palladion whistleblower.

| Mission | Reveals |
|---|---|
| 1 Harbour | Manifests point to the relay; the client is a whistleblower |
| 2 Relay | The relay broadcasts AI-generated news: **Synthetic Content Inflation**, manufacturing the crises Aigis gets deployed to |
| 3 Annex | Aigis was built from **dead commanders' memories**; the Core is under the Harbour; Palladion is about to give Aigis full authority over defense networks |
| Core | The analyst's plan: feed it fabricated memories, "the same trick it uses on the world". The global seizure is mentioned as the stakes, never shown |

Pre-Emptive Escalation shows up through Promachos's lines.

**Finale** (at the Core terminal, right after the director)

1. **The last Spoofed transmission:** the radial radio menu opens one last time with a single order, "Transmit memories", in slowed time. It's scripted and can't fail: the outcome follows Lethality, not skill.
2. **Final debate:** a full-screen text scene, no portraits; each Voice has a name and a small glyph. Each Voice's stance is fixed by its doctrine: Promachos rejects the memories; Nike asks only whether accepting them wins; Pallas weighs them; Gorgo asks whether they protect Palladion's people; Glaukopis gives an authenticity verdict that varies with the Operative's Spoofing level (0–3). One line per Voice per band; the Dominant Voice speaks last and settles it.
3. **Ending** (4–6 lines, the last one addressed directly to the Operative, the only time Aigis speaks to them):
   - **Pallas** (low Lethality): the memories hold, Aigis doubts its doctrine and **shuts down**, and the region it held burns without it.
   - **Nike** (mixed): cold calculus says it's a draw. Aigis goes **dormant**, aware of what it nearly did and of what was done to convince it.
   - **Gorgo** (high): it shields itself from the anomaly as noise and the **shutdown fails**: "You are not the exception you're claiming to be."
4. **Epilogue:** one short paused Codec call per ending (handler + analyst, ~4 lines). The shared twist: **Metis profits from the escalated war**, and the new conflicts are its next contracts. The ending colours the tone. If the epilogue is cut, the twist survives as a single text card.

**Stock footage**

Used only in the ending sequence (debate, endings, epilogue) and in an optional premise **intro** if one ever gets built. Never in Briefings, Codec calls or the field. PSX-processed stills with a slow pan/zoom plus at most 2–3 short loops, from Pexels/Pixabay, each with a `CREDITS.md` line. Video is converted to Ogg Theora (`.ogv`) for VideoStreamPlayer.

**Writing and budget**

- The user writes the Voices (Briefings, post-Mission lines, final debate) and the endings. An agent drafts everything else and the full Spanish translation; the user proofreads the Spanish.
- **Cap of 3,500 source words** (~225 narrative lines + ~80 UI strings per language):

| Block | Lines |
|---|---|
| Guard Profile chatter | ~48 |
| HQ radio | ~20 |
| Target chatter + director | ~10 |
| Tutorial | ~12 |
| Codec calls | ~40 |
| Briefings | ~37 |
| Post-Mission | 6 |
| Final debate | ~20 |
| Endings + epilogue | ~30 |

- **Cut order:** (1) the intro, (2) the epilogue, shrinking to the twist card, (3) chatter variants from 2 to 1, (4) Target chatter, (5) the debate shrinks to the Dominant Voice alone. Never cut: Briefings, post-Mission lines, endings, Profile chatter (warning + confirmation).

**Handed to other tickets**

- Architecture of the five Voices: the ending *content* now follows the pitch's outcomes (see the comment there); bands, weights and deployment are unchanged.
- AI write-up: Glaukopis's final-debate line reads the Spoofing level, one more place the Profile surfaces.
