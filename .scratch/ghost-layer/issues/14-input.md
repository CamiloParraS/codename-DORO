# Input

Type: grilling
Status: resolved
Blocked by:

## Question

Which input devices does the game support: keyboard+mouse, gamepad, or both? What is the binding for every verb settled so far: movement, crouch, the shoulder swap, aiming and firing the tranq pistol and rifle, takedowns (choke or kill), carrying and dropping bodies, the knock, the radio radial (with slowed time), cycling and using items (Scanner, Magazine), and calls into the codec? Is rebinding required, and which settings (sensitivity, invert) ship?

## Comments

- 2026-10-09 (from the map's fog): the item cycle/use bindings were deferred here by [Gadgets and items](12-gadgets-and-items.md). The radial menu comes from [Spoofing prototype](05-spoofing-prototype.md), and the shoulder swap from [Core stealth feel prototype](04-stealth-core-prototype.md).

## Answer

**Devices:** keyboard and mouse only. Every binding goes through a named InputMap action (no hardcoded keys as in the prototypes), so a gamepad would be a mapping job later. Gamepad support is out of scope.

**Bindings:**

| Verb | Binding |
|---|---|
| Move | WASD (default pace is running) |
| Walk (quiet) | hold Shift |
| Crouch | C or Ctrl, toggle |
| Shoulder swap | Tab |
| Aim / fire | hold RMB / LMB. Firing works only while aiming; there is no hip fire |
| Weapons | 1 tranq pistol, 2 rifle |
| Reload | R |
| Item cycle / use | mouse wheel / F. Scanner: tap. Magazine: hold to show the arc, release to throw, RMB while holding cancels |
| Interact (context) | E: choke takedown, pick up or drop a body (toggle), resupply crate |
| Kill takedown | X |
| Knock | V |
| Radio radial | Q toggles it open (time slows). Mouse points, LMB confirms, RMB goes back, 1–9 are shortcuts, Q/Esc closes |
| Codec advance | LMB / Space / Enter |
| Pause | Esc (controls list, current objective, settings) |
| Debug overlay | F3, everywhere including the campaign (for the live demo) |

F8 stays unbound because it stops a game launched from the editor. Eavesdropping needs no key: staying within 6 m during a check-in records the Voiceprint.

**Takedowns:** choke and kill use separate keys, and both show as a prompt when in range ("E choke · X kill"). A kill always takes a deliberate press on a key used for nothing else, because it moves Lethality.

**Carry:** E toggles it (E picks the guard up, E drops them). This replaces "releasing the button drops the guard" in [Combat verbs and Lethality](07-combat-verbs-lethality.md): holding E while using WASD is awkward on a keyboard.

**Reload:** the tranq pistol holds 4 darts per magazine (8 total), the rifle 30 rounds (60 total). A reload takes ~1.5 s and is silent. It happens automatically when firing on an empty magazine, and R reloads early. No reloading while carrying a body (the pistol is one-handed then). HUD E's pip column shows the current magazine and the weapon card shows the reserve. Numbers are build-time tuning.

**Knock:** anywhere, with a 1 s cooldown, heard from the Operative's position (as in the prototype). No wall needed.

**Codec calls:** all scripted, and the player can't call Metis. The current objective lives on the pause screen instead.

**Settings:** no rebinding; the pause screen shows a fixed controls list. Settings: mouse sensitivity, invert Y, language (EN/ES), fullscreen/windowed, master volume.
