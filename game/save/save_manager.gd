extends Node

const SAVE_VERSION: int = 4
const DEFAULT_SAVE_PATH: String = "user://saves/game.json"
const MINUTES_PER_DAY: int = 1440

var save_path: String = DEFAULT_SAVE_PATH


func _playthrough() -> Node:
	var node: Node = get_node("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
	return node


func _time_service() -> Node:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
	return node


func new_game() -> void:
	_playthrough().apply_new_game()
	var clock: Variant = _time_service()
	if clock != null:
		clock.on_playthrough_reset()


func save_game() -> void:
	var folder: String = save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"game_state": _playthrough().to_dict(),
	}
	file.store_string(JSON.stringify(payload, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	var root: Dictionary = parsed
	var version: int = int(root.get("save_version", 1))
	if version < 1:
		return false
	var state_data: Variant = root.get("game_state", {})
	if not (state_data is Dictionary):
		return false
	var migrated: Dictionary = _migrate_game_state(state_data, version)
	_playthrough().from_dict(migrated)
	var clock: Variant = _time_service()
	if clock != null:
		clock.on_playthrough_reset()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if not has_save():
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _migrate_game_state(state_data: Dictionary, from_version: int) -> Dictionary:
	var migrated: Dictionary = state_data.duplicate(true)
	if from_version >= SAVE_VERSION:
		return migrated
	if from_version < 2:
		migrated = _migrate_v1_flow(migrated)
	if from_version < 3:
		migrated = _migrate_v2_story(migrated)
	if from_version < 4:
		migrated = _migrate_v3_progression(migrated)
	return migrated


func _migrate_v1_flow(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var flow_value: Variant = migrated.get("flow", {})
	if not (flow_value is Dictionary):
		return migrated
	var flow: Dictionary = flow_value
	if not flow.has("game_time_minutes"):
		var old_day: int = int(flow.get("day", 1))
		flow["game_time_minutes"] = maxi(0, old_day - 1) * MINUTES_PER_DAY
	flow.erase("day")
	migrated["flow"] = flow
	return migrated


func _migrate_v2_story(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var story_value: Variant = migrated.get("story", {})
	if not (story_value is Dictionary):
		return migrated
	var story: Dictionary = story_value
	if not story.has("finale_reached"):
		story["finale_reached"] = false
	migrated["story"] = story
	return migrated


func _migrate_v3_progression(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	if not progression.has("purchased_ids"):
		progression["purchased_ids"] = []
	migrated["progression"] = progression
	return migrated
