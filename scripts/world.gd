class_name World
extends Node2D
# The wood, left to right: the baker's cottage (bell, lantern, a tray of
# cookies cooling on the sill), bushes and mushrooms, the crow's old tree,
# the fox's den under a log, a pond with a frog, and an owl's tree.
#
# Ground level is y = 0; up is negative. Everything you can tap is registered
# with add_tap(); main.gd hit-tests taps against that list.

const WIDTH := 940.0
const COTTAGE := Vector2(30, -80)
const SILL_LAND := Vector2(71, -18)
const TREE := Vector2(320, -120)
const PERCH := Vector2(424, -54)
const FOX_SIT_X := 470.0
const DEN := Vector2(560, -22)
const DEN_HOLE := Vector2(596, 0)
const POND := Vector2(660, -2)

var taps: Array = []           # {node, rect, cb, prio}
var tray_cookies: Array[Sprite2D] = []
var window_glow: Sprite2D
var lantern: Sprite2D
var lantern_glow: Sprite2D
var lantern_on := false
var owl_eyes: Sprite2D
var crumbs: Node2D
var glow_layer: Node2D          # set by main before build()
var frog: Sprite2D
var _reeds: Array[Sprite2D] = []
var _fireflies: Array = []
var night := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()

func add_tap(node: Node2D, rect: Rect2, cb: Callable, prio: int = 0, name: String = "") -> void:
	taps.append({"node": node, "rect": rect, "cb": cb, "prio": prio, "name": name})

# Best tap target at world point p (pad widens every target, in world px).
func find_tap(p: Vector2, pad: float) -> Dictionary:
	var best := {}
	var best_score := INF
	for t in taps:
		var n: Node2D = t["node"]
		if not is_instance_valid(n) or not n.is_visible_in_tree():
			continue
		var r: Rect2 = t["rect"]
		r.position += n.global_position
		var rr := r.grow(pad)
		if not rr.has_point(p):
			continue
		var inside := r.has_point(p)
		var score: float = -float(t["prio"]) * 100000.0 + r.get_area() + (0.0 if inside else 50000.0)
		if score < best_score:
			best_score = score
			best = t
	return best

func build() -> void:
	_rng.seed = 77
	_ground()
	_cottage()
	_garden()
	_crow_tree()
	_den()
	_pond()
	_owl_tree()
	crumbs = Node2D.new()
	add_child(crumbs)
	_fireflies_make()

# ---- pieces -----------------------------------------------------------

func _ground() -> void:
	var deep := ColorRect.new()
	deep.color = Color("#3a2230")
	deep.position = Vector2(-400, 40)
	deep.size = Vector2(WIDTH + 800, 600)
	add_child(deep)
	var g := Sprite2D.new()
	g.texture = Art.tex("ground")
	g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	g.region_enabled = true
	g.region_rect = Rect2(0, 0, WIDTH + 800, 48)
	g.centered = false
	g.position = Vector2(-400, -4)
	add_child(g)

func _cottage() -> void:
	var c := Art.sprite("cottage", 2, 0)
	c.centered = false
	c.position = COTTAGE
	add_child(c)
	add_tap(c, Rect2(66, 0, 10, 26), func() -> void:
		Sfx.play("puff", -6.0)
		for i in 3:
			get_tree().create_timer(i * 0.25).timeout.connect(func() -> void: Fx.inst.puff(COTTAGE + Vector2(70, -2 - i * 2), 14.0))
	, 1, "chimney")
	add_tap(c, Rect2(0, 6, 96, 32), func() -> void:
		Sfx.play("rustle", -12.0, 0.7)
		for i in 3:
			Fx.inst.leaf(COTTAGE + Vector2(_rng.randf_range(10, 86), 38), 30.0)
	, 0, "roof")
	add_tap(c, Rect2(60, 52, 14, 28), func() -> void:
		Sfx.play("knock", 0.0)
		get_tree().create_timer(0.18).timeout.connect(func() -> void: Sfx.play("knock", -2.0, 1.1))
		Fx.inst.icon_pop(COTTAGE + Vector2(67, 48), Fx.ICON_QUESTION)
	, 1, "door")
	add_tap(c, Rect2(10, 34, 77, 46), func() -> void:
		Sfx.play("knock", -10.0, 0.6)
	, -1, "wall")
	# the lit window, on the glow layer so night doesn't dim it
	var at := AtlasTexture.new()
	at.atlas = Art.tex("cottage")
	at.region = Rect2(96 + 20, 44, 24, 18)
	window_glow = Sprite2D.new()
	window_glow.texture = at
	window_glow.centered = false
	window_glow.position = COTTAGE + Vector2(20, 44)
	window_glow.modulate.a = 0.0
	glow_layer.add_child(window_glow)
	# the tray and its cookies
	var tray := Art.sprite("tray")
	tray.centered = false
	tray.position = Vector2(52, -21)
	tray.visible = false
	tray.name = "Tray"
	add_child(tray)
	for x in [55, 61, 67]:
		var ck := Art.sprite("cookie", 4)
		ck.position = Vector2(x, -24 - (1 if x == 61 else 0))
		ck.visible = false
		add_child(ck)
		tray_cookies.append(ck)
		add_tap(ck, Rect2(-4, -4, 8, 8), func() -> void: glint(ck), 3, "cookie")
	# bell by the door
	var bell := Art.sprite("bell", 4, 1)
	bell.centered = false
	bell.position = COTTAGE + Vector2(78, 39)
	add_child(bell)
	add_tap(bell, Rect2(0, 0, 9, 12), func() -> void: _ring(bell), 2, "bell")
	# lantern post
	lantern = Art.prop("lantern", 136, 0, 2, 0)
	add_child(lantern)
	var lat := AtlasTexture.new()
	lat.atlas = Art.tex("lantern")
	lat.region = Rect2(9 + 2, 1, 5, 7)
	lantern_glow = Sprite2D.new()
	lantern_glow.texture = lat
	lantern_glow.centered = false
	lantern_glow.position = lantern.position + Vector2(2, 1)
	lantern_glow.modulate.a = 0.0
	glow_layer.add_child(lantern_glow)
	add_tap(lantern, Rect2(0, 0, 9, 28), func() -> void:
		set_lantern(not lantern_on)
		Sfx.play("pop", -8.0, 0.8)
	, 2, "lantern")

func _garden() -> void:
	_bush("bush_green", 160, true)
	_bush("bush_red", 232, false)
	_bush("bush_red", 500, false)
	_bush("bush_gold", 790, false)
	for x in [204, 216, 872]:
		var m := Art.prop("mushroom", x, 1, 2, 0)
		add_child(m)
		add_tap(m, Rect2(0, 0, 10, 9), func() -> void:
			m.frame = 1
			Sfx.play("boing", -6.0, _rng.randf_range(0.9, 1.3))
			Fx.inst.puff(m.position + Vector2(5, -2), 6.0)
			get_tree().create_timer(0.25).timeout.connect(func() -> void: m.frame = 0)
		, 2, "mushroom")
	for x in [270, 352]:
		var pile := Art.prop("leafpile", x, 1)
		add_child(pile)
		add_tap(pile, Rect2(0, 0, 30, 9), func() -> void:
			Sfx.play("rustle", -4.0, 1.2)
			for i in 7:
				var from := pile.position + Vector2(_rng.randf_range(4, 26), 4)
				_toss_leaf(from)
		, 1, "leaves")
	var rock := Art.prop("rock", 628, 1)
	add_child(rock)
	add_tap(rock, Rect2(0, 0, 22, 12), func() -> void:
		Sfx.play("knock", -4.0, 0.7)
		Fx.inst.puff(rock.position + Vector2(11, 2), 4.0)
	, 1, "rock")

func _bush(strip: String, x: float, birds: bool) -> void:
	var b := Art.prop(strip, x, 1, 3, 0)
	add_child(b)
	var hidden: Array = []
	if birds:
		for i in 3:
			var s := Art.sprite("sparrow", 4, 0)
			s.position = b.position + Vector2(8 + i * 8, 6)
			s.visible = false
			add_child(s)
			hidden.append(s)
	add_tap(b, Rect2(0, 0, 32, 22), func() -> void:
		Sfx.play("rustle", -2.0, _rng.randf_range(0.9, 1.15))
		var tw := b.create_tween()
		for k in 4:
			tw.tween_callback(func() -> void: b.frame = 1 + (k % 2))
			tw.tween_interval(0.08)
		tw.tween_callback(func() -> void: b.frame = 0)
		for i in 2:
			Fx.inst.leaf(b.position + Vector2(_rng.randf_range(4, 28), 6), 14.0)
		if birds:
			_flush(hidden)
	, 1, "bush")

func _flush(birds: Array) -> void:
	for i in birds.size():
		var s: Sprite2D = birds[i]
		if s.visible:
			continue
		s.visible = true
		var from := s.position
		var dir := -1.0 if i % 2 == 0 else 1.0
		var to := from + Vector2(dir * _rng.randf_range(90, 160), -_rng.randf_range(70, 110))
		s.flip_h = dir > 0
		Sfx.play("chirp", -8.0, _rng.randf_range(0.9, 1.3))
		var tw := s.create_tween()
		tw.tween_method(func(k: float) -> void:
			s.position = from.lerp(to, k) + Vector2(0, sin(k * 20.0) * 2.0)
			s.frame = 2 if int(k * 24.0) % 2 == 0 else 3
		, 0.0, 1.0, 2.2 + i * 0.3)
		tw.tween_callback(func() -> void:
			s.visible = false
			s.position = from
			s.frame = 0)

func _crow_tree() -> void:
	var t := Art.prop("hemlock/tree_4", TREE.x, TREE.y + 128)
	t.position = TREE
	add_child(t)
	# the trunk knocks loose leaves; the crowns shed leaves too
	add_tap(t, Rect2(48, 60, 32, 64), func() -> void:
		Sfx.play("knock", -2.0, 0.8)
		for i in 5:
			_drop_leaf_from(TREE + Vector2(_rng.randf_range(10, 118), _rng.randf_range(20, 70)))
		_drop_acorn(TREE + Vector2(_rng.randf_range(30, 100), 50))
	, 0, "trunk")
	add_tap(t, Rect2(0, 10, 128, 70), func() -> void:
		Sfx.play("rustle", -6.0, 1.3)
		for i in 4:
			_drop_leaf_from(TREE + Vector2(_rng.randf_range(10, 118), _rng.randf_range(15, 60)))
	, -1, "canopy")

func _den() -> void:
	var d := Art.prop("den", DEN.x, 0)
	add_child(d)
	var eyes := Node2D.new()
	eyes.position = DEN_HOLE + Vector2(-2, -5)
	eyes.visible = false
	glow_layer.add_child(eyes)
	for dx in [0, 3]:
		var e := ColorRect.new()
		e.color = Color("#ffe08a")
		e.size = Vector2(1, 1)
		e.position = Vector2(dx, 0)
		eyes.add_child(e)
	add_tap(d, Rect2(0, 0, 52, 22), func() -> void:
		Sfx.play("knock", -6.0, 0.9)
		eyes.visible = true
		get_tree().create_timer(0.9).timeout.connect(func() -> void: eyes.visible = false)
	, 0, "den")
	set_meta("den_eyes", eyes)

func _pond() -> void:
	var p := Art.prop("pond", POND.x, POND.y + 16)
	p.position = POND
	add_child(p)
	add_tap(p, Rect2(4, 0, 112, 12), func() -> void:
		pass  # handled with the tap point in tap_pond()
	, 0, "pond")
	var pad := Art.prop("lilypad", 700, 4)
	add_child(pad)
	frog = Art.sprite("hemlock/frog")
	frog.position = Vector2(706, -4)
	add_child(frog)
	add_tap(frog, Rect2(-7, -6, 14, 12), func() -> void: _frog_hop(), 3, "frog")
	for x in [648, 774]:
		var r := Art.prop("reeds", x, 2, 4, 0)
		add_child(r)
		_reeds.append(r)
		add_tap(r, Rect2(0, 0, 14, 24), func() -> void:
			Sfx.play("rustle", -10.0, 1.5)
			r.set_meta("fast", 1.5)
		, 1, "reeds")

func _owl_tree() -> void:
	var t := Art.prop("hemlock/tree_owl", 806, 6, 5, 0)
	add_child(t)
	owl_eyes = t
	add_tap(t, Rect2(40, 16, 26, 24), func() -> void:
		var tw := t.create_tween()
		for f in [1, 2, 3, 4, 0]:
			tw.tween_callback(func() -> void: t.frame = f)
			tw.tween_interval(0.12)
		Sfx.play("croak", -8.0, 2.6)
	, 2, "owl")
	add_tap(t, Rect2(0, 10, 128, 70), func() -> void:
		Sfx.play("rustle", -6.0, 1.2)
		for i in 4:
			_drop_leaf_from(t.position + Vector2(_rng.randf_range(10, 118), _rng.randf_range(15, 60)))
	, -1, "canopy")

func _fireflies_make() -> void:
	for i in 16:
		var f := Art.sprite("firefly", 2, i % 2)
		f.modulate.a = 0.0
		glow_layer.add_child(f)
		_fireflies.append({"s": f, "home": Vector2(_rng.randf_range(20, WIDTH - 20), _rng.randf_range(-50, -6)), "ph": _rng.randf() * TAU, "sp": _rng.randf_range(0.4, 0.9)})

# ---- behaviour ----------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	for r in _reeds:
		var fast: float = r.get_meta("fast", 0.0)
		if fast > 0.0:
			r.set_meta("fast", fast - delta)
		var rate := 9.0 if fast > 0.0 else 1.6
		r.frame = int(_t * rate + r.position.x) % 4
	for f in _fireflies:
		var s: Sprite2D = f["s"]
		var ph: float = f["ph"] + _t * f["sp"]
		s.position = (f["home"] + Vector2(sin(ph) * 14.0, sin(ph * 1.7) * 6.0)).round()
		var blink := 0.5 + 0.5 * sin(_t * 3.0 * f["sp"] + f["ph"] * 3.0)
		s.modulate.a = clampf(night * 1.3 - 0.3, 0.0, 1.0) * blink
		s.frame = 1 if blink > 0.6 else 0
	if tray_cookies.size() > 0 and int(_t * 10.0) % 37 == 0:
		for ck in tray_cookies:
			if ck.visible and ck.frame == 0 and _rng.randf() < 0.01:
				glint(ck)

func set_lit(amount: float) -> void:
	window_glow.modulate.a = amount

func set_lantern(on: bool) -> void:
	lantern_on = on
	lantern.frame = 1 if on else 0
	lantern_glow.modulate.a = 1.0 if on else 0.0

func glint(ck: Sprite2D) -> void:
	if not ck.visible:
		return
	Sfx.play("sparkle", -12.0)
	Fx.inst.sparkle(ck.global_position)
	var tw := ck.create_tween()
	tw.tween_callback(func() -> void: ck.frame = 1)
	tw.tween_interval(0.15)
	tw.tween_callback(func() -> void: ck.frame = 2)
	tw.tween_interval(0.15)
	tw.tween_callback(func() -> void: ck.frame = 0 if ck.frame != 3 else 3)

func tap_pond(p: Vector2) -> void:
	Sfx.play("splash", -6.0, _rng.randf_range(0.9, 1.2))
	Fx.inst.ripple(Vector2(p.x, POND.y + 5))

func _ring(bell: Sprite2D) -> void:
	Sfx.play("bell", -4.0)
	var tw := bell.create_tween()
	for f in [0, 1, 2, 1, 0, 1, 2, 1]:
		tw.tween_callback(func() -> void: bell.frame = f)
		tw.tween_interval(0.1)

func _frog_hop() -> void:
	Sfx.play("croak", -2.0)
	var y0 := -4.0
	var tw := frog.create_tween()
	tw.tween_property(frog, "position:y", y0 - 10.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(frog, "position:y", y0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		Fx.inst.ripple(Vector2(706, POND.y + 6))
		Sfx.play("splash", -14.0, 1.6))

func _drop_leaf_from(p: Vector2) -> void:
	Fx.inst.leaf(p, -p.y - 2.0)

func _toss_leaf(from: Vector2) -> void:
	var s := Art.sprite("leaf", 4, _rng.randi() % 4)
	s.position = from
	glow_layer.add_child(s)
	var v := Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-60, -35))
	var tw := s.create_tween()
	tw.tween_method(func(k: float) -> void:
		var tt := k * 1.6
		s.position = (from + Vector2(v.x * tt, v.y * tt + 50.0 * tt * tt)).round()
		s.position.y = minf(s.position.y, -1.0)
		s.frame = int(tt * 8.0) % 4
	, 0.0, 1.0, 1.6)
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.tween_callback(s.queue_free)

func _drop_acorn(from: Vector2) -> void:
	var a := Art.sprite("acorn")
	a.position = from
	add_child(a)
	var tw := a.create_tween()
	var fall := -from.y - 2.0
	tw.tween_property(a, "position:y", -2.0, sqrt(fall) * 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: Sfx.play("knock", -4.0, 1.4))
	tw.tween_property(a, "position", Vector2(from.x + 6, -7), 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "position", Vector2(from.x + 9, -2), 0.15).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: Sfx.play("knock", -12.0, 1.6))
	tw.tween_interval(2.5)
	tw.tween_property(a, "modulate:a", 0.0, 0.5)
	tw.tween_callback(a.queue_free)

# Leave crumbs on the ground where the cookie was caught.
func add_crumbs(x: float) -> void:
	for i in 5:
		var c := Art.sprite("crumbs", 4, i % 4)
		c.position = Vector2(x + _rng.randf_range(-7, 7), -1).round()
		crumbs.add_child(c)
		add_tap(c, Rect2(-3, -3, 6, 6), func() -> void:
			Sfx.play("pop", -12.0, 1.4)
			Fx.inst.sparkle(c.global_position)
		, 1, "crumb")

func clear_crumbs(n: int = 99) -> void:
	var k := 0
	for c in crumbs.get_children():
		if k >= n:
			break
		c.queue_free()
		k += 1

# Fallback for taps that hit nothing: the wood still answers.
func tap_empty(p: Vector2) -> void:
	if p.y < -70.0:
		_bird_across(p)
	elif night > 0.5:
		for i in 3:
			Fx.inst.sparkle(p + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-6, 6)))
		Sfx.play("sparkle", -16.0, 0.8)
	else:
		Fx.inst.puff(Vector2(p.x, minf(p.y, -2.0)), 5.0)
		Sfx.play("puff", -14.0, 1.3)

func _bird_across(p: Vector2) -> void:
	var s := Art.sprite("sparrow", 4, 2)
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var from := p + Vector2(-dir * 30.0, 6.0)
	var to := p + Vector2(dir * 140.0, -30.0)
	s.flip_h = dir > 0.0
	s.position = from
	glow_layer.add_child(s)
	Sfx.play("chirp2", -8.0, _rng.randf_range(0.9, 1.2))
	var tw := s.create_tween()
	tw.tween_method(func(k: float) -> void:
		s.position = from.lerp(to, k).round()
		s.frame = 2 if int(k * 30.0) % 2 == 0 else 3
	, 0.0, 1.0, 2.0)
	tw.tween_callback(s.queue_free)
