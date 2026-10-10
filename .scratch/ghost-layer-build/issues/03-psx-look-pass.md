# 03: PSX look pass

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The game looks modern-retro as decided in the PSX look prototype: low-resolution 3D upscaled with nearest filtering, 15-bit banding, far fog and chunky textures, while the HUD stays crisp.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] 3D renders at 854×480 with nearest upscaling at any window size
- [ ] A full-screen pass under the HUD rounds each channel to 31 levels, with no dither
- [ ] Far depth fog (about 20–60 m) in the sky colour; per-pixel lighting with shadows
- [ ] Greybox materials use 128 px nearest textures on world-space box UVs (about 2 m per tile)
- [ ] Press Start 2P and VT323 are imported with their OFL files; the textures and fonts have `CREDITS.md` lines
- [ ] No vertex snapping or affine textures
