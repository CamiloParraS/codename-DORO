# Addons and Godot 4.7 compatibility

Type: research
Status: resolved
Blocked by:

## Question

Which addons or built-in features fit a third-person stealth game in **Godot 4.7**, and do they officially support 4.7?
- Behaviour trees / state machines: LimboAI vs Beehave vs writing them by hand.
- Dialogue/codec: Dialogue Manager (Nathan Hoad).
- Tests: GUT vs gdUnit4 (and which one the installed `addons/godot_ai` test tools use).
- PSX look: shader techniques (vertex snapping, affine textures, dithering, low resolution via SubViewport), and whether Forward Plus or Compatibility suits it better.
- Third-person camera: SpringArm3D and collision, built-in vs addon.
- Navigation: NavigationAgent3D / NavigationServer3D for patrols.

Output: `.scratch/ghost-layer/research/godot-addons.md`

## Answer

- AI: LimboAI 1.8.1 (GDExtension; 4.6+ declared, module build explicitly 4.7, so smoke-test on day 1); Beehave 2.9.3 (4.7 confirmed) is the fallback.
- Tests: `godot_ai` test tools run its own `McpTestSuite` from `res://tests/`, not GUT/gdUnit4. Use that; gdUnit4 6.2.x (4.7 confirmed) only if mocks are needed.
- Built-ins suffice for PSX look (own shaders + SubViewport/NEAREST scaling, stay on Forward Plus), SpringArm3D camera (Phantom Camera 4.7 unconfirmed), and NavigationAgent3D patrols (defer first path query).
- Dialogue Manager 4.1.0 is 4.7-confirmed but only worth adopting if codec calls branch.

Full findings with citations: [research/godot-addons.md](../research/godot-addons.md)
