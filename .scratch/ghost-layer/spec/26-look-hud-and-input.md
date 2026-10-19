# Implementation Decisions: Look, HUD and input

- 3D at **854×480** with nearest upscaling; no vertex snapping or affine textures; per-pixel lighting with shadows; a full-screen 15-bit banding pass (31 levels per channel, no dither) under the HUD; far depth fog (20–60 m); 128 px nearest textures on world-space box UVs (~2 m per tile), with geometry subdivided every ~2 m.
- HUD laid out on a 640×360 logical canvas at native resolution. **HUD E:** left, a vertical life bar, "OPERATIVE" and a slot number; right strip, ALERT/EVASION + timer, a stance silhouette, an item card (name + count/charges) and a weapon card (pip column for the magazine, suppressor count, reserve). A compass ring top-right with no enemy dots. A "VP A B" Voiceprint line. The MGSV arcs and ?/! marks. The radial, codec and post-Mission screen share E's white/grey palette. Press Start 2P for labels, VT323 for text.
- Bindings, all through named InputMap actions (no rebinding; the pause screen lists them):

| Verb | Binding |
|---|---|
| Move / walk / crouch | WASD (runs by default) / hold Shift / C or Ctrl toggle |
| Shoulder swap | Tab |
| Aim / fire | hold RMB / LMB (no hip fire) |
| Weapons / reload | 1 tranq, 2 rifle / R |
| Items | wheel cycles, F uses (Scanner tap; Magazine hold-arc-release, RMB cancels) |
| Interact | E: choke, carry toggle, crate, sabotage |
| Kill takedown | X |
| Knock | V |
| Radio radial | Q toggle; mouse points, LMB confirms, RMB back, 1–9 shortcuts, Q/Esc close |
| Codec advance | LMB / Space / Enter |
| Pause / debug | Esc / F3 |

  F8 stays unbound (it stops a game launched from the editor).
- Settings: mouse sensitivity, invert Y, language (EN/ES), fullscreen/windowed, master volume.
