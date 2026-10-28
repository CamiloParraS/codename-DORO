# Credits and licenses

Ghost Layer is a student project. Third-party assets and their licenses:

## 3D models and animation

- Universal Base Characters / Universal Animation Library / Universal Animation Library 2 by Quaternius, https://quaternius.com
  License shown at download (2026-10-08): CC0 1.0. No credit required, credited anyway.
  Used: 9 clips baked from UAL1/UAL2 into `assets/models/animations/clips.res` by `tools/bake_clips.gd`; the Superhero_Male_FullBody skin weights seeded the Nikita rig (`tools/rig_nikita.py`). The Universal Animation Library is under the Quaternius license (CC0 1.0).
- Blocky Characters, Survival Kit, City Kit (Industrial) by Kenney, https://kenney.nl
  License: CC0 1.0 Universal, https://creativecommons.org/publicdomain/zero/1.0/
- Kenney Survival Kit `box-large` and City Kit (Industrial) `shipping-container-a/b` (`assets/models/props/`, skinned onto the greybox crates by `areas/prop_skin.gd`), https://kenney.nl, CC0 1.0
- Characters PSX `Character_Male_36` by Elbolilloduro, https://elbolilloduro.itch.io/characters-psx, CC0 1.0 (`assets/models/characters/target/`, the Target's body; its clips are Mixamo, baked by `tools/bake_target.gd`)
- Modern Rebel Soldier (PSX) by yugg0, https://yugg0.itch.io/modern-rebel-soldier-character-psx-ps1
  Free for personal and commercial use per the author's page; rig from Mixamo; basemesh from Sketchfab (see the author's page).
- Characters PSX by Elbolilloduro, https://elbolilloduro.itch.io/characters-psx, CC0 1.0
- Pizza Doggy's PSX Mega Pack pistol and suppressor (`assets/models/weapons/pistol.glb`, `suppressor.glb`), by Pizza Doggy, link: https://itch.io/profile/pizzadoggy. Same license as the line below.
- Pizza Doggy's Mystery Package vol. 1-14 (pizza doggy models) by Pizza Doggy, link: https://itch.io/profile/pizzadoggy
  License: Pizza Doggy's Game Assets License Agreement (dated 2026-09-01). Proprietary, not Creative Commons. Commercial and non-commercial game use allowed, modification allowed, no royalties. Attribution optional ("Game Assets by Pizza Doggy"). Not allowed: redistributing or selling the assets as standalone or reusable files, asset packs, or uploading/using them for AI training or AI generation.
- Set dressing in `assets/models/props/` (placed by each Area's `DRESS` data in `tools/build_*.gd`):
  - Pizza Doggy's PSX Mega Pack (same license as the line above): `drum`, `crate_small`, `supply_crate`, `cardboard_box`, `vending_machine`, `jerrycan`, `pc`, `monitor`, `monitoring_screen`, `chair`, `shelf`, `table`, `locker`, `ceiling_lamp`.
  - PSX Industrial Environment Asset Pack by godgoldfear (CC 4.0, see below), split out of its FBX in Blender, metallic zeroed: `generator`, `pallet`, `pallet_stack`, `barrel_a`, `barrel_b`, `crate_wide`, `cabinet_a`, `cabinet_b`, `pipe_riser`, `tank_tall`, `vent_unit`, `chimney`, `shed`.
  - PSX style barriers by valsekemarplant (CC0, see below): `bollard`, `cone`, `jersey_barrier` (`Jersey_barrier_dirty`).
  - Pizza Doggy's Retro Tree Pack v1.0, Super Low Res (same license as the Pizza Doggy line above): `pine` (`tree_rt_3`), `pine_small` (`tree_rt_1`), `poplar` (`tree_rt_2_1`), `dead_tree` (`dead_tree_rt_1`).
  - Kenney City Kit (Industrial), https://kenney.nl, CC0 1.0: `water_tower`.
  - Made for this project in Blender (via the Blender MCP, textured with the project's own `assets/textures/`): `utility_pole`, `pylon`, `sat_dish`, `lighthouse`, `buoy_red`, `buoy_green`, `piling`, `vent_cowl`, `tyre_fender`; and the bare shapes the builders skin with `psx_surface` (`SKINS` in `tools/area_builder.gd`): `mountain_a`, `mountain_b`, `boulder_a`, `boulder_b`, `mound`.
  - Also from godgoldfear's pack, textures relinked and split out in Blender (`_raw/work/bl/export_props.py`, `fence.py`): `fence` (frame plus chain-link panel), `roadblock`, `sandbags`, `pipe_arch`, `tank_wide`, and the Backdrop blocks `block_tall`, `block_wide`, `block_hall`, `block_long`.
  - Surface textures in `assets/textures/` (cropped and cut to 128 px): `asphalt`, `concrete`, `corrugated_rust`, `panels`, `cargo_green`, `hatch`, `bridge_windows`, `hazard` from godgoldfear's pack (CC 4.0); `deck_plate`, `rust`, `planks`, `rock` from Screaming Brain Studios' Tiny Texture Pack 2 (CC0, see below).
  - `crane_tower`, `crane_boom`: made for this project in Blender (procedural lattice, `_raw/work/bl/crane.blend`, exported by `export_crane.py`).
  - `lamp_post`: made for this project in Blender (`_raw/blender/dressing_props.blend`).
- Character animations from Mixamo (c) Adobe, https://www.mixamo.com, used under Mixamo's free terms; raw files are not redistributed.
- 3D model of a M4A1 in PS1 style by Plewr, https://plewr.itch.io/psx-style-m4a1-model, CC0 1.0
- PSX Industrial Environment Asset Pack by godgoldfear, https://godgoldfear.itch.io/psx-industrial-environment-asset-pack, CC 4.0
- Mine, Elbolilloduro, https://elbolilloduro.itch.io/mine, CC0 1.0
- PSX style modular walls & fences / PSX style barriers / PSX style urban stacked pack, valsekemarplant, https://valsekamerplant.itch.io/, CC0 1.0
- 2 Retro 3D Dieselpunk Tanks, chilly_durango, https://chilly-durango.itch.io/2dieselpunktanks, CC0 1.0
- Nikita low poly character mesh, n0mad, https://n0madcoder.itch.io/nikita-low-poly-character-base-mesh, CC0 1.0 (rigged to the Quaternius skeleton in Blender: `assets/models/characters/Nikita_Rigged.glb`; UV template for painting: `assets/textures/characters/nikita_uv_template.png`)
- Lowpoly Female Mesh, Titanium Rat, https://titaniumrat42.itch.io/lowpoly-female-mesh, CC0 1.0
- Freddy - Low-Poly Retro PSX FNAF Models / PSX Rifle Free / PSX skeleton , Puck, https://puszke.itch.io/, CC0 1.0 (the PSX Rifle, scaled and exported to GLB, is `assets/models/weapons/rifle.glb`)
- PSX Female Secretary Character, Vinrax, https://vinrax.itch.io/psx-secretary-character, Free to use must credit author
- Asimov 3D Guns and Gun Accessory Pack, Hans Woofington, https://hans-woofington.itch.io/asimov-3d-guns-and-gun-accessory-pack, do not resell this models and provide credit
-

## Textures

- Tiny Texture Pack 2 by Screaming Brain Studios, https://opengameart.org/content/tiny-texture-pack-2, CC0 1.0
- Textures derived from ambientCG, https://ambientcg.com (CC0 1.0), and Poly Haven, https://polyhaven.com (CC0 1.0), downscaled to 64-128 px.
- Foxtex, Foxhead, https://foxh3ad.itch.io/foxtexcom, CC0 1.0
- Crosshairs (`crosshair_4_small.png`, `crosshair_21.png`) from Pizza Doggy's Mystery Package vol. 14 (Crosshairs Pack v1.0), https://itch.io/profile/pizzadoggy. Same license as the models above (Pizza Doggy's Game Assets License Agreement).

## Fonts

- Press Start 2P, Copyright 2012 The Press Start 2P Project Authors (cody@zone38.net), SIL Open Font License 1.1. OFL.txt is included at res://assets/fonts/OFL.txt.
- VT323, Copyright 2011 The VT323 Project Authors (peter.hull@oikoi.com), SIL Open Font License 1.1. ofl_vt323.txt is included at res://assets/fonts/ofl_vt323.txt.

## Audio

- `spaceEngineLow_000` (`assets/audio/ambience_hum.ogg`), Sci-fi Sounds by Kenney, https://kenney.nl/assets/sci-fi-sounds, CC0 1.0
- `impactMetal_000` (`assets/audio/sfx_knock.ogg`), Sci-fi Sounds by Kenney, https://kenney.nl/assets/sci-fi-sounds, CC0 1.0
- `impactMetal_light_000`-`002` (`assets/audio/sfx_ricochet_0-2.ogg`) and `impactPunch_medium_000`-`002` (`assets/audio/sfx_bullet_hit_0-2.ogg`), Impact Sounds by Kenney, https://kenney.nl/assets/impact-sounds, CC0 1.0
- `question_002` (`assets/audio/sting_question.ogg`, provisional), Interface Sounds by Kenney, https://kenney.nl/assets/interface-sounds, CC0 1.0
- `confirmation_002` (`assets/audio/sting_relief.ogg`, provisional), Interface Sounds by Kenney, https://kenney.nl/assets/interface-sounds, CC0 1.0
- "Frequency Static Sound Effects" by bretbernhoft, https://opengameart.org/content/frequency-static-sound-effects, CC0 1.0
- "airy_0", "urgent_0", "sector_0" (`assets/audio/music_patrol.ogg`, `music_alert.ogg`, `music_evasion.ogg`) from Dark Sci-Fi Audio Pack by SRG774, https://opengameart.org/content/dark-sci-fi-audio-pack, CC0 1.0
- Impact Sounds by Kenney, https://kenney.nl/assets/impact-sounds, CC0 1.0: `footstep_concrete_000..004` (`sfx_step_*`), `impactPunch_medium_000` (`sfx_takedown`), `impactSoft_heavy_000` (`sfx_body_fall`), `impactSoft_medium_000` (`sfx_dart_hit`), `impactPlate_light_000` (`sfx_dart_vest`), `impactMetal_light_000..001` (`sfx_mag_land_*`)
- `cloth1` (layered into `sfx_choke.ogg`), RPG Audio by Kenney, https://kenney.nl/assets/rpg-audio, CC0 1.0
- `click3` (`sfx_ui_click.ogg`), UI Audio by Kenney, https://kenney.nl/assets/ui-audio, CC0 1.0
- "A silenced/suppressed handgun being shot once w/ phaser sounding trail // pretty metallic sounding" by serøutōnin--deprivəd, https://freesound.org/s/855656/, CC0 (`sfx_shot_quiet.ogg`)
- "Silenced Sniper Rifle.flac" by qubodup, https://freesound.org/s/182815/, CC0 (`sfx_shot_quiet_rifle.ogg`, trimmed)
- "M4A1 Shot" by qubodup, https://freesound.org/s/854207/, CC0 (`sfx_shot_loud.ogg`)
- "Male Choking_1" by Drkvixn91, https://freesound.org/s/318080/, CC0 (`sfx_choke.ogg`, first 1.6 s)
- "Climbing Metal Ladder hands and feet" by DeqstersLab, https://freesound.org/s/767343/, CC0 (`sfx_ladder_*.ogg`, three slices)
- "Walkie Talkie - Transmission Start" by bruce965, https://freesound.org/s/321905/, CC0 (`sfx_radio_on.ogg`)
- "radio-static" by carroll27, https://freesound.org/s/151903/, CC0 (`sfx_radio_static.ogg`, the loudest 0.15 s)
- "Radio receiver on/off" by LukaCafuka, https://freesound.org/s/753402/, CC0 (`sfx_radio_off.ogg`, the off click)
- "Shock Stab 12" by nomiqbomi, https://freesound.org/s/578382/, CC0 (`sting_alert.ogg`, first 0.4 s)
- "9_inch_inflate" by tix99, https://freesound.org/s/732685/, CC0 (`sfx_fulton_launch.ogg`)
- "Steam.wav" by SukritSen, https://freesound.org/s/398077/, CC0 (layered into `sfx_fulton_launch.ogg`)
- "rope leathery creaking.wav" by vestibule-door, https://freesound.org/s/664929/, CC0 (layered into `sfx_fulton_launch.ogg`)
- "magical rising wind or sea .wav" by martian, https://freesound.org/s/403003/, CC0 (`sfx_fulton_lift.ogg`, first 5.5 s, faded out)
- "Footsteps on metal" by IENBA, https://freesound.org/s/834029/, CC0 (`sfx_step_metal_*.ogg`, eight single steps sliced out)
- "Night time crickets, distant dogs and traffic ambience.WAV" by SukritSen, https://freesound.org/s/482687/, CC0 (`ambience_outdoor.ogg`)
- Guard barks and grunts (`assets/audio/barks/`, `assets/audio/grunts/`, sorted into role folders), source: public archive. Custom licence: included in the game, not to be redistributed as standalone or reusable files.

## Shaders

- Ultimate Retro Shader Collection, Zorochase, https://github.com/Zorochase/ultimate-retro-shader-collection?tab=readme-ov-file, MIT License

## Tools

- Godot Engine, MIT License, https://godotengine.org
- LimboAI 1.8.1 by Serhii Snitsaruk and contributors, https://github.com/limbonaut/limboai, MIT License (behaviour trees)
- Pizza Doggy's Rusty PSX Style Kidnapper's Van (Mystery Package vol. 8) and PSX Mega Pack dinner table (`assets/models/props/van.glb`, `desk.glb`, skinned onto the Truck and the relay console desk). Pizza Doggy's Game Assets License Agreement, see above.
- Characters PSX `Character_21_Police`, `Character_23_Firefighter`, `Character_25_Doctor`, `Character_27_HM` textures (guard skins, `assets/models/characters/guard/`) by Elbolilloduro, CC0 1.0, baked onto Nikita's UVs (`_raw/work/bake/bake.py`).
- Operative skin (`assets/models/characters/operative.png`): self-made, painted on Nikita's UV layout (`assets/textures/characters/nikita_uv_labeled.png`).
- Quaternius Universal Animation Library `Hit_Chest` clip, CC0, baked into `clips.res` as `hit` (`tools/bake_clips.gd`).
