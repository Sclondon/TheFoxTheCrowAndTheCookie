class_name Backdrop
extends CanvasLayer
# Everything behind the wood: a banded sky that changes with the song's
# time of day (data/timeline.json "sky"), stars, sun and moon, drifting
# clouds, and three parallax layers (far hills, near hills, a treeline)
# tinted to match. Also hands main.gd the light colour for the wood itself.

const PHASES := {
	"dawn":      {"top": "#3a2f5a", "bot": "#e8a07a", "light": "#e0c4c0", "sun": 0.08, "moon": -1.0, "stars": 0.35},
	"morning":   {"top": "#5b8fd0", "bot": "#cfe6f0", "light": "#ffffff", "sun": 0.5,  "moon": -1.0, "stars": 0.0},
	"day":       {"top": "#4f86d0", "bot": "#bfe0f4", "light": "#ffffff", "sun": 0.85, "moon": -1.0, "stars": 0.0},
	"afternoon": {"top": "#6a8ccc", "bot": "#f0dcb0", "light": "#fff2e0", "sun": 0.6,  "moon": -1.0, "stars": 0.0},
	"golden":    {"top": "#6a5a9a", "bot": "#f0a060", "light": "#ffd8b0", "sun": 0.22, "moon": -1.0, "stars": 0.0},
	"dusk":      {"top": "#2a2050", "bot": "#c06070", "light": "#bca6c4", "sun": -0.2, "moon": 0.25, "stars": 0.5},
	"night":     {"top": "#0a0c22", "bot": "#232048", "light": "#6c78aa", "sun": -0.6, "moon": 0.7,  "stars": 1.0},
}

var keys: Array = []          # [{t, phase}]
var cur := {}                 # interpolated values
var cam := Vector2.ZERO
var zoom := 1.0
var screen := Vector2(844, 390)
var _canvas: Node2D
var _layers: Array = []       # [{node, f}]
var _sun: Sprite2D
var _moon: Sprite2D
var _clouds: Node2D
var _trees: Node2D
var _haze: ShaderMaterial
var _stars: Array = []
var _t := 0.0

func _ready() -> void:
	layer = -10
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_sky)
	add_child(_canvas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.75, rng.randf() * TAU))
	_sun = Art.sprite("sun")
	add_child(_sun)
	_moon = Art.sprite("moon")
	add_child(_moon)
	_clouds = Node2D.new()
	add_child(_clouds)
	for i in 7:
		var c := Art.sprite("cloud", 2, i % 2)
		c.position = Vector2(-300 + i * 190 + rng.randf_range(-40, 40), -150 + rng.randf_range(-30, 30))
		_clouds.add_child(c)
	_layers.append({"node": _clouds, "f": 0.12})
	_layers.append({"node": _band("hills_far", 0.18, 2), "f": 0.18})
	_layers.append({"node": _band("hills_near", 0.32, 1), "f": 0.32})
	_layers.append({"node": _band("treeline", 0.55, 0), "f": 0.55})
	_trees = _tree_layer()
	_layers.append({"node": _trees, "f": 0.8})
	set_time(0.0)

func _band(strip: String, _f: float, _depth: int) -> Node2D:
	var n := Node2D.new()
	var s := Sprite2D.new()
	s.texture = Art.tex(strip)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, 4096, s.texture.get_height())
	s.centered = false
	s.position = Vector2(-1500, -s.texture.get_height() + 2)
	n.add_child(s)
	add_child(n)
	return n

func setup(sky_keys: Array) -> void:
	keys = sky_keys
	set_time(0.0)

static func _col(h: String) -> Color:
	return Color.html(h)

func set_time(t: float) -> void:
	_t = t
	var a := {}
	var b := {}
	var k := 0.0
	if keys.is_empty():
		a = PHASES["day"]
		b = a
	else:
		var i := 0
		while i + 1 < keys.size() and float(keys[i + 1]["t"]) <= t:
			i += 1
		a = PHASES[keys[i]["phase"]]
		if i + 1 < keys.size():
			b = PHASES[keys[i + 1]["phase"]]
			var t0: float = keys[i]["t"]
			var t1: float = keys[i + 1]["t"]
			k = clampf((t - t0) / maxf(0.01, t1 - t0), 0.0, 1.0)
			k = smoothstep(0.0, 1.0, k)
		else:
			b = a
	cur = {
		"top": _col(a["top"]).lerp(_col(b["top"]), k),
		"bot": _col(a["bot"]).lerp(_col(b["bot"]), k),
		"light": _col(a["light"]).lerp(_col(b["light"]), k),
		"sun": lerpf(a["sun"], b["sun"], k),
		"moon": lerpf(a["moon"], b["moon"], k),
		"stars": lerpf(a["stars"], b["stars"], k),
	}

func night_amount() -> float:
	return clampf(cur.get("stars", 0.0), 0.0, 1.0)

func light() -> Color:
	return cur.get("light", Color.WHITE)

func _process(_delta: float) -> void:
	var top: Color = cur["top"]
	var bot: Color = cur["bot"]
	var far := bot.lerp(top, 0.35).darkened(0.12)
	var near := bot.lerp(top, 0.5).darkened(0.32)
	var trees := near.lerp(Color("#16261f"), 0.45).darkened(0.2)
	_layers[1]["node"].modulate = far
	_layers[2]["node"].modulate = near
	_layers[3]["node"].modulate = trees
	_haze.set_shader_parameter("haze", near.lerp(bot, 0.25))
	_haze.set_shader_parameter("amount", 0.5)
	_clouds.modulate = Color(1, 1, 1, 0.85).lerp(bot.lightened(0.2), 0.45) * Color(1, 1, 1, 1.0 - night_amount() * 0.6)
	for L in _layers:
		var n: Node2D = L["node"]
		n.scale = Vector2(zoom, zoom)
		n.position = Vector2(screen.x * 0.5 - cam.x * L["f"] * zoom, screen.y * 0.5 - cam.y * zoom).round()
	_clouds.position.x += 0.0
	for c in _clouds.get_children():
		c.position.x += _delta_drift()
		if c.position.x > 1200:
			c.position.x -= 1500
	# sun and moon ride an arc across the screen
	var horizon := screen.y * 0.5 - cam.y * zoom
	var top_y := 0.12 * screen.y
	_sun.scale = Vector2(zoom, zoom)
	_moon.scale = Vector2(zoom, zoom)
	var sh: float = cur["sun"]
	_sun.position = Vector2(screen.x * (0.82 - sh * 0.25), lerpf(horizon, top_y, sh)).round()
	_sun.visible = sh > -0.15
	var mh: float = cur["moon"]
	_moon.position = Vector2(screen.x * (0.86 - mh * 0.12), lerpf(horizon, top_y * 0.7, mh)).round()
	_moon.visible = mh > -0.15
	_canvas.queue_redraw()

func _delta_drift() -> float:
	return get_process_delta_time() * 1.5

func _draw_sky() -> void:
	var top: Color = cur["top"]
	var bot: Color = cur["bot"]
	var horizon := screen.y * 0.5 - cam.y * zoom
	var bands := 10
	var hgt := maxf(horizon, 1.0)
	for i in bands:
		var y0 := hgt * i / bands
		var y1 := hgt * (i + 1) / bands
		_canvas.draw_rect(Rect2(0, floorf(y0), screen.x, ceilf(y1 - y0) + 1), top.lerp(bot, pow(float(i) / (bands - 1), 1.4)))
	_canvas.draw_rect(Rect2(0, floorf(hgt), screen.x, screen.y - hgt + 1), bot)
	var st := night_amount()
	if st > 0.01:
		var px := maxf(1.0, roundf(zoom))
		for s in _stars:
			var tw := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.002 + s.z)
			var p := Vector2(s.x * screen.x, s.y * hgt).round()
			_canvas.draw_rect(Rect2(p, Vector2(px, px)), Color(0.85, 0.85, 1.0, st * tw))

# The Hemlock's Tower trees, hazed into the distance behind the wood. x is
# where each stands when the camera is right in front of it (the layer
# moves at 0.8 of the camera's pace).
func _tree_layer() -> Node2D:
	var n := Node2D.new()
	_haze = ShaderMaterial.new()
	_haze.shader = load("res://shaders/haze.gdshader")
	for spec in [["hemlock/tree", -40], ["hemlock/tree_6", 150], ["hemlock/tree_3", 560], ["hemlock/tree_2", 700], ["hemlock/tree_5", 1000], ["hemlock/tree", 300]]:
		var s := Art.sprite(spec[0])
		s.centered = false
		s.material = _haze
		s.position = Vector2(float(spec[1]) * 0.8 - 64.0, -124.0)
		n.add_child(s)
	add_child(n)
	return n
