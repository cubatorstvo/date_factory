class_name Sfx
extends RefCounted
## Licensed authored SFX with procedural fallback and smooth zone music.

const UI_STREAMS: Dictionary = {
	&"click": "res://assets/audio/sfx/ui/click.ogg",
	&"hover": "res://assets/audio/sfx/ui/hover.ogg",
	&"confirm": "res://assets/audio/sfx/ui/confirm.ogg",
	&"back": "res://assets/audio/sfx/ui/back.ogg",
	&"error": "res://assets/audio/sfx/ui/error.ogg",
	&"open": "res://assets/audio/sfx/ui/open.ogg",
	&"close": "res://assets/audio/sfx/ui/close.ogg",
	&"toggle": "res://assets/audio/sfx/ui/toggle.ogg",
	&"tick": "res://assets/audio/sfx/ui/tick.ogg",
}
const WORLD_STREAMS: Dictionary = {
	&"door": "res://assets/audio/sfx/world/door_open.ogg",
	&"impact": "res://assets/audio/sfx/world/soft_impact.ogg",
	&"event": "res://assets/audio/sfx/world/event_chime.ogg",
	&"result_success": "res://assets/audio/sfx/world/result_success.ogg",
	&"result_fail": "res://assets/audio/sfx/world/result_fail.ogg",
}
const ZONE_MUSIC: Dictionary = {
	&"apartment": {"path": "res://assets/audio/music/apartment_chill.ogg", "volume": -21.0},
	&"street": {"path": "res://assets/audio/music/street_night.ogg", "volume": -20.0},
	&"restaurant": {"path": "res://assets/audio/music/restaurant_warm.ogg", "volume": -17.0},
}

static var _player: AudioStreamPlayer
static var _music_player: AudioStreamPlayer
static var _active_zone: StringName = &""
static var _zone_tween: Tween

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
	set_zone(&"apartment")

static func stop_menu_bed() -> void:
	_active_zone = &""
	if _zone_tween != null:
		_zone_tween.kill()
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()

static func _play(kind: StringName, bus: StringName) -> void:
	ensure()
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		var pending_tree := Engine.get_main_loop() as SceneTree
		if pending_tree:
			pending_tree.create_timer(0.01).timeout.connect(func() -> void: _play(kind, bus), CONNECT_ONE_SHOT)
		return
	var pitch := randf_range(0.97, 1.03)
	_player.bus = bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
	_player.pitch_scale = pitch
	var stream_path := _stream_path(kind, bus)
	if not stream_path.is_empty():
		var authored := load(stream_path) as AudioStream
		if authored:
			_player.stream = authored
			_player.play()
			return
	var profile := _profile(kind)
	_player.stream = _make_wav(profile.frequency, profile.duration, profile.volume, profile.decay, false, profile.harmonic)
	_player.play()

static func set_zone(zone: StringName) -> void:
	ensure()
	if _music_player == null or not is_instance_valid(_music_player) or not _music_player.is_inside_tree():
		var pending_tree := Engine.get_main_loop() as SceneTree
		if pending_tree:
			pending_tree.create_timer(0.01).timeout.connect(func() -> void: set_zone(zone), CONNECT_ONE_SHOT)
		return
	if not ZONE_MUSIC.has(zone):
		return
	if _active_zone == zone and _music_player.playing:
		return
	_active_zone = zone
	var profile: Dictionary = ZONE_MUSIC[zone]
	var stream := load(str(profile.get("path", ""))) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var target_volume := float(profile.get("volume", -18.0))
	if _zone_tween != null:
		_zone_tween.kill()
	_zone_tween = _music_player.create_tween()
	if _music_player.playing:
		_zone_tween.tween_property(_music_player, "volume_db", -36.0, 0.38)
		_zone_tween.tween_callback(func() -> void:
			_music_player.stream = stream
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = -36.0
		_music_player.play()
	_zone_tween.tween_property(_music_player, "volume_db", target_volume, 0.72)

static func current_zone() -> StringName:
	return _active_zone

static func _stream_path(kind: StringName, bus: StringName) -> String:
	var normalized := _normalize_kind(kind)
	if bus == &"UI" and UI_STREAMS.has(normalized):
		return str(UI_STREAMS[normalized])
	if kind == &"step":
		var zone_name := str(_active_zone)
		if zone_name not in ["apartment", "street", "restaurant"]:
			zone_name = "apartment"
		return "res://assets/audio/sfx/steps/%s_%d.ogg" % [zone_name, randi_range(1, 3)]
	if WORLD_STREAMS.has(normalized):
		return str(WORLD_STREAMS[normalized])
	return ""

static func _normalize_kind(kind: StringName) -> StringName:
	match str(kind):
		"click", "pop", "info", "ok":
			return &"click"
		"hover":
			return &"hover"
		"confirm", "date_ok", "date", "girl", "relation", "story", "buy", "money", "gift":
			return &"confirm"
		"cancel":
			return &"back"
		"deny", "error", "date_bad", "warn", "crisis":
			return &"error"
		"unlock", "reveal_big", "event_start", "decision":
			return &"event"
		"door", "elevator":
			return &"door"
		"land", "event_end", "fix", "place":
			return &"impact"
		"result_success", "finale":
			return &"result_success"
		"result_fail":
			return &"result_fail"
		_:
			return kind

static func _profile(kind: StringName) -> Dictionary:
	match str(kind):
		"click", "hover", "pop", "info", "ok":
			return {"frequency": 920.0, "duration": 0.045, "volume": 0.22, "decay": 1.8, "harmonic": 0.15}
		"step":
			return {"frequency": 180.0 + randf() * 40.0, "duration": 0.05, "volume": 0.14, "decay": 2.2, "harmonic": 0.05}
		"confirm", "date_ok", "date", "girl", "relation", "story":
			return {"frequency": 620.0, "duration": 0.16, "volume": 0.32, "decay": 1.1, "harmonic": 0.35}
		"unlock", "reveal_big":
			return {"frequency": 540.0, "duration": 0.32, "volume": 0.40, "decay": 0.85, "harmonic": 0.55}
		"event_start", "decision":
			return {"frequency": 480.0, "duration": 0.22, "volume": 0.34, "decay": 1.0, "harmonic": 0.40}
		"cancel", "deny", "error", "date_bad", "warn", "crisis":
			return {"frequency": 190.0, "duration": 0.14, "volume": 0.30, "decay": 0.8, "harmonic": 0.50}
		"buy", "money", "gift":
			return {"frequency": 760.0, "duration": 0.12, "volume": 0.34, "decay": 1.2, "harmonic": 0.30}
		"buy_big", "finale", "clone", "lab":
			return {"frequency": 520.0, "duration": 0.28, "volume": 0.38, "decay": 0.7, "harmonic": 0.45}
		"door", "elevator", "machine", "place", "alarm":
			return {"frequency": 270.0, "duration": 0.18, "volume": 0.30, "decay": 0.65, "harmonic": 0.65}
		"land", "event_end", "fix":
			return {"frequency": 360.0, "duration": 0.10, "volume": 0.32, "decay": 1.5, "harmonic": 0.20}
		"legend_hit":
			return {"frequency": 140.0, "duration": 0.25, "volume": 0.36, "decay": 0.6, "harmonic": 0.7}
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
