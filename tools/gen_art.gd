extends SceneTree
# Regenerates every PNG in art/ (except art/hemlock/, which are copies of the
# Hemlock's Tower originals). Run:
#   godot --headless --path . --script tools/gen_art.gd
# then `godot --headless --path . --import` so Godot picks up the changes.

const Chars := preload("res://tools/gen_characters.gd")

func _init() -> void:
	var out := ProjectSettings.globalize_path("res://art")
	DirAccess.make_dir_recursive_absolute(out)
	Chars.crow_strips(out)
	Chars.fox_strips(out)
	Chars.cookie_strip(out)
	Chars.sparrow_strip(out)
	if ResourceLoader.exists("res://tools/gen_scenery.gd"):
		load("res://tools/gen_scenery.gd").generate(out)
	print("gen_art: done")
	quit()
