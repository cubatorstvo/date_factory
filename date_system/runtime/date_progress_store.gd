class_name DateProgressStore
extends RefCounted

const STORE_PATH := "user://date_system/runtime.json"

var player_state: TestPlayerState = TestPlayerState.new()
var girl_progress_by_id: Dictionary = {}
var last_replay: DateReplaySnapshot


func load_store(catalog: DateContentCatalog) -> void:
	_ensure_defaults(catalog)
	if not FileAccess.file_exists(STORE_PATH):
		save_store()
		return
	var file := FileAccess.open(STORE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_from_dictionary(parsed, catalog)


func save_store() -> void:
	DirAccess.make_dir_recursive_absolute("user://date_system")
	var file := FileAccess.open(STORE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_to_dictionary(), "\t"))


func get_girl_progress(girl_id: StringName, girl: GirlProfile) -> GirlProgress:
	var key: String = String(girl_id)
	if girl_progress_by_id.has(key):
		return girl_progress_by_id[key]
	var progress := GirlProgress.new()
	progress.reset_to_profile(girl)
	girl_progress_by_id[key] = progress
	return progress


func reset_girl(girl: GirlProfile) -> void:
	if girl == null:
		return
	var progress := GirlProgress.new()
	progress.reset_to_profile(girl)
	girl_progress_by_id[String(girl.id)] = progress
	save_store()


func reset_all(catalog: DateContentCatalog) -> void:
	player_state = TestPlayerState.new()
	last_replay = null
	girl_progress_by_id.clear()
	_ensure_defaults(catalog)
	save_store()


func capture_replay(seed: int, girl_id: StringName, location_id: StringName, outfit_id: StringName, progress: GirlProgress) -> void:
	last_replay = DateReplaySnapshot.new()
	last_replay.seed = seed
	last_replay.girl_id = girl_id
	last_replay.location_id = location_id
	last_replay.outfit_id = outfit_id
	last_replay.girl_progress = GirlProgress.from_dictionary(progress.to_dictionary())
	last_replay.player_state = TestPlayerState.from_dictionary(player_state.to_dictionary())
	save_store()


func restore_replay() -> bool:
	if last_replay == null or last_replay.girl_progress == null:
		return false
	girl_progress_by_id[String(last_replay.girl_id)] = GirlProgress.from_dictionary(last_replay.girl_progress.to_dictionary())
	if last_replay.player_state != null:
		player_state = TestPlayerState.from_dictionary(last_replay.player_state.to_dictionary())
	save_store()
	return true


func _ensure_defaults(catalog: DateContentCatalog) -> void:
	if catalog == null:
		return
	for girl in catalog.girls:
		if girl == null:
			continue
		var key: String = String(girl.id)
		if not girl_progress_by_id.has(key):
			var progress := GirlProgress.new()
			progress.reset_to_profile(girl)
			girl_progress_by_id[key] = progress


func _to_dictionary() -> Dictionary:
	var girls: Dictionary = {}
	for key in girl_progress_by_id.keys():
		var progress: GirlProgress = girl_progress_by_id[key]
		girls[str(key)] = progress.to_dictionary()
	return {
		"player_state": player_state.to_dictionary(),
		"girl_progress": girls,
		"last_replay": last_replay.to_dictionary() if last_replay != null else {},
	}


func _from_dictionary(data: Dictionary, catalog: DateContentCatalog) -> void:
	var player_data: Variant = data.get("player_state", {})
	if player_data is Dictionary:
		player_state = TestPlayerState.from_dictionary(player_data)
	girl_progress_by_id.clear()
	var girls_data: Variant = data.get("girl_progress", {})
	if girls_data is Dictionary:
		for key in girls_data.keys():
			var item: Variant = girls_data[key]
			if item is Dictionary:
				girl_progress_by_id[str(key)] = GirlProgress.from_dictionary(item)
	var replay_data: Variant = data.get("last_replay", {})
	if replay_data is Dictionary and not (replay_data as Dictionary).is_empty():
		last_replay = DateReplaySnapshot.from_dictionary(replay_data)
	_ensure_defaults(catalog)
	realign_to_catalog(catalog)


func realign_to_catalog(catalog: DateContentCatalog) -> void:
	if catalog == null:
		return
	for key in girl_progress_by_id.keys():
		var progress: GirlProgress = girl_progress_by_id[key]
		var girl: GirlProfile = catalog.find_girl(StringName(str(key)))
		if progress == null or girl == null:
			continue
		progress.realign_revealed_to_profile(girl, catalog)
	if last_replay != null and last_replay.girl_progress != null:
		var replay_girl: GirlProfile = catalog.find_girl(last_replay.girl_id)
		if replay_girl != null:
			last_replay.girl_progress.realign_revealed_to_profile(replay_girl, catalog)
