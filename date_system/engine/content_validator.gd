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
	_check_characteristic_moves(catalog, issues)
	_check_outfits(catalog, issues)
	_check_base_usage(catalog, issues)
	_check_situation_base_pool(catalog, issues)
	_check_local_objects(catalog, issues)
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
		for mapping in move.situation_mappings:
			if mapping == null:
				issues.append(_issue("DateMove", String(move.id), "situation_mappings", "Пустой mapping."))
				continue
			if catalog.find_situation(mapping.situation_id) == null:
				issues.append(_issue("DateMove", String(move.id), "situation_id", "Неизвестная Situation: %s." % String(mapping.situation_id)))
			if catalog.find_tag(mapping.tag_id) == null:
				issues.append(_issue("DateMove", String(move.id), "tag_id", "Неизвестный Tag: %s." % String(mapping.tag_id)))
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


func _check_characteristic_moves(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	var characteristic_moves: Array[DateMove] = []
	for move in catalog.moves:
		if move == null or not move.is_characteristic():
			continue
		characteristic_moves.append(move)
		if not move.situation_mappings.is_empty():
			issues.append(_issue("DateMove", String(move.id), "situation_mappings", "Characteristic Move имеет постоянный Tag и не использует situation mappings."))
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
		if not move.situation_mappings.is_empty():
			issues.append(_issue("DateMove", String(move.id), "situation_mappings", "Outfit Move имеет постоянный Tag и не использует situation mappings."))
		if not referenced_outfit_moves.has(String(move.id)):
			issues.append(_issue("DateMove", String(move.id), "kind", "Outfit Move должен быть привязан к Outfit."))

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
	for location in catalog.date_venues:
		if location == null:
			continue
		for object_id in location.local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("DateVenue", String(location.id), "local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))
		if location.enabled and [&"apartment", &"cafe", &"restaurant"].has(location.id):
			if location.local_object_ids.is_empty():
				issues.append(_issue("DateVenue", String(location.id), "local_object_ids", "Активное место должно иметь хотя бы один Local Object."))
	var apartment_catalog: ApartmentCatalog = ApartmentCatalog.create_seed()
	for upgrade in apartment_catalog.get_all_upgrades():
		if upgrade == null:
			continue
		for object_id in upgrade.granted_local_object_ids:
			if catalog.find_local_object(object_id) == null:
				issues.append(_issue("ApartmentUpgradeDefinition", String(upgrade.id), "granted_local_object_ids", "Неизвестный Local Object: %s." % String(object_id)))


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


func _expected_initial_known(girl_id: StringName) -> Array[StringName]:
	match String(girl_id):
		"alina":
			return [&"politeness", &"audacity"]
		"marina":
			return [&"care", &"risk"]
		"vika":
			return [&"humor", &"politeness"]
		"dasha":
			return [&"risk", &"care"]
		"katya":
			return [&"humor", &"status"]
		"lera":
			return [&"status", &"audacity"]
		"kira":
			return [&"audacity", &"flattery"]
		"olya":
			return [&"generosity", &"dominance"]
		"sonya":
			return [&"risk", &"composure"]
		"nika":
			return [&"cunning", &"flattery"]
		"rita":
			return [&"status", &"care"]
		"eva":
			return [&"dominance", &"humor"]
		_:
			var empty: Array[StringName] = []
			return empty


func _check_initial_known_tags(catalog: DateContentCatalog, issues: Array[ContentValidationIssue]) -> void:
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var expected: Array[StringName] = _expected_initial_known(girl.id)
		if GirlCatalog.is_story_girl_id(girl.id):
			if not girl.initial_known_tag_ids.is_empty():
				issues.append(_issue("GirlProfile", String(girl.id), "initial_known_tag_ids", "У сюжетной девушки начально известные Tags должны быть пустыми."))
			continue
		var positive_count: int = 0
		var negative_count: int = 0
		for tag_id in girl.initial_known_tag_ids:
			var tag: DateTag = catalog.find_tag(tag_id)
			if tag == null or not tag.enabled:
				issues.append(_issue("GirlProfile", String(girl.id), "initial_known_tag_ids", "Начально известный Tag не существует или отключён: %s." % String(tag_id)))
				continue
			if girl.prefers_tag(tag_id) > 0:
				positive_count += 1
			else:
				negative_count += 1
		if girl.initial_known_tag_ids.size() != 2 or positive_count != 1 or negative_count != 1:
			issues.append(_issue("GirlProfile", String(girl.id), "initial_known_tag_ids", "У обычной девушки должны быть ровно один положительный и один отрицательный начально известный Tag."))
		if girl.initial_known_tag_ids.size() == expected.size():
			var matches: bool = true
			for tag_id in expected:
				if not girl.initial_known_tag_ids.has(tag_id):
					matches = false
					break
			if not matches:
				issues.append(_issue("GirlProfile", String(girl.id), "initial_known_tag_ids", "Начально известные Tags не совпадают с канонической таблицей."))


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
		for mapping in move.situation_mappings:
			if mapping == null:
				continue
			used[String(mapping.tag_id)] = true
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
