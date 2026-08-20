class_name DateBalanceDiagnostics
extends RefCounted


func theoretical_availability(catalog: DateContentCatalog, girl: GirlProfile) -> float:
	if catalog == null or girl == null:
		return 0.0
	var preset: GirlDifficultyPreset = catalog.find_girl_difficulty(girl.difficulty_preset_id)
	var positive_count: int = girl.positive_tag_ids.size()
	if preset != null:
		positive_count = preset.positive_tag_count
	var draws: int = 3
	if catalog.date_rules != null:
		draws = catalog.date_rules.base_moves_per_episode
	return DateBalanceMath.at_least_one_positive_probability(catalog.enabled_tags().size(), positive_count, draws)


func simulate_girl(catalog: DateContentCatalog, girl: GirlProfile, seed_count: int = 10000) -> Dictionary:
	var situation_rows: Array = []
	var total_episodes: int = 0
	var total_at_least: int = 0
	var total_all_negative: int = 0
	var total_positive_count: int = 0
	if catalog == null or girl == null:
		return _aggregate(situation_rows, total_episodes, total_at_least, total_all_negative, total_positive_count)
	var positives: Dictionary = {}
	for tag_id in girl.positive_tag_ids:
		positives[String(tag_id)] = true
	for situation in catalog.enabled_situations():
		var row: Dictionary = _simulate_situation(catalog, girl, situation, positives, seed_count)
		situation_rows.append(row)
		total_episodes += int(row["episodes"])
		total_at_least += int(row["at_least_one_count"])
		total_all_negative += int(row["all_negative_count"])
		total_positive_count += int(row["positive_sum"])
	return _aggregate(situation_rows, total_episodes, total_at_least, total_all_negative, total_positive_count)


func _simulate_situation(
	catalog: DateContentCatalog,
	girl: GirlProfile,
	situation: DateSituation,
	positives: Dictionary,
	seed_count: int
) -> Dictionary:
	var lean: DateContentCatalog = _lean_catalog(catalog, girl, situation)
	var at_least: int = 0
	var all_negative: int = 0
	var positive_sum: int = 0
	for seed in range(1, seed_count + 1):
		var engine: DateEngine = DateEngine.new()
		var config: DateSessionConfig = DateSessionConfig.new()
		config.catalog = lean
		config.girl_id = girl.id
		config.location_id = &"cafe"
		config.outfit_id = &"casual"
		config.seed = seed
		config.girl_progress = GirlProgress.new()
		config.girl_progress.reset_to_profile(girl)
		config.player_state = TestPlayerState.new()
		engine.create_date_session(config)
		var hit: int = 0
		for tag_id in engine.get_session_state().current_selected_base_tag_ids:
			if positives.has(String(tag_id)):
				hit += 1
		positive_sum += hit
		if hit > 0:
			at_least += 1
		else:
			all_negative += 1
	return {
		"situation_id": String(situation.id),
		"situation_name": situation.display_name,
		"episodes": seed_count,
		"at_least_one_count": at_least,
		"all_negative_count": all_negative,
		"positive_sum": positive_sum,
		"at_least_one": float(at_least) / float(seed_count),
		"all_negative": float(all_negative) / float(seed_count),
		"average_positive": float(positive_sum) / float(seed_count),
	}


func _lean_catalog(catalog: DateContentCatalog, girl: GirlProfile, situation: DateSituation) -> DateContentCatalog:
	var lean := DateContentCatalog.new()
	lean.tags = catalog.tags
	lean.moves = catalog.moves
	lean.progression_stats = catalog.progression_stats
	lean.girl_difficulty_presets = catalog.girl_difficulty_presets
	var girls: Array[GirlProfile] = []
	girls.append(girl)
	lean.girls = girls
	var situations: Array[DateSituation] = []
	situations.append(situation)
	lean.situations = situations
	var locations: Array[DateLocation] = []
	var cafe: DateLocation = catalog.find_location(&"cafe")
	if cafe != null:
		locations.append(cafe)
	lean.locations = locations
	var outfits: Array[Outfit] = []
	var casual: Outfit = catalog.find_outfit(&"casual")
	if casual != null:
		outfits.append(casual)
	lean.outfits = outfits
	var rules: DateRules = catalog.date_rules.duplicate() as DateRules
	rules.opening_episode_count = 0
	rules.core_episode_count = 0
	rules.closing_episode_count = 0
	if situation.allowed_phases.has(int(DateTypes.DatePhase.OPENING)):
		rules.opening_episode_count = 1
	elif situation.allowed_phases.has(int(DateTypes.DatePhase.CORE)):
		rules.core_episode_count = 1
	else:
		rules.closing_episode_count = 1
	lean.date_rules = rules
	return lean


func _aggregate(
	situation_rows: Array,
	total_episodes: int,
	total_at_least: int,
	total_all_negative: int,
	total_positive_count: int
) -> Dictionary:
	var at_least: float = 0.0
	var all_negative: float = 0.0
	var average_positive: float = 0.0
	if total_episodes > 0:
		at_least = float(total_at_least) / float(total_episodes)
		all_negative = float(total_all_negative) / float(total_episodes)
		average_positive = float(total_positive_count) / float(total_episodes)
	return {
		"situations": situation_rows,
		"episodes": total_episodes,
		"at_least_one": at_least,
		"all_negative": all_negative,
		"average_positive": average_positive,
	}
