extends Node
## Independent MODULE 24 Save/Load/Settings QA (not product code).
## Evidence under tmp/m24_qa.
## Headless:
##   Godot --path . --headless --quit-after 120000 res://tmp/m24_qa/m24_indep_qa.tscn
## Windowed shots:
##   Godot --path . --quit-after 0 res://tmp/m24_qa/m24_indep_qa.tscn

const OUT := "res://tmp/m24_qa"
const TAKE_SHOTS := true

var _ss: Node = null
var _gs: Node = null
var _world: Node = null
var _ci: Node = null
var _ad: Node = null
var _failed: int = 0
var _passed: int = 0
var _lines: PackedStringArray = PackedStringArray()
var _title: CanvasLayer = null
var _pause: CanvasLayer = null
var _settings_panel: CanvasLayer = null


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_ss = get_node_or_null("/root/SaveSystem")
	_gs = get_node_or_null("/root/GameState")
	_world = get_node_or_null("/root/World")
	_ci = get_node_or_null("/root/CloneIncremental")
	_ad = get_node_or_null("/root/AudioDirector")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	if _ci != null and _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	if _world != null and _world.has_method("set_auto_reset_on_state_reset_for_test"):
		_world.call("set_auto_reset_on_state_reset_for_test", false)
	await _run()
	print("M24_INDEP_QA: DONE passed=%s failed=%s" % [_passed, _failed])
	for line in _lines:
		print(line)
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/m24_indep_qa_report.txt" % OUT), FileAccess.WRITE)
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
		push_error("[M24_INDEP_QA] FAIL: %s" % label)


func _log(msg: String) -> void:
	_lines.append("INFO: %s" % msg)
	print("M24_INDEP_QA: %s" % msg)


func _run() -> void:
	_test_autoload_order()
	_test_no_module25()
	await _test_title_continue_disabled_when_empty()
	await _test_new_game_apartment()
	await _test_slot_roundtrip_midgame()
	await _test_settings_persist()
	await _test_corrupt_primary_bak()
	await _test_unsupported_schema_edge()
	await _optional_shots()


func _test_autoload_order() -> void:
	_ok(_ss != null, "SaveSystem autoload present")
	_ok(_ad != null, "AudioDirector autoload present")
	var proj_txt: String = FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://project.godot")
	)
	var ss_idx: int = proj_txt.find('SaveSystem="*res://persistence/save_system.gd"')
	var ad_idx: int = proj_txt.find('AudioDirector="*res://audio/audio_director.gd"')
	_ok(ss_idx >= 0 and ad_idx >= 0 and ss_idx < ad_idx, "SaveSystem before AudioDirector in project.godot")
	_ok(SaveTypes.SAVE_SCHEMA_VERSION == 1, "SAVE_SCHEMA_VERSION == 1")


func _test_no_module25() -> void:
	var forbidden: Array[String] = [
		"res://docs/modules/MODULE_25_CONTENT_COMPLETION.md",
		"res://content/module25/",
		"res://game/content_completion/",
	]
	var found: PackedStringArray = PackedStringArray()
	for path: String in forbidden:
		if ResourceLoader.exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)) \
			or FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			found.append(path)
	_ok(found.is_empty(), "no MODULE25 product start (found=%s)" % ",".join(found))
	_ok(
		ResourceLoader.exists("res://ui/frontend/title_menu.tscn"),
		"title_menu.tscn present",
	)
	_ok(
		ResourceLoader.exists("res://ui/frontend/pause_menu.tscn"),
		"pause_menu.tscn present",
	)
	_ok(
		ResourceLoader.exists("res://ui/frontend/settings_panel.tscn"),
		"settings_panel.tscn present",
	)


func _wipe_all_slots() -> void:
	if _ss == null:
		return
	for slot: SaveTypes.Slot in SaveTypes.all_slots():
		_ss.call("delete_slot", slot)
		var primary: String = SaveTypes.slot_path(slot)
		var bak: String = SaveTypes.backup_path(slot)
		if FileAccess.file_exists(primary):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(primary))
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))


func _ensure_title() -> CanvasLayer:
	if _title != null and is_instance_valid(_title):
		return _title
	var packed: PackedScene = load("res://ui/frontend/title_menu.tscn") as PackedScene
	_ok(packed != null, "load title_menu.tscn")
	if packed == null:
		return null
	_title = packed.instantiate() as CanvasLayer
	add_child(_title)
	return _title


func _ensure_pause() -> CanvasLayer:
	if _pause != null and is_instance_valid(_pause):
		return _pause
	var packed: PackedScene = load("res://ui/frontend/pause_menu.tscn") as PackedScene
	_ok(packed != null, "load pause_menu.tscn")
	if packed == null:
		return null
	_pause = packed.instantiate() as CanvasLayer
	add_child(_pause)
	return _pause


func _ensure_settings() -> CanvasLayer:
	if _settings_panel != null and is_instance_valid(_settings_panel):
		return _settings_panel
	var packed: PackedScene = load("res://ui/frontend/settings_panel.tscn") as PackedScene
	_ok(packed != null, "load settings_panel.tscn")
	if packed == null:
		return null
	_settings_panel = packed.instantiate() as CanvasLayer
	add_child(_settings_panel)
	return _settings_panel


func _test_title_continue_disabled_when_empty() -> void:
	_wipe_all_slots()
	await get_tree().process_frame
	_ok(not FrontendSaveApi.has_any_valid_save(), "no valid saves after wipe")
	var title: CanvasLayer = _ensure_title()
	if title == null:
		return
	if title.has_method("show_menu"):
		title.call("show_menu")
	await get_tree().process_frame
	var cont: Button = title.get("_continue_btn") as Button
	_ok(cont != null, "title Continue button exists")
	if cont != null:
		_ok(cont.disabled, "Continue disabled when empty")
	_ok(title.visible, "title menu visible when empty")


func _test_new_game_apartment() -> void:
	if _ss == null or _world == null:
		_ok(false, "new game prerequisites")
		return
	var result: SaveResult = _ss.call("start_new_game") as SaveResult
	_ok(result != null and result.ok, "start_new_game ok")
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	_ok(String(_world.get("current_location_id")) == "apartment", "New Game boots apartment")
	if _title != null and _title.has_method("hide_menu"):
		_title.call("hide_menu")
	await get_tree().process_frame


func _test_slot_roundtrip_midgame() -> void:
	if _ss == null or _gs == null:
		_ok(false, "slot roundtrip prerequisites")
		return
	# Midgame mutation.
	_gs.call("add_money", 777)
	_gs.call("add_authority", 2)
	if _gs.has_method("restore_stage"):
		_gs.call("restore_stage", GameTypes.GameStage.STAGE_2)
	await get_tree().process_frame
	var money_before: int = int(_gs.call("get_money")) if _gs.has_method("get_money") else int(_gs.get("money"))
	var auth_before: int = int(_gs.call("get_authority")) if _gs.has_method("get_authority") else int(_gs.get("authority"))
	var stage_before: int = int(_gs.call("get_stage")) if _gs.has_method("get_stage") else int(_gs.get("stage"))
	_log("midgame money=%s auth=%s stage=%s" % [money_before, auth_before, stage_before])

	var save_r: SaveResult = _ss.call("save_slot", SaveTypes.Slot.MANUAL_1) as SaveResult
	_ok(save_r != null and save_r.ok, "save MANUAL_1 midgame")
	_ok(FileAccess.file_exists(SaveTypes.slot_path(SaveTypes.Slot.MANUAL_1)), "slot_1.json exists")
	var meta: SaveSlotMetadata = _ss.call("get_slot_metadata", SaveTypes.Slot.MANUAL_1) as SaveSlotMetadata
	_ok(meta != null and meta.valid, "slot_1 metadata valid")

	# Mutate away from saved state.
	_gs.call("add_money", 50)
	if _gs.has_method("restore_stage"):
		_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	await get_tree().process_frame
	var money_mutated: int = int(_gs.call("get_money")) if _gs.has_method("get_money") else int(_gs.get("money"))
	_ok(money_mutated != money_before, "state diverged after save")

	var load_r: SaveResult = _ss.call("load_slot", SaveTypes.Slot.MANUAL_1) as SaveResult
	_ok(load_r != null and load_r.ok, "load MANUAL_1 midgame")
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	var money_after: int = int(_gs.call("get_money")) if _gs.has_method("get_money") else int(_gs.get("money"))
	var auth_after: int = int(_gs.call("get_authority")) if _gs.has_method("get_authority") else int(_gs.get("authority"))
	var stage_after: int = int(_gs.call("get_stage")) if _gs.has_method("get_stage") else int(_gs.get("stage"))
	_ok(money_after == money_before, "money roundtrip (%s==%s)" % [money_after, money_before])
	_ok(auth_after == auth_before, "authority roundtrip (%s==%s)" % [auth_after, auth_before])
	_ok(stage_after == stage_before, "stage roundtrip (%s==%s)" % [stage_after, stage_before])

	# Continue should now be enabled on title.
	_ok(FrontendSaveApi.has_any_valid_save(), "has_any_valid_save after slot save")
	var title: CanvasLayer = _ensure_title()
	if title != null:
		if title.has_method("show_menu"):
			title.call("show_menu")
		await get_tree().process_frame
		var cont: Button = title.get("_continue_btn") as Button
		if cont != null:
			_ok(not cont.disabled, "Continue enabled with valid save")
		if title.has_method("hide_menu"):
			title.call("hide_menu")


func _test_settings_persist() -> void:
	if _ss == null:
		_ok(false, "settings prerequisites")
		return
	var original: Dictionary = _ss.call("get_settings") as Dictionary
	var mutated: Dictionary = original.duplicate(true)
	mutated["music"] = 0.37
	mutated["master"] = 0.55
	mutated["fov"] = 82.0
	mutated["ui_scale"] = 1.25
	mutated["mouse_sensitivity"] = 0.18
	var applied: bool = bool(_ss.call("apply_settings", mutated))
	_ok(applied, "apply_settings returns true")
	var saved: bool = bool(_ss.call("save_settings"))
	_ok(saved, "save_settings returns true")
	_ok(FileAccess.file_exists(SaveTypes.SETTINGS_PATH), "user://settings.cfg exists")

	# Force reload from disk.
	_ss.call("load_settings")
	var reloaded: Dictionary = _ss.call("get_settings") as Dictionary
	_ok(is_equal_approx(float(reloaded.get("music", -1.0)), 0.37), "settings music persist")
	_ok(is_equal_approx(float(reloaded.get("master", -1.0)), 0.55), "settings master persist")
	_ok(is_equal_approx(float(reloaded.get("fov", -1.0)), 82.0), "settings fov persist")
	_ok(is_equal_approx(float(reloaded.get("ui_scale", -1.0)), 1.25), "settings ui_scale persist")
	_ok(
		is_equal_approx(float(reloaded.get("mouse_sensitivity", -1.0)), 0.18),
		"settings mouse_sensitivity persist",
	)

	# Settings independent of game save slots: wipe slots must not wipe settings.cfg.
	_wipe_all_slots()
	_ss.call("load_settings")
	var still: Dictionary = _ss.call("get_settings") as Dictionary
	_ok(is_equal_approx(float(still.get("music", -1.0)), 0.37), "settings survive slot wipe")

	# Restore milder values so windowed shots are not oddly muted.
	var restore: Dictionary = original.duplicate(true)
	restore["music"] = 0.8
	restore["master"] = 0.8
	restore["fov"] = 75.0
	restore["ui_scale"] = 1.0
	_ss.call("apply_settings", restore)
	_ss.call("save_settings")


func _test_corrupt_primary_bak() -> void:
	if _ss == null or _gs == null:
		_ok(false, "corrupt bak prerequisites")
		return
	# Ensure midgame state and create primary + bak via two saves.
	var ng: SaveResult = _ss.call("start_new_game") as SaveResult
	_ok(ng != null and ng.ok, "new game before bak test")
	await get_tree().process_frame
	_gs.call("add_money", 321)
	var money_saved: int = int(_gs.call("get_money")) if _gs.has_method("get_money") else int(_gs.get("money"))
	var s1: SaveResult = _ss.call("save_slot", SaveTypes.Slot.MANUAL_2) as SaveResult
	_ok(s1 != null and s1.ok, "first MANUAL_2 save")
	_gs.call("add_money", 10)
	var s2: SaveResult = _ss.call("save_slot", SaveTypes.Slot.MANUAL_2) as SaveResult
	_ok(s2 != null and s2.ok, "second MANUAL_2 save creates bak")
	_ok(FileAccess.file_exists(SaveTypes.backup_path(SaveTypes.Slot.MANUAL_2)), "slot_2.bak.json exists")

	# Corrupt primary.
	var primary: String = SaveTypes.slot_path(SaveTypes.Slot.MANUAL_2)
	var f := FileAccess.open(primary, FileAccess.WRITE)
	_ok(f != null, "open primary for corrupt write")
	if f != null:
		f.store_string("{not-valid-json!!!")
		f.close()

	var load_r: SaveResult = _ss.call("load_slot", SaveTypes.Slot.MANUAL_2) as SaveResult
	_ok(load_r != null and load_r.ok, "load recovers from bak after corrupt primary")
	if load_r != null:
		_ok(load_r.recovered_from_backup, "recovered_from_backup flag set")
	await get_tree().process_frame
	var money_now: int = int(_gs.call("get_money")) if _gs.has_method("get_money") else int(_gs.get("money"))
	_ok(
		money_now == money_saved or money_now == money_saved + 10,
		"bak money plausible (got=%s expected~%s/+10)" % [money_now, money_saved],
	)


func _test_unsupported_schema_edge() -> void:
	if _ss == null:
		return
	var path: String = SaveTypes.slot_path(SaveTypes.Slot.MANUAL_3)
	var payload := {
		"schema_version": 99,
		"saved_at_unix": 1,
		"game": {},
		"world": {},
		"runtime": {},
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	_ok(f != null, "write unsupported schema file")
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
	# Remove bak so recovery cannot mask rejection.
	var bak: String = SaveTypes.backup_path(SaveTypes.Slot.MANUAL_3)
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
	var load_r: SaveResult = _ss.call("load_slot", SaveTypes.Slot.MANUAL_3) as SaveResult
	_ok(load_r != null and not load_r.ok, "unsupported schema rejected")
	if load_r != null:
		_ok(load_r.error == SaveTypes.ErrorCode.UNSUPPORTED_SCHEMA, "error UNSUPPORTED_SCHEMA")


func _optional_shots() -> void:
	if not TAKE_SHOTS:
		_log("shots skipped (TAKE_SHOTS=false)")
		return
	if DisplayServer.get_name() == "headless" or OS.has_feature("headless"):
		_log("shots skipped (headless display)")
		return

	# 01 title menu
	_wipe_all_slots()
	if _ss != null:
		_ss.call("return_to_title")
	await get_tree().process_frame
	var title: CanvasLayer = _ensure_title()
	if title != null and title.has_method("show_menu"):
		title.call("show_menu")
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await _shot("%s/01_title_menu.png" % OUT)
	_ok(title != null and title.visible, "shot context title menu")

	# 02 settings panel from title
	var settings: CanvasLayer = _ensure_settings()
	if settings != null and settings.has_method("open"):
		settings.call("open", Callable())
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await _shot("%s/02_settings.png" % OUT)
	_ok(settings != null and settings.visible, "shot context settings")
	if settings != null and settings.has_method("close"):
		settings.call("close", false)
	if title != null and title.has_method("hide_menu"):
		title.call("hide_menu")
	await get_tree().process_frame

	# 03 pause menu during gameplay
	if _ss != null:
		var ng: SaveResult = _ss.call("start_new_game") as SaveResult
		_ok(ng != null and ng.ok, "new game for pause shot")
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var pause: CanvasLayer = _ensure_pause()
	if pause != null and pause.has_method("open_from_pause"):
		pause.call("open_from_pause")
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await _shot("%s/03_pause_menu.png" % OUT)
	_ok(pause != null and pause.visible, "shot context pause menu")
	if pause != null and pause.has_method("hide_menu"):
		pause.call("hide_menu")


func _shot(path: String) -> void:
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
