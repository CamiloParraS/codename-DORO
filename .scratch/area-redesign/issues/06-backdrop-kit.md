# Backdrop kit

Type: grilling
Status: resolved
Blocked by: 04

## Question

Which pieces make up the shared Backdrop kit (sea plane, cliffs, distant building blocks, skybox, fence and lights, and so on)? How is it placed around each Area's outline? How does it stay cheap: PSX textures, far fog, no collision past the boundary?

The Harbour's outline is now the Tanker berth: the sea to the east and south (the moored freighter is play space, not Backdrop), the cliff to the west, and the fence and road gap to the north.

Also settle how the playable boundary reads to the player through water, cliffs or fences, without invisible walls.

## Answer

A shared kit of six no-collision pieces in `areas/backdrop/`, hand-placed per Area under a `Backdrop` node.

- **Pieces:** sea plane (flat, unlit, scrolling UV), cliff wall, distant block (box silhouette), skyline strip (far ring of boxes, no skybox texture), fence run, horizon sky (the flat colour plus an optional gradient). Skipped: lights, a skybox texture, trees, props.
- **Source of the pieces** (from `_raw/INVENTORY.md`). Only what is copied into `assets/` gets a `CREDITS.md` line.
  - Fence run: `all_fences.zip` (valsekemarplant, CC0), plus `Cones & Barriers.zip` for kerbs and road-gap barriers.
  - Distant block and skyline strip: Kenney City Kit Industrial (CC0), kept as far, fogged silhouettes. `Industrial_exterior_v1` (godgoldfear, CC BY 4.0) is an alternative that needs attribution.
  - Cliff wall, sea plane, horizon sky: primitives with the existing 128 px stone texture. No asset covers these.
  - Pizza Doggy PSX Mega Pack has no exterior scenery. It is for play-space props, which is a later effort. Its licence is proprietary, so read `License Agreement.pdf` before copying anything.
  - Retro Tree Pack (Pizza Doggy) is an optional extra for a treeline. Skipped for now.
- **Placement:** each Area scene hand-places kit scenes along its own outline. There's no scatter script, since three Areas don't justify one, and hand placement aims at specific sight lines.
- **Fog:** each Area overrides the shared fog (`ui/psx_look/psx_look.gd`, currently 20–60 m) and defaults to the shared sky colour. The Harbour starts at `FOG_END` ≈ 140 m so the Backdrop reads as dark silhouettes instead of detail.
- **Cost rules:** no collision and no navmesh in the Backdrop; one shared PSX material per piece from the existing 128 px textures; a `Backdrop` group so a test can assert no piece has a `CollisionObject3D`.
- **Boundary without invisible walls:** real collision that matches the visible edge: quay kerb, bollards and railings, solid cliffs taller than a jump, solid fences. A kill/return-to-Area volume is added only where the sea is reachable by dropping: the south pier tip and the freighter's stern.
- **Stealth:** the Backdrop is purely visual. Guards never react to it, so Approaches and Countermeasure placement don't depend on it.
