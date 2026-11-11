extends Node
## Quiet wind and a short click accompany government controls.

const RATE := 22050

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last := {}
var rng := RandomNumberGenerator.new()
var wind: AudioStreamPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	rng.seed = 4
	sounds.click = _synth(0.04, func(u, tt): return _sq(tt * 900.0), 0.12, 3.0)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	wind = _looper(_noise_loop(4.0, 0.02, 0.22), -20.0)


func _n() -> float:
	return rng.randf_range(-1.0, 1.0)


func _sq(ph: float) -> float:
	return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = samples.size()
	return st


func _synth(dur: float, f: Callable, vol: float, decay: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var u := float(i) / n
		var env := minf(1.0, i / (RATE * 0.002)) * pow(1.0 - u, decay)
		out[i] = float(f.call(u, float(i) / RATE)) * env * vol
	return _wav(out)


func _noise_loop(dur: float, smooth: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		y += (_n() - y) * smooth
		out[i] = y * vol * 4.0
	var f := int(RATE * 0.3)
	for i in f:
		var w := float(i) / f
		out[i] = out[i] * w + out[n - f + i] * (1.0 - w)
	return _wav(out, true)


func _looper(st: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = db
	add_child(p)
	p.play()
	return p


func play(name: String, vol_db := 0.0, pitch := 1.0, delay := 0.0) -> void:
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(play.bind(name, vol_db, pitch, 0.0))
		return
	if not sounds.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(last.get(name, -1000)) < 40:
		return
	last[name] = now
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.volume_db = vol_db
			p.pitch_scale = pitch * rng.randf_range(0.95, 1.05)
			p.play()
			return


func _exit_tree() -> void:
	for player in players:
		player.stop()
	if is_instance_valid(wind):
		wind.stop()
