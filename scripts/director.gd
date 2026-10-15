class_name Director
extends Node
# Acts out the story: each beat in data/timeline.json names a handler here
# (_beat_<id>) that tells the crow, the fox and the wood what to do. Beats run
# when the show clock reaches their time, whatever the player is doing.
#
# Every story tween goes through track(). Before a new beat runs, any story
# tween still going is finished at once, so the scene is always in the state
# the timeline expects, even if beats are retimed close together or the clock
# jumps (a seek, a skip, a slow frame).

static var live: Array = []

static func track(t: Tween) -> Tween:
	live.append(t)
	return t

static func finish_all() -> void:
	var list := live.duplicate()
	live.clear()
	for t in list:
		if t is Tween and t.is_valid() and t.is_running():
			t.custom_step(10000.0)
	# finishing may have started new tweens: finish those too
	if not live.is_empty():
		finish_all()

signal beat_started(beat: Dictionary)

var world: World
var crow: Crow
var fox: Fox
var beats: Array = []
var next_i := 0
var current := {}
var falling: Sprite2D
var crumb_x := 430.0
var caught := false

func setup(w: World, c: Crow, f: Fox, beat_list: Array) -> void:
	world = w
	crow = c
	fox = f
	beats = beat_list.duplicate()
	beats.sort_custom(func(a, b) -> bool: return float(a["t"]) < float(b["t"]))
	reset()

# Back to the very start: the opening tableau, before any beat.
func reset() -> void:
	for t in live:
		if t is Tween and t.is_valid():
			t.kill()
	live.clear()
	next_i = 0
	current = {}
	caught = false
	if is_instance_valid(falling):
		falling.queue_free()
	crow.stop_moving()
	crow.position = World.PERCH
	crow.facing_left = true
	crow.holding = false
	crow.cookie_at_feet = false
	crow.flying = false
	crow.set_anim("sleep")
	fox.stop_moving()
	fox.position = World.DEN_HOLE
	fox.visible = false
	fox.modulate.a = 1.0
	fox.holding = false
	fox.facing_right = false
	fox.set_anim("sit")
	world.get_node("Tray").visible = false
	for ck in world.tray_cookies:
		ck.visible = false
		ck.frame = 0
	world.clear_crumbs()
	world.set_lantern(true)
	world.set_lit(0.8)

func update(t: float) -> void:
	while next_i < beats.size() and float(beats[next_i]["t"]) <= t:
		finish_all()
		var b: Dictionary = beats[next_i]
		var nt: float = float(beats[next_i + 1]["t"]) if next_i + 1 < beats.size() else float(b["t"]) + 12.0
		current = b
		next_i += 1
		var fn := "_beat_" + str(b["id"])
		if has_method(fn):
			call(fn, maxf(0.5, nt - float(b["t"])))
		beat_started.emit(b)

# Where the camera should look, in world coordinates.
func focus_point() -> Vector2:
	var f = current.get("focus", "crow")
	if f is float or f is int:
		return Vector2(float(f), -40)
	match str(f):
		"fox":
			return fox.global_position + Vector2(0, -12) if fox.visible else World.DEN_HOLE
		"cookie":
			if is_instance_valid(falling):
				return falling.global_position
			if fox.holding:
				return fox.global_position + Vector2(0, -12)
			if crow.holding:
				return crow.global_position + Vector2(0, -8)
			return world.tray_cookies[2].global_position
		"cottage":
			return World.COTTAGE + Vector2(48, 40)
		"tree":
			return Vector2((crow.global_position.x + World.FOX_SIT_X) * 0.5, -40)
		"den":
			return World.DEN_HOLE
	return crow.global_position + Vector2(0, -8)

func _seq() -> Tween:
	return track(create_tween())

# ---- the beats ----------------------------------------------------------

func _beat_dawn(_d: float) -> void:
	crow.set_anim("sleep")
	world.set_lantern(true)
	world.set_lit(0.8)

func _beat_tray(_d: float) -> void:
	var tray: Sprite2D = world.get_node("Tray")
	var s := _seq()
	s.tween_callback(func() -> void:
		Sfx.play("knock", -10.0, 1.2)
		Fx.inst.puff(World.COTTAGE + Vector2(32, 52), 6.0))
	s.tween_interval(0.6)
	s.tween_callback(func() -> void:
		tray.visible = true
		for ck in world.tray_cookies:
			ck.visible = true
		Sfx.play("pop", -8.0)
		Fx.inst.sparkle(Vector2(61, -26)))
	for i in 3:
		s.tween_interval(0.7)
		s.tween_callback(func() -> void: Fx.inst.puff(Vector2(56 + i * 5, -28), 10.0))
	s.tween_interval(1.5)
	s.tween_callback(func() -> void: world.set_lantern(false))
	s.tween_property(world.window_glow, "modulate:a", 0.0, 2.0)

func _beat_crow_wakes(d: float) -> void:
	crow.set_anim("idle")
	crow.play_once("startle", 0.6)
	Sfx.play("caw", -8.0, 1.1)
	var s := _seq()
	s.tween_interval(minf(2.0, d * 0.25))
	s.tween_callback(func() -> void: crow.set_anim("preen"))
	s.tween_interval(minf(3.5, d * 0.4))
	s.tween_callback(func() -> void:
		crow.set_anim("idle")
		crow.hop(-4.0))

func _beat_crow_spies(d: float) -> void:
	crow.facing_left = true
	crow.play_once("startle", 0.8)
	Fx.inst.bang(crow.global_position + Vector2(0, -20))
	var s := _seq()
	for i in 3:
		s.tween_interval(minf(1.8, d / 4.0))
		s.tween_callback(func() -> void: world.glint(world.tray_cookies[2]))

func _beat_crow_swoops(d: float) -> void:
	crow.fly_to(World.SILL_LAND, minf(6.0, d - 0.3))

func _beat_crow_takes(d: float) -> void:
	crow.position = World.SILL_LAND
	crow.facing_left = true
	crow.set_anim("idle")
	var s := _seq()
	s.tween_callback(func() -> void: crow.play_once("peck", 0.5))
	s.tween_interval(0.45)
	s.tween_callback(func() -> void:
		world.tray_cookies[2].visible = false
		crow.holding = true
		Sfx.play("pop", -4.0, 1.2)
		Fx.inst.sparkle(crow.beak_global()))
	s.tween_interval(0.8)
	s.tween_callback(func() -> void:
		crow.play_once("startle", 0.4)
		Fx.inst.bang(crow.global_position + Vector2(0, -20)))
	s.tween_interval(0.5)
	s.tween_callback(func() -> void: crow.fly_to(World.PERCH, minf(6.0, d - 2.2)))

func _beat_crow_home(d: float) -> void:
	crow.position = World.PERCH
	crow.holding = true
	crow.facing_left = true
	crow.set_anim("idle")
	var s := _seq()
	s.tween_interval(minf(2.0, d * 0.2))
	s.tween_callback(func() -> void:
		crow.set_anim("preen")
		Fx.inst.sparkle(crow.global_position + Vector2(0, -10)))
	s.tween_interval(minf(4.0, d * 0.4))
	s.tween_callback(func() -> void: crow.set_anim("idle"))

func _beat_fox_wakes(d: float) -> void:
	var eyes: Node2D = world.get_meta("den_eyes")
	eyes.visible = true
	fox.position = World.DEN_HOLE
	fox.facing_right = false
	fox.visible = false
	var s := _seq()
	s.tween_interval(minf(1.5, d * 0.2))
	s.tween_callback(func() -> void:
		eyes.visible = false
		fox.visible = true
		fox.modulate.a = 0.0
		fox.set_anim("sit"))
	s.tween_property(fox, "modulate:a", 1.0, 0.6)
	s.tween_property(fox, "position:x", World.DEN_HOLE.x - 18.0, 0.8)
	s.tween_callback(func() -> void:
		fox.set_anim("bow")
		Sfx.play("yip", -10.0, 0.8))
	s.tween_interval(minf(1.6, d * 0.2))
	s.tween_callback(func() -> void:
		fox.set_anim("yip")
		Sfx.play("yip", -6.0, 1.0))
	s.tween_interval(0.6)
	s.tween_callback(func() -> void: fox.set_anim("sniff"))

func _beat_fox_trots(d: float) -> void:
	fox.visible = true
	fox.modulate.a = 1.0
	var x0 := fox.position.x
	var mid := lerpf(x0, World.FOX_SIT_X, 0.55)
	var s := _seq()
	s.tween_callback(func() -> void:
		fox.facing_right = false
		fox.set_anim("sniff"))
	s.tween_property(fox, "position:x", mid, minf(4.0, d * 0.45))
	s.tween_callback(func() -> void: fox.set_anim("sit"))
	s.tween_interval(minf(1.2, d * 0.12))
	s.tween_callback(func() -> void: fox.set_anim("trot"))
	s.tween_property(fox, "position:x", World.FOX_SIT_X, minf(2.4, d * 0.3))
	s.tween_callback(func() -> void: fox.set_anim("sit"))

func _beat_fox_sees(d: float) -> void:
	fox.visible = true
	fox.position = Vector2(World.FOX_SIT_X, 0)
	fox.facing_right = false
	fox.set_anim("lookup")
	crow.facing_left = false
	crow.play_once("startle", 0.8)
	Sfx.play("caw", -10.0, 1.15)
	var s := _seq()
	s.tween_interval(minf(2.0, d * 0.3))
	s.tween_callback(func() -> void: Fx.inst.icon_pop(fox.global_position + Vector2(-4, -30), Fx.ICON_COOKIE))

func _talk(icons: Array, d: float) -> void:
	fox.set_anim("talk")
	Fx.inst.bubble(fox.global_position + Vector2(-6, -26), icons, minf(4.0, d * 0.45))
	Sfx.play("yip", -14.0, 1.3)

func _beat_flatter_feathers(d: float) -> void:
	_talk([Fx.ICON_FEATHER], d)
	var s := _seq()
	s.tween_interval(minf(2.4, d * 0.2))
	s.tween_callback(func() -> void:
		fox.set_anim("lookup")
		crow.set_anim("preen")
		Fx.inst.sparkle(crow.global_position + Vector2(0, -10)))
	s.tween_interval(minf(4.0, d * 0.3))
	s.tween_callback(func() -> void:
		crow.set_anim("idle")
		fox.set_anim("smile"))
	s.tween_interval(minf(3.0, d * 0.2))
	s.tween_callback(func() -> void: fox.set_anim("lookup"))

func _beat_flatter_eyes(d: float) -> void:
	_talk([Fx.ICON_STAR], d)
	var s := _seq()
	s.tween_interval(minf(2.0, d * 0.2))
	s.tween_callback(func() -> void:
		fox.set_anim("lookup")
		crow.play_once("startle", 0.5)
		for i in 3:
			Fx.inst.sparkle(crow.global_position + Vector2(0, -12)))
	s.tween_interval(minf(3.0, d * 0.25))
	s.tween_callback(func() -> void: crow.hop(3.0))
	s.tween_interval(minf(3.0, d * 0.2))
	s.tween_callback(func() -> void:
		fox.set_anim("smile")
		crow.set_anim("preen"))
	s.tween_interval(minf(3.0, d * 0.2))
	s.tween_callback(func() -> void:
		crow.set_anim("idle")
		fox.set_anim("lookup"))

func _beat_flatter_crown(d: float) -> void:
	fox.set_anim("bow")
	Fx.inst.bubble(fox.global_position + Vector2(-6, -26), [Fx.ICON_CROWN], minf(4.0, d * 0.4))
	var s := _seq()
	s.tween_interval(minf(2.5, d * 0.2))
	s.tween_callback(func() -> void: fox.set_anim("lookup"))
	# she struts along the branch, chin up
	for dx in [-5.0, -5.0, 5.0, 5.0]:
		s.tween_interval(minf(1.2, d * 0.08))
		s.tween_callback(func() -> void:
			crow.hop(dx)
			Fx.inst.sparkle(crow.global_position + Vector2(0, -12)))
	s.tween_interval(0.6)
	s.tween_callback(func() -> void:
		crow.position = World.PERCH
		crow.facing_left = false
		crow.set_anim("idle"))

func _beat_ask_song(d: float) -> void:
	crow.position = World.PERCH
	_talk([Fx.ICON_NOTE, Fx.ICON_QUESTION], d)
	var s := _seq()
	s.tween_interval(minf(2.5, d * 0.25))
	s.tween_callback(func() -> void: fox.set_anim("smile"))
	# she hesitates: looks down at the cookie, out at the wood, at the fox
	s.tween_interval(minf(2.0, d * 0.15))
	s.tween_callback(func() -> void: crow.facing_left = true)
	s.tween_interval(minf(2.0, d * 0.15))
	s.tween_callback(func() -> void: crow.facing_left = false)
	s.tween_interval(minf(1.5, d * 0.12))
	s.tween_callback(func() -> void:
		crow.play_once("startle", 0.5)
		fox.set_anim("lookup"))

func _beat_sing(d: float) -> void:
	crow.position = World.PERCH
	crow.facing_left = false
	crow.holding = false
	crow.set_anim("sing")
	Sfx.play("song", -4.0)
	# the cookie slips from her open beak
	falling = Art.sprite("cookie", 4)
	falling.position = crow.global_position + Vector2(5, -8)
	world.add_child(falling)
	fox.set_anim("talk")
	var catch_at := Vector2(World.FOX_SIT_X - 14.0, 0)
	crumb_x = catch_at.x + 2.0
	var s := _seq()
	s.tween_interval(0.15)
	s.tween_callback(func() -> void: fox.leap_to(catch_at, 0.6))
	var from := falling.position
	s.tween_method(func(k: float) -> void:
		if is_instance_valid(falling):
			var to := catch_at + Vector2(-8, -20)
			falling.position = Vector2(lerpf(from.x, to.x, k), lerpf(from.y, to.y, k * k)).round()
			falling.frame = int(k * 8.0) % 3
	, 0.0, 1.0, 0.6)
	s.tween_callback(func() -> void:
		if is_instance_valid(falling):
			falling.queue_free()
		fox.position = catch_at
		fox.holding = true
		caught = true
		fox.set_anim("sit")
		Sfx.play("pop", -2.0, 0.8)
		world.add_crumbs(crumb_x)
		Fx.inst.sparkle(fox.mouth_global()))
	# she sings on a moment, not yet knowing
	var notes := int(clampf((d - 1.0) / 0.45, 1.0, 8.0))
	for i in notes:
		s.tween_callback(func() -> void: Fx.inst.note(crow.global_position + Vector2(7, -14)))
		s.tween_interval(0.45)

func _beat_gone(d: float) -> void:
	crow.position = World.PERCH
	crow.holding = false
	crow.facing_left = false
	crow.play_once("startle", 1.0)
	crow.set_anim("idle")
	Fx.inst.bang(crow.global_position + Vector2(0, -20))
	Sfx.play("caw", -4.0, 0.9)
	if not caught:
		fox.position = Vector2(World.FOX_SIT_X - 14.0, 0)
		fox.holding = true
		world.add_crumbs(crumb_x)
		caught = true
	fox.facing_right = false
	fox.set_anim("sit")
	var s := _seq()
	s.tween_interval(minf(1.6, d * 0.4))
	s.tween_callback(func() -> void: crow.set_anim("droop"))

func _beat_fox_thanks(d: float) -> void:
	fox.holding = true
	fox.facing_right = false
	fox.set_anim("bow")
	Sfx.play("yip", -12.0, 0.9)
	var s := _seq()
	s.tween_interval(minf(2.5, d * 0.35))
	s.tween_callback(func() -> void:
		fox.set_anim("smile")
		Fx.inst.icon_pop(fox.global_position + Vector2(-4, -30), Fx.ICON_HEART))
	s.tween_interval(minf(2.5, d * 0.3))
	s.tween_callback(func() -> void: fox.set_anim("sit"))

func _beat_fox_leaves(d: float) -> void:
	fox.holding = true
	crow.set_anim("droop")
	var s := _seq()
	s.tween_callback(func() -> void:
		fox.facing_right = true
		fox.set_anim("trot"))
	s.tween_property(fox, "position:x", World.DEN_HOLE.x - 6.0, minf(6.0, d * 0.6))
	s.tween_property(fox, "modulate:a", 0.0, 0.6)
	s.tween_callback(func() -> void:
		fox.visible = false
		fox.holding = false
		fox.set_anim("sit"))

func _beat_dusk(_d: float) -> void:
	crow.position = World.PERCH
	crow.set_anim("droop")
	fox.visible = false
	var s := _seq()
	s.tween_property(world.window_glow, "modulate:a", 1.0, 3.0)
	s.tween_callback(func() -> void: world.set_lantern(true))

func _beat_crumbs(d: float) -> void:
	crow.holding = false
	var spot := Vector2(crumb_x + 10.0, 0)
	crow.fly_to(spot, minf(3.0, d * 0.3), "idle")
	var s := _seq()
	s.tween_interval(minf(3.2, d * 0.32))
	s.tween_callback(func() -> void:
		crow.facing_left = true
		crow.set_anim("peck"))
	for i in 4:
		s.tween_interval(minf(1.4, d * 0.12))
		s.tween_callback(func() -> void:
			world.clear_crumbs(1)
			Sfx.play("pop", -12.0, 1.5))
	s.tween_callback(func() -> void: crow.set_anim("idle"))

func _beat_night(d: float) -> void:
	world.clear_crumbs()
	crow.fly_to(World.PERCH, minf(4.0, d * 0.35), "idle")
	var s := _seq()
	s.tween_interval(minf(5.0, d * 0.45))
	s.tween_callback(func() -> void:
		crow.facing_left = true
		crow.set_anim("sleep"))
