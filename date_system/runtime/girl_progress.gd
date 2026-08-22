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
	return DateTypes.TagKnowledge.UNKNOWN


func reveal_tag(tag_id: StringName, positive: bool, girl: GirlProfile = null, catalog: DateContentCatalog = null) -> bool:
	if tag_knowledge(tag_id, girl) != DateTypes.TagKnowledge.UNKNOWN:
		return false
	if positive:
		revealed_positive_tag_ids.append(tag_id)
	else:
		revealed_negative_tag_ids.append(tag_id)
	normalize_deduced_knowledge(girl, catalog)
	return true


func unknown_tag_count(girl: GirlProfile, catalog: DateContentCatalog = null) -> int:
	return unknown_positive_tag_count(girl, catalog) + unknown_negative_tag_count(girl, catalog)


func unknown_positive_tag_count(girl: GirlProfile, catalog: DateContentCatalog = null) -> int:
	return _unknown_tag_count_for(girl, catalog, true)


func unknown_negative_tag_count(girl: GirlProfile, catalog: DateContentCatalog = null) -> int:
	return _unknown_tag_count_for(girl, catalog, false)


func normalize_deduced_knowledge(girl: GirlProfile, catalog: DateContentCatalog = null) -> void:
	if girl == null or catalog == null:
		return
	var enabled: Array[DateTag] = catalog.enabled_tags()
	var total_positive: int = girl.positive_tag_ids.size()
	var total_negative: int = maxi(0, enabled.size() - total_positive)
	var revealed_positive: int = 0
	var revealed_negative: int = 0
	for tag in enabled:
		if tag == null:
			continue
		match tag_knowledge(tag.id, girl):
			DateTypes.TagKnowledge.POSITIVE:
				revealed_positive += 1
			DateTypes.TagKnowledge.NEGATIVE:
				revealed_negative += 1
	var deduce_negative: bool = revealed_positive == total_positive and unknown_tag_count(girl, catalog) > 0
	var deduce_positive: bool = revealed_negative == total_negative and unknown_tag_count(girl, catalog) > 0
	if not deduce_negative and not deduce_positive:
		return
	for tag in enabled:
		if tag == null:
			continue
		if tag_knowledge(tag.id, girl) != DateTypes.TagKnowledge.UNKNOWN:
			continue
		if deduce_negative:
			revealed_negative_tag_ids.append(tag.id)
		elif deduce_positive:
			revealed_positive_tag_ids.append(tag.id)


func _unknown_tag_count_for(girl: GirlProfile, catalog: DateContentCatalog, positive: bool) -> int:
	if girl == null or catalog == null:
		return 0
	var unknown: int = 0
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if tag_knowledge(tag.id, girl) != DateTypes.TagKnowledge.UNKNOWN:
			continue
		if (girl.prefers_tag(tag.id) > 0) == positive:
			unknown += 1
	return unknown


func known_positive_tag_ids(girl: GirlProfile) -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	for tag_id in revealed_positive_tag_ids:
		seen[String(tag_id)] = true
		ids.append(tag_id)
	return ids


func known_negative_tag_ids(girl: GirlProfile) -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	for tag_id in revealed_negative_tag_ids:
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
	normalize_deduced_knowledge(girl, catalog)


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
