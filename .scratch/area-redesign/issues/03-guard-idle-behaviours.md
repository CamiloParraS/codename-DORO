# Guard idle behaviours for placement

Type: grilling
Status: resolved
Blocked by: 01

## Question

Which 2–3 cheap new guard idle behaviours give level design the placements that MGS-style layouts need? Settled input from the Crawlspace and Ladder rules: one of the 2–3 is a **look-in** patrol stop at a Crawlspace mouth (face the tunnel axis for about 3 s; guards never enter), which the extra-patrol Countermeasure uses. Candidates: a posted sentry who scans an arc, a conversation pair that stays put and chats, or a patrol stop that looks out over a view.

For each one, settle:
- what it does;
- how it fits the existing behaviour tree as a branch that runs during patrol;
- how it interacts with check-ins and Voiceprints (a chatting pair is a natural eavesdrop spot);
- how an Area declares it for a given guard post.

## Answer

**Three behaviours, four placements.** All three live in `Guard.patrol()`, with no change to the behaviour tree. A route point carries a facing and a hold time as well as a position. An Area declares each behaviour as metadata on the Markers it already has, so the shared Area script reads nothing new and existing routes work as they do now.

**1. Facing stop (look-in and look-out)**
- **Does:** a waypoint with `hold` meta (seconds) turns the guard to face the Marker's own facing (−Z) and holds there for that long. A look-in faces the Crawlspace axis for about 3 s; a look-out faces a view for longer, as the diagram sets it. A waypoint without `hold` keeps today's 1.5 s pause with no turn.
- **Tree:** the patrol pause reads the point's facing and hold. Any state change already restarts the tree, so a guard drops the stop the moment it sees or hears something. The Takedowns L1 glance behind still overrides it.
- **Check-ins / Voiceprints:** unchanged. A holding guard checks in as normal.

**2. Scan**
- **Does:** an optional `scan` meta (degrees) on any stop sweeps the facing back and forth across that arc around the Marker's facing, on a smooth sine with a period of about 6 s. With the ±30° front cone, a 90° scan covers 150°. The side it isn't facing gets only the 6 m peripheral cone, so a chokepoint has a rhythm to time. A post with no waypoints, `scan` set and no `hold` sweeps forever: that's the **scanning post**. A patrol stop can scan too, for example a look-out sweeping a yard.
- **Sentries:** `sentry_high_point` Markers read the same `scan` meta. Whether a given sentry scans is a placement call made in each Area diagram.
- **Check-ins / Voiceprints:** unchanged.

**3. Chatting pair**
- **Declared:** a guard post with `chat` meta spawns two guards, one on each side of the post along its X axis, 2 m apart and facing each other. Each guard's own spot is where it returns. It counts as 2 toward the Area's guard count. Takedowns L2's `_pair_up` already skips guards without a route.
- **Does:** they stay put and take turns speaking. A small node-free `Chat` timer shared by the pair (like `Checkin`) runs A 3 s, B 3 s, then about 4 s of quiet, on a loop, in PATROL only. Each guard also keeps its normal radio check-ins.
- **Voiceprints:** the guard currently speaking shows ((·)) and can be recorded under check-in rules (within 6 m, 2.5 s). This is the deception Approach's dependable eavesdrop spot.
- **Lines:** chat isn't radio. Two or three short lines per guard appear as a subtitle only while the Operative is within about 10 m, and stay out of the radio log.
- **Takedowns:** each guard's front cone covers the other's back, so you can't choke one unseen. The pair is a place to eavesdrop, not a Takedown target. Darting one from range works, and the other reacts to a Down guard by the existing rules.
- **Alerts / orders:** each guard acts alone (alert, search, Spoofed order), then walks back to its own spot, and the chat resumes. A Checkpoint restore resets the pair with the rest.

**Glossary / ADR:** neither. These are placement tools, not player-facing terms, and all of them are cheap to change.
