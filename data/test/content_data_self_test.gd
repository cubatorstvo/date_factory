extends Node
## Reproducible MODULE 03 Content Data Layer tests (spec §88–98).
## Run via world/test/content_data_test.tscn.

const _ContentDBScript = preload("res://data/catalog/content_db.gd")

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
	# MODULE 14B ships Editor + ordinary public girls (11 total).
	var prod_girls: Array = db.call("list_girls") as Array
	_ok(prod_girls.size() == 11, "11 production GirlDefinitions in 14B")
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
	]:
		var g: GirlDefinition = db.call("get_girl", gid) as GirlDefinition
		_ok(g != null and g.id == gid, "production girl %s" % String(gid))
	var editor: GirlDefinition = db.call("get_girl", &"girl_magazine_editor") as GirlDefinition
	_ok(editor != null and editor.is_story and editor.story_stage == GameTypes.GameStage.STAGE_3, "14B girl_magazine_editor present STAGE_3")
	var scientist_missing: GirlDefinition = null
	if db.has_method("try_get_girl"):
		scientist_missing = db.call("try_get_girl", StoryIds.GIRL_SCIENTIST) as GirlDefinition
	else:
		scientist_missing = db.call("get_girl", StoryIds.GIRL_SCIENTIST) as GirlDefinition
	_ok(scientist_missing == null, "14B girl_scientist still absent")


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
