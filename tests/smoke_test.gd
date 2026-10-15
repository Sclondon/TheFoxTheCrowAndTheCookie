extends SceneTree
# Headless smoke test: plays the whole show at speed on the silent clock and
# checks the story, the timeline file, every tap target, a seek back, the
# ending card and "Watch again". Ends with PASSED or FAILED (exit code 0/1).
#
#   godot --headless --path . --script tests/smoke_test.gd

class ErrorCounter extends Logger:
	var errors: Array[String] = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		errors.append("%s:%d %s %s %s" % [file, line, function, code, rationale])
	func _log_message(_message: String, _error: bool) -> void:
		pass

const SPEED := 25.0

var main: Node
var errlog := ErrorCounter.new()
var fails: Array[String] = []
var fired: Array[String] = []
var frames := 0
var phase := "run"
var t0 := 0

func _init() -> void:
	OS.add_logger(errlog)
	_check_timeline()
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	main.set_meta("args", {"silent": 1, "autostart": 1, "speed": SPEED})
	root.add_child(main)
	t0 = Time.get_ticks_msec()

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("  FAIL: ", what)

func _check_timeline() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/timeline.json"))
	_check(cfg is Dictionary, "timeline.json parses")
	var beats: Array = cfg.get("beats", [])
	var last := -1.0
	var Dir: Script = load("res://scripts/director.gd")
	var d: Object = Dir.new()
	for b in beats:
		_check(float(b["t"]) >= last, "beats in time order at " + str(b["id"]))
		last = float(b["t"])
		_check(d.has_method("_beat_" + str(b["id"])), "a handler for beat " + str(b["id"]))
		var f = b.get("focus", "crow")
		_check(f is float or str(f) in ["crow", "fox", "cookie", "cottage", "tree", "den"], "focus of " + str(b["id"]))
		_check(not str(b.get("caption", "")).contains("\n"), "one-line caption " + str(b["id"]))
	d.free()
	_check(float(cfg.get("length", 0)) > last, "length is after the last beat")
	_check(absf(float(cfg.get("length", 0)) - 211.0) < 1.0, "length matches the song (3:31)")
	var Back: Script = load("res://scripts/backdrop.gd")
	for k in cfg.get("sky", []):
		_check(Back.PHASES.has(k["phase"]), "sky phase " + str(k["phase"]))
	var src: Dictionary = cfg.get("sources", {})
	_check(src.has("spotify") and str(src["spotify"].get("track_id", "")) != "", "a Spotify track id")
	_check(src.has("youtube") and str(src["youtube"].get("video_id", "")) != "", "a YouTube video id")

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		main.director.beat_started.connect(func(b: Dictionary) -> void: fired.append(str(b["id"])))
		fired.append(str(main.director.current.get("id", "")))
	if Time.get_ticks_msec() - t0 > 90000:
		_check(false, "finished within 90 s (phase %s, t=%.1f)" % [phase, main.show_t])
		return _finish()
	match phase:
		"run":
			# poke every tap target once along the way
			if frames == 30:
				_tap_everything()
			if frames == 40:
				_check(main.state == main.State.SHOW, "show is running on the silent clock")
				_check(main.source is SilentSource, "tests use the silent clock")
			# a seek back from 120 s to 55 s: the story should rebuild itself
			if phase == "run" and main.show_t > 120.0 and not main.has_meta("seeked"):
				main.set_meta("seeked", true)
				(main.source as SilentSource).t = 55.0
			if main.has_meta("seeked") and not main.has_meta("checked_seek") and main.show_t > 56.0 and main.show_t < 59.0:
				main.set_meta("checked_seek", true)
				_check(main.crow.holding, "after the seek back the crow has her cookie again")
				_check(not main.fox.visible, "after the seek back the fox is still in his den")
			if main.state == main.State.END:
				phase = "ended"
		"ended":
			_check(main.hud.end_box.visible, "ending card shows")
			_check(main.crow.base_anim == "sleep", "the crow ends asleep (was %s)" % main.crow.base_anim)
			_check(main.crow.position.distance_to(World.PERCH) < 1.0, "the crow ends on her perch")
			_check(not main.fox.visible, "the fox ends in his den")
			_check(not main.crow.holding and not main.fox.holding, "the cookie is gone")
			_check(main.world.crumbs.get_child_count() == 0 or _all_queued(main.world.crumbs), "the crumbs are eaten")
			var ids: Array = []
			for b in main.director.beats:
				ids.append(str(b["id"]))
			for id in ids:
				_check(fired.has(id), "beat %s ran" % id)
			_check(main.director.next_i == ids.size(), "the director reached the last beat")
			_check(main.has_meta("checked_seek"), "the seek-back check ran")
			# Watch again
			main._tap(main.hud.again_btn.get_global_rect().get_center())
			phase = "again"
			frames = 0
		"again":
			if frames == 10:
				_check(main.state == main.State.SHOW, "Watch again restarts the show")
				_check(main.show_t < 20.0, "the restart begins at the start (t=%.1f)" % main.show_t)
				_check(not main.hud.end_box.visible, "ending card hides on restart")
				main._fall_back("test", 30.0)
				_check(main.source is SilentSource and absf(main.source.time() - 30.0) < 0.5, "fallback carries on from where it was")
				return _finish()
	return false

func _all_queued(n: Node) -> bool:
	for c in n.get_children():
		if not c.is_queued_for_deletion():
			return false
	return true

func _tap_everything() -> void:
	var names := {}
	for t in main.world.taps:
		var n: Node2D = t["node"]
		if not is_instance_valid(n):
			continue
		names[t["name"]] = true
		if t["name"] == "pond":
			main.world.tap_pond(n.global_position + Vector2(40, 4))
		else:
			(t["cb"] as Callable).call()
	main.world.tap_empty(Vector2(300, -120))
	main.world.tap_empty(Vector2(300, -10))
	for want in ["crow", "fox", "bell", "bush", "mushroom", "leaves", "trunk", "canopy", "lantern", "chimney", "door", "frog", "pond", "reeds", "owl", "den", "rock", "cookie"]:
		_check(names.has(want), "there is a tap target: " + want)

func _finish() -> bool:
	Engine.time_scale = 1.0
	for e in errlog.errors:
		_check(false, "engine/script error: " + e)
	print("beats run: ", fired.size(), "  frames: ", frames)
	if fails.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED (%d)" % fails.size())
		quit(1)
	return true
