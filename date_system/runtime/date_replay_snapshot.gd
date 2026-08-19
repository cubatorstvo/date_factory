class_name DateReplaySnapshot
extends Resource

@export var seed: int = 0
@export var girl_id: StringName = &""
@export var location_id: StringName = &""
@export var outfit_id: StringName = &""
@export var girl_progress: GirlProgress
@export var player_state: TestPlayerState


func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"girl_id": String(girl_id),
		"location_id": String(location_id),
		"outfit_id": String(outfit_id),
		"girl_progress": girl_progress.to_dictionary() if girl_progress != null else {},
		"player_state": player_state.to_dictionary() if player_state != null else {},
	}


static func from_dictionary(data: Dictionary) -> DateReplaySnapshot:
	var snapshot := DateReplaySnapshot.new()
	snapshot.seed = int(data.get("seed", 0))
	snapshot.girl_id = StringName(str(data.get("girl_id", "")))
	snapshot.location_id = StringName(str(data.get("location_id", "")))
	snapshot.outfit_id = StringName(str(data.get("outfit_id", "")))
	var progress_data: Variant = data.get("girl_progress", {})
	if progress_data is Dictionary:
		snapshot.girl_progress = GirlProgress.from_dictionary(progress_data)
	var player_data: Variant = data.get("player_state", {})
	if player_data is Dictionary:
		snapshot.player_state = TestPlayerState.from_dictionary(player_data)
	return snapshot
