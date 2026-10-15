extends Node2D
# The Fox, The Crow, and The Cookie: an interactive music video.
#
# main.gd builds the scene, reads data/timeline.json, runs the camera and all
# input, and drives the show from a SongSource:
#   TITLE   title card; the chosen music player loads in the corner
#   WAITING "Tap to play" pressed; waiting for the music to start
#   SHOW    the story plays on the source's clock
#   END     the ending card and "Watch again"
#
# Command line (after --): --silent forces the plain clock; --autostart skips
# the title card; --speed=N runs the show N times faster; --at=SECONDS starts
# partway in. On the web, ?source=spotify|youtube picks the music source.

enum State { TITLE, WAITING, SHOW, END }

const TIMELINE := "res://data/timeline.json"

var state := State.TITLE
var cfg := {}
var length := 211.0
var source: SongSource
var source_id := "spotify"
var sky: Backdrop
var world: World
var crow: Crow
var fox: Fox
var director: Director
var hud: Hud
var cam: Camera2D
var glow: CanvasLayer
var fx: Fx
var light: CanvasModulate

var zoom := 2.0
var screen := Vector2(844, 390)
var cam_x := 420.0
var show_t := 0.0
var _last_t := 0.0
var _wait_t := 0.0
var _idle := 99.0           # seconds since the player last panned
var _touches := {}          # index -> {start, t, moved}
var _primary := -2
var _args := {}
var taps_handled := 0       # for tests
var last_tap_name := ""     # for tests

func _ready() -> void:
	_parse_args()
	cfg = _load_json(TIMELINE)
	length = float(cfg.get("length", 211.0))
	if _args.has("speed"):
		Engine.time_scale = float(_args["speed"])

	add_child(Sfx.new())
	sky = Backdrop.new()
	add_child(sky)
	sky.setup(cfg.get("sky", []))

	light = CanvasModulate.new()
	add_child(light)
	world = World.new()
	glow = CanvasLayer.new()
	glow.layer = 1
	glow.follow_viewport_enabled = true
	add_child(glow)
	var glow_root := Node2D.new()
	glow.add_child(glow_root)
	world.glow_layer = glow_root
	fx = Fx.new()
	glow.add_child(fx)
	add_child(world)
	world.build()

	crow = Crow.new()
	world.add_child(crow)
	fox = Fox.new()
	world.add_child(fox)
	world.add_tap(crow, Rect2(-9, -16, 18, 18), crow.tap, 5, "crow")
	world.add_tap(fox, Rect2(-15, -22, 30, 23), fox.tap, 4, "fox")

	director = Director.new()
	add_child(director)
	director.setup(world, crow, fox, cfg.get("beats", []))
	director.beat_started.connect(func(b: Dictionary) -> void: hud.set_caption(str(b.get("caption", ""))))

	cam = Camera2D.new()
	world.add_child(cam)
	cam.make_current()

	hud = Hud.new()
	add_child(hud)

	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	cam_x = World.PERCH.x
	_place_camera(0.0)

	_pick_source(_initial_source())
	if _args.has("shots"):
		add_child(load("res://tools/shots.gd").new())
	if _args.has("autostart"):
		_start()
		if _args.has("at"):
			_skip_to(float(_args["at"]))

func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var kv := s.split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	# the tests hand their options over as metadata
	if has_meta("args"):
		var m: Dictionary = get_meta("args")
		for k in m:
			_args[k] = str(m[k])

static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("can't read " + path)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

# ---- song source -------------------------------------------------------

func _is_web() -> bool:
	return OS.has_feature("web") and not _args.has("silent")

func _initial_source() -> String:
	var srcs: Dictionary = cfg.get("sources", {})
	var id := str(srcs.get("default", "spotify"))
	if _is_web():
		var q = JavaScriptBridge.eval("(new URLSearchParams(window.location.search)).get('source') || ''", true)
		if q != null and str(q) in ["spotify", "youtube"]:
			id = str(q)
	return id

func _pick_source(id: String) -> void:
	if source:
		source.shutdown()
		source = null
	source_id = id
	var srcs: Dictionary = cfg.get("sources", {})
	if _is_web() and (id == "spotify" or id == "youtube"):
		var c: Dictionary = (srcs.get(id, {}) as Dictionary).duplicate()
		c["song_length"] = length
		source = SpotifySource.new() if id == "spotify" else YouTubeSource.new()
		add_child(source)
		source.setup(c)
		hud.set_title_note("")
	else:
		source = SilentSource.new(0.0, "")
		add_child(source)
		hud.set_title_note("" if _args.has("silent") else "Playing silently here: the song plays in the web version.")
	hud.set_web(_is_web(), id)

# Carry on from `at` on the plain clock, with a note saying why.
func _fall_back(why: String, at: float) -> void:
	if source:
		# keep a music player on screen (it may still be useful), drop its clock
		source.set_process(false)
	var s := SilentSource.new(at, why)
	add_child(s)
	s.begin()
	source = s
	hud.set_note(why)

func _start() -> void:
	Sfx.start_ambience()
	hud.show_title(false)
	director.reset()
	_last_t = 0.0
	show_t = 0.0
	source.begin()
	Sfx.set_music(source.is_music())
	_wait_t = 0.0
	state = State.WAITING
	if source is SilentSource:
		state = State.SHOW
		hud.flash_hint()

func _restart() -> void:
	hud.show_end(false)
	director.reset()
	_last_t = 0.0
	show_t = 0.0
	if source is SilentSource:
		source.restart()
		state = State.SHOW
	else:
		source.restart()
		_wait_t = 0.0
		state = State.WAITING
	_idle = 99.0

func _skip_to(t: float) -> void:
	if source is SilentSource:
		(source as SilentSource).t = t
	director.update(t)
	Director.finish_all()

# ---- per frame ------------------------------------------------------------

func _process(delta: float) -> void:
	_idle += delta / maxf(Engine.time_scale, 0.001)
	_keys(delta / maxf(Engine.time_scale, 0.001))
	match state:
		State.TITLE:
			if source.is_music() and source.state() == "failed" and not hud.title_note.visible:
				var other := "YouTube" if source_id == "spotify" else "Spotify"
				hud.set_title_note("%s can't play the song here. Try %s, or tap play to watch without it." % [source_id.capitalize().replace("Youtube", "YouTube"), other])
		State.WAITING:
			_wait_t += delta / maxf(Engine.time_scale, 0.001)
			var st := source.state()
			if st == "playing":
				state = State.SHOW
				hud.show_wait(false)
				hud.flash_hint()
			elif st == "failed":
				_fall_back(_fail_note(), 0.0)
				state = State.SHOW
				hud.show_wait(false)
			elif _wait_t > 4.0:
				hud.show_wait(true)
		State.SHOW:
			var st := source.state()
			if st == "failed":
				_fall_back(_fail_note(), maxf(show_t, 0.0))
			elif st == "preview_over":
				_fall_back(source.note, maxf(show_t, 0.0))
			hud.set_paused(st == "paused")
			var t := source.show_time()
			if t < _last_t - 2.0:
				# the listener seeked back: rebuild the story up to here
				director.reset()
				director.update(t)
			_last_t = t
			show_t = t
			director.update(t)
			if t >= length:
				state = State.END
				hud.show_end(true)
		State.END:
			pass
	var tt := clampf(show_t, 0.0, length)
	sky.set_time(tt)
	light.color = sky.light()
	# stage light: lift the two players back out of the dusk and dark, so
	# they read against the trees while the wood around them dims
	var l := light.color
	var lift := Color(1.0 / maxf(l.r, 0.2), 1.0 / maxf(l.g, 0.2), 1.0 / maxf(l.b, 0.2))
	var k := 1.0 + 0.3 * world.night
	var boost := Color.WHITE.lerp(lift, 0.7) * Color(k, k, k * 1.05)
	crow.spr.self_modulate = boost
	fox.spr.self_modulate = boost
	world.night = sky.night_amount()
	Sfx.set_night(world.night)
	_follow(delta / maxf(Engine.time_scale, 0.001))
	_place_camera(delta)

func _fail_note() -> String:
	var why := "The song couldn't load here, so this is playing silently."
	if source is WebEmbedSource:
		var e := (source as WebEmbedSource).page_error()
		if e != "":
			why += " (" + e + ")"
	return why

func _keys(dt: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	if dir != 0.0:
		cam_x += dir * 160.0 * dt
		_idle = 0.0

# Drift toward the action when the player hasn't panned for a while; point
# an arrow at it when it's off screen.
func _follow(dt: float) -> void:
	var focus := director.focus_point()
	var vis := screen / zoom
	if state == State.SHOW and _idle > 3.5:
		cam_x = lerpf(cam_x, focus.x, 1.0 - exp(-dt * 1.4))
	var off := focus.x - cam_x
	var side := 0
	if state == State.SHOW and absf(off) > vis.x * 0.5 - 6.0:
		side = 1 if off > 0 else -1
	hud.set_arrow(side)

func _place_camera(_d: float) -> void:
	var vis := screen / zoom
	var lo := vis.x * 0.5 - 30.0
	var hi := World.WIDTH - vis.x * 0.5 + 30.0
	cam_x = (lo + hi) * 0.5 if lo > hi else clampf(cam_x, lo, hi)
	# put the action's middle (y = -40) a little below the screen's middle,
	# but never show more than 30% of the screen as earth
	var cy := clampf(-40.0 - vis.y * 0.1, -0.38 * vis.y, -0.2 * vis.y)
	# On a phone held upright the screen is mostly height: keep the earth to about
	# 15% so the wood fills it, instead of a band of empty ground along the bottom.
	if screen.y > screen.x:
		cy = -0.35 * vis.y
	cam.zoom = Vector2(zoom, zoom)
	cam.position = Vector2(roundf(cam_x * zoom) / zoom, roundf(cy * zoom) / zoom)
	sky.cam = cam.position
	sky.zoom = zoom
	sky.screen = screen

func _on_resize() -> void:
	screen = get_viewport().get_visible_rect().size
	zoom = maxf(1.0, roundf(screen.y / 260.0))
	hud.layout(screen)

# ---- input ------------------------------------------------------------------
# Touches are read here, not from the emulated mouse. A drag from a finger
# whose press never arrived (some iPhones drop it) counts as a press, and a
# release with no press counts as a tap, so a tap alone always works.

func _slop() -> float:
	return maxf(8.0, minf(screen.x, screen.y) * 0.025)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index, event.position)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press(-1, event.position)
			else:
				_release(-1, event.position)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			cam_x -= 24.0
			_idle = 0.0
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			cam_x += 24.0
			_idle = 0.0
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(-1, event.position, event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			if state == State.TITLE:
				_start()
			elif state == State.END:
				_restart()

func _press(idx: int, pos: Vector2) -> void:
	Sfx.start_ambience()
	_touches[idx] = {"start": pos, "t": Time.get_ticks_msec(), "moved": false}
	if _primary == -2:
		_primary = idx

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	if not _touches.has(idx):
		# the press never arrived: treat this as the press
		_press(idx, pos - rel)
	var rec: Dictionary = _touches[idx]
	if not rec["moved"] and pos.distance_to(rec["start"]) > _slop():
		rec["moved"] = true
	if rec["moved"] and idx == _primary and state != State.TITLE and state != State.END:
		cam_x -= rel.x / zoom
		_idle = 0.0

func _release(idx: int, pos: Vector2) -> void:
	if not _touches.has(idx):
		_tap(pos)
		return
	var rec: Dictionary = _touches[idx]
	_touches.erase(idx)
	if idx == _primary:
		_primary = -2 if _touches.is_empty() else _touches.keys()[0]
	if not rec["moved"] and Time.get_ticks_msec() - int(rec["t"]) < 900:
		_tap(pos)

func _tap(pos: Vector2) -> void:
	var a := hud.tap(pos)
	match a:
		"play":
			_start()
			return
		"src_spotify":
			_pick_source("spotify")
			return
		"src_youtube":
			_pick_source("youtube")
			return
		"silent":
			hud.show_wait(false)
			_fall_back("Playing without the song.", 0.0)
			director.reset()
			_last_t = 0.0
			state = State.SHOW
			hud.flash_hint()
			return
		"again":
			_restart()
			return
		"arrow":
			cam_x = director.focus_point().x
			_idle = 99.0
			return
		"block":
			return
	if state != State.SHOW and state != State.WAITING:
		return
	var p := screen_to_world(pos)
	var pad := maxf(3.0, minf(screen.x, screen.y) * 0.035 / zoom)
	var hit := world.find_tap(p, pad)
	taps_handled += 1
	if hit.is_empty():
		last_tap_name = ""
		world.tap_empty(p)
		return
	last_tap_name = str(hit.get("name", ""))
	if last_tap_name == "pond":
		world.tap_pond(p)
	else:
		(hit["cb"] as Callable).call()

func screen_to_world(pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * pos
