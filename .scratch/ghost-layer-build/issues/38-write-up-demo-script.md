# 38: Write-up + demo script

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** A 4–6 page Spanish write-up of the game AI, exported to PDF, quoting the generated deployment tables, with a ~10 minute demo script appendix the evaluator can rerun in Free mode.

**Blocked by:** 12, 32

**Status:** ready-for-agent

- [x] Sections 1–10 as in the spec, with 2 (architecture), 5 (Aigis) and 8 (evidence) as the core
- [x] Deployment tables quoted from the generated Preset × Mission output
- [ ] Mermaid diagrams for the architecture flow and the alert state machine; a LimboAI editor screenshot of the guard tree
- [ ] Before/after captures (Harbour Mission 1 under Clean slate vs the Core) and debug overlay captures
- [ ] Spanish terms from the game's translation, with the code identifier on first use
- [ ] Demo appendix: Clean slate Harbour → Butcher on the Core → Ghost → a live spoof with Glaukopis doubting → the ending screen

## Comments

- Draft is `docs/writeup.md` (Spanish, sections 1-10 plus Appendix A demo script). Tables in 8.2 are copied from `docs/deployment-tables.md` (Clean slate and Butcher in full; Ghost and Trickster Core rows only). The three Mermaid diagrams (architecture, alert state machine, Lethality chain) are written but not rendered here.
- Left unticked, needs a human: LimboAI editor screenshot, before/after captures, F3 overlay captures (all `TODO(humano)` in section 3 and 8.3-8.4), PDF export (no pandoc or mmdc in this environment; instructions at the end of the doc), page count check (4-6), and a timed rehearsal of the demo appendix.
- Spanish terms: used the game's names for Voices, Habits and Presets, but `text/lines.csv` still has placeholder es lines (ticket 37 not done), so check the terms against the final translation and add the code identifier on first use where missing.
- No playtest measurements were invented; section 8.5 is a TODO.
- Note for the capture plan: Harbour Mission 1 has budget 0 under every Preset, so the real before/after is Harbour under Clean slate vs the Core under Butcher.
