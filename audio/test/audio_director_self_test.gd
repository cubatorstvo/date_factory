extends Node
## MODULE 23 AudioDirector core self-test (§3–9, §35–39).
## Run: Godot --path . --headless res://audio/test/audio_director_self_test.tscn


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _ad: Node = null
var _gs: Node = null


func _ready() -> void:
	_ad = get_node_or_null("/root/AudioDirector")
	_gs = get_node_or_null("/root/GameState")
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		print("MODULE_23_AUDIO_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_23_AUDIO_TEST PASS: %s" % label)
	else:
		print("MODULE_23_AUDIO_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_23_AUDIO_TEST] FAIL: %s" % label)
		print("MODULE_23_AUDIO_TEST FAIL: %s" % label)


func _run_all() -> void:
	_test_autoload_and_buses()
	_test_stage_music_mapping()
	await _test_same_state_no_restart()
	_test_volume_mute()
	_test_pool_bound()
	_test_missing_id_safe()
	await _test_duck_restore()


func _test_autoload_and_buses() -> void:
	_ok(_ad != null, "AudioDirector autoload present")
	if _ad == null:
		return
	_ok(bool(_ad.call("bus_exists", &"Master")), "bus Master")
	_ok(bool(_ad.call("bus_exists", &"Music")), "bus Music")
	_ok(bool(_ad.call("bus_exists", &"SFX")), "bus SFX")
	_ok(bool(_ad.call("bus_exists", &"UI")), "bus UI")
	_ok(bool(_ad.call("bus_exists", &"Ambience")), "bus Ambience")
	_ok(int(_ad.call("get_sfx_pool_size")) == 8, "sfx pool size 8")
	_ok(int(_ad.call("get_ui_pool_size")) == 4, "ui pool size 4")


func _test_stage_music_mapping() -> void:
	if _ad == null:
		return
	_ad.call("set_music_state", AudioIds.MUSIC_MANUAL)
	_ok(StringName(_ad.call("get_music_state")) == AudioIds.MUSIC_MANUAL, "direct MANUAL")

	_assert_stage_maps(GameTypes.GameStage.PROLOGUE, AudioIds.MUSIC_MANUAL, "PROLOGUE→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_1, AudioIds.MUSIC_MANUAL, "STAGE1→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_2, AudioIds.MUSIC_MANUAL, "STAGE2→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_3, AudioIds.MUSIC_MANUAL, "STAGE3→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_4, AudioIds.MUSIC_MEDIA, "STAGE4→MEDIA")
	_assert_stage_maps(GameTypes.GameStage.STAGE_5, AudioIds.MUSIC_CLONE, "STAGE5→CLONE")
	_assert_stage_maps(GameTypes.GameStage.STAGE_6, AudioIds.MUSIC_CLONE, "STAGE6→CLONE")
	_assert_stage_maps(GameTypes.GameStage.FINALE, AudioIds.MUSIC_FINAL, "FINALE→FINAL")


func _assert_stage_maps(stage: int, expected: StringName, label: String) -> void:
	_ad.call("notify_stage", stage)
	_ok(StringName(_ad.call("get_music_state")) == expected, label)


func _test_same_state_no_restart() -> void:
	if _ad == null:
		return
	_ad.call("set_music_state", AudioIds.MUSIC_MANUAL)
	await get_tree().process_frame
	var before: int = int(_ad.get("music_start_count"))
	_ad.call("set_music_state", AudioIds.MUSIC_MANUAL)
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_1)
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_2)
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_3)
	var after: int = int(_ad.get("music_start_count"))
	_ok(after == before, "same-state travel does not restart music")

	# Cross-state must restart (when asset exists) or at least change state.
	_ad.call("set_music_state", AudioIds.MUSIC_MEDIA)
	_ok(StringName(_ad.call("get_music_state")) == AudioIds.MUSIC_MEDIA, "cross-state MEDIA applied")


func _test_volume_mute() -> void:
	if _ad == null:
		return
	_ad.call("set_master_volume", 1.0)
	_ad.call("set_music_volume", 1.0)
	_ad.call("set_sfx_volume", 1.0)
	_ad.call("set_ui_volume", 1.0)
	_ad.call("set_ambience_volume", 1.0)
	_ok(is_equal_approx(float(_ad.call("get_master_volume")), 1.0), "master volume getter")
	_ad.call("set_master_volume", 0.0)
	var master_idx: int = AudioServer.get_bus_index("Master")
	_ok(master_idx >= 0, "master bus index")
	if master_idx >= 0:
		_ok(AudioServer.get_bus_volume_db(master_idx) <= -79.0, "master mute ≈ -80dB")
	_ad.call("set_music_volume", 0.0)
	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		_ok(AudioServer.get_bus_volume_db(music_idx) <= -79.0, "music mute ≈ -80dB")
	_ad.call("set_master_volume", 1.0)
	_ad.call("set_music_volume", 1.0)
	_ok(is_equal_approx(float(_ad.call("get_sfx_volume")), 1.0), "sfx volume restored seam")


func _test_pool_bound() -> void:
	if _ad == null:
		return
	for _i: int in 40:
		_ad.call("play_sfx", AudioIds.UI_CLICK)
		_ad.call("play_ui", AudioIds.UI_CLICK)
	var playing: int = int(_ad.call("get_playing_oneshot_count"))
	_ok(playing <= 12, "pool bound ≤12 simultaneous oneshots (got %s)" % playing)
	_ok(int(_ad.call("get_sfx_pool_size")) == 8, "sfx pool still 8 after spam")
	_ok(int(_ad.call("get_ui_pool_size")) == 4, "ui pool still 4 after spam")


func _test_missing_id_safe() -> void:
	if _ad == null:
		return
	# Unknown id must not crash.
	_ad.call("play_sfx", &"definitely_missing_sound_xyz")
	_ad.call("play_ui", &"definitely_missing_ui_xyz")
	_ad.call("set_music_state", &"NOT_A_STATE")
	_ok(true, "missing id / state skipped safely")


func _test_duck_restore() -> void:
	if _ad == null:
		return
	_ad.call("set_music_volume", 1.0)
	_ad.call("duck_for_minigame", false)
	await get_tree().create_timer(0.45).timeout
	var music_idx: int = AudioServer.get_bus_index("Music")
	_ok(music_idx >= 0, "music bus for duck")
	if music_idx < 0:
		return
	var baseline: float = AudioServer.get_bus_volume_db(music_idx)
	_ad.call("duck_for_minigame", true)
	await get_tree().create_timer(0.08).timeout
	var ducked: float = AudioServer.get_bus_volume_db(music_idx)
	_ok(ducked <= baseline - 3.5, "minigame duck ≈ -4dB (base=%.2f ducked=%.2f)" % [baseline, ducked])
	_ad.call("duck_for_minigame", false)
	await get_tree().create_timer(0.45).timeout
	var restored: float = AudioServer.get_bus_volume_db(music_idx)
	_ok(is_equal_approx(restored, baseline) or absf(restored - baseline) < 0.15, "duck restore no drift (base=%.2f restored=%.2f)" % [baseline, restored])
