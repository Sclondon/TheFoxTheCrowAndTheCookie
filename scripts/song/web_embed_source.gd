class_name WebEmbedSource
extends SongSource
# Shared parts of the Spotify and YouTube sources: a framed corner window
# added to the page (never hidden: the listener can shrink it, not close it),
# and a poll of the player's state through JavaScriptBridge every frame.
#
# The page-side object is window.__fccSong. Each subclass's JS fills in:
#   S.state  loading / ready / failed
#   S.err    why it failed
#   S.poll() -> JSON {t, paused, dur, started}
#   S.play(), S.restart()

var _last := {}
var _poll_ok := false

static func available() -> bool:
	return OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge")

# The frame: bottom-left, in the scene's wood colours, with a small tab to
# shrink and grow it. size/small are [w, h] in CSS pixels.
func _frame_js(size: Array, small: Array, title: String) -> String:
	return """
(function(){
  var old = window.__fccSong;
  if (old && old.shutdown) { try { old.shutdown(); } catch(e) {} }
  var S = window.__fccSong = {state:'loading', err:'', t:0, dur:0, paused:true, started:false};
  var wrap = document.createElement('div');
  wrap.id = 'fcc-song';
  wrap.style.cssText = 'position:fixed;left:max(8px, env(safe-area-inset-left));bottom:max(8px, env(safe-area-inset-bottom));z-index:20;pointer-events:auto;';
  var frame = document.createElement('div');
  frame.style.cssText = 'width:%dpx;height:%dpx;max-width:calc(100vw - 24px);border:3px solid #452c32;border-radius:12px;background:#321e2f;box-shadow:0 0 0 2px #88361c,0 4px 14px rgba(0,0,0,.55);overflow:hidden;transition:width .2s,height .2s;';
  var slot = document.createElement('div');
  slot.style.cssText = 'width:100%%;height:100%%;';
  frame.appendChild(slot);
  var tab = document.createElement('button');
  tab.setAttribute('aria-label', 'Shrink or grow the %s player');
  tab.textContent = '–';
  tab.style.cssText = 'position:absolute;right:-6px;top:-14px;width:26px;height:22px;padding:0;border:2px solid #452c32;border-radius:8px;background:#ca8c40;color:#321e2f;font:bold 15px/16px sans-serif;cursor:pointer;';
  var big = true;
  tab.onclick = function(ev){
    ev.stopPropagation();
    big = !big;
    frame.style.width = (big ? %d : %d) + 'px';
    frame.style.height = (big ? %d : %d) + 'px';
    tab.textContent = big ? '–' : '+';
  };
  wrap.appendChild(frame);
  wrap.appendChild(tab);
  document.body.appendChild(wrap);
  S.wrap = wrap; S.slot = slot;
  S.shutdown = function(){ try { if (S.destroy) S.destroy(); } catch(e) {} wrap.remove(); };
  S.load = function(src, onerr){
    var sc = document.createElement('script');
    sc.src = src; sc.async = true;
    sc.onerror = function(){ S.state = 'failed'; S.err = 'load'; };
    document.head.appendChild(sc);
    setTimeout(function(){ if (S.state === 'loading') { S.state = 'failed'; S.err = 'timeout'; } }, 15000);
  };
})();
""" % [size[0], size[1], title, size[0], small[0], size[1], small[1]]

func _js(code: String):
	if not available():
		return null
	return JavaScriptBridge.eval(code, true)

func _process(_delta: float) -> void:
	if not available():
		return
	var s = _js("window.__fccSong && window.__fccSong.poll ? window.__fccSong.poll() : ''")
	if typeof(s) == TYPE_STRING and s != "":
		var d = JSON.parse_string(s)
		if d is Dictionary:
			_last = d
			_poll_ok = true

func _page_state() -> String:
	var s = _js("window.__fccSong ? window.__fccSong.state : 'failed'")
	return str(s) if s != null else "failed"

func page_error() -> String:
	var s = _js("window.__fccSong ? window.__fccSong.err : ''")
	return str(s) if s != null else ""

var _begun := false

func begin() -> void:
	_begun = true
	_js("window.__fccSong && window.__fccSong.play && window.__fccSong.play()")

func restart() -> void:
	_begun = true
	_js("window.__fccSong && window.__fccSong.restart && window.__fccSong.restart()")

func state() -> String:
	var ps := _page_state()
	if ps == "failed":
		return "failed"
	if ps == "loading":
		return "loading"
	if not _poll_ok or not bool(_last.get("started", false)):
		return "starting" if _begun else "ready"
	return "paused" if bool(_last.get("paused", true)) else "playing"

func time() -> float:
	return float(_last.get("t", 0.0))

func duration() -> float:
	return float(_last.get("dur", 0.0))

func is_music() -> bool:
	return true

func shutdown() -> void:
	_js("window.__fccSong && window.__fccSong.shutdown && window.__fccSong.shutdown()")
	queue_free()
