class_name DateReplaySnapshot
extends Resource

@export var seed: int = 0
@export var girl_id: StringName = &""
@export var venue_id: StringName = &""
@export var outfit_id: StringName = &""
@export var local_object_ids: Array[StringName] = []
@export var girl_progress: GirlProgress
@export var player_snapshot: DatePlayerSnapshot


func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"girl_id": String(girl_id),
		"venue_id": String(venue_id),
		"outfit_id": String(outfit_id),
		"local_object_ids": _ids_to_strings(local_object_ids),
		"girl_progress": girl_progress.to_dictionary() if girl_progress != null else {},
		"player_snapshot": player_snapshot.to_dictionary() if player_snapshot != null else {},
	}


static func from_dictionary(data: Dictionary) -> DateReplaySnapshot:
	var snapshot := DateReplaySnapshot.new()
	snapshot.seed = int(data.get("seed", 0))
	snapshot.girl_id = StringName(str(data.get("girl_id", "")))
	snapshot.venue_id = StringName(str(data.get("venue_id", "")))
	snapshot.outfit_id = StringName(str(data.get("outfit_id", "")))
	snapshot.local_object_ids = _strings_to_ids(data.get("local_object_ids", []))
	var progress_data: Variant = data.get("girl_progress", {})
	if progress_data is Dictionary:
		snapshot.girl_progress = GirlProgress.from_dictionary(progress_data)
	var player_data: Variant = data.get("player_snapshot", data.get("player_state", {}))
	if player_data is Dictionary:
		snapshot.player_snapshot = DatePlayerSnapshot.from_dictionary(player_data)
	return snapshot


static func _ids_to_strings(ids: Array[StringName]) -> Array:
	var result: Array = []
	for item in ids:
		result.append(String(item))
	return result


static func _strings_to_ids(raw: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not (raw is Array):
		return result
	for item in raw:
		var object_id := StringName(str(item))
		if object_id != &"" and not result.has(object_id):
			result.append(object_id)
	return result