class_name Crow
extends Node2D
# The crow from Hemlock's Tower (idle, flap and fall strips copied from it),
# plus the poses this story needs, drawn to match (tools/gen_characters.gd).
# The node's origin is at her feet. The art faces left.

var spr: AnimatedSprite2D
var cookie: Sprite2D
var holding := false
var cookie_at_feet := false
var facing_left := true
var flying := false
var base_anim := "idle"
var _once := 0.0
var _tw: Tween
var _taps := 0

func _ready() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Art.add_anim(sf, "idle", "hemlock/crow", 16, 16, 5.0)
	Art.add_anim(sf, "flap", "hemlock/crowFlap", 32, 32, 10.0)
	Art.add_anim(sf, "glide", "hemlock/crowFlap", 32, 32, 1.0, true, [1])
	Art.add_anim(sf, "fall", "hemlock/crow_fall", 16, 16, 5.0)
	Art.add_anim(sf, "preen", "crow_preen", 16, 16, 5.0)
	Art.add_anim(sf, "sing", "crow_sing", 16, 16, 4.0)
	Art.add_anim(sf, "startle", "crow_startle", 16, 16, 8.0)
	Art.add_anim(sf, "droop", "crow_droop", 16, 16, 1.2)
	Art.add_anim(sf, "peck", "crow_peck", 16, 16, 4.0)
	Art.add_anim(sf, "sleep", "crow_sleep", 16, 16, 0.8)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = sf
	add_child(spr)
	cookie = Art.sprite("cookie", 4)
	cookie.visible = false
	add_child(cookie)
	_apply("idle")

func set_anim(a: String) -> void:
	base_anim = a
	if _once <= 0.0:
		_apply(a)

func play_once(a: String, dur: float) -> void:
	_once = dur
	_apply(a)

func _apply(a: String) -> void:
	if spr.animation != a or not spr.is_playing():
		spr.play(a)
	spr.offset = Vector2(0, -13) if a in ["flap", "glide"] else Vector2(0, -6)

func _process(delta: float) -> void:
	if _once > 0.0:
		_once -= delta
		if _once <= 0.0:
			_apply(base_anim)
	spr.flip_h = not facing_left
	cookie.visible = holding
	cookie.position = cookie_offset()
	cookie.z_index = -1 if spr.animation in ["preen", "sleep"] else 0

func cookie_offset() -> Vector2:
	var a := spr.animation
	var p := Vector2(-5, -8)
	if a in ["flap", "glide"]:
		p = Vector2(-4, -15)
	elif cookie_at_feet or a in ["preen", "sleep", "peck", "droop", "sing"]:
		p = Vector2(-2, -2)
	elif a == "startle":
		p = Vector2(-5, -9)
	if a == "idle" and spr.frame in [3, 7]:
		p.y += 1
	if not facing_left:
		p.x = -p.x
	return p

func beak_global() -> Vector2:
	var p := Vector2(-5, -9) if spr.animation != "flap" else Vector2(-4, -15)
	if not facing_left:
		p.x = -p.x
	return global_position + p

# Fly along an arc. Returns the tween (tracked so the show can skip ahead).
func fly_to(target: Vector2, dur: float, land_anim: String = "idle") -> Tween:
	if _tw and _tw.is_valid():
		_tw.kill()
	flying = true
	facing_left = target.x < position.x
	set_anim("flap")
	Sfx.play("flap", -8.0)
	var from := position
	var lift := clampf(absf(target.x - from.x) * 0.25, 12.0, 50.0)
	var mid := (from + target) * 0.5 + Vector2(0, -lift)
	_tw = Director.track(create_tween())
	_tw.tween_method(func(k: float) -> void:
		var e := smoothstep(0.0, 1.0, k)
		position = from.lerp(mid, e).lerp(mid.lerp(target, e), e)
		if spr.animation == "flap" and k > 0.82:
			_apply("glide")
	, 0.0, 1.0, dur)
	_tw.tween_callback(func() -> void:
		flying = false
		set_anim(land_anim)
		Sfx.play("flap", -14.0, 1.3))
	return _tw

# A little hop along the branch (or the ground).
func hop(dx: float, dur: float = 0.35) -> Tween:
	if _tw and _tw.is_valid():
		_tw.kill()
	if dx != 0.0:
		facing_left = dx < 0.0
	var from := position
	_tw = Director.track(create_tween())
	_tw.tween_method(func(k: float) -> void:
		position = from + Vector2(dx * k, -sin(k * PI) * 4.0)
	, 0.0, 1.0, dur)
	return _tw

func stop_moving() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()

# Tap reactions: never change where she is or what the story has her doing,
# only a flourish on top.
func tap() -> void:
	_taps += 1
	if flying:
		Sfx.play("caw", -6.0, randf_range(0.95, 1.1))
		Fx.inst.feather(global_position + Vector2(0, -8))
		return
	match base_anim:
		"sleep":
			play_once("startle", 0.5)
			Fx.inst.bang(global_position + Vector2(0, -18))
			Sfx.play("caw", -10.0, 1.2)
		"sing":
			Fx.inst.note(global_position + Vector2(-6 if facing_left else 6, -14))
		_:
			if _taps % 3 == 0:
				play_once("startle", 0.6)
				Sfx.play("caw", -6.0)
				Fx.inst.feather(global_position + Vector2(0, -8))
			else:
				play_once("preen", 1.6)
				Sfx.play("rustle", -14.0, 1.6)
				Fx.inst.sparkle(global_position + Vector2(randf_range(-5, 5), -10))
