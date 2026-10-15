extends RefCounted
# Scenery, props, effects and UI bits, drawn to STYLE_GUIDE.md.
# Called from tools/gen_art.gd.

const Pix := preload("res://tools/pix.gd")

# Ramps are [outline, dark, mid, light] unless noted.
const WOOD := ["#321e2f", "#452c32", "#5a3a3a", "#7a5048"]
const THATCH := ["#321e2f", "#88361c", "#ca8c40", "#deb04f"]
const BRICK := ["#1a3a48", "#295553", "#4c705f", "#6b8f68"]
const BRICK_HI := "#84a17a"
const LEAF_GREEN := ["#19391a", "#21533f", "#376854", "#4b7d5a"]
const LEAF_RED := ["#321e2f", "#88361c", "#b8601e", "#ca8c40"]
const LEAF_GOLD := ["#88361c", "#b8601e", "#ca8c40", "#deb04f"]
const STONE := ["#25232b", "#3e3b46", "#5e5a66", "#7a7584"]
const WATER := ["#1a3a48", "#295553", "#3c5e58", "#6b8f68"]
const CAP := ["#4a1a1a", "#7a1919", "#a02727", "#d04a3a"]
const CREAM := ["#321e2f", "#bca98b", "#eadcbf", "#f6eedd"]
const DIRT := ["#3a2230", "#55303d", "#673f4d", "#7d506c"]
const GLOW := "#ffe08a"
const GLOW_HI := "#fff4d0"

static func generate(out: String) -> void:
	cottage(out)
	bell(out)
	bushes(out)
	small_props(out)
	pond(out)
	den(out)
	lantern(out)
	ground(out)
	backdrop(out)
	effects(out)
	ui(out)
	icon(out)

# ---- cottage (the bakery at the wood's edge) ---------------------------
static func _cottage(lit: bool) -> Object:
	var p = Pix.new(96, 80)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# chimney (behind the roof)
	var ch = p.mask().rect(66, 2, 9, 26)
	p.shade(ch, BRICK)
	p.rect(65, 1, 11, 2, BRICK[0])
	for y in range(5, 26, 4):
		p.line(67, y, 73, y, BRICK[1])
	# walls: brick courses 4px tall, 8px bricks, staggered
	var wall = p.mask().rect(10, 34, 77, 46)
	p.fill(wall, BRICK[1])
	for row in 12:
		var y0 := 34 + row * 4
		var off := 0 if row % 2 == 0 else 4
		for bx in range(-1, 11):
			var x0 := 10 + bx * 8 + off
			var tone: String = BRICK[2] if rng.randf() > 0.2 else "#40635a"
			for yy in range(y0, y0 + 3):
				for xx in range(x0, x0 + 7):
					if xx >= 10 and xx < 87 and yy < 80:
						p.px(xx, yy, tone)
			if x0 >= 10 and x0 < 87:
				p.px(x0, y0, BRICK[3])
				if rng.randf() > 0.7:
					p.px(x0 + 1, y0, BRICK_HI)
	# shade under the eaves and at the foot
	p.rect(10, 34, 77, 2, BRICK[0])
	p.rect(10, 78, 77, 2, BRICK[0])
	# timber corner posts
	p.rect(10, 34, 2, 46, WOOD[1])
	p.rect(85, 34, 2, 46, WOOD[1])
	p.rect(10, 34, 1, 46, WOOD[0])
	p.rect(86, 34, 1, 46, WOOD[0])
	# roof: thatch trapezoid with a ragged eave
	var roof = p.mask().poly(PackedVector2Array([
		Vector2(1, 39), Vector2(95, 39), Vector2(70, 8), Vector2(26, 8)]))
	p.shade(roof, THATCH)
	for y in range(12, 38, 4):
		for x in 96:
			if roof.has(x, y) and roof.has(x, y - 1) and rng.randf() > 0.25:
				p.px(x, y, THATCH[1])
	for x in range(2, 95):
		if x % 3 != 0:
			p.px(x, 39, THATCH[0])
		if x % 3 == 1:
			p.px(x, 40, THATCH[1])
	p.line(26, 8, 70, 8, THATCH[0])
	p.line(27, 7, 69, 7, THATCH[1])
	# door with an arched top
	var door = p.mask().rect(60, 54, 14, 26)
	door.add(p.mask().ellipse(67, 55, 7, 4))
	p.shade(door, WOOD)
	for x in [63, 67, 71]:
		p.line(x, 54, x, 79, WOOD[0])
	p.px(71, 67, THATCH[3])
	p.px(72, 67, THATCH[2])
	# window: frame, four panes, and a sill for the tray
	p.rect(20, 44, 24, 18, WOOD[1])
	p.rect(20, 44, 24, 1, WOOD[3])
	var glass_a: String = GLOW if lit else "#1b1f34"
	var glass_b: String = GLOW_HI if lit else "#414247"
	for i in 4:
		var gx := 22 + (i % 2) * 11
		var gy := 46 + (i / 2) * 7
		p.rect(gx, gy, 9, 6, glass_a)
		if lit:
			p.rect(gx, gy, 3, 2, glass_b)
		else:
			p.px(gx + 1, gy + 1, glass_b)
			p.px(gx + 2, gy + 1, glass_b)
	# shutters
	for sx in [16, 44]:
		p.rect(sx, 44, 4, 18, THATCH[1])
		p.line(sx, 44, sx, 61, THATCH[0])
		p.line(sx + 1, 48, sx + 2, 48, THATCH[0])
		p.line(sx + 1, 56, sx + 2, 56, THATCH[0])
	# sill
	p.rect(18, 62, 28, 3, WOOD[2])
	p.rect(18, 62, 28, 1, WOOD[3])
	p.rect(18, 64, 28, 1, WOOD[0])
	# little hanging sign: a cookie on a board
	p.rect(48, 41, 9, 7, WOOD[2])
	p.rect(48, 41, 9, 1, WOOD[3])
	p.rect(48, 47, 9, 1, WOOD[0])
	p.grid([".oo.", "omlo", "okmo", ".oo."], {"o": "#88361c", "m": "#ca8c40", "l": "#deb04f", "k": "#321e2f"}, 50, 42)
	return p

static func cottage(out: String) -> void:
	Pix.strip([_cottage(false), _cottage(true)]).save_png(out + "/cottage.png")
	# a cooling tray for the sill
	var t = Pix.new(18, 3)
	t.rect(0, 0, 18, 2, "#7a7584")
	t.rect(0, 0, 18, 1, "#a8a3b0")
	t.rect(1, 2, 16, 1, "#3e3b46")
	t.save(out + "/tray.png")

static func bell(out: String) -> void:
	var frames := []
	for lean in [-1, 0, 1, 0]:
		var p = Pix.new(9, 12)
		p.rect(0, 0, 9, 1, WOOD[1])
		p.px(4, 1, WOOD[0])
		var m = p.mask().poly(PackedVector2Array([
			Vector2(3 + lean, 2), Vector2(6 + lean, 2), Vector2(8 + lean * 2, 9), Vector2(1 + lean * 2, 9)]))
		p.shade(m, ["#88361c", "#b8601e", "#ca8c40", "#deb04f"])
		p.px(4 + lean * 2, 10, "#452c32")
		frames.append(p)
	Pix.strip(frames).save_png(out + "/bell.png")

# ---- bushes: rest, lean left, lean right -------------------------------
static func _bush(ramp: Array, seed_i: int, lean: int, berries: bool) -> Object:
	var p = Pix.new(32, 22)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	for i in 3:
		var cx := 8.0 + i * 8.0 + lean * (1.0 + i * 0.4)
		p.clump(cx, 13.0 - (1.0 if i == 1 else 0.0), 7.0, 6.0, ramp, rng, 6)
	# ground the base with the darkest tone
	for x in 32:
		for y in range(17, 22):
			if p.is_set(x, y):
				p.px(x, y, ramp[0] if y > 19 else ramp[1])
	if berries:
		for k in 6:
			var bx := rng.randi_range(5, 26)
			var by := rng.randi_range(8, 16)
			if p.is_set(bx, by):
				p.px(bx, by, "#a02727")
	return p

static func bushes(out: String) -> void:
	for spec in [["bush_green", LEAF_GREEN, 3, true], ["bush_red", LEAF_RED, 11, false], ["bush_gold", LEAF_GOLD, 21, false]]:
		Pix.strip([
			_bush(spec[1], spec[2], 0, spec[3]),
			_bush(spec[1], spec[2], -1, spec[3]),
			_bush(spec[1], spec[2], 1, spec[3]),
		]).save_png(out + "/%s.png" % spec[0])

# ---- props: mushrooms, acorn, leaves, rock, leaf pile -------------------
static func small_props(out: String) -> void:
	var shrooms := []
	for squash in [0, 1]:
		var p = Pix.new(10, 9)
		var stem = p.mask().rect(4, 4 + squash, 3, 5 - squash)
		p.shade(stem, CREAM)
		var cap = p.mask().ellipse(5, 4 + squash, 4.6 + squash * 0.5, 3.2 - squash * 0.6)
		cap.cut(p.mask().rect(0, 5 + squash, 10, 4))
		p.shade(cap, CAP)
		p.px(3, 2 + squash, CREAM[3])
		p.px(6, 3 + squash, CREAM[3])
		p.px(7, 2 + squash, CREAM[2])
		shrooms.append(p)
	Pix.strip(shrooms).save_png(out + "/mushroom.png")
	var a = Pix.new(4, 5)
	a.grid(["kKKk", "KkkK", "mllm", "dmmd", ".dd."], {"k": "#321e2f", "K": "#452c32", "l": "#deb04f", "m": "#ca8c40", "d": "#88361c"})
	a.save(out + "/acorn.png")
	var leaves := []
	for g in [[".l.", "lmd", ".d."], ["ll.", "lmd", "..d"], [".m.", "mdo", ".o."], ["l..", ".mm", "..d"]]:
		var lp = Pix.new(3, 3)
		lp.grid(g, {"l": "#deb04f", "m": "#ca8c40", "d": "#b8601e", "o": "#88361c"})
		leaves.append(lp)
	Pix.strip(leaves).save_png(out + "/leaf.png")
	var r = Pix.new(22, 12)
	var rm = r.mask().ellipse(11, 8, 10, 6)
	rm.add(r.mask().ellipse(7, 7, 5, 5))
	rm.cut(r.mask().rect(0, 11, 22, 1))
	r.shade(rm, STONE)
	for x in range(4, 18):
		if (x * 7) % 5 == 0:
			r.px(x, 3 + (x % 3), "#376854")
	r.save(out + "/rock.png")
	var pile = Pix.new(30, 9)
	var prng := RandomNumberGenerator.new()
	prng.seed = 5
	var pm = pile.mask().ellipse(15, 9, 14, 7)
	for y in 9:
		for x in 30:
			if pm.has(x, y):
				var t := prng.randf()
				pile.px(x, y, LEAF_GOLD[3] if t < 0.25 else (LEAF_GOLD[2] if t < 0.55 else (LEAF_GOLD[1] if t < 0.85 else LEAF_GOLD[0])))
	pile.save(out + "/leafpile.png")

# ---- pond with reeds and a lily pad ------------------------------------
static func pond(out: String) -> void:
	var p = Pix.new(120, 16)
	var bank = p.mask().ellipse(60, 6, 60, 10)
	bank.cut(p.mask().rect(0, 0, 120, 2))
	p.fill(bank, DIRT[1])
	var water = p.mask().ellipse(60, 5, 56, 8.5)
	water.cut(p.mask().rect(0, 0, 120, 2))
	for y in 16:
		for x in 120:
			if water.has(x, y):
				p.px(x, y, WATER[1] if y > 7 else WATER[2])
	for y in [3, 6, 9, 12]:
		for x in range(14 + y * 2, 106 - y * 2, 9):
			if water.has(x, y) and water.has(x + 4, y):
				p.line(x, y, x + 3 + (y % 2), y, WATER[3])
	p.line(8, 2, 112, 2, DIRT[2])
	p.save(out + "/pond.png")
	var ripple := []
	for r in [2, 4, 6]:
		var rp = Pix.new(16, 6)
		var outer = rp.mask().ellipse(8, 3, r + 1.5, (r + 1.5) * 0.35)
		outer.cut(rp.mask().ellipse(8, 3, r + 0.5, (r + 0.5) * 0.35))
		rp.fill(outer, "#93b68e")
		ripple.append(rp)
	Pix.strip(ripple).save_png(out + "/ripple.png")
	var pad = Pix.new(12, 4)
	var pm = pad.mask().ellipse(6, 2, 6, 2)
	pm.cut(pad.mask().poly(PackedVector2Array([Vector2(6, 2), Vector2(12, 0), Vector2(12, 2)])))
	pad.shade(pm, LEAF_GREEN)
	pad.save(out + "/lilypad.png")
	var reeds := []
	for sway in [0, 1, 0, -1]:
		var rp = Pix.new(14, 24)
		for k in 5:
			var bx := 2 + k * 2 + (k % 2)
			var top := 4 + (k * 5) % 9
			rp.line(bx, 23, bx + sway * (1 if k % 2 == 0 else 2), top, LEAF_GREEN[2] if k % 2 == 0 else LEAF_GREEN[1])
			if k == 1 or k == 3:
				var cx: int = bx + sway * 2
				rp.rect(cx, top - 1, 2, 4, WOOD[1])
				rp.px(cx, top - 1, WOOD[3])
		reeds.append(rp)
	Pix.strip(reeds).save_png(out + "/reeds.png")

# ---- the fox's den: a hollow log over a hole under roots ----------------
static func den(out: String) -> void:
	var p = Pix.new(52, 22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	# earth mound with a dark hole
	var mound = p.mask().ellipse(30, 22, 22, 11)
	p.shade(mound, DIRT)
	var hole = p.mask().ellipse(36, 19, 7, 6)
	p.fill(hole, "#140b18")
	p.fill(p.mask().ellipse(36, 20, 5, 4), "#0c0610")
	# a log lying over it
	var lg = p.mask().capsule(Vector2(4, 9), Vector2(40, 7), 4.0)
	p.shade(lg, WOOD)
	for x in range(8, 38, 5):
		p.px(x, 6 + (x % 2), WOOD[1])
		p.px(x + 1, 6 + (x % 2), WOOD[1])
	var end = p.mask().ellipse(41, 7, 3.0, 4.0)
	p.shade(end, ["#88361c", "#b8601e", "#ca8c40", "#deb04f"])
	p.px(41, 7, "#88361c")
	# moss
	for x in range(6, 34):
		if rng.randf() > 0.45:
			p.px(x, 4 + int(rng.randf() * 1.5), LEAF_GREEN[2] if rng.randf() > 0.4 else LEAF_GREEN[3])
	# roots
	p.line(22, 13, 18, 21, WOOD[1])
	p.line(46, 15, 50, 21, WOOD[1])
	p.save(out + "/den.png")

static func lantern(out: String) -> void:
	var frames := []
	for lit in [false, true]:
		var p = Pix.new(9, 28)
		p.rect(4, 8, 1, 20, WOOD[1])
		p.rect(3, 26, 3, 2, WOOD[0])
		p.rect(1, 1, 7, 1, WOOD[0])
		p.rect(2, 0, 5, 1, WOOD[1])
		p.rect(2, 2, 5, 5, WOOD[0])
		p.rect(3, 3, 3, 3, GLOW if lit else "#1b1f34")
		if lit:
			p.px(3, 3, GLOW_HI)
		p.rect(2, 7, 5, 1, WOOD[1])
		frames.append(p)
	Pix.strip(frames).save_png(out + "/lantern.png")

# ---- ground tile: grass fringe over the Hemlock dirt --------------------
static func ground(out: String) -> void:
	var p = Pix.new(64, 48)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	p.rect(0, 6, 64, 42, DIRT[2])
	for y in range(6, 48):
		for x in 64:
			var t := rng.randf()
			if t < 0.04:
				p.px(x, y, DIRT[3])
			elif t < 0.08 + y * 0.004:
				p.px(x, y, DIRT[1])
	p.rect(0, 30, 64, 18, DIRT[1])
	for y in range(30, 48):
		for x in 64:
			if rng.randf() < 0.05:
				p.px(x, y, DIRT[0])
	# grass
	p.rect(0, 4, 64, 3, LEAF_GREEN[2])
	p.rect(0, 7, 64, 1, LEAF_GREEN[1])
	for x in 64:
		if rng.randf() > 0.35:
			p.px(x, 7 + (1 if rng.randf() > 0.6 else 0), LEAF_GREEN[1])
		var hgt := rng.randi_range(0, 3)
		for k in hgt:
			p.px(x, 3 - k, LEAF_GREEN[3] if k == hgt - 1 else LEAF_GREEN[2])
		if rng.randf() > 0.85:
			p.px(x, 4, LEAF_GOLD[2])
	p.save(out + "/ground.png")

# ---- backdrop layers (white, tinted by the sky in game) ----------------
static func backdrop(out: String) -> void:
	for spec in [["hills_far", 256, 96, [3.0, 5.0, 2.0], 0.0], ["hills_near", 256, 72, [2.0, 4.0, 7.0], 1.7]]:
		var w: int = spec[1]
		var h: int = spec[2]
		var p = Pix.new(w, h)
		for x in w:
			var t := float(x) / w * TAU
			var f: Array = spec[3]
			var top := h * 0.45 + sin(t * f[0] + spec[4]) * h * 0.18 + sin(t * f[1]) * h * 0.08 + sin(t * f[2] + 1.0) * h * 0.05
			var ti := int(top)
			for y in range(ti, h):
				p.px(x, y, "#ffffff" if y < ti + 2 else "#d8d8d8")
		p.save(out + "/%s.png" % spec[0])
	# a band of far treetops
	var tt = Pix.new(256, 48)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var x := 0.0
	while x < 256.0:
		var r := rng.randf_range(5.0, 11.0)
		var cy := rng.randf_range(14.0, 26.0)
		for yy in range(0, 48):
			for xx in range(int(x - r), int(x + r) + 1):
				var dx := xx + 0.5 - x
				var dy := yy + 0.5 - cy
				if dy > 0 or dx * dx + dy * dy <= r * r:
					tt.px(posmod(xx, 256), yy, "#ffffff" if dy < -r + 2 else "#d8d8d8")
		x += r * 1.3
	tt.save(out + "/treeline.png")
	var clouds := []
	for s in [1, 2]:
		var c = Pix.new(36, 12)
		var crng := RandomNumberGenerator.new()
		crng.seed = s * 31
		var m = c.mask()
		for k in 5:
			m.ellipse(6 + k * 6 + crng.randf_range(-1, 1), 7 - (2 if k == 2 or k == 1 + s else 0), 6, 4.5)
		m.cut(c.mask().rect(0, 11, 36, 1))
		c.shade(m, ["#c8c8d8", "#d8d8e4", "#f0f0f4", "#ffffff"], false, Vector2i(0, -2), Vector2i(0, 2))
		clouds.append(c)
	Pix.strip(clouds).save_png(out + "/cloud.png")
	var sun = Pix.new(15, 15)
	sun.fill(sun.mask().circle(7.5, 7.5, 7.2), "#fff0b0")
	sun.fill(sun.mask().circle(7.5, 7.5, 5.8), "#ffe08a")
	sun.fill(sun.mask().circle(6.5, 6.5, 2.5), "#fff8e0")
	sun.save(out + "/sun.png")
	var moon = Pix.new(13, 13)
	var mm = moon.mask().circle(6.5, 6.5, 6.2)
	moon.shade(mm, ["#a8a3b0", "#c8c4d0", "#e8e4ec", "#ffffff"], false)
	moon.px(4, 7, "#c8c4d0")
	moon.px(8, 4, "#c8c4d0")
	moon.px(8, 8, "#c8c4d0")
	moon.px(9, 8, "#c8c4d0")
	moon.save(out + "/moon.png")

# ---- small effects -----------------------------------------------------
static func effects(out: String) -> void:
	var notes := []
	for g in [
		["..ww.", "..w.w", "..w..", "..w..", "www..", "www..", ".w..."],
		[".wwww", ".w..w", ".w..w", ".w..w", "ww.ww", "ww.ww", "....."],
	]:
		var n = Pix.new(7, 9)
		n.grid(g, {"w": "#f6eedd"}, 1, 1)
		n.outline_outside("#321e2f")
		notes.append(n)
	Pix.strip(notes).save_png(out + "/note.png")
	var sparkles := []
	for g in [["..w..", ".wWw.", "..w.."], ["..w..", "..W..", "wWyWw", "..W..", "..w.."], ["w...w", ".W.W.", "..y..", ".W.W.", "w...w"]]:
		var s = Pix.new(5, 5)
		s.grid(g, {"w": "#ffe08a", "W": "#fff4d0", "y": "#ffffff"}, 0, 0 if g.size() == 5 else 1)
		sparkles.append(s)
	Pix.strip(sparkles).save_png(out + "/sparkle.png")
	var puffs := []
	for r in [1.6, 2.4, 3.0, 3.3]:
		var s = Pix.new(8, 8)
		var m = s.mask().circle(4, 4, r)
		s.shade(m, ["#8a8796", "#a8a3b0", "#c8c4d0", "#e8e4ec"], false)
		puffs.append(s)
	Pix.strip(puffs).save_png(out + "/puff.png")
	var flies := []
	for big in [false, true]:
		var f = Pix.new(5, 5)
		if big:
			f.grid([".y.", "yWy", ".y."], {"y": "#c8e88a", "W": "#fffbe0"}, 1, 1)
		else:
			f.px(2, 2, "#e8f8b0")
		flies.append(f)
	Pix.strip(flies).save_png(out + "/firefly.png")
	var stars := []
	for g in [["w"], [".w.", "wWw", ".w."]]:
		var s = Pix.new(3, 3)
		s.grid(g, {"w": "#c8c4e0", "W": "#ffffff"}, 1 if g.size() == 1 else 0, 1 if g.size() == 1 else 0)
		stars.append(s)
	Pix.strip(stars).save_png(out + "/star.png")
	var bang = Pix.new(4, 9)
	bang.grid(["ww", "ww", "ww", "ww", "..", "ww"], {"w": "#f6eedd"}, 1, 1)
	bang.outline_outside("#321e2f")
	bang.save(out + "/bang.png")

# ---- speech bubble and its icons (no words: the fox talks in pictures) ---
static func ui(out: String) -> void:
	var b = Pix.new(20, 18)
	var m = b.mask().ellipse(10, 7, 9.6, 6.8)
	m.add(b.mask().poly(PackedVector2Array([Vector2(4, 11), Vector2(9, 12), Vector2(2, 17)])))
	b.shade(m, ["#321e2f", "#bca98b", "#f6eedd", "#ffffff"], true, Vector2i(-1, -2), Vector2i(0, 2))
	b.save(out + "/bubble.png")
	var icons := []
	var pal := {
		"o": "#321e2f", "b": "#272b41", "c": "#414247", "g": "#0c1023", "y": "#deb04f", "Y": "#fff0b0",
		"m": "#ca8c40", "r": "#a02727", "R": "#d04a3a", "w": "#ffffff", "k": "#452c32",
	}
	for g in [
		# feather
		[".....gb.", "....gbcb", "...gbcb.", "..gbcb..", ".gbcb...", ".bcb....", "gb......", "g......."],
		# star (bright eyes)
		["...y....", "...y....", ".yyYyy..", "..yYy...", "..y.y...", ".y...y..", "........", "........"],
		# crown
		["........", "y..y..y.", "yy.y.yy.", "yyyryyy.", "ymmmmmy.", "yyyyyyy.", "........", "........"],
		# note
		["...ooo..", "...o.o..", "...o.o..", "...o.o..", ".ooo.o..", "oooooo..", ".oo.oo..", "........"],
		# heart
		["........", ".rr.rr..", "rRrrrrr.", "rRrrrrr.", ".rrrrr..", "..rrr...", "...r....", "........"],
		# question
		["..ooo...", ".o...o..", ".....o..", "....o...", "...o....", "........", "...o....", "........"],
		# cookie
		["..kkk...", ".kmyymk.", "kmyomyk.", "kmmmomk.", "kmomymk.", ".kmmmk..", "..kkk...", "........"],
	]:
		var ip = Pix.new(8, 8)
		ip.grid(g, pal)
		icons.append(ip)
	Pix.strip(icons).save_png(out + "/icons.png")
	var arrow = Pix.new(11, 13)
	arrow.grid([
		"oo.........",
		"owoo.......",
		"owwwoo.....",
		"owwwwwoo...",
		"owwwwwwwoo.",
		"owwwwwwwwwo",
		"owwwwwwwwwo",
		"owwwwwwwoo.",
		"owwwwwoo...",
		"owwwoo.....",
		"owoo.......",
		"oo.........",
	], {"o": "#321e2f", "w": "#f6eedd"})
	arrow.save(out + "/arrow.png")

# ---- the game's icon: the crow and her cookie at dusk -------------------
static func icon(out: String) -> void:
	var p = Pix.new(64, 64)
	var sky := ["#2a2050", "#4a3068", "#7a4a78", "#c06070", "#e8a07a"]
	for y in 64:
		var band: int = clampi(y / 13, 0, 4)
		for x in 64:
			p.px(x, y, sky[band])
	p.fill(p.mask().circle(46, 18, 7), "#fff0b0")
	# branch
	p.fill(p.mask().capsule(Vector2(0, 50), Vector2(64, 44), 3.5), WOOD[1])
	p.line(0, 47, 64, 41, WOOD[3])
	var crow := Image.load_from_file(ProjectSettings.globalize_path("res://art/hemlock/crow.png"))
	crow.convert(Image.FORMAT_RGBA8)
	var f := crow.get_region(Rect2i(0, 0, 16, 16))
	f.resize(48, 48, Image.INTERPOLATE_NEAREST)
	p.blit(f, 10, 3)
	var ck := Image.load_from_file(out + "/cookie.png")
	ck.convert(Image.FORMAT_RGBA8)
	var c6 := ck.get_region(Rect2i(0, 0, 6, 6))
	c6.resize(18, 18, Image.INTERPOLATE_NEAREST)
	p.blit(c6, 4, 15)
	var big: Image = p.img.duplicate()
	big.resize(128, 128, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://icon.png"))
