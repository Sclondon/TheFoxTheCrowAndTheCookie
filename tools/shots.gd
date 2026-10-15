extends Node
# Screenshot tool. Run the game in a real window at a phone size and save
# frames at chosen moments of the show:
#
#   godot --path . --resolution 390x844 -- --silent --shots=title,20,90,150 \
#         --shotdir=shots --tag=portrait [--speed=6]
#
# "title" grabs the title card; numbers are show seconds (the show starts
# itself after the title shot). Files: <shotdir>/<tag>_<what>.png. Quits when
# done. main.gd adds this node when it sees --shots.

var main: Node
var wants: Array = []
var dir := "shots"
var tag := "shot"
var _frames := 0
var _busy := false

func _ready() -> void:
	main = get_parent()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := str(a).trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	wants = str(args.get("shots", "")).split(",", false)
	dir = str(args.get("shotdir", "shots"))
	tag = str(args.get("tag", "shot"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + dir))
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_d: float) -> void:
	_frames += 1
	if _busy or _frames < 20:
		return
	if wants.is_empty():
		get_tree().quit()
		return
	var w: String = wants[0]
	if w == "title":
		_grab(w)
		return
	if main.state == main.State.TITLE:
		main._start()
		return
	if float(main.show_t) >= float(w):
		_grab(w)

func _grab(what: String) -> void:
	_busy = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://%s/%s_%s.png" % [dir, tag, what])
	img.save_png(path)
	print("shot: ", path, " ", img.get_size())
	wants.pop_front()
	_busy = false
