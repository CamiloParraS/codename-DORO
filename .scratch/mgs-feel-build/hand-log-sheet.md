# Hand-log sheet (fallback if the session logger fails)

Observer stays silent. One sheet per tester. Definitions match `ai/session_log.gd` exactly.

Tester: ______  Date: ______  Session start: ______ (cap 45 min)

## Per Mission (1 Harbour, 2 Relay Station, 3 Annex, 4 Core)

| Mission | Start | End | Time (min) | Tranq darts fired | Rifle shots fired | Spoof sends | Idles over 60 s (length each) |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |
| 4 | | | | | | | |

## Definitions

- **Mission time:** from the Mission starting to Extraction, minus time on the pause screen. Alert and death-retries count.
- **Dart / rifle shot:** each trigger pull that actually fired (not an empty click).
- **Spoof send:** each Spoofed transmission the Operative sends from the radio menu, including a report-in to HQ, whether it is believed or exposed. Mark each one "prompted" if the Mission 1 tutorial had just told them to (feel bar item 5 needs one that was not).
- **Progress event:** an objective step done (intel picked up), a Checkpoint taken, or an Alert (Alert or Evasion) ending.
- **Idle:** seconds since the last progress event, not counting any time a guard is in Alert or Evasion. At a progress event, or the Mission ending, an idle over 60 s is written down with its length (one line per idle, not per minute). Over 90 s fails feel-bar item 2.

## Notes

Each time you would have spoken: ______ (each is one fail of item 2).
Each death / Alert cause: ______
Closing question, "Where were you least sure what to do?": ______
