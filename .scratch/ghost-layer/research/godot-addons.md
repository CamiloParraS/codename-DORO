# Godot addons and built-ins for Ghost Layer (Godot 4.7)

Researched 2026-10-08. Project is on Godot 4.7 + Forward Plus (`project.godot`, `config/features=PackedStringArray("4.7", "Forward Plus")`). Godot docs cited are the 4.7 "stable" pages. Release data comes from the GitHub releases API of each repo.

"Supports 4.7" legend: **Confirmed** = release notes or README name 4.7. **Likely** = declared range covers 4.7 but no explicit 4.7 statement. **Unconfirmed** = nothing found.

## Summary table

| Need                  | Candidate                  | Latest release (date)  | 4.7 status                                                                                                |
| --------------------- | -------------------------- | ---------------------- | --------------------------------------------------------------------------------------------------------- |
| Behaviour trees + HSM | LimboAI                    | v1.8.1 (2026-08-20)    | Confirmed (v1.8.0 "Support Godot 4.7"); GDExtension zip is built against 4.6 and declared "4.6 or higher" |
| Behaviour trees       | Beehave                    | v2.9.3 (2026-08-18)    | Confirmed ("compatible with latest Godot 4.7")                                                            |
| Dialogue              | Dialogue Manager           | v4.1.0 (2026-09-04)    | Confirmed (v4.0.0 release titled "for Godot 4.7"; README says 4.6+)                                       |
| Tests                 | GUT                        | v9.7.1 (2026-07-10)    | Confirmed (9.7.0 "Godot 4.7 compatibility", branch `godot_4_7`)                                           |
| Tests                 | gdUnit4                    | v6.2.2 (2026-10-07)    | Confirmed (README table: 4.7, 4.7.1)                                                                      |
| Camera                | Phantom Camera             | v0.11.0.3 (2026-07-19) | Unconfirmed as a range (badge "4.4+"); one release fixes a 4.7.1 bug                                      |
| Camera                | SpringArm3D                | built-in               | Documented in 4.7 docs                                                                                    |
| Navigation            | NavigationAgent3D/Server3D | built-in               | Documented in 4.7 docs                                                                                    |

## 1. Behaviour trees / state machines

### LimboAI

- C++ plugin combining behaviour trees and hierarchical state machines, with BT editor, visual debugger and demo. Distributed either as a C++ engine module or as a GDExtension that works with stock Godot. [README](https://github.com/limbonaut/limboai)
- Licence: MIT-style; logo and demo art CC BY 4.0. [README, License section](https://github.com/limbonaut/limboai#license)
- Version table: `1.8.x` = GDExtension/AssetLib "Godot 4.6 or higher", Module "Godot 4.7". [README, Supported Godot versions](https://github.com/limbonaut/limboai)
- v1.8.0 (2026-06-19): "Support Godot 4.7". v1.8.1 (2026-08-20): engine builds updated to 4.7.2-stable. Release assets include 4.7.2 editor builds and `limboai+v1.8.1.gdextension-4.6.zip`. [releases API](https://api.github.com/repos/limbonaut/limboai/releases)
- 4.7 verdict: **Confirmed for the module build; the GDExtension is declared 4.6+ (so it should load on 4.7) but is built on 4.6 and no release note says it was tested on 4.7.** Smoke-test in the editor on day 1.
- GDExtension limits: "Documentation tooltips are not available"; the BBParam property editor is not available in the extension. Module build "offers a better editor experience and is slightly faster" but requires a custom engine build plus its own export templates. GDExtension is on the Asset Library; errors right after download are fixed by Project > Reload project. [Getting LimboAI docs](https://limboai.readthedocs.io/en/stable/getting-started/getting-limboai.html)
- Custom BT tasks and HSM states can be written in GDScript (README: "You can write custom behavior tree tasks and HSM states in GDScript"). The state machine has no GUI editor, it is set up in code. [README](https://github.com/limbonaut/limboai)
- Debugging: visual runtime debugger for BTs, runtime blackboard inspection added in v1.7.0. [README](https://github.com/limbonaut/limboai), [v1.7.0 notes](https://github.com/limbonaut/limboai/releases/tag/v1.7.0)
- Caveat: v1.7.0 notes say it is "not compatible with previous Godot versions", so the project must stay on 4.6+ (it is on 4.7, fine).

### Beehave

- Pure GDScript behaviour-tree addon, MIT, trees are nodes in the scene tree; has an editor debug view (Debugger V2 in v2.9.1) and a performance monitor. [README](https://github.com/bitbrain/beehave), [v2.9.1 notes](https://github.com/bitbrain/beehave/releases/tag/v2.9.1)
- v2.9.3 (2026-08-18): "compatible with latest Godot 4.7"; includes "Fix singleton conflict caused in godot 4.7.1" and debug monitor fixes. [v2.9.3 notes](https://github.com/bitbrain/beehave/releases/tag/v2.9.3)
- 4.7 verdict: **Confirmed**. Documentation inconsistency: the README compatibility table says Godot 4.5+ needs "2.10+", but the newest published release is 2.9.3 and `godot-4.x` branch `plugin.cfg` says `2.9.4-dev`. Use the 2.9.3 tag. [README](https://github.com/bitbrain/beehave), [plugin.cfg](https://github.com/bitbrain/beehave/blob/godot-4.x/addons/beehave/plugin.cfg)
- Release cadence is slow (2.9.2 was Dec 2025, 2.9.3 Aug 2026).

### Hand-rolled

- Not a source claim: a small GDScript state machine (enum + `match`, or node-per-state) is the standard minimal option and has zero version risk. For a stealth guard (patrol / suspicious / chase / search) 4 to 6 states is typical.
- Tradeoffs from the sources above: GDScript addons (Beehave) are readable and have no native binary, but give less tooling than LimboAI (which has a dedicated visual editor and debugger). A GDExtension adds a native binary that must match the engine's GDExtension ABI, which is why LimboAI ships a separate 4.6-built zip and per-version module builds.
- Requirement check: the project asks for "game AI such as behaviour trees/utility AI". A hand-rolled FSM alone may not read as a behaviour tree to graders; LimboAI or Beehave makes the BT explicit.

## 2. Dialogue Manager (Nathan Hoad)

- "stateless branching dialogue editor and runtime", MIT, README headline "Dialogue Manager 4 for Godot 4.6+". Older lines: v3.10 for 4.4/4.5. [README](https://github.com/nathanhoad/godot_dialogue_manager)
- v4.0.0 release is titled "for Godot 4.7"; latest is v4.1.0 (2026-09-04), `plugin.cfg` version 4.1.0. [v4.0.0](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.0.0), [releases](https://github.com/nathanhoad/godot_dialogue_manager/releases)
- 4.7 verdict: **Confirmed**.
- Codec fit: example projects exist for portraits and emotes/tags, speech balloons, and voices and translations; balloon scene is customisable, so a codec screen (portrait left/right, speaker name, text) is a custom balloon scene. [README, Example Projects](https://github.com/nathanhoad/godot_dialogue_manager)
- v4 renamed titles to "cues" and changed response-condition syntax (breaking vs v3). [v4.0.0 notes](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.0.0)
- v4.1.0 adds CSV export and UID import paths. [v4.1.0](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.1.0)
- Cost to skip: a hand-rolled codec could be a `Resource` array of `{speaker, portrait, line}` plus a `Control` scene. Dialogue Manager earns its place only if there is branching (choices) or conditions on game state; linear codec calls do not need it.

## 3. Tests: GUT vs gdUnit4, and what `godot_ai` expects

### What `addons/godot_ai` uses (inspected locally)

- `addons/godot_ai/plugin.cfg`: Godot AI, version 4.3.0.
- `handlers/test_handler.gd` header: "Discovers and runs McpTestSuite scripts from res://tests/". `testing/test_suite.gd` defines `class_name McpTestSuite extends RefCounted` ("Base class for MCP test suites ... add test_* methods, and drop the script in res://tests/"); `testing/test_runner.gd` defines `McpTestRunner`. Discovery rejects scripts that are "not a McpTestSuite subclass".
- No reference to GUT or gdUnit4 code anywhere in the addon, only a docs/example mention of a hypothetical third-party `gdunit4_mcp` addon in `custom_tools/mcp_custom_tool_spec.gd` (custom-tool name example "gdunit_run").
- Conclusion: `test_manage` / `test_run` use the addon's **own built-in framework (`McpTestSuite`)**, not GUT or gdUnit4. They run inside the editor over MCP. Tests written for GUT/gdUnit4 will not be discovered by them.

### GUT

- MIT, v9.7.1 (2026-07-10), per-Godot branches: 4.7.x = 9.7.1 (`godot_4_7` branch), 4.6.x = 9.6.1, 4.5.x = 9.5.0. 9.7.0: "Compatibility changes for Godot 4.7"; breaking change that doubles now return type defaults because Godot 4.7 type-checks returns more strictly. Doubles, partial doubles, stubs, spies, CLI runner. [README](https://github.com/bitwes/Gut), [v9.7.0](https://github.com/bitwes/Gut/releases/tag/v9.7.0)
- 4.7 verdict: **Confirmed**, but version-pinned: you must use the `godot_4_7` build, and each Godot minor needs a different GUT.

### gdUnit4

- MIT, v6.2.2 (2026-10-07), repo now at `godot-gdunit-labs/gdUnit4`. README table: v6.2.x and master support 4.5, 4.6 and 4.7 (4.7, 4.7.1); v6.1.x does not list 4.7. GDScript and C#, command line tool for CI, JUnit XML and HTML reports. [README](https://github.com/godot-gdunit-labs/gdUnit4), [releases](https://github.com/godot-gdunit-labs/gdUnit4/releases)
- 4.7 verdict: **Confirmed** (use 6.2.x). One version spans 4.5 to 4.7.

### Comparison for this project

- Both are MIT and 4.7-ready. gdUnit4 has an editor inspector, scene runner, and wider version range per release; GUT is lighter with a simpler API.
- Neither is needed to satisfy the MCP tools: `McpTestSuite` already runs from `res://tests/` through `test_run`. Third-party framework only matters if you want its mocks, scene runner, or CI.

## 4. PSX look

### Techniques (all achievable in a spatial shader, no addon required)

- Vertex snapping: round the clip-space or view-space `VERTEX` to a coarse grid in `vertex()`. Spatial shader exposes `VERTEX`, `MODELVIEW_MATRIX`, `PROJECTION_MATRIX`, and `skip_vertex_transform` for manual transform. [Spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- Affine texture warping: the spatial shader docs do not describe a built-in non-perspective-correct interpolation (the page does not mention `flat`/`smooth` qualifiers), so it is done by the shader trick of pre-multiplying UV by w (used by the implementations below). [Spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), [psx_visuals_gd4 README](https://github.com/scolastico/psx_visuals_gd4)
- Vertex lighting / unshaded: `vertex_lighting` ("Use vertex-based lighting instead of per-pixel lighting") and `unshaded` render modes. [Spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- Fog: a `FOG` output ("blends final pixel color with FOG.rgb based on FOG.a") or built-in environment fog. [Spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- Colour dithering / posterise: fullscreen-quad post-process reading `hint_screen_texture` (Godot 4 replacement for removed `SCREEN_TEXTURE`). Fullscreen-quad post-processing and screen texture are supported in all three renderers. [Spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Low internal resolution, two built-in ways:
  1. `SubViewportContainer` (Stretch on) + `SubViewport` with a small size; the container sets the displayed size. [Using Viewports](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html)
  2. `Viewport.scaling_3d_scale` below 1.0 with `scaling_3d_mode = NEAREST` (value 5, "Nearest-neighbor filtering with no extra rendering cost"). The docs do not say which renderers support it; test in the chosen renderer. [Viewport class](https://docs.godotengine.org/en/stable/classes/class_viewport.html)
- Debanding is irrelevant for a deliberately banded look; colour precision note: Compatibility is RGBA8 LDR, Forward+ is RGBA16F HDR. [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [3D rendering limitations](https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html)

### Existing open implementations

| Repo                                                                                                        | Licence (GitHub API) | Last push  | Notes                                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | -------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [scolastico/psx_visuals_gd4](https://github.com/scolastico/psx_visuals_gd4) (Asset Library #4687)           | MIT                  | 2026-04-13 | Vertex snap, affine, fog, post-process dithering via global shader uniforms; AssetLib lists "Shaders 4.1". Auto-apply swaps `StandardMaterial3D` at runtime and loses PBR maps (author's README says so and plans a conversion workflow). Godot 4.7 not stated. |
| [Zorochase/ultimate-retro-shader-collection](https://github.com/Zorochase/ultimate-retro-shader-collection) | MIT                  | 2026-08-30 | 5th-gen console shaders for Godot 4, vertex snap, affine, screen dithering; needs a `setup.gd` for global uniforms. Godot 4.7 not stated.                                                                                                                       |
| [MenacingMecha/godot-psx-style-demo](https://github.com/MenacingMecha/godot-psx-style-demo)                 | MIT                  | 2023-09-21 | Small demo of snapping, affine wobble and dithering; stale, useful as a reference only.                                                                                                                                                                         |

None state 4.7 explicitly; they are plain `.gdshader` files, so low risk, but verify visually. Reading the shader source and writing a ~40-line own version is realistic for a 6 week project.

### Forward Plus vs Compatibility (4.7 docs, [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html))

- Compatibility: "widest range of hardware", "Low base cost, but high scaling cost". Lacks CompositorEffects, SDFGI, volumetric fog, normal/roughness buffer, compute shaders.
- Forward+: "Highest base cost, and low scaling cost"; all of the above supported.
- Both support glow, fullscreen-quad post-processing, screen and depth texture. `texture_mipmap_bias` is Forward+/Mobile only. [Viewport class](https://docs.godotengine.org/en/stable/classes/class_viewport.html)
- A PSX look needs none of the Forward+-only features, and at ~320x240 internal resolution the "high scaling cost" is irrelevant. Compatibility would be lighter and broaden hardware, but the project is already configured for Forward Plus, and the in-editor tooling (godot_ai screenshot etc.) is already working with it. Switching later is possible because the renderer is a project setting, but shaders and any `SubViewport` setup should be validated again after a switch.

## 5. Third-person camera

- `SpringArm3D` is built in. Casts a ray, or a shape if `shape` is set ("When the shape is set, the SpringArm3D will cast the Shape3D on its z axis instead of performing a ray cast"), and "moves all its direct children to the collision point". `spring_length` is the max extent; `margin` default 0.01 is subtracted from the hit length; `collision_mask` default 1; `add_excluded_object(RID)` excludes the player's own body. [SpringArm3D class (4.7 docs)](https://docs.godotengine.org/en/stable/classes/class_springarm3d.html)
- Practical consequence: put the player on a layer the arm's mask excludes, or add the player RID to exclusions, otherwise the camera collapses onto the player. Use a small `SphereShape3D` so the camera does not clip through wall corners (a ray gives zero-thickness).
- Phantom Camera: MIT, README badge "Godot 4.4+", latest v0.11.0.3 (2026-07-19), whose only 4.7-related note is a fix for "an issue introduced in Godot 4.7.1" (autoload singleton unregistering). Its third-person mode wraps a SpringArm3D, so it adds no collision behaviour of its own. [README](https://github.com/ramokz/phantom-camera), [v0.11.0.3](https://github.com/ramokz/phantom-camera/releases/tag/v0.11.0.3)
- 4.7 verdict for Phantom Camera: **Unconfirmed as a declared range** (4.4+ badge, a 4.7.1 fix exists so it is actively tracked). Built-in SpringArm3D: documented in 4.7.
- Value of Phantom Camera is camera blending between cameras (cutscenes, codec zoom-in), not basic follow.

## 6. Navigation

Built-in, 4.7 docs: [NavigationAgent3D usage](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html), [NavigationAgent3D class](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html), [NavigationServer use](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationservers.html).

- Agent "never moves the parent itself"; set `target_position`, call `get_next_path_position()` once each `_physics_process`, move with your own code. Stop calling it when `is_navigation_finished()` is true, to avoid jitter.
- Gotcha, first frame: "At the start of the game, a new scene or procedural navigation changes any path query to a NavigationServer will return empty or wrong." Queries made in `_ready()` can return an empty path (agent looks "finished"). Wait until the map has synced (check `NavigationServer3D.map_get_iteration_id()` or defer / wait a physics frame). Awaiting `physics_frame` directly in `_ready()` "might get stuck", use `call_deferred`.
- Gotcha, deferred changes: "most NavigationServer changes take effect after the next physics frame and not immediately", so same-frame reads can be stale (e.g. after moving a navigation region or toggling obstacles).
- Gotcha, fast agents can overshoot `path_desired_distance` and backtrack; raise the distance values.
- Gotcha, avoidance: needs `avoidance_enabled` and the `velocity_computed` signal; set a target even when only avoiding, otherwise `safe_velocity` is zero; avoidance "has a significant performance cost" with many agents and "does not affect pathfinding".
- `waypoint_reached` callbacks must not call path methods recursively (use physics step or defer).
- Height: `path_height_offset` does not influence the navmesh or query; `height` is ignored when `use_3d_avoidance` is on.
- Patrols: a loop of `Marker3D`/`Path3D` points plus one `NavigationAgent3D` per guard is enough; waypoint advance is your own state-machine/BT task. No addon is needed.
- Not found in these pages: anything specific to 4.7 behavioural changes in navigation. Not researched: baking workflow (`NavigationRegion3D` + `NavigationMesh` bake options) beyond the above.

## Recommendation for Ghost Layer

| Need                 | Pick                                                                                                                                                                                                                                                                                                | Reason                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AI / behaviour trees | **LimboAI 1.8.1 (GDExtension from Asset Library)**, with a hand-rolled fallback FSM for trivial states only                                                                                                                                                                                         | Gives the explicit behaviour-tree plus HSM that the course requirement names, with a visual debugger and runtime blackboard inspection, MIT, 1.8.x declared for Godot 4.6+ and the module line explicitly targets 4.7. Risk: the GDExtension zip is built on 4.6 and not stated as 4.7-tested, so open the project and run a 3-node BT in week 1. If it fails to load, fall back to Beehave 2.9.3 (pure GDScript, explicitly 4.7-compatible). |
| Dialogue / codec     | **No addon; a small `Control` scene driven by a `Resource` array** (speaker, portrait, line)                                                                                                                                                                                                        | Codec calls are linear. Dialogue Manager 4.1.0 is 4.7-confirmed and the right choice only if branching choices or state-conditioned lines appear in the design; adopt then.                                                                                                                                                                                                                                                                   |
| Tests                | **Built-in `McpTestSuite` in `res://tests/` (run via `test_run`)**; add gdUnit4 6.2.x only if you need mocks or a scene runner                                                                                                                                                                      | The installed `godot_ai` test tools only discover `McpTestSuite` scripts, not GUT or gdUnit4. That already satisfies agent-driven testing at zero install cost. gdUnit4 6.2.x is the 4.7-confirmed fallback, preferred over GUT because one version covers 4.5 to 4.7.                                                                                                                                                                        |
| PSX look             | **Own spatial shaders (vertex snap + affine UV, `vertex_lighting`, fog) + a fullscreen dithering pass, with a `SubViewport` or `scaling_3d_scale` with NEAREST for low resolution**; read `scolastico/psx_visuals_gd4` or `Zorochase/ultimate-retro-shader-collection` (both MIT) as reference only | Everything needed is in built-in shader features. The MIT repos are useful for reference, but none states 4.7 and the former's auto-apply drops PBR maps.                                                                                                                                                                                                                                                                                     |
| Renderer             | **Stay on Forward Plus**                                                                                                                                                                                                                                                                            | No PSX technique needs Compatibility, resolution is tiny, the project is already set up. Revisit only if the target machine is weak.                                                                                                                                                                                                                                                                                                          |
| Camera               | **Built-in `SpringArm3D` with a sphere shape, player excluded**                                                                                                                                                                                                                                     | Covers collision. Phantom Camera adds blending only, and its 4.7 support is unconfirmed (4.4+ badge). Add it only if you need cinematic camera transitions.                                                                                                                                                                                                                                                                                   |
| Navigation           | **Built-in `NavigationAgent3D` per guard with waypoint markers**                                                                                                                                                                                                                                    | Meets patrol needs. Handle the first-frame sync (defer the first path query) and call `get_next_path_position()` once per physics frame.                                                                                                                                                                                                                                                                                                      |

Open items to verify empirically in the project: (1) LimboAI GDExtension loads and runs on 4.7 editor, (2) `scaling_3d_mode = NEAREST` behaves as expected in Forward Plus for the pixelation, (3) the exact `affine` UV trick in 4.7 shader compiler (copy from the MIT reference repos).
