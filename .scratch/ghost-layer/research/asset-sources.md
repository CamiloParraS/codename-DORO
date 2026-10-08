# Asset sources and licenses (Ghost Layer)

Researched 2026-10-08 against the asset pages and license texts themselves. Items marked **[unverified]** came only from secondary sources or practitioner knowledge, not from the owner's page. Not legal advice. Re-check each pack's page and bundled license file on the day you download.

## TL;DR

- **Characters:** Quaternius (Universal Base Characters + Universal Animation Library, both free "Standard" tier) is the best humanoid-rig fit. Kenney Blocky Characters is a no-risk CC0 fallback. There is **no verified-CC0 animated PSX soldier**. Closest: yugg0 itch.io "Modern Rebel Soldier" (free, own terms, Mixamo rig).
- **Props/buildings:** No single CC0 PSX military pack was found. Build the base from Kenney/Quaternius kits plus 64-128px textures.
- **Textures:** Screaming Brain Studios "Tiny Texture Pack" (CC0, ships at 128x128) or downscale ambientCG/Poly Haven (CC0).
- **Font:** Press Start 2P or VT323 (SIL OFL 1.1) or Kenney Fonts (CC0).
- **SFX:** Kenney Sci-fi Sounds + Interface Sounds (CC0), OpenGameArt CC0 static, Freesound filtered to CC0 only.
- **Mixamo:** OK to use in a game, but **do not commit raw Mixamo FBX files to a public repo** (see Traps).

## Traps (read first)

1. **Quaternius changed its license.** The Quaternius License page now shows the "Quaternius Asset License (QAL) v1.0", last updated 8/28/2026, not CC0. It still allows personal/educational/commercial use with no credit, but section 3a forbids redistributing the assets themselves "as a standalone asset, asset pack, stock file, template... whether for free or for payment... regardless of how much the Assets have been modified". The individual pack pages I read still say "CC0". Per QAL section 7, the version in effect when you obtained the assets governs. Action: record the download date and the license shown per pack in CREDITS.md. A public repo containing raw Quaternius files could be read as redistribution under QAL, so keep raw source packs out of a public repo (or only commit them if the pack you downloaded was clearly CC0 at the time).
   Source: https://quaternius.com/license.html
2. **Mixamo forbids distributing the raw character/animation files** to non-team members. A public Git repo or a downloadable project source zip with `.fbx` from Mixamo is a violation risk. Shipping a built game is fine.
   Source: https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400
3. **The only Mixamo FAQ text I could reach is a community-posted copy from Sept 2022** (Adobe's own FAQ URLs returned 404/403). It describes a "limited duration technology preview" and replies from 2026 question whether it is current. Check Adobe's live Mixamo terms before presenting.
4. **Mixamo content may not be used to train ML models** (same FAQ).
5. **Quaternius free "Standard" tier is only about 60-70% of each pack.** Pro/Source tiers are paid ($ via itch.io / Patreon keys $10/$20/$50 per month). The Godot-ready project files are only in Source. Universal Animation Library Standard has about 45 animations; Source is listed at $14.99+.
   Sources: https://quaternius.com/packs/universalanimationlibrary.html, https://quaternius.itch.io/universal-animation-library
6. **Freesound is per-sound.** CC BY requires credit; CC BY-NC forbids commercial use; "Sampling+" is a retired legacy license treated like BY-NC. Only filter for CC0 if you want zero bookkeeping. Source: https://freesound.org/help/faq/
7. **Sonniss GDC bundles:** royalty-free, no attribution, but no standalone redistribution (so no raw files in a public repo) and **AI/ML training is prohibited**. Source: https://sonniss.com/gameaudiogdc/
8. **Pixabay content** is not CC0: no standalone sale/distribution of unaltered content, no trademarks/logos, and "only the full Content License is legally binding". Source: https://pixabay.com/service/license-summary/
9. **LaFinca "Retrogard Textures"** is free but requires credit to LaFinca Studio (not CC0) [secondary: search result summary]. Tactical Ops Essentials (Superhive) is a **paid** pack mixing CC-BY and CC0 models [secondary]. Fab/TurboSquid "military base" packs are **paid** (about $30) and not PSX style [secondary].
10. **OFL fonts:** may be bundled with a game and sold with it, but cannot be sold on their own, and a font with a Reserved Font Name (Press Start 2P has one) cannot be renamed-and-modified under the same name. Include the OFL.txt. A public repo containing the font counts as redistribution, so ship OFL.txt next to it. Source: https://openfontlicense.org/ofl-faq/
11. **AI-generated assets:** Freesound allows AI-generated uploads if tagged "GenAI" with the model named, so a "CC0" sound there may be AI-made; check the tag if your teacher or audience cares. Freesound also lets uploaders opt out of AI training (since July 2026). Source: https://freesound.org/help/faq/. I found no AI-content policy on the Kenney, Quaternius, ambientCG, Poly Haven or OpenGameArt pages I fetched (OpenGameArt's FAQ page has none). Treat provenance of itch.io packs as unknown.
12. **Kenney logo is reserved.** Do not use the Kenney logo in your game. Credit text "Kenney" is fine. Source: https://kenney.nl/support
13. **Preview images/audio on OpenGameArt are generally not covered by the download license.** Source: https://opengameart.org/content/faq

## 1. Animated low-poly human characters

| Source | What it has | Rig / animations | License (as shown on the page) | Notes |
|---|---|---|---|---|
| Quaternius Universal Base Characters https://quaternius.com/packs/universalbasecharacters.html | 6 base models (Superhero/Regular/Teen, M/F), 20 hairstyles, avg 13k tris, no outfits listed | Humanoid rig "retargetable in any engine"; **no animations included**, made to pair with the Universal Animation Library | Page says CC0; see Trap 1 (QAL) | Standard tier free (60-70%), Source paid. 13k tris is high for PSone: decimate or accept, then use low-res texture + vertex-snap shader |
| Quaternius Universal Animation Library https://quaternius.com/packs/universalanimationlibrary.html | 120+ animations: 8-direction locomotion, jog, sprint, crawl, swim, sit, death, combat and gun, emotes | Universal humanoid rig, "ready for retargeting" for Godot/Unity/Unreal | Page says CC0, free for personal/educational/commercial (see Trap 1) | Standard free tier about 45 animations; Source with .blend and Godot project is paid. Best fit for a stealth game (gun/death/crawl) |
| Quaternius Universal Animation Library 2 https://quaternius.com/packs/universalanimationlibrary2.html | 130+ animations: melee/armed combos, parkour, farming, fishing, zombie locomotion | Universal humanoid rig | Page says CC0 | Page does **not** mention gun, stealth or crouch; skip unless you need parkour/melee |
| Quaternius Animated Men Pack https://quaternius.com/packs/animatedmen.html | 4 human models "with many animations", FBX/OBJ/Blend, textured | Rig not described on page; animation list not given | CC0, free | Not stated to be soldiers. Download and inspect before committing |
| Quaternius Ultimate Animated Character Pack https://quaternius.com/packs/ultimatedanimatedcharacter.html (the slug really has "ultimated") | 50+ animated characters, FBX/OBJ/Blend | Rig not described; probably untextured | CC0, free | Check the roster for soldier-like models after download |
| Quaternius Ultimate Modular Women https://quaternius.com/packs/ultimatemodularwomen.html | 10 characters, 4 swappable parts each, 24 animations, humanoid rig version included | Humanoid rig | CC0 | Gender-skewed; modular parts could be recolored as camo |
| Kenney Blocky Characters https://kenney.nl/assets/blocky-characters | 20 files; "Animation" feature (a mirror lists 18 skins, 27 animations) [secondary: https://opengameart.org/content/blocky-characters] | Animated | CC0 | Blocky style, not PSX-realistic, but zero risk. Page does not list which animations |
| Elbolilloduro Characters PSX https://elbolilloduro.itch.io/characters-psx | 113 PSX-style characters (12 police, 41 civilians, 8 "murderers", 6 monsters, 34 extras), FBX + Blend, name-your-price (can be free) | Page does not say if rigged; comments dispute rig quality and mention a Mixamo NLA strip | "The models in this package are under the CC0 license" | **Best PSX look, but not soldiers**. Possibly Mixamo-derived animation data, so see Trap 2 before redistributing. Use as enemies/guards (police/murderers) |
| yugg0 Modern Rebel Soldier (PSX/PS1) https://yugg0.itch.io/modern-rebel-soldier-character-psx-ps1 and #2 https://yugg0.itch.io/modern-rebel-soldier-character-2-psx-ps1 | Rigged low-poly soldier, FBX + PNG textures + Blender source, name-your-price | Rigged with bones; **no animation clips listed**; rig credited to Mixamo | Own terms: free for personal and commercial, modification allowed, **cannot claim as your own, cannot redistribute under your name**; credits a Sketchfab basemesh and the Mixamo rig | Closest to the brief (PSX soldier). Mixamo rig so Mixamo animations apply directly. Not CC0: keep the author's credit in CREDITS.md |
| DullMesh Rigged Stylized SWAT Soldier https://dullmesh.itch.io/free-rigged-stylized-swat-soldier | "Stylized SWAT Soldier" (rigged) | Rig only | License not seen (itch.io listing page returned only title) | **[unverified]** open the page and read the terms first |

Other itch.io soldier listings (not 3D PSX or license unknown): https://itch.io/game-assets/free/tag-soldier

Recommended combination: a Quaternius base character (or the yugg0 soldier) driven by Universal Animation Library or Mixamo clips, retargeted with Godot's humanoid BoneMap (see section 6).

## 2. Military props and buildings

No free, verified-CC0, PSX-style military pack covering crates + fences + watchtower + radar + barracks was found. Findings:

- **Kenney Survival Kit** https://kenney.nl/assets/survival-kit: CC0, 80 files, 3D with animation. The page does not itemize contents (crates, fences, barrels, tents likely but unconfirmed).
- **Kenney City Kit (Industrial)** https://kenney.nl/assets/city-kit-industrial: CC0, 40 files, tags city/building/factory/warehouse. Contents not itemized on the page.
- **Quaternius Sci-Fi Essentials Kit** https://quaternius.com/packs/scifiessentialskit.html: CC0 (see Trap 1), 60+ models: robot enemies, guns, animated screens, crates, props. Standard tier is 60-70% free.
- **Quaternius Modular Sci-Fi Megakit / Ultimate Modular Sci-Fi** (listed at https://quaternius.com/index.html): corridors and bunker-style interiors, not inspected.
- **Kenney Blaster Kit** https://kenney.nl/assets/blaster-kit: listed in the 3D category; contents not inspected.
- **PSX weapons, CC0:** https://amos-makes.itch.io/psx-weapon-pack, https://amos-makes.itch.io/psx-grenades, https://ziv-iz3.itch.io/mp5-weapon-psx-mesh (the CC0 status comes from listings/author comments in search results; confirm on the page).
- **Paid/mixed, avoid for this project:** Tactical Ops Essentials Vol 1 (watchtower, fences, sandbags; CC-BY + CC0 mix, paid) https://superhivemarket.com/products/tactical-ops-essentials-asset-pack; Cozy Low-Poly Military Structures (barracks, watchtower, about $30, stylized) https://www.turbosquid.com/3d-models/stylized-cozy-military-structures-pack-2495600; Fab "Modular Military Base" (license not stated) [all secondary].

Practical plan: model the missing pieces yourself (crate = cube, fence = plane with alpha texture, watchtower/radar dish = CSG or 10-minute Blender boxes). PSone buildings were boxes with 64-128px textures anyway. Godot's CSG nodes cover prototyping.

## 3. PSone-style textures (64-128px)

**Ready-made, CC0**
- Screaming Brain Studios Tiny Texture Pack 2, CC0, 160 seamless textures (Brick, Dirt, Elements, Metal, Plaster, Stone, Tile, Wood), each at 512/256/**128** px (the 128px zip is 5.4 MB), no credit required: https://opengameart.org/content/tiny-texture-pack-2
- Same author, Tiny Texture Pack 3 (grating, metal, stone, terrain, weave; CC0) https://opengameart.org/content/tiny-texture-pack-3, and Base Material Texture Pack (384 textures, 128/256/512, CC0) https://opengameart.org/content/base-material-texture-pack (both license statements from search-result summaries; open pages to confirm).
- Kenney Prototype Textures (CC0, 75 files; sizes not stated on page) https://kenney.nl/assets/prototype-textures: good for greybox.

**Source libraries (CC0) to downscale**
- ambientCG: all assets CC0, raw files may be included in a game, attribution not required (suggested wording: "Created using <asset name> from ambientCG.com, licensed under the Creative Commons CC0 1.0 Universal License."). https://docs.ambientcg.com/license/
- Poly Haven: CC0, commercial use allowed, credit appreciated not required. Website terms prohibit scraping/data mining. https://polyhaven.com/license

**Downscale workflow** (ImageMagick 7 syntax; commands are standard, not tested against these specific packs)
1. Download the 1K JPG color map only.
2. `magick in_Color.jpg -filter Box -resize 64x64! -colors 32 out_64.png` (Box/point filter keeps it crunchy; `-colors 32` approximates the PSone palette feel; add `-ordered-dither o8x8` for dithering). Use 128x128 for large walls.
3. In Godot import dock for each texture: Filter off (nearest), Mipmaps off, Compress Lossless. Set the project default under Rendering > Textures > Canvas Textures/Default Texture Filter to Nearest for UI, and set materials' Texture Filter to Nearest for 3D.
4. Use affine-mapping/vertex-snap shaders and a low-res SubViewport (for example 320x240) for the rest of the PSone look.

## 4. PSone-style fonts and UI

- **Press Start 2P** (OFL 1.1, "Copyright 2012 The Press Start 2P Project Authors", Reserved Font Name "Press Start 2P"): https://github.com/google/fonts/tree/main/ofl/pressstart2p , license https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt
- **VT323** (OFL 1.1, terminal style, good for codec/radio text): https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt
- **Silkscreen** (OFL 1.1, small pixel font): https://raw.githubusercontent.com/google/fonts/main/ofl/silkscreen/OFL.txt
- **Kenney Fonts**, CC0, 11 files, pixel style, v1.0 (2014): https://kenney.nl/assets/kenney-fonts
- OFL rules: bundle freely in a game, include OFL.txt, do not sell the font alone, do not reuse the Reserved Font Name for a modified font (https://openfontlicense.org/ofl-faq/). Artwork made with the font needs no credit.
- UI elements: Kenney has UI/icon packs under CC0 (search the 2D category at https://kenney.nl/assets, I did not inspect specific ones). For codec windows, draw simple 9-patch panels with a flat green/blue palette in Godot; a StyleBoxFlat with no AA is enough.
- Free PSone-ish font alternatives I did not verify: none recommended. Avoid "ripped" game fonts (Metal Gear/Final Fantasy): those are copyrighted.

## 5. Radio / codec / stealth sound effects

| Source | License | Notes |
|---|---|---|
| Kenney Sci-fi Sounds https://kenney.nl/assets/sci-fi-sounds | CC0, 70 files | Beeps, computer sounds; contents not itemized on the page |
| Kenney Interface Sounds https://kenney.nl/assets/interface-sounds | CC0, 100 files | Clicks/buttons for menus; codec UI blips |
| OpenGameArt "Frequency Static Sound Effects" by bretbernhoft https://opengameart.org/content/frequency-static-sound-effects | CC0, 11 WAVs (about 42 MB each) | Radio/TV static; large files, trim and convert to OGG |
| Freesound https://freesound.org | Per-sound: CC0 / CC BY / CC BY-NC / legacy Sampling+ | Search with the license filter on "Creative Commons 0". Do not use BY-NC for a public release. Credit format is in the FAQ. Check the GenAI tag |
| Sonniss GameAudioGDC bundles https://sonniss.com/gameaudiogdc/ | Royalty-free, attribution optional, no standalone redistribution, no AI training | GDC 2024 bundle is 9 zips; read /gdc-bundle-license/ first |
| ZapSplat | Not verified (site blocked automated fetch) | Free tier historically requires credit **[unverified]**; skip or read https://www.zapsplat.com/license-type/standard-license/ in a browser |
| Pixabay SFX | Pixabay Content License, not CC0 | See Trap 8 |
| VoiceBosch "RADIO SOLDIER - Announcer Audio Pack" https://voicebosch.itch.io/radio-soldier-announcer-audio-pack | Not checked | Radio-style voice lines; read the page's terms |

Codec/radio recipe: take a clean voice line, apply a bandpass (about 300-3000 Hz) plus bit-crush in Audacity (or Godot AudioEffectFilter/Distortion on a bus), then mix CC0 static underneath. This avoids needing a pre-made "radio voice" pack.

## 6. Mixamo

### Licensing (source: Adobe-posted FAQ copy, see Trap 3)
https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400
- Free, "no licensing or royalty fees, for unlimited commercial or non commercial use". Games, DLC and add-on content for games are listed as permitted.
- Attribution to Adobe/Mixamo/Fuse is welcome but **not required**.
- "The only thing you can't do is distribute the raw character and animation files." Team members may access them; customers and non-team members may not.
- Not permitted: blueprints, templates or asset packages for game engines that redistribute the raw files; training ML models.
- Needs an Adobe ID (free). An Enterprise ID login does not work [secondary: Adobe community thread].
- Practical consequence for this project: ship the exported game, keep Mixamo `.fbx` out of public Git (use `.gitignore`) or convert to a non-redistributed local-only folder. The Godot-imported `.res`/`.tres` animation library derived from Mixamo is still "animation files" in spirit, so also keep it out of a public repo.

### Workflow into Godot 4.7
Godot-documented parts are cited; Mixamo-specific parts are **[unverified]** practitioner steps because neither the Godot docs nor Mixamo's pages describe each other.

1. **On Mixamo:** pick a character (or upload your own to auto-rig). Download the character once as FBX with skin in T-pose. For each animation, download FBX, "Without Skin" (skeleton + animation only), 30 fps. Tick "In Place" for locomotion loops you will drive with code. **[unverified]**
2. **Import:** Godot 4.3+ imports `.fbx` through ufbx by default; glTF is the recommended format. https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
3. **Retarget on import** (page: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html). In Advanced Import Settings, select the **Skeleton3D** node. Under **Retarget**, set `bone_map` to a new BoneMap with the **SkeletonProfileHumanoid** profile. Setting the profile triggers auto-mapping. Fix any red/magenta buttons manually (warnings, not blockers).
4. **Bone Renamer:** enable Rename Bones, and Unique Node (so animation track paths do not depend on scene hierarchy).
5. **Rest Fixer:** enable Overwrite Axis (the key option to share animations across characters in Godot 4), Normalize Position Tracks (reduces foot slipping between different-sized models), and Fix Silhouette for A-pose models (usually unneeded for T-pose). Reference pose assumes T-pose, facing +Z. Overwrite Axis "can produce horrible results" if the original rest matters.
6. **Remove Tracks** (only when importing animations to share): Unimportant Positions, Unmapped Bones, and Except Bone Transform (keep these off when the model has animated accessories).
7. **Animation Library:** select the animation FBX/glTF in the FileSystem dock, set the Import dock's import type to **Animation Library**, Reimport (restart prompt). The result is an AnimationLibrary resource you can add to an AnimationPlayer. Alternative: use Advanced Import Settings > animation > "Save to file" so custom tracks persist after reimport. https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html and .../advanced_import_settings.html
8. Use the same humanoid BoneMap/profile on **every** character and animation import so tracks match (the Quaternius rig is built for the same retargeting flow).
9. **Root motion** (https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html): in an AnimationTree set the **Root Motion Track** to the root/hips bone, which cancels the bone's visual translation so the animation stays in place. Read `get_root_motion_position()`, `get_root_motion_rotation()`, `get_root_motion_scale()` (deltas) or the `*_accumulator()` variants. The docs say this can feed `CharacterBody3D.move_and_slide`; a sketch (not from docs): `velocity = anim_tree.get_root_motion_position() / delta; move_and_slide()`. Mixamo skeletons have no separate root bone, so for root motion either use "In Place" clips and move the body from code (simpler, recommended for a student schedule) or point Root Motion Track at the Hips **[unverified]**.
10. Commit only the retargeted, locally-generated resources if the repo is private; otherwise see Trap 2.

Not found in primary docs: any statement that Godot's BoneMap auto-maps `mixamorig:` bone names. Test it on one clip; if auto-map fails, map manually once and save the BoneMap resource for reuse.

## CREDITS.md template

```markdown
# Credits and licenses

Ghost Layer is a student project. Third-party assets and their licenses:

## 3D models and animation
- Universal Base Characters / Universal Animation Library by Quaternius, https://quaternius.com
  License shown at download (YYYY-MM-DD): CC0 1.0 / Quaternius Asset License (QAL) v1.0 (delete one). No credit required, credited anyway.
- Blocky Characters, Survival Kit, City Kit (Industrial) by Kenney, https://kenney.nl
  License: CC0 1.0 Universal, https://creativecommons.org/publicdomain/zero/1.0/
- Modern Rebel Soldier (PSX) by yugg0, https://yugg0.itch.io/modern-rebel-soldier-character-psx-ps1
  Free for personal and commercial use per the author's page; rig from Mixamo; basemesh from Sketchfab (see the author's page).
- Characters PSX by Elbolilloduro, https://elbolilloduro.itch.io/characters-psx, CC0 1.0 (delete if unused)
- Character animations from Mixamo (c) Adobe, https://www.mixamo.com, used under Mixamo's free terms; raw files are not redistributed.

## Textures
- Tiny Texture Pack 2 by Screaming Brain Studios, https://opengameart.org/content/tiny-texture-pack-2, CC0 1.0
- Textures derived from ambientCG, https://ambientcg.com (CC0 1.0), and Poly Haven, https://polyhaven.com (CC0 1.0), downscaled to 64-128 px.

## Fonts
- Press Start 2P, Copyright 2012 The Press Start 2P Project Authors (cody@zone38.net), SIL Open Font License 1.1. OFL.txt is included at res://assets/fonts/OFL.txt.
- VT323, Copyright 2011 The VT323 Project Authors (peter.hull@oikoi.com), SIL Open Font License 1.1.

## Audio
- Sci-fi Sounds and Interface Sounds by Kenney, https://kenney.nl, CC0 1.0
- "Frequency Static Sound Effects" by bretbernhoft, https://opengameart.org/content/frequency-static-sound-effects, CC0 1.0
- Freesound sounds (one line per sound: "<title>" by <author>, https://freesound.org/s/<id>/, <CC0 | CC BY 4.0>)

## Tools
- Godot Engine, MIT License, https://godotengine.org
```

Keep a per-asset row (name, author, URL, license, download date, file path in project) as you import; a one-liner in the commit message when adding a pack keeps this honest.

## Recommended starter kit

| Need | Pick | License | Why |
|---|---|---|---|
| Characters | Quaternius Universal Base Characters (Standard) + Universal Animation Library (Standard) | CC0 on pack page; QAL v1.0 on license page (Trap 1) | Humanoid rig built for Godot retargeting, includes gun, death and crawl |
| Character fallback / PSX look | Kenney Blocky Characters; yugg0 Modern Rebel Soldier (PSX) | CC0; author terms | Zero-risk fallback; PSX soldier |
| Extra animations | Mixamo, locomotion "In Place" clips, kept out of public repo | Mixamo free terms | Fills stealth-walk and crouch gaps |
| Props/buildings | Kenney Survival Kit + City Kit (Industrial) + a few hand-built boxes/CSG | CC0 | Nothing CC0 military + PSX exists; build the rest |
| Textures | Screaming Brain Tiny Texture Pack 2 (128 px) + ambientCG/Poly Haven downscaled to 64 px | CC0 | Already low-res or easily crunched |
| Font | Press Start 2P (HUD), VT323 (codec text) | OFL 1.1 | Pixel, free to bundle; ship OFL.txt |
| SFX | Kenney Sci-fi Sounds + Interface Sounds, OpenGameArt radio static, Freesound CC0-filter only | CC0 | One license to track |
