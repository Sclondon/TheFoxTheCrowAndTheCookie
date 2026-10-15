class_name Art
extends RefCounted
# Small helpers for the sprite strips in art/ (frames laid left to right).

static var _cache := {}

static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = load("res://art/%s.png" % name)
	return _cache[name]

# Add an animation cut from a strip. frames: which cells (null = all).
static func add_anim(sf: SpriteFrames, anim: String, strip: String, fw: int, fh: int, fps: float, loop: bool = true, frames = null) -> void:
	var t := tex(strip)
	var n := t.get_width() / fw
	if not sf.has_animation(anim):
		sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	var list: Array = frames if frames != null else range(n)
	for i in list:
		var at := AtlasTexture.new()
		at.atlas = t
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(anim, at)

# A Sprite2D showing one cell of a strip.
static func sprite(strip: String, frames: int = 1, frame: int = 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(strip)
	s.hframes = frames
	s.frame = frame
	return s

# A Sprite2D placed by its bottom-left corner (handy for scenery).
static func prop(strip: String, x: float, ground_y: float, frames: int = 1, frame: int = 0) -> Sprite2D:
	var s := sprite(strip, frames, frame)
	s.centered = false
	s.position = Vector2(x, ground_y - s.texture.get_height())
	return s
