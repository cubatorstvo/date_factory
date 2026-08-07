class_name WorldAccessResult
extends RefCounted
## Typed read model for World location access (MODULE 12).

var location_id: StringName = &""
var status: WorldTypes.WorldAccessStatus = WorldTypes.WorldAccessStatus.UNKNOWN_LOCATION
var required_feature: StoryTypes.StoryFeature = StoryTypes.StoryFeature.SOCIAL_ACCESS
var has_required_feature: bool = false
var current_stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
var message: String = ""


func is_available() -> bool:
	return status == WorldTypes.WorldAccessStatus.AVAILABLE
