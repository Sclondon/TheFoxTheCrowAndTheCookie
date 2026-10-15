class_name Hud
extends CanvasLayer
# Title card (Tap to play, choice of song source), scene captions, a status
# note, the off-screen arrow, the "press play" prompt and the ending card.
# Controls never take input themselves: main.gd passes every tap to tap(),
# which says what was hit. That way touch, mouse and dropped-finger taps all
# go down the same path.

const CREAM := Color("#f6eedd")
const INK := Color("#321e2f")
const WOOD := Color("#452c32")
const GOLD := Color("#ca8c40")

var ui_scale := 1.0
var root: Control
var title_box: Control
var wait_box: Control
var end_box: Control
var dim: ColorRect
var caption: Label
var note: Label
var hint: Label
var paused: Label
var arrow_l: TextureRect
var arrow_r: TextureRect
var play_btn: Button
var spotify_btn: Button
var youtube_btn: Button
var silent_btn: Button
var again_btn: Button
var source_row: Control
var title_note: Label
var _cap_tw: Tween
var _t := 0.0
var _serif: Font
var _sans: Font
var _sans_bold: Font

func _ready() -> void:
	layer = 10
	_serif = load("res://fonts/Cinzel.ttf")
	_sans = load("res://fonts/AlegreyaSans-Regular.ttf")
	_sans_bold = load("res://fonts/AlegreyaSans-Bold.ttf")
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	dim = ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.08, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	caption = _label("", _serif, 19, CREAM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.modulate.a = 0.0
	root.add_child(caption)
	note = _label("", _sans, 13, CREAM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	note.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	hint = _label("Drag to look around. Tap anything.", _sans_bold, 14, CREAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate.a = 0.0
	root.add_child(hint)
	paused = _label("Paused", _serif, 16, CREAM)
	paused.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused.visible = false
	root.add_child(paused)
	arrow_l = _arrow(true)
	arrow_r = _arrow(false)

	# title card
	title_box = VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 6)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_box)
	var t := _label("The Fox, The Crow,\nand The Cookie", _serif, 30, CREAM)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(t)
	var sub := _label("an interactive music video for the song by mewithoutYou", _sans, 15, CREAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(sub)
	title_box.add_child(_gap(8))
	play_btn = _button("Tap to play", 24, Vector2(210, 58))
	title_box.add_child(_center(play_btn))
	title_box.add_child(_gap(4))
	source_row = HBoxContainer.new()
	source_row.alignment = BoxContainer.ALIGNMENT_CENTER
	source_row.add_theme_constant_override("separation", 8)
	source_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := _label("Song from", _sans, 14, CREAM)
	source_row.add_child(lab)
	spotify_btn = _button("Spotify", 14, Vector2(84, 32))
	youtube_btn = _button("YouTube", 14, Vector2(84, 32))
	source_row.add_child(spotify_btn)
	source_row.add_child(youtube_btn)
	title_box.add_child(source_row)
	title_note = _label("", _sans, 13, CREAM)
	title_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(title_note)
	var tip := _label("Drag to look around the wood, and tap anything.", _sans, 13, Color(CREAM, 0.8))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(tip)

	# waiting for the music to start
	wait_box = VBoxContainer.new()
	wait_box.add_theme_constant_override("separation", 6)
	wait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wl := _label("If the song hasn't started, press play on the player in the corner.", _sans_bold, 15, CREAM)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wait_box.add_child(wl)
	silent_btn = _button("Watch without the song", 15, Vector2(200, 38))
	wait_box.add_child(_center(silent_btn))
	wait_box.visible = false
	root.add_child(wait_box)

	# the ending card
	end_box = VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 8)
	end_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var et := _label("The Fox, The Crow,\nand The Cookie", _serif, 26, CREAM)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_box.add_child(et)
	for line in [
		"An interactive music video for mewithoutYou's song, from It's All Crazy! It's All False! It's All a Dream! It's Alright (2009).",
		"The story is the old fable of the fox and the crow, as retold by Bawa Muhaiyaddeen.",
		"The crow is from Hemlock's Tower.",
	]:
		var l := _label(line, _sans, 14, CREAM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		end_box.add_child(l)
	end_box.add_child(_gap(6))
	again_btn = _button("Watch again", 22, Vector2(200, 54))
	end_box.add_child(_center(again_btn))
	end_box.visible = false
	root.add_child(end_box)
	show_title(true)

func _label(text: String, font: Font, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 6)
	return l

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc

func _button(text: String, size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.add_theme_font_override("font", _sans_bold)
	b.add_theme_font_size_override("font_size", size)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = GOLD
		sb.border_color = WOOD
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 4
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, INK)
	return b

func _arrow(left: bool) -> TextureRect:
	var a := TextureRect.new()
	a.texture = Art.tex("arrow")
	a.flip_h = left
	a.stretch_mode = TextureRect.STRETCH_SCALE
	a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.visible = false
	root.add_child(a)
	return a

func _select(b: Button, on: bool) -> void:
	var sb: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
	sb.bg_color = GOLD if on else Color("#7a5048")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", INK if on else CREAM)

# ---- layout --------------------------------------------------------------

func layout(screen: Vector2) -> void:
	ui_scale = clampf(minf(screen.x, screen.y) / 380.0, 1.0, 4.0)
	root.scale = Vector2(ui_scale, ui_scale)
	var sz := screen / ui_scale
	root.size = sz
	dim.size = sz
	var w := minf(sz.x - 32.0, 460.0)
	for box in [title_box, end_box]:
		box.size = Vector2(w, 0)
		box.reset_size()
		box.size.x = w
		box.position = Vector2((sz.x - w) * 0.5, maxf(12.0, (sz.y - box.get_combined_minimum_size().y) * 0.42))
	wait_box.size = Vector2(w, 0)
	wait_box.reset_size()
	wait_box.size.x = w
	wait_box.position = Vector2((sz.x - w) * 0.5, sz.y * 0.3)
	caption.size = Vector2(sz.x - 32.0, 0)
	caption.position = Vector2(16, 14)
	hint.size = Vector2(sz.x - 32.0, 0)
	hint.position = Vector2(16, 48)
	paused.size = Vector2(sz.x, 0)
	paused.position = Vector2(0, sz.y * 0.42)
	# bottom-right, clear of the music player in the bottom-left corner
	note.size = Vector2(minf(sz.x * 0.45, 230.0), 0)
	note.position = Vector2(sz.x - note.size.x - 10.0, sz.y - 10.0 - note.get_combined_minimum_size().y)
	var asz := Vector2(22, 26)
	for a in [arrow_l, arrow_r]:
		a.size = asz
	arrow_l.position = Vector2(8, sz.y * 0.45)
	arrow_r.position = Vector2(sz.x - 8 - asz.x, sz.y * 0.45)

# ---- state ----------------------------------------------------------------

func show_title(v: bool) -> void:
	title_box.visible = v
	_update_dim()

func show_wait(v: bool) -> void:
	wait_box.visible = v

func show_end(v: bool) -> void:
	end_box.visible = v
	_update_dim()

func _update_dim() -> void:
	dim.visible = title_box.visible or end_box.visible

func set_web(is_web: bool, source_id: String) -> void:
	source_row.visible = is_web
	_select(spotify_btn, source_id == "spotify")
	_select(youtube_btn, source_id == "youtube")

func set_title_note(text: String) -> void:
	title_note.text = text
	title_note.visible = text != ""

func set_caption(text: String) -> void:
	if text == "":
		return
	caption.text = text
	if _cap_tw and _cap_tw.is_valid():
		_cap_tw.kill()
	_cap_tw = create_tween()
	_cap_tw.tween_property(caption, "modulate:a", 1.0, 0.6)
	_cap_tw.tween_interval(3.5)
	_cap_tw.tween_property(caption, "modulate:a", 0.0, 1.0)

func set_note(text: String) -> void:
	note.text = text
	note.position.y = root.size.y - 10.0 - note.get_combined_minimum_size().y

func flash_hint() -> void:
	var tw := create_tween()
	tw.tween_interval(4.5)
	tw.tween_property(hint, "modulate:a", 1.0, 0.5)
	tw.tween_interval(5.0)
	tw.tween_property(hint, "modulate:a", 0.0, 1.0)

func set_paused(v: bool) -> void:
	paused.visible = v

# side: -1 left, 1 right, 0 none
func set_arrow(side: int) -> void:
	arrow_l.visible = side < 0
	arrow_r.visible = side > 0

func _process(delta: float) -> void:
	_t += delta
	var bob := sin(_t * 5.0) * 3.0
	arrow_l.position.x = 8 + bob
	arrow_r.position.x = root.size.x - 8 - arrow_r.size.x - bob

# ---- taps -----------------------------------------------------------------

func _hit(c: Control, pos: Vector2, pad: float = 6.0) -> bool:
	return c.is_visible_in_tree() and c.get_global_rect().grow(pad * ui_scale).has_point(pos)

# What a tap at window position pos hits: an action name, "block" when an
# overlay swallows it, or "" when it should go on to the wood.
func tap(pos: Vector2) -> String:
	if end_box.visible:
		return "again" if _hit(again_btn, pos) else "block"
	if title_box.visible:
		if _hit(play_btn, pos, 10.0):
			return "play"
		if _hit(spotify_btn, pos):
			return "src_spotify"
		if _hit(youtube_btn, pos):
			return "src_youtube"
		return "block"
	if wait_box.visible and _hit(silent_btn, pos):
		return "silent"
	if _hit(arrow_l, pos, 14.0) or _hit(arrow_r, pos, 14.0):
		return "arrow"
	return ""
