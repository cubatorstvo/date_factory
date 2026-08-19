class_name GirlProgress
extends Resource

@export var girl_id: StringName = &""
@export var relationship: int = 0
@export var revealed_positive_tag_ids: Array[StringName] = []
@export var revealed_negative_tag_ids: Array[StringName] = []
@export var secondary_revealed: bool = false
@export var completed_dates: int = 0


func tag_knowledge(tag_id: StringName) -> DateTypes.TagKnowledge:
	if revealed_positive_tag_ids.has(tag_id):
		return DateTypes.TagKnowledge.POSITIVE
	if revealed_negative_tag_ids.has(tag_id):
		return DateTypes.TagKnowledge.NEGATIVE
	return DateTypes.TagKnowledge.UNKNOWN


func reveal_tag(tag_id: StringName, positive: bool) -> bool:
	if tag_knowledge(tag_id) != DateTypes.TagKnowledge.UNKNOWN:
		return false
	if positive:
		revealed_positive_tag_ids.append(tag_id)
	else:
		revealed_negative_tag_ids.append(tag_id)
	return true


func unknown_tag_count(girl: GirlProfile) -> int:
	if girl == null:
		return 0
	var known: int = revealed_positive_tag_ids.size() + revealed_negative_tag_ids.size()
	return maxi(0, girl.positive_tag_ids.size() + girl.negative_tag_ids.size() - known)


func reset_to_profile(girl: GirlProfile) -> void:
	if girl == null:
		return
	girl_id = girl.id
	relationship = girl.relationship_start
	revealed_positive_tag_ids.clear()
	revealed_negative_tag_ids.clear()
	secondary_revealed = false
	completed_dates = 0


func to_dictionary() -> Dictionary:
	var positives: Array = []
	for tag_id in revealed_positive_tag_ids:
		positives.append(String(tag_id))
	var negatives: Array = []
	for tag_id in revealed_negative_tag_ids:
		negatives.append(String(tag_id))
	return {
		"girl_id": String(girl_id),
		"relationship": relationship,
		"revealed_positive_tag_ids": positives,
		"revealed_negative_tag_ids": negatives,
		"secondary_revealed": secondary_revealed,
		"completed_dates": completed_dates,
	}


static func from_dictionary(data: Dictionary) -> GirlProgress:
	var progress := GirlProgress.new()
	progress.girl_id = StringName(str(data.get("girl_id", "")))
	progress.relationship = int(data.get("relationship", 0))
	progress.secondary_revealed = bool(data.get("secondary_revealed", false))
	progress.completed_dates = int(data.get("completed_dates", 0))
	var positives: Array = data.get("revealed_positive_tag_ids", [])
	for item in positives:
		progress.revealed_positive_tag_ids.append(StringName(str(item)))
	var negatives: Array = data.get("revealed_negative_tag_ids", [])
	for item in negatives:
		progress.revealed_negative_tag_ids.append(StringName(str(item)))
	return progress
