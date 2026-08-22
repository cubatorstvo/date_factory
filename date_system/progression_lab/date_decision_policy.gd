class_name DateDecisionPolicy
extends RefCounted

var config: ProgressionLabConfig
var profile: PlayerProfile
var interests: CampaignInterests
var plan: StagePlan
var rng: RandomNumberGenerator
var consume_rng: bool = true


func choose_venue(girl_id: StringName) -> StringName:
	var dating: Variant = _dating_service()
	if dating == null:
		return &"apartment"
	var best_id: StringName = &""
	var best_score: float = -INF
	for venue in dating.get_available_date_venues(girl_id):
		if venue == null:
			continue
		if not bool(dating.is_date_venue_available(girl_id, venue.id)):
			continue
		var score: float = _venue_score(girl_id, venue)
		if score > best_score or (score == best_score and String(venue.id) < String(best_id)):
			best_score = score
			best_id = venue.id
	if best_id == &"":
		return &"apartment"
	return best_id


func choose_outfits(girl_id: StringName, venue_id: StringName, require_dressed: bool = false) -> Dictionary:
	var equipment: Variant = _equipment_service()
	var owned: Array = []
	if equipment != null:
		owned = equipment.get_owned_outfits()
	var scored: Array = []
	for outfit in owned:
		if outfit == null:
			continue
		if require_dressed and int(outfit.tier) < 1:
			continue
		scored.append({"id": outfit.id, "score": _outfit_score(girl_id, venue_id, outfit)})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return String(a["id"]) < String(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	var primary: StringName = OutfitCatalog.START_OUTFIT_ID
	var backup: StringName = &""
	if not scored.is_empty():
		primary = scored[0]["id"]
	var girls: Variant = _girls_service()
	if girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_NIKA_BACKUP_OUTFIT)) and scored.size() >= 2:
		backup = scored[1]["id"]
	return {
		"outfit_id": primary,
		"backup_outfit_id": backup,
	}


func play_date(engine: DateEngine) -> Dictionary:
	var moves_used: PackedStringArray = PackedStringArray()
	var situations: PackedStringArray = PackedStringArray()
	var tags: PackedStringArray = PackedStringArray()
	var nika_swap: bool = false
	if engine == null:
		return {
			"moves": moves_used,
			"situations": situations,
			"tags": tags,
			"nika_swap": nika_swap,
		}
	for _episode in range(5):
		var session: DateSession = engine.get_session_state()
		if session == null:
			break
		if session.stage == DateSession.Stage.COMPLETED or session.stage == DateSession.Stage.ABORTED:
			break
		if session.stage == DateSession.Stage.AWAITING_MOVE:
			var options: Array[DateMoveOption] = engine.get_available_moves()
			var chosen: DateMoveOption = _choose_move(engine, options)
			if chosen == null:
				break
			if engine.can_queue_outfit_swap() and not nika_swap and profile.whimsy > 0.5:
				engine.set_pending_outfit_swap(true)
				nika_swap = true
			engine.choose_move(chosen.move_id)
			moves_used.append(String(chosen.move_id))
			if chosen.tag_id != &"":
				tags.append("%s:%s" % [String(chosen.tag_id), _knowledge_name(chosen.tag_knowledge)])
			if session.current_episode_index < session.selected_situation_ids.size():
				situations.append(String(session.selected_situation_ids[session.current_episode_index]))
			engine.advance()
		elif session.stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
		elif session.stage == DateSession.Stage.SHOWING_DATE_RESULT:
			engine.advance()
			break
	var session_end: DateSession = engine.get_session_state()
	if session_end != null and session_end.stage == DateSession.Stage.SHOWING_DATE_RESULT:
		engine.advance()
	if session_end != null and session_end.outfit_swap_used:
		nika_swap = true
	return {
		"moves": moves_used,
		"situations": situations,
		"tags": tags,
		"nika_swap": nika_swap,
	}


func _choose_move(engine: DateEngine, options: Array[DateMoveOption]) -> DateMoveOption:
	var best: DateMoveOption = null
	var best_score: float = -INF
	for option in options:
		if option == null or not option.is_selectable():
			continue
		var score: float = _move_utility(engine, option)
		if score > best_score or (score == best_score and String(option.move_id) < String(best.move_id if best != null else &"")):
			best_score = score
			best = option
	return best


func _move_utility(engine: DateEngine, option: DateMoveOption) -> float:
	var base_utility: float = 0.0
	if option.tag_knowledge == DateTypes.TagKnowledge.POSITIVE:
		base_utility = config.date_known_positive_utility
	elif option.tag_knowledge == DateTypes.TagKnowledge.NEGATIVE:
		base_utility = config.date_known_negative_utility
	else:
		var progress: GirlProgress = engine.girl_progress()
		var girl: GirlProfile = null
		var catalog: DateContentCatalog = engine.catalog()
		if catalog != null:
			var session: DateSession = engine.get_session_state()
			if session != null:
				girl = catalog.find_girl(session.girl_id)
		var remaining_unknown: int = 1
		var remaining_positive: int = 0
		if progress != null and girl != null:
			remaining_unknown = maxi(1, progress.unknown_tag_count(girl, catalog))
			remaining_positive = progress.unknown_positive_tag_count(girl, catalog)
		var p_positive: float = float(remaining_positive) / float(remaining_unknown)
		var expected: float = p_positive * 1.0 + (1.0 - p_positive) * -1.0
		base_utility = config.date_unknown_utility_scale * expected
	var bonus: float = _bonus_awareness(engine, option)
	var conservation: float = _conservation_penalty(engine, option)
	var noise_amplitude: float = config.date_noise_skill_scale * (1.0 - profile.dating_skill) + config.date_noise_whimsy_scale * profile.whimsy
	var move_noise: float = rng.randf_range(-noise_amplitude, noise_amplitude)
	return base_utility + bonus - conservation + move_noise


func _bonus_awareness(engine: DateEngine, option: DateMoveOption) -> float:
	var bonus: float = 0.0
	var session: DateSession = engine.get_session_state()
	var catalog: DateContentCatalog = engine.catalog()
	if session == null or catalog == null:
		return bonus
	var girl: GirlProfile = catalog.find_girl(session.girl_id)
	if girl == null:
		return bonus
	var girl_trait: GirlTrait = catalog.find_trait(girl.trait_id)
	if girl_trait != null and girl_trait.kind == GirlTrait.Kind.CHARACTERISTIC:
		if option.requirement_stat_id == girl_trait.characteristic_id and not session.girl_trait_applied:
			bonus += config.date_bonus_point_utility
	if girl_trait != null and girl_trait.kind == GirlTrait.Kind.VENUE and option.kind == DateTypes.DateMoveKind.LOCAL:
		if session.venue_id == girl_trait.date_venue_id:
			bonus += 0.0
	if option.local_object_id != &"" and session.accent_object_id == option.local_object_id and option.tag_knowledge == DateTypes.TagKnowledge.POSITIVE:
		bonus += config.date_bonus_point_utility
	if session.dasha_soften_available and not session.dasha_soften_used and option.tag_knowledge == DateTypes.TagKnowledge.NEGATIVE:
		bonus += config.date_bonus_point_utility
	return bonus


func _conservation_penalty(engine: DateEngine, option: DateMoveOption) -> float:
	if option.kind == DateTypes.DateMoveKind.BASE:
		return 0.0
	var session: DateSession = engine.get_session_state()
	if session == null:
		return 0.0
	var remaining_uses: int = 1
	if option.kind == DateTypes.DateMoveKind.CHARACTERISTIC and session.characteristic_source_used:
		remaining_uses = 0
	elif option.kind == DateTypes.DateMoveKind.OUTFIT and session.outfit_source_used:
		remaining_uses = 0
	elif option.kind == DateTypes.DateMoveKind.LOCAL:
		remaining_uses = maxi(0, session.venue_source_limit - session.venue_source_uses)
	if remaining_uses != 1:
		return 0.0
	var catalog: DateContentCatalog = engine.catalog()
	var total: int = 5
	if catalog != null and catalog.date_rules != null:
		total = catalog.date_rules.total_episode_count()
	var remaining_after: int = maxi(0, total - session.current_episode_index - 1)
	var ratio: float = float(remaining_after) / 4.0
	return config.date_conservation_scale * ratio * profile.planning_skill


func _venue_score(girl_id: StringName, venue: DateVenue) -> float:
	var dating: Variant = _dating_service()
	var girls: Variant = _girls_service()
	var catalog: DateContentCatalog = null
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null:
			catalog = catalog_service.catalog
	var known_positive: int = 0
	var unknown: int = 0
	var known_negative: int = 0
	var progress := GirlProgress.new()
	var girl: GirlProfile = null
	if catalog != null:
		girl = catalog.find_girl(girl_id)
		if girl != null:
			progress.reset_to_profile(girl)
		if girls != null:
			girls.fill_date_progress(girl_id, progress)
	var local_ids: Array[StringName] = []
	if dating != null:
		local_ids = dating.resolve_date_local_object_ids(venue.id)
	if catalog != null:
		for object_id in local_ids:
			var local_object: DateLocalObject = catalog.find_local_object(object_id)
			if local_object == null:
				continue
			for move_id in local_object.move_ids:
				var move: DateMove = catalog.find_move(move_id)
				if move == null:
					continue
				var knowledge: DateTypes.TagKnowledge = progress.tag_knowledge(move.resolved_tag_id(), girl)
				if knowledge == DateTypes.TagKnowledge.POSITIVE:
					known_positive += 1
				elif knowledge == DateTypes.TagKnowledge.NEGATIVE:
					known_negative += 1
				else:
					unknown += 1
	var trait_bonus: float = 0.0
	if catalog != null and girl != null:
		var girl_trait: GirlTrait = catalog.find_trait(girl.trait_id)
		if girl_trait != null and girl_trait.kind == GirlTrait.Kind.VENUE and girl_trait.date_venue_id == venue.id:
			trait_bonus = 1.0
	var exploration_bonus: float = 0.0
	if plan != null and plan.venue_visit_goals.has(venue.id):
		exploration_bonus = 1.0
	var money: int = 0
	var economy: Variant = _economy_service()
	if economy != null:
		money = int(economy.get_money())
	var work_income: int = WorkService.get_current_hourly_pay()
	var price_pressure: float = config.venue_price_pressure_scale * float(venue.price) / float(maxi(money + work_income, 1)) * profile.planning_skill
	var interest: float = interests.value_for(interests.venue_interest, venue.id)
	var noise: float = 0.0
	if consume_rng and rng != null:
		noise = rng.randf_range(-config.venue_whimsy_noise, config.venue_whimsy_noise) * profile.whimsy
	return (
		config.venue_known_positive_weight * float(known_positive)
		+ config.venue_unknown_weight * float(unknown)
		- config.venue_known_negative_weight * float(known_negative)
		+ config.venue_trait_weight * trait_bonus
		+ config.venue_exploration_weight * exploration_bonus
		+ config.venue_interest_weight * interest
		- price_pressure
		+ noise
	)


func _outfit_score(girl_id: StringName, _venue_id: StringName, outfit: Outfit) -> float:
	var newly_satisfied: int = 0
	var characteristics: Variant = _characteristic_service()
	var dating: Variant = _dating_service()
	var catalog: DateContentCatalog = null
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null:
			catalog = catalog_service.catalog
	if characteristics != null and catalog != null:
		for move in catalog.moves:
			if move == null or not move.is_characteristic() or move.unlock_requirement == null:
				continue
			var required: int = move.unlock_requirement.required_level
			var stat_id: StringName = move.unlock_requirement.stat_id
			var base_value: int = int(characteristics.get_value(stat_id))
			var with_outfit: int = DateTypes.effective_stat(base_value, outfit, stat_id)
			if base_value < required and with_outfit >= required:
				newly_satisfied += 1
	var known_positive: float = 0.0
	var unknown: float = 0.0
	if outfit.outfit_move_id != &"" and catalog != null:
		var move: DateMove = catalog.find_move(outfit.outfit_move_id)
		var girls: Variant = _girls_service()
		var progress := GirlProgress.new()
		var girl: GirlProfile = catalog.find_girl(girl_id)
		if girl != null:
			progress.reset_to_profile(girl)
		if girls != null:
			girls.fill_date_progress(girl_id, progress)
		if move != null:
			var knowledge: DateTypes.TagKnowledge = progress.tag_knowledge(move.resolved_tag_id(), girl)
			if knowledge == DateTypes.TagKnowledge.POSITIVE:
				known_positive = 1.0
			elif knowledge == DateTypes.TagKnowledge.UNKNOWN:
				unknown = 1.0
	var planned: float = 0.0
	if plan != null and outfit.stat_id != &"" and plan.characteristic_targets.has(String(outfit.stat_id)):
		planned = 1.0
	var noise: float = 0.0
	if consume_rng and rng != null:
		noise = rng.randf_range(-config.outfit_whimsy_noise, config.outfit_whimsy_noise) * profile.whimsy
	return (
		config.outfit_new_stat_weight * float(newly_satisfied)
		+ config.outfit_known_positive_weight * known_positive
		+ config.outfit_unknown_weight * unknown
		+ config.outfit_planned_stat_weight * planned
		+ noise
	)


func _knowledge_name(knowledge: DateTypes.TagKnowledge) -> String:
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE:
			return "positive"
		DateTypes.TagKnowledge.NEGATIVE:
			return "negative"
		_:
			return "unknown"


func _dating_service() -> Variant:
	return _root_node("DatingService")


func _girls_service() -> Variant:
	return _root_node("GirlsService")


func _equipment_service() -> Variant:
	return _root_node("EquipmentService")


func _characteristic_service() -> Variant:
	return _root_node("CharacteristicService")


func _economy_service() -> Variant:
	return _root_node("EconomyService")


func _root_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
