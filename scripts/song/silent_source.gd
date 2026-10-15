class_name SilentSource
extends SongSource
# The plain clock: counts seconds once begin() is called. Used in the editor,
# on desktop, in the tests, and whenever a music source can't play.
# It follows Engine.time_scale, so the smoke test can run the show fast.

var t := 0.0
var running := false

func _init(start_at: float = 0.0, why: String = "") -> void:
	id = "silent"
	t = start_at
	note = why

func begin() -> void:
	running = true

func restart() -> void:
	t = 0.0
	running = true

func state() -> String:
	return "playing" if running else "ready"

func time() -> float:
	return t

func _process(delta: float) -> void:
	if running:
		t += delta
