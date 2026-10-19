# Implementation Decisions: Architecture (ADR-0001)

Three layers. Each pure module is node-free and deterministic; scenes gather facts, call the module, and only read its results.

1. **Guards:** a LimboAI behaviour tree per guard. It reads a pure **guard alert state machine** module for its state.
2. **Glaukopis:** a pure in-Mission **Spoofing judge**. It is the only Aigis logic in the field and is unaffected by Voice weights.
3. **Aigis:** a pure, between-Missions **campaign module** that owns the Profile and Lethality rules and the Voices' utility planning.

Adding Voice behaviour inside a Mission later would be a new seam (feeding weights into the guard tree), not a tweak.
