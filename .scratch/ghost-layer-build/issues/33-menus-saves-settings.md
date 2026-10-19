# 33: Menus, saves, settings, Custom Preset

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The game has its shell: main and pause menus, three autosave campaign slots written on Mission completion, a settings file, and Custom sliders in Free mode.

**Blocked by:** 22, 18

**Status:** ready-for-agent

- [ ] Main menu: Continue (most recently written unfinished slot; hidden if none), New game, Load, Free mode, Settings, Quit
- [ ] The slot picker shows each slot's next Mission or "Complete" and last-saved time; overwriting asks for confirmation
- [x] A slot stores next Mission index, Habit points, Lethality, denominator and a complete flag; written after the post-Mission screen, and at the Core terminal (marking it complete); an unreadable file is an empty slot
- [ ] Loading a complete slot replays the finale and returns to the menu
- [ ] Pause menu: Resume, Restart from checkpoint, Abort Mission (back to the Briefing, nothing applied), Settings, Quit to menu (confirmed); shows the controls list and current objective
- [ ] Settings (sensitivity, invert Y, language EN/ES live, fullscreen/windowed, master volume) in their own file, surviving New game
- [x] Free mode Custom: a slider per Habit (0–3) and a ratio slider (0–1), starting from Clean slate; Free mode writes nothing

## Comments

- 2026-10-19 (review): the slot is now marked complete at the Core terminal (when the finale begins), not at the Core's post-Mission commit.
- 2026-10-19 (implementation): `missions/save_slots.gd` (`SaveSlots`, tested) and `ui/settings/game_settings.gd` (`GameSettings`, tested; `user://settings.json`, untouched by New game) are node-free. Screens built but not played: `ui/main_menu/` (Continue/New/Load/Free mode/Settings/Quit, overwrite confirm, now the main scene), `ui/settings/settings_panel.gd`, the pause menu rewrite (`ui/pause/pause.gd`: objective, controls from InputMap, Resume/Restart/Abort/Settings/Quit with confirm), Free mode's NEW CAMPAIGN swapped for BACK. The Operative reads sensitivity/invert Y from `GameSettings.current`. `MissionRun` writes `Campaign.slot` when the post-Mission screen commits (the Core's commit marks the slot complete; there is no separate Core terminal yet). Headless suites: `godot --headless --path . tools/run_tests.tscn -- test_save_slots`.
- Left to a playtest: the menus and pause flows by hand (focus, mouse capture after Resume/Abort, overwrite and quit dialogs under pause), loading a complete slot replaying the finale then returning to the menu, language/fullscreen/volume applying live, and menu text is not in `lines.csv` (EN only) so ES covers only existing keys. Status stays `ready-for-agent` until then.
