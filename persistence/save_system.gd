extends Node
## SaveSystem — slots, autosave, settings (MODULE 24).
## Autoload name: SaveSystem. Registered before AudioDirector.

signal save_started(slot: int)
signal save_completed(slot: int)
signal save_failed(slot: int, error: int)
signal load_started(slot: int)
signal load_completed(slot: int)
signal load_failed(slot: int, error: int)
signal settings_applied()
signal autosave_completed()

var _is_restoring: bool = false
var _autosave_pending: bool = false
var _autosave_timer: Timer = null
var _settings: Dictionary = {}
var _had_clones: bool = false
var _signals_hooked: bool = false


func _ready() -> void:
	_ensure_saves_dir()
	_settings = _default_settings()
	load_settings()
	_apply_boot_settings()
	_setup_autosave_timer()
	call_deferred("_hook_autosave_signals")
	call_deferred("_apply_audio_settings")
	call_deferred("_apply_player_settings")
	DfLog.info("MODULE_24", "SaveSystem ready")


func is_restoring() -> bool:
	return _is_restoring


func get_settings() -> Dictionary:
	return _settings.duplicate(true)


func get_tutorial_seen_ids() -> Array:
	var seen: Variant = _settings.get("tutorial_seen", [])
	if seen is Array:
		return (seen as Array).duplicate()
	return []


func set_tutorial_seen_ids(ids: Array) -> void:
	var out: Array = []
	for item in ids:
		out.append(str(item))
	_settings["tutorial_seen"] = out


func can_save_now() -> bool:
	if _is_restoring:
		return false
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		return false
	if bool(world.call("is_busy")):
		return false
	var player: Node = null
	if world.has_method("get_player"):
		player = world.call("get_player") as Node
	if player == null or not is_instance_valid(player):
		return false
	if not player.has_method("get_control_mode"):
		return false
	var mode: Variant = player.call("get_control_mode")
	var mode_i: int = int(mode)
	# Pause menu may save while PAUSED; block MODAL_UI / MINIGAME only.
	if (
		mode_i != int(PlayerController.ControlMode.GAMEPLAY)
		and mode_i != int(PlayerController.ControlMode.PAUSED)
	):
		return false
	var dating: Node = get_node_or_null("/root/DatingCore")
	if dating != null and dating.has_method("is_date_active") and bool(dating.call("is_date_active")):
		return false
	var rivals: Node = get_node_or_null("/root/RivalEncounters")
	if rivals != null and rivals.has_method("has_active_encounter") and bool(rivals.call("has_active_encounter")):
		return false
	var rival_runner: Node = get_node_or_null("/root/RivalCompetitionRunner")
	if rival_runner != null and rival_runner.has_method("is_busy") and bool(rival_runner.call("is_busy")):
		return false
	var discovery: Node = get_node_or_null("/root/GirlDiscovery")
	if discovery != null and discovery.has_method("has_active_attempt") and bool(discovery.call("has_active_attempt")):
		return false
	var first_clone: Node = get_node_or_null("/root/FirstClone")
	if first_clone != null and first_clone.has_method("is_sequence_active") and bool(first_clone.call("is_sequence_active")):
		return false
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("has_active_photo_session") and bool(media.call("has_active_photo_session")):
		return false
	if _is_final_date_attempt_active():
		return false
	return true


func get_slot_metadata(slot: SaveTypes.Slot) -> SaveSlotMetadata:
	var meta: SaveSlotMetadata = SaveSlotMetadata.empty(slot)
	var path: String = SaveTypes.slot_path(slot)
	if not FileAccess.file_exists(path):
		var bak: String = SaveTypes.backup_path(slot)
		if FileAccess.file_exists(bak):
			var bak_parsed: Dictionary = _read_validate_payload(bak)
			if bool(bak_parsed.get("ok", false)):
				_fill_metadata_from_payload(meta, bak_parsed["payload"] as Dictionary)
				meta.exists = true
				meta.valid = true
				meta.recovered_from_backup = true
				return meta
		meta.exists = false
		meta.valid = false
		meta.error = SaveTypes.ErrorCode.FILE_NOT_FOUND
		return meta
	var parsed: Dictionary = _read_validate_payload(path)
	meta.exists = true
	if not bool(parsed.get("ok", false)):
		var bak2: String = SaveTypes.backup_path(slot)
		if FileAccess.file_exists(bak2):
			var bak_parsed2: Dictionary = _read_validate_payload(bak2)
			if bool(bak_parsed2.get("ok", false)):
				_fill_metadata_from_payload(meta, bak_parsed2["payload"] as Dictionary)
				meta.valid = true
				meta.recovered_from_backup = true
				return meta
		meta.valid = false
		meta.error = parsed.get("error", SaveTypes.ErrorCode.VALIDATION_FAILED) as SaveTypes.ErrorCode
		meta.message = str(parsed.get("message", ""))
		return meta
	_fill_metadata_from_payload(meta, parsed["payload"] as Dictionary)
	meta.valid = true
	return meta


func save_slot(slot: SaveTypes.Slot) -> SaveResult:
	if slot != SaveTypes.Slot.AUTOSAVE and not can_save_now():
		var bad: SaveResult = SaveResult.fail(slot, SaveTypes.ErrorCode.UNSAFE_STATE, "Сейчас сохранить игру нельзя.")
		save_failed.emit(int(slot), int(bad.error))
		return bad
	if slot == SaveTypes.Slot.AUTOSAVE and _is_restoring:
		return SaveResult.fail(slot, SaveTypes.ErrorCode.BUSY, "restoring")
	save_started.emit(int(slot))
	var payload: Dictionary = _build_save_payload()
	var text: String = JSON.stringify(payload)
	if text.strip_edges() == "":
		var fail_json: SaveResult = SaveResult.fail(slot, SaveTypes.ErrorCode.JSON_INVALID, "stringify failed")
		save_failed.emit(int(slot), int(fail_json.error))
		return fail_json
	_ensure_saves_dir()
	var path: String = SaveTypes.slot_path(slot)
	if not _atomic_write_text(path, text, SaveTypes.backup_path(slot)):
		var fail_write: SaveResult = SaveResult.fail(slot, SaveTypes.ErrorCode.WRITE_FAILED, "write failed")
		save_failed.emit(int(slot), int(fail_write.error))
		return fail_write
	var ok_result: SaveResult = SaveResult.success(slot, "saved")
	save_completed.emit(int(slot))
	if slot == SaveTypes.Slot.AUTOSAVE:
		autosave_completed.emit()
	return ok_result


func autosave() -> SaveResult:
	if _is_restoring:
		return SaveResult.fail(SaveTypes.Slot.AUTOSAVE, SaveTypes.ErrorCode.BUSY, "restoring")
	if not can_save_now():
		return SaveResult.fail(SaveTypes.Slot.AUTOSAVE, SaveTypes.ErrorCode.UNSAFE_STATE, "unsafe")
	return save_slot(SaveTypes.Slot.AUTOSAVE)


func load_slot(slot: SaveTypes.Slot) -> SaveResult:
	load_started.emit(int(slot))
	var path: String = SaveTypes.slot_path(slot)
	var bak_path: String = SaveTypes.backup_path(slot)
	var recovered: bool = false
	var parsed: Dictionary = {}
	if FileAccess.file_exists(path):
		parsed = _read_validate_payload(path)
		if not bool(parsed.get("ok", false)):
			if FileAccess.file_exists(bak_path):
				var bak_parsed: Dictionary = _read_validate_payload(bak_path)
				if bool(bak_parsed.get("ok", false)):
					parsed = bak_parsed
					recovered = true
				else:
					var fail_v: SaveResult = SaveResult.fail(
						slot,
						parsed.get("error", SaveTypes.ErrorCode.VALIDATION_FAILED) as SaveTypes.ErrorCode,
						str(parsed.get("message", "corrupt")),
					)
					load_failed.emit(int(slot), int(fail_v.error))
					return fail_v
			else:
				var fail_v2: SaveResult = SaveResult.fail(
					slot,
					parsed.get("error", SaveTypes.ErrorCode.VALIDATION_FAILED) as SaveTypes.ErrorCode,
					str(parsed.get("message", "corrupt")),
				)
				load_failed.emit(int(slot), int(fail_v2.error))
				return fail_v2
	elif FileAccess.file_exists(bak_path):
		parsed = _read_validate_payload(bak_path)
		if bool(parsed.get("ok", false)):
			recovered = true
		else:
			var fail_bak: SaveResult = SaveResult.fail(
				slot,
				parsed.get("error", SaveTypes.ErrorCode.VALIDATION_FAILED) as SaveTypes.ErrorCode,
				str(parsed.get("message", "backup corrupt")),
			)
			load_failed.emit(int(slot), int(fail_bak.error))
			return fail_bak
	else:
		var miss: SaveResult = SaveResult.fail(slot, SaveTypes.ErrorCode.FILE_NOT_FOUND, "missing")
		load_failed.emit(int(slot), int(miss.error))
		return miss
	if not bool(parsed.get("ok", false)):
		var fail_p: SaveResult = SaveResult.fail(
			slot,
			parsed.get("error", SaveTypes.ErrorCode.VALIDATION_FAILED) as SaveTypes.ErrorCode,
			str(parsed.get("message", "invalid")),
		)
		load_failed.emit(int(slot), int(fail_p.error))
		return fail_p
	var payload: Dictionary = parsed["payload"] as Dictionary
	if not _restore_validated_payload(payload):
		var fail_r: SaveResult = SaveResult.fail(slot, SaveTypes.ErrorCode.RESTORE_FAILED, "restore failed")
		load_failed.emit(int(slot), int(fail_r.error))
		return fail_r
	var ok_r: SaveResult = SaveResult.success(slot, "loaded", recovered)
	load_completed.emit(int(slot))
	return ok_r


func delete_slot(slot: SaveTypes.Slot) -> SaveResult:
	var path: String = SaveTypes.slot_path(slot)
	var bak: String = SaveTypes.backup_path(slot)
	var any: bool = false
	if FileAccess.file_exists(path):
		var err: Error = DirAccess.remove_absolute(path)
		if err != OK:
			return SaveResult.fail(slot, SaveTypes.ErrorCode.WRITE_FAILED, "delete failed")
		any = true
	if FileAccess.file_exists(bak):
		var err2: Error = DirAccess.remove_absolute(bak)
		if err2 != OK:
			return SaveResult.fail(slot, SaveTypes.ErrorCode.WRITE_FAILED, "delete bak failed")
		any = true
	if not any:
		return SaveResult.fail(slot, SaveTypes.ErrorCode.FILE_NOT_FOUND, "missing")
	return SaveResult.success(slot, "deleted")


func continue_latest() -> SaveResult:
	var best_slot: SaveTypes.Slot = SaveTypes.Slot.AUTOSAVE
	var best_ts: int = -1
	var found: bool = false
	for slot in SaveTypes.all_slots():
		var meta: SaveSlotMetadata = get_slot_metadata(slot)
		if not meta.valid:
			continue
		if meta.saved_at_unix >= best_ts:
			best_ts = meta.saved_at_unix
			best_slot = slot
			found = true
	if not found:
		return SaveResult.fail(SaveTypes.Slot.AUTOSAVE, SaveTypes.ErrorCode.FILE_NOT_FOUND, "no saves")
	return load_slot(best_slot)


func start_new_game() -> SaveResult:
	_is_restoring = true
	_cancel_autosave()
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
		world.call("suppress_auto_reset_on_state_reset", true)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("reset_for_new_game"):
		gs.call("reset_for_new_game")
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_method("restore_day"):
		day.call("restore_day", 1)
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("restore_runtime_state"):
		ci.call(
			"restore_runtime_state",
			{
				"production_elapsed_seconds": 0.0,
				"money_fraction": 0.0,
				"date_fraction": 0.0,
			},
		)
	_sync_services_after_load()
	if world != null and world.has_method("begin_new_game_boot"):
		var travel: Variant = world.call("begin_new_game_boot")
		if int(travel) != int(WorldTypes.WorldTravelResult.SUCCESS):
			_is_restoring = false
			if world.has_method("suppress_auto_reset_on_state_reset"):
				world.call("suppress_auto_reset_on_state_reset", false)
			return SaveResult.fail(
				SaveTypes.Slot.AUTOSAVE,
				SaveTypes.ErrorCode.RESTORE_FAILED,
				"new game boot failed",
			)
	_apply_player_settings()
	_had_clones = false
	_is_restoring = false
	if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
		world.call("suppress_auto_reset_on_state_reset", false)
	return SaveResult.success(SaveTypes.Slot.AUTOSAVE, "new_game")


func return_to_title() -> SaveResult:
	_cancel_autosave()
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("prepare_for_title"):
		world.call("prepare_for_title")
	return SaveResult.success(SaveTypes.Slot.AUTOSAVE, "title")


func apply_settings(settings: Dictionary) -> bool:
	if settings == null or settings.is_empty():
		return false
	_merge_settings(settings)
	_apply_boot_settings()
	_apply_audio_settings()
	_apply_player_settings()
	var wrote: bool = save_settings()
	settings_applied.emit()
	return wrote


func reset_settings_defaults() -> Dictionary:
	_settings = _default_settings()
	return get_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(SaveTypes.SETTINGS_PATH)
	if err != OK:
		_settings = _default_settings()
		return
	var defaults: Dictionary = _default_settings()
	_settings["master"] = float(cfg.get_value("audio", "master", defaults["master"]))
	_settings["music"] = float(cfg.get_value("audio", "music", defaults["music"]))
	_settings["sfx"] = float(cfg.get_value("audio", "sfx", defaults["sfx"]))
	_settings["ui"] = float(cfg.get_value("audio", "ui", defaults["ui"]))
	_settings["ambience"] = float(cfg.get_value("audio", "ambience", defaults["ambience"]))
	_settings["mouse_sensitivity"] = float(
		cfg.get_value("controls", "mouse_sensitivity", defaults["mouse_sensitivity"])
	)
	_settings["camera_feedback"] = float(
		cfg.get_value("controls", "camera_feedback", defaults["camera_feedback"])
	)
	_settings["fullscreen"] = bool(cfg.get_value("display", "fullscreen", defaults["fullscreen"]))
	_settings["vsync"] = bool(cfg.get_value("display", "vsync", defaults["vsync"]))
	_settings["fov"] = float(cfg.get_value("display", "fov", defaults["fov"]))
	_settings["ui_scale"] = float(cfg.get_value("display", "ui_scale", defaults["ui_scale"]))
	_settings["show_fps"] = bool(cfg.get_value("display", "show_fps", defaults["show_fps"]))
	var seen_v: Variant = cfg.get_value("tutorial", "seen", [])
	var seen: Array = []
	if seen_v is PackedStringArray:
		for s in seen_v as PackedStringArray:
			seen.append(String(s))
	elif seen_v is Array:
		for s2 in seen_v as Array:
			seen.append(str(s2))
	_settings["tutorial_seen"] = seen
	_clamp_settings()


func save_settings() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", float(_settings["master"]))
	cfg.set_value("audio", "music", float(_settings["music"]))
	cfg.set_value("audio", "sfx", float(_settings["sfx"]))
	cfg.set_value("audio", "ui", float(_settings["ui"]))
	cfg.set_value("audio", "ambience", float(_settings["ambience"]))
	cfg.set_value("controls", "mouse_sensitivity", float(_settings["mouse_sensitivity"]))
	cfg.set_value("controls", "camera_feedback", float(_settings["camera_feedback"]))
	cfg.set_value("display", "fullscreen", bool(_settings["fullscreen"]))
	cfg.set_value("display", "vsync", bool(_settings["vsync"]))
	cfg.set_value("display", "fov", float(_settings["fov"]))
	cfg.set_value("display", "ui_scale", float(_settings["ui_scale"]))
	cfg.set_value("display", "show_fps", bool(_settings["show_fps"]))
	var packed := PackedStringArray()
	var seen: Array = get_tutorial_seen_ids()
	for item in seen:
		packed.append(str(item))
	cfg.set_value("tutorial", "seen", packed)
	var err: Error = cfg.save(SaveTypes.SETTINGS_PATH)
	if err != OK:
		DfLog.error("MODULE_24", "settings write failed: %s" % error_string(err))
		return false
	return true


func request_autosave() -> void:
	if _is_restoring:
		return
	_autosave_pending = true
	if _autosave_timer == null:
		return
	_autosave_timer.start(SaveTypes.AUTOSAVE_DEBOUNCE_SEC)


func _setup_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.name = "AutosaveDebounce"
	_autosave_timer.one_shot = true
	_autosave_timer.wait_time = SaveTypes.AUTOSAVE_DEBOUNCE_SEC
	add_child(_autosave_timer)
	_autosave_timer.timeout.connect(_on_autosave_timer_timeout)


func _on_autosave_timer_timeout() -> void:
	if not _autosave_pending:
		return
	if _is_restoring:
		return
	if not can_save_now():
		# Wait for next safe gameplay opportunity.
		if _autosave_timer != null:
			_autosave_timer.start(SaveTypes.AUTOSAVE_DEBOUNCE_SEC)
		return
	_autosave_pending = false
	autosave()


func _cancel_autosave() -> void:
	_autosave_pending = false
	if _autosave_timer != null:
		_autosave_timer.stop()


func _hook_autosave_signals() -> void:
	if _signals_hooked:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
		if gs.has_signal("girl_conquered") and not gs.is_connected("girl_conquered", _on_girl_conquered):
			gs.connect("girl_conquered", _on_girl_conquered)
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.connect("clone_counts_changed", _on_clone_counts_changed)
		if gs.has_method("get_total_clones"):
			_had_clones = int(gs.call("get_total_clones")) >= 1
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_signal("day_advanced") and not day.is_connected("day_advanced", _on_day_advanced):
		day.connect("day_advanced", _on_day_advanced)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_signal("location_changed") and not world.is_connected("location_changed", _on_location_changed):
		world.connect("location_changed", _on_location_changed)
	_signals_hooked = true


func _on_stage_changed(_n: Variant, _p: Variant) -> void:
	request_autosave()


func _on_girl_conquered(_id: StringName) -> void:
	request_autosave()


func _on_day_advanced(_day: int) -> void:
	request_autosave()


func _on_location_changed(_new_id: StringName, _prev_id: StringName) -> void:
	request_autosave()


func _on_clone_counts_changed(total: int, _w: int, _d: int, _f: int) -> void:
	if not _had_clones and total >= 1:
		_had_clones = true
		request_autosave()
	elif total >= 1:
		_had_clones = true


func _build_save_payload() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	var world: Node = get_node_or_null("/root/World")
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	var game_state: Dictionary = {}
	if gs != null and gs.has_method("export_save_state"):
		game_state = gs.call("export_save_state") as Dictionary
	var current_day: int = 1
	if day != null and day.has_method("get_current_day"):
		current_day = int(day.call("get_current_day"))
	var world_state: Dictionary = {"location_id": "", "player": {"position": [0.0, 0.0, 0.0], "yaw": 0.0, "pitch": 0.0}}
	if world != null and world.has_method("export_world_save_state"):
		world_state = world.call("export_world_save_state") as Dictionary
	var runtime_ci: Dictionary = {
		"production_elapsed_seconds": 0.0,
		"money_fraction": 0.0,
		"date_fraction": 0.0,
	}
	if ci != null and ci.has_method("export_runtime_state"):
		runtime_ci = ci.call("export_runtime_state") as Dictionary
	return {
		"schema_version": SaveTypes.SAVE_SCHEMA_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"game": {
			"game_state": game_state,
			"game_day": {"current_day": current_day},
		},
		"world": world_state,
		"runtime": {
			"clone_incremental": runtime_ci,
		},
	}


func _restore_validated_payload(payload: Dictionary) -> bool:
	_is_restoring = true
	_cancel_autosave()
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
		world.call("suppress_auto_reset_on_state_reset", true)
	var game: Dictionary = payload.get("game", {}) as Dictionary
	var game_state: Dictionary = game.get("game_state", {}) as Dictionary
	var game_day: Dictionary = game.get("game_day", {}) as Dictionary
	var world_data: Dictionary = payload.get("world", {}) as Dictionary
	var runtime: Dictionary = payload.get("runtime", {}) as Dictionary
	var ci_data: Dictionary = runtime.get("clone_incremental", {}) as Dictionary
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("restore_save_state"):
		_is_restoring = false
		return false
	if not bool(gs.call("restore_save_state", game_state)):
		_is_restoring = false
		if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
			world.call("suppress_auto_reset_on_state_reset", false)
		return false
	var day_node: Node = get_node_or_null("/root/GameDay")
	var day_i: int = int(game_day.get("current_day", 1))
	if day_node != null and day_node.has_method("restore_day"):
		if not bool(day_node.call("restore_day", day_i)):
			_is_restoring = false
			if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
				world.call("suppress_auto_reset_on_state_reset", false)
			return false
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("restore_runtime_state"):
		if not bool(ci.call("restore_runtime_state", ci_data)):
			_is_restoring = false
			if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
				world.call("suppress_auto_reset_on_state_reset", false)
			return false
	_sync_services_after_load()
	var location_id: StringName = StringName(str(world_data.get("location_id", "apartment")))
	var player_pose: Dictionary = {}
	var player_v: Variant = world_data.get("player", {})
	if player_v is Dictionary:
		player_pose = player_v as Dictionary
	if world != null and world.has_method("restore_saved_location"):
		if not bool(world.call("restore_saved_location", location_id, player_pose)):
			DfLog.warn("MODULE_24", "world restore failed; continuing with domain state")
	_apply_player_settings()
	if gs != null and gs.has_method("get_total_clones"):
		_had_clones = int(gs.call("get_total_clones")) >= 1
	_is_restoring = false
	if world != null and world.has_method("suppress_auto_reset_on_state_reset"):
		world.call("suppress_auto_reset_on_state_reset", false)
	return true


func _sync_services_after_load() -> void:
	var late: Node = get_node_or_null("/root/LateGameExpansion")
	if late != null and late.has_method("sync_after_load"):
		late.call("sync_after_load")
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("sync_after_load"):
		story.call("sync_after_load")
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("sync_after_load"):
		media.call("sync_after_load")
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_method("sync_after_load"):
		overload.call("sync_after_load")


func _read_validate_payload(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": SaveTypes.ErrorCode.READ_FAILED, "message": "read failed"}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK or not (json.data is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.JSON_INVALID, "message": "json invalid"}
	var root: Dictionary = json.data as Dictionary
	var schema_v: int = int(root.get("schema_version", -1))
	if schema_v != SaveTypes.SAVE_SCHEMA_VERSION:
		return {"ok": false, "error": SaveTypes.ErrorCode.UNSUPPORTED_SCHEMA, "message": "unsupported schema"}
	if not root.has("game") or not root.has("world") or not root.has("runtime"):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "missing root keys"}
	var game: Variant = root["game"]
	if not (game is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "game not dict"}
	var game_d: Dictionary = game as Dictionary
	if not game_d.has("game_state") or not game_d.has("game_day"):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "missing game blocks"}
	if not (game_d["game_state"] is Dictionary) or not (game_d["game_day"] is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "game blocks type"}
	var day_d: Dictionary = game_d["game_day"] as Dictionary
	if int(day_d.get("current_day", 0)) < 1:
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "bad day"}
	var runtime: Variant = root["runtime"]
	if not (runtime is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "runtime not dict"}
	var runtime_d: Dictionary = runtime as Dictionary
	if not runtime_d.has("clone_incremental") or not (runtime_d["clone_incremental"] is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "missing clone_incremental"}
	var ci: Dictionary = runtime_d["clone_incremental"] as Dictionary
	for key in ["production_elapsed_seconds", "money_fraction", "date_fraction"]:
		if not ci.has(key):
			return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "ci missing %s" % key}
	var ci_node: Node = get_node_or_null("/root/CloneIncremental")
	if ci_node == null or not ci_node.has_method("normalize_runtime_state"):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "clone incremental unavailable"}
	var ci_normalized: Dictionary = ci_node.call("normalize_runtime_state", ci) as Dictionary
	if not bool(ci_normalized.get("ok", false)):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "clone incremental runtime invalid"}
	if not (root["world"] is Dictionary):
		return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "world not dict"}
	# Domain validation without mutating current GameState: use a throwaway check via export shape.
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("restore_save_state"):
		# Validate by probing required keys locally before restore.
		var gs_data: Dictionary = game_d["game_state"] as Dictionary
		var required: Array[String] = [
			"stage", "money", "authority", "experience", "upgrade_points",
			"characteristics", "purchased_perks", "defeated_rivals", "girls",
			"unlocked_locations", "story_flags", "salary", "media",
			"dating_overload", "clones", "late_game",
		]
		for rk in required:
			if not gs_data.has(rk):
				return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "gs missing %s" % rk}
		var stage_i: int = int(gs_data.get("stage", -1))
		if stage_i < 0 or stage_i > 6:
			return {"ok": false, "error": SaveTypes.ErrorCode.VALIDATION_FAILED, "message": "bad stage"}
	return {"ok": true, "payload": root, "error": SaveTypes.ErrorCode.OK, "message": ""}


func _fill_metadata_from_payload(meta: SaveSlotMetadata, payload: Dictionary) -> void:
	meta.schema_version = int(payload.get("schema_version", 0))
	meta.saved_at_unix = int(payload.get("saved_at_unix", 0))
	var game: Dictionary = payload.get("game", {}) as Dictionary
	var gs: Dictionary = game.get("game_state", {}) as Dictionary
	var day: Dictionary = game.get("game_day", {}) as Dictionary
	var world: Dictionary = payload.get("world", {}) as Dictionary
	meta.stage = int(gs.get("stage", 0))
	meta.game_day = int(day.get("current_day", 0))
	meta.location_id = str(world.get("location_id", ""))
	meta.money = int(gs.get("money", 0))
	meta.authority = int(gs.get("authority", 0))
	meta.experience = int(gs.get("experience", 0))
	var clones: Dictionary = gs.get("clones", {}) as Dictionary
	meta.total_clones = int(clones.get("total", 0))
	var late: Dictionary = gs.get("late_game", {}) as Dictionary
	meta.world_reach = int(late.get("world_reach", 0))
	var girls: Dictionary = gs.get("girls", {}) as Dictionary
	var conquered: Variant = girls.get("conquered", [])
	meta.final_completed = false
	if conquered is Array:
		for gid in conquered as Array:
			if str(gid) == String(SaveTypes.FINAL_TARGET_GIRL_ID):
				meta.final_completed = true
				break


func _atomic_write_text(target_path: String, text: String, bak_path: String) -> bool:
	var tmp_path: String = target_path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		DfLog.error("MODULE_24", "cannot open tmp %s" % tmp_path)
		return false
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(target_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var ren_bak: Error = DirAccess.rename_absolute(target_path, bak_path)
		if ren_bak != OK:
			# Fallback copy then remove.
			if not _copy_file(target_path, bak_path):
				DirAccess.remove_absolute(tmp_path)
				return false
			DirAccess.remove_absolute(target_path)
	var ren: Error = DirAccess.rename_absolute(tmp_path, target_path)
	if ren != OK:
		if not _copy_file(tmp_path, target_path):
			return false
		DirAccess.remove_absolute(tmp_path)
	return true


func _copy_file(from_path: String, to_path: String) -> bool:
	var src: FileAccess = FileAccess.open(from_path, FileAccess.READ)
	if src == null:
		return false
	var data: PackedByteArray = src.get_buffer(src.get_length())
	src.close()
	var dst: FileAccess = FileAccess.open(to_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(data)
	dst.close()
	return true


func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(SaveTypes.SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(SaveTypes.SAVES_DIR)


func _default_settings() -> Dictionary:
	return {
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0,
		"ui": 1.0,
		"ambience": 1.0,
		"mouse_sensitivity": 0.12,
		"camera_feedback": 1.0,
		"fullscreen": false,
		"vsync": true,
		"fov": 75.0,
		"ui_scale": 1.0,
		"show_fps": false,
		"tutorial_seen": [],
	}


func _merge_settings(settings: Dictionary) -> void:
	for key in _settings.keys():
		if settings.has(key):
			_settings[key] = settings[key]
	_clamp_settings()


func _clamp_settings() -> void:
	_settings["master"] = clampf(float(_settings["master"]), 0.0, 1.0)
	_settings["music"] = clampf(float(_settings["music"]), 0.0, 1.0)
	_settings["sfx"] = clampf(float(_settings["sfx"]), 0.0, 1.0)
	_settings["ui"] = clampf(float(_settings["ui"]), 0.0, 1.0)
	_settings["ambience"] = clampf(float(_settings["ambience"]), 0.0, 1.0)
	_settings["mouse_sensitivity"] = clampf(float(_settings["mouse_sensitivity"]), 0.04, 0.30)
	_settings["camera_feedback"] = clampf(float(_settings["camera_feedback"]), 0.0, 1.0)
	_settings["fov"] = clampf(float(_settings["fov"]), 60.0, 100.0)
	var scale: float = float(_settings["ui_scale"])
	if absf(scale - 1.25) < 0.01:
		_settings["ui_scale"] = 1.25
	elif absf(scale - 1.5) < 0.01:
		_settings["ui_scale"] = 1.5
	else:
		_settings["ui_scale"] = 1.0
	_settings["fullscreen"] = bool(_settings["fullscreen"])
	_settings["vsync"] = bool(_settings["vsync"])
	_settings["show_fps"] = bool(_settings["show_fps"])


func _apply_boot_settings() -> void:
	_clamp_settings()
	if not _is_headless_display():
		if bool(_settings["fullscreen"]):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if bool(_settings["vsync"]):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	UiScaleHelper.set_ui_scale(float(_settings["ui_scale"]))


func _apply_audio_settings() -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio == null:
		return
	if audio.has_method("set_master_volume"):
		audio.call("set_master_volume", float(_settings["master"]))
	if audio.has_method("set_music_volume"):
		audio.call("set_music_volume", float(_settings["music"]))
	if audio.has_method("set_sfx_volume"):
		audio.call("set_sfx_volume", float(_settings["sfx"]))
	if audio.has_method("set_ui_volume"):
		audio.call("set_ui_volume", float(_settings["ui"]))
	if audio.has_method("set_ambience_volume"):
		audio.call("set_ambience_volume", float(_settings["ambience"]))


func _apply_player_settings() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_player"):
		return
	var player: Node = world.call("get_player") as Node
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("set_mouse_sensitivity_degrees"):
		player.call("set_mouse_sensitivity_degrees", float(_settings["mouse_sensitivity"]))
	if player.has_method("set_camera_fov"):
		player.call("set_camera_fov", float(_settings["fov"]))
	if player.has_method("get_camera_feedback"):
		var fb: Variant = player.call("get_camera_feedback")
		if fb != null and fb is CameraFeedback:
			(fb as CameraFeedback).set_feedback_scale(float(_settings["camera_feedback"]))


func _is_headless_display() -> bool:
	return DisplayServer.get_name() == "headless" or OS.has_feature("headless")


func _is_final_date_attempt_active() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	# Controllers are scene-local nodes named FinalDateController.
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		if n is FinalDateController and is_instance_valid(n) and not n.is_queued_for_deletion():
			var ctrl: FinalDateController = n as FinalDateController
			if ctrl.is_attempt_active():
				return true
		for child in n.get_children():
			stack.append(child)
	return false
