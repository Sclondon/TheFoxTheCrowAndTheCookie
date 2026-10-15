extends RefCounted
# A tiny pixel painter for the art generator (tools/gen_art.gd).
#
# A Pix is one canvas. Draw on it with grids (rows of characters looked up in
# a palette), plain pixels/rects/lines, or shaded shapes. A shaded shape is a
# mask (circles, ellipses, polygons, thick lines) painted with a 4-tone ramp
# [outline, dark, mid, light] the way the Hemlock's Tower sprites are shaded:
# the silhouette edge takes the material's own darkest tone (no black line),
# surfaces facing up-left take the light tone, surfaces facing down-right the
# dark tone, and the rest the mid tone. See STYLE_GUIDE.md.

var w: int
var h: int
var img: Image

func _init(width: int, height: int) -> void:
	w = width
	h = height
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

static func c(hex: String) -> Color:
	return Color.html(hex)

func px(x: int, y: int, col) -> void:
	if x < 0 or y < 0 or x >= w or y >= h or col == null:
		return
	if col is String:
		col = Color.html(col)
	img.set_pixel(x, y, col)

func get_px(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)

func is_set(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.05

func rect(x: int, y: int, rw: int, rh: int, col) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, col)

func line(x0: int, y0: int, x1: int, y1: int, col) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		px(x0, y0, col)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

# Rows of characters; '.' and ' ' are transparent. pal maps char -> hex.
func grid(rows: Array, pal: Dictionary, ox: int = 0, oy: int = 0, flip: bool = false) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == "." or ch == " ":
				continue
			if not pal.has(ch):
				push_error("pix: no colour for '%s'" % ch)
				continue
			var xx: int = (row.length() - 1 - x) if flip else x
			px(ox + xx, oy + y, pal[ch])

func blit(src: Image, ox: int, oy: int, flip: bool = false) -> void:
	for y in src.get_height():
		for x in src.get_width():
			var col := src.get_pixel(x, y)
			if col.a > 0.05:
				px(ox + ((src.get_width() - 1 - x) if flip else x), oy + y, col)

func paste(other, ox: int, oy: int, flip: bool = false) -> void:
	blit(other.img, ox, oy, flip)

# ---- masks -------------------------------------------------------------

class Mask:
	var w: int
	var h: int
	var bits: PackedByteArray
	func _init(width: int, height: int) -> void:
		w = width
		h = height
		bits.resize(w * h)
	func has(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and bits[y * w + x] == 1
	func put(x: int, y: int, on: bool = true) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			bits[y * w + x] = 1 if on else 0
	func ellipse(cx: float, cy: float, rx: float, ry: float, ang: float = 0.0) -> Mask:
		var ca := cos(ang)
		var sa := sin(ang)
		for y in h:
			for x in w:
				var dx := x + 0.5 - cx
				var dy := y + 0.5 - cy
				var u := dx * ca + dy * sa
				var v := -dx * sa + dy * ca
				if (u * u) / (rx * rx) + (v * v) / (ry * ry) <= 1.0:
					put(x, y)
		return self
	func circle(cx: float, cy: float, r: float) -> Mask:
		return ellipse(cx, cy, r, r)
	func poly(pts: PackedVector2Array) -> Mask:
		for y in h:
			for x in w:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
					put(x, y)
		return self
	func capsule(a: Vector2, b: Vector2, r: float) -> Mask:
		for y in h:
			for x in w:
				var p := Vector2(x + 0.5, y + 0.5)
				var q := Geometry2D.get_closest_point_to_segment(p, a, b)
				if p.distance_to(q) <= r:
					put(x, y)
		return self
	func rect(x0: int, y0: int, rw: int, rh: int) -> Mask:
		for y in range(y0, y0 + rh):
			for x in range(x0, x0 + rw):
				put(x, y)
		return self
	func cut(other: Mask) -> Mask:
		for i in bits.size():
			if other.bits[i] == 1:
				bits[i] = 0
		return self
	func add(other: Mask) -> Mask:
		for i in bits.size():
			if other.bits[i] == 1:
				bits[i] = 1
		return self

func mask() -> Mask:
	return Mask.new(w, h)

# Paint a mask with ramp [outline, dark, mid, light] (hex strings; outline may
# be null to use dark). light_off is how far up-left a pixel looks to decide
# it is a lit surface; dark_off how far down-right for shade.
func shade(m: Mask, ramp: Array, outline: bool = true, light_off := Vector2i(-1, -2), dark_off := Vector2i(1, 2)) -> void:
	var o = ramp[0] if ramp[0] != null else ramp[1]
	for y in h:
		for x in w:
			if not m.has(x, y):
				continue
			var edge := not (m.has(x - 1, y) and m.has(x + 1, y) and m.has(x, y - 1) and m.has(x, y + 1))
			var col
			if outline and edge:
				col = o
			elif not m.has(x + dark_off.x, y + dark_off.y) or not m.has(x, y + dark_off.y):
				col = ramp[1]
			elif not m.has(x + light_off.x, y + light_off.y) or not m.has(x, y + light_off.y):
				col = ramp[3]
			else:
				col = ramp[2]
			px(x, y, col)

# Fill a mask with one colour.
func fill(m: Mask, col) -> void:
	for y in h:
		for x in w:
			if m.has(x, y):
				px(x, y, col)

# Foliage clump in the Hemlock tree manner: overlapping round blobs, each
# lit top-left and shaded bottom, with ragged single pixels round the rim.
func clump(cx: float, cy: float, rx: float, ry: float, ramp: Array, rng: RandomNumberGenerator, blobs: int = 7) -> void:
	for i in blobs:
		var a := rng.randf() * TAU
		var d := rng.randf() * 0.65
		var bx := cx + cos(a) * rx * d
		var by := cy + sin(a) * ry * d
		var r := lerpf(minf(rx, ry) * 0.45, minf(rx, ry) * 0.8, rng.randf())
		for y in range(int(by - r) - 1, int(by + r) + 2):
			for x in range(int(bx - r) - 1, int(bx + r) + 2):
				var dx := x + 0.5 - bx
				var dy := y + 0.5 - by
				if dx * dx + dy * dy > r * r:
					continue
				var t := (dx * 0.6 + dy) / r + rng.randf_range(-0.25, 0.25)
				var col = ramp[2]
				if t < -0.35:
					col = ramp[3]
				elif t > 0.55:
					col = ramp[1]
				px(x, y, col)
		# stray pixels round the blob, like the tree's leaf edges
		for k in int(r):
			var aa := rng.randf() * TAU
			var rr := r + rng.randf_range(0.5, 1.8)
			px(int(bx + cos(aa) * rr), int(by + sin(aa) * rr), ramp[3] if sin(aa) < 0 else ramp[2])

# Ring everything drawn so far with a 1px outline on the outside (4-way).
func outline_outside(col) -> void:
	var src: Image = img.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.05:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.05:
					px(x, y, col)
					break

func save(path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("pix: could not save %s (%d)" % [path, err])

# Join frames left to right into a strip.
static func strip(frames: Array) -> Image:
	var fw: int = frames[0].w
	var fh: int = frames[0].h
	var out := Image.create(fw * frames.size(), fh, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for i in frames.size():
		out.blit_rect(frames[i].img, Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return out
