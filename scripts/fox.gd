class_name Fox
extends Node2D
# The fox, drawn to the style guide (tools/gen_characters.gd). The node's
# origin is at his feet. The art faces right.

var spr: AnimatedSprite2D
var cookie: Sprite2D
var holding := false
var facing_right := true
var base_anim := "sit"
var _once := 0.0
var _tw: Tween
var _taps := 0

const COOKIE_AT := {
	"trot": Vector2(14, -14), "sniff": Vector2(14, -11),
	"sit": Vector2(10, -16), "yip": Vector2(10, -16), "smile": Vector2(10, -16),
	"lookup": Vector2(7, -22), "talk": Vector2(7, -22), "leap": Vector2(9, -22),
	"bow": Vector2(13, -6),
}

func _ready() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Art.add_anim(sf, "trot", "fox_trot", 32, 24, 10.0)
	Art.add_anim(sf, "sniff", "fox_sniff", 32, 24, 7.0)
	Art.add_anim(sf, "sit", "fox_sit", 32, 24, 3.0)
	Art.add_anim(sf, "lookup", "fox_lookup", 32, 24, 1.5)
	Art.add_anim(sf, "talk", "fox_talk", 32, 24, 5.0)
	Art.add_anim(sf, "smile", "fox_smile", 32, 24, 1.5)
	Art.add_anim(sf, "bow", "fox_bow", 32, 24, 1.0)
	Art.add_anim(sf, "leap", "fox_leap", 32, 24, 7.0, false)
	Art.add_anim(sf, "yip", "fox_yip", 32, 24, 6.0)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.offset = Vector2(0, -11)
	add_child(spr)
	cookie = Art.sprite("cookie", 4)
	cookie.visible = false
	add_child(cookie)
	_apply("sit")

func set_anim(a: String) -> void:
	base_anim = a
	if _once <= 0.0:
		_apply(a)

func play_once(a: String, dur: float) -> void:
	_once = dur
	_apply(a)

func _apply(a: String) -> void:
	spr.play(a)

func _process(delta: float) -> void:
	if _once > 0.0:
		_once -= delta
		if _once <= 0.0:
			_apply(base_anim)
	spr.flip_h = not facing_right
	cookie.visible = holding
	var p: Vector2 = COOKIE_AT.get(spr.animation, Vector2(10, -16))
	if not facing_right:
		p.x = -p.x
	cookie.position = p

func mouth_global() -> Vector2:
	var p: Vector2 = COOKIE_AT.get(spr.animation, Vector2(10, -16))
	if not facing_right:
		p.x = -p.x
	return global_position + p

func trot_to(x: float, dur: float, anim: String = "trot", end_anim: String = "sit") -> Tween:
	if _tw and _tw.is_valid():
		_tw.kill()
	facing_right = x > position.x
	set_anim(anim)
	_tw = Director.track(create_tween())
	_tw.tween_property(self, "position:x", x, dur)
	_tw.tween_callback(func() -> void: set_anim(end_anim))
	return _tw

func leap_to(target: Vector2, dur: float) -> Tween:
	if _tw and _tw.is_valid():
		_tw.kill()
	set_anim("leap")
	spr.frame = 0
	var from := position
	_tw = Director.track(create_tween())
	_tw.tween_method(func(k: float) -> void:
		var e := k
		position = from.lerp(target, e) + Vector2(0, -sin(e * PI) * 14.0)
		spr.frame = 0 if k < 0.15 else (1 if k < 0.5 else 2)
	, 0.0, 1.0, dur)
	return _tw

func stop_moving() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()

func tap() -> void:
	_taps += 1
	if base_anim in ["trot", "sniff"]:
		play_once("sniff", 0.7)
		Sfx.play("puff", -10.0, 1.5)
		Fx.inst.puff(global_position + Vector2(14 if facing_right else -14, -4))
		return
	if base_anim == "leap":
		return
	if holding:
		play_once("smile", 0.9)
		Fx.inst.sparkle(mouth_global())
		return
	if _taps % 2 == 0:
		play_once("yip", 0.5)
		Sfx.play("yip", -6.0, randf_range(0.95, 1.1))
	else:
		play_once("smile", 1.0)
		Sfx.play("pop", -12.0, 0.7)
		Fx.inst.icon_pop(global_position + Vector2(0, -30), 4)
