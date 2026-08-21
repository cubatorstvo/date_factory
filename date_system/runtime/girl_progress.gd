class_name GirlProgress
extends Resource

@export var girl_id: StringName = &""
@export var relationship: int = 0
@export var revealed_positive_tag_ids: Array[StringName] = []
@export var revealed_negative_tag_ids: Array[StringName] = []
@export var completed_dates: int = 0


func tag_knowledge(tag_id: StringName, girl: GirlProfile = null) -> DateTypes.TagKnowledge:
	if revealed_positive_tag_ids.has(tag_id):
		return DateTypes.TagKnowledge.POSITIVE
	if revealed_negative_tag_ids.has(tag_id):
		return DateTypes.TagKnowledge.NEGATIVE
	if girl != null and girl.initial_known_tag_ids.has(tag_id):
		return DateTypes.TagKnowledge.POSITIVE if girl.prefers_tag(tag_id) > 0 else DateTypes.TagKnowledge.NEGATIVE
	return DateTypes.TagKnowledge.UNKNOWN


func reveal_tag(tag_id: StringName, positive: bool, girl: GirlProfile = null) -> bool:
	if tag_knowledge(tag_id, girl) != DateTypes.TagKnowledge.UNKNOWN:
		return false
	if positive:
		revealed_positive_tag_ids.append(tag_id)
	else:
		revealed_negative_tag_ids.append(tag_id)
	return true


func unknown_tag_count(girl: GirlProfile) -> int:
	if girl == null:
		return 0
	var unknown: int = 0
	for tag_id in girl.positive_tag_ids:
		if tag_knowledge(tag_id, girl) == DateTypes.TagKnowledge.UNKNOWN:
			unknown += 1
	for tag_id in girl.negative_tag_ids:
		if tag_knowledge(tag_id, girl) == DateTypes.TagKnowledge.UNKNOWN:
			unknown += 1
	return unknown


func known_positive_tag_ids(girl: GirlProfile) -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	for tag_id in revealed_positive_tag_ids:
		seen[String(tag_id)] = true
		ids.append(tag_id)
	if girl != null:
		for tag_id in girl.initial_known_tag_ids:
			if seen.has(String(tag_id)):
				continue
			if girl.prefers_tag(tag_id) > 0:
				seen[String(tag_id)] = true
				ids.append(tag_id)
	return ids


func known_negative_tag_ids(girl: GirlProfile) -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	for tag_id in revealed_negative_tag_ids:
		seen[String(tag_id)] = true
		ids.append(tag_id)
	if girl != null:
		for tag_id in girl.initial_known_tag_ids:
			if seen.has(String(tag_id)):
				continue
			if girl.prefers_tag(tag_id) <= 0:
				seen[String(tag_id)] = true
				ids.append(tag_id)
	return ids


func reset_to_profile(girl: GirlProfile) -> void:
	if girl == null:
		return
	girl_id = girl.id
	relationship = 0
	revealed_positive_tag_ids.clear()
	revealed_negative_tag_ids.clear()
	completed_dates = 0


func realign_revealed_to_profile(girl: GirlProfile, catalog: DateContentCatalog) -> void:
	if girl == null or catalog == null:
		return
	var known: Dictionary = {}
	for tag_id in revealed_positive_tag_ids:
		known[String(tag_id)] = true
	for tag_id in revealed_negative_tag_ids:
		known[String(tag_id)] = true
	revealed_positive_tag_ids.clear()
	revealed_negative_tag_ids.clear()
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if not known.has(String(tag.id)):
			continue
		if girl.prefers_tag(tag.id) > 0:
			revealed_positive_tag_ids.append(tag.id)
		else:
			revealed_negative_tag_ids.append(tag.id)


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
		"completed_dates": completed_dates,
	}


static func from_dictionary(data: Dictionary) -> GirlProgress:
	var progress := GirlProgress.new()
	progress.girl_id = StringName(str(data.get("girl_id", "")))
	progress.relationship = maxi(0, int(data.get("relationship", 0)))
	progress.completed_dates = int(data.get("completed_dates", 0))
	var positives: Array = data.get("revealed_positive_tag_ids", [])
	for item in positives:
		progress.revealed_positive_tag_ids.append(StringName(str(item)))
	var negatives: Array = data.get("revealed_negative_tag_ids", [])
	for item in negatives:
		progress.revealed_negative_tag_ids.append(StringName(str(item)))
	return progress
