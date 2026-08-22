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
	_check_fixed_presentation(catalog, issues)
	_check_characteristic_moves(catalog, issues)
	_check_outfits(catalog, issues)
	_check_base_usage(catalog, issues)
	_check_situation_base_pool(catalog, issues)
	_check_local_objects(catalog, issues)
	_check_venue_local_catalog(catalog, issues)
	_check_combo_rules(catalog, issues)
	_check_phase_coverage(catalog, issues)
	_check_girl_relationship_bounds(catalog, issues)
	_check_required_girl_profiles(catalog, issues)
	_check_girl_traits(catalog, issues)
	_check_initial_known_tags(catalog, issues)
	_check_requirement_range(catalog, issues)
	_check_stage_relationship_max(issues)
	_check_display_copy(catalog, issues)
	_check_game_terms(catalog, issues)
	_check_tag_move_usage(catalog, issues)
	_check_base_tag_diversity(catalog, issues)
	return issues


func _check_unique_ids(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	_unique_group("DateTag", catalog.tags, issues)
	_unique_group("DateMove", catalog.moves, issues)
	_unique_group("DateSituation", catalog.situations, issues)
	_unique_group("GirlProfile", catalog.girls, issues)
	_unique_group("DateLocalObject", catalog.local_objects, issues)
	_unique_group("DateVenue", catalog.date_venues, issues)
	_unique_group("Outfit", catalog.outfits, issues)
	_unique_group("GirlTrait", catalog.traits, issues)
	_unique_group("CharacteristicDefinition", catalog.characteristics, issues)
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
		if move.unlock_requirement != null and catalog.find_characteristic(move.unlock_requirement.stat_id) == null:
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement.stat_id", "Неизвестная характеристика: %s." % String(move.unlock_requirement.stat_id)))
		if move.has_fixed_presentation():
			if catalog.find_tag(move.fixed_tag_id) == null:
				issues.append(_issue("DateMove", String(move.id), "fixed_tag_id", "Ход с фиксированным текстом должен иметь существующий Tag."))
			if move.fixed_option_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", String(move.id), "fixed_option_text", "Ход с фиксированным текстом должен иметь option text."))
			if move.fixed_positive_result_text.strip_edges().is_empty() or move.fixed_negative_result_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", String(move.id), "fixed_result_text", "Ход с фиксированным текстом должен иметь positive и negative result text."))


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
		var duplicate_state: PackedStringArray = PackedStringArray()
		var unknown_ids: PackedStringArray = PackedStringArray()
		for tag_id in girl.positive_tag_ids:
			var key: String = String(tag_id)
			if liked.has(key):
				if not duplicate_state.has(key):
					duplicate_state.append(key)
			liked[key] = true
			if not enabled_ids.has(key) and not unknown_ids.has(key):
				unknown_ids.append(key)
		if duplicate_state.is_empty() and unknown_ids.is_empty():
			continue
		duplicate_state.sort()
		unknown_ids.sort()
		issues.append(_issue(
			"GirlProfile",
			String(girl.id),
			"positive_tag_ids",
			"Девушка \"%s\": повторы или неизвестные положительные теги. duplicate_state_tag_ids: %s. unknown_tag_ids: %s." % [
				String(girl.id),
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


func _check_fixed_presentation(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null or not move.enabled:
			continue
		if not move.has_fixed_presentation() or move.fixed_tag_id == &"":
			issues.append(_issue("DateMove", String(move.id), "fixed_tag_id", "Ход должен иметь постоянный Tag и player-facing текст."))


func _check_characteristic_moves(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var characteristic_moves: Array[DateMove] = []
	for move in catalog.moves:
		if move == null or not move.is_characteristic():
			continue
		characteristic_moves.append(move)
		if move.unlock_requirement == null or String(move.unlock_requirement.stat_id).is_empty():
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "CHARACTERISTIC должен содержать UnlockRequirement."))
		elif not DateTypes.CHARACTERISTIC_LEVELS.has(move.unlock_requirement.required_level):
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement.required_level", "Characteristic Move открывается на уровнях 1, 3 или 5."))
	if characteristic_moves.size() != 12:
		issues.append(_issue("DateMove", "", "kind", "Должно быть ровно 12 Characteristic Moves.", DateTypes.ValidationSeverity.ERROR, "CHARACTERISTIC_MOVE_COUNT"))
	var tags_to_moves: Dictionary = {}
	var slots: Dictionary = {}
	for move in characteristic_moves:
		var tag_key: String = String(move.fixed_tag_id)
		if tag_key.is_empty():
			continue
		if tags_to_moves.has(tag_key):
			issues.append(_issue(
				"DateMove",
				String(move.id),
				"fixed_tag_id",
				"Characteristic Moves дублируют Tag \"%s\": %s, %s" % [tag_key, String(tags_to_moves[tag_key]), String(move.id)],
				DateTypes.ValidationSeverity.ERROR,
				"CHARACTERISTIC_TAG_DUPLICATE"
			))
		else:
			tags_to_moves[tag_key] = move.id
		if move.unlock_requirement == null:
			continue
		var slot_key: String = "%s:%d" % [String(move.unlock_requirement.stat_id), move.unlock_requirement.required_level]
		if slots.has(slot_key):
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "Characteristic Move дублирует слот %s." % slot_key))
		else:
			slots[slot_key] = true
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if tags_to_moves.has(String(tag.id)):
			continue
		issues.append(_issue("DateTag", String(tag.id), "characteristic_moves", "Активный Tag не покрыт Characteristic Move.", DateTypes.ValidationSeverity.ERROR, "CHARACTERISTIC_TAG_COVERAGE"))
	for stat_id in DateTypes.CHARACTERISTIC_STAT_ORDER:
		for level in DateTypes.CHARACTERISTIC_LEVELS:
			var slot_key: String = "%s:%d" % [String(stat_id), level]
			if slots.has(slot_key):
				continue
			issues.append(_issue("DateMove", "", "unlock_requirement", "Нет Characteristic Move для %s %d." % [String(stat_id), level]))

func _check_outfits(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var referenced_outfit_moves: Dictionary = {}
	for outfit in catalog.outfits:
		if outfit == null:
			continue
		if outfit.stat_bonus < 0 or outfit.stat_bonus > 1:
			issues.append(_issue("Outfit", String(outfit.id), "stat_bonus", "Outfit даёт максимум +1 к одной характеристике."))
		if outfit.stat_bonus == 1 and (outfit.stat_id == &"" or catalog.find_characteristic(outfit.stat_id) == null):
			issues.append(_issue("Outfit", String(outfit.id), "stat_id", "Outfit с бонусом должен указывать существующую характеристику."))
		if not outfit.has_outfit_move():
			continue
		var outfit_move: DateMove = catalog.find_move(outfit.outfit_move_id)
		if outfit_move == null or not outfit_move.is_outfit():
			issues.append(_issue("Outfit", String(outfit.id), "outfit_move_id", "Outfit Move должен существовать и иметь kind OUTFIT."))
		else:
			referenced_outfit_moves[String(outfit.outfit_move_id)] = true
	for move in catalog.moves:
		if move == null or not move.is_outfit():
			continue
		if not referenced_outfit_moves.has(String(move.id)):
			issues.append(_issue("DateMove", String(move.id), "kind", "Outfit Move должен быть привязан к Outfit."))

func _check_base_usage(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null or move.kind != DateTypes.DateMoveKind.BASE:
			continue
		if move.max_uses_per_date != 0:
			issues.append(_issue("DateMove", String(move.id), "max_uses_per_date", "BASE должен использовать unlimited (0)."))


func _check_situation_base_pool(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var owners: Dictionary = {}
	for situation in catalog.situations:
		if situation == null or not situation.enabled:
			continue
		if situation.allowed_phases.is_empty():
			issues.append(_issue("DateSituation", String(situation.id), "allowed_phases", "Situation %s должна иметь хотя бы одну фазу." % String(situation.id)))
		if situation.weight < 0.0:
			issues.append(_issue("DateSituation", String(situation.id), "weight", "Situation %s имеет отрицательный weight." % String(situation.id)))
		for venue_id in situation.allowed_venue_ids:
			if catalog.find_venue(venue_id) == null:
				issues.append(_issue("DateSituation", String(situation.id), "allowed_venue_ids", "Situation %s ссылается на неизвестный DateVenue %s." % [String(situation.id), String(venue_id)]))
		for girl_id in situation.allowed_girl_ids:
			if catalog.find_girl(girl_id) == null:
				issues.append(_issue("DateSituation", String(situation.id), "allowed_girl_ids", "Situation %s ссылается на неизвестный GirlProfile %s." % [String(situation.id), String(girl_id)]))
		var seen_ids: Dictionary = {}
		var seen_tags: Dictionary = {}
		if situation.base_move_ids.size() != 6:
			issues.append(_issue("DateSituation", String(situation.id), "base_move_ids", "Situation %s должна иметь ровно 6 BASE Moves, сейчас %d." % [String(situation.id), situation.base_move_ids.size()]))
		for move_id in situation.base_move_ids:
			var key: String = String(move_id)
			if seen_ids.has(key):
				issues.append(_issue("DateSituation", String(situation.id), "base_move_ids", "Situation %s содержит повтор BASE %s." % [String(situation.id), key]))
			seen_ids[key] = true
			if owners.has(key) and String(owners[key]) != String(situation.id):
				issues.append(_issue("DateMove", key, "base_move_ids", "BASE %s принадлежит нескольким Situations: %s и %s." % [key, String(owners[key]), String(situation.id)]))
			else:
				owners[key] = situation.id
			var move: DateMove = catalog.find_move(move_id)
			if move == null:
				issues.append(_issue("DateSituation", String(situation.id), "base_move_ids", "Situation %s ссылается на отсутствующий Move %s." % [String(situation.id), key]))
				continue
			if not move.enabled:
				issues.append(_issue("DateMove", key, "enabled", "BASE %s Situation %s должен быть enabled." % [key, String(situation.id)]))
			if move.kind != DateTypes.DateMoveKind.BASE:
				issues.append(_issue("DateMove", key, "kind", "Move %s Situation %s должен иметь kind BASE." % [key, String(situation.id)]))
			if move.fixed_tag_id == &"":
				issues.append(_issue("DateMove", key, "fixed_tag_id", "BASE %s Situation %s должен иметь fixed_tag_id." % [key, String(situation.id)]))
			elif catalog.find_tag(move.fixed_tag_id) == null:
				issues.append(_issue("DateMove", key, "fixed_tag_id", "BASE %s Situation %s ссылается на неизвестный Tag %s." % [key, String(situation.id), String(move.fixed_tag_id)]))
			if seen_tags.has(String(move.fixed_tag_id)):
				issues.append(_issue("DateSituation", String(situation.id), "fixed_tag_id", "Situation %s имеет повторный Tag %s среди BASE." % [String(situation.id), String(move.fixed_tag_id)]))
			elif move.fixed_tag_id != &"":
				seen_tags[String(move.fixed_tag_id)] = true
			if move.fixed_option_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", key, "fixed_option_text", "BASE %s Situation %s должен иметь option text." % [key, String(situation.id)]))
			if move.fixed_positive_result_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", key, "fixed_positive_result_text", "BASE %s Situation %s должен иметь positive result text." % [key, String(situation.id)]))
			if move.fixed_negative_result_text.strip_edges().is_empty():
				issues.append(_issue("DateMove", key, "fixed_negative_result_text", "BASE %s Situation %s должен иметь negative result text." % [key, String(situation.id)]))
		if situation.base_move_ids.size() == 6 and seen_tags.size() != 6:
			issues.append(_issue("DateSituation", String(situation.id), "fixed_tag_id", "Situation %s должна иметь 6 различных BASE Tags, сейчас %d." % [String(situation.id), seen_tags.size()]))
	for move in catalog.moves:
		if move == null or not move.enabled or move.kind != DateTypes.DateMoveKind.BASE:
			continue
		if not owners.has(String(move.id)):
			issues.append(_issue("DateMove", String(move.id), "base_move_ids", "BASE %s не принадлежит ни одной DateSituation." % String(move.id)))


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
			elif move.max_uses_per_date != 1:
				issues.append(_issue("DateMove", String(move.id), "max_uses_per_date", "Local Move должен иметь max_uses_per_date = 1."))
	for location in catalog.date_venues:
		if location == null:
			continue
		for object_id in location.local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("DateVenue", String(location.id), "local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))
		if location.enabled and [&"cafe", &"leisure_center", &"restaurant"].has(location.id):
			if location.local_object_ids.is_empty():
				issues.append(_issue("DateVenue", String(location.id), "local_object_ids", "Активное место должно иметь хотя бы один Local Object."))
		if location.id == &"apartment" and not location.local_object_ids.is_empty():
			issues.append(_issue("DateVenue", "apartment", "local_object_ids", "Квартира не должна содержать Local Objects в DateVenue; покрытие идёт только от купленных Apartment Objects."))
	var apartment_catalog: ApartmentCatalog = ApartmentCatalog.create_seed()
	for upgrade in apartment_catalog.get_all_upgrades():
		if upgrade == null:
			continue
		for object_id in upgrade.granted_local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "granted_local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))

func _check_venue_local_catalog(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var expected_venues: Array[StringName] = [&"apartment", &"cafe", &"leisure_center", &"restaurant"]
	var venue_ids: Array[StringName] = []
	for location in catalog.date_venues:
		if location == null:
			continue
		venue_ids.append(location.id)
		if not location.enabled:
			issues.append(_issue("DateVenue", String(location.id), "enabled", "Production DateVenue должен быть enabled."))
	if venue_ids.size() != 4:
		issues.append(_issue("DateVenue", "", "date_venues", "Должно быть ровно 4 основных DateVenue."))
	for expected_id in expected_venues:
		if venue_ids.has(expected_id):
			continue
		issues.append(_issue("DateVenue", String(expected_id), "id", "Отсутствует production DateVenue: %s." % String(expected_id)))
	for venue_id in venue_ids:
		if expected_venues.has(venue_id):
			continue
		issues.append(_issue("DateVenue", String(venue_id), "id", "Лишний DateVenue не входит в production catalog: %s." % String(venue_id)))
	_check_public_venue_local_set(
		catalog,
		issues,
		&"cafe",
		3,
		6,
		[&"politeness", &"directness", &"cunning", &"humor", &"care", &"audacity"],
		false
	)
	_check_public_venue_local_set(
		catalog,
		issues,
		&"leisure_center",
		4,
		8,
		[&"care", &"cunning", &"risk", &"audacity", &"dominance", &"humor", &"generosity", &"status"],
		false
	)
	_check_public_venue_local_set(
		catalog,
		issues,
		&"restaurant",
		4,
		8,
		[&"politeness", &"dominance", &"status", &"composure", &"flattery", &"generosity", &"care", &"directness"],
		true
	)
	_check_restaurant_characteristic_gates(catalog, issues)
	_check_apartment_local_catalog(catalog, issues)


func _check_public_venue_local_set(
	catalog: DateContentCatalog,
	issues: Array[ContentValidationIssue],
	venue_id: StringName,
	object_count: int,
	move_count: int,
	expected_tags: Array[StringName],
	require_characteristic: bool
) -> void:
	var venue: DateVenue = catalog.find_venue(venue_id)
	if venue == null:
		return
	if venue.local_object_ids.size() != object_count:
		issues.append(_issue("DateVenue", String(venue_id), "local_object_ids", "Ожидается %d Local Objects." % object_count))
	var tags: Dictionary = {}
	var moves_found: int = 0
	for object_id in venue.local_object_ids:
		var local_object: DateLocalObject = catalog.find_local_object(object_id)
		if local_object == null:
			continue
		moves_found += local_object.move_ids.size()
		for move_id in local_object.move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move == null:
				continue
			var tag_key: String = String(move.fixed_tag_id)
			if tags.has(tag_key):
				issues.append(_issue("DateVenue", String(venue_id), "fixed_tag_id", "Тег %s повторяется внутри Venue." % tag_key))
			else:
				tags[tag_key] = true
			var has_req: bool = move.unlock_requirement != null and not String(move.unlock_requirement.stat_id).is_empty()
			if require_characteristic and not has_req:
				issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "Restaurant Local Move должен иметь Characteristic requirement."))
			elif not require_characteristic and has_req:
				issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "Local Move этого Venue не должен иметь Characteristic requirement."))
	if moves_found != move_count:
		issues.append(_issue("DateVenue", String(venue_id), "move_ids", "Ожидается %d Local Moves." % move_count))
	if tags.size() != expected_tags.size():
		issues.append(_issue("DateVenue", String(venue_id), "fixed_tag_id", "Ожидается %d уникальных Tags." % expected_tags.size()))
	for expected_tag in expected_tags:
		if tags.has(String(expected_tag)):
			continue
		issues.append(_issue("DateVenue", String(venue_id), "fixed_tag_id", "Отсутствует Tag %s." % String(expected_tag)))


func _check_restaurant_characteristic_gates(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var venue: DateVenue = catalog.find_venue(&"restaurant")
	if venue == null:
		return
	var slots: Dictionary = {}
	var req_count: int = 0
	var level1: int = 0
	var level3: int = 0
	for object_id in venue.local_object_ids:
		var local_object: DateLocalObject = catalog.find_local_object(object_id)
		if local_object == null:
			continue
		for move_id in local_object.move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move == null or move.unlock_requirement == null:
				continue
			var stat_id: String = String(move.unlock_requirement.stat_id)
			var level: int = move.unlock_requirement.required_level
			if stat_id.is_empty():
				continue
			req_count += 1
			if level == 1:
				level1 += 1
			elif level == 3:
				level3 += 1
			var slot_key: String = "%s:%d" % [stat_id, level]
			if slots.has(slot_key):
				issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "Restaurant дублирует слот %s." % slot_key))
			else:
				slots[slot_key] = true
	if req_count != 8:
		issues.append(_issue("DateVenue", "restaurant", "unlock_requirement", "Restaurant должен иметь 8 Characteristic requirements."))
	if level1 != 4 or level3 != 4:
		issues.append(_issue("DateVenue", "restaurant", "unlock_requirement", "Restaurant должен иметь 4 хода ур. 1 и 4 хода ур. 3."))
	for stat_id in DateTypes.CHARACTERISTIC_STAT_ORDER:
		for level in [1, 3]:
			var slot_key: String = "%s:%d" % [String(stat_id), level]
			if slots.has(slot_key):
				continue
			issues.append(_issue("DateVenue", "restaurant", "unlock_requirement", "Нет Restaurant Local Move для %s ур. %d." % [String(stat_id), level]))


func _check_apartment_local_catalog(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var apartment_catalog: ApartmentCatalog = ApartmentCatalog.create_seed()
	var upgrades: Array[ApartmentUpgradeDefinition] = apartment_catalog.get_all_upgrades()
	if upgrades.size() != 12:
		issues.append(_issue("ApartmentUpgradeDefinition", "", "upgrades", "Apartment catalog должен содержать 12 purchasable objects."))
	var tags: Dictionary = {}
	var object_ids: Dictionary = {}
	var stage_counts: Dictionary = {2: 0, 3: 0, 4: 0}
	for upgrade in upgrades:
		if upgrade == null:
			continue
		if upgrade.granted_local_object_ids.size() != 1:
			issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "granted_local_object_ids", "Каждый Apartment Object даёт ровно один Local Object."))
			continue
		var object_id: StringName = upgrade.granted_local_object_ids[0]
		if object_ids.has(String(object_id)):
			issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "granted_local_object_ids", "Local Object %s повторяется." % String(object_id)))
		else:
			object_ids[String(object_id)] = true
		if upgrade.min_story_stage == 2 or upgrade.min_story_stage == 3 or upgrade.min_story_stage == 4:
			stage_counts[upgrade.min_story_stage] = int(stage_counts[upgrade.min_story_stage]) + 1
		else:
			issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "min_story_stage", "Apartment Object открывается на Stage 2, 3 или 4."))
		var local_object: DateLocalObject = catalog.find_local_object(object_id)
		if local_object == null:
			continue
		if local_object.move_ids.size() != 1:
			issues.append(_issue("DateLocalObject", String(object_id), "move_ids", "Apartment Object должен иметь ровно один Local Move."))
			continue
		var move: DateMove = catalog.find_move(local_object.move_ids[0])
		if move == null:
			continue
		var has_req: bool = move.unlock_requirement != null and not String(move.unlock_requirement.stat_id).is_empty()
		if has_req:
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement", "Apartment Local Move не должен иметь Characteristic requirement."))
		var tag_key: String = String(move.fixed_tag_id)
		if tags.has(tag_key):
			issues.append(_issue("DateLocalObject", String(object_id), "fixed_tag_id", "Apartment Tag %s повторяется." % tag_key))
		else:
			tags[tag_key] = true
	if int(stage_counts[2]) != 4 or int(stage_counts[3]) != 4 or int(stage_counts[4]) != 4:
		issues.append(_issue("ApartmentUpgradeDefinition", "", "min_story_stage", "Apartment Objects должны распределяться 4 / 4 / 4 по Stage 2 / 3 / 4."))
	if tags.size() != 12:
		issues.append(_issue("ApartmentUpgradeDefinition", "", "fixed_tag_id", "Apartment должен покрывать 12 уникальных Tags."))
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if tags.has(String(tag.id)):
			continue
		issues.append(_issue("DateTag", String(tag.id), "apartment", "Канонический Tag не покрыт Apartment Object."))

func _check_combo_rules(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var rules: DateRules = catalog.date_rules
	if rules == null:
		return
	if rules.combo_required_distinct_success_tags < 2:
		issues.append(_issue("DateRules", "", "combo_required_distinct_success_tags", "combo_required_distinct_success_tags должен быть >= 2."))
	if rules.combo_bonus_score <= 0:
		issues.append(_issue("DateRules", "", "combo_bonus_score", "combo_bonus_score должен быть больше 0."))
	if rules.combo_max_rewards_per_date < 1:
		issues.append(_issue("DateRules", "", "combo_max_rewards_per_date", "combo_max_rewards_per_date должен быть >= 1."))


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


func _check_girl_relationship_bounds(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var world_catalog: GirlCatalog = GirlCatalog.create_seed()
	for girl in catalog.girls:
		if girl == null:
			continue
		var world_girl: GirlDefinition = world_catalog.get_girl(girl.id)
		if world_girl == null:
			issues.append(_issue("GirlProfile", String(girl.id), "id", "GirlProfile не имеет пары в GirlCatalog."))
			continue
		var expected_max: int = GirlCatalog.seed_relationship_max(girl.id)
		if world_girl.relationship_min != 0:
			issues.append(_issue("GirlDefinition", String(girl.id), "relationship_min", "relationship_min должен быть 0."))
		if world_girl.relationship_max != expected_max:
			issues.append(_issue("GirlDefinition", String(girl.id), "relationship_max", "relationship_max должен быть %d." % expected_max))


func _check_required_girl_profiles(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var world_catalog: GirlCatalog = GirlCatalog.create_seed()
	var world_girls: Array[GirlDefinition] = world_catalog.get_all_girls()
	if catalog.girls.size() != world_girls.size():
		issues.append(_issue("GirlProfile", "", "id", "Date Content должен содержать ровно %d профилей." % world_girls.size()))
	for definition in world_girls:
		if definition == null:
			continue
		if catalog.find_girl(definition.id) != null:
			continue
		issues.append(_issue("GirlProfile", String(definition.id), "id", "В каталоге должна быть девушка \"%s\"." % String(definition.id)))


func _check_girl_traits(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var girl_trait: GirlTrait = catalog.find_trait(girl.trait_id)
		if girl_trait == null or not girl_trait.enabled:
			issues.append(_issue("GirlProfile", String(girl.id), "trait_id", "У девушки должен быть ровно один существующий Trait."))
			continue
		match girl_trait.kind:
			GirlTrait.Kind.CHARACTERISTIC:
				var stat: CharacteristicDefinition = catalog.find_characteristic(girl_trait.characteristic_id)
				if stat == null:
					issues.append(_issue("GirlTrait", String(girl_trait.id), "characteristic_id", "Trait характеристики должен ссылаться на каноническую характеристику."))
			GirlTrait.Kind.VENUE:
				var location: DateVenue = catalog.find_venue(girl_trait.date_venue_id)
				if location == null:
					issues.append(_issue("GirlTrait", String(girl_trait.id), "date_venue_id", "Trait места должен ссылаться на существующий DateVenue."))


func _check_initial_known_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var expected: int = 0 if GirlCatalog.is_story_girl_id(girl.id) else 2
		if girl.initial_known_tag_count != expected:
			issues.append(_issue("GirlProfile", String(girl.id), "initial_known_tag_count", "Начальное число известных Tags должно быть %d." % expected))


func _check_requirement_range(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for move in catalog.moves:
		if move == null or move.unlock_requirement == null:
			continue
		var required: int = move.unlock_requirement.required_level
		if required < 0 or required > 5:
			issues.append(_issue("DateMove", String(move.id), "unlock_requirement.required_level", "Требование характеристики должно быть в диапазоне 0..5."))
	for stat in catalog.characteristics:
		if stat == null:
			continue
		if stat.min_level != 0 or stat.max_level != 5:
			issues.append(_issue("CharacteristicDefinition", String(stat.id), "max_level", "Характеристика должна иметь диапазон 0..5."))


func _check_stage_relationship_max(issues: Array[ContentValidationIssue]) -> void:
	var world_catalog: GirlCatalog = GirlCatalog.create_seed()
	for girl_id in [GirlCatalog.ID_ACTRESS, GirlCatalog.ID_MINE_BOSS, GirlCatalog.ID_MAGAZINE_EDITOR, GirlCatalog.ID_SCIENTIST, GirlCatalog.ID_PRESIDENT]:
		var definition: GirlDefinition = world_catalog.get_girl(girl_id)
		if definition == null:
			continue
		var requirement: GirlRelationshipRequirement = StageCatalog.make_girl_relationship_requirement(definition)
		if requirement == null or requirement.target_relationship != definition.relationship_max:
			issues.append(_issue("StageCatalog", String(girl_id), "target_relationship", "StageCatalog должен использовать relationship_max сюжетной девушки."))


func _check_game_terms(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var registry: GameTermRegistry = GameTermRegistry.from_catalog(catalog)
	for term_id in registry.duplicate_ids():
		issues.append(_issue("GameTerm", term_id, "id", "GameTermRegistry содержит повторяющийся id."))
	for alias in registry.ambiguous_aliases():
		issues.append(_issue("GameTerm", alias, "aliases", "Alias игрового термина разрешается неоднозначно."))


func _check_display_copy(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if tag.display_name.strip_edges().is_empty() or tag.description.strip_edges().is_empty():
			issues.append(_issue("DateTag", String(tag.id), "description", "Активный тег должен иметь display_name и description."))
	for stat in catalog.characteristics:
		if stat == null:
			continue
		if stat.display_name.strip_edges().is_empty() or stat.description.strip_edges().is_empty():
			issues.append(_issue("CharacteristicDefinition", String(stat.id), "description", "Характеристика должна иметь display_name и description."))


func _check_tag_move_usage(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var used: Dictionary = {}
	for move in catalog.moves:
		if move == null:
			continue
		if move.has_fixed_presentation() and move.fixed_tag_id != &"":
			used[String(move.fixed_tag_id)] = true
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if used.has(String(tag.id)):
			continue
		issues.append(_issue(
			"DateTag",
			String(tag.id),
			"fixed_tag_id",
			"Активный тег \"%s\" не используется ни в одном DateMove." % String(tag.id),
			DateTypes.ValidationSeverity.WARNING,
			"TAG_WITHOUT_MOVE_MAPPING"
		))


func _check_base_tag_diversity(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	if catalog.enabled_situations().size() < 30:
		return
	var opening: int = 0
	var core: int = 0
	var closing: int = 0
	var tag_counts: Dictionary = {}
	var base_count: int = 0
	for situation in catalog.enabled_situations():
		if situation.allows_phase(DateTypes.DatePhase.OPENING):
			opening += 1
		if situation.allows_phase(DateTypes.DatePhase.CORE):
			core += 1
		if situation.allows_phase(DateTypes.DatePhase.CLOSING):
			closing += 1
		for move_id in situation.base_move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move == null or not move.enabled or move.kind != DateTypes.DateMoveKind.BASE:
				continue
			base_count += 1
			var key: String = String(move.fixed_tag_id)
			tag_counts[key] = int(tag_counts.get(key, 0)) + 1
	if opening != 6 or core != 18 or closing != 6:
		issues.append(_issue("DateContentCatalog", "catalog", "situations", "Baseline pool must be 6 OPENING / 18 CORE / 6 CLOSING, сейчас %d / %d / %d." % [opening, core, closing]))
	if base_count != 180:
		issues.append(_issue("DateContentCatalog", "catalog", "moves", "Baseline pool must contain 180 situation-owned BASE, сейчас %d." % base_count))
	for tag in catalog.enabled_tags():
		var count: int = int(tag_counts.get(String(tag.id), 0))
		if count != 15:
			issues.append(_issue("DateTag", String(tag.id), "fixed_tag_id", "Canonical Tag %s must appear on 15 BASE Moves, сейчас %d." % [String(tag.id), count]))


func _check_duplicate_characteristic_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	pass
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
