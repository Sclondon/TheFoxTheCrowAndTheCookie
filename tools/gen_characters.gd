extends RefCounted
# Characters: the crow's extra poses (to match the Hemlock's Tower crow),
# the fox, the cookie, the small birds and the frog's hop.
# Called from tools/gen_art.gd.

const Pix := preload("res://tools/pix.gd")

# ---- the crow -----------------------------------------------------------
# Palette taken pixel for pixel from Hemlock's Tower images/crow.png.
const CROW := {
	"a": "#7a1919", # brow (dark red)
	"b": "#272b41", # body mid
	"c": "#414247", # beak light
	"d": "#35363c", # beak mid
	"e": "#a02727", # eye
	"f": "#212430", # beak shade
	"g": "#0c1023", # darkest navy: edges, tail, legs
	"h": "#1b1f34", # body dark
	"x": "#e8dcbf", # (not in the crow: cookie crumb glint, unused here)
}

# Body rows 6..13 of the Hemlock idle frame 0 (facing left).
const BODY := [
	"...ghbhbhhbgghhh",
	"...hhhbhbbhgggh.",
	"...hhbbbbhbhgggg",
	"...hhhbbbbhbhgg.",
	"....ggggbbbhbh..",
	".....bbbgggg....",
	"......h.h.......",
	".....hh.hh......",
]

static func _crow(head: Array, body: Array = BODY, body_y: int = 6) -> Object:
	var p = Pix.new(16, 16)
	p.grid(body, CROW, 0, body_y)
	p.grid(head, CROW, 0, 0)
	return p

static func crow_strips(out: String) -> void:
	# preen: head turns back over the shoulder and dips into the wing
	var preen := [
		_crow([
			"", "", "",
			"......abbb......",
			".....bbebbdc....",
			"....hbbbbbbf..h.",
		]),
		_crow([
			"", "", "", "",
			"......abbb......",
			".....hbebbdcg.h.",
		]),
		_crow([
			"", "", "", "",
			"......abbb...h..",
			".....hbhbbdcg.h.",
		]),
		_crow([
			"", "", "",
			"......abbb......",
			".....bbebbdc....",
			"....hbbbbbbf..h.",
		]),
	]
	Pix.strip(preen).save_png(out + "/crow_preen.png")

	# sing: head up, beak open (two widths)
	var sing := [
		_crow([
			"",
			"..c.............",
			"...dabbb........",
			".....bebb.......",
			"...fgbbbb.......",
			"....bbbbbg..g.h.",
		]),
		_crow([
			".c..............",
			"..dabbb.........",
			"....bbebb.......",
			"................",
			"..fgbbbbb.......",
			"....bbbbbg..g.h.",
		]),
	]
	# frame 1: fill the throat under the open beak
	sing[1].grid(["....bbbb........"], CROW, 0, 3)
	Pix.strip(sing).save_png(out + "/crow_sing.png")

	# startled: head up a pixel, feathers puffed, wings flicked out
	var st_body := [
		"..gghbhbhhbgghhh",
		"..hhhhbhbbhgggh.",
		"..hhhbbbbhbhgggg",
		"..hhhhbbbbhbhgg.",
		"...hggggbbbhbh..",
		".....bbbgggg....",
		"......h.h.......",
		".....hh.hh......",
	]
	var startle := [
		_crow([
			"",
			"....abbb........",
			"...cdbebb.......",
			"...fgbbbb.......",
			"....bbbbb.......",
			"...hbbbbbg.g.h.h",
		], st_body),
		_crow([
			"....a...........",
			"....abbb........",
			"...cdbebb.......",
			"...fgbbbb..g....",
			".h..bbbbb...h...",
			"...hbbbbbg.g.h.h",
		], st_body),
	]
	Pix.strip(startle).save_png(out + "/crow_startle.png")

	# droop: head low, eye dulled (second frame blinks)
	var droop_body := [
		"...hhbbbbhbhgggg",
		"...hhhbbbbhbhgg.",
		"....ggggbbbhbh..",
		".....bbbgggg....",
		"......h.h.......",
		".....hh.hh......",
	]
	var droop := [
		_crow([
			"", "", "", "", "",
			".....abbb.......",
			"....cdbabbbg..h.",
			"....fgbbbbhggghh",
		], droop_body, 8),
		_crow([
			"", "", "", "", "",
			".....abbb.......",
			"....cdbhbbbg..h.",
			"....fgbbbbhggghh",
		], droop_body, 8),
	]
	Pix.strip(droop).save_png(out + "/crow_droop.png")

	# peck: tipping forward to the ground and back
	var peck_body_a := [
		"....hbbhhbgghhhh",
		"...bbbhbbhgggh..",
		"..hbbbbbhbhgggg.",
		"..hhbbbbbhbhgg..",
		"....ggggbbbhbh..",
		".....bbbgggg....",
		"......h.h.......",
		".....hh.hh......",
	]
	var peck := [
		_crow([
			"", "", "", "",
			"................",
			".........g..g.h.",
		], peck_body_a),
		_crow([], peck_body_a),
	]
	peck[0].grid([
		"..abbb..........",
		".cdbebb.........",
		".fgbbbb.........",
	], CROW, 0, 6)
	peck[1].grid([
		"..abbb..........",
		"..dbebb.........",
		".cfgbbb.........",
		".g..............",
	], CROW, 0, 9)
	Pix.strip(peck).save_png(out + "/crow_peck.png")

	# sleep: head tucked into the back, eye shut
	var sleep := [
		_crow([
			"", "", "", "",
			"......bbbb......",
			".....bbhhbbg..h.",
		]),
		_crow([
			"", "", "", "",
			"................",
			".....bbbbbbg..h.",
		]),
	]
	sleep[1].grid([".....bbhhbb....."], CROW, 0, 6)
	Pix.strip(sleep).save_png(out + "/crow_sleep.png")

# ---- the fox ------------------------------------------------------------
# Built to the guide: hue outline (the tree's shadow brown), 4-tone orange
# ramp shared with the autumn tree, cream bib, dark socks, 1px eye.
const FOX_RAMP := ["#321e2f", "#88361c", "#b8601e", "#d47a32"]
const CREAM_RAMP := ["#321e2f", "#bca98b", "#eadcbf", "#f6eedd"]
const SOCK_RAMP := ["#321e2f", "#321e2f", "#452c32", "#5a3a3a"]
const FOXP := {
	"O": "#321e2f", "D": "#88361c", "M": "#b8601e", "L": "#d47a32",
	"C": "#eadcbf", "c": "#bca98b", "K": "#452c32", "E": "#0c1023",
	"W": "#f6eedd",
}

# Heads, all facing right. Each is placed with its top-left at a given spot.
const HEAD_FWD := [
	".O..O.......",
	"OKOOKO......",
	"OMKMMO......",
	"OMLLLMO.....",
	"OLLELLMOO...",
	"OLLLLLLLMOO.",
	".OCCCLLLLLLE",
	"..OCCCCOOOO.",
	"...OOOO.....",
]
const HEAD_DOWN := [ # sniffing: snout to the ground
	".O..O.......",
	"OKOOKO......",
	"OMKMMO......",
	"OMLLLMOO....",
	"OLLELLLMOO..",
	".OCCLLLLLMO.",
	"..OCCCLLLLLO",
	"...OOOOOOOOE",
]
const HEAD_UP := [ # looking up-right
	".......OE...",
	"......OLLO..",
	"..O..OLLMO..",
	".OKOOLLLO...",
	".OKMLELMO...",
	".OMLLLLLO...",
	".OCCCLMO....",
	"..OCCCO.....",
	"...OOO......",
]
const HEAD_UP_TALK := [ # looking up, mouth open
	"........OE..",
	".......OLO..",
	"..O..OLLO...",
	".OKOOLLO.O..",
	".OKMLELOCO..",
	".OMLLLLCCO..",
	".OCCCLCCO...",
	"..OCCCCO....",
	"...OOOO.....",
]
const HEAD_SMILE := [ # eyes shut, pleased (flattery)
	".O..O.......",
	"OKOOKO......",
	"OMKMMO......",
	"OMLLLMO.....",
	"OLLDDLMOO...",
	"OLLLLLLLMOO.",
	".OCCCLLLLLLE",
	"..OCCCCDOOO.",
	"...OOOO.....",
]
const HEAD_TALK := [ # forward, mouth open
	".O..O.......",
	"OKOOKO......",
	"OMKMMO......",
	"OMLLLMO.....",
	"OLLELLMOO...",
	"OLLLLLLLMOOE",
	".OCCCLLOOO..",
	"..OCCCCCCO..",
	"...OOOOOO...",
]

static func _fox_tail(p, a: Vector2, b: Vector2, r: float) -> void:
	var m = p.mask().capsule(a, b, r)
	var mid = (a + b) * 0.5
	m.ellipse(mid.x, mid.y, a.distance_to(b) * 0.5 + 0.5, r + 1.0, a.angle_to_point(b))
	p.shade(m, FOX_RAMP)
	# cream tip at the a end
	var tip = p.mask().circle(a.x, a.y, r + 0.6)
	tip.bits = _and(tip.bits, m.bits)
	p.shade(tip, CREAM_RAMP)

static func _and(x: PackedByteArray, y: PackedByteArray) -> PackedByteArray:
	var o := PackedByteArray()
	o.resize(x.size())
	for i in x.size():
		o[i] = 1 if x[i] == 1 and y[i] == 1 else 0
	return o

const FAR_RAMP := ["#321e2f", "#5e2416", "#88361c", "#9a4620"]

# far: the leg on the far side, a tone darker
static func _leg(p, hip: Vector2, foot: Vector2, far: bool) -> void:
	var m = p.mask().capsule(hip, foot, 0.95)
	p.shade(m, FAR_RAMP if far else FOX_RAMP, false)
	var sock = p.mask().capsule(foot + Vector2(0, -1.6), foot, 0.95)
	p.fill(sock, FOXP["K"])
	p.px(int(foot.x) + 1, int(foot.y), FOXP["O"])

static func _fox_trot(phase: int, head: Array, head_dy: int = 0) -> Object:
	var p = Pix.new(32, 24)
	var swing := [-2, -1, 1, 2, 1, -1]
	var lift := [0, 1, 1, 0, 0, 0]
	var s: int = swing[phase]
	var s2: int = swing[(phase + 3) % 6]
	var bob: int = 1 if phase % 3 == 1 else 0
	# far legs first (darker, drawn under the body)
	_leg(p, Vector2(11, 14 + bob), Vector2(11 - s2, 21 - lift[(phase + 3) % 6]), true)
	_leg(p, Vector2(21, 14 + bob), Vector2(21 + s2, 21 - lift[(phase + 3) % 6]), true)
	_fox_tail(p, Vector2(2.5, 9 + bob + (phase % 2)), Vector2(9, 11 + bob), 2.3)
	var body = p.mask().ellipse(16, 12 + bob, 7.5, 4.1)
	p.shade(body, FOX_RAMP)
	var bib = p.mask().ellipse(22.5, 14 + bob, 2.4, 2.4)
	bib.bits = _and(bib.bits, p.mask().ellipse(16, 12.5 + bob, 9.5, 4.0).bits)
	p.shade(bib, CREAM_RAMP, false)
	# near legs
	_leg(p, Vector2(13, 14 + bob), Vector2(13 + s, 22 - lift[phase]), false)
	_leg(p, Vector2(20, 14 + bob), Vector2(20 - s, 22 - lift[phase]), false)
	p.grid(head, FOXP, 20, 2 + bob + head_dy)
	return p

static func _fox_sit(head: Array, tail_up: int = 0, breathe: int = 0, head_x: int = 15) -> Object:
	var p = Pix.new(32, 24)
	# tail curled along the ground behind
	_fox_tail(p, Vector2(2.5, 20 - tail_up), Vector2(11, 21), 2.2)
	var haunch = p.mask().ellipse(12.5, 17.5, 5.5, 4.8)
	p.shade(haunch, FOX_RAMP)
	var torso = p.mask().ellipse(17.5, 13 + breathe * 0.5, 3.8, 6.8, -0.25)
	p.shade(torso, FOX_RAMP)
	var bib = p.mask().ellipse(19.6, 12.5, 2.0, 4.5, -0.2)
	bib.bits = _and(bib.bits, torso.bits)
	p.shade(bib, CREAM_RAMP, false)
	# back foot
	var foot = p.mask().ellipse(12, 22.4, 3.2, 1.3)
	p.shade(foot, SOCK_RAMP)
	_leg(p, Vector2(18.5, 15), Vector2(18.5, 22), true)
	_leg(p, Vector2(20.5, 15), Vector2(20.5, 22), false)
	p.grid(head, FOXP, head_x, 0)
	return p

static func _fox_bow(head: Array) -> Object:
	var p = Pix.new(32, 24)
	_fox_tail(p, Vector2(2.5, 3.5), Vector2(9, 10), 2.3)
	_leg(p, Vector2(10, 14), Vector2(9, 22), true)
	var body = p.mask().ellipse(15, 13, 7.5, 3.6, 0.42)
	p.shade(body, FOX_RAMP)
	_leg(p, Vector2(12, 14), Vector2(12, 22), false)
	# forelegs stretched flat along the ground
	var fl = p.mask().capsule(Vector2(19, 19), Vector2(27, 21.5), 1.1)
	p.shade(fl, FOX_RAMP)
	p.fill(p.mask().capsule(Vector2(26, 21.5), Vector2(28, 21.5), 1.0), FOXP["K"])
	p.grid(head, FOXP, 19, 11)
	return p

static func _fox_leap(head: Array, stretch: float) -> Object:
	var p = Pix.new(32, 24)
	_fox_tail(p, Vector2(1.5, 18), Vector2(9, 14), 2.2)
	_leg(p, Vector2(11, 14), Vector2(6, 20), true)
	var body = p.mask().ellipse(16, 11, 7.0 + stretch, 3.4, -0.45)
	p.shade(body, FOX_RAMP)
	_leg(p, Vector2(13, 14), Vector2(8, 21), false)
	_leg(p, Vector2(21, 8), Vector2(25, 11 - int(stretch)), false)
	p.grid(head, FOXP, 18, 0)
	return p

static func fox_strips(out: String) -> void:
	var trot := []
	for i in 6:
		trot.append(_fox_trot(i, HEAD_FWD))
	Pix.strip(trot).save_png(out + "/fox_trot.png")
	var sniff := []
	for i in 6:
		sniff.append(_fox_trot(i, HEAD_DOWN, 2))
	Pix.strip(sniff).save_png(out + "/fox_sniff.png")
	# sit: breathe and flick the tail (4 frames)
	Pix.strip([
		_fox_sit(HEAD_FWD, 0, 0), _fox_sit(HEAD_FWD, 1, 0),
		_fox_sit(HEAD_FWD, 1, 1), _fox_sit(HEAD_FWD, 0, 1),
	]).save_png(out + "/fox_sit.png")
	Pix.strip([
		_fox_sit(HEAD_UP, 0, 0, 14), _fox_sit(HEAD_UP, 1, 1, 14),
	]).save_png(out + "/fox_lookup.png")
	Pix.strip([
		_fox_sit(HEAD_UP_TALK, 0, 0, 14), _fox_sit(HEAD_UP, 1, 0, 14),
	]).save_png(out + "/fox_talk.png")
	Pix.strip([
		_fox_sit(HEAD_SMILE, 0, 0), _fox_sit(HEAD_SMILE, 1, 1),
	]).save_png(out + "/fox_smile.png")
	Pix.strip([_fox_bow(HEAD_SMILE), _fox_bow(HEAD_FWD)]).save_png(out + "/fox_bow.png")
	Pix.strip([
		_fox_sit(HEAD_UP_TALK, 0, 0, 14), _fox_leap(HEAD_UP_TALK, 0.0), _fox_leap(HEAD_UP, 1.0),
	]).save_png(out + "/fox_leap.png")
	Pix.strip([
		_fox_sit(HEAD_TALK, 0, 0), _fox_sit(HEAD_FWD, 0, 0),
	]).save_png(out + "/fox_yip.png")

# ---- the cookie ---------------------------------------------------------
const COOKIE := {
	"o": "#88361c", "d": "#b8601e", "m": "#ca8c40", "l": "#deb04f",
	"k": "#452c32", "K": "#321e2f", "w": "#fff4d0", "W": "#ffffff",
}

static func cookie_strip(out: String) -> void:
	var base := [
		".oooo.",
		"omllmo",
		"olKmdo",
		"ommkdo",
		"odkmdo",
		".oooo.",
	]
	var f0 = Pix.new(6, 6)
	f0.grid(base, COOKIE)
	var f1 = Pix.new(6, 6)
	f1.grid(base, COOKIE)
	f1.grid([".w", "wWw", ".w"], COOKIE, 0, 0)
	var f2 = Pix.new(6, 6)
	f2.grid(base, COOKIE)
	f2.px(1, 1, COOKIE["w"])
	var bitten = Pix.new(6, 6)
	bitten.grid([
		".oooo.",
		"omllo.",
		"olKo..",
		"ommo..",
		"odkmdo",
		".oooo.",
	], COOKIE)
	Pix.strip([f0, f1, f2, bitten]).save_png(out + "/cookie.png")
	# crumbs: 4 tiny 3x3 bits
	var crumbs := []
	for g in [["md", "do"], ["l.", "mo"], [".m", "dk"], ["mm", "o."]]:
		var cpix = Pix.new(3, 3)
		cpix.grid(g, COOKIE)
		crumbs.append(cpix)
	Pix.strip(crumbs).save_png(out + "/crumbs.png")

# ---- small birds (sparrows that flush from the bushes) ------------------
const SPARROW := {
	"o": "#321e2f", "b": "#674356", "m": "#8a6959", "l": "#bca98b", "e": "#0c1023", "y": "#deb04f",
}
static func sparrow_strip(out: String) -> void:
	var frames := []
	for g in [
		["........", "..oo....", ".omeo.o.", "ylmmmmo.", ".olmmo..", "..o.o...", "........", "........"],
		["........", "..oo....", ".omeo...", "ylmmmmoo", ".olmmo..", "..o.o...", "........", "........"],
		["..o..o..", "..omo...", ".omeoo..", "ylmmmmo.", "..ooo...", "........", "........", "........"],
		["........", "..oo....", ".omeo...", "ylmmmmo.", ".bmmmbo.", ".bo..ob.", "b......b", "........"],
	]:
		var p = Pix.new(8, 8)
		p.grid(g, SPARROW)
		frames.append(p)
	Pix.strip(frames).save_png(out + "/sparrow.png")
