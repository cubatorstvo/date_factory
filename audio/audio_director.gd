extends Node
## Compact presentation AudioDirector (MODULE 23).
## Owns music states, crossfade, bounded SFX/UI pools, volume seams, minigame duck.
## Does not own gameplay.


const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const BUS_AMBIENCE: StringName = &"Ambience"

const SFX_POOL_SIZE: int = 8
const UI_POOL_SIZE: int = 4
const CROSSFADE_SEC: float = 1.0
const DUCK_DB: float = -4.0
const DUCK_RESTORE_SEC: float = 0.4
const MUTE_DB: float = -80.0

const _BUS_DEFAULT_DB: Dictionary = {
	BUS_MASTER: 0.0,
	BUS_MUSIC: -8.0,
	BUS_SFX: -3.0,
	BUS_UI: -5.0,
	BUS_AMBIENCE: -10.0,
}

var _music_state: StringName = &""
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _fade_tween: Tween

var _sfx_pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _ui_cursor: int = 0

var _master_volume: float = 0.0
var _music_volume: float = 1.0
var _sfx_volume: float = 1.0
var _ui_volume: float = 1.0
var _ambience_volume: float = 1.0

var _duck_active: bool = false
var _duck_tween: Tween
var _duck_extra_db: float = 0.0

var _warned_missing: Dictionary = {}
var _stream_cache: Dictionary = {}
var _procedural_cache: Dictionary = {}

## Test/debug: increments only when a music stream actually (re)starts.
var music_start_count: int = 0


func _ready() -> void:
	_build_music_players()
	_build_pools()
	_apply_all_volumes()
	_connect_game_state()
	# Seed music from current stage without forcing a restart later on same-state travel.
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_stage"):
		notify_stage(int(gs.call("get_stage")))
	else:
		set_music_state(AudioIds.MUSIC_MANUAL)


func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.bus = String(BUS_MUSIC)
	_music_a.volume_db = MUTE_DB
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.bus = String(BUS_MUSIC)
	_music_b.volume_db = MUTE_DB
	add_child(_music_b)
	_active_music = _music_a


func _build_pools() -> void:
	for i: int in SFX_POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "Sfx_%d" % i
		p.bus = String(BUS_SFX)
		add_child(p)
		_sfx_pool.append(p)
	for i: int in UI_POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "Ui_%d" % i
		p.bus = String(BUS_UI)
		add_child(p)
		_ui_pool.append(p)


func _connect_game_state() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
		gs.connect("stage_changed", _on_stage_changed)


func _on_stage_changed(new_stage: Variant, _previous_stage: Variant) -> void:
	notify_stage(int(new_stage))


func notify_stage(stage: int) -> void:
	set_music_state(AudioIds.music_state_for_stage(stage))


func play_ui(sound_id: StringName) -> void:
	_play_oneshot(sound_id, _ui_pool, true)


func play_sfx(sound_id: StringName) -> void:
	_play_oneshot(sound_id, _sfx_pool, false)


func set_music_state(state: StringName) -> void:
	if state == _music_state:
		return
	var path: String = String(AudioIds.music_paths().get(state, ""))
	if path.is_empty():
		_warn_missing(state, "unknown music state")
		return
	var stream: AudioStream = _load_stream(path, false)
	if stream == null:
		# Still record the logical state so stage mapping / same-state checks work.
		_music_state = state
		_warn_missing(state, path)
		return
	_crossfade_to(stream)
	_music_state = state


func get_music_state() -> StringName:
	return _music_state


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, _master_volume, 0.0)


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_music_bus_volume()


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, _sfx_volume, 0.0)


func set_ui_volume(value: float) -> void:
	_ui_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_UI, _ui_volume, 0.0)


func set_ambience_volume(value: float) -> void:
	_ambience_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_AMBIENCE, _ambience_volume, 0.0)


func get_master_volume() -> float:
	return _master_volume


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func get_ui_volume() -> float:
	return _ui_volume


func get_ambience_volume() -> float:
	return _ambience_volume


func duck_for_minigame(active: bool) -> void:
	if active == _duck_active:
		return
	_duck_active = active
	var target_extra: float = DUCK_DB if active else 0.0
	var duration: float = 0.05 if active else DUCK_RESTORE_SEC
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_duck_extra_db, _duck_extra_db, target_extra, duration)


func get_sfx_pool_size() -> int:
	return _sfx_pool.size()


func get_ui_pool_size() -> int:
	return _ui_pool.size()


func get_playing_oneshot_count() -> int:
	var n: int = 0
	for p: AudioStreamPlayer in _sfx_pool:
		if p.playing:
			n += 1
	for p: AudioStreamPlayer in _ui_pool:
		if p.playing:
			n += 1
	return n


func bus_exists(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) >= 0


func _exit_tree() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_stream_cache.clear()
	_procedural_cache.clear()


func _set_duck_extra_db(db: float) -> void:
	_duck_extra_db = db
	_apply_music_bus_volume()


func _apply_all_volumes() -> void:
	_apply_bus_volume(BUS_MASTER, _master_volume, 0.0)
	_apply_music_bus_volume()
	_apply_bus_volume(BUS_SFX, _sfx_volume, 0.0)
	_apply_bus_volume(BUS_UI, _ui_volume, 0.0)
	_apply_bus_volume(BUS_AMBIENCE, _ambience_volume, 0.0)


func _apply_music_bus_volume() -> void:
	_apply_bus_volume(BUS_MUSIC, _music_volume, _duck_extra_db)


func _apply_bus_volume(bus_name: StringName, linear: float, extra_db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.0001:
		AudioServer.set_bus_volume_db(idx, MUTE_DB)
		return
	var base_db: float = float(_BUS_DEFAULT_DB.get(bus_name, 0.0))
	AudioServer.set_bus_volume_db(idx, base_db + linear_to_db(linear) + extra_db)


func _play_oneshot(sound_id: StringName, pool: Array[AudioStreamPlayer], is_ui: bool) -> void:
	if pool.is_empty():
		return
	var stream: AudioStream = _resolve_oneshot_stream(sound_id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_pool_player(pool, is_ui)
	if player.playing:
		player.stop()
	player.stream = stream
	player.volume_db = 0.0
	player.play()


func _next_pool_player(pool: Array[AudioStreamPlayer], is_ui: bool) -> AudioStreamPlayer:
	# Prefer an idle player; otherwise recycle round-robin.
	for p: AudioStreamPlayer in pool:
		if not p.playing:
			if is_ui:
				_ui_cursor = (pool.find(p) + 1) % pool.size()
			else:
				_sfx_cursor = (pool.find(p) + 1) % pool.size()
			return p
	var idx: int = _ui_cursor if is_ui else _sfx_cursor
	if is_ui:
		_ui_cursor = (_ui_cursor + 1) % pool.size()
	else:
		_sfx_cursor = (_sfx_cursor + 1) % pool.size()
	return pool[idx]


func _resolve_oneshot_stream(sound_id: StringName) -> AudioStream:
	var path: String = String(AudioIds.sfx_paths().get(sound_id, ""))
	if path.is_empty():
		_warn_missing(sound_id, "unknown sound id")
		return null
	var stream: AudioStream = _load_stream(path, true)
	if stream != null:
		return stream
	if sound_id in AudioIds.critical_oneshot_ids():
		return _get_procedural_oneshot(sound_id)
	_warn_missing(sound_id, path)
	return null


func _load_stream(path: String, _allow_missing: bool) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is AudioStream:
		_stream_cache[path] = res
		return res as AudioStream
	return null


func _get_procedural_oneshot(sound_id: StringName) -> AudioStream:
	if _procedural_cache.has(sound_id):
		return _procedural_cache[sound_id] as AudioStream
	var stream: AudioStreamWAV = _make_procedural_click(sound_id)
	_procedural_cache[sound_id] = stream
	return stream


func _make_procedural_click(sound_id: StringName) -> AudioStreamWAV:
	# Tiny mono PCM click so headless tests pass before asset import finishes.
	var sample_rate: int = 22050
	var duration: float = 0.045
	var frames: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames * 2)
	var freq: float = 880.0
	if sound_id == AudioIds.UI_BACK:
		freq = 660.0
	elif sound_id == AudioIds.UI_DENIED:
		freq = 220.0
	elif sound_id == AudioIds.UI_PURCHASE:
		freq = 1100.0
	for i: int in frames:
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0 - (float(i) / float(frames))
		var sample: float = sin(TAU * freq * t) * env * 0.35
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, s16)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


func _crossfade_to(stream: AudioStream) -> void:
	var incoming: AudioStreamPlayer = _music_b if _active_music == _music_a else _music_a
	var outgoing: AudioStreamPlayer = _active_music
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	incoming.stop()
	incoming.stream = stream
	if stream is AudioStreamOggVorbis:
		var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
		ogg.loop = true
	elif stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	incoming.volume_db = MUTE_DB
	incoming.play()
	music_start_count += 1
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_SEC)
	if outgoing != null and outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", MUTE_DB, CROSSFADE_SEC)
		_fade_tween.chain().tween_callback(outgoing.stop)
	_active_music = incoming


func _warn_missing(id: StringName, detail: String) -> void:
	if _warned_missing.has(id):
		return
	_warned_missing[id] = true
	push_warning("[AudioDirector] missing audio '%s' (%s) — skipped" % [String(id), detail])
