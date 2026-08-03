class_name Sfx
extends RefCounted
## Lightweight procedural UI and world SFX; replace with authored assets later.

static var _player: AudioStreamPlayer
static var _music_player: AudioStreamPlayer

static func ensure() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.name = "SfxPlayer"
		_player.bus = &"SFX"
		tree.root.call_deferred("add_child", _player)
	if _music_player == null or not is_instance_valid(_music_player):
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MenuBed"
		_music_player.bus = &"Music"
		tree.root.call_deferred("add_child", _music_player)

static func play(kind: StringName) -> void:
	_play(kind, &"SFX")

static func play_ui(kind: StringName) -> void:
	_play(kind, &"UI")

static func start_menu_bed() -> void:
	ensure()
	if _music_player == null or not is_instance_valid(_music_player) or not _music_player.is_inside_tree() or _music_player.playing:
		return
	_music_player.stream = _make_wav(110.0, 1.0, 0.18, 0.10, true)
	_music_player.play()

static func stop_menu_bed() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()

static func _play(kind: StringName, bus: StringName) -> void:
	ensure()
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	var profile := _profile(kind)
	var pitch := randf_range(0.97, 1.03)
	_player.bus = bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
	_player.pitch_scale = pitch
	_player.stream = _make_wav(profile.frequency, profile.duration, profile.volume, profile.decay, false, profile.harmonic)
	_player.play()

static func _profile(kind: StringName) -> Dictionary:
	match str(kind):
		"click", "hover", "pop", "step", "info", "ok":
			return {"frequency": 920.0, "duration": 0.045, "volume": 0.22, "decay": 1.8, "harmonic": 0.15}
		"confirm", "date_ok", "date", "unlock", "girl", "relation", "event_start", "story":
			return {"frequency": 620.0, "duration": 0.16, "volume": 0.32, "decay": 1.1, "harmonic": 0.35}
		"cancel", "deny", "error", "date_bad", "warn":
			return {"frequency": 190.0, "duration": 0.14, "volume": 0.30, "decay": 0.8, "harmonic": 0.50}
		"buy", "money", "gift":
			return {"frequency": 760.0, "duration": 0.12, "volume": 0.34, "decay": 1.2, "harmonic": 0.30}
		"buy_big", "finale", "clone":
			return {"frequency": 520.0, "duration": 0.28, "volume": 0.38, "decay": 0.7, "harmonic": 0.45}
		"door", "elevator", "machine", "place":
			return {"frequency": 270.0, "duration": 0.18, "volume": 0.30, "decay": 0.65, "harmonic": 0.65}
		"land", "event_end":
			return {"frequency": 360.0, "duration": 0.10, "volume": 0.32, "decay": 1.5, "harmonic": 0.20}
		_:
			return {"frequency": 440.0, "duration": 0.08, "volume": 0.25, "decay": 1.0, "harmonic": 0.20}

static func _make_wav(frequency: float, duration: float, volume: float, decay: float, looping: bool, harmonic: float = 0.2) -> AudioStreamWAV:
	var sample_rate := 22050
	var length := maxi(1, int(sample_rate * duration))
	var data := PackedByteArray()
	data.resize(length * 2)
	for index in range(length):
		var t := float(index) / float(sample_rate)
		var progress := float(index) / float(length)
		var envelope := exp(-progress * 5.0 * decay)
		var waveform := sin(t * frequency * TAU) + sin(t * frequency * 2.0 * TAU) * harmonic
		var sample := int(clampf(waveform * volume * envelope, -1.0, 1.0) * 32767.0)
		data[index * 2] = sample & 0xFF
		data[index * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = length
	return stream
