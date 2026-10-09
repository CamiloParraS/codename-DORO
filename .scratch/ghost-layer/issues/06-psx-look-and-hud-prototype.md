# PSX look and HUD prototype

Type: prototype
Status: resolved
Blocked by: 02, 03

## Question

What does the game look like? Internal resolution, PSX shaders (vertex snapping, affine textures, dithering, fog), texture size, and the HUD. Starting hypothesis for the UI: a minimal Peace Walker / MGS1-style HUD (life, weapon and item in the corners, alert/evasion timer, codec screen) **plus** the MGSV detection indicator (already chosen in [Core stealth feel prototype](04-stealth-core-prototype.md): arcs around the screen centre + ?/! head marks; this ticket only gives it the PSX look). Also the radio menu for Spoofing: a radial menu with time slowed (chosen in [Spoofing prototype](05-spoofing-prototype.md)). Not MGSV's markers or iDroid. Confirm or adjust by looking at it.

## Comments

- 2026-10-09 (from Operator profile and countermeasures): the post-Mission screen needs a strip of 0–3 icons, one per Habit (Stealth, Combat, Headshots, Takedowns, Downs, Spoofing), with arrows for what rose or fell. No raw numbers.

## Answer

The look is **modern-retro**, not full PSX: the PSX geometry tricks (vertex snapping, affine textures, low poly) are dropped. The HUD is **E, the Peace Walker side strips**, with C's subtitles for radio. Prototype on branch `prototype/psx-look` (`areas/proto_psx/`). All five HUD variants stay there so E can be refined later.

- **Look** (the user chose modern + 15-bit banding and left the rest to the agent's pick; the exact values are build-time tuning):
  - 3D at **854×480** (16:9) with nearest-neighbour upscaling (`Viewport.scaling_3d_mode = NEAREST`, `scaling_3d_scale = 480 / window height`). At 240p, a guard 16 m away was only a few pixels, too small for stealth reading.
  - **No vertex snapping, no affine textures.**
  - **Per-pixel lighting with shadows.** Shadows help you read cover; vertex lighting wasn't needed.
  - **15-bit colour with banding, no dither:** a full-screen canvas pass under the HUD that rounds each channel to 31 levels.
  - **Far depth fog** (20–60 m) in the sky colour.
  - **128 px textures**, nearest filtering, world-space box UVs at about 2 m per tile. Box geometry subdivided about every 2 m.
  - **HUD crisp at native resolution.** It's laid out on a 640×360 logical canvas; a HUD drawn at the low resolution too wasn't chosen.
- **HUD E** (Peace Walker):
  - **Left:** a vertical life bar, "OPERATIVE" written upward beside it, and a slot number underneath.
  - **Right strip:** ALERT/EVASION with its timer in red vertical text, a stance silhouette, then vertical cards for the item (name plus a 4-digit count) and the weapon (an ammo pip column, a suppressor count on the rifle, name plus total ammo).
  - **Compass:** a ring top-right where the N turns with the camera. It shows no enemy dots, so it never acts as radar.
  - **Voiceprints:** a short "VP A B" line under the compass.
  - **Radio lines** (check-ins, chatter, Spoofed orders) show as **C-style subtitles**: centred at the bottom, the last two lines, fading after about 6 s.
  - **No CALL bar on radio lines.** In Peace Walker that bar belongs to codec calls, so it stays with them.
  - The **MGSV arcs + ?/! marks** stay as decided in [Core stealth feel prototype](04-stealth-core-prototype.md).
- **The radial radio menu and the codec are restyled to match E:** a white/grey palette instead of MGS1 green.
- **Codec: two kinds of call, picked per call.**
  - A call that **stops the game** uses the **full-screen codec**, paused: two portraits, a frequency, a typewriter text box.
  - A call **during play** keeps the game running and uses **Peace Walker subtitles over a `CALL >> <speaker>` bar**.
  - Which calls are which belongs to [Narrative delivery](11-narrative-delivery.md).
- **Fonts:** Press Start 2P for HUD labels, VT323 for text and subtitles (both OFL, in `assets/fonts/` with their OFL files). Textures come from Screaming Brain's Tiny Texture Pack 2 (CC0).
- **Carried forward (from Operator profile and countermeasures):** the post-Mission screen's 0–3 icon strip per Habit, with rise/fall arrows, follows E's white/grey style. It wasn't prototyped; its layout is build-time work.
- **Godot gotcha:** in a game launched from the editor, F8 stops the game (the editor's stop shortcut), so don't bind it. The codec call moved to K for that reason.

