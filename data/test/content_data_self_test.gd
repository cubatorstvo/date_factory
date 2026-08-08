extends Node
## Reproducible MODULE 03 Content Data Layer tests (spec §88–98).
## Run via world/test/content_data_test.tscn.

const _ContentDBScript = preload("res://data/catalog/content_db.gd")

## MODULE 25 Wave K — ordinary matrix completeness (spec §88–91, counts).
const _FINAL_EXHIBITION_RIVAL_IDS: Array[StringName] = [
	&"rival_final_ceremonial",
	&"rival_final_gravity",
]

const _CAFE_COMMON_NEW_EVENT_IDS: Array[StringName] = [
	&"date_event_cafe_wrong_order",
	&"date_event_cafe_last_cake",
	&"date_event_cafe_window_draft",
	&"date_event_cafe_phone_charger",
	&"date_event_cafe_reserved_sign",
	&"date_event_cafe_loud_table",
	&"date_event_cafe_wobbly_spoon",
	&"date_event_cafe_free_sample",
	&"date_event_cafe_coat_mixup",
	&"date_event_cafe_waiter_question",
	&"date_event_cafe_table_photo",
	&"date_event_cafe_closing_chairs",
]

var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_03_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_03_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_03_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_03_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_03_TEST] FAIL: %s" % label)
		print("MODULE_03_TEST FAIL: %s" % label)


func _run_all() -> void:
	_test_contentdb_ready()
	_test_validate_all()
	_test_action_tag_coverage()
	_test_kind()
	_test_status()
	_test_thrill()
	_test_strange()
	_test_perks()
	_test_competitions()
	_test_locations()
	_test_stages()
	_test_fixture_lookups()
	_test_max_tags()
	_test_duplicate_id()
	_test_immutability()
	_test_gamestate_untouched()
	_test_module25_ordinary_matrix()
	_test_module25_ordinary_girl_completeness()
	_test_module25_signature_pools()
	_test_module25_cafe_common_pool()
	_test_module25_rivals_and_discovery()
	_test_module25_dating_central_events()


func _test_contentdb_ready() -> void:
	var db: Node = get_node("/root/ContentDB")
	_ok(db != null, "ContentDB autoload present")
	_ok(bool(db.call("is_ready_ok")), "ContentDB ready_ok")


func _test_validate_all() -> void:
	var db: Node = get_node("/root/ContentDB")
	var result: Dictionary = db.call("validate_all") as Dictionary
	_ok(bool(result.get("ok", false)), "validate_all ok")
	if not bool(result.get("ok", false)):
		for e in result.get("errors", []):
			print("MODULE_03_TEST validate error: %s" % str(e))


func _tags_equal(actual: Array, expected: Array[GameTypes.ActionTag]) -> bool:
	if actual.size() != expected.size():
		return false
	for i in range(expected.size()):
		if int(actual[i]) != int(expected[i]):
			return false
	return true


func _test_action_tag_coverage() -> void:
	var db: Node = get_node("/root/ContentDB")
	var union: Dictionary = {}
	for t in [
		GameTypes.PrimaryGirlTrait.KIND,
		GameTypes.PrimaryGirlTrait.STATUS,
		GameTypes.PrimaryGirlTrait.THRILL_SEEKING,
		GameTypes.PrimaryGirlTrait.STRANGE,
	]:
		var def: PrimaryTraitDefinition = db.call("get_primary_trait", t) as PrimaryTraitDefinition
		_ok(def != null, "primary exists %s" % t)
		if def == null:
			continue
		for tag in def.liked_tags:
			_ok(not union.has(tag), "liked tag unique %s" % tag)
			union[tag] = true
	_ok(union.size() == 12, "12 ActionTags covered by liked sets")


func _test_kind() -> void:
	var db: Node = get_node("/root/ContentDB")
	var def: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.KIND) as PrimaryTraitDefinition
	_ok(def != null and def.display_name == "Добрая", "KIND name")
	var likes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.CARE,
		GameTypes.ActionTag.VULNERABILITY,
		GameTypes.ActionTag.SIMPLICITY,
	]
	var dislikes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.DOMINANCE,
		GameTypes.ActionTag.CONFLICT,
		GameTypes.ActionTag.OBSESSION,
	]
	_ok(_tags_equal(def.liked_tags, likes), "KIND likes")
	_ok(_tags_equal(def.disliked_tags, dislikes), "KIND dislikes")


func _test_status() -> void:
	var db: Node = get_node("/root/ContentDB")
	var def: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.STATUS) as PrimaryTraitDefinition
	_ok(def != null and def.display_name == "Статусная", "STATUS name")
	var likes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.PRESTIGE,
		GameTypes.ActionTag.CONTROL,
		GameTypes.ActionTag.DOMINANCE,
	]
	var dislikes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.VULNERABILITY,
		GameTypes.ActionTag.SPONTANEITY,
		GameTypes.ActionTag.ABSURDITY,
	]
	_ok(_tags_equal(def.liked_tags, likes), "STATUS likes")
	_ok(_tags_equal(def.disliked_tags, dislikes), "STATUS dislikes")


func _test_thrill() -> void:
	var db: Node = get_node("/root/ContentDB")
	var def: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.THRILL_SEEKING) as PrimaryTraitDefinition
	_ok(def != null and def.display_name == "Азартная", "THRILL name")
	var likes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.RISK,
		GameTypes.ActionTag.CONFLICT,
		GameTypes.ActionTag.SPONTANEITY,
	]
	var dislikes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.CONTROL,
		GameTypes.ActionTag.SIMPLICITY,
		GameTypes.ActionTag.PRESTIGE,
	]
	_ok(_tags_equal(def.liked_tags, likes), "THRILL likes")
	_ok(_tags_equal(def.disliked_tags, dislikes), "THRILL dislikes")


func _test_strange() -> void:
	var db: Node = get_node("/root/ContentDB")
	var def: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.STRANGE) as PrimaryTraitDefinition
	_ok(def != null and def.display_name == "Странная", "STRANGE name")
	var likes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.ABSURDITY,
		GameTypes.ActionTag.ORIGINALITY,
		GameTypes.ActionTag.OBSESSION,
	]
	var dislikes: Array[GameTypes.ActionTag] = [
		GameTypes.ActionTag.PRESTIGE,
		GameTypes.ActionTag.CONTROL,
		GameTypes.ActionTag.SIMPLICITY,
	]
	_ok(_tags_equal(def.liked_tags, likes), "STRANGE likes")
	_ok(_tags_equal(def.disliked_tags, dislikes), "STRANGE dislikes")


func _test_perks() -> void:
	var db: Node = get_node("/root/ContentDB")
	var perks: Array = db.call("list_perks") as Array
	_ok(perks.size() == 32, "32 perks")
	var counts: Dictionary = {}
	var expected_names: Dictionary = {
		&"perk_muscle_no_warmup": "Без разминки",
		&"perk_muscle_tough_cheek": "Крепкая щека",
		&"perk_muscle_double_slap": "Двойная пощёчина",
		&"perk_muscle_counter_argument": "Ответный аргумент",
		&"perk_muscle_hold_doorway": "Удержание проёма",
		&"perk_muscle_heroic_defeat": "Героическое поражение",
		&"perk_muscle_mass_reserve": "Запас массы",
		&"perk_muscle_two_handed_argument": "Двуручный довод",
		&"perk_appearance_good_profile": "Выгодный профиль",
		&"perk_appearance_staged_walk": "Поставленная походка",
		&"perk_appearance_pocket_mirror": "Карманное зеркало",
		&"perk_appearance_control_profile": "Контрольный профиль",
		&"perk_appearance_second_outfit": "Второй комплект",
		&"perk_appearance_encore": "Выход на бис",
		&"perk_appearance_rhythm_in_body": "Ритм в теле",
		&"perk_appearance_public_significance": "Внешность общественного значения",
		&"perk_capital_payable_intent": "Платёжеспособное намерение",
		&"perk_capital_representation_expenses": "Представительские расходы",
		&"perk_capital_buy_problem": "Купить проблему",
		&"perk_capital_hostile_acquisition": "Враждебное приобретение",
		&"perk_capital_salary_advance": "Зарплата вперёд",
		&"perk_capital_dignity_refund": "Возврат достоинства",
		&"perk_capital_financial_inertia": "Финансовая инерция",
		&"perk_capital_no_limit": "Лимит отсутствует",
		&"perk_aura_presence_registered": "Присутствие зарегистрировано",
		&"perk_aura_dont_blink_first": "Не моргать первым",
		&"perk_aura_silence_longer": "Молчание длиннее нормы",
		&"perk_aura_reverse_pressure": "Обратное давление",
		&"perk_aura_right_to_say_nothing": "Право первым ничего не говорить",
		&"perk_aura_she_already_started": "Она уже начала",
		&"perk_aura_atmospheric_influence": "Атмосферное влияние",
		&"perk_aura_local_significance": "Аура местного значения",
	}
	for pid in expected_names.keys():
		var def: PerkDefinition = db.call("get_perk", pid) as PerkDefinition
		_ok(def != null and def.display_name == String(expected_names[pid]), "perk %s name" % String(pid))
		if def != null:
			var c: int = int(def.characteristic)
			counts[c] = int(counts.get(c, 0)) + 1
	_ok(int(counts.get(int(GameTypes.PlayerCharacteristic.MUSCLE), 0)) == 8, "8 muscle perks")
	_ok(int(counts.get(int(GameTypes.PlayerCharacteristic.APPEARANCE), 0)) == 8, "8 appearance perks")
	_ok(int(counts.get(int(GameTypes.PlayerCharacteristic.CAPITAL), 0)) == 8, "8 capital perks")
	_ok(int(counts.get(int(GameTypes.PlayerCharacteristic.AURA), 0)) == 8, "8 aura perks")


func _test_competitions() -> void:
	var db: Node = get_node("/root/ContentDB")
	var mapping: Dictionary = {
		GameTypes.CompetitionType.SLAP: GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.CompetitionType.DANCE: GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.CompetitionType.MONEY: GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.CompetitionType.SIGMA: GameTypes.PlayerCharacteristic.AURA,
	}
	var names: Dictionary = {
		GameTypes.CompetitionType.SLAP: "Пощёчинный бой",
		GameTypes.CompetitionType.DANCE: "Танцевальное противостояние",
		GameTypes.CompetitionType.MONEY: "Денежное противостояние",
		GameTypes.CompetitionType.SIGMA: "Сигма-давление",
	}
	for ct in mapping.keys():
		var def: CompetitionDefinition = db.call("get_competition", ct) as CompetitionDefinition
		_ok(def != null, "competition exists %s" % ct)
		if def == null:
			continue
		_ok(int(def.characteristic) == int(mapping[ct]), "competition map %s" % ct)
		_ok(def.display_name == String(names[ct]), "competition name %s" % ct)


func _test_locations() -> void:
	var db: Node = get_node("/root/ContentDB")
	var locs: Array = db.call("list_locations") as Array
	_ok(locs.size() == 9, "9 locations")
	for lid in [
		&"apartment", &"city_hub", &"cafe", &"gym", &"appearance_space",
		&"salary_mine", &"laboratory", &"production_area", &"final_location",
	]:
		var def: LocationDefinition = db.call("get_location", lid) as LocationDefinition
		_ok(def != null and def.display_name != "", "location %s" % String(lid))


func _test_stages() -> void:
	var db: Node = get_node("/root/ContentDB")
	var stages: Array = db.call("list_stages") as Array
	_ok(stages.size() == 8, "8 stages")
	var prologue: StoryStageDefinition = db.call("get_stage", GameTypes.GameStage.PROLOGUE) as StoryStageDefinition
	_ok(prologue != null and prologue.story_girl_id == &"girl_neighbor" and prologue.story_rival_id == &"", "prologue refs")
	var finale: StoryStageDefinition = db.call("get_stage", GameTypes.GameStage.FINALE) as StoryStageDefinition
	_ok(finale != null and finale.story_girl_id == &"girl_final_target", "finale girl")
	# MODULE 25: 23 girls (16 ordinary + 7 story/final); rivals 19 after Wave G.
	var prod_girls: Array = db.call("list_girls") as Array
	_ok(prod_girls.size() == 23, "23 production GirlDefinitions with MODULE25 ordinary set")
	var prod_rivals: Array = db.call("list_rivals") as Array
	_ok(prod_rivals.size() == 19, "19 production RivalDefinitions with MODULE25 Wave G rivals")
	for gid in [
		&"girl_neighbor",
		&"girl_actress",
		&"girl_mine_boss",
		&"girl_city_bicycle",
		&"girl_cafe_laptop",
		&"girl_gym_chalk",
		&"girl_appearance_ritual",
		&"girl_magazine_editor",
		&"girl_public_sculpture",
		&"girl_cafe_receipt_notes",
		&"girl_appearance_flash",
		&"girl_scientist",
		&"girl_president",
		&"girl_final_target",
		&"girl_city_umbrella",
		&"girl_cafe_spoon_stack",
		&"girl_city_lanyard",
		&"girl_appearance_coat_check",
		&"girl_gym_timer",
		&"girl_city_crosswalk",
		&"girl_cafe_hot_sauce",
		&"girl_appearance_mannequin",
		&"girl_cafe_sugar_geometry",
	]:
		var g: GirlDefinition = db.call("get_girl", gid) as GirlDefinition
		_ok(g != null and g.id == gid, "production girl %s" % String(gid))
	var editor: GirlDefinition = db.call("get_girl", &"girl_magazine_editor") as GirlDefinition
	_ok(editor != null and editor.is_story and editor.story_stage == GameTypes.GameStage.STAGE_3, "14B girl_magazine_editor present STAGE_3")
	var scientist: GirlDefinition = null
	if db.has_method("try_get_girl"):
		scientist = db.call("try_get_girl", StoryIds.GIRL_SCIENTIST) as GirlDefinition
	else:
		scientist = db.call("get_girl", StoryIds.GIRL_SCIENTIST) as GirlDefinition
	_ok(scientist != null and scientist.is_story and scientist.story_stage == GameTypes.GameStage.STAGE_4, "17 girl_scientist present STAGE_4")
	var rival_scientist: RivalDefinition = db.call("get_rival", &"rival_scientist") as RivalDefinition
	_ok(rival_scientist != null and rival_scientist.is_story and rival_scientist.story_stage == GameTypes.GameStage.STAGE_4, "17 rival_scientist present STAGE_4")
	var president: GirlDefinition = null
	if db.has_method("try_get_girl"):
		president = db.call("try_get_girl", StoryIds.GIRL_PRESIDENT) as GirlDefinition
	else:
		president = db.call("get_girl", StoryIds.GIRL_PRESIDENT) as GirlDefinition
	_ok(president != null and president.is_story and president.story_stage == GameTypes.GameStage.STAGE_5, "20 girl_president present STAGE_5")
	var rival_president: RivalDefinition = db.call("get_rival", &"rival_president") as RivalDefinition
	_ok(rival_president != null and rival_president.is_story and rival_president.story_stage == GameTypes.GameStage.STAGE_5, "20 rival_president present STAGE_5")
	var final_girl: GirlDefinition = null
	if db.has_method("try_get_girl"):
		final_girl = db.call("try_get_girl", StoryIds.GIRL_FINAL_TARGET) as GirlDefinition
	else:
		final_girl = db.call("get_girl", StoryIds.GIRL_FINAL_TARGET) as GirlDefinition
	_ok(
		final_girl != null
		and final_girl.is_story
		and final_girl.story_stage == GameTypes.GameStage.FINALE
		and final_girl.primary_trait == GameTypes.PrimaryGirlTrait.STRANGE
		and final_girl.secondary_trait == GameTypes.SecondaryGirlTrait.VARIETY_SEEKING
		and final_girl.dating_pool_ids.is_empty()
		and String(final_girl.discovery_situation_id) == "",
		"21 girl_final_target FINALE empty dating/discovery",
	)
	var rival_ceremonial: RivalDefinition = db.call("get_rival", &"rival_final_ceremonial") as RivalDefinition
	_ok(
		rival_ceremonial != null
		and rival_ceremonial.required_authority == 0
		and rival_ceremonial.authority_reward == 0
		and rival_ceremonial.preferred_competition == GameTypes.CompetitionType.DANCE
		and rival_ceremonial.allowed_competitions.size() == 1
		and rival_ceremonial.allowed_competitions[0] == GameTypes.CompetitionType.DANCE,
		"21 rival_final_ceremonial DANCE auth0",
	)
	var rival_gravity: RivalDefinition = db.call("get_rival", &"rival_final_gravity") as RivalDefinition
	_ok(
		rival_gravity != null
		and rival_gravity.required_authority == 0
		and rival_gravity.authority_reward == 0
		and rival_gravity.preferred_competition == GameTypes.CompetitionType.SLAP
		and rival_gravity.allowed_competitions.size() == 1
		and rival_gravity.allowed_competitions[0] == GameTypes.CompetitionType.SLAP,
		"21 rival_final_gravity SLAP auth0",
	)


func _test_fixture_lookups() -> void:
	var girl: GirlDefinition = load("res://data/test/girl_test_kind.tres") as GirlDefinition
	var rival: RivalDefinition = load("res://data/test/rival_test.tres") as RivalDefinition
	var pool: DatingEventPoolDefinition = load("res://data/test/date_pool_test.tres") as DatingEventPoolDefinition
	_ok(girl != null and girl.id == &"girl_test_kind", "fixture girl id")
	_ok(girl.primary_trait == GameTypes.PrimaryGirlTrait.KIND, "fixture girl KIND")
	_ok(girl.secondary_trait == GameTypes.SecondaryGirlTrait.CONSISTENT, "fixture girl CONSISTENT")
	_ok(rival != null and rival.id == &"rival_test", "fixture rival id")
	_ok(rival.preferred_competition == GameTypes.CompetitionType.SLAP, "fixture rival preferred")
	_ok(rival.allowed_competitions.size() == 2, "fixture rival allowed size")
	_ok(pool != null and pool.event_ids.size() == 3, "fixture pool 3 events")
	var cat: ContentCatalog = ContentCatalog.new()
	cat.girls = [girl]
	cat.rivals = [rival]
	var ev1: DatingEventDefinition = load("res://data/test/date_event_test_conversation.tres") as DatingEventDefinition
	var ev2: DatingEventDefinition = load("res://data/test/date_event_test_space.tres") as DatingEventDefinition
	var ev3: DatingEventDefinition = load("res://data/test/date_event_test_proposal.tres") as DatingEventDefinition
	cat.dating_events = [ev1, ev2, ev3]
	cat.dating_pools = [pool]
	var idx: Dictionary = _ContentDBScript.build_indexes(cat)
	_ok((idx["girls_by_id"] as Dictionary).has(&"girl_test_kind"), "index girl")
	_ok((idx["rivals_by_id"] as Dictionary).has(&"rival_test"), "index rival")
	_ok(not (idx["girls_by_id"] as Dictionary).has(&"missing"), "missing girl absent")
	var db: Node = get_node("/root/ContentDB")
	var missing: Variant = db.call("get_girl", &"missing_girl_xyz")
	_ok(missing == null, "production missing girl null")


func _test_max_tags() -> void:
	var ok_event: DatingEventDefinition = load("res://data/test/date_event_test_conversation.tres") as DatingEventDefinition
	_ok(ok_event != null and ok_event.actions.size() >= 2, "ok event loaded")
	var errs1: Array[String] = _ContentDBScript.validate_dating_action(ok_event.actions[0], "date_event_test_conversation")
	var errs2: Array[String] = _ContentDBScript.validate_dating_action(ok_event.actions[1], "date_event_test_conversation")
	_ok(errs1.is_empty(), "1-tag action valid")
	_ok(errs2.is_empty(), "2-tag action valid")
	var bad_event: DatingEventDefinition = load("res://data/test/date_event_invalid_three_tags.tres") as DatingEventDefinition
	_ok(bad_event != null and bad_event.actions.size() == 1, "invalid event loaded")
	var bad_errs: Array[String] = _ContentDBScript.validate_dating_action(bad_event.actions[0], "date_event_invalid_three_tags")
	_ok(not bad_errs.is_empty(), "3-tag action validation fail")


func _test_duplicate_id() -> void:
	var a: GirlDefinition = load("res://data/test/girl_test_dup_a.tres") as GirlDefinition
	var b: GirlDefinition = load("res://data/test/girl_test_dup_b.tres") as GirlDefinition
	var cat: ContentCatalog = ContentCatalog.new()
	cat.girls = [a, b]
	var idx: Dictionary = _ContentDBScript.build_indexes(cat)
	var dups: Array = idx["dup_errors"] as Array
	_ok(not dups.is_empty(), "duplicate girl id detected")
	_ok((idx["girls_by_id"] as Dictionary).size() == 1, "duplicate does not silently keep both")


func _test_immutability() -> void:
	var db: Node = get_node("/root/ContentDB")
	var a: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.KIND) as PrimaryTraitDefinition
	var b: PrimaryTraitDefinition = db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.KIND) as PrimaryTraitDefinition
	_ok(a != null and a == b, "lookup returns same resource instance")


func _test_gamestate_untouched() -> void:
	var gs: Node = get_node("/root/GameState")
	_ok(int(gs.call("get_money")) == 0, "ContentDB did not change money")
	_ok(int(gs.call("get_stage")) == int(GameTypes.GameStage.PROLOGUE), "ContentDB did not change stage")


func _ordinary_girls(db: Node) -> Array[GirlDefinition]:
	var out: Array[GirlDefinition] = []
	var girls: Array = db.call("list_girls") as Array
	for g in girls:
		var girl: GirlDefinition = g as GirlDefinition
		if girl == null:
			continue
		if girl.is_story:
			continue
		out.append(girl)
	return out


func _signature_pool_id_for_girl(girl: GirlDefinition) -> StringName:
	for pid in girl.dating_pool_ids:
		var s: String = String(pid)
		if s.begins_with("date_pool_signature_"):
			return pid
	return &""


func _test_module25_ordinary_matrix() -> void:
	var db: Node = get_node("/root/ContentDB")
	var ordinary: Array[GirlDefinition] = _ordinary_girls(db)
	var all_girls: Array = db.call("list_girls") as Array
	_ok(ordinary.size() == 16, "MODULE25 ordinary girls count == 16 got %s" % ordinary.size())
	_ok(all_girls.size() == 23, "MODULE25 total girls == 23 got %s" % all_girls.size())
	var pairs: Dictionary = {}
	var expected_primaries: Array = [
		GameTypes.PrimaryGirlTrait.KIND,
		GameTypes.PrimaryGirlTrait.STATUS,
		GameTypes.PrimaryGirlTrait.THRILL_SEEKING,
		GameTypes.PrimaryGirlTrait.STRANGE,
	]
	var expected_secondaries: Array = [
		GameTypes.SecondaryGirlTrait.SCANDALOUS,
		GameTypes.SecondaryGirlTrait.CONSISTENT,
		GameTypes.SecondaryGirlTrait.VARIETY_SEEKING,
		GameTypes.SecondaryGirlTrait.DEMANDING,
	]
	for girl in ordinary:
		var key: String = "%s|%s" % [int(girl.primary_trait), int(girl.secondary_trait)]
		_ok(not pairs.has(key), "MODULE25 unique pair for %s" % String(girl.id))
		pairs[key] = girl.id
	_ok(pairs.size() == 16, "MODULE25 16 unique primary×secondary pairs got %s" % pairs.size())
	for p in expected_primaries:
		for s in expected_secondaries:
			var need: String = "%s|%s" % [int(p), int(s)]
			_ok(pairs.has(need), "MODULE25 matrix cell primary=%s secondary=%s" % [int(p), int(s)])


func _test_module25_ordinary_girl_completeness() -> void:
	var db: Node = get_node("/root/ContentDB")
	var ordinary: Array[GirlDefinition] = _ordinary_girls(db)
	for girl in ordinary:
		var gid: String = String(girl.id)
		var appearance: AppearanceProfileDefinition = db.call(
			"get_appearance_profile", girl.appearance_profile_id
		) as AppearanceProfileDefinition
		_ok(
			appearance != null and String(girl.appearance_profile_id) != "",
			"MODULE25 %s valid appearance" % gid,
		)
		var discovery: DiscoverySituationDefinition = db.call(
			"get_discovery_situation", girl.discovery_situation_id
		) as DiscoverySituationDefinition
		_ok(
			discovery != null and String(girl.discovery_situation_id) != "",
			"MODULE25 %s valid discovery" % gid,
		)
		_ok(
			girl.required_experience >= 0 and girl.required_experience <= 4,
			"MODULE25 %s XP 0..4 got %s" % [gid, girl.required_experience],
		)
		_ok(
			girl.dating_pool_ids.has(&"date_pool_cafe_common"),
			"MODULE25 %s has cafe_common pool" % gid,
		)
		var sig_pool: StringName = _signature_pool_id_for_girl(girl)
		_ok(String(sig_pool) != "", "MODULE25 %s has signature pool" % gid)
		if String(sig_pool) != "":
			var pool: DatingEventPoolDefinition = db.call("get_dating_pool", sig_pool) as DatingEventPoolDefinition
			_ok(pool != null, "MODULE25 %s signature pool resolves" % gid)
		_ok(not girl.dating_greeting_ids.is_empty(), "MODULE25 %s greetings nonempty" % gid)
		for gre_id in girl.dating_greeting_ids:
			var gre: DatingGreetingDefinition = db.call("get_dating_greeting", gre_id) as DatingGreetingDefinition
			_ok(gre != null, "MODULE25 %s greeting %s" % [gid, String(gre_id)])
		var farewell: DatingFarewellDefinition = db.call(
			"get_dating_farewell", girl.dating_farewell_id
		) as DatingFarewellDefinition
		_ok(
			farewell != null and String(girl.dating_farewell_id) != "",
			"MODULE25 %s farewell set" % gid,
		)
		_ok(girl.clue_notes.size() == 3, "MODULE25 %s exactly 3 clues got %s" % [gid, girl.clue_notes.size()])
		for i in range(girl.clue_notes.size()):
			_ok(girl.clue_notes[i].strip_edges() != "", "MODULE25 %s clue %s nonempty" % [gid, i])
		_ok(
			girl.speech_style_note.strip_edges() != "",
			"MODULE25 %s speech_style_note nonempty" % gid,
		)


func _test_module25_signature_pools() -> void:
	var db: Node = get_node("/root/ContentDB")
	var ordinary: Array[GirlDefinition] = _ordinary_girls(db)
	var sig_pools: Dictionary = {}
	var sig_events: Dictionary = {}
	for girl in ordinary:
		var sig_pool_id: StringName = _signature_pool_id_for_girl(girl)
		_ok(String(sig_pool_id) != "", "MODULE25 signature pool id for %s" % String(girl.id))
		if String(sig_pool_id) == "":
			continue
		_ok(not sig_pools.has(sig_pool_id), "MODULE25 unique signature pool %s" % String(sig_pool_id))
		sig_pools[sig_pool_id] = girl.id
		var pool: DatingEventPoolDefinition = db.call("get_dating_pool", sig_pool_id) as DatingEventPoolDefinition
		_ok(pool != null, "MODULE25 signature pool exists %s" % String(sig_pool_id))
		if pool == null:
			continue
		_ok(pool.event_ids.size() == 1, "MODULE25 %s has exactly 1 signature event" % String(sig_pool_id))
		if pool.event_ids.is_empty():
			continue
		var eid: StringName = pool.event_ids[0]
		var ev: DatingEventDefinition = db.call("get_dating_event", eid) as DatingEventDefinition
		_ok(ev != null, "MODULE25 signature event exists %s" % String(eid))
		_ok(not sig_events.has(eid), "MODULE25 signature event not shared %s" % String(eid))
		sig_events[eid] = girl.id
	_ok(sig_pools.size() == 16, "MODULE25 exactly 16 signature pools got %s" % sig_pools.size())
	_ok(sig_events.size() == 16, "MODULE25 exactly 16 signature events got %s" % sig_events.size())


func _test_module25_cafe_common_pool() -> void:
	var db: Node = get_node("/root/ContentDB")
	var pool: DatingEventPoolDefinition = db.call("get_dating_pool", &"date_pool_cafe_common") as DatingEventPoolDefinition
	_ok(pool != null, "MODULE25 date_pool_cafe_common exists")
	if pool == null:
		return
	_ok(
		pool.event_ids.size() >= 24,
		"MODULE25 cafe_common events >= 24 got %s" % pool.event_ids.size(),
	)
	for eid in _CAFE_COMMON_NEW_EVENT_IDS:
		_ok(pool.event_ids.has(eid), "MODULE25 cafe_common contains %s" % String(eid))
		var ev: DatingEventDefinition = db.call("get_dating_event", eid) as DatingEventDefinition
		_ok(ev != null, "MODULE25 cafe_common event resource %s" % String(eid))


func _test_module25_rivals_and_discovery() -> void:
	var db: Node = get_node("/root/ContentDB")
	var rivals: Array = db.call("list_rivals") as Array
	_ok(rivals.size() == 19, "MODULE25 rivals == 19 got %s" % rivals.size())
	var ordinary_rivals: int = 0
	for r in rivals:
		var rival: RivalDefinition = r as RivalDefinition
		if rival == null:
			continue
		if rival.is_story:
			continue
		if _FINAL_EXHIBITION_RIVAL_IDS.has(rival.id):
			continue
		ordinary_rivals += 1
	_ok(ordinary_rivals == 12, "MODULE25 ordinary rivals == 12 got %s" % ordinary_rivals)
	for fid in _FINAL_EXHIBITION_RIVAL_IDS:
		var fr: RivalDefinition = db.call("get_rival", fid) as RivalDefinition
		_ok(fr != null and not fr.is_story, "MODULE25 final exhibition present %s" % String(fid))
	var situations: Array = db.call("list_discovery_situations") as Array
	_ok(situations.size() == 22, "MODULE25 discovery situations == 22 got %s" % situations.size())


func _test_module25_dating_central_events() -> void:
	var db: Node = get_node("/root/ContentDB")
	var events: Array = db.call("list_dating_events") as Array
	_ok(events.size() >= 62, "MODULE25 dating central events >= 62 got %s" % events.size())
