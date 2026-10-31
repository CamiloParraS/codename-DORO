## The rules of a take, node-free: how long a skip hold takes, when the lower-third shows, how tall the
## letterbox bars are, and whether a take is the length its own data says it should be.
## A take's length range is per-take data: the AnimationPlayer's metadata `min_s` / `max_s`, else RANGE.
class_name CineLogic
extends RefCounted

const SKIP_HOLD := 0.6          # s the advance key is held to skip a take; a tap does nothing
const ASPECT := 2.39            # the bars frame the picture to this
const RANGE := Vector2(2.0, 10.0)  # s, a take's length when it declares none: takes are short
const LOWER_THIRD_AT := 0.3     # s into the take the lower-third starts fading in (over the first 2 s)
const LOWER_THIRD_IN := 0.4     # s it takes to fade in, and again to fade out
const LOWER_THIRD_HOLD := 3.0   # s into the take it starts fading out (earlier in a take too short for it)
const FADE_OUT := 0.6           # s an outro take spends fading to black at its end


## 0..1: how far a skip hold has come.
static func skip_progress(held: float) -> float:
	return clampf(held / SKIP_HOLD, 0.0, 1.0)


static func skip_done(held: float) -> bool:
	return held >= SKIP_HOLD


## Whether the skip ring is drawn: from the first frame the key is held, so the press is answered at once.
static func ring_shown(held: float) -> bool:
	return held > 0.0


## Whether a Mission's intro and outro takes play: the campaign and Mission-select replays do (skippable); Free mode does not
## (the Preset is the point). No settings toggle.
static func plays(campaign: bool, replay: bool) -> bool:
	return campaign or replay


## The lower-third's opacity `t` seconds into a take of `length`: in at `at` (default LOWER_THIRD_AT; a take may say its own
## in its metadata `third_at`), held, out before the take ends.
static func lower_third(t: float, length: float, at := LOWER_THIRD_AT) -> float:
	var out_at := minf(at - LOWER_THIRD_AT + LOWER_THIRD_HOLD, length - LOWER_THIRD_IN - 0.2)
	return minf(clampf((t - at) / LOWER_THIRD_IN, 0.0, 1.0), clampf((out_at + LOWER_THIRD_IN - t) / LOWER_THIRD_IN, 0.0, 1.0))


## Opacity of an outro take's black at `t` of `length`: 0 until FADE_OUT before the end, then up to 1.
static func black(t: float, length: float) -> float:
	return clampf((t - (length - FADE_OUT)) / FADE_OUT, 0.0, 1.0)


## Height in px of each bar for a viewport of `size`: nothing when the picture is already 2.39:1 or wider.
static func bar_height(size: Vector2) -> float:
	return maxf(0.0, (size.y - size.x / ASPECT) * 0.5)


## The [min, max] seconds this take may last: its own metadata, else RANGE.
static func range_of(player: AnimationPlayer) -> Vector2:
	return Vector2(float(player.get_meta("min_s", RANGE.x)), float(player.get_meta("max_s", RANGE.y)))


static func length_ok(player: AnimationPlayer, clip := "take") -> bool:
	if not player.has_animation(clip):
		return false
	var len := player.get_animation(clip).length
	var r := range_of(player)
	return len >= r.x and len <= r.y


## The Session log's line for a take.
static func log_line(key: String, skipped: bool, t: float) -> String:
	return "cine %s %s at %.1fs" % [key, "skipped" if skipped else "played", t]
