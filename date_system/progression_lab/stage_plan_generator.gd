class_name StagePlanGenerator
extends RefCounted

var config: ProgressionLabConfig
var profile: PlayerProfile
var interests: CampaignInterests
var isolation_mode: StringName = &""
var isolation_characteristic_id: StringName = &""
var isolation_milestone: int = 0


func generate(stage: int, rng: RandomNumberGenerator) -> StagePlan:
	var plan := StagePlan.new()
	plan.stage = stage
	var definition: StageDefinition = _stage_definition(stage)
	if definition != null:
		plan.story_girl_id = definition.story_girl_id
		plan.story_rival_id = definition.story_rival_id
	_generate_fillers(plan, definition, rng)
	_generate_rivals(plan, definition, rng)
	_generate_characteristics(plan, rng)
	_generate_outfits(plan, rng)
	_generate_apartment(plan, rng)
	_generate_venues(plan, rng)
	_append_story_decisions(plan)
	plan.freeze()
	return plan


func _generate_fillers(plan: StagePlan, definition: StageDefinition, rng: RandomNumberGenerator) -> void:
	var fillers: Array[StringName] = []
	if definition != null:
		fillers = definition.filler_girl_ids.duplicate()
	var target_count: int = config.filler_base_count
	if isolation_mode == ProgressionLabConfig.ISOLATION_FULL:
		target_count = mini(3, fillers.size())
	elif isolation_mode == ProgressionLabConfig.ISOLATION_MINIMAL:
		target_count = mini(config.filler_base_count, fillers.size())
	elif rng.randf() < profile.completionism:
		target_count = fillers.size()
	target_count = clampi(target_count, 0, fillers.size())
	var scored: Array = []
	for girl_id in fillers:
		var score: float = 0.75 * interests.value_for(interests.girl_interest, girl_id) + 0.25 * rng.randf()
		if isolation_mode != &"":
			score = float(fillers.find(girl_id))
		scored.append({"id": girl_id, "score": score})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return String(a["id"]) < String(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	for i in range(scored.size()):
		var girl_id: StringName = scored[i]["id"]
		if i < target_count:
			plan.target_filler_girl_ids.append(girl_id)
		else:
			plan.skipped_filler_girl_ids.append(girl_id)
	if plan.target_filler_girl_ids.size() >= fillers.size() and fillers.size() > 0:
		plan.plan_decisions.append("Решил довести до MAX всех трёх filler girls")
	else:
		var names: PackedStringArray = PackedStringArray()
		for girl_id in plan.target_filler_girl_ids:
			names.append(_girl_name(girl_id))
		if names.is_empty():
			plan.plan_decisions.append("Решил не доводить filler girls до MAX")
		else:
			plan.plan_decisions.append("Решил довести до MAX: %s" % ", ".join(names))


func _generate_rivals(plan: StagePlan, definition: StageDefinition, rng: RandomNumberGenerator) -> void:
	var rivals: Array[StringName] = []
	if definition != null:
		rivals = definition.ordinary_rival_ids.duplicate()
	for rival_id in rivals:
		var engage: bool = false
		if isolation_mode == ProgressionLabConfig.ISOLATION_FULL:
			engage = true
		elif isolation_mode == ProgressionLabConfig.ISOLATION_MINIMAL:
			engage = false
		else:
			var engage_probability: float = clampf(
				config.rival_engage_base
				+ config.rival_engage_completionism * profile.completionism
				+ config.rival_engage_exploration * profile.exploration,
				0.0,
				1.0
			)
			var interest_adjustment: float = lerpf(
				config.rival_interest_lerp_min,
				config.rival_interest_lerp_max,
				interests.value_for(interests.rival_interest, rival_id)
			)
			var final_probability: float = clampf(engage_probability * interest_adjustment, 0.0, 1.0)
			engage = rng.randf() < final_probability
		if engage:
			plan.target_ordinary_rival_ids.append(rival_id)
			plan.plan_decisions.append("%s → engage" % _rival_name(rival_id))
		else:
			plan.skipped_ordinary_rival_ids.append(rival_id)
			plan.plan_decisions.append("%s → skip" % _rival_name(rival_id))


func _generate_characteristics(plan: StagePlan, rng: RandomNumberGenerator) -> void:
	var characteristics: Variant = _characteristic_service()
	for characteristic_id in CharacteristicIds.all_ids():
		var current_value: int = 0
		if characteristics != null:
			current_value = int(characteristics.get_value(characteristic_id))
		var include: bool = false
		var target: int = 0
		if isolation_mode != &"" and characteristic_id == isolation_characteristic_id:
			include = true
			target = isolation_milestone
		elif isolation_mode != &"":
			include = false
		else:
			var probability: float = clampf(
				config.characteristic_target_base
				+ config.characteristic_target_build * profile.build_ambition
				+ config.characteristic_target_exploration * profile.exploration,
				0.0,
				1.0
			)
			probability *= lerpf(
				config.characteristic_interest_lerp_min,
				config.characteristic_interest_lerp_max,
				interests.value_for(interests.characteristic_interest, characteristic_id)
			)
			if rng.randf() < probability:
				include = true
				target = _next_milestone(current_value)
				var next_deep: int = _next_milestone(target)
				if next_deep > target:
					var deep_probability: float = config.deep_build_base + config.deep_build_ambition * profile.build_ambition
					if rng.randf() < deep_probability:
						target = next_deep
		if include and target > current_value:
			plan.characteristic_targets[String(characteristic_id)] = target
			plan.plan_decisions.append("%s: current %d → target %d" % [CharacteristicIds.display_name(characteristic_id), current_value, target])
		else:
			plan.plan_decisions.append("%s: no additional target" % CharacteristicIds.display_name(characteristic_id))


func _generate_outfits(plan: StagePlan, rng: RandomNumberGenerator) -> void:
	if plan.stage <= 1:
		plan.target_outfit_count = 0
		plan.plan_decisions.append("Outfit: Stage 1 target count 0")
		return
	var p_extra: float = clampf(
		config.outfit_extra_base
		+ config.outfit_extra_build * profile.build_ambition
		+ config.outfit_extra_exploration * profile.exploration
		+ config.outfit_extra_spending * profile.spending_impulsiveness,
		0.0,
		1.0
	)
	if isolation_mode == ProgressionLabConfig.ISOLATION_MINIMAL:
		plan.target_outfit_count = 1 if plan.stage == 2 else 0
	elif isolation_mode == ProgressionLabConfig.ISOLATION_FULL:
		plan.target_outfit_count = 2 if plan.stage >= 2 else 0
	elif plan.stage == 2:
		plan.target_outfit_count = 1 + _binomial(rng, 3, p_extra)
		plan.target_outfit_count = clampi(plan.target_outfit_count, 1, 4)
	else:
		plan.target_outfit_count = _binomial(rng, 4, p_extra)
	var candidates: Array = _current_stage_outfits(plan.stage)
	var scored: Array = []
	for outfit in candidates:
		if outfit == null:
			continue
		var characteristic_relevance: float = 0.0
		if outfit.stat_id != &"" and plan.characteristic_targets.has(String(outfit.stat_id)):
			characteristic_relevance = 1.0
		var tag_relevance: float = 0.0
		if outfit.outfit_move_id != &"":
			var move_tag: StringName = _move_tag(outfit.outfit_move_id)
			tag_relevance = interests.value_for(interests.tag_interest, move_tag)
		var score: float = 0.55 * characteristic_relevance + 0.25 * tag_relevance + 0.20 * rng.randf()
		scored.append({"id": outfit.id, "score": score, "name": outfit.display_name})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return String(a["id"]) < String(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	var take: int = mini(plan.target_outfit_count, scored.size())
	var names: PackedStringArray = PackedStringArray()
	for i in range(take):
		plan.target_outfit_ids.append(scored[i]["id"])
		names.append(str(scored[i]["name"]))
	plan.target_outfit_count = plan.target_outfit_ids.size()
	plan.plan_decisions.append("Outfit: acquire %d current-stage Outfit" % plan.target_outfit_count)
	if not names.is_empty():
		plan.plan_decisions.append("Outfit priorities: %s" % ", ".join(names))


func _generate_apartment(plan: StagePlan, rng: RandomNumberGenerator) -> void:
	if plan.stage <= 1:
		plan.target_apartment_object_count = 0
		plan.plan_decisions.append("Apartment: Stage 1 target count 0")
		return
	var p_object: float = clampf(
		config.apartment_object_base
		+ config.apartment_object_build * profile.build_ambition
		+ config.apartment_object_exploration * profile.exploration
		+ config.apartment_object_spending * profile.spending_impulsiveness,
		0.0,
		1.0
	)
	var current_stage_objects: Array = _current_stage_apartment_objects(plan.stage)
	if isolation_mode == ProgressionLabConfig.ISOLATION_MINIMAL:
		plan.target_apartment_object_count = 0
	elif isolation_mode == ProgressionLabConfig.ISOLATION_FULL:
		plan.target_apartment_object_count = mini(2, current_stage_objects.size())
	else:
		var count: int = 0
		for _i in range(mini(4, current_stage_objects.size())):
			if rng.randf() < p_object:
				count += 1
		plan.target_apartment_object_count = count
	var scored: Array = []
	for item in current_stage_objects:
		if item == null:
			continue
		var object_tag: StringName = _apartment_object_tag(item)
		var tag_score: float = interests.value_for(interests.tag_interest, object_tag)
		var coverage: float = _known_positive_coverage(object_tag, plan)
		var score: float = 0.55 * tag_score + 0.30 * coverage + 0.15 * rng.randf()
		scored.append({"id": item.id, "score": score, "name": item.display_name})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return String(a["id"]) < String(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	var take: int = mini(plan.target_apartment_object_count, scored.size())
	var names: PackedStringArray = PackedStringArray()
	for i in range(take):
		plan.target_apartment_object_ids.append(scored[i]["id"])
		names.append(str(scored[i]["name"]))
	plan.target_apartment_object_count = plan.target_apartment_object_ids.size()
	plan.plan_decisions.append("Apartment: buy %d objects" % plan.target_apartment_object_count)
	if not names.is_empty():
		plan.plan_decisions.append("Apartment priorities: %s" % ", ".join(names))


func _generate_venues(plan: StagePlan, rng: RandomNumberGenerator) -> void:
	var venue_ids: Array[StringName] = []
	if plan.stage == 2:
		venue_ids.append(&"cafe")
		venue_ids.append(&"leisure_center")
	elif plan.stage == 3:
		venue_ids.append(&"restaurant")
	for venue_id in venue_ids:
		var visit: bool = false
		if isolation_mode != &"":
			visit = false
		else:
			visit = rng.randf() < profile.exploration
		if visit:
			plan.venue_visit_goals.append(venue_id)
			plan.plan_decisions.append("Venue: visit %s at least once" % _venue_name(venue_id))
		else:
			plan.plan_decisions.append("Venue: %s visit goal absent" % _venue_name(venue_id))


func _append_story_decisions(plan: StagePlan) -> void:
	if plan.story_girl_id != &"":
		plan.plan_decisions.append("Story girl mandatory: %s" % _girl_name(plan.story_girl_id))
	if plan.story_rival_id != &"":
		plan.plan_decisions.append("Story rival mandatory: %s" % _rival_name(plan.story_rival_id))


func _next_milestone(current_value: int) -> int:
	for milestone in config.characteristic_milestones():
		if milestone > current_value:
			return milestone
	return current_value


func _binomial(rng: RandomNumberGenerator, trials: int, probability: float) -> int:
	var count: int = 0
	for _i in range(trials):
		if rng.randf() < probability:
			count += 1
	return count


func _current_stage_outfits(stage: int) -> Array:
	var result: Array = []
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return result
	var catalog: OutfitCatalog = equipment.get_catalog()
	if catalog == null:
		return result
	for outfit in catalog.get_purchasable_outfits():
		if outfit != null and outfit.min_story_stage == stage:
			result.append(outfit)
	return result


func _current_stage_apartment_objects(stage: int) -> Array:
	var result: Array = []
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return result
	var catalog: ApartmentCatalog = apartment.get_catalog()
	if catalog == null:
		return result
	for item in catalog.enabled_objects():
		if item != null and item.min_story_stage == stage:
			result.append(item)
	return result


func _apartment_object_tag(item: ApartmentObjectDefinition) -> StringName:
	var dating: Variant = _dating_service()
	if dating == null or item == null:
		return &""
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return &""
	var local_object: DateLocalObject = catalog_service.catalog.find_local_object(item.local_object_id())
	if local_object == null or local_object.move_ids.is_empty():
		return &""
	return _move_tag(local_object.move_ids[0])


func _move_tag(move_id: StringName) -> StringName:
	var dating: Variant = _dating_service()
	if dating == null:
		return &""
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return &""
	var move: DateMove = catalog_service.catalog.find_move(move_id)
	if move == null:
		return &""
	return move.resolved_tag_id()


func _known_positive_coverage(object_tag: StringName, plan: StagePlan) -> float:
	if object_tag == &"":
		return 0.0
	var girls: Variant = _girls_service()
	if girls == null:
		return 0.0
	var known_targets: int = 0
	var matching: int = 0
	for girl_id in plan.target_filler_girl_ids:
		if not bool(girls.is_discovered(girl_id)):
			continue
		known_targets += 1
		var state: GirlState = girls.peek_state(girl_id)
		if state != null and state.revealed_positive_tag_ids.has(object_tag):
			matching += 1
	if plan.story_girl_id != &"" and bool(girls.is_discovered(plan.story_girl_id)):
		known_targets += 1
		var story_state: GirlState = girls.peek_state(plan.story_girl_id)
		if story_state != null and story_state.revealed_positive_tag_ids.has(object_tag):
			matching += 1
	if known_targets <= 0:
		return 0.0
	return float(matching) / float(known_targets)


func _stage_definition(stage: int) -> StageDefinition:
	var stages: Variant = _stage_service()
	if stages == null:
		return null
	var catalog: StageCatalog = stages.get_catalog()
	if catalog == null:
		return null
	return catalog.get_stage(stage)


func _girl_name(girl_id: StringName) -> String:
	var girls: Variant = _girls_service()
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return String(girl_id)


func _rival_name(rival_id: StringName) -> String:
	var rivals: Variant = _rivals_service()
	if rivals != null:
		var definition: RivalDefinition = rivals.get_definition(rival_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return String(rival_id)


func _venue_name(venue_id: StringName) -> String:
	var dating: Variant = _dating_service()
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null and catalog_service.catalog != null:
			var venue: DateVenue = catalog_service.catalog.find_venue(venue_id)
			if venue != null and not venue.display_name.is_empty():
				return venue.display_name
	return String(venue_id)


func _stage_service() -> Variant:
	return _root_node("StageService")


func _girls_service() -> Variant:
	return _root_node("GirlsService")


func _rivals_service() -> Variant:
	return _root_node("RivalsService")


func _characteristic_service() -> Variant:
	return _root_node("CharacteristicService")


func _equipment_service() -> Variant:
	return _root_node("EquipmentService")


func _apartment_service() -> Variant:
	return _root_node("ApartmentService")


func _dating_service() -> Variant:
	return _root_node("DatingService")


func _root_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
