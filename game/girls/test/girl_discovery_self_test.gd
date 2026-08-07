extends Node
## MODULE 08 Girl Discovery & Phone Journal self-test (spec §§107–144).
## Run: res://game/girls/test/girl_discovery_test.tscn --quit-after 12000

const _ContentDBScript = preload("res://data/catalog/content_db.gd")


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _gd: Node = null
var _available_again_count: int = 0
var _last_available_id: StringName = &""
var _contact_signal_count: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_gd = get_node("/root/GirlDiscovery")
	await get_tree().process_frame
	_gd.connect("girl_available_again", _on_available_again)
	_gd.connect("girl_contact_added", _on_contact_added)
	_load_fixtures()
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_08_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_08_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_08_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_08_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_available_again(gid: StringName) -> void:
	_available_again_count += 1
	_last_available_id = gid


func _on_contact_added(_gid: StringName) -> void:
	_contact_signal_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_08_TEST] FAIL: %s" % label)
		print("MODULE_08_TEST FAIL: %s" % label)


func _load_fixtures() -> void:
	_gd.call("clear_content_overrides")
	var girls: Array[String] = [
		"res://data/test/girl_test_discovery.tres",
		"res://data/test/girl_test_experience_locked.tres",
	]
	for p in girls:
		var def: GirlDefinition = load(p) as GirlDefinition
		_ok(def != null, "load girl fixture %s" % p)
		if def != null:
			_gd.call("register_girl_definition", def)
	var sit: DiscoverySituationDefinition = load(
		"res://data/test/discovery_situation_test_bicycle.tres"
	) as DiscoverySituationDefinition
	_ok(sit != null, "load situation fixture")
	if sit != null:
		_gd.call("register_discovery_situation", sit)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_gd.call("force_clear_attempt")
	_available_again_count = 0
	_last_available_id = &""
	_contact_signal_count = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_gd.call("set_rng", rng)


func _run_all() -> void:
	_test_initial_state()
	_test_proximity_discovery()
	_test_proximity_idempotent()
	_test_good_profile()
	_test_good_profile_not_retroactive()
	_test_experience_gate()
	_test_experience_gate_exact()
	_test_disabled_characteristic()
	_test_success()
	_test_duplicate_success()
	_test_already_contact()
	_test_failure()
	_test_deterministic_cooldown()
	_test_failure_all_clues_known()
	await _test_actor_disappears()
	_test_cooldown_blocks()
	_test_day_decrement()
	await _test_return_signal()
	await _test_scene_reload_cooldown()
	_test_same_girl_remains()
	_test_contact_clears_cooldown()
	await _test_phone_only_discovered()
	await _test_phone_contact_state()
	await _test_phone_clues()
	await _test_trait_hidden()
	await _test_trait_reveal()
	_test_known_reaction_api()
	_test_discovery_no_fake_reaction()
	_test_no_relationship_xp_conquest()
	await _test_phone_control_mode()
	_test_no_phone_hotkey()
	_test_contentdb_validation()
	await _test_character_regression()
	_gs.call("reset_for_new_game")
	_gd.call("force_clear_attempt")


func _test_initial_state() -> void:
	_reset()
	var discovered: Array = _gs.call("get_discovered_girl_ids") as Array
	var contacts: Array = _gs.call("get_girl_contact_ids") as Array
	_ok(discovered.is_empty(), "107 discovered empty")
	_ok(contacts.is_empty(), "107 contacts empty")
	_ok((_gs.call("get_known_girl_clue_indices", &"girl_test_discovery") as Array).is_empty(), "107 clues empty")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 0, "107 cooldown empty")
	_ok(not bool(_gs.call("is_primary_trait_revealed", &"girl_test_discovery")), "107 trait empty")


func _test_proximity_discovery() -> void:
	_reset()
	var r: Dictionary = _gd.call("discover_girl", &"girl_test_discovery") as Dictionary
	_ok(bool(r.get("ok", false)), "108 discover ok")
	_ok(bool(_gs.call("is_girl_discovered", &"girl_test_discovery")), "108 discovered")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 0)), "108 clue0")
	_ok(not bool(_gs.call("has_girl_contact", &"girl_test_discovery")), "108 no contact")


func _test_proximity_idempotent() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var clues_before: Array = _gs.call("get_known_girl_clue_indices", &"girl_test_discovery") as Array
	_gd.call("discover_girl", &"girl_test_discovery")
	var discovered: Array = _gs.call("get_discovered_girl_ids") as Array
	var clues_after: Array = _gs.call("get_known_girl_clue_indices", &"girl_test_discovery") as Array
	_ok(discovered.size() == 1, "109 no duplicate discovery")
	_ok(clues_before.size() == clues_after.size(), "109 no extra clue")


func _test_good_profile() -> void:
	_reset()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_GOOD_PROFILE])
	_gd.call("discover_girl", &"girl_test_discovery")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 0)), "110 clue0")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 1)), "110 clue1")
	_ok(not bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 2)), "110 no clue2")


func _test_good_profile_not_retroactive() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 0)), "111 clue0")
	_ok(not bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 1)), "111 clue1 unknown")
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_GOOD_PROFILE])
	_gd.call("discover_girl", &"girl_test_discovery")
	_ok(not bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 1)), "111 still unknown")


func _test_experience_gate() -> void:
	_reset()
	_gs.call("add_experience", 2)
	_gd.call("discover_girl", &"girl_test_experience_locked")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_test_experience_locked") as Dictionary
	_ok(not bool(begin.get("ok", true)), "112 locked")
	_ok(begin.get("reason", &"") == &"LOCKED_EXPERIENCE", "112 LOCKED_EXPERIENCE")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_experience_locked")) == 0, "112 no cooldown")
	_ok(not bool(_gs.call("is_girl_clue_known", &"girl_test_experience_locked", 1)), "112 no extra clue")
	_ok(not bool(_gs.call("has_girl_contact", &"girl_test_experience_locked")), "112 no contact")


func _test_experience_gate_exact() -> void:
	_reset()
	_gs.call("add_experience", 3)
	_gd.call("discover_girl", &"girl_test_experience_locked")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_test_experience_locked") as Dictionary
	_ok(bool(begin.get("ok", false)), "113 attempt allowed at 3")
	_gd.call("force_clear_attempt")


func _test_disabled_characteristic() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 1)
	_gd.call("discover_girl", &"girl_test_discovery")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_test_discovery") as Dictionary
	_ok(bool(begin.get("ok", false)), "114 begin")
	var approaches: Array = begin.get("approaches", []) as Array
	var flex_available: bool = true
	for a in approaches:
		var info: Dictionary = a as Dictionary
		if info.get("id", &"") == &"discovery_approach_test_flex":
			flex_available = bool(info.get("available", true))
	_ok(not flex_available, "114 flex disabled")
	var sel: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
	_ok(not bool(sel.get("ok", true)), "114 select rejected")
	_ok(sel.get("reason", &"") == &"REQUIREMENT_UNMET", "114 REQUIREMENT_UNMET")
	_gd.call("force_clear_attempt")


func _test_success() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var rel_before: int = int(_gs.call("get_girl_relationship", &"girl_test_discovery"))
	var xp_before: int = int(_gs.call("get_experience"))
	_gd.call("begin_attempt", &"girl_test_discovery")
	var res: Dictionary = _gd.call("select_approach", &"discovery_approach_test_help") as Dictionary
	_ok(bool(res.get("ok", false)) and res.get("reason", &"") == &"SUCCESS", "115 success")
	_ok(bool(_gs.call("has_girl_contact", &"girl_test_discovery")), "115 contact")
	_ok(bool(_gs.call("is_girl_discovered", &"girl_test_discovery")), "115 discovered")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 0, "115 cooldown 0")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_discovery")) == rel_before, "115 rel unchanged")
	_ok(int(_gs.call("get_experience")) == xp_before, "115 xp unchanged")


func _test_duplicate_success() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_contact_signal_count = 0
	_gd.call("select_approach", &"discovery_approach_test_help")
	var signals_after_first: int = _contact_signal_count
	var again: Dictionary = _gd.call("select_approach", &"discovery_approach_test_help") as Dictionary
	_ok(not bool(again.get("ok", true)), "116 second rejected")
	_ok(_contact_signal_count == signals_after_first, "116 no second contact signal")


func _test_already_contact() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_gs.call("add_girl_contact", &"girl_test_discovery")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_test_discovery") as Dictionary
	_ok(not bool(begin.get("ok", true)), "117 blocked")
	_ok(begin.get("reason", &"") == &"ALREADY_CONTACT", "117 ALREADY_CONTACT")


func _test_failure() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	var res: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
	_ok(bool(res.get("ok", false)) and res.get("reason", &"") == &"FAILURE", "118 failure")
	_ok(not bool(_gs.call("has_girl_contact", &"girl_test_discovery")), "118 no contact")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_discovery", 1)), "118 next clue")
	var cd: int = int(res.get("cooldown_days", 0))
	_ok(cd >= 1 and cd <= 3, "118 cooldown 1..3")


func _test_deterministic_cooldown() -> void:
	for seed_v in [1, 2, 3, 7, 42]:
		_reset()
		var rng := RandomNumberGenerator.new()
		rng.seed = int(seed_v)
		_gd.call("set_rng", rng)
		_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
		_gd.call("discover_girl", &"girl_test_discovery")
		_gd.call("begin_attempt", &"girl_test_discovery")
		var res: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
		var cd: int = int(res.get("cooldown_days", -1))
		_ok(cd >= 1 and cd <= 3, "119 seed %s cooldown in range" % seed_v)
	# Reproduce exact value for seed=1 twice
	_reset()
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 99
	_gd.call("set_rng", rng_a)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	var a: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
	var cd_a: int = int(a.get("cooldown_days", -1))
	_reset()
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 99
	_gd.call("set_rng", rng_b)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	var b: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
	_ok(int(b.get("cooldown_days", -2)) == cd_a, "119 deterministic same seed")


func _test_failure_all_clues_known() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gs.call("reveal_girl_clue", &"girl_test_discovery", 1)
	_gs.call("reveal_girl_clue", &"girl_test_discovery", 2)
	_gd.call("begin_attempt", &"girl_test_discovery")
	var res: Dictionary = _gd.call("select_approach", &"discovery_approach_test_flex") as Dictionary
	_ok(bool(res.get("ok", false)) and res.get("reason", &"") == &"FAILURE", "120 failure ok")
	_ok(not res.has("new_clue_index"), "120 no new clue")
	_ok(int(res.get("cooldown_days", 0)) >= 1, "120 cooldown applied")


func _test_actor_disappears() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	var actor: GirlActor = GirlActor.new()
	actor.girl_id = &"girl_test_discovery"
	add_child(actor)
	await get_tree().process_frame
	actor.refresh_presence()
	await get_tree().process_frame
	_ok(actor.visible, "121 visible before")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_flex")
	await get_tree().process_frame
	_ok(not actor.visible, "121 hidden after failure")
	_ok(not actor.interaction_enabled or not actor.can_interact(self), "121 interaction disabled")
	actor.queue_free()


func _test_cooldown_blocks() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_flex")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_test_discovery") as Dictionary
	_ok(not bool(begin.get("ok", true)), "122 blocked")
	_ok(begin.get("reason", &"") == &"COOLDOWN", "122 COOLDOWN")


func _test_day_decrement() -> void:
	_reset()
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 3)
	_gd.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 2, "123 day->2")
	_gd.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 1, "123 day->1")
	_gd.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 0, "123 day->0")


func _test_return_signal() -> void:
	_reset()
	_gs.call("mark_girl_discovered", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 1)
	_available_again_count = 0
	var actor: GirlActor = GirlActor.new()
	actor.girl_id = &"girl_test_discovery"
	add_child(actor)
	await get_tree().process_frame
	actor.refresh_presence()
	await get_tree().process_frame
	_ok(not actor.visible, "124 starts hidden")
	_gd.call("notify_game_day_advanced")
	_ok(_available_again_count == 1, "124 signal once")
	_ok(_last_available_id == &"girl_test_discovery", "124 id")
	await get_tree().process_frame
	_ok(actor.visible, "124 visible again")
	_gd.call("notify_game_day_advanced")
	_ok(_available_again_count == 1, "124 no second signal")
	actor.queue_free()


func _test_scene_reload_cooldown() -> void:
	_reset()
	_gs.call("mark_girl_discovered", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 2)
	var actor: GirlActor = GirlActor.new()
	actor.girl_id = &"girl_test_discovery"
	add_child(actor)
	await get_tree().process_frame
	_ok(not actor.visible, "125 hidden immediately")
	actor.queue_free()


func _test_same_girl_remains() -> void:
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_flex")
	var clues: Array = _gs.call("get_known_girl_clue_indices", &"girl_test_discovery") as Array
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 0)
	var def: GirlDefinition = _gd.call("get_girl_definition", &"girl_test_discovery") as GirlDefinition
	_ok(def != null and def.id == &"girl_test_discovery", "126 same id")
	_ok(def.appearance_profile_id == &"appearance_female_base", "126 same appearance")
	_ok(clues.size() >= 2, "126 clues preserved")


func _test_contact_clears_cooldown() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 3)
	_gd.call("begin_attempt", &"girl_test_discovery")
	# Force clear cooldown block by resetting remaining for success path test via contact API
	_gd.call("force_clear_attempt")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 0)
	_gd.call("begin_attempt", &"girl_test_discovery")
	var res: Dictionary = _gd.call("select_approach", &"discovery_approach_test_help") as Dictionary
	_ok(res.get("reason", &"") == &"SUCCESS", "127 success")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 0, "127 remaining 0")
	# Also verify add_girl_contact clears cooldown
	_reset()
	_gs.call("mark_girl_discovered", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 2)
	_gs.call("add_girl_contact", &"girl_test_discovery")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 0, "127 contact clears")


func _test_phone_only_discovered() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open()
	var listed: Array[StringName] = phone.get_listed_girl_ids()
	_ok(listed.size() == 1, "128 lists one")
	_ok(listed[0] == &"girl_test_discovery", "128 correct id")
	phone.close()
	phone.queue_free()


func _test_phone_contact_state() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open()
	phone.select_girl_by_id(&"girl_test_discovery")
	var text1: String = phone.get_detail_text()
	_ok(text1.contains("Номера нет"), "129 no number")
	phone.close()
	_gs.call("add_girl_contact", &"girl_test_discovery")
	phone.open()
	phone.select_girl_by_id(&"girl_test_discovery")
	var text2: String = phone.get_detail_text()
	_ok(text2.contains("Номер получен"), "129 number obtained")
	phone.close()
	phone.queue_free()


func _test_phone_clues() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open()
	phone.select_girl_by_id(&"girl_test_discovery")
	var text: String = phone.get_detail_text()
	_ok(text.contains("Поднимает чужой велосипед."), "130 known clue shown")
	_ok(not text.contains("Раздражается, когда помощь"), "130 unknown not leaked")
	_ok(not text.contains("? ? ?"), "130 no ??? count")
	phone.close()
	phone.queue_free()


func _test_trait_hidden() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open()
	phone.select_girl_by_id(&"girl_test_discovery")
	var text: String = phone.get_detail_text()
	_ok(text.contains("Характер: ?"), "131 trait hidden")
	_ok(not text.contains("Добрая"), "131 no KIND name")
	phone.close()
	phone.queue_free()


func _test_trait_reveal() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_gs.call("reveal_primary_trait", &"girl_test_discovery")
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open()
	phone.select_girl_by_id(&"girl_test_discovery")
	var text: String = phone.get_detail_text()
	_ok(text.contains("Добрая"), "132 trait name")
	_ok(text.contains("CARE") or text.contains("Нравится"), "132 likes")
	_ok(text.contains("Не нравится"), "132 dislikes")
	phone.close()
	phone.queue_free()


func _test_known_reaction_api() -> void:
	_reset()
	_ok(bool(_gs.call("record_girl_known_reaction", &"girl_test_discovery", &"src_a", 1)), "133 +1")
	_ok(bool(_gs.call("record_girl_known_reaction", &"girl_test_discovery", &"src_b", 0)), "133 0")
	_ok(bool(_gs.call("record_girl_known_reaction", &"girl_test_discovery", &"src_c", -1)), "133 -1")
	var reactions: Dictionary = _gs.call("get_girl_known_reactions", &"girl_test_discovery") as Dictionary
	_ok(int(reactions.get(&"src_a", 99)) == 1, "133 query +1")
	_ok(int(reactions.get(&"src_b", 99)) == 0, "133 query 0")
	_ok(int(reactions.get(&"src_c", 99)) == -1, "133 query -1")
	_ok(not bool(_gs.call("record_girl_known_reaction", &"girl_test_discovery", &"src_bad", 2)), "133 reject 2")


func _test_discovery_no_fake_reaction() -> void:
	_reset()
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_help")
	var reactions: Dictionary = _gs.call("get_girl_known_reactions", &"girl_test_discovery") as Dictionary
	_ok(reactions.is_empty(), "134 no fake reactions on success")
	_reset()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_flex")
	var reactions2: Dictionary = _gs.call("get_girl_known_reactions", &"girl_test_discovery") as Dictionary
	_ok(reactions2.is_empty(), "134 no fake reactions on failure")


func _test_no_relationship_xp_conquest() -> void:
	var src_gd: String = FileAccess.get_file_as_string("res://game/girls/girl_discovery.gd")
	var src_actor: String = FileAccess.get_file_as_string("res://game/girls/girl_actor.gd")
	_ok(not src_gd.contains("add_experience"), "136 no add_experience GirlDiscovery")
	_ok(not src_gd.contains("mark_girl_conquered"), "137 no mark_girl_conquered GirlDiscovery")
	_ok(not src_gd.contains("add_girl_relationship"), "135 no add_girl_relationship GirlDiscovery")
	_ok(not src_actor.contains("add_experience"), "136 no add_experience GirlActor")
	_ok(not src_actor.contains("mark_girl_conquered"), "137 no mark_girl_conquered GirlActor")
	_ok(not src_actor.contains("add_girl_relationship"), "135 no add_girl_relationship GirlActor")
	_reset()
	_gs.call("set_girl_relationship", &"girl_test_discovery", 2)
	_gs.call("add_experience", 1)
	var rel: int = int(_gs.call("get_girl_relationship", &"girl_test_discovery"))
	var xp: int = int(_gs.call("get_experience"))
	_gd.call("discover_girl", &"girl_test_discovery")
	_gd.call("begin_attempt", &"girl_test_discovery")
	_gd.call("select_approach", &"discovery_approach_test_help")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_discovery")) == rel, "135 rel unchanged")
	_ok(int(_gs.call("get_experience")) == xp, "136 xp unchanged")
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_test_discovery")), "137 not conquered")


func _test_phone_control_mode() -> void:
	_reset()
	var player_scene: PackedScene = load("res://characters/player/player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	await get_tree().process_frame
	player.enter_gameplay()
	var phone: PhoneJournal = PhoneJournal.new()
	add_child(phone)
	await get_tree().process_frame
	phone.open(player)
	_ok(player.get_control_mode() == PlayerController.ControlMode.MODAL_UI, "138 MODAL_UI")
	_ok(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "138 mouse visible")
	phone.close()
	_ok(player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY, "138 restored")
	phone.queue_free()
	player.queue_free()


func _test_no_phone_hotkey() -> void:
	var map_ok: bool = true
	for action in ["phone", "open_phone", "journal", "phone_journal"]:
		if InputMap.has_action(action):
			map_ok = false
	_ok(map_ok, "139 no permanent phone InputMap")


func _test_contentdb_validation() -> void:
	var db: Node = get_node("/root/ContentDB")
	var result: Dictionary = db.call("validate_all") as Dictionary
	_ok(bool(result.get("ok", false)), "140 ContentDB validate_all")
	var girls: Array = db.call("list_girls") as Array
	_ok(girls.is_empty(), "140 production girls empty")
	var sits: Array = db.call("list_discovery_situations") as Array
	_ok(sits.is_empty(), "140 production discovery empty")
	# Index fixture catalog
	var cat: ContentCatalog = ContentCatalog.new()
	var girl: GirlDefinition = load("res://data/test/girl_test_discovery.tres") as GirlDefinition
	var sit: DiscoverySituationDefinition = load(
		"res://data/test/discovery_situation_test_bicycle.tres"
	) as DiscoverySituationDefinition
	cat.girls = [girl]
	cat.discovery_situations = [sit]
	# Pull locations from production for location ref validation
	var prod: ContentCatalog = db.call("get_catalog") as ContentCatalog
	if prod != null:
		cat.locations = prod.locations
		cat.primary_traits = prod.primary_traits
		cat.secondary_traits = prod.secondary_traits
		cat.perks = prod.perks
		cat.competitions = prod.competitions
		cat.stages = prod.stages
	var idx: Dictionary = _build_idx(cat)
	_ok((idx["discovery_situations_by_id"] as Dictionary).has(&"discovery_situation_test_bicycle"), "140 indexed")


func _build_idx(cat: ContentCatalog) -> Dictionary:
	return _ContentDBScript.build_indexes(cat)


func _test_character_regression() -> void:
	_reset()
	var actor: GirlActor = GirlActor.new()
	actor.girl_id = &"girl_test_discovery"
	add_child(actor)
	await get_tree().process_frame
	var ch: CharacterActor = actor.get_character_actor()
	_ok(ch != null, "141 CharacterActor present")
	if ch != null:
		_ok(ch.get_appearance_profile_id() == &"appearance_female_base", "141 appearance applied")
	actor.queue_free()
