extends SceneTree
# Touch test, in a real window (headless scales touches out of place):
#
#   godot --path . --resolution 390x844 --script tests/touch_test.gd
#
# Drives the game with simulated InputEventScreenTouch / ScreenDrag (and one
# mouse click) at window positions worked out from the nodes themselves:
#   window = root.get_final_transform() * node.get_global_transform_with_canvas() * local
# Checks: Tap to play, panning by drag, a drag whose finger-down never
# arrived, a release with no press, taps on the bell, crow, fox, a bush and a
# mushroom, the off-screen arrow, the ending card and Watch again.
# Ends with PASSED or FAILED (exit code 0/1).

var main: Node
var fails: Array[String] = []

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	main.set_meta("args", {"silent": 1})
	root.add_child(main)
	_run.call_deferred()

func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails.append(what)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _win(canvas_pos: Vector2) -> Vector2:
	return root.get_final_transform() * canvas_pos

func _node_win(n: Node2D, local: Vector2 = Vector2.ZERO) -> Vector2:
	return _win(n.get_global_transform_with_canvas() * local)

func _ctrl_win(c: Control) -> Vector2:
	return _win(c.get_global_rect().get_center())

func _touch(idx: int, pos: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = pos
	e.pressed = down
	Input.parse_input_event(e)

func _drag_ev(idx: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	e.relative = rel
	e.screen_relative = rel
	Input.parse_input_event(e)

func _tap(pos: Vector2, idx: int = 0) -> void:
	_touch(idx, pos, true)
	await _frames(2)
	_touch(idx, pos, false)
	await _frames(3)

func _look_at(x: float) -> void:
	main.cam_x = x
	main._idle = 0.0
	await _frames(3)

func _run() -> void:
	await _frames(30)
	var vp_size: Vector2 = root.get_visible_rect().size
	print("window ", DisplayServer.window_get_size(), " viewport ", vp_size, " zoom ", main.zoom)

	# 1. Tap to play
	await _tap(_ctrl_win(main.hud.play_btn))
	_check(main.state == main.State.SHOW, "Tap to play starts the show")
	_check(not main.hud.title_box.visible, "the title card goes away")

	# 2. pan by dragging a finger to the left (the view moves right)
	await _look_at(300.0)
	var x0: float = main.cam_x
	var p := vp_size * 0.5
	_touch(0, _win(p), true)
	await _frames(1)
	for i in 10:
		p += Vector2(-20, 0)
		_drag_ev(0, _win(p), Vector2(-20, 0))
		main._idle = 0.0
		await _frames(1)
	_touch(0, _win(p), false)
	await _frames(2)
	var moved: float = main.cam_x - x0
	_check(moved > 150.0 / main.zoom, "dragging pans the wood (moved %.1f world px)" % moved)

	# 3. a drag whose finger-down never arrived still pans, and isn't a tap
	var taps_before: int = main.taps_handled
	x0 = main.cam_x
	p = vp_size * 0.5
	for i in 8:
		p += Vector2(20, 0)
		_drag_ev(5, _win(p), Vector2(20, 0))
		main._idle = 0.0
		await _frames(1)
	_touch(5, _win(p), false)
	await _frames(2)
	_check(main.cam_x < x0 - 100.0 / main.zoom, "a drag with no press pans (moved %.1f)" % (main.cam_x - x0))
	_check(main.taps_handled == taps_before, "that drag didn't count as a tap")

	# 4. tap the bell by the cottage door
	var bell: Sprite2D = null
	for t in main.world.taps:
		if t["name"] == "bell":
			bell = t["node"]
	await _look_at(bell.global_position.x)
	await _tap(_node_win(bell, Vector2(4.5, 6)))
	_check(main.last_tap_name == "bell", "tapping the bell rings it (hit: %s)" % main.last_tap_name)

	# 5. a release with no press counts as a tap (some iPhones drop the press)
	var bush: Sprite2D = null
	for t in main.world.taps:
		if t["name"] == "bush":
			bush = t["node"]
			break
	await _look_at(bush.global_position.x + 16)
	_touch(7, _node_win(bush, Vector2(16, 11)), false)
	await _frames(3)
	_check(main.last_tap_name == "bush", "a lone release taps the bush (hit: %s)" % main.last_tap_name)

	# 6. tap the crow
	await _look_at(main.crow.global_position.x)
	await _tap(_node_win(main.crow, Vector2(0, -7)))
	_check(main.last_tap_name == "crow", "tapping the crow (hit: %s)" % main.last_tap_name)

	# 7. later, tap the fox under the tree
	(main.source as SilentSource).t = 100.0
	await _frames(5)
	await _look_at(main.fox.global_position.x)
	await _tap(_node_win(main.fox, Vector2(0, -10)))
	_check(main.last_tap_name == "fox", "tapping the fox (hit: %s)" % main.last_tap_name)

	# 8. a mouse click works too (desktop)
	var shroom: Sprite2D = null
	for t in main.world.taps:
		if t["name"] == "mushroom":
			shroom = t["node"]
			break
	await _look_at(shroom.global_position.x)
	var mp := _node_win(shroom, Vector2(5, 5))
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.position = mp
	mb.pressed = true
	Input.parse_input_event(mb)
	await _frames(2)
	var mr := mb.duplicate()
	mr.pressed = false
	Input.parse_input_event(mr)
	await _frames(3)
	_check(main.last_tap_name == "mushroom", "a mouse click taps a mushroom (hit: %s)" % main.last_tap_name)

	# 9. pan far away: an arrow points back to the action; tapping it goes there
	await _look_at(40.0)
	await _frames(3)
	_check(main.hud.arrow_r.visible, "an arrow points to the action off to the right")
	await _tap(_ctrl_win(main.hud.arrow_r))
	await _frames(3)
	var fx: float = main.director.focus_point().x
	_check(absf(main.cam_x - fx) < 60.0, "tapping the arrow goes to the action (cam %.0f, focus %.0f)" % [main.cam_x, fx])

	# 10. the end, and Watch again
	(main.source as SilentSource).t = 212.0
	await _frames(5)
	_check(main.state == main.State.END and main.hud.end_box.visible, "the ending card shows")
	await _tap(_ctrl_win(main.hud.again_btn))
	await _frames(3)
	_check(main.state == main.State.SHOW and main.show_t < 5.0, "Watch again starts over (t=%.1f)" % main.show_t)

	if fails.is_empty():
		print("TOUCH TEST PASSED")
		quit(0)
	else:
		print("TOUCH TEST FAILED (%d)" % fails.size())
		quit(1)
