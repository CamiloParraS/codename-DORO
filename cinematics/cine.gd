## Plays a take: one continuous camera move in the live Area, driven by the AnimationPlayer at `Cine/<key>` (clip "take").
## While it runs the Operative takes no input (`cine`), the HUD is hidden, the MissionRun's clocks hold (`take_playing`)
## and letterbox bars frame the picture; the tree is NOT paused, so guards idle and the fog moves.
## It ends on the clip's last frame, or when the advance key is held for CineLogic.SKIP_HOLD (a tap does nothing).
## Then the take's pcams drop below GameplayCam, the host tweens to the shoulder rig, and `then` runs once
## control is back. An outro (`fade_out`) instead ends on black with the Operative still locked: the Mission is over.
## A take's pcams are listed in the AnimationPlayer's metadata `pcams` (paths relative to the player); see tools/area_cine.gd.
class_name Cine
extends Node

signal finished(skipped: bool)
signal held(skipped: bool)   # a `hold` take reached its last frame (or was skipped to it) and waits for release()

const CLIP := "take"
const ALONE := "Alone"  # a take key + this: the version for an Operative carrying nothing
const LANDING_MAX := 2.0  # s to wait for the host to switch back before handing over anyway
const WARM_VIEWS := 8     # samples along a rail take for the loading screen to warm (views)

var lines: Array[String] = []   # the lower-third's translated lines (a Mission's intro card text)
var fade_out := false           # an outro: ends on black
var hold := false               # waits on its last frame until release(), then goes to black (the Ascent plays under the Epilogue)
var skipped := false
var done := false

var _key := ""
var _player: AnimationPlayer
var _then := Callable()
var _op: Node
var _run: MissionRun
var _hud: Node
var _hud_shown := true
var _host: PhantomCameraHost
var _gameplay: PhantomCamera3D
var _pcams: Array[PhantomCamera3D] = []
var _overlay: CineOverlay
var _layer: CanvasLayer
var _held := 0.0
var _armed := false             # the advance key has been up since the take began
var _ending := false
var _holding := false
var _landing := 0.0
var _at := 0.0                  # s into the take when it ended
var _swallow := false           # control is back but the skip key is still down: the Operative stays locked until it is released
var _worst := 0.0               # timing: the slowest frame of the take (s), and how many ran past HITCH
var _hitches := 0
var _frames := 0

const HITCH := 0.05  # s: a frame this slow is a visible stall


## The take's AnimationPlayer in `area`, or null.
static func take_of(area: Node, key: String) -> AnimationPlayer:
	return area.get_node_or_null("Cine/" + key) as AnimationPlayer


## Where `player`'s take looks from, for the loading screen to show its Area through before it lifts: each view's
## shaders and shadow maps are then built behind the cover, not mid-take. A rail gives WARM_VIEWS samples of its
## Dolly and LookTarget tracks; a fixed pcam (a relay's, a cut's) gives its own. Each is {xf: Transform3D, fov: 0 = the lens as is}.
static func views(player: AnimationPlayer) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if player == null or not player.has_animation(CLIP):
		return out
	var clip := player.get_animation(CLIP)
	for p in player.get_meta("pcams", []):
		var pcam := player.get_node_or_null(p) as PhantomCamera3D
		if pcam == null or pcam.look_at_target == null:
			continue
		var fov: float = pcam.camera_3d_resource.fov if pcam.camera_3d_resource else 0.0
		var rig := pcam.get_parent() as Node3D
		var dolly := clip.find_track(NodePath("%s/Dolly:position" % rig.name), Animation.TYPE_VALUE)
		var look := clip.find_track(NodePath("%s/LookTarget:position" % rig.name), Animation.TYPE_VALUE)
		if pcam.follow_mode == PhantomCamera3D.FollowMode.PATH and dolly >= 0 and look >= 0:
			for i in WARM_VIEWS:
				var t := clip.length * i / (WARM_VIEWS - 1)
				out.append(_view(rig.global_transform * clip.value_track_interpolate(dolly, t), rig.global_transform * clip.value_track_interpolate(look, t), fov))
		else:
			out.append(_view(pcam.global_position, pcam.look_at_target.global_position, fov))
	return out


static func _view(from: Vector3, to: Vector3, fov: float) -> Dictionary:
	var up := Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.BACK
	return {xf = Transform3D(Basis(), from).looking_at(to, up), fov = fov}


## The take to play for `key`: its "Alone" sibling when the Area has one and the Operative carries nothing (an outro that shows
## him leaving with the objective or without it), else `key` itself.
static func variant_key(area: Node, key: String) -> String:
	var op = area.get_node_or_null("Operative")
	var alone := key + ALONE
	return alone if op != null and op.carrying == null and take_of(area, alone) != null else key


## A take over `run`'s Area (a child of `run`: the Area is still setting up its own when an intro starts).
static func launch(run: MissionRun, key: String, lines: Array, outro: bool, then: Callable) -> void:
	var c := Cine.new()
	c.name = "CineRunner"
	run.add_child(c)
	c.fade_out = outro
	c.lines.assign(lines)
	c.play(run.get_parent(), variant_key(run.get_parent(), key) if outro else key, then)


## Plays `key` in `area`, then calls `then`. False (and `then` is called at once) when the Area has no such take.
func play(area: Node, key: String, then: Callable) -> bool:
	_key = key
	_then = then
	_player = take_of(area, key)
	if _player == null or not _player.has_animation(CLIP):
		push_warning("%s has no take '%s'" % [area.name, key])
		done = true
		then.call()
		finished.emit(false)
		return false
	if not is_inside_tree():
		area.add_child(self)
	_op = area.get_node_or_null("Operative")
	_run = area.get_node_or_null("MissionRun") as MissionRun
	_hud = area.get_node_or_null("HudLayer")
	for p in _player.get_meta("pcams", []):
		var pcam := _player.get_node_or_null(p) as PhantomCamera3D
		if pcam:
			_pcams.append(pcam)
	if _op:
		_op.cine = true
		_op.moving = false
		_gameplay = _op.gameplay_cam
		_host = OperativeCam.host_of(_op.camera)
	if _run:
		_run.take_playing = true
	Mixer.take(true)
	if _hud:
		_hud_shown = _hud.visible
		_hud.visible = false
	_layer = CanvasLayer.new()
	_layer.layer = 3  # over the HUD (1) and a card or screen (2); the PSX look is under both
	_overlay = CineOverlay.new()
	_overlay.lines = lines
	_layer.add_child(_overlay)
	add_child(_layer)
	_player.animation_finished.connect(_on_finished)
	_player.play(CLIP)
	_player.advance(0.0)  # the first frame (the pcams' priority) lands now, not next frame
	return true


func _process(delta: float) -> void:
	if _swallow:  # the key that skipped must not also fire a Takedown or interact in the first frame of play
		if not _advance_down():
			_unlock()
		return
	if done or _holding:
		return
	if not _ending:
		_frames += 1
		_worst = maxf(_worst, delta)
		_hitches += int(delta >= HITCH)
	if _ending:
		_landing += delta
		if _landing >= LANDING_MAX:
			_land()
		return
	var len := _player.get_animation(CLIP).length
	var t := _player.current_animation_position
	_overlay.third = CineLogic.lower_third(t, len, float(_player.get_meta("third_at", CineLogic.LOWER_THIRD_AT)))
	if fade_out:
		_overlay.black = CineLogic.black(t, len)
	var down := _advance_down()
	_armed = _armed or not down
	_held = _held + delta if down and _armed else 0.0
	_overlay.skip = CineLogic.skip_progress(_held) if CineLogic.ring_shown(_held) else 0.0
	_overlay.queue_redraw()
	if CineLogic.skip_done(_held):
		skip()


static func _advance_down() -> bool:
	return Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


## Jump to the take's last frame and end it now (contract: seek to the end, tween skipped).
func skip() -> void:
	if _ending or done:
		return
	skipped = true
	_player.seek(_player.get_animation(CLIP).length, true)
	_arrive()


func _on_finished(_clip: StringName) -> void:
	_arrive()


## The clip is at its last frame: end it, or (a `hold` take) stay on that frame until release().
func _arrive() -> void:
	if hold and not _holding and not _ending:
		_holding = true
		_overlay.third = 0.0
		_overlay.skip = 0.0
		_overlay.queue_redraw()
		held.emit(skipped)
		return
	_end()


## Ends a `hold` take on black; `then` runs as for an outro.
func release() -> void:
	if not _holding:
		return
	_holding = false
	fade_out = true
	_end()


func _end() -> void:
	if _ending:
		return
	_ending = true
	_at = _player.current_animation_position
	SessionLog.current.note(CineLogic.log_line(_key, skipped, _at))
	print("[timing] take %s: %.1f s, %d frames, worst %.0f ms, %d over %.0f ms%s" % [_key, _at, _frames, _worst * 1000.0, _hitches, HITCH * 1000.0, " (skipped)" if skipped else ""])
	_player.animation_finished.disconnect(_on_finished)
	_player.stop(true)
	if _op and not fade_out:
		_op.snap_view()  # a take may have moved the body far; the gameplay camera must not fly after it
	if fade_out:
		_overlay.black = 1.0
		_overlay.third = 0.0
		_overlay.skip = 0.0
		_overlay.queue_redraw()
		_finish()
		return
	if _gameplay and skipped:
		_gameplay.set_tween_skip(_host, true)  # only the host may; no half-tween on a skip
	for pcam in _pcams:
		pcam.priority = 0  # below GameplayCam
	var active: Node = _host.get_active_pcam() if _host else null
	if active == null or active == _gameplay:  # no host yet (or nothing to wait for)
		_land()
	else:
		_host.pcam_became_active.connect(func(p: Node) -> void:
			if p == _gameplay:
				_land(), CONNECT_ONE_SHOT)


## The host is on GameplayCam: control comes back.
func _land() -> void:
	if done:
		return
	if _op:
		_op.moving = false
		_swallow = skipped and _advance_down()
		_op.cine = _swallow
	if _hud:
		_hud.visible = _hud_shown
	_layer.queue_free()
	_finish()


func _unlock() -> void:
	_swallow = false
	if is_instance_valid(_op):
		_op.cine = false
	queue_free()


func _finish() -> void:
	done = true
	Mixer.take(false)
	if _run:
		_run.take_playing = false
	if fade_out:  # the black stays until the next screen has taken over, then clears under it
		HudPalette.fade(_overlay, false)
		get_tree().create_timer(HudPalette.FADE, true, false, true).timeout.connect(func() -> void:
			_layer.queue_free()
			queue_free())
	_then.call()
	finished.emit(skipped)
	if not fade_out and not _swallow:
		queue_free()


func _exit_tree() -> void:
	if not done:
		Mixer.take(false)  # freed mid-take (a scene change): no stuck duck
