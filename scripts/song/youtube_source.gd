class_name YouTubeSource
extends WebEmbedSource
# The song through the YouTube IFrame Player API, in a small framed window in
# the bottom-left corner (playsinline, no controls, no related videos). The
# clock is player.getCurrentTime(), polled every frame, so pauses, buffering
# and seeks keep the scene in sync.
#
# YouTube asks for embedded players of at least 200x200, so this window stays
# 200x200 (the shrink tab only takes it down to that).

const API := "https://www.youtube.com/iframe_api"

var video_id := ""

func setup(cfg: Dictionary) -> void:
	id = "youtube"
	video_id = str(cfg.get("video_id", ""))
	offset = float(cfg.get("offset", 0.0))
	if not available() or video_id == "":
		return
	_js(_frame_js([200, 200], [200, 200], "YouTube"))
	_js("""
(function(){
  var S = window.__fccSong;
  S.kind = 'youtube';
  S.wantPlay = false;
  S.poll = function(){
    var p = S.player, t = 0, st = -1, dur = 0;
    if (p && p.getCurrentTime) { try { t = p.getCurrentTime() || 0; st = p.getPlayerState(); dur = p.getDuration() || 0; } catch(e) {} }
    if (st === 1 && t > 0) S.started = true;
    return JSON.stringify({t: t, paused: st !== 1, dur: dur, started: S.started});
  };
  S.play = function(){
    if (S.player && S.player.playVideo) { try { S.player.playVideo(); } catch(e) {} } else { S.wantPlay = true; }
  };
  S.restart = function(){
    if (S.player && S.player.seekTo) { try { S.player.seekTo(0, true); S.player.playVideo(); } catch(e) {} }
  };
  S.destroy = function(){ if (S.player && S.player.destroy) S.player.destroy(); };
  var make = function(){
    var host = document.createElement('div');
    S.slot.appendChild(host);
    S.player = new YT.Player(host, {
      videoId: '%s', width: '100%%', height: '100%%',
      playerVars: {playsinline: 1, controls: 0, rel: 0, modestbranding: 1, fs: 0, iv_load_policy: 3, disablekb: 1},
      events: {
        onReady: function(){ S.state = 'ready'; if (S.wantPlay) S.player.playVideo(); },
        onError: function(e){ S.state = 'failed'; S.err = 'youtube error ' + e.data; }
      }
    });
  };
  if (window.YT && window.YT.Player) { make(); }
  else {
    var prev = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = function(){ if (prev) try { prev(); } catch(e) {} make(); };
    S.load('%s');
  }
})();
""" % [video_id, API])

func state() -> String:
	if not available() or video_id == "":
		return "failed"
	return super.state()
