# 33: Menus, saves, settings, Custom Preset

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The game has its shell: main and pause menus, three autosave campaign slots written on Mission completion, a settings file, and Custom sliders in Free mode.

**Blocked by:** 22, 18

**Status:** ready-for-agent

- [ ] Main menu: Continue (most recently written unfinished slot; hidden if none), New game, Load, Free mode, Settings, Quit
- [ ] The slot picker shows each slot's next Mission or "Complete" and last-saved time; overwriting asks for confirmation
- [ ] A slot stores next Mission index, Habit points, Lethality, denominator and a complete flag; written after the post-Mission screen, and at the Core terminal (marking it complete); an unreadable file is an empty slot
- [ ] Loading a complete slot replays the finale and returns to the menu
- [ ] Pause menu: Resume, Restart from checkpoint, Abort Mission (back to the Briefing, nothing applied), Settings, Quit to menu (confirmed); shows the controls list and current objective
- [ ] Settings (sensitivity, invert Y, language EN/ES live, fullscreen/windowed, master volume) in their own file, surviving New game
- [ ] Free mode Custom: a slider per Habit (0–3) and a ratio slider (0–1), starting from Clean slate; Free mode writes nothing
