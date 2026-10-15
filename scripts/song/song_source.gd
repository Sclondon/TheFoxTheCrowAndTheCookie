class_name SongSource
extends Node
# Where the show's clock comes from. The story reads `time()` every frame and
# acts out whatever beats it has reached, so a source that pauses, buffers or
# seeks carries the story with it.
#
# States:
#   "loading"       still fetching the player
#   "ready"         loaded, waiting for begin() (the Tap to play press)
#   "starting"      begin() called, the music hasn't started yet
#   "playing"       the clock is moving
#   "paused"        the listener paused (the story waits)
#   "failed"        couldn't load or play: the show falls back to SilentSource
#   "preview_over"  a 30 s preview ran out: the show carries on silently
#
# Implementations: SilentSource (plain clock), SpotifySource, YouTubeSource.

var id := "silent"
var offset := 0.0        # seconds of source before the timeline's 0
var note := ""           # a short line for the HUD when something's off

func setup(_cfg: Dictionary) -> void:
	pass

func begin() -> void:
	pass

func restart() -> void:
	pass

func state() -> String:
	return "ready"

# Seconds into the song (the source's own time, offset not yet removed).
func time() -> float:
	return 0.0

# Seconds of the song the listener will hear (0 if unknown).
func duration() -> float:
	return 0.0

func is_music() -> bool:
	return false

func shutdown() -> void:
	queue_free()

# Timeline time.
func show_time() -> float:
	return time() - offset
