class_name PlayerProfile
extends RefCounted

const TRAIT_NAMES: PackedStringArray = [
	"completionism",
	"exploration",
	"build_ambition",
	"spending_impulsiveness",
	"planning_skill",
	"dating_skill",
	"whimsy",
]

var archetype: StringName = ProgressionLabConfig.ARCHETYPE_TYPICAL
var completionism: float = 0.0
var exploration: float = 0.0
var build_ambition: float = 0.0
var spending_impulsiveness: float = 0.0
var planning_skill: float = 0.0
var dating_skill: float = 0.0
var whimsy: float = 0.0


static func pick_archetype(config: ProgressionLabConfig, rng: RandomNumberGenerator, archetype_mode: StringName) -> StringName:
	if archetype_mode != ProgressionLabConfig.MODE_POPULATION:
		if archetype_mode == ProgressionLabConfig.ARCHETYPE_EFFICIENT:
			return ProgressionLabConfig.ARCHETYPE_EFFICIENT
		if archetype_mode == ProgressionLabConfig.ARCHETYPE_EXPLORER:
			return ProgressionLabConfig.ARCHETYPE_EXPLORER
		if archetype_mode == ProgressionLabConfig.ARCHETYPE_CHAOTIC:
			return ProgressionLabConfig.ARCHETYPE_CHAOTIC
		return ProgressionLabConfig.ARCHETYPE_TYPICAL
	var roll: float = rng.randf()
	var cursor: float = 0.0
	var weights: Dictionary = config.population_weights()
	var order: PackedStringArray = PackedStringArray([
		String(ProgressionLabConfig.ARCHETYPE_EFFICIENT),
		String(ProgressionLabConfig.ARCHETYPE_TYPICAL),
		String(ProgressionLabConfig.ARCHETYPE_EXPLORER),
		String(ProgressionLabConfig.ARCHETYPE_CHAOTIC),
	])
	for key in order:
		var weight_value: Variant = weights.get(key, 0.0)
		cursor += float(weight_value)
		if roll <= cursor:
			return StringName(key)
	return ProgressionLabConfig.ARCHETYPE_TYPICAL


static func generate(config: ProgressionLabConfig, rng: RandomNumberGenerator, archetype_mode: StringName, jitter_override: float = -1.0) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.archetype = pick_archetype(config, rng, archetype_mode)
	var jitter: float = config.trait_jitter
	if jitter_override >= 0.0:
		jitter = jitter_override
	for trait_name in TRAIT_NAMES:
		var center: float = config.trait_center(profile.archetype, trait_name)
		var u1: float = rng.randf()
		var u2: float = rng.randf()
		var value: float = clampf(center + (u1 + u2 - 1.0) * jitter, 0.0, 1.0)
		profile.set_trait(trait_name, value)
	return profile


func set_trait(trait_name: String, value: float) -> void:
	match trait_name:
		"completionism":
			completionism = value
		"exploration":
			exploration = value
		"build_ambition":
			build_ambition = value
		"spending_impulsiveness":
			spending_impulsiveness = value
		"planning_skill":
			planning_skill = value
		"dating_skill":
			dating_skill = value
		"whimsy":
			whimsy = value


func get_trait(trait_name: String) -> float:
	match trait_name:
		"completionism":
			return completionism
		"exploration":
			return exploration
		"build_ambition":
			return build_ambition
		"spending_impulsiveness":
			return spending_impulsiveness
		"planning_skill":
			return planning_skill
		"dating_skill":
			return dating_skill
		"whimsy":
			return whimsy
		_:
			return 0.0


func to_dict() -> Dictionary:
	return {
		"archetype": String(archetype),
		"completionism": completionism,
		"exploration": exploration,
		"build_ambition": build_ambition,
		"spending_impulsiveness": spending_impulsiveness,
		"planning_skill": planning_skill,
		"dating_skill": dating_skill,
		"whimsy": whimsy,
	}


static func from_dict(data: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.archetype = StringName(str(data.get("archetype", "TYPICAL")))
	profile.completionism = float(data.get("completionism", 0.0))
	profile.exploration = float(data.get("exploration", 0.0))
	profile.build_ambition = float(data.get("build_ambition", 0.0))
	profile.spending_impulsiveness = float(data.get("spending_impulsiveness", 0.0))
	profile.planning_skill = float(data.get("planning_skill", 0.0))
	profile.dating_skill = float(data.get("dating_skill", 0.0))
	profile.whimsy = float(data.get("whimsy", 0.0))
	return profile
