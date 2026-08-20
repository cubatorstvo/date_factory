class_name ContentValidator
extends RefCounted


func validate(catalog: DateContentCatalog) -> Array[ContentValidationIssue]:
	var issues: Array[ContentValidationIssue] = []
	if catalog == null:
		issues.append(_issue("Catalog", "", "", "Каталог отсутствует."))
		return issues
	_check_unique_ids(catalog, issues)
	_check_references(catalog, issues)
	_check_difficulty_presets(catalog, issues)
	_check_girl_tags(catalog, issues)
	_check_move_mappings(catalog, issues)
	_check_unlockables(catalog, issues)
	_check_base_usage(catalog, issues)
	_check_situation_base_pool(catalog, issues)
	_check_local_objects(catalog, issues)
	_check_secondary_parameters(catalog, issues)
	_check_phase_coverage(catalog, issues)
	_check_girl_secondary(catalog, issues)
	_check_duplicate_unlockable_tags(catalog, issues)
	_check_tag_move_usage(catalog, issues)
	_check_base_tag_diversity(catalog, issues)
	return issues


func _check_unique_ids(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	_unique_group("DateTag", catalog.tags, issues)
	_unique_group("DateMove", catalog.moves, issues)
	_unique_group("DateSituation", catalog.situations, issues)
	_unique_group("GirlProfile", catalog.girls, issues)
	_unique_group("SecondaryRule", catalog.secondary_rules, issues)
	_unique_group("DateLocalObject", catalog.local_objects, issues)
	_unique_group("DateLocation", catalog.locations, issues)
	_unique_group("Outfit", catalog.outfits, issues)
	_unique_group("ProgressionStat", catalog.progression_stats, issues)
	_unique_group("GirlDifficultyPreset", catalog.girl_difficulty_presets, issues)


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
		if move.is_local():
			if catalog.find_tag(move.local_tag_id) == null:
				issues.append(_issue("DateMove", String(move.id), "local_tag_id", "LOCAL Move должен иметь существующий Tag."))
			if move.local_option_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", String(move.id), "local_option_text", "LOCAL Move должен иметь option text."))
			if move.local_positive_result_text.strip_edges().is_empty() or move.local_negative_result_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", String(move.id), "local_result_text", "LOCAL Move должен иметь positive и negative result text."))


func _check_girl_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var enabled_ids: Dictionary = {}
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		enabled_ids[String(tag.id)] = true
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var preset: GirlDifficultyPreset = catalog.find_girl_difficulty(girl.difficulty_preset_id)
		if preset == null or not preset.enabled:
			issues.append(_issue(
				"GirlProfile",
				String(girl.id),
				"difficulty_preset_id",
				"Девушка \"%s\" ссылается на отсутствующий или отключённый preset сложности \"%s\"." % [String(girl.id), String(girl.difficulty_preset_id)],
				DateTypes.ValidationSeverity.ERROR,
				"INVALID_GIRL_DIFFICULTY_REFERENCE"
			))
		var expected_positive: int = 0
		var difficulty_name: String = String(girl.difficulty_preset_id)
		if preset != null:
			expected_positive = preset.positive_tag_count
			difficulty_name = preset.display_name
		var actual_count: int = girl.positive_tag_ids.size()
		if preset != null and preset.enabled and actual_count != expected_positive:
			issues.append(_issue(
				"GirlProfile",
				String(girl.id),
				"positive_tag_ids",
				"Девушка \"%s\" имеет сложность \"%s\". Требуется положительных тегов: %d. Сейчас указано: %d." % [String(girl.id), difficulty_name, expected_positive, actual_count],
				DateTypes.ValidationSeverity.ERROR,
				"INVALID_POSITIVE_TAG_COUNT"
			))
		var liked: Dictionary = {}
		var disliked: Dictionary = {}
		var duplicate_state: PackedStringArray = PackedStringArray()
		var unknown_ids: PackedStringArray = PackedStringArray()
		for tag_id in girl.positive_tag_ids:
			var key: String = String(tag_id)
			liked[key] = true
			if not enabled_ids.has(key) and not unknown_ids.has(key):
				unknown_ids.append(key)
		for tag_id in girl.negative_tag_ids:
			var key: String = String(tag_id)
			disliked[key] = true
			if liked.has(key) and not duplicate_state.has(key):
				duplicate_state.append(key)
			if not enabled_ids.has(key) and not unknown_ids.has(key):
				unknown_ids.append(key)
		var missing: PackedStringArray = PackedStringArray()
		for tag_key in enabled_ids.keys():
			var key: String = String(tag_key)
			if not liked.has(key) and not disliked.has(key):
				missing.append(key)
		if missing.is_empty() and duplicate_state.is_empty() and unknown_ids.is_empty():
			continue
		missing.sort()
		duplicate_state.sort()
		unknown_ids.sort()
		issues.append(_issue(
			"GirlProfile",
			String(girl.id),
			"tags",
			"Девушка \"%s\": неполный охват тегов. missing_tag_ids: %s. duplicate_state_tag_ids: %s. unknown_tag_ids: %s." % [
				String(girl.id),
				", ".join(missing) if not missing.is_empty() else "нет",
				", ".join(duplicate_state) if not duplicate_state.is_empty() else "нет",
				", ".join(unknown_ids) if not unknown_ids.is_empty() else "нет",
			],
			DateTypes.ValidationSeverity.ERROR,
			"INCOMPLETE_GIRL_TAG_COVERAGE"
		))


func _check_difficulty_presets(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var enabled_count: int = catalog.enabled_tags().size()
	for preset in catalog.girl_difficulty_presets:
		if preset == null or not preset.enabled:
			continue
		if preset.positive_tag_count >= 1 and preset.positive_tag_count < enabled_count:
			continue
		issues.append(_issue(
			"GirlDifficultyPreset",
			String(preset.id),
			"positive_tag_count",
			"Preset \"%s\" должен иметь 1..%d положительных тегов. Сейчас: %d." % [String(preset.id), maxi(0, enabled_count - 1), preset.positive_tag_count],
			DateTypes.ValidationSeverity.ERROR,
			"INVALID_DIFFICULTY_POSITIVE_COUNT"
		))


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


func _check_local_objects(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for local_object in catalog.local_objects:
		if local_object == null:
			continue
		for move_id in local_object.move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move == null:
				issues.append(_issue("DateLocalObject", String(local_object.id), "move_ids", "Неизвестный DateMove: %s." % String(move_id)))
				continue
			if not move.is_local():
				issues.append(_issue("DateLocalObject", String(local_object.id), "move_ids", "Ход %s должен иметь kind LOCAL." % String(move_id)))
	for location in catalog.locations:
		if location == null:
			continue
		for object_id in location.local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("DateLocation", String(location.id), "local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))
		if location.enabled and [&"apartment", &"cafe", &"restaurant"].has(location.id):
			if location.local_object_ids.is_empty():
				issues.append(_issue("DateLocation", String(location.id), "local_object_ids", "Активное место должно иметь хотя бы один Local Object."))
	var apartment_catalog: ApartmentCatalog = ApartmentCatalog.create_seed()
	for upgrade in apartment_catalog.get_all_upgrades():
		if upgrade == null:
			continue
		for object_id in upgrade.granted_local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "granted_local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))


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


func _check_girl_secondary(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null:
			continue
		if catalog.find_secondary(girl.secondary_rule_id) == null:
			issues.append(_issue("GirlProfile", String(girl.id), "secondary_rule_id", "Неизвестное Secondary-правило."))


func _check_tag_move_usage(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var used: Dictionary = {}
	for move in catalog.moves:
		if move == null:
			continue
		for mapping in move.situation_mappings:
			if mapping == null:
				continue
			used[String(mapping.tag_id)] = true
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if used.has(String(tag.id)):
			continue
		issues.append(_issue(
			"DateTag",
			String(tag.id),
			"situation_mappings",
			"Активный тег \"%s\" не используется ни в одном DateMoveSituationMapping." % String(tag.id),
			DateTypes.ValidationSeverity.WARNING,
			"TAG_WITHOUT_MOVE_MAPPING"
		))


func _check_base_tag_diversity(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var min_distinct: int = 6
	if catalog.date_rules != null:
		min_distinct = catalog.date_rules.min_distinct_base_tags_per_situation
	for situation in catalog.situations:
		if situation == null or not situation.enabled:
			continue
		var tags: Dictionary = {}
		for move in catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE):
			var mapping: DateMoveSituationMapping = move.mapping_for(situation.id)
			if mapping == null:
				continue
			tags[String(mapping.tag_id)] = true
		if tags.size() >= min_distinct:
			continue
		issues.append(_issue(
			"DateSituation",
			String(situation.id),
			"base_tags",
			"Ситуация \"%s\" имеет только %d разных BASE Tags, минимум %d." % [String(situation.id), tags.size(), min_distinct],
			DateTypes.ValidationSeverity.WARNING,
			"LOW_BASE_TAG_DIVERSITY"
		))


func _check_duplicate_unlockable_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for situation in catalog.situations:
		if situation == null or not situation.enabled:
			continue
		var tag_to_moves: Dictionary = {}
		for move in catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.UNLOCKABLE):
			var mapping: DateMoveSituationMapping = move.mapping_for(situation.id)
			if mapping == null:
				continue
			var tag_key: String = String(mapping.tag_id)
			if not tag_to_moves.has(tag_key):
				var ids: PackedStringArray = PackedStringArray()
				tag_to_moves[tag_key] = ids
			var listed: PackedStringArray = tag_to_moves[tag_key]
			listed.append(String(move.id))
			tag_to_moves[tag_key] = listed
		for tag_key in tag_to_moves.keys():
			var move_ids: PackedStringArray = tag_to_moves[tag_key]
			if move_ids.size() < 2:
				continue
			var sorted_ids: PackedStringArray = move_ids.duplicate()
			sorted_ids.sort()
			var message: String = "Ситуация \"%s\" содержит несколько Открываемых ходов с одинаковым тегом \"%s\":\n%s" % [String(situation.id), String(tag_key), ", ".join(sorted_ids)]
			issues.append(_issue(
				"DateSituation",
				String(situation.id),
				"unlockable_tags",
				message,
				DateTypes.ValidationSeverity.WARNING,
				"DUPLICATE_UNLOCKABLE_TAG_IN_SITUATION"
			))


func _issue(
	resource_type: String,
	resource_id: String,
	field: String,
	message: String,
	severity: DateTypes.ValidationSeverity = DateTypes.ValidationSeverity.ERROR,
	code: String = ""
) -> ContentValidationIssue:
	var issue: ContentValidationIssue = ContentValidationIssue.new()
	issue.severity = severity
	issue.code = code
	issue.resource_type = resource_type
	issue.resource_id = resource_id
	issue.field = field
	issue.message = message
	return issue
