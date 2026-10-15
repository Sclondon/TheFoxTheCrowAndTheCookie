class_name Fx
extends Node2D
# Little effects: sparkles, music notes, feathers, leaves, puffs, ripples,
# the "!" and the fox's picture-only speech bubbles. Lives on the glow layer
# (above the world, untouched by the time-of-day tint) so they stay bright.

static var inst: Fx

const ICON_FEATHER := 0
const ICON_STAR := 1
const ICON_CROWN := 2
const ICON_NOTE := 3
const ICON_HEART := 4
const ICON_QUESTION := 5
const ICON_COOKIE := 6

func _enter_tree() -> void:
	inst = self

func _anim(strip: String, frames: int, pos: Vector2, fps: float, life: float) -> Sprite2D:
	var s := Art.sprite(strip, frames)
	s.position = pos.round()
	add_child(s)
	var tw := s.create_tween()
	if frames > 1:
		tw.tween_method(func(k: float) -> void: s.frame = mini(frames - 1, int(k * fps)), 0.0, life, life)
	else:
		tw.tween_interval(life)
	tw.tween_callback(s.queue_free)
	return s

func sparkle(pos: Vector2) -> void:
	for i in 3:
		var p := pos + Vector2(randf_range(-6, 6), randf_range(-6, 4))
		var s := _anim("sparkle", 3, p, 8.0, 0.4)
		s.modulate.a = 0.0
		var tw := s.create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_property(s, "modulate:a", 1.0, 0.01)

func note(pos: Vector2) -> void:
	var s := Art.sprite("note", 2, randi() % 2)
	s.position = pos.round()
	add_child(s)
	var drift := randf_range(-10, 10)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		s.position = (pos + Vector2(drift * k + sin(k * 9.0) * 3.0, -40.0 * k)).round()
	, 0.0, 1.0, 2.2)
	tw.tween_property(s, "modulate:a", 0.0, 0.8).set_delay(1.4)
	tw.chain().tween_callback(s.queue_free)

func feather(pos: Vector2) -> void:
	var s := Art.sprite("icons", 7, ICON_FEATHER)
	s.position = pos.round()
	s.scale = Vector2(0.75, 0.75)
	add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		s.position = (pos + Vector2(sin(k * 7.0) * 6.0, 26.0 * k)).round()
	, 0.0, 1.0, 2.0)
	tw.tween_property(s, "modulate:a", 0.0, 0.6).set_delay(1.4)
	tw.chain().tween_callback(s.queue_free)

func leaf(pos: Vector2, fall: float = 40.0) -> void:
	var s := Art.sprite("leaf", 4, randi() % 4)
	s.position = pos.round()
	add_child(s)
	var sway := randf_range(5, 10)
	var ph := randf() * TAU
	var dur := randf_range(1.8, 2.8)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		s.position = (pos + Vector2(sin(k * 6.0 + ph) * sway, fall * k)).round()
		s.frame = int(k * 10.0) % 4
	, 0.0, 1.0, dur)
	tw.tween_property(s, "modulate:a", 0.0, 0.5).set_delay(dur - 0.5)
	tw.chain().tween_callback(s.queue_free)

func puff(pos: Vector2, rise: float = 8.0) -> void:
	var s := Art.sprite("puff", 4)
	s.position = pos.round()
	add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		s.frame = mini(3, int(k * 4.0))
		s.position = (pos + Vector2(k * 3.0, -rise * k)).round()
	, 0.0, 1.0, 1.0)
	tw.tween_property(s, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(s.queue_free)

func ripple(pos: Vector2) -> void:
	_anim("ripple", 3, pos, 4.0, 0.75)

func bang(pos: Vector2) -> void:
	var s := Art.sprite("bang")
	s.position = pos.round()
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", pos.y - 3, 0.12)
	tw.tween_interval(0.6)
	tw.tween_callback(s.queue_free)

# A small bubble with one icon, popping up and fading (tap flourishes).
func icon_pop(pos: Vector2, icon: int) -> void:
	var b := bubble(pos, [icon], 1.1)
	b.scale = Vector2(0.75, 0.75)

# The fox's speech: a bubble holding one or two picture icons, no words.
func bubble(pos: Vector2, icons: Array, dur: float) -> Node2D:
	var n := Node2D.new()
	n.position = pos.round()
	add_child(n)
	var bg := Art.sprite("bubble")
	bg.centered = false
	bg.position = Vector2(-2, -18)
	n.add_child(bg)
	for i in icons.size():
		var ic := Art.sprite("icons", 7, icons[i])
		ic.centered = false
		var w := icons.size() * 8
		ic.position = bg.position + Vector2(10 - w / 2 + i * 8, 3)
		n.add_child(ic)
	n.scale = Vector2(0.2, 0.2)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.2, dur - 0.4))
	tw.tween_property(n, "modulate:a", 0.0, 0.2)
	tw.tween_callback(n.queue_free)
	return n
