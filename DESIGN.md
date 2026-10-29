---
name: Ghost Layer
description: In-game UI for a short stealth game; an MGSV-craft tactical HUD on the Peace Walker layout, and Peace Walker grey-paper menus.
colors:
  # HUD (over the 3D scene). Hex with alpha is #RRGGBBAA, which Godot's Color.html() reads directly.
  ink: "#f2f4f3"
  ink-2: "#f2f4f3bd"
  ink-3: "#f2f4f38f"
  smoke: "#16191b8c"
  smoke-hi: "#16191bb8"
  hairline: "#f2f4f342"
  sand: "#d4bc8a"
  sand-dim: "#d4bc8a80"
  aigis-cyan: "#a9d6dc"
  damage-red: "#c9302a"
  alert-mark-red: "#e0423a"
  slp-blue: "#2c6aa3"
  dark-ink: "#0c0e0f"
  life-track: "#0c0e0f8c"
  radio-backing: "#0c0e0f99"
  jam-ground: "#150a0b"
  # Menus (Requisition and every between-Mission screen)
  menu-ground: "#cdcec9"
  menu-ground-hi: "#d8d9d4"
  menu-ground-lo: "#b9bab5"
  menu-paper: "#e4e4df"
  menu-white: "#f4f4f1"
  menu-detail: "#f4f4f1b8"
  menu-ink: "#2a2c2d"
  menu-ink-2: "#555958"
  menu-ink-3: "#6f7371"
  menu-faint: "#a7a9a4"
  menu-line: "#2a2c2d47"
  menu-line-strong: "#2a2c2d80"
  menu-select-red: "#c42032"
  menu-strip: "#2f3132"
  menu-strip-deep: "#232526"
  menu-strip-hover: "#45484a"
  drafting-ink: "#141617"
  drafting-fill: "#ecece8"
typography:
  # All sizes are px on the 1920x1080 logical canvas. Numerals always tabular + lining.
  hud-mark:
    fontFamily: "Barlow, sans-serif"
    fontSize: "60px"
    fontWeight: 700
    lineHeight: 1
  hud-count:
    fontFamily: "Barlow, sans-serif"
    fontSize: "46px"
    fontWeight: 600
    lineHeight: 1
    fontFeature: "tnum, lnum"
  hud-phase:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0.4em"
  hud-timer:
    fontFamily: "Barlow, sans-serif"
    fontSize: "26px"
    fontWeight: 600
    lineHeight: 1
    fontFeature: "tnum, lnum"
  hud-subtitle:
    fontFamily: "Barlow, sans-serif"
    fontSize: "24px"
    fontWeight: 500
    lineHeight: 1.4
  hud-label:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.26em"
  hud-ring-label:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.12em"
  hud-card-name:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "19px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.1em"
  hud-caption:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.14em"
  hud-chip:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "13px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0.1em"
  hud-keycap:
    fontFamily: "Barlow, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1
  menu-title:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: 1.02
    letterSpacing: "0.08em"
  menu-headline:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "34px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.08em"
  menu-figure:
    fontFamily: "Barlow, sans-serif"
    fontSize: "40px"
    fontWeight: 500
    lineHeight: 1
    fontFeature: "tnum, lnum"
  menu-rank-numeral:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "40px"
    fontWeight: 400
    lineHeight: 1
  menu-action:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.12em"
  menu-row-name:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "20px"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "0.1em"
  menu-strip-label:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.12em"
  menu-body:
    fontFamily: "Barlow, sans-serif"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.5
  menu-ticker:
    fontFamily: "Barlow, sans-serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: 1
  menu-label:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.14em"
  menu-caption:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.1em"
  menu-keycap:
    fontFamily: "Barlow, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1
  drafting-annotation:
    fontFamily: "Barlow Condensed, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "2px"
rounded:
  none: "0px"
  menu-sm: "2px"
  menu-md: "3px"
  hud-key-sm: "4px"
  menu-key: "5px"
  hud-key: "6px"
  full: "9999px"
spacing:
  hair: "2px"
  xs: "6px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  hud-edge: "64px"
  menu-edge: "72px"
components:
  hud-panel:
    backgroundColor: "{colors.smoke}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "12px 16px"
  hud-chip-slp:
    backgroundColor: "{colors.slp-blue}"
    textColor: "{colors.ink}"
    typography: "{typography.hud-chip}"
    rounded: "{rounded.none}"
    padding: "3px 5px 2px"
  hud-phase-alert:
    backgroundColor: "{colors.damage-red}"
    textColor: "{colors.ink}"
    typography: "{typography.hud-phase}"
    rounded: "{rounded.none}"
    padding: "10px 22px 9px 24px"
  hud-keycap:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.dark-ink}"
    typography: "{typography.hud-keycap}"
    rounded: "{rounded.hud-key}"
    size: "42px"
  hud-keycap-sm:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.dark-ink}"
    rounded: "{rounded.hud-key-sm}"
    size: "30px"
  hud-prompt-action:
    backgroundColor: "{colors.smoke-hi}"
    rounded: "{rounded.full}"
    size: "76px"
  hud-slot:
    backgroundColor: "{colors.smoke}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    width: "72px"
    height: "200px"
  hud-slot-selected:
    backgroundColor: "{colors.sand}"
    textColor: "{colors.dark-ink}"
    width: "72px"
    height: "220px"
  hud-life-bar:
    backgroundColor: "{colors.life-track}"
    width: "12px"
    height: "300px"
  menu-title-plate:
    backgroundColor: "{colors.menu-strip}"
    textColor: "{colors.menu-white}"
    typography: "{typography.menu-title}"
    rounded: "{rounded.menu-sm}"
    padding: "12px 20px 11px"
  menu-recruits-box:
    backgroundColor: "{colors.menu-white}"
    textColor: "{colors.menu-ink}"
    typography: "{typography.menu-figure}"
    rounded: "{rounded.menu-sm}"
    width: "360px"
    height: "54px"
  menu-prompt-strip:
    backgroundColor: "{colors.menu-strip}"
    textColor: "{colors.menu-white}"
    typography: "{typography.menu-strip-label}"
    rounded: "{rounded.menu-sm}"
    height: "44px"
    padding: "0 16px"
  menu-keycap:
    backgroundColor: "{colors.menu-white}"
    textColor: "{colors.menu-strip}"
    typography: "{typography.menu-keycap}"
    rounded: "{rounded.menu-key}"
    height: "30px"
    padding: "0 7px"
  menu-tab:
    textColor: "{colors.menu-ink-3}"
    rounded: "{rounded.menu-md}"
    width: "64px"
    height: "46px"
  menu-tab-selected:
    backgroundColor: "{colors.menu-white}"
    textColor: "{colors.menu-ink}"
  menu-cell-own:
    backgroundColor: "{colors.menu-strip}"
    textColor: "{colors.menu-white}"
    rounded: "{rounded.menu-md}"
    width: "104px"
    height: "88px"
  menu-cell-next:
    backgroundColor: "{colors.menu-white}"
    textColor: "{colors.menu-ink}"
    rounded: "{rounded.menu-md}"
    width: "104px"
    height: "88px"
  menu-cell-far:
    textColor: "{colors.menu-faint}"
    rounded: "{rounded.menu-md}"
    width: "104px"
    height: "88px"
  menu-drafting-plate:
    backgroundColor: "{colors.menu-detail}"
    textColor: "{colors.menu-ink}"
    rounded: "{rounded.menu-md}"
    height: "760px"
  menu-button-requisition:
    backgroundColor: "{colors.menu-strip}"
    textColor: "{colors.menu-white}"
    typography: "{typography.menu-action}"
    rounded: "{rounded.menu-md}"
    height: "62px"
    padding: "0 24px 0 12px"
  menu-button-requisition-hover:
    backgroundColor: "{colors.menu-strip-hover}"
  menu-button-requisition-disabled:
    textColor: "{colors.menu-ink-3}"
  menu-button-continue:
    backgroundColor: "{colors.menu-white}"
    textColor: "{colors.menu-ink}"
    rounded: "{rounded.menu-md}"
    height: "54px"
    padding: "0 20px 0 10px"
  menu-ticker:
    backgroundColor: "{colors.menu-strip}"
    textColor: "{colors.menu-white}"
    typography: "{typography.menu-ticker}"
    height: "52px"
  menu-ticker-tag:
    backgroundColor: "{colors.menu-strip-deep}"
    typography: "{typography.menu-label}"
    padding: "0 18px 0 72px"
---

# Design System: Ghost Layer

## Overview

**Creative North Star: "Smoked Glass, Grey Paper"**

Ghost Layer's UI has two materials. In play, information sits on smoked glass: charcoal panels at about half opacity over the PSX-era 3D, white Barlow type, hairline borders, and a muted sand accent on the corner brackets, the selection and the Operative's own readouts. The four corners of the screen each hold one kind of information, in fixed places, so the player knows where to look before they notice the style. Between Missions, the UI turns into grey paper: Peace Walker's light grey ground, charcoal plates, a red selection outline, and engineering drawings of the gear on a drafting grid.

Both materials are quiet by default and loud only when the game state is. The HUD stays near-monochrome while sneaking; ALERT is the one moment a solid red plate sits at top-centre and the Radar fills with red static. The UI renders at full resolution (1920x1080 logical) over the 854x480 3D render and never imitates the PSX look: no pixel fonts, no dithered chrome. It also refuses neon sci-fi: no glows, no scanline overlays on panels, no saturated cyan chrome.

All tokens are px values on the 1920x1080 logical canvas, ready for a Godot Theme and `ui/hud/hud_palette.gd`. The HTML mocks in `docs/ui-mock/` are the reference renders.

**Key Characteristics:**
- Smoked translucent panels with 1px hairlines and two sand corner brackets (top-left and bottom-right only).
- Barlow for figures and running text, Barlow Condensed in tracked uppercase for every label; numerals always tabular.
- Fixed corner map: Aigis top-left, phase top-centre, Radar top-right, life bottom-left, gear bottom-right.
- Corner clusters sit on a slight perspective tilt that follows the camera (MGSV parallax).
- Menus are flat grey paper with soft lift, red selection outlines, and drafted gear figures.

## Colors

The HUD is near-monochrome ink on smoke with one muted sand accent. Signal colours (red, blue, cyan) each carry exactly one meaning. The menus are a separate grey-paper palette.

### Primary
- **Muted Sand** (sand): the HUD's only accent. Panel corner brackets, the life fill and the OPERATIVE label, gear names, Habit pips that are on, the selected selector slot (solid fill), the active radio segment (at 78% alpha), the radio step name, the Operative's arrow on the Radar, and the Radar range rings (28% alpha) and edge ticks (70% alpha). It marks what belongs to the Operative and what is selected.
- **Sand Dim** (sand-dim): the half-strength sand for secondary accent strokes.

### Secondary
- **Damage Red** (damage-red): danger. The ALERT plate, life lost (the trailing segment that drains after a hit), the ALERT detection arc (14px stroke), the Radar blip of a guard with a pending radio call (flashing), and the 70% edge of the jammed Radar.
- **Alert Mark Red** (alert-mark-red): a lighter red used only for the 72px `!` over a guard, so the glyph stays readable against the dark scene.
- **SLP Blue** (slp-blue): non-lethal. The SLP chip on a tranquilliser weapon card, nothing else.

### Tertiary
- **Aigis Cyan** (aigis-cyan): Aigis, and only Aigis. The Voice cue (icon and name, e.g. PALLAS) and the rise arrow on a Habit Aigis has noticed going up.

### Neutral (HUD)
- **Ink** (ink): primary text and figures, icon silhouettes, the keycap face, the `?` mark, the filled part of the noticing arc.
- **Ink 2** (ink-2, 74%): secondary text: the call tag, crumb names, the codec waveform.
- **Ink 3** (ink-3, 56%): tertiary text: reserve counts ("/ 4"), radio labels that are not hovered, hints, empty slot names.
- **Smoke** (smoke, 55%): every panel, the Radar disc, selector slots. A 7% ink gradient over the top 40% gives the glass its sheen.
- **Smoke Hi** (smoke-hi, 72%): the round action disc of a contextual prompt.
- **Hairline** (hairline, 26%): 1px borders on panels, slots, the Radar disc, the life track, the codec portrait.
- **Dark Ink** (dark-ink): legends on light fills (keycaps, the selected slot), the radio centre dot.
- **Life Track** (life-track): the empty well of the life bar.
- **Radio Backing** (radio-backing): the radial gradient behind the radio ring (60% to transparent between 50% and 70% of its radius).
- **Jam Ground** (jam-ground): the ground under the jammed Radar's static.

### Menu palette
- **Menu Ground** (menu-ground), with **Ground Hi** and **Ground Lo**: the Peace Walker grey, laid as a soft radial (120% x 90% at 70% / 40%: hi, ground at 55%, lo at the edge) under a multiply noise grain at 35%.
- **Menu Paper** (menu-paper) and **Menu White** (menu-white): raised surfaces: the recruits box, next cells, the selected tab, keycap faces, the Continue button. **Menu Detail** (menu-detail, 72%) is the drafting plate.
- **Menu Ink** (menu-ink): soft black text. Peace Walker never goes to pure black on the grey. **Ink 2** and **Ink 3** step down for row names, labels and captions; **Menu Faint** (menu-faint) is for locked and out-of-reach content only.
- **Menu Line** (menu-line, 28%) and **Line Strong** (menu-line-strong, 50%): 1px rules and borders; strong for the tab rule and the selected tab.
- **Menu Strip** (menu-strip), **Strip Deep** (menu-strip-deep), **Strip Hover** (menu-strip-hover): the charcoal plates (title, prompt strip, own cells, the Requisition button, the ticker), the ticker tag, and the button hover.
- **Menu Select Red** (menu-select-red): selection in menus. The 3px outline around the selected cell, its caption, focus rings, the recruits-signed banner, and the spend tick on the recruit count.
- **Drafting Ink** (drafting-ink) and **Drafting Fill** (drafting-fill): line work and body fill of the gear drawings.

### Named Rules
**The Cyan Is Aigis Rule.** Aigis Cyan appears only where Aigis is speaking or measuring the player: Voice cues, Habit changes, Aigis-side debug readouts. Metis, the Handler and the player's own gear never use it.

**The One Meaning Rule.** Red is danger, blue is non-lethal, cyan is Aigis, sand is the Operative and selection. No colour is borrowed for decoration.

**The Never By Hue Alone Rule.** Every state that has a colour also has a second cue: ALERT is a plate with a word and a timer; the jammed Radar has static, rolling bands and the word JAMMED; the selected slot is 20px taller and solid; the selected menu cell has an outline offset 4px; an on Habit pip is filled where an off one is a 25% track; the calling guard's blip flashes.

## Typography

**Display / Figure Font:** Barlow (sans-serif fallback), weights 400 to 700.
**Label Font:** Barlow Condensed (sans-serif fallback), weights 400 to 700.

**Character:** a plain, engineered grotesque. Barlow carries numbers and sentences; Barlow Condensed carries every label in tracked uppercase, which is what makes the UI read as military kit rather than app chrome. Both are OFL and need to be shipped in `assets/fonts/`.

### Hierarchy
- **Mark** (Barlow 700, 60px; `!` at 72px): the `?` and `!` over a guard's head.
- **Count** (Barlow 600, 46px weapon / 34px item, tabular): ammo and item counts on gear cards; the reserve after the slash is Barlow 500 20px in Ink 3.
- **Phase** (Barlow Condensed 700, 26px, 0.4em tracking, uppercase): ALERT. The timer beside it is Barlow 600 26px, tabular.
- **Subtitle** (Barlow 500, 24px, 1.4 line height): codec subtitle during play, wrapped at the 560px call column.
- **Label** (Barlow Condensed 600, 22px, 0.26 to 0.3em tracking, uppercase): the Aigis Voice name, the OPERATIVE label running up the life bar.
- **Ring label** (Barlow Condensed 600, 20px, 0.12em, uppercase): radio options, with the option number at 70% opacity ahead of the label; the step name in the ring centre is the same size at 0.24em in sand.
- **Card name** (Barlow Condensed 600, 19px, 0.1em, uppercase): gear names on cards; selector slot names are 17px set vertically.
- **Caption** (Barlow Condensed 600, 15 to 17px, 0.14 to 0.16em, uppercase): call tag, radio crumb and hints, referent tags.
- **Chip** (Barlow Condensed 700, 13px, 0.1em): the SLP chip.
- **Menu title** (Barlow Condensed 600, 30px, 1.02 line height, 0.08em): the title plate, set on two lines (METIS / REQUISITION).
- **Menu headline** (Barlow Condensed 500, 34px, 0.08em, uppercase): the selected gear's name in the drafting plate.
- **Menu figure** (Barlow 500, 40px, tabular): the before → after effect values; the recruit count is 36px.
- **Rank numeral** (Barlow Condensed 400, 40px): column heads 1 / 2 / 3, with RANK above in 13px 0.16em.
- **Menu action** (Barlow Condensed 600, 22px, 0.12em, uppercase): the Requisition button; Continue is 20px.
- **Row name** (Barlow Condensed 500, 20px, 0.1em, uppercase): rank-grid row names, with a Barlow 500 15px sentence-case subline.
- **Strip label** (Barlow Condensed 500, 18px, 0.12em, uppercase): prompt-strip verbs.
- **Menu body** (Barlow 400, 18px, 1.5, max 54ch): gear descriptions.
- **Menu label / caption** (Barlow Condensed 500, 15px at 0.14em / 14px at 0.1em, uppercase): box labels, effect labels, cell captions, the ticker tag.
- **Drafting annotation** (Barlow Condensed 600, 17px, 2px tracking, uppercase): dimensions and callouts inside the drawings.

### Named Rules
**The Condensed Labels Rule.** Labels are Barlow Condensed, uppercase, tracked 0.1em or wider. Figures and sentences are Barlow, never tracked. A label set in Barlow, or a number set in Condensed (rank numerals aside), is off-system.

**The Tabular Figures Rule.** Every number that changes (counts, timers, recruit points, effect values) uses tabular lining figures so it never shifts as it ticks.

## Layout

**HUD corner map (1920x1080).** The edge margin is 64px (Aigis and the phase plate sit at top 52px, the Radar at top 48px).
- **Top-left:** Aigis cue. Voice icon (26px) plus name, with the Habit strip 14px below: six 32px stroke icons 20px apart, each with three 8x3px pips. Drawn at 90% opacity; it can be switched off and steps back while the radio is open.
- **Top-centre:** phase plate, ALERT only.
- **Top-right:** Radar, a 300px disc.
- **Middle-left:** codec call during play, at left 64px, top 400px, 560px wide: an 84px portrait, then tag and subtitle.
- **Centre-left:** radio ring, centred at (516, 530).
- **Lower-middle:** contextual prompt, centred at x 960, top 850px.
- **Bottom-left:** life, a 12x300px vertical bar with OPERATIVE running bottom-to-top 24px to its right.
- **Bottom-right:** gear, 320px wide: the item card (220x84px, right-aligned) stacked 12px above the weapon card (320x118px). The selector opens to their left (336px from the right edge of the cluster, slots 6px apart).
- **World-anchored:** `?` / `!` over the guard's head, detection arcs around the screen centre, radio referent brackets around the targeted guard.

**Requisition layout (1920x1080).** The edge margin is 72px.
- Title plate top-left (72, 52); recruits box top-right (360x54px at top 48px); prompt strip from x 300 to the right margin at top 112px (44px tall). While the recruits-signed banner shows (under the recruits box, top 118px), the strip's right edge pulls in to 290px.
- Left column (72px to 1072px): icon tabs at top 176px over a 1px strong rule at top 222px, the category name at top 236px, then the rank grid at top 268px: a 220px name column plus three equal rank columns, a 48px header row and 148px rows.
- Right column: the drafting plate from x 1120px to the right margin, top 176px, 760px tall. The drawing area is its top 430px on a 32px grid; the info block starts at 450px with 32px side insets.
- Continue button bottom-right, 76px above the bottom edge; the 52px ticker spans the full bottom edge.
- Backdrop: the Metis emblem (1100px) and gear icons as watermarks, blurred 14px at 22% opacity.

**Rhythm.** Spacing steps are 2, 6, 8, 12, 16 and 20px; gaps inside clusters are 6 to 16px. Clusters are separated by whole screen regions, not by stacking panels.

## Elevation & Depth

The HUD is flat glass and gets its depth from translucency and perspective, not from shadows: panels are smoke over the scene, and each corner cluster is rotated in 3D toward the screen centre. Shadows appear only where an opaque object needs to lift off a moving scene (the ALERT plate, keycaps) and as dark legibility halos under text that sits directly on the 3D. The menus are paper with a soft, low lift: small blurred shadows at 8 to 20% black, never a coloured shadow.

### Shadow Vocabulary
- **Plate lift** (`0 4px 16px rgba(0,0,0,.35)`): the ALERT plate.
- **Keycap lift (HUD)** (`0 3px 8px rgba(0,0,0,.5)`): HUD keycaps over the scene.
- **Keycap skirt (menu)** (`0 2px 0 rgba(0,0,0,.25), inset 0 -2px 0 rgba(42,44,45,.18)`): the visible lower edge of a physical key. Only on menu keycaps.
- **Paper lift** (`0 2px 6px rgba(0,0,0,.12)` to `.18`): title plate, recruits box, Continue button.
- **Cell lift** (`0 2px 5px rgba(0,0,0,.2)`): own rank cells. **Button lift** (`0 3px 8px rgba(0,0,0,.2)`): the Requisition button. **Plate float** (`0 2px 10px rgba(0,0,0,.08)`): the drafting plate.
- **Subtitle halo** (text: `0 2px 6px rgba(0,0,0,.9), 0 0 2px #000`): text over the 3D with no panel behind it.
- **Mark halo** (text: `0 2px 0 #000, 0 0 12px rgba(0,0,0,.6)`): the `?` and `!` marks.

### Named Rules
**The Parallax Tilt Rule.** Left-corner clusters pivot on their left edge at `rotateY(6deg)`, right-corner clusters on their right edge at `rotateY(-6deg)`, under a 1400px perspective. Camera or mouse motion adds up to ±2deg yaw and ∓1.5deg pitch, eased over 500ms. Centred elements (phase plate, prompt, radio, call) do not tilt.

**The Dark Halo Rule.** Shadows are black and lift or separate; nothing glows. A coloured or light shadow is off-system.

## Shapes

The HUD is square. Panels, slots, chips and plates have 0 radius, and their corners are marked by brackets instead of rounding: two 10x10px L-shapes in 2px sand at the top-left and bottom-right corners, offset 3px outside the hairline border. The only round forms in play are the ones that are round as objects: the Radar disc, the prompt's action disc, keycaps (6px, or 4px when small), and the radio ring. Radio referent brackets are 22px L-shapes in 2px ink on the targeted guard. Menus soften slightly: 2px on plates and the recruits box, 3px on cells, buttons, tabs (top corners only) and the drafting plate, 5px on keycaps. Empty and out-of-reach things are drawn with dashed borders: empty selector slots, far rank cells, the disabled Requisition button.

## Components

### Panel (gear card)
The base HUD surface.
- **Fill:** smoke, with an ink gradient (7% at the top, transparent at 40%) for sheen; 1px hairline border; 0 radius.
- **Brackets:** sand L-shapes at top-left and bottom-right (10px, 2px stroke, offset 3px).
- **Content:** card name top-left in sand (Card name style) with an optional chip; a solid ink silhouette of the gear bottom-left; the count bottom-right (Count style), reserve in Ink 3.
- **Padding:** 12px 16px.

### Chip
- **SLP:** slp-blue fill, ink text, Chip style, 3px 5px 2px padding, square. It follows the weapon name.

### Keycap prompt
A key drawn as a key.
- **HUD keycap:** a 42px square, 6px radius, ink face, dark-ink legend (Barlow 700 20px), HUD keycap lift. **Small:** 30px, 4px radius, 14px legend. **Wide:** auto width with 8px side padding, for LMB / RMB.
- **Contextual prompt:** keycap, then a 76px round action disc 14px to its right (smoke-hi, 1px hairline) holding a 50px solid ink pictogram of the action. No text.
- **Legend:** always the bound input's name, read from the input map, never a decorative glyph.

### HUD states
- **Sneak:** the base layout. The contextual prompt shows when an action is available; nothing else is extra.
- **Noticed:** `?` over the guard (Mark style, ink). A detection arc around the screen centre on the guard's bearing: a 2px track at 28% ink and a 10px ink fill that grows as the guard's suspicion rises and drains as it falls.
- **Alert:** the phase plate appears at top-centre: one damage-red plate holding the word (ALERT, ALERTA) and, behind a 1px 45% white divider, the countdown timer. `!` over the guard (alert-mark red, 72px, pops in). The arc becomes a solid 14px damage-red stroke. The Radar is fully jammed: jam-ground with animated red fractal static, rolling 2px dark bands every 6px, a 70% red rim, and JAMMED centred (Barlow Condensed 700 20px, 0.32em). Nothing of the Radar shows through. Life drains: the fill drops at once and the red lost segment follows after 400ms.
- **Selector:** Peace Walker's selector, scaled down, opening left of the gear cards. Slots are 72x200px smoke columns with a hairline border, the name set vertically top-left, the gear silhouette rotated -90°, and a 28px count band at the foot behind a hairline. The selected slot is solid sand with dark-ink content and 20px taller (220px). Empty slots are 30% smoke with a dashed border and an Ink 3 name. Two small keycaps sit 40px under the row.
- **Radio:** the segmented ring from `ui/radio/radio.gd`, centred left of centre at (516, 530): mean radius 114px, ring width 84px (inner 72, outer 156), one arc per option starting at the top, 0.04 rad gap on each side. The hovered segment is sand at 78%, the others ink at 14%. Option labels sit outside the ring (number at 70% + label, Ink 3, sand when hovered), the step name in the centre in sand, the crumb (GUARD05 › PATROLLER 2) above, keycap hints below (LMB OK · RMB Back · Q Close). The scene drops to 80% grayscale at 55% brightness; gear and the Aigis cue fade out; the target guard gets ink referent brackets with its name above.
- **Call:** a codec subtitle at middle-left without a panel: an 84px portrait (grayscale, contrast 1.3, a 4px halftone dot overlay, hairline border), then a tag row (four-bar animated waveform, CALL ›› and the speaker's name) and the subtitle in Subtitle style with the subtitle halo.

### Radar
- **Disc:** 300px, smoke with a hairline border. Range rings at r 48 and 96 in sand at 28%; N/E/S/W ticks (14px, 2px) in sand at 70%; an N label in Barlow Condensed 600 16px.
- **Marks:** the Operative is a sand arrow with a 1.5px dark-ink keyline at the centre; guards are ink triangles with a fading ink view cone (36% to 0); a guard beyond range is pinned to the edge at 55% ink; a calling guard's triangle is damage red, flashing every 300ms.
- **Jammed:** see the Alert state.

### Life bar
- **Track:** 12x300px life-track well, 1px hairline.
- **Fill:** sand, 2px inset. The lost segment behind it is damage red and drains after a 400ms delay.
- **Label:** OPERATIVE in Label style, sand, running bottom-to-top.

### Habit strip (Aigis)
- Six 32px stroke pictograms (2.4px ink stroke, round caps) at 62% opacity, 20px apart; one Aigis has seen rising is at full opacity with an 11px cyan rise triangle at its top-right.
- Three 8x3px pips under each, 2px apart: sand when on, 25% ink when off.

### Title plate (menu)
- Menu-strip fill, menu-white text in Menu title style, 2px radius, paper lift, 12px 20px 11px padding.

### Recruits box
- 360x54px, menu-white, 1px menu-line border, 2px radius, paper lift. Recruit pictogram (26px), RECRUITS in Menu label style, the count right-aligned (Barlow 500 36px, tabular). On spend the number ticks in from red and 5px up over 450ms. The recruits-signed banner (red fill, white Condensed 600 15px) shows under it for 3.4s after a Mission.

### Prompt strip
- A 44px menu-strip bar with a white left-pointing triangle marker at its far left and the prompts right-aligned 26px apart. Each prompt is one or two menu keycaps then its verb in Strip label style (↑ ↓ Choose gear · ← → Switch tab · Esc Skip for now).
- **Menu keycap:** menu-white face, menu-strip legend (Barlow 600 16px), min 34x30px with 7px padding, 5px radius, keycap skirt. In the Requisition button it grows to 40x38px with a 19px legend; on the Continue button it inverts to a strip face with a white legend.

### Tabs
- 64x46px icon tabs, 4px apart, top corners 3px, 1px menu-line border, no bottom border. **Idle:** 8% ink fill, Ink 3 icon. **Selected:** menu-white fill, menu-ink icon, 50% border. Focus is a 2px red outline offset 2px. The category name under the rule names the selected tab.

### Rank grid
- Rows are 148px with a 220px name column (row name and its current-value subline); the current row's name is full ink. Cells are 104x88px boxes, joined by 1px 40% ink links at the box's vertical midpoint.
- **Own:** strip fill, white pictogram (48px) and ×value bottom-right, cell lift, caption (gear name) in full ink under it.
- **Next:** menu-white fill, 1px 55% ink border, the cost (recruit glyph + number) top-left, pictogram (44px), ×value bottom-right. At 55% opacity when the player cannot afford it.
- **Far:** no fill, 1px dashed 30% ink border, a faint lock pictogram.
- **Selected:** a 3px menu-select-red outline offset 4px around the box, and the caption turns red.
- The S-rank items tab uses one cell per row: own (earned) or far (locked), captioned with the condition.

### Drafting plate
- menu-detail paper, 1px menu-line border, 3px radius, plate float.
- **Drawing area:** the top 430px on a 32px grid of 7% ink lines, with a bottom rule. The gear drawn as an engineering drawing (2.4px drafting-ink outlines, drafting-fill bodies, 45° hatching at 7px, dimension lines with arrowheads, leader callouts) in Drafting annotation type, at 82% opacity, fading in over 250ms when it changes.
- **Title block:** top-left, the part name in Ink 2 weight 600 over the drawing number and scale (METIS R&D · DWG GL-01 · 1:2) in Ink 3, Menu caption style at 1.3 line height.
- **Info:** gear name (Menu headline), the effect label then before → after values (Menu figure; the before value faint, an arrow between them), the description (Menu body, max 54ch).
- **Action row:** the Requisition button (strip fill, keycap E + "Requisition for N Recruits", 62px tall, hover to strip-hover, red focus ring). **Disabled:** transparent with a dashed faint border, Ink 3 text and a faint keycap, with the reason beside it in Barlow 400 16px Ink 3.

### Continue button
- 54px, menu-white, 1px menu-line border, 3px radius, paper lift; an inverted keycap (C) then "Continue to Briefing" in Condensed 600 20px.

### Ticker
- A 52px menu-strip band across the bottom edge. The tag block (strip-deep, 72px left inset) names the speaker in Menu label style; the line runs in Menu ticker style, scrolling at 30s per pass after a 2s hold.

### Motion
- One easing for everything that settles: `cubic-bezier(.16, 1, .3, 1)`. State elements fade over 220ms; the scene dims for the radio over 350ms; the tilt follows over 500ms; the life fill moves over 500ms and the lost segment over 1.2s after 400ms.
- Feedback motions: the `!` pops from 40% scale over 280ms with a slight overshoot (`cubic-bezier(.34, 1.56, .64, 1)`); a calling blip flashes on a 300ms step; the jam bands roll every 1.2s and the static reseeds every 0.4s; the codec waveform pulses on 0.9s.
- With reduced motion, every animation and transition is off.

## Do's and Don'ts

### Do:
- **Do** keep every HUD element in its corner from the layout map; a new readout joins the cluster it belongs to rather than taking a new spot.
- **Do** draw HUD panels as smoke (55%) with a 1px hairline (26%) and the two sand corner brackets, at 0 radius.
- **Do** pair every coloured state with a shape, word, size or motion cue (ALERT plate with word and timer, JAMMED static, the taller selected slot, the offset red outline).
- **Do** set labels in Barlow Condensed, uppercase, tracked 0.1em or more, and every changing number in tabular figures.
- **Do** make contextual prompts a keycap plus a pictogram disc, and make every keycap legend the bound input's real name.
- **Do** check that English and Spanish both fit (ALERT / ALERTA, JAMMED / BLOQUEADO, Tranq pistol / Pistola tranq.).
- **Do** draw every emblem, portrait, pictogram and gear drawing originally.

### Don't:
- **Don't** put text on a contextual prompt; the pictogram is the verb.
- **Don't** signal state by hue alone.
- **Don't** use Aigis Cyan for anything that is not Aigis: not Metis, not the Handler, not the player's gear, not focus rings.
- **Don't** ship Konami assets: no MGS portraits, MSF logo, item icons, button art or screen captures.
- **Don't** use neon, glows, coloured shadows, bloom or scanline overlays on panels and text; the only shadows are black. The jammed Radar's rolling bands are the one banded surface, because they depict signal loss.
- **Don't** imitate the PSX look in the UI: no pixel fonts, no dithered chrome, no low-res UI textures.
- **Don't** let anything show through the jammed Radar.
- **Don't** use pure black text on the menu grey; use Menu Ink.
