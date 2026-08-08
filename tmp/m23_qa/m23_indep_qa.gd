extends Node
## Independent MODULE 23 Audio/Animation/Feedback QA (not product code).
## Evidence under tmp/m23_qa.
## Headless:
##   Godot --path . --headless --quit-after 120 res://tmp/m23_qa/m23_indep_qa.tscn
## Windowed shots:
##   Godot --path . --quit-after 180 res://tmp/m23_qa/m23_indep_qa.tscn

const OUT := "res://tmp/m23_qa"
const TAKE_SHOTS := true

var _world: Node = null
var _gs: Node = null
var _ad: Node = null
var _story: Node = null
var _ci: Node = null
var _fc: Node = null
var _failed: int = 0
var _passed: int = 0
var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_world = get_node_or_null("/root/World")
	_gs = get_node_or_null("/root/GameState")
	_ad = get_node_or_null("/root/AudioDirector")
	_story = get_node_or_null("/root/Story")
	_ci = get_node_or_null("/root/CloneIncremental")
	_fc = get_node_or_null("/root/FirstClone")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	if _ci != null and _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	if _world != null and _world.has_method("set_auto_reset_on_state_reset_for_test"):
		_world.call("set_auto_reset_on_state_reset_for_test", false)
	await _run()
	print("M23_INDEP_QA: DONE passed=%s failed=%s" % [_passed, _failed])
	for line in _lines:
		print(line)
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/m23_indep_qa_report.txt" % OUT), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
	await get_tree().create_timer(0.35).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_lines.append("PASS: %s" % label)
	else:
		_failed += 1
		_lines.append("FAIL: %s" % label)
		push_error("[M23_INDEP_QA] FAIL: %s" % label)


func _log(msg: String) -> void:
	_lines.append("INFO: %s" % msg)
	print("M23_INDEP_QA: %s" % msg)


func _run() -> void:
	_test_buses()
	_test_stage_music()
	await _test_same_state_travel()
	await _test_duck_restore()
	await _test_money_tick_no_sfx()
	_test_camera_scale_zero()
	_test_no_donor_runtime_paths()
	_test_no_module24_settings()
	await _optional_shots()


func _test_buses() -> void:
	_ok(_ad != null, "AudioDirector autoload present")
	if _ad == null:
		return
	for bus_name: String in ["Master", "Music", "SFX", "UI", "Ambience"]:
		_ok(bool(_ad.call("bus_exists", StringName(bus_name))), "bus %s exists" % bus_name)
	_ok(AudioServer.get_bus_index("Master") >= 0, "AudioServer Master index")
	_ok(AudioServer.get_bus_index("Music") >= 0, "AudioServer Music index")
	_ok(AudioServer.get_bus_index("SFX") >= 0, "AudioServer SFX index")
	_ok(AudioServer.get_bus_index("UI") >= 0, "AudioServer UI index")
	_ok(AudioServer.get_bus_index("Ambience") >= 0, "AudioServer Ambience index")


func _test_stage_music() -> void:
	if _ad == null:
		return
	_assert_stage_maps(GameTypes.GameStage.PROLOGUE, AudioIds.MUSIC_MANUAL, "stage PROLOGUE→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_1, AudioIds.MUSIC_MANUAL, "stage STAGE_1→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_2, AudioIds.MUSIC_MANUAL, "stage STAGE_2→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_3, AudioIds.MUSIC_MANUAL, "stage STAGE_3→MANUAL")
	_assert_stage_maps(GameTypes.GameStage.STAGE_4, AudioIds.MUSIC_MEDIA, "stage STAGE_4→MEDIA")
	_assert_stage_maps(GameTypes.GameStage.STAGE_5, AudioIds.MUSIC_CLONE, "stage STAGE_5→CLONE")
	_assert_stage_maps(GameTypes.GameStage.STAGE_6, AudioIds.MUSIC_CLONE, "stage STAGE_6→CLONE")
	_assert_stage_maps(GameTypes.GameStage.FINALE, AudioIds.MUSIC_FINAL, "stage FINALE→FINAL")
	for state: StringName in [AudioIds.MUSIC_MANUAL, AudioIds.MUSIC_MEDIA, AudioIds.MUSIC_CLONE, AudioIds.MUSIC_FINAL]:
		var path: String = String(AudioIds.music_paths().get(state, ""))
		_ok(not path.is_empty() and ResourceLoader.exists(path), "music asset exists for %s (%s)" % [String(state), path])


func _assert_stage_maps(stage: int, expected: StringName, label: String) -> void:
	_ad.call("notify_stage", stage)
	_ok(StringName(_ad.call("get_music_state")) == expected, label)


func _test_same_state_travel() -> void:
	if _ad == null or _gs == null or _world == null:
		_ok(false, "same-state travel prerequisites")
		return
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(int(_world.call("reset_to_start")) == 0, "reset_to_start SUCCESS")
	_ad.call("set_music_state", AudioIds.MUSIC_MANUAL)
	await get_tree().process_frame
	var before: int = int(_ad.get("music_start_count"))
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_1)
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_2)
	_ad.call("notify_stage", GameTypes.GameStage.STAGE_3)
	if _world.has_method("request_travel"):
		_world.call("request_travel", &"apartment", &"spawn_default")
	await get_tree().process_frame
	var after: int = int(_ad.get("music_start_count"))
	_ok(after == before, "same-state travel no music restart (before=%s after=%s)" % [before, after])


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
	_ok(ducked <= baseline - 3.5, "duck lowers Music bus (base=%.2f ducked=%.2f)" % [baseline, ducked])
	_ad.call("duck_for_minigame", false)
	await get_tree().create_timer(0.45).timeout
	var restored: float = AudioServer.get_bus_volume_db(music_idx)
	_ok(absf(restored - baseline) < 0.15, "duck restore no drift (base=%.2f restored=%.2f)" % [baseline, restored])


func _test_money_tick_no_sfx() -> void:
	if _ad == null or _gs == null or _world == null:
		_ok(false, "money tick prerequisites")
		return
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_world.call("reset_to_start")
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_stop_oneshot_pools()
	await get_tree().process_frame
	# Sanity: detector sees intentional play.
	_ad.call("play_sfx", AudioIds.UI_CLICK)
	await get_tree().process_frame
	var detected: int = _count_oneshot_playing()
	var detected_api: int = int(_ad.call("get_playing_oneshot_count"))
	_ok(detected >= 1 or detected_api >= 1, "oneshot detector sanity (pool=%s api=%s)" % [detected, detected_api])
	_stop_oneshot_pools()
	await get_tree().process_frame
	_ok(_count_oneshot_playing() == 0, "oneshot pools silenced before money ticks")
	for _i: int in 100:
		_gs.call("add_money", 1)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	var after_play: int = _count_oneshot_playing()
	var after_api: int = int(_ad.call("get_playing_oneshot_count"))
	_ok(after_play == 0 and after_api == 0, "100 money ticks → 0 unintended SFX (pool=%s api=%s)" % [after_play, after_api])


func _stop_oneshot_pools() -> void:
	if _ad == null:
		return
	for child in _ad.get_children():
		if child is AudioStreamPlayer:
			var n: String = String(child.name)
			if n.begins_with("Sfx_") or n.begins_with("Ui_"):
				(child as AudioStreamPlayer).stop()


func _count_oneshot_playing() -> int:
	if _ad == null:
		return 0
	var n: int = 0
	for child in _ad.get_children():
		if child is AudioStreamPlayer:
			var nm: String = String(child.name)
			if (nm.begins_with("Sfx_") or nm.begins_with("Ui_")) and (child as AudioStreamPlayer).playing:
				n += 1
	return n


func _test_camera_scale_zero() -> void:
	var cam := Camera3D.new()
	cam.name = "M23QaCam"
	add_child(cam)
	var fb: CameraFeedback = CameraFeedback.new()
	fb.name = "CameraFeedback"
	cam.add_child(fb)
	fb.bind_camera(cam)
	fb.set_feedback_scale(0.0)
	_ok(is_equal_approx(fb.get_feedback_scale(), 0.0), "CameraFeedback scale seam 0")
	fb.impulse_rotation(3.0, 0.2)
	fb.shake(0.05, 0.2)
	fb.fov_pulse(2.0, 0.2)
	fb._process(0.016)
	_ok(
		is_zero_approx(fb.debug_last_rot_deg)
		and is_zero_approx(fb.debug_last_shake_m)
		and is_zero_approx(fb.debug_last_fov_deg)
		and not fb.is_effect_active(),
		"CameraFeedback scale0 → zero motion"
	)
	var suite_ok: bool = CameraFeedback.run_self_test()
	_ok(suite_ok, "CameraFeedback.run_self_test()")
	cam.queue_free()


func _test_no_donor_runtime_paths() -> void:
	var donor_token := "date_factory_legacy"
	var bad: PackedStringArray = PackedStringArray()
	var music: Dictionary = AudioIds.music_paths()
	for k in music.keys():
		var p: String = String(music[k])
		if p.contains(donor_token) or p.contains("../"):
			bad.append("music:%s=%s" % [String(k), p])
	var sfx: Dictionary = AudioIds.sfx_paths()
	for k in sfx.keys():
		var p2: String = String(sfx[k])
		if p2.contains(donor_token) or p2.begins_with(".."):
			bad.append("sfx:%s=%s" % [String(k), p2])
	_scan_dir_for_donor("res://assets/audio", donor_token, bad)
	_ok(bad.is_empty(), "no runtime donor path in audio catalog (bad=%s)" % ",".join(bad))


func _scan_dir_for_donor(res_dir: String, token: String, bad: PackedStringArray) -> void:
	var abs_dir: String = ProjectSettings.globalize_path(res_dir)
	var da := DirAccess.open(abs_dir)
	if da == null:
		return
	da.list_dir_begin()
	var name: String = da.get_next()
	while name != "":
		if name.begins_with("."):
			name = da.get_next()
			continue
		var child_abs: String = abs_dir.path_join(name)
		var child_res: String = res_dir.path_join(name)
		if da.current_is_dir():
			_scan_dir_for_donor(child_res, token, bad)
		elif name.ends_with(".import"):
			var txt: String = FileAccess.get_file_as_string(child_abs)
			if txt.contains(token) or txt.contains("../date_factory"):
				bad.append(child_res)
		name = da.get_next()
	da.list_dir_end()


func _test_no_module24_settings() -> void:
	var forbidden: Array[String] = [
		"res://ui/settings/settings_menu.tscn",
		"res://ui/settings/settings_menu.gd",
		"res://game/save/save_manager.gd",
		"res://game/save/save_service.gd",
		"res://game/settings/settings_store.gd",
		"res://game/settings/settings_persistence.gd",
		"res://docs/modules/MODULE_24_SAVE_LOAD_SETTINGS.md",
	]
	var found: PackedStringArray = PackedStringArray()
	for path: String in forbidden:
		if ResourceLoader.exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			found.append(path)
	_ok(found.is_empty(), "no MODULE24 settings/save product files (found=%s)" % ",".join(found))
	if _ad != null:
		_ok(_ad.has_method("set_master_volume"), "volume seam set_master_volume exposed")
		_ok(_ad.has_method("set_music_volume"), "volume seam set_music_volume exposed")
		_ok(_ad.has_method("set_sfx_volume"), "volume seam set_sfx_volume exposed")
		_ok(_ad.has_method("set_ui_volume"), "volume seam set_ui_volume exposed")
		_ok(_ad.has_method("set_ambience_volume"), "volume seam set_ambience_volume exposed")


func _optional_shots() -> void:
	if not TAKE_SHOTS:
		_log("shots skipped (TAKE_SHOTS=false)")
		return
	if _world == null or _gs == null:
		_log("shots skipped (no World/GameState)")
		return
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_world.call("reset_to_start")
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	await _shot_player_view("%s/01_apartment_hud.png" % OUT)
	_ok(String(_world.get("current_location_id")) == "apartment", "shot context apartment")

	# Lab seed: STAGE_5 + scientist conquered + overload recognized
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("mark_girl_conquered", &"girl_scientist")
	if _gs.has_method("mark_dating_overload_problem_recognized"):
		_gs.call("mark_dating_overload_problem_recognized")
	await get_tree().process_frame
	var lab_unlocked: bool = _story != null and bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY))
	_ok(lab_unlocked, "LABORATORY unlocked for lab shot")
	var lab_code: int = int(_world.call("request_travel", &"laboratory", &"spawn_default"))
	if lab_code == 0:
		await get_tree().process_frame
		await get_tree().create_timer(0.4).timeout
		await _shot_player_view("%s/02_lab.png" % OUT)
		_ok(String(_world.get("current_location_id")) == "laboratory", "shot context laboratory")
	else:
		_log("lab travel not available code=%s — skipping lab shot" % lab_code)
		_ok(false, "travel laboratory for shot")

	# Final location beacon
	_seed_finale_for_shot()
	await get_tree().process_frame
	var fin_code: int = int(_world.call("request_travel", &"final_location", &"spawn_default"))
	if fin_code == 0:
		await get_tree().process_frame
		await get_tree().create_timer(0.45).timeout
		await _shot_player_view("%s/03_final_location_beacon.png" % OUT)
		_ok(String(_world.get("current_location_id")) == "final_location", "shot context final_location")
	else:
		_log("final_location travel failed code=%s" % fin_code)
		_ok(false, "final_location travel for shot")


func _seed_finale_for_shot() -> void:
	if _gs == null:
		return
	_gs.call("restore_stage", GameTypes.GameStage.FINALE)
	if _gs.has_method("set_world_reach"):
		_gs.call("set_world_reach", 100)
	# Reach/feature may already unlock via stage; ensure contacts not required for travel.


func _shot_player_view(path: String) -> void:
	var player: Node = null
	if _world != null and _world.has_method("get_player"):
		player = _world.call("get_player") as Node
	var cam: Camera3D = null
	if player != null:
		cam = player.find_child("Camera3D", true, false) as Camera3D
	if cam == null:
		cam = get_viewport().get_camera_3d()
	if cam == null:
		cam = Camera3D.new()
		cam.name = "M23QaCam"
		add_child(cam)
		cam.current = true
		cam.global_position = Vector3(0.0, 1.6, 2.5)
		cam.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)
	elif not cam.current:
		cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_log("shot failed no viewport texture %s" % path)
		return
	var img: Image = tex.get_image()
	if img == null:
		_log("shot failed null image %s" % path)
		return
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: Error = img.save_png(abs_path)
	_log("shot %s err=%s size=%sx%s" % [path, err, img.get_width(), img.get_height()])
