class_name StagePlan
extends RefCounted

var stage: int = 1
var target_filler_girl_ids: Array[StringName] = []
var skipped_filler_girl_ids: Array[StringName] = []
var target_ordinary_rival_ids: Array[StringName] = []
var skipped_ordinary_rival_ids: Array[StringName] = []
var characteristic_targets: Dictionary = {}
var target_outfit_count: int = 0
var target_outfit_ids: Array[StringName] = []
var target_apartment_object_count: int = 0
var target_apartment_object_ids: Array[StringName] = []
var venue_visit_goals: Array[StringName] = []
var story_girl_id: StringName = &""
var story_rival_id: StringName = &""
var plan_decisions: PackedStringArray = PackedStringArray()
var generation_hash: String = ""


func content_hash() -> String:
	return ProgressionRng.sha256_hex(_canonical_payload())


func freeze() -> void:
	generation_hash = content_hash()


func to_dict() -> Dictionary:
	return {
		"stage": stage,
		"target_filler_girl_ids": _ids_to_strings(target_filler_girl_ids),
		"skipped_filler_girl_ids": _ids_to_strings(skipped_filler_girl_ids),
		"target_ordinary_rival_ids": _ids_to_strings(target_ordinary_rival_ids),
		"skipped_ordinary_rival_ids": _ids_to_strings(skipped_ordinary_rival_ids),
		"characteristic_targets": characteristic_targets.duplicate(true),
		"target_outfit_count": target_outfit_count,
		"target_outfit_ids": _ids_to_strings(target_outfit_ids),
		"target_apartment_object_count": target_apartment_object_count,
		"target_apartment_object_ids": _ids_to_strings(target_apartment_object_ids),
		"venue_visit_goals": _ids_to_strings(venue_visit_goals),
		"story_girl_id": String(story_girl_id),
		"story_rival_id": String(story_rival_id),
		"plan_decisions": Array(plan_decisions),
		"generation_hash": generation_hash,
		"content_hash": content_hash(),
	}


func one_line_summary() -> String:
	var filler_names: PackedStringArray = PackedStringArray()
	for girl_id in target_filler_girl_ids:
		filler_names.append(String(girl_id))
	return "S%d fillers=%s outfits=%d apt=%d venues=%d" % [
		stage,
		",".join(filler_names),
		target_outfit_count,
		target_apartment_object_count,
		venue_visit_goals.size(),
	]


func _canonical_payload() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("stage=%d" % stage)
	parts.append("fillers=%s" % ",".join(_sorted_ids(target_filler_girl_ids)))
	parts.append("skip_fillers=%s" % ",".join(_sorted_ids(skipped_filler_girl_ids)))
	parts.append("rivals=%s" % ",".join(_sorted_ids(target_ordinary_rival_ids)))
	parts.append("skip_rivals=%s" % ",".join(_sorted_ids(skipped_ordinary_rival_ids)))
	var char_keys: Array = characteristic_targets.keys()
	char_keys.sort()
	var char_parts: PackedStringArray = PackedStringArray()
	for key in char_keys:
		char_parts.append("%s:%s" % [str(key), str(characteristic_targets[key])])
	parts.append("chars=%s" % ",".join(char_parts))
	parts.append("outfit_count=%d" % target_outfit_count)
	parts.append("outfits=%s" % ",".join(_sorted_ids(target_outfit_ids)))
	parts.append("apt_count=%d" % target_apartment_object_count)
	parts.append("apt=%s" % ",".join(_sorted_ids(target_apartment_object_ids)))
	parts.append("venues=%s" % ",".join(_sorted_ids(venue_visit_goals)))
	parts.append("story_girl=%s" % String(story_girl_id))
	parts.append("story_rival=%s" % String(story_rival_id))
	parts.append("decisions=%s" % " | ".join(plan_decisions))
	return "\n".join(parts)


static func _ids_to_strings(ids: Array[StringName]) -> Array:
	var result: Array = []
	for id_value in ids:
		result.append(String(id_value))
	return result


static func _sorted_ids(ids: Array[StringName]) -> PackedStringArray:
	var values: PackedStringArray = PackedStringArray()
	for id_value in ids:
		values.append(String(id_value))
	values.sort()
	return values
