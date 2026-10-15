class_name Sfx
extends Node
# Every sound in the game is made here, in code, when the game starts: short
# 16-bit mono buffers (AudioStreamWAV) played from a small pool. Two loops run
# underneath the show: wind (all the time) and crickets (at night).
# With a music source playing, the ambience sits lower.

const RATE := 22050

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var wind: AudioStreamPlayer
var crickets: AudioStreamPlayer
var music_on := false
var night := 0.0
var _bird_timer := 3.0
var _rng := RandomNumberGenerator.new()

static var inst: Sfx

static func play(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if inst:
		inst._play(name, vol_db, pitch)

static func start_ambience() -> void:
	if inst:
		inst._start_ambience()

static func set_music(on: bool) -> void:
	if inst:
		inst.music_on = on

static func set_night(v: float) -> void:
	if inst:
		inst.night = v

func _enter_tree() -> void:
	inst = self

func _ready() -> void:
	_rng.seed = 1234
	_streams["chirp"] = _wav(_chirp())
	_streams["chirp2"] = _wav(_chirp(1.25))
	_streams["rustle"] = _wav(_rustle())
	_streams["bell"] = _wav(_bell())
	_streams["knock"] = _wav(_knock())
	_streams["croak"] = _wav(_croak())
	_streams["caw"] = _wav(_caw())
	_streams["pop"] = _wav(_pop())
	_streams["sparkle"] = _wav(_sparkle())
	_streams["splash"] = _wav(_splash())
	_streams["yip"] = _wav(_yip())
	_streams["flap"] = _wav(_flap())
	_streams["song"] = _wav(_crow_song())
	_streams["puff"] = _wav(_puff())
	_streams["boing"] = _wav(_boing())
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	wind = AudioStreamPlayer.new()
	wind.stream = _wav(_wind(), true)
	wind.volume_db = -22.0
	add_child(wind)
	crickets = AudioStreamPlayer.new()
	crickets.stream = _wav(_crickets(), true)
	crickets.volume_db = -80.0
	add_child(crickets)

# Called on the first tap (browsers only allow sound after one).
func _start_ambience() -> void:
	if not wind.playing:
		wind.play()
	if not crickets.playing:
		crickets.play()

func _play(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _streams.has(name):
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _streams[name]
	p.volume_db = vol_db - (5.0 if music_on else 0.0)
	p.pitch_scale = pitch
	p.play()

func _process(delta: float) -> void:
	var amb := -12.0 if music_on else 0.0
	wind.volume_db = -24.0 + amb
	crickets.volume_db = lerpf(-60.0, -24.0, clampf(night, 0.0, 1.0)) + amb if night > 0.02 else -80.0
	if wind.playing and not music_on:
		_bird_timer -= delta
		if _bird_timer <= 0.0:
			_bird_timer = _rng.randf_range(3.0, 8.0)
			if night < 0.5:
				_play("chirp" if _rng.randf() < 0.5 else "chirp2", -18.0, _rng.randf_range(0.85, 1.2))

# ---- synthesis ---------------------------------------------------------

func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * RATE))
	return b

func _chirp(k: float = 1.0) -> PackedFloat32Array:
	var b := _buf(0.32)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var seg := fmod(t, 0.1)
		var f := (2600.0 + seg * 18000.0) * k
		ph += TAU * f / RATE
		var env := sin(clampf(seg / 0.08, 0.0, 1.0) * PI) * (1.0 if t < 0.3 else 0.0)
		b[i] = sin(ph) * env * 0.35
	return b

func _noise_lp(n: int, a: float, seed_v: int = 1) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var b := PackedFloat32Array()
	b.resize(n)
	var y := 0.0
	for i in n:
		y += (r.randf_range(-1.0, 1.0) - y) * a
		b[i] = y
	return b

func _rustle() -> PackedFloat32Array:
	var n := int(0.45 * RATE)
	var hi := _noise_lp(n, 0.6, 3)
	var lo := _noise_lp(n, 0.08, 4)
	var r := RandomNumberGenerator.new()
	r.seed = 9
	var b := _buf(0.45)
	var crackle := 0.0
	for i in n:
		var t := float(i) / n
		if r.randf() < 0.004:
			crackle = 1.0
		crackle *= 0.995
		var env := pow(1.0 - t, 1.5) * minf(1.0, t * 30.0)
		b[i] = (hi[i] - lo[i]) * env * (0.5 + crackle) * 0.9
	return b

func _bell() -> PackedFloat32Array:
	var b := _buf(1.6)
	var parts := [[1.0, 1.0], [2.0, 0.5], [2.76, 0.35], [5.4, 0.2], [8.9, 0.1]]
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for p in parts:
			s += sin(TAU * 1046.0 * p[0] * t) * p[1] * exp(-t * (2.0 + p[0]))
		b[i] = s * 0.25
	return b

func _knock() -> PackedFloat32Array:
	var b := _buf(0.12)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * lerpf(320.0, 110.0, t / 0.12) / RATE
		b[i] = sin(ph) * exp(-t * 40.0) * 0.6
	return b

func _croak() -> PackedFloat32Array:
	var b := _buf(0.38)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (95.0 - t * 40.0) / RATE
		var sq := 1.0 if fmod(ph, TAU) < PI else -1.0
		var am := 0.5 + 0.5 * sin(TAU * 28.0 * t)
		b[i] = sq * am * sin(PI * t / 0.38) * 0.22
	return b

func _caw() -> PackedFloat32Array:
	var b := _buf(0.4)
	var nz := _noise_lp(b.size(), 0.5, 7)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 620.0 - t * 500.0
		ph += TAU * f / RATE
		var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
		var env := sin(PI * minf(t / 0.36, 1.0)) * (0.7 + 0.3 * sin(TAU * 35.0 * t))
		b[i] = (saw * 0.5 + nz[i] * 0.5) * env * 0.35
	return b

func _pop() -> PackedFloat32Array:
	var b := _buf(0.08)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * lerpf(700.0, 1500.0, t / 0.08) / RATE
		b[i] = sin(ph) * (1.0 - t / 0.08) * 0.4
	return b

func _sparkle() -> PackedFloat32Array:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for k in 3:
			var t0 := k * 0.09
			if t >= t0:
				s += sin(TAU * (2093.0 * pow(1.26, k)) * (t - t0)) * exp(-(t - t0) * 12.0)
		b[i] = s * 0.18
	return b

func _splash() -> PackedFloat32Array:
	var n := int(0.5 * RATE)
	var nz := _noise_lp(n, 0.25, 11)
	var b := _buf(0.5)
	for i in n:
		var t := float(i) / n
		b[i] = nz[i] * pow(1.0 - t, 2.0) * minf(1.0, t * 40.0) * 0.9
	return b

func _yip() -> PackedFloat32Array:
	var b := _buf(0.18)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 700.0 + sin(PI * t / 0.18) * 500.0
		ph += TAU * f / RATE
		b[i] = (sin(ph) + 0.3 * sin(ph * 2.0)) * sin(PI * t / 0.18) * 0.3
	return b

func _flap() -> PackedFloat32Array:
	var n := int(0.36 * RATE)
	var nz := _noise_lp(n, 0.12, 13)
	var b := _buf(0.36)
	for i in n:
		var t := float(i) / RATE
		var beat := fmod(t, 0.12) / 0.12
		b[i] = nz[i] * exp(-beat * 9.0) * 1.4
	return b

func _puff() -> PackedFloat32Array:
	var n := int(0.3 * RATE)
	var nz := _noise_lp(n, 0.05, 17)
	var b := _buf(0.3)
	for i in n:
		var t := float(i) / n
		b[i] = nz[i] * sin(PI * t) * 1.6
	return b

func _boing() -> PackedFloat32Array:
	var b := _buf(0.25)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (220.0 + 180.0 * sin(t * 50.0) * exp(-t * 8.0)) / RATE
		b[i] = sin(ph) * exp(-t * 10.0) * 0.4
	return b

# The crow's song: a rough, hopeful little croon of six notes.
func _crow_song() -> PackedFloat32Array:
	var notes := [[0.0, 523.0], [0.28, 587.0], [0.56, 659.0], [0.84, 587.0], [1.1, 784.0], [1.45, 698.0]]
	var b := _buf(2.1)
	var nz := _noise_lp(b.size(), 0.4, 21)
	for n in notes:
		var t0: float = n[0]
		var f: float = n[1] * 0.75
		var ph := 0.0
		var i0 := int(t0 * RATE)
		for i in range(i0, mini(b.size(), i0 + int(0.4 * RATE))):
			var t := float(i - i0) / RATE
			ph += TAU * f * (1.0 + 0.02 * sin(TAU * 6.0 * t)) / RATE
			var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
			var env := sin(PI * minf(t / 0.38, 1.0))
			b[i] += (saw * 0.35 + sin(ph) * 0.4 + nz[i] * 0.15) * env * 0.4
	return b

func _wind() -> PackedFloat32Array:
	var sec := 6.0
	var n := int(sec * RATE)
	var nz := _noise_lp(n, 0.02, 31)
	var b := _buf(sec)
	for i in n:
		var t := float(i) / RATE
		var lfo := 0.55 + 0.45 * sin(TAU * t / sec) * sin(TAU * 2.0 * t / sec + 1.0)
		b[i] = nz[i] * lfo * 3.0
	# cross-fade the ends so the loop has no click
	var fade := int(0.3 * RATE)
	for i in fade:
		var a := float(i) / fade
		b[i] = b[i] * a + b[n - fade + i] * (1.0 - a)
	return b

func _crickets() -> PackedFloat32Array:
	var sec := 2.0
	var b := _buf(sec)
	for i in b.size():
		var t := float(i) / RATE
		var pulse := fmod(t, 0.5)
		var on := 1.0 if pulse < 0.12 and fmod(pulse, 0.03) < 0.018 else 0.0
		b[i] = sin(TAU * 4400.0 * t) * on * 0.12
	return b
