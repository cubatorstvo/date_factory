class_name FrontendSaveApi
extends RefCounted
## Soft façade over /root/SaveSystem for MODULE24 front-end UI.

const MANUAL_SLOTS: Array[SaveTypes.Slot] = [
	SaveTypes.Slot.MANUAL_1,
	SaveTypes.Slot.MANUAL_2,
	SaveTypes.Slot.MANUAL_3,
]
const LOAD_SLOTS: Array[SaveTypes.Slot] = [
	SaveTypes.Slot.AUTOSAVE,
	SaveTypes.Slot.MANUAL_1,
	SaveTypes.Slot.MANUAL_2,
	SaveTypes.Slot.MANUAL_3,
]


static func save_system() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SaveSystem")


static func is_ready() -> bool:
	return save_system() != null


static func _missing(method: String) -> void:
	push_error("[FrontendSaveApi] SaveSystem.%s unavailable" % method)


static func has_any_valid_save() -> bool:
	var ss: Node = save_system()
	if ss == null:
		return false
	for slot in LOAD_SLOTS:
		var meta: SaveSlotMetadata = get_slot_metadata(slot)
		if meta != null and meta.valid:
			return true
	return false


static func get_slot_metadata(slot: SaveTypes.Slot) -> SaveSlotMetadata:
	var ss: Node = save_system()
	if ss == null or not ss.has_method("get_slot_metadata"):
		return SaveSlotMetadata.empty(slot)
	var raw: Variant = ss.call("get_slot_metadata", slot)
	if raw is SaveSlotMetadata:
		return raw as SaveSlotMetadata
	return SaveSlotMetadata.empty(slot)


static func continue_latest() -> bool:
	return _call_result("continue_latest", [])


static func start_new_game() -> bool:
	var ss: Node = save_system()
	if ss != null and ss.has_method("start_new_game"):
		return _result_ok(ss.call("start_new_game"))
	_missing("start_new_game")
	var world: Node = _world()
	if world != null and world.has_method("begin_new_game_boot"):
		var travel: Variant = world.call("begin_new_game_boot")
		return int(travel) == int(WorldTypes.WorldTravelResult.SUCCESS)
	return false


static func load_slot(slot: SaveTypes.Slot) -> bool:
	return _call_result("load_slot", [slot])


static func save_slot(slot: SaveTypes.Slot) -> bool:
	var ss: Node = save_system()
	if ss == null or not ss.has_method("save_slot"):
		_missing("save_slot")
		return false
	# SaveSystem.can_save_now currently requires GAMEPLAY; pause is product-safe.
	var player: Node = _player()
	var restored_pause: bool = false
	if (
		player != null
		and player.has_method("get_control_mode")
		and int(player.call("get_control_mode")) == int(PlayerController.ControlMode.PAUSED)
	):
		player.set("_mode", PlayerController.ControlMode.GAMEPLAY)
		restored_pause = true
	var result: Variant = ss.call("save_slot", slot)
	if restored_pause and is_instance_valid(player):
		player.set("_mode", PlayerController.ControlMode.PAUSED)
	return _result_ok(result)


static func delete_slot(slot: SaveTypes.Slot) -> bool:
	return _call_result("delete_slot", [slot])


static func return_to_title() -> bool:
	var ss: Node = save_system()
	if ss != null and ss.has_method("return_to_title"):
		return _result_ok(ss.call("return_to_title"))
	_missing("return_to_title")
	var world: Node = _world()
	if world != null and world.has_method("prepare_for_title"):
		world.call("prepare_for_title")
	return true


static func get_settings() -> Dictionary:
	var ss: Node = save_system()
	if ss != null and ss.has_method("get_settings"):
		var raw: Variant = ss.call("get_settings")
		if raw is Dictionary:
			return (raw as Dictionary).duplicate(true)
	return default_settings()


static func get_default_settings() -> Dictionary:
	var ss: Node = save_system()
	if ss != null and ss.has_method("reset_settings_defaults"):
		# Do not mutate runtime here — return a clean default snapshot.
		return default_settings()
	return default_settings()


static func apply_settings(settings: Dictionary) -> bool:
	var ss: Node = save_system()
	if ss != null and ss.has_method("apply_settings"):
		return bool(ss.call("apply_settings", settings))
	_missing("apply_settings")
	_apply_runtime_settings(settings)
	return true


static func reset_tutorials() -> bool:
	var ss: Node = save_system()
	if ss != null and ss.has_method("set_tutorial_seen_ids"):
		ss.call("set_tutorial_seen_ids", [])
		if ss.has_method("save_settings"):
			return bool(ss.call("save_settings"))
		var settings: Dictionary = get_settings()
		settings["tutorial_seen"] = []
		return apply_settings(settings)
	var settings2: Dictionary = get_settings()
	settings2["tutorial_seen"] = []
	return apply_settings(settings2)


static func default_settings() -> Dictionary:
	return {
		"master": 0.0,
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


static func preview_audio(settings: Dictionary) -> void:
	var audio: Node = _audio()
	if audio == null:
		return
	if audio.has_method("set_master_volume"):
		audio.call("set_master_volume", float(settings.get("master", 0.0)))
	if audio.has_method("set_music_volume"):
		audio.call("set_music_volume", float(settings.get("music", 1.0)))
	if audio.has_method("set_sfx_volume"):
		audio.call("set_sfx_volume", float(settings.get("sfx", 1.0)))
	if audio.has_method("set_ui_volume"):
		audio.call("set_ui_volume", float(settings.get("ui", 1.0)))
	if audio.has_method("set_ambience_volume"):
		audio.call("set_ambience_volume", float(settings.get("ambience", 1.0)))


static func _apply_runtime_settings(settings: Dictionary) -> void:
	preview_audio(settings)
	UiScaleHelper.set_ui_scale(float(settings.get("ui_scale", 1.0)))


static func _call_result(method: String, args: Array) -> bool:
	var ss: Node = save_system()
	if ss == null or not ss.has_method(method):
		_missing(method)
		return false
	return _result_ok(ss.callv(method, args))


static func _result_ok(result: Variant) -> bool:
	if result == null:
		return false
	if result is SaveResult:
		return (result as SaveResult).ok
	if result is bool:
		return bool(result)
	return true


static func _world() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("World")


static func _audio() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AudioDirector")


static func _player() -> Node:
	var world: Node = _world()
	if world != null and world.has_method("get_player"):
		return world.call("get_player") as Node
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node


static func slot_title(slot: SaveTypes.Slot) -> String:
	match slot:
		SaveTypes.Slot.AUTOSAVE:
			return "АВТОСОХРАНЕНИЕ"
		SaveTypes.Slot.MANUAL_1:
			return "СЛОТ 1"
		SaveTypes.Slot.MANUAL_2:
			return "СЛОТ 2"
		SaveTypes.Slot.MANUAL_3:
			return "СЛОТ 3"
		_:
			return "СЛОТ"


static func format_metadata_card(meta: SaveSlotMetadata) -> String:
	if meta == null or not meta.exists:
		return "ПУСТО"
	if not meta.valid:
		if meta.recovered_from_backup:
			return "ВОССТАНОВЛЕНО ИЗ РЕЗЕРВНОЙ КОПИИ"
		return "СОХРАНЕНИЕ ПОВРЕЖДЕНО"
	var loc_label: String = _location_label(meta.location_id)
	var time_label: String = _format_unix(meta.saved_at_unix)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Стадия %d · %s" % [meta.stage, loc_label])
	lines.append("День %d" % meta.game_day)
	lines.append("Деньги %d" % meta.money)
	lines.append("Клоны %d" % meta.total_clones)
	if time_label != "":
		lines.append(time_label)
	if meta.recovered_from_backup:
		lines.append("ВОССТАНОВЛЕНО ИЗ РЕЗЕРВНОЙ КОПИИ")
	return "\n".join(lines)


static func _location_label(location_id: String) -> String:
	match location_id:
		"apartment":
			return "Квартира"
		"city_hub":
			return "Город"
		"cafe":
			return "Кафе"
		"gym":
			return "Зал"
		"appearance_space":
			return "Студия"
		"salary_mine":
			return "Шахта"
		"laboratory":
			return "Лаборатория"
		"production_area":
			return "Производство"
		"final_location":
			return "Финал"
		"":
			return "—"
		_:
			return location_id


static func _format_unix(unix: int) -> String:
	if unix <= 0:
		return ""
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%02d.%02d.%04d %02d:%02d" % [
		int(dt.get("day", 0)),
		int(dt.get("month", 0)),
		int(dt.get("year", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
	]
