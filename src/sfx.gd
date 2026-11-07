extends Node
## Synthesized sound for Last Light.

const RATE := 22050

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last := {}
var rng := RandomNumberGenerator.new()
var wind: AudioStreamPlayer
var heart_p: AudioStreamPlayer


func _ready() -> void:
	rng.seed = 4
	sounds.shot = _synth(0.5, func(u, tt): return _n() * (1.0 if u < 0.06 else 0.45) + sin(tt * TAU * lerpf(160.0, 50.0, u)) * 0.7, 0.75, 2.4)
	sounds.empty = _synth(0.05, func(u, tt): return _sq(tt * 1900.0), 0.2, 3.0)
	sounds.reload = _synth(0.5, func(u, tt): return _n() * (1.0 if fmod(u, 0.5) < 0.07 else 0.0), 0.3, 0.3)
	sounds.swing = _synth(0.18, func(u, tt): return _n() * sin(u * PI), 0.25, 0.5)
	sounds.bash = _synth(0.15, func(u, tt): return sin(tt * TAU * lerpf(150.0, 60.0, u)) + _n() * 0.4, 0.5, 2.0)
	sounds.hit = _synth(0.12, func(u, tt): return _n() * 0.6 + sin(tt * TAU * 90.0) * 0.6, 0.4, 2.0)
	sounds.kill = _synth(0.35, func(u, tt): return _saw(tt * lerpf(140.0, 60.0, u)) * 0.5 + _n() * 0.3, 0.35, 1.5)
	sounds.groan1 = _synth(1.1, func(u, tt): return _saw(tt * (lerpf(95.0, 70.0, u) + sin(tt * 9.0) * 6.0)) * (0.6 + 0.4 * sin(u * PI)), 0.22, 0.6)
	sounds.groan2 = _synth(0.8, func(u, tt): return _saw(tt * (lerpf(120.0, 85.0, u) + sin(tt * 13.0) * 8.0)) * sin(u * PI), 0.2, 0.4)
	sounds.board = _synth(0.5, func(u, tt): return (sin(tt * TAU * 180.0) + _n()) * (1.0 if fmod(u * 3.0, 1.0) < 0.12 else 0.0), 0.45, 0.2)
	sounds.bang = _synth(0.25, func(u, tt): return sin(tt * TAU * lerpf(110.0, 60.0, u)) * 0.8 + _n() * 0.5, 0.5, 1.8)
	sounds.crack = _synth(0.4, func(u, tt): return _n() * (1.0 if rng.randf() < 0.4 else 0.2), 0.5, 1.6)
	sounds.loot = _synth(0.4, func(u, tt): return _n() * 0.5 * sin(u * PI * 3.0), 0.25, 0.8)
	sounds.pickup = _chord([660.0, 990.0], 0.35, 0.16)
	sounds.hurt = _synth(0.25, func(u, tt): return _saw(tt * lerpf(220.0, 140.0, u)) * 0.6, 0.3, 1.2)
	sounds.heal = _chord([523.0, 659.0, 784.0], 0.7, 0.14)
	sounds.night = _synth(2.5, func(u, tt): return sin(tt * TAU * 55.0) * 0.6 + sin(tt * TAU * 82.4) * 0.4 + _n() * 0.1, 0.35, 0.7)
	sounds.dawn = _chord([392.0, 523.25, 659.25, 783.99], 2.0, 0.15)
	sounds.die = _synth(1.6, func(u, tt): return _saw(tt * lerpf(200.0, 40.0, u)) * 0.6 + _n() * 0.3, 0.4, 0.8)
	sounds.click = _synth(0.04, func(u, tt): return _sq(tt * 900.0), 0.12, 3.0)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	wind = _looper(_noise_loop(4.0, 0.02, 0.22), -20.0)
	heart_p = _looper(_heartbeat(), -80.0)


func _n() -> float:
	return rng.randf_range(-1.0, 1.0)


func _sq(ph: float) -> float:
	return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0


func _saw(ph: float) -> float:
	return fmod(ph, 1.0) * 2.0 - 1.0


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


func _chord(freqs: Array, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var tt := float(i) / RATE
		var s := 0.0
		for k in freqs.size():
			s += sin(tt * freqs[k] * TAU) * exp(-tt * 1.5)
		out[i] = s * vol
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


func _heartbeat() -> AudioStreamWAV:
	var n := int(0.9 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var tt := float(i) / RATE
		var s := 0.0
		for b in [0.0, 0.22]:
			if tt > b:
				s += sin((tt - b) * TAU * 55.0) * exp(-(tt - b) * 22.0)
		out[i] = s * 0.8
	return _wav(out, true)


func _siren() -> AudioStreamWAV:
	var n := int(2.0 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var u := float(i) / n
		ph += lerpf(500.0, 800.0, 0.5 - 0.5 * cos(u * TAU)) / RATE
		out[i] = _saw(ph) * 0.18
	return _wav(out, true)


func _looper(st: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = db
	add_child(p)
	p.play()
	return p


func heart(amount: float) -> void:
	heart_p.volume_db = lerpf(heart_p.volume_db, lerpf(-80.0, -4.0, amount), 0.1)


func groan(vol: float) -> void:
	play("groan1" if rng.randf() < 0.5 else "groan2", vol, rng.randf_range(0.8, 1.25))


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
