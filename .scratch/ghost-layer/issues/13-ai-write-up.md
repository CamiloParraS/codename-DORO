# AI write-up

Type: grilling
Status: resolved
Blocked by:

## Question

What is the game AI write-up delivered with the build: format (document, slides, both), length, and sections? Which diagrams and evidence does it carry (the Profile + Lethality → `plan_mission` → Countermeasures flow, the guard behaviour tree, Glaukopis's judge, deployment tables for the preset profiles, debug overlay screenshots), and how does it fit the live presentation?

## Comments

- 2026-10-09 (from Architecture of the five Voices): the story is "a behaviour tree for guards, a utility AI for the commander, profiling feeding the commander". Aigis is deterministic, so the preset profiles give repeatable deployment tables to quote.
- 2026-10-09 (from Campaign plan): four fixed Presets (Clean slate, Ghost/Pallas, Trickster/Nike, Butcher/Gorgo) plus Custom, loadable on any Mission in Free mode. The Harbour in Mission 1 (no Countermeasures) versus the Core Mission (cap 3, budget 6) is the natural before/after pair for screenshots and the live demo.
- 2026-10-09 (from Narrative delivery): Glaukopis's line in the final debate reads the Spoofing level, so the Profile also surfaces in the ending.

## Answer

Settled in a grilling session (2026-10-09). No glossary changes.

**Deliverables:** the live demo plus one document. No slides. There's no rubric (the brief is just "a game with AI"), so the document stays at the minimum needed to show the idea.

**Format:** Markdown in the repo (`docs/write-up.md`), exported to PDF, written in Spanish. It's the last task of the project, roughly 4–6 pages.

**Sections:** sections 2, 5 and 8 are the core. The rest get a paragraph each.

1. El juego en una página: the premise, the loop, and the pillar "la adaptación debe verse".
2. Arquitectura de la IA: guards run a behaviour tree, the commander is a utility AI, profiling feeds the commander.
3. Guardias: the behaviour tree, perception, patrol→suspicion→alert→evasion.
4. Perfil del Operador: Habits, points, levels, rollback.
5. Aigis: Voices, sponsors, pinned Habit, greedy fill, budget.
6. Glaukopis: the Spoofing judge.
7. Letalidad → Voz Dominante → final.
8. Evidencia: deployment tables, before/after captures, debug overlay.
9. Límites y trabajo futuro.
10. Referencias: the MGSV Revenge research.

**Evidence:** a test suite runs `plan_mission` for each Preset × Mission and writes a Markdown table, which the write-up quotes, so the tables match the final tuning. Before/after captures: the Harbour in Mission 1 (Clean slate) vs the Core Mission. Debug overlay screenshots.

**Diagrams:** Mermaid for the architecture flow (Profile + Lethality → `plan_mission` → Countermeasures → guards) and the alert state machine. The guard behaviour tree is a screenshot of the LimboAI editor (the real tree, not a redrawing).

**Terms:** the Spanish names from the game's CSV translation (Hábitos, Contramedidas, Voces, Letalidad), with the code identifier in parentheses the first time each appears.

**Demo script:** a one-page appendix, about 10 min, that the evaluator can rerun in Free mode: Clean slate Harbour (empty base) → Butcher on the Core Mission (fortified, overlay with Voice weights, the briefing names the Habit) → Ghost (the deployment changes) → a live spoof with Glaukopis doubting → the ending screen.

**Cut line:** if time runs out, only sections 2, 5 and 8 plus the demo appendix.
