# 01: Project skeleton + LimboAI smoke test

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The project is ready to build on. Every binding from the spec's input table exists as a named InputMap action, LimboAI is enabled and proven to run a behaviour tree on Godot 4.7 (or the switch to Beehave is made and recorded), and the test suite runs green.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Every action in the spec's binding table exists in the InputMap; F8 is unbound
- [x] LimboAI is enabled and a trivial behaviour tree ticks in a scene on 4.7 without errors; if it fails, Beehave replaces it and the decision is noted on the map
- [x] One McpTestSuite test runs and passes from the tests folder
- [x] LimboAI has a `CREDITS.md` line
