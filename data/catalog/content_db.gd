extends Node
## Read-only static content database (MODULE 03).
## Autoload name: ContentDB. Does not touch GameState.

const CATALOG_PATH: String = "res://data/catalog/content_catalog.tres"

const RESERVED_STORY_GIRL_IDS: Array[StringName] = [
	&"girl_neighbor",
	&"girl_actress",
	&"girl_mine_boss",
	&"girl_magazine_editor",
	&"girl_scientist",
	&"girl_president",
	&"girl_final_target",
]

const RESERVED_STORY_RIVAL_IDS: Array[StringName] = [
	&"rival_actress",
	&"rival_mine_boss",
	&"rival_magazine_editor",
	&"rival_scientist",
	&"rival_president",
]

const CANONICAL_LOCATION_IDS: Array[StringName] = [
	&"apartment",
	&"city_hub",
	&"cafe",
	&"gym",
	&"appearance_space",
	&"salary_mine",
	&"laboratory",
	&"production_area",
	&"final_location",
]

const CANONICAL_PERK_IDS: Array[StringName] = [
	&"perk_muscle_no_warmup",
	&"perk_muscle_tough_cheek",
	&"perk_muscle_double_slap",
	&"perk_muscle_counter_argument",
	&"perk_muscle_hold_doorway",
	&"perk_muscle_heroic_defeat",
	&"perk_muscle_mass_reserve",
	&"perk_muscle_two_handed_argument",
	&"perk_appearance_good_profile",
	&"perk_appearance_staged_walk",
	&"perk_appearance_pocket_mirror",
	&"perk_appearance_control_profile",
	&"perk_appearance_second_outfit",
	&"perk_appearance_encore",
	&"perk_appearance_rhythm_in_body",
	&"perk_appearance_public_significance",
	&"perk_capital_payable_intent",
	&"perk_capital_representation_expenses",
	&"perk_capital_buy_problem",
	&"perk_capital_hostile_acquisition",
	&"perk_capital_salary_advance",
	&"perk_capital_dignity_refund",
	&"perk_capital_financial_inertia",
	&"perk_capital_no_limit",
	&"perk_aura_presence_registered",
	&"perk_aura_dont_blink_first",
	&"perk_aura_silence_longer",
	&"perk_aura_reverse_pressure",
	&"perk_aura_right_to_say_nothing",
	&"perk_aura_she_already_started",
	&"perk_aura_atmospheric_influence",
	&"perk_aura_local_significance",
]

var _catalog: ContentCatalog = null
var _primary_by_trait: Dictionary = {}
var _secondary_by_trait: Dictionary = {}
var _girls_by_id: Dictionary = {}
var _rivals_by_id: Dictionary = {}
var _events_by_id: Dictionary = {}
var _pools_by_id: Dictionary = {}
var _perks_by_id: Dictionary = {}
var _competitions_by_type: Dictionary = {}
var _locations_by_id: Dictionary = {}
var _stages_by_stage: Dictionary = {}
var _appearances_by_id: Dictionary = {}
var _animations_by_id: Dictionary = {}
var _discovery_situations_by_id: Dictionary = {}
var _discovery_approaches_by_id: Dictionary = {}
var _ready_ok: bool = false


func _ready() -> void:
	var catalog: Resource = load(CATALOG_PATH)
	if catalog == null or not (catalog is ContentCatalog):
		push_error("[ContentDB] Failed to load ContentCatalog at %s" % CATALOG_PATH)
		DfLog.error("MODULE_03", "ContentDB catalog load failed")
		return
	_catalog = catalog as ContentCatalog
	_index_catalog(_catalog)
	var result: Dictionary = validate_catalog(_catalog)
	if not bool(result.get("ok", false)):
		var errors: Array = result.get("errors", []) as Array
		for err in errors:
			push_error("[ContentDB] %s" % str(err))
		DfLog.error("MODULE_03", "ContentDB validate_all failed (%s errors)" % errors.size())
	else:
		_ready_ok = true
		DfLog.info("MODULE_03", "ContentDB ready")


func is_ready_ok() -> bool:
	return _ready_ok


func get_catalog() -> ContentCatalog:
	return _catalog


func get_primary_trait(primary_trait: GameTypes.PrimaryGirlTrait) -> PrimaryTraitDefinition:
	if not _primary_by_trait.has(primary_trait):
		push_error("[ContentDB] missing primary trait: %s" % primary_trait)
		return null
	return _primary_by_trait[primary_trait] as PrimaryTraitDefinition


func get_secondary_trait(secondary_trait: GameTypes.SecondaryGirlTrait) -> SecondaryTraitDefinition:
	if not _secondary_by_trait.has(secondary_trait):
		push_error("[ContentDB] missing secondary trait: %s" % secondary_trait)
		return null
	return _secondary_by_trait[secondary_trait] as SecondaryTraitDefinition


func get_girl(id: StringName) -> GirlDefinition:
	if not _girls_by_id.has(id):
		push_error("[ContentDB] missing girl: %s" % String(id))
		return null
	return _girls_by_id[id] as GirlDefinition


func get_rival(id: StringName) -> RivalDefinition:
	if not _rivals_by_id.has(id):
		push_error("[ContentDB] missing rival: %s" % String(id))
		return null
	return _rivals_by_id[id] as RivalDefinition


func get_dating_event(id: StringName) -> DatingEventDefinition:
	if not _events_by_id.has(id):
		push_error("[ContentDB] missing dating event: %s" % String(id))
		return null
	return _events_by_id[id] as DatingEventDefinition


func get_dating_pool(id: StringName) -> DatingEventPoolDefinition:
	if not _pools_by_id.has(id):
		push_error("[ContentDB] missing dating pool: %s" % String(id))
		return null
	return _pools_by_id[id] as DatingEventPoolDefinition


func get_perk(id: StringName) -> PerkDefinition:
	if not _perks_by_id.has(id):
		push_error("[ContentDB] missing perk: %s" % String(id))
		return null
	return _perks_by_id[id] as PerkDefinition


func get_competition(competition_type: GameTypes.CompetitionType) -> CompetitionDefinition:
	if not _competitions_by_type.has(competition_type):
		push_error("[ContentDB] missing competition: %s" % competition_type)
		return null
	return _competitions_by_type[competition_type] as CompetitionDefinition


func get_location(id: StringName) -> LocationDefinition:
	if not _locations_by_id.has(id):
		push_error("[ContentDB] missing location: %s" % String(id))
		return null
	return _locations_by_id[id] as LocationDefinition


func get_stage(stage: GameTypes.GameStage) -> StoryStageDefinition:
	if not _stages_by_stage.has(stage):
		push_error("[ContentDB] missing stage: %s" % stage)
		return null
	return _stages_by_stage[stage] as StoryStageDefinition


func get_appearance_profile(id: StringName) -> AppearanceProfileDefinition:
	if not _appearances_by_id.has(id):
		push_error("[ContentDB] missing appearance profile: %s" % String(id))
		return null
	return _appearances_by_id[id] as AppearanceProfileDefinition


func get_animation_profile(id: StringName) -> AnimationProfileDefinition:
	if not _animations_by_id.has(id):
		push_error("[ContentDB] missing animation profile: %s" % String(id))
		return null
	return _animations_by_id[id] as AnimationProfileDefinition


func get_discovery_situation(id: StringName) -> DiscoverySituationDefinition:
	if not _discovery_situations_by_id.has(id):
		push_error("[ContentDB] missing discovery situation: %s" % String(id))
		return null
	return _discovery_situations_by_id[id] as DiscoverySituationDefinition


func find_discovery_approach(approach_id: StringName) -> DiscoveryApproachDefinition:
	if not _discovery_approaches_by_id.has(approach_id):
		return null
	return _discovery_approaches_by_id[approach_id] as DiscoveryApproachDefinition


func list_primary_traits() -> Array[PrimaryTraitDefinition]:
	return _catalog.primary_traits if _catalog != null else []


func list_secondary_traits() -> Array[SecondaryTraitDefinition]:
	return _catalog.secondary_traits if _catalog != null else []


func list_girls() -> Array[GirlDefinition]:
	return _catalog.girls if _catalog != null else []


func list_rivals() -> Array[RivalDefinition]:
	return _catalog.rivals if _catalog != null else []


func list_dating_events() -> Array[DatingEventDefinition]:
	return _catalog.dating_events if _catalog != null else []


func list_dating_pools() -> Array[DatingEventPoolDefinition]:
	return _catalog.dating_pools if _catalog != null else []


func list_perks() -> Array[PerkDefinition]:
	return _catalog.perks if _catalog != null else []


func list_competitions() -> Array[CompetitionDefinition]:
	return _catalog.competitions if _catalog != null else []


func list_locations() -> Array[LocationDefinition]:
	return _catalog.locations if _catalog != null else []


func list_stages() -> Array[StoryStageDefinition]:
	return _catalog.stages if _catalog != null else []


func list_appearance_profiles() -> Array[AppearanceProfileDefinition]:
	return _catalog.appearance_profiles if _catalog != null else []


func list_animation_profiles() -> Array[AnimationProfileDefinition]:
	return _catalog.animation_profiles if _catalog != null else []


func list_discovery_situations() -> Array[DiscoverySituationDefinition]:
	return _catalog.discovery_situations if _catalog != null else []


func validate_all() -> Dictionary:
	if _catalog == null:
		return {"ok": false, "errors": ["catalog not loaded"]}
	return validate_catalog(_catalog)


## Validate any catalog (production or test). Does not mutate GameState.
static func validate_catalog(catalog: ContentCatalog) -> Dictionary:
	var errors: Array[String] = []
	if catalog == null:
		return {"ok": false, "errors": ["catalog is null"]}
	_validate_traits(catalog, errors)
	_validate_competitions(catalog, errors)
	_validate_perks(catalog, errors)
	_validate_locations(catalog, errors)
	_validate_stages(catalog, errors)
	_validate_girls(catalog, errors)
	_validate_rivals(catalog, errors)
	_validate_dating_events(catalog, errors)
	_validate_dating_pools(catalog, errors)
	_validate_animation_profiles(catalog, errors)
	_validate_appearance_profiles(catalog, errors)
	_validate_discovery_situations(catalog, errors)
	return {"ok": errors.is_empty(), "errors": errors}


## Public action validation for fixtures/self-tests.
static func validate_dating_action(action: DatingActionDefinition, event_id: String = "fixture") -> Array[String]:
	var errors: Array[String] = []
	if action == null:
		errors.append("null action")
		return errors
	_validate_action(action, event_id, errors)
	return errors


## Lookup helpers that do not push_error (for tests).
static func try_get_from_maps(maps: Dictionary, key: Variant) -> Resource:
	if maps.has(key):
		return maps[key] as Resource
	return null


static func build_indexes(catalog: ContentCatalog) -> Dictionary:
	var primary_by_trait: Dictionary = {}
	var secondary_by_trait: Dictionary = {}
	var girls_by_id: Dictionary = {}
	var rivals_by_id: Dictionary = {}
	var events_by_id: Dictionary = {}
	var pools_by_id: Dictionary = {}
	var perks_by_id: Dictionary = {}
	var competitions_by_type: Dictionary = {}
	var locations_by_id: Dictionary = {}
	var stages_by_stage: Dictionary = {}
	var appearances_by_id: Dictionary = {}
	var animations_by_id: Dictionary = {}
	var discovery_situations_by_id: Dictionary = {}
	var discovery_approaches_by_id: Dictionary = {}
	var dup_errors: Array[String] = []
	for def in catalog.primary_traits:
		if def == null:
			continue
		if primary_by_trait.has(def.primary_trait):
			dup_errors.append("duplicate primary trait enum %s" % def.primary_trait)
		else:
			primary_by_trait[def.primary_trait] = def
	for def in catalog.secondary_traits:
		if def == null:
			continue
		if secondary_by_trait.has(def.secondary_trait):
			dup_errors.append("duplicate secondary trait enum %s" % def.secondary_trait)
		else:
			secondary_by_trait[def.secondary_trait] = def
	for def in catalog.girls:
		if def == null:
			continue
		if girls_by_id.has(def.id):
			dup_errors.append("duplicate girl id %s" % String(def.id))
		else:
			girls_by_id[def.id] = def
	for def in catalog.rivals:
		if def == null:
			continue
		if rivals_by_id.has(def.id):
			dup_errors.append("duplicate rival id %s" % String(def.id))
		else:
			rivals_by_id[def.id] = def
	for def in catalog.dating_events:
		if def == null:
			continue
		if events_by_id.has(def.id):
			dup_errors.append("duplicate dating event id %s" % String(def.id))
		else:
			events_by_id[def.id] = def
	for def in catalog.dating_pools:
		if def == null:
			continue
		if pools_by_id.has(def.id):
			dup_errors.append("duplicate dating pool id %s" % String(def.id))
		else:
			pools_by_id[def.id] = def
	for def in catalog.perks:
		if def == null:
			continue
		if perks_by_id.has(def.id):
			dup_errors.append("duplicate perk id %s" % String(def.id))
		else:
			perks_by_id[def.id] = def
	for def in catalog.competitions:
		if def == null:
			continue
		if competitions_by_type.has(def.competition_type):
			dup_errors.append("duplicate competition type %s" % def.competition_type)
		else:
			competitions_by_type[def.competition_type] = def
	for def in catalog.locations:
		if def == null:
			continue
		if locations_by_id.has(def.id):
			dup_errors.append("duplicate location id %s" % String(def.id))
		else:
			locations_by_id[def.id] = def
	for def in catalog.stages:
		if def == null:
			continue
		if stages_by_stage.has(def.stage):
			dup_errors.append("duplicate stage enum %s" % def.stage)
		else:
			stages_by_stage[def.stage] = def
	for def in catalog.appearance_profiles:
		if def == null:
			continue
		if appearances_by_id.has(def.id):
			dup_errors.append("duplicate appearance profile id %s" % String(def.id))
		else:
			appearances_by_id[def.id] = def
	for def in catalog.animation_profiles:
		if def == null:
			continue
		if animations_by_id.has(def.id):
			dup_errors.append("duplicate animation profile id %s" % String(def.id))
		else:
			animations_by_id[def.id] = def
	for def in catalog.discovery_situations:
		if def == null:
			continue
		if discovery_situations_by_id.has(def.id):
			dup_errors.append("duplicate discovery situation id %s" % String(def.id))
		else:
			discovery_situations_by_id[def.id] = def
		for approach in def.approaches:
			if approach == null:
				continue
			if discovery_approaches_by_id.has(approach.id):
				dup_errors.append("duplicate discovery approach id %s" % String(approach.id))
			else:
				discovery_approaches_by_id[approach.id] = approach
	return {
		"primary_by_trait": primary_by_trait,
		"secondary_by_trait": secondary_by_trait,
		"girls_by_id": girls_by_id,
		"rivals_by_id": rivals_by_id,
		"events_by_id": events_by_id,
		"pools_by_id": pools_by_id,
		"perks_by_id": perks_by_id,
		"competitions_by_type": competitions_by_type,
		"locations_by_id": locations_by_id,
		"stages_by_stage": stages_by_stage,
		"appearances_by_id": appearances_by_id,
		"animations_by_id": animations_by_id,
		"discovery_situations_by_id": discovery_situations_by_id,
		"discovery_approaches_by_id": discovery_approaches_by_id,
		"dup_errors": dup_errors,
	}


func _index_catalog(catalog: ContentCatalog) -> void:
	var idx: Dictionary = build_indexes(catalog)
	_primary_by_trait = idx["primary_by_trait"]
	_secondary_by_trait = idx["secondary_by_trait"]
	_girls_by_id = idx["girls_by_id"]
	_rivals_by_id = idx["rivals_by_id"]
	_events_by_id = idx["events_by_id"]
	_pools_by_id = idx["pools_by_id"]
	_perks_by_id = idx["perks_by_id"]
	_competitions_by_type = idx["competitions_by_type"]
	_locations_by_id = idx["locations_by_id"]
	_stages_by_stage = idx["stages_by_stage"]
	_appearances_by_id = idx["appearances_by_id"]
	_animations_by_id = idx["animations_by_id"]
	_discovery_situations_by_id = idx["discovery_situations_by_id"]
	_discovery_approaches_by_id = idx["discovery_approaches_by_id"]


static func _validate_traits(catalog: ContentCatalog, errors: Array[String]) -> void:
	if catalog.primary_traits.size() != 4:
		errors.append("primary_traits count %s != 4" % catalog.primary_traits.size())
	if catalog.secondary_traits.size() != 4:
		errors.append("secondary_traits count %s != 4" % catalog.secondary_traits.size())
	var idx: Dictionary = build_indexes(catalog)
	for e in idx["dup_errors"]:
		errors.append(str(e))
	var primary_by_trait: Dictionary = idx["primary_by_trait"]
	var secondary_by_trait: Dictionary = idx["secondary_by_trait"]
	for t in [
		GameTypes.PrimaryGirlTrait.KIND,
		GameTypes.PrimaryGirlTrait.STATUS,
		GameTypes.PrimaryGirlTrait.THRILL_SEEKING,
		GameTypes.PrimaryGirlTrait.STRANGE,
	]:
		if not primary_by_trait.has(t):
			errors.append("missing primary trait definition %s" % t)
	for t in [
		GameTypes.SecondaryGirlTrait.SCANDALOUS,
		GameTypes.SecondaryGirlTrait.CONSISTENT,
		GameTypes.SecondaryGirlTrait.VARIETY_SEEKING,
		GameTypes.SecondaryGirlTrait.DEMANDING,
	]:
		if not secondary_by_trait.has(t):
			errors.append("missing secondary trait definition %s" % t)
	var liked_union: Dictionary = {}
	for trait_key in primary_by_trait.keys():
		var def: PrimaryTraitDefinition = primary_by_trait[trait_key] as PrimaryTraitDefinition
		if def.display_name.strip_edges() == "":
			errors.append("primary trait %s empty display_name" % def.primary_trait)
		var liked_seen: Dictionary = {}
		var disliked_seen: Dictionary = {}
		for tag in def.liked_tags:
			if liked_seen.has(tag):
				errors.append("primary %s duplicate liked tag %s" % [def.primary_trait, tag])
			liked_seen[tag] = true
			if liked_union.has(tag):
				errors.append("liked tag %s claimed by multiple primary traits" % tag)
			else:
				liked_union[tag] = def.primary_trait
		for tag in def.disliked_tags:
			if disliked_seen.has(tag):
				errors.append("primary %s duplicate disliked tag %s" % [def.primary_trait, tag])
			disliked_seen[tag] = true
			if liked_seen.has(tag):
				errors.append("primary %s tag %s is both liked and disliked" % [def.primary_trait, tag])
	if liked_union.size() != 12:
		errors.append("primary liked tags cover %s != 12 ActionTags" % liked_union.size())
	for sec_key in secondary_by_trait.keys():
		var sdef: SecondaryTraitDefinition = secondary_by_trait[sec_key] as SecondaryTraitDefinition
		if sdef.display_name.strip_edges() == "":
			errors.append("secondary trait %s empty display_name" % sdef.secondary_trait)


static func _validate_competitions(catalog: ContentCatalog, errors: Array[String]) -> void:
	if catalog.competitions.size() != 4:
		errors.append("competitions count %s != 4" % catalog.competitions.size())
	var expected: Dictionary = {
		GameTypes.CompetitionType.SLAP: GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.CompetitionType.DANCE: GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.CompetitionType.MONEY: GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.CompetitionType.SIGMA: GameTypes.PlayerCharacteristic.AURA,
	}
	var seen: Dictionary = {}
	for def in catalog.competitions:
		if def == null:
			errors.append("null competition definition")
			continue
		if seen.has(def.competition_type):
			errors.append("duplicate competition type %s" % def.competition_type)
		seen[def.competition_type] = true
		if def.display_name.strip_edges() == "":
			errors.append("competition %s empty display_name" % def.competition_type)
		if not expected.has(def.competition_type):
			errors.append("unknown competition type %s" % def.competition_type)
		elif int(def.characteristic) != int(expected[def.competition_type]):
			errors.append("competition %s characteristic mismatch" % def.competition_type)
		if def.expected_duration_min_seconds < 20 or def.expected_duration_max_seconds > 60:
			errors.append("competition %s duration guideline out of 20..60" % def.competition_type)
		if def.expected_duration_min_seconds > def.expected_duration_max_seconds:
			errors.append("competition %s min>max duration" % def.competition_type)
	for t in expected.keys():
		if not seen.has(t):
			errors.append("missing competition type %s" % t)


static func _validate_perks(catalog: ContentCatalog, errors: Array[String]) -> void:
	if catalog.perks.size() != 32:
		errors.append("perks count %s != 32" % catalog.perks.size())
	var by_id: Dictionary = {}
	var counts_by_char: Dictionary = {}
	var section_orders: Dictionary = {}
	for def in catalog.perks:
		if def == null:
			errors.append("null perk definition")
			continue
		if String(def.id) == "":
			errors.append("perk empty id")
			continue
		if not String(def.id).begins_with("perk_"):
			errors.append("perk id missing perk_ prefix: %s" % String(def.id))
		if by_id.has(def.id):
			errors.append("duplicate perk id %s" % String(def.id))
		by_id[def.id] = def
		if def.display_name.strip_edges() == "":
			errors.append("perk %s empty display_name" % String(def.id))
		var c: int = int(def.characteristic)
		counts_by_char[c] = int(counts_by_char.get(c, 0)) + 1
		var sk: String = "%s|%s" % [c, int(def.section)]
		if not section_orders.has(sk):
			section_orders[sk] = {}
		var orders: Dictionary = section_orders[sk]
		if orders.has(def.order_in_section):
			errors.append("perk duplicate order %s in %s" % [def.order_in_section, sk])
		orders[def.order_in_section] = true
	for pid in CANONICAL_PERK_IDS:
		if not by_id.has(pid):
			errors.append("missing canonical perk %s" % String(pid))
	for c in [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]:
		if int(counts_by_char.get(int(c), 0)) != 8:
			errors.append("perk count for %s != 8" % c)
		for sec in [
			GameTypes.PerkSection.EARLY_COMMON,
			GameTypes.PerkSection.BRANCH_A,
			GameTypes.PerkSection.BRANCH_B,
			GameTypes.PerkSection.LATE_COMMON,
		]:
			var sk2: String = "%s|%s" % [int(c), int(sec)]
			var orders2: Dictionary = section_orders.get(sk2, {})
			if orders2.size() != 2:
				errors.append("perk section %s size %s != 2" % [sk2, orders2.size()])
			if not orders2.has(1):
				errors.append("perk section %s missing order 1" % sk2)
			if not orders2.has(2):
				errors.append("perk section %s missing order 2" % sk2)
			for order_key in orders2.keys():
				var order_val: int = int(order_key)
				if order_val != 1 and order_val != 2:
					errors.append("perk section %s unexpected order %s" % [sk2, order_val])


static func _validate_locations(catalog: ContentCatalog, errors: Array[String]) -> void:
	if catalog.locations.size() != 9:
		errors.append("locations count %s != 9" % catalog.locations.size())
	var by_id: Dictionary = {}
	for def in catalog.locations:
		if def == null:
			errors.append("null location")
			continue
		if String(def.id) == "":
			errors.append("location empty id")
			continue
		if by_id.has(def.id):
			errors.append("duplicate location id %s" % String(def.id))
		by_id[def.id] = def
		if def.display_name.strip_edges() == "":
			errors.append("location %s empty display_name" % String(def.id))
	for lid in CANONICAL_LOCATION_IDS:
		if not by_id.has(lid):
			errors.append("missing canonical location %s" % String(lid))


static func _validate_stages(catalog: ContentCatalog, errors: Array[String]) -> void:
	if catalog.stages.size() != 8:
		errors.append("stages count %s != 8" % catalog.stages.size())
	var by_stage: Dictionary = {}
	for def in catalog.stages:
		if def == null:
			errors.append("null stage")
			continue
		if by_stage.has(def.stage):
			errors.append("duplicate stage %s" % def.stage)
		by_stage[def.stage] = def
		if def.display_name.strip_edges() == "":
			errors.append("stage %s empty display_name" % def.stage)
	var expected_girl: Dictionary = {
		GameTypes.GameStage.PROLOGUE: &"girl_neighbor",
		GameTypes.GameStage.STAGE_1: &"girl_actress",
		GameTypes.GameStage.STAGE_2: &"girl_mine_boss",
		GameTypes.GameStage.STAGE_3: &"girl_magazine_editor",
		GameTypes.GameStage.STAGE_4: &"girl_scientist",
		GameTypes.GameStage.STAGE_5: &"girl_president",
		GameTypes.GameStage.STAGE_6: &"",
		GameTypes.GameStage.FINALE: &"girl_final_target",
	}
	var expected_rival: Dictionary = {
		GameTypes.GameStage.PROLOGUE: &"",
		GameTypes.GameStage.STAGE_1: &"rival_actress",
		GameTypes.GameStage.STAGE_2: &"rival_mine_boss",
		GameTypes.GameStage.STAGE_3: &"rival_magazine_editor",
		GameTypes.GameStage.STAGE_4: &"rival_scientist",
		GameTypes.GameStage.STAGE_5: &"rival_president",
		GameTypes.GameStage.STAGE_6: &"",
		GameTypes.GameStage.FINALE: &"",
	}
	for st in expected_girl.keys():
		if not by_stage.has(st):
			errors.append("missing stage definition %s" % st)
			continue
		var sdef: StoryStageDefinition = by_stage[st] as StoryStageDefinition
		if sdef.story_girl_id != expected_girl[st]:
			errors.append("stage %s girl_id expected %s got %s" % [st, String(expected_girl[st]), String(sdef.story_girl_id)])
		if sdef.story_rival_id != expected_rival[st]:
			errors.append("stage %s rival_id expected %s got %s" % [st, String(expected_rival[st]), String(sdef.story_rival_id)])
		# Reserved story IDs may lack GirlDefinition/RivalDefinition — do not require existence.
		var gid: String = String(sdef.story_girl_id)
		if gid != "" and not gid.begins_with("girl_"):
			errors.append("stage %s girl_id must use girl_ prefix" % st)
		var rid: String = String(sdef.story_rival_id)
		if rid != "" and not rid.begins_with("rival_"):
			errors.append("stage %s rival_id must use rival_ prefix" % st)


static func _validate_girls(catalog: ContentCatalog, errors: Array[String]) -> void:
	var pool_ids: Dictionary = {}
	for p in catalog.dating_pools:
		if p != null:
			pool_ids[p.id] = true
	for def in catalog.girls:
		if def == null:
			errors.append("null girl")
			continue
		var sid: String = String(def.id)
		if sid == "" or not sid.begins_with("girl_"):
			errors.append("girl invalid id %s" % sid)
		if def.display_name.strip_edges() == "":
			errors.append("girl %s empty display_name" % sid)
		if def.required_experience < 0:
			errors.append("girl %s required_experience < 0" % sid)
		var seen_pools: Dictionary = {}
		for pid in def.dating_pool_ids:
			if seen_pools.has(pid):
				errors.append("girl %s duplicate pool %s" % [sid, String(pid)])
			seen_pools[pid] = true
			if not pool_ids.has(pid):
				errors.append("girl %s unknown pool %s" % [sid, String(pid)])
		var sit_id: String = String(def.discovery_situation_id)
		if sit_id != "":
			var sit_found: bool = false
			for sit in catalog.discovery_situations:
				if sit != null and sit.id == def.discovery_situation_id:
					sit_found = true
					break
			if not sit_found:
				errors.append("girl %s unknown discovery_situation_id %s" % [sid, sit_id])


static func _validate_rivals(catalog: ContentCatalog, errors: Array[String]) -> void:
	for def in catalog.rivals:
		if def == null:
			errors.append("null rival")
			continue
		var sid: String = String(def.id)
		if sid == "" or not sid.begins_with("rival_"):
			errors.append("rival invalid id %s" % sid)
		if def.display_name.strip_edges() == "":
			errors.append("rival %s empty display_name" % sid)
		if def.required_authority < 0:
			errors.append("rival %s required_authority < 0" % sid)
		if def.authority_reward < 0:
			errors.append("rival %s authority_reward < 0" % sid)
		for stat_name in ["muscle", "appearance", "capital", "aura"]:
			var v: int = int(def.get(stat_name))
			if v < 0 or v > 10:
				errors.append("rival %s %s out of 0..10" % [sid, stat_name])
		if def.allowed_competitions.is_empty():
			errors.append("rival %s allowed_competitions empty" % sid)
		var seen: Dictionary = {}
		var preferred_ok: bool = false
		for c in def.allowed_competitions:
			if seen.has(c):
				errors.append("rival %s duplicate allowed competition" % sid)
			seen[c] = true
			if c == def.preferred_competition:
				preferred_ok = true
		if not preferred_ok:
			errors.append("rival %s preferred not in allowed" % sid)


static func _validate_dating_events(catalog: ContentCatalog, errors: Array[String]) -> void:
	var loc_ids: Dictionary = {}
	for loc in catalog.locations:
		if loc != null:
			loc_ids[loc.id] = true
	for def in catalog.dating_events:
		if def == null:
			errors.append("null dating event")
			continue
		var sid: String = String(def.id)
		if sid == "" or not sid.begins_with("date_event_"):
			errors.append("dating event invalid id %s" % sid)
		if def.actions.is_empty():
			errors.append("dating event %s has no actions" % sid)
		var action_ids: Dictionary = {}
		for action in def.actions:
			if action == null:
				errors.append("dating event %s null action" % sid)
				continue
			_validate_action(action, sid, errors)
			if action_ids.has(action.id):
				errors.append("dating event %s duplicate action id %s" % [sid, String(action.id)])
			action_ids[action.id] = true
		var seen_locs: Dictionary = {}
		for lid in def.allowed_location_ids:
			if seen_locs.has(lid):
				errors.append("dating event %s duplicate location %s" % [sid, String(lid)])
			seen_locs[lid] = true
			if not loc_ids.is_empty() and not loc_ids.has(lid):
				# Only enforce when catalog has locations (production).
				errors.append("dating event %s unknown location %s" % [sid, String(lid)])


static func _validate_action(action: DatingActionDefinition, event_id: String, errors: Array[String]) -> void:
	if String(action.id) == "":
		errors.append("event %s action empty id" % event_id)
	if action.required_characteristic_level < 0:
		errors.append("event %s action %s level < 0" % [event_id, String(action.id)])
	if action.money_cost < 0:
		errors.append("event %s action %s money_cost < 0" % [event_id, String(action.id)])
	if action.direct_tags.size() > 2:
		errors.append("event %s action %s direct_tags > 2" % [event_id, String(action.id)])
	var seen: Dictionary = {}
	for tag in action.direct_tags:
		if seen.has(tag):
			errors.append("event %s action %s duplicate tag" % [event_id, String(action.id)])
		seen[tag] = true
	if action.resolver_id == &"direct" and action.direct_tags.size() == 0:
		# Production evaluated direct actions should have 1–2 tags.
		# Allow empty only for explicitly technical fixtures (label starts with TECH).
		if not action.label.begins_with("TECH"):
			errors.append("event %s action %s direct resolver needs 1-2 tags" % [event_id, String(action.id)])


static func _validate_dating_pools(catalog: ContentCatalog, errors: Array[String]) -> void:
	var event_ids: Dictionary = {}
	for e in catalog.dating_events:
		if e != null:
			event_ids[e.id] = true
	for def in catalog.dating_pools:
		if def == null:
			errors.append("null dating pool")
			continue
		var sid: String = String(def.id)
		if sid == "" or not sid.begins_with("date_pool_"):
			errors.append("dating pool invalid id %s" % sid)
		var seen: Dictionary = {}
		for eid in def.event_ids:
			if seen.has(eid):
				errors.append("pool %s duplicate event %s" % [sid, String(eid)])
			seen[eid] = true
			if not event_ids.has(eid):
				errors.append("pool %s unknown event %s" % [sid, String(eid)])


static func _validate_animation_profiles(catalog: ContentCatalog, errors: Array[String]) -> void:
	# Empty list is valid until animation content is authored.
	var by_id: Dictionary = {}
	for def in catalog.animation_profiles:
		if def == null:
			errors.append("null animation profile")
			continue
		var sid: String = String(def.id)
		if sid == "":
			errors.append("animation profile empty id")
			continue
		if not sid.begins_with("animation_"):
			errors.append("animation profile id missing animation_ prefix: %s" % sid)
		if by_id.has(def.id):
			errors.append("duplicate animation profile id %s" % sid)
		by_id[def.id] = def


static func _validate_appearance_profiles(catalog: ContentCatalog, errors: Array[String]) -> void:
	# Empty list is valid until visual PackedScenes exist (MODULE 04).
	var animation_ids: Dictionary = {}
	for anim in catalog.animation_profiles:
		if anim != null and String(anim.id) != "":
			animation_ids[anim.id] = true
	var by_id: Dictionary = {}
	for def in catalog.appearance_profiles:
		if def == null:
			errors.append("null appearance profile")
			continue
		var sid: String = String(def.id)
		if sid == "":
			errors.append("appearance profile empty id")
			continue
		if not sid.begins_with("appearance_"):
			errors.append("appearance profile id missing appearance_ prefix: %s" % sid)
		if by_id.has(def.id):
			errors.append("duplicate appearance profile id %s" % sid)
		by_id[def.id] = def
		if def.visual_scale <= 0.0:
			errors.append("appearance %s visual_scale must be > 0" % sid)
		var anim_id: String = String(def.animation_profile_id)
		if anim_id != "" and not animation_ids.has(def.animation_profile_id):
			errors.append("appearance %s unknown animation_profile_id %s" % [sid, anim_id])


static func _validate_discovery_situations(catalog: ContentCatalog, errors: Array[String]) -> void:
	var loc_ids: Dictionary = {}
	for loc in catalog.locations:
		if loc != null and String(loc.id) != "":
			loc_ids[loc.id] = true
	var approach_ids: Dictionary = {}
	for def in catalog.discovery_situations:
		if def == null:
			errors.append("null discovery situation")
			continue
		var sid: String = String(def.id)
		if sid == "" or not sid.begins_with("discovery_situation_"):
			errors.append("discovery situation invalid id %s" % sid)
		if String(def.location_id) == "":
			errors.append("discovery situation %s empty location_id" % sid)
		elif not loc_ids.is_empty() and not loc_ids.has(def.location_id):
			errors.append("discovery situation %s unknown location %s" % [sid, String(def.location_id)])
		if def.setup_text.strip_edges() == "":
			errors.append("discovery situation %s empty setup_text" % sid)
		if def.approaches.is_empty():
			errors.append("discovery situation %s has no approaches" % sid)
		for approach in def.approaches:
			if approach == null:
				errors.append("discovery situation %s null approach" % sid)
				continue
			var aid: String = String(approach.id)
			if aid == "" or not aid.begins_with("discovery_approach_"):
				errors.append("discovery approach invalid id %s" % aid)
			if approach_ids.has(approach.id):
				errors.append("duplicate discovery approach id %s" % aid)
			else:
				approach_ids[approach.id] = true
			if approach.label.strip_edges() == "":
				errors.append("discovery approach %s empty label" % aid)
			var outcome_i: int = int(approach.outcome)
			if (
				outcome_i != int(DiscoveryApproachDefinition.DiscoveryApproachOutcome.SUCCESS)
				and outcome_i != int(DiscoveryApproachDefinition.DiscoveryApproachOutcome.FAILURE)
			):
				errors.append("discovery approach %s invalid outcome" % aid)
			if approach.has_requirement:
				if approach.required_level < 0 or approach.required_level > 8:
					errors.append("discovery approach %s required_level out of 0..8" % aid)
			if approach.result_text.strip_edges() == "":
				errors.append("discovery approach %s empty result_text" % aid)
