class_name ContentValidator
extends RefCounted


func validate(catalog: DateContentCatalog) -> Array[ContentValidationIssue]:
	var issues: Array[ContentValidationIssue] = []
	if catalog == null:
		issues.append(_issue("Catalog", "", "", "Каталог отсутствует."))
		return issues
	_check_unique_ids(catalog, issues)
	_check_references(catalog, issues)
	_check_girl_tags(catalog, issues)
	_check_move_mappings(catalog, issues)
	_check_unlockables(catalog, issues)
	_check_base_usage(catalog, issues)
	_check_situation_base_pool(catalog, issues)
	_check_thematic_locations(catalog, issues)
	_check_secondary_parameters(catalog, issues)
	_check_phase_coverage(catalog, issues)
	_check_girl_secondary_and_formats(catalog, issues)
	return issues


func _check_unique_ids(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	_unique_group("DateTag", catalog.tags, issues)
	_unique_group("DateMove", catalog.moves, issues)
	_unique_group("DateSituation", catalog.situations, issues)
	_unique_group("GirlProfile", catalog.girls, issues)
	_unique_group("SecondaryRule", catalog.secondary_rules, issues)
	_unique_group("LocationFormat", catalog.location_formats, issues)
	_unique_group("DateLocation", catalog.locations, issues)
	_unique_group("Outfit", catalog.outfits, issues)
	_unique_group("ProgressionStat", catalog.progression_stats, issues)


func _unique_group(resource_type: String, items: Array, issues: Array[ContentValidationIssue]) -> void:
	var seen: Dictionary = {}
	for item in items:
		if item == null:
			issues.append(_issue(resource_type, "", "id", "Пустая ссылка в каталоге."))
			continue
		var item_id: String = String(item.id)
		if item_id.is_empty():
			issues.append(_issue(resource_type, "", "id", "Пустой id."))
			continue
		if seen.has(item_id):
			issues.append(_issue(resource_type, item_id, "id", "Дублирующийся id."))
		seen[item_id] = true


func _check_references(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	if catalog.date_rules == null:
		issues.append(_issue("DateRules", "", "", "DateRules отсутствуют."))
	for move in catalog.moves:
		if move == null:
			continue
		for mapping in move.situation_mappings:
			if mapping == null:
				issues.append(_issue("DateMove", String(move.id), "situation_mappings", "Пустой mapping."))
				continue
			if catalog.find_situation(mapping.situation_id) == null:
				issues.append(_issue("DateMove", String(move.id), "situation_id", "Неизвестная Situation: %s." % String(mapping.situation_id)))
			if catalog.find_tag(mapping.tag_id) == null:
				issues.append(_issue("DateMove", String(move.id), "tag_id", "Неизвестный Tag: %s." % String(mapping.tag_id)))
		if move.unlock_requirement != null and catalog.find_stat(move.unlock_requirement.stat_id) == null:
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement.stat_id", "Неизвестная характеристика: %s." % String(move.unlock_requirement.stat_id)))


func _check_girl_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var assigned: Dictionary = {}
		for tag_id in girl.positive_tag_ids:
			_assign_girl_tag(catalog, issues, girl, tag_id, assigned, "positive_tag_ids")
		for tag_id in girl.negative_tag_ids:
			if assigned.has(String(tag_id)):
				issues.append(_issue("GirlProfile", String(girl.id), "negative_tag_ids", "Tag %s указан и как positive, и как negative." % String(tag_id)))
			_assign_girl_tag(catalog, issues, girl, tag_id, assigned, "negative_tag_ids")
		for tag in catalog.enabled_tags():
			if not assigned.has(String(tag.id)):
				issues.append(_issue("GirlProfile", String(girl.id), "tags", "Активный Tag %s не распределён между positive и negative." % String(tag.id)))


func _assign_girl_tag(
	catalog: DateContentCatalog,
	issues: Array[ContentValidationIssue],
	girl: GirlProfile,
	tag_id: StringName,
	assigned: Dictionary,
	field: String
) -> void:
	if catalog.find_tag(tag_id) == null:
		issues.append(_issue("GirlProfile", String(girl.id), field, "Неизвестный Tag: %s." % String(tag_id)))
	assigned[String(tag_id)] = true


func _check_move_mappings(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null:
			continue
		var seen: Dictionary = {}
		for mapping in move.situation_mappings:
			if mapping == null:
				continue
			var key: String = String(mapping.situation_id)
			if seen.has(key):
				issues.append(_issue("DateMove", String(move.id), "situation_mappings", "Больше одного mapping на Situation %s." % key))
			seen[key] = true


func _check_unlockables(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null or move.kind != DateTypes.DateMoveKind.UNLOCKABLE:
			continue
		if move.unlock_requirement == null or String(move.unlock_requirement.stat_id).is_empty():
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "UNLOCKABLE должен содержать UnlockRequirement."))


func _check_base_usage(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null or move.kind != DateTypes.DateMoveKind.BASE:
			continue
		if move.max_uses_per_date != 0:
			issues.append(_issue("DateMove", String(move.id), "max_uses_per_date", "BASE должен использовать unlimited (0)."))


func _check_situation_base_pool(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var needed: int = 3
	if catalog.date_rules != null:
		needed = catalog.date_rules.base_moves_per_episode
	for situation in catalog.situations:
		if situation == null or not situation.enabled:
			continue
		var pool: Array[DateMove] = catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE)
		if pool.size() < needed:
			issues.append(_issue("DateSituation", String(situation.id), "base_pool", "Недостаточно BASE-ходов: %d из %d." % [pool.size(), needed]))


func _check_thematic_locations(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for location in catalog.locations:
		if location == null:
			continue
		if location.preference_mode != DateTypes.LocationPreferenceMode.THEMATIC:
			continue
		if catalog.find_location_format(location.location_format_id) == null:
			issues.append(_issue("DateLocation", String(location.id), "location_format_id", "THEMATIC Location должна иметь существующий LocationFormat."))


func _check_secondary_parameters(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for rule in catalog.secondary_rules:
		if rule == null:
			continue
		match rule.condition_type:
			DateTypes.SecondaryConditionType.DISTINCT_SUCCESS_TAGS:
				if int(rule.condition_parameters.get("required_count", 0)) <= 0:
					issues.append(_issue("SecondaryRule", String(rule.id), "condition_parameters.required_count", "required_count должен быть больше 0."))
			DateTypes.SecondaryConditionType.NO_FAILURES:
				pass
			_:
				issues.append(_issue("SecondaryRule", String(rule.id), "condition_type", "Неизвестный тип Secondary."))
		var phases: Variant = rule.condition_parameters.get("counted_phases", [])
		if phases is Array and (phases as Array).is_empty():
			issues.append(_issue("SecondaryRule", String(rule.id), "condition_parameters.counted_phases", "counted_phases не должен быть пустым."))


func _check_phase_coverage(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	if catalog.date_rules == null:
		return
	var counts: Dictionary = {
		int(DateTypes.DatePhase.OPENING): 0,
		int(DateTypes.DatePhase.CORE): 0,
		int(DateTypes.DatePhase.CLOSING): 0,
	}
	for situation in catalog.enabled_situations():
		for phase_value in situation.allowed_phases:
			if counts.has(int(phase_value)):
				counts[int(phase_value)] = int(counts[int(phase_value)]) + 1
	var needed: Dictionary = {
		int(DateTypes.DatePhase.OPENING): catalog.date_rules.opening_episode_count,
		int(DateTypes.DatePhase.CORE): catalog.date_rules.core_episode_count,
		int(DateTypes.DatePhase.CLOSING): catalog.date_rules.closing_episode_count,
	}
	for phase_value in needed.keys():
		if int(counts[phase_value]) < int(needed[phase_value]):
			issues.append(_issue("DateSituation", "", "allowed_phases", "Недостаточно Situation для фазы %s: %d из %d." % [DateTypes.phase_name(phase_value as DateTypes.DatePhase), int(counts[phase_value]), int(needed[phase_value])]))


func _check_girl_secondary_and_formats(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null:
			continue
		if catalog.find_secondary(girl.secondary_rule_id) == null:
			issues.append(_issue("GirlProfile", String(girl.id), "secondary_rule_id", "Неизвестное Secondary-правило."))
		for format_id in girl.favorite_location_format_ids:
			if catalog.find_location_format(format_id) == null:
				issues.append(_issue("GirlProfile", String(girl.id), "favorite_location_format_ids", "Неизвестный LocationFormat: %s." % String(format_id)))


func _issue(resource_type: String, resource_id: String, field: String, message: String) -> ContentValidationIssue:
	var issue := ContentValidationIssue.new()
	issue.severity = DateTypes.ValidationSeverity.ERROR
	issue.resource_type = resource_type
	issue.resource_id = resource_id
	issue.field = field
	issue.message = message
	return issue
