class_name SpotifySource
extends WebEmbedSource
# The song through Spotify's official Embed iFrame API, shown as the compact
# (80px) player in the bottom-left corner.
#
# The clock follows the controller's playback_update events (position and
# duration in ms, isPaused): it keeps the last position and the moment it
# arrived, and moves on from there between updates, so the scene stays smooth
# and still follows pauses and seeks.
#
# Listeners not signed in to Spotify get a 30 s preview. That shows up as a
# duration of about 30000 ms (or playback stopping near 30 s); the state goes
# to "preview_over" and the show carries on with the plain clock.

const API := "https://open.spotify.com/embed/iframe-api/v1"
const PREVIEW_NOTE := "Sign in to Spotify in this browser to hear the whole song"

var track_id := ""
var song_length := 211.0

func setup(cfg: Dictionary) -> void:
	id = "spotify"
	track_id = str(cfg.get("track_id", ""))
	offset = float(cfg.get("offset", 0.0))
	song_length = float(cfg.get("song_length", 211.0))
	if not available() or track_id == "":
		return
	_js(_frame_js([300, 80], [160, 80], "Spotify"))
	_js("""
(function(){
  var S = window.__fccSong;
  S.kind = 'spotify';
  S.pos = 0; S.stamp = performance.now(); S.wantPlay = false;
  S.poll = function(){
    var t = S.pos;
    if (!S.paused && S.started) t += (performance.now() - S.stamp) / 1000;
    if (S.dur > 0) t = Math.min(t, S.dur);
    return JSON.stringify({t: t, paused: S.paused, dur: S.dur, started: S.started});
  };
  S.play = function(){
    if (S.ctrl) { try { S.ctrl.play(); } catch(e) {} } else { S.wantPlay = true; }
  };
  S.restart = function(){
    if (S.ctrl) { try { S.ctrl.seek(0); S.ctrl.resume(); } catch(e) { try { S.ctrl.play(); } catch(e2) {} } }
  };
  S.destroy = function(){ if (S.ctrl && S.ctrl.destroy) S.ctrl.destroy(); };
  var make = function(IFrameAPI){
    IFrameAPI.createController(S.slot, {uri: 'spotify:track:%s', width: '100%%', height: 80}, function(ctrl){
      S.ctrl = ctrl;
      S.state = 'ready';
      ctrl.addListener('playback_update', function(e){
        var d = e.data || {};
        S.pos = (d.position || 0) / 1000;
        S.dur = (d.duration || 0) / 1000;
        S.paused = !!d.isPaused || !!d.isBuffering;
        S.stamp = performance.now();
        if (!d.isPaused && S.pos > 0) S.started = true;
      });
      if (S.wantPlay) { try { ctrl.play(); } catch(e) {} }
    });
  };
  if (window.__fccSpotifyAPI) { make(window.__fccSpotifyAPI); }
  else {
    window.onSpotifyIframeApiReady = function(IFrameAPI){ window.__fccSpotifyAPI = IFrameAPI; make(IFrameAPI); };
    S.load('%s');
  }
})();
""" % [track_id, API])

func state() -> String:
	if not available() or track_id == "":
		return "failed"
	var s := super.state()
	if s == "playing" or s == "paused":
		var d := duration()
		# A preview: the embed reports ~30 s for a song that runs 3:31.
		if d > 1.0 and d < 40.0 and song_length > 60.0:
			if time() >= d - 0.6 or (s == "paused" and time() >= d - 2.0):
				note = PREVIEW_NOTE
				return "preview_over"
	return s

func is_preview() -> bool:
	var d := duration()
	return d > 1.0 and d < 40.0 and song_length > 60.0
