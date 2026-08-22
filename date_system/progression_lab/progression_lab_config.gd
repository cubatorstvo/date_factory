class_name ProgressionLabConfig
extends Resource

const SCHEMA_VERSION: int = 1
const ARCHETYPE_EFFICIENT: StringName = &"EFFICIENT"
const ARCHETYPE_TYPICAL: StringName = &"TYPICAL"
const ARCHETYPE_EXPLORER: StringName = &"EXPLORER"
const ARCHETYPE_CHAOTIC: StringName = &"CHAOTIC"
const MODE_POPULATION: StringName = &"POPULATION"
const ISOLATION_MINIMAL: StringName = &"MINIMAL_CONTENT"
const ISOLATION_FULL: StringName = &"FULL_STAGE_CONTENT"

@export var schema_version: int = SCHEMA_VERSION
@export var default_n: int = 1000
@export var default_bad_seed_count: int = 25
@export var default_end_story_stage: int = 4
@export var default_base_seed_start: int = 1
@export var batch_size: int = 100
@export var max_calendar_days: int = 400
@export var max_consecutive_stalled_days: int = 8
@export var trait_jitter: float = 0.15

@export var weight_efficient: float = 0.15
@export var weight_typical: float = 0.50
@export var weight_explorer: float = 0.25
@export var weight_chaotic: float = 0.10

@export var efficient_completionism: float = 0.20
@export var efficient_exploration: float = 0.20
@export var efficient_build_ambition: float = 0.55
@export var efficient_spending_impulsiveness: float = 0.15
@export var efficient_planning_skill: float = 0.95
@export var efficient_dating_skill: float = 0.90
@export var efficient_whimsy: float = 0.10

@export var typical_completionism: float = 0.45
@export var typical_exploration: float = 0.50
@export var typical_build_ambition: float = 0.55
@export var typical_spending_impulsiveness: float = 0.45
@export var typical_planning_skill: float = 0.65
@export var typical_dating_skill: float = 0.70
@export var typical_whimsy: float = 0.25

@export var explorer_completionism: float = 0.85
@export var explorer_exploration: float = 0.95
@export var explorer_build_ambition: float = 0.70
@export var explorer_spending_impulsiveness: float = 0.60
@export var explorer_planning_skill: float = 0.55
@export var explorer_dating_skill: float = 0.60
@export var explorer_whimsy: float = 0.35

@export var chaotic_completionism: float = 0.60
@export var chaotic_exploration: float = 0.75
@export var chaotic_build_ambition: float = 0.80
@export var chaotic_spending_impulsiveness: float = 0.90
@export var chaotic_planning_skill: float = 0.30
@export var chaotic_dating_skill: float = 0.40
@export var chaotic_whimsy: float = 0.70

@export var filler_base_count: int = 2
@export var rival_engage_base: float = 0.10
@export var rival_engage_completionism: float = 0.70
@export var rival_engage_exploration: float = 0.20
@export var rival_interest_lerp_min: float = 0.75
@export var rival_interest_lerp_max: float = 1.25
@export var characteristic_target_base: float = 0.10
@export var characteristic_target_build: float = 0.50
@export var characteristic_target_exploration: float = 0.10
@export var characteristic_interest_lerp_min: float = 0.80
@export var characteristic_interest_lerp_max: float = 1.20
@export var deep_build_base: float = 0.10
@export var deep_build_ambition: float = 0.50
@export var outfit_extra_base: float = 0.05
@export var outfit_extra_build: float = 0.35
@export var outfit_extra_exploration: float = 0.25
@export var outfit_extra_spending: float = 0.25
@export var apartment_object_base: float = 0.05
@export var apartment_object_build: float = 0.45
@export var apartment_object_exploration: float = 0.25
@export var apartment_object_spending: float = 0.20

@export var priority_dress_up: float = 100.0
@export var priority_filler_date: float = 90.0
@export var priority_story_rival: float = 90.0
@export var priority_characteristic: float = 75.0
@export var priority_outfit: float = 70.0
@export var priority_apartment: float = 65.0
@export var priority_ordinary_rival: float = 60.0
@export var priority_venue: float = 35.0
@export var priority_story_girl_before_barrier: float = 55.0
@export var priority_story_girl_after_barrier: float = 100.0
@export var daily_gate_bonus: float = 20.0
@export var unblock_bonus: float = 25.0
@export var novelty_bonus: float = 10.0
@export var repetition_penalty_per_step: float = 8.0
@export var decision_noise_max: float = 15.0
@export var work_priority_offset: float = 5.0

@export var date_known_positive_utility: float = 100.0
@export var date_unknown_utility_scale: float = 35.0
@export var date_known_negative_utility: float = -80.0
@export var date_bonus_point_utility: float = 25.0
@export var date_conservation_scale: float = 25.0
@export var date_noise_skill_scale: float = 80.0
@export var date_noise_whimsy_scale: float = 40.0
@export var venue_known_positive_weight: float = 35.0
@export var venue_unknown_weight: float = 8.0
@export var venue_known_negative_weight: float = 20.0
@export var venue_trait_weight: float = 30.0
@export var venue_exploration_weight: float = 25.0
@export var venue_interest_weight: float = 15.0
@export var venue_price_pressure_scale: float = 40.0
@export var venue_whimsy_noise: float = 20.0
@export var outfit_new_stat_weight: float = 40.0
@export var outfit_known_positive_weight: float = 30.0
@export var outfit_unknown_weight: float = 10.0
@export var outfit_planned_stat_weight: float = 20.0
@export var outfit_whimsy_noise: float = 15.0

@export var badness_work_only_weight: float = 0.20
@export var badness_economy_weight: float = 0.15
@export var badness_money_block_weight: float = 0.15
@export var badness_daily_gate_weight: float = 0.10
@export var badness_dead_days_weight: float = 0.10
@export var badness_calendar_weight: float = 0.10
@export var badness_friction_weight: float = 0.10
@export var badness_novelty_weight: float = 0.10
@export var hard_work_only_days: int = 4
@export var hard_dead_progress_days: int = 2
@export var hard_money_blocked: int = 5
@export var hard_friction_ratio: float = 3.0
@export var hard_friction_support_actions: int = 4
@export var hard_economy_share: float = 0.45
@export var hard_economy_min_actions: int = 12
@export var warning_work_streak_p90: float = 4.0
@export var warning_economy_p50: float = 0.30
@export var warning_economy_p90: float = 0.45
@export var warning_money_block_p90: float = 5.0
@export var warning_dead_days_p90: float = 2.0
@export var warning_friction_p90: float = 3.0
@export var warning_novelty_p10: float = 0.15


func trait_center(archetype: StringName, trait_name: String) -> float:
	match String(archetype):
		"EFFICIENT":
			return _efficient_trait(trait_name)
		"EXPLORER":
			return _explorer_trait(trait_name)
		"CHAOTIC":
			return _chaotic_trait(trait_name)
		_:
			return _typical_trait(trait_name)


func population_weights() -> Dictionary:
	return {
		String(ARCHETYPE_EFFICIENT): weight_efficient,
		String(ARCHETYPE_TYPICAL): weight_typical,
		String(ARCHETYPE_EXPLORER): weight_explorer,
		String(ARCHETYPE_CHAOTIC): weight_chaotic,
	}


func characteristic_milestones() -> PackedInt32Array:
	var values: PackedInt32Array = PackedInt32Array()
	values.append(1)
	values.append(3)
	values.append(5)
	return values


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"default_n": default_n,
		"default_bad_seed_count": default_bad_seed_count,
		"default_end_story_stage": default_end_story_stage,
		"default_base_seed_start": default_base_seed_start,
		"batch_size": batch_size,
		"max_calendar_days": max_calendar_days,
		"max_consecutive_stalled_days": max_consecutive_stalled_days,
		"trait_jitter": trait_jitter,
		"population_weights": population_weights(),
		"trait_centers": {
			"EFFICIENT": _archetype_traits(ARCHETYPE_EFFICIENT),
			"TYPICAL": _archetype_traits(ARCHETYPE_TYPICAL),
			"EXPLORER": _archetype_traits(ARCHETYPE_EXPLORER),
			"CHAOTIC": _archetype_traits(ARCHETYPE_CHAOTIC),
		},
		"stage_plan": {
			"filler_base_count": filler_base_count,
			"rival_engage_base": rival_engage_base,
			"rival_engage_completionism": rival_engage_completionism,
			"rival_engage_exploration": rival_engage_exploration,
			"rival_interest_lerp_min": rival_interest_lerp_min,
			"rival_interest_lerp_max": rival_interest_lerp_max,
			"characteristic_target_base": characteristic_target_base,
			"characteristic_target_build": characteristic_target_build,
			"characteristic_target_exploration": characteristic_target_exploration,
			"characteristic_interest_lerp_min": characteristic_interest_lerp_min,
			"characteristic_interest_lerp_max": characteristic_interest_lerp_max,
			"deep_build_base": deep_build_base,
			"deep_build_ambition": deep_build_ambition,
			"outfit_extra_base": outfit_extra_base,
			"outfit_extra_build": outfit_extra_build,
			"outfit_extra_exploration": outfit_extra_exploration,
			"outfit_extra_spending": outfit_extra_spending,
			"apartment_object_base": apartment_object_base,
			"apartment_object_build": apartment_object_build,
			"apartment_object_exploration": apartment_object_exploration,
			"apartment_object_spending": apartment_object_spending,
		},
		"candidate_scoring": {
			"priority_dress_up": priority_dress_up,
			"priority_filler_date": priority_filler_date,
			"priority_story_rival": priority_story_rival,
			"priority_characteristic": priority_characteristic,
			"priority_outfit": priority_outfit,
			"priority_apartment": priority_apartment,
			"priority_ordinary_rival": priority_ordinary_rival,
			"priority_venue": priority_venue,
			"priority_story_girl_before_barrier": priority_story_girl_before_barrier,
			"priority_story_girl_after_barrier": priority_story_girl_after_barrier,
			"daily_gate_bonus": daily_gate_bonus,
			"unblock_bonus": unblock_bonus,
			"novelty_bonus": novelty_bonus,
			"repetition_penalty_per_step": repetition_penalty_per_step,
			"decision_noise_max": decision_noise_max,
			"work_priority_offset": work_priority_offset,
		},
		"date_utility": {
			"known_positive": date_known_positive_utility,
			"unknown_scale": date_unknown_utility_scale,
			"known_negative": date_known_negative_utility,
			"bonus_point": date_bonus_point_utility,
			"conservation_scale": date_conservation_scale,
			"noise_skill_scale": date_noise_skill_scale,
			"noise_whimsy_scale": date_noise_whimsy_scale,
		},
		"badness_weights": {
			"max_consecutive_work_only_days": badness_work_only_weight,
			"economy_support_share": badness_economy_weight,
			"money_blocked_decision_points": badness_money_block_weight,
			"daily_gate_blocked_decision_points": badness_daily_gate_weight,
			"dead_progress_days": badness_dead_days_weight,
			"calendar_days": badness_calendar_weight,
			"max_goal_friction_ratio": badness_friction_weight,
			"one_minus_novelty_density": badness_novelty_weight,
		},
		"hard_warning_thresholds": {
			"max_consecutive_work_only_days": hard_work_only_days,
			"max_consecutive_dead_progress_days": hard_dead_progress_days,
			"money_blocked_decision_points": hard_money_blocked,
			"max_goal_friction_ratio": hard_friction_ratio,
			"highest_friction_support_actions": hard_friction_support_actions,
			"economy_support_share": hard_economy_share,
			"economy_min_actions": hard_economy_min_actions,
		},
	}


func _archetype_traits(archetype: StringName) -> Dictionary:
	return {
		"completionism": trait_center(archetype, "completionism"),
		"exploration": trait_center(archetype, "exploration"),
		"build_ambition": trait_center(archetype, "build_ambition"),
		"spending_impulsiveness": trait_center(archetype, "spending_impulsiveness"),
		"planning_skill": trait_center(archetype, "planning_skill"),
		"dating_skill": trait_center(archetype, "dating_skill"),
		"whimsy": trait_center(archetype, "whimsy"),
	}


func _efficient_trait(trait_name: String) -> float:
	match trait_name:
		"completionism":
			return efficient_completionism
		"exploration":
			return efficient_exploration
		"build_ambition":
			return efficient_build_ambition
		"spending_impulsiveness":
			return efficient_spending_impulsiveness
		"planning_skill":
			return efficient_planning_skill
		"dating_skill":
			return efficient_dating_skill
		"whimsy":
			return efficient_whimsy
		_:
			return 0.0


func _typical_trait(trait_name: String) -> float:
	match trait_name:
		"completionism":
			return typical_completionism
		"exploration":
			return typical_exploration
		"build_ambition":
			return typical_build_ambition
		"spending_impulsiveness":
			return typical_spending_impulsiveness
		"planning_skill":
			return typical_planning_skill
		"dating_skill":
			return typical_dating_skill
		"whimsy":
			return typical_whimsy
		_:
			return 0.0


func _explorer_trait(trait_name: String) -> float:
	match trait_name:
		"completionism":
			return explorer_completionism
		"exploration":
			return explorer_exploration
		"build_ambition":
			return explorer_build_ambition
		"spending_impulsiveness":
			return explorer_spending_impulsiveness
		"planning_skill":
			return explorer_planning_skill
		"dating_skill":
			return explorer_dating_skill
		"whimsy":
			return explorer_whimsy
		_:
			return 0.0


func _chaotic_trait(trait_name: String) -> float:
	match trait_name:
		"completionism":
			return chaotic_completionism
		"exploration":
			return chaotic_exploration
		"build_ambition":
			return chaotic_build_ambition
		"spending_impulsiveness":
			return chaotic_spending_impulsiveness
		"planning_skill":
			return chaotic_planning_skill
		"dating_skill":
			return chaotic_dating_skill
		"whimsy":
			return chaotic_whimsy
		_:
			return 0.0
