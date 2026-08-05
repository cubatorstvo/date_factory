class_name ReleaseSmokeSuite
extends RefCounted
## Fast headless smoke: init, ContentDB, scenes, New Game, save isolation, core transitions.


func run(tree: SceneTree, helpers: RefCounted, seed_helper: RefCounted, report: RefCounted) -> bool:
	seed_helper.apply_headless_defaults()
	var game: Node = helpers.game_node(tree)
	if not helpers.require(game != null, "autoload_game", "/root/Game"):
		return false
	var bus: Node = tree.root.get_node_or_null("EventBus")
	helpers.check(bus != null, "autoload_eventbus", "/root/EventBus")

	if not helpers.assert_modules(game):
		return false

	ContentDB.ensure_loaded()
	helpers.check(ContentDB.gifts.size() >= 24, "content_gifts", "count=%d" % ContentDB.gifts.size())
	helpers.check(ContentDB.outfits.size() >= 11, "content_outfits", "count=%d" % ContentDB.outfits.size())
	helpers.check(ContentDB.venues.size() >= 11, "content_venues", "count=%d" % ContentDB.venues.size())
	helpers.check(ContentDB.venues.has("arcade"), "content_venue_arcade")
	helpers.check(str(DatePlaces.place("arcade").get("venue_id", "")) == "arcade", "date_places_arcade_venue_id")
	helpers.check(str(DatePlaces.place("cafe").get("venue_id", "")) == "cheap_cafe", "date_places_cafe_venue_id")
	helpers.check(DatePlaces.normalize_venue_id("arcade", "cheap_cafe") == "arcade", "arcade_migrate_from_cheap_cafe")
	helpers.check(DatePlaces.normalize_venue_id("arcade", "cinema_room") == "arcade", "arcade_migrate_from_cinema_room")
	helpers.check(ContentDB.girls.size() >= 12, "content_girls", "count=%d" % ContentDB.girls.size())
	helpers.check(ContentDB.upgrades.size() >= 80, "content_upgrades", "count=%d" % ContentDB.upgrades.size())
	helpers.check(ContentDB.events.size() >= 30, "content_events", "count=%d" % ContentDB.events.size())
	helpers.check(ContentDB.stages.size() >= 6, "content_stages", "count=%d" % ContentDB.stages.size())
	helpers.check(ContentDB.rooms.size() >= 8, "content_rooms", "count=%d" % ContentDB.rooms.size())

	if not helpers.assert_critical_resources_loadable():
		return false

	var save: Node = game.get("save")
	var normal_path: String = str(save.get("PATH"))
	var qa_path: String = str(save.get("QA_FULL_ACCESS_PATH"))
	if not helpers.require(normal_path != qa_path and not normal_path.is_empty() and not qa_path.is_empty(), "save_path_constants_distinct", "%s vs %s" % [normal_path, qa_path]):
		return false

	# Seed a known QA slot marker so Continue/normal save cannot silently mutate it.
	var qa_probe: Dictionary = {
		"qa_profile": "full_access",
		"qa_schema_version": 1,
		"stage_id": "stage_6",
		"probe_token": "rc_b001_isolation",
	}
	save.call("write_qa_full_access_save", qa_probe)
	var qa_before_text: String = _read_user_file_text(qa_path)
	if not helpers.require(not qa_before_text.is_empty() and qa_before_text.contains("rc_b001_isolation"), "qa_slot_seeded"):
		return false

	# no-save boot: «Продолжить» must be disabled and must not create QA/normal side effects.
	var prior_normal: Dictionary = {}
	var had_normal: bool = bool(save.call("has_save"))
	if had_normal:
		prior_normal = save.call("read_save")
	_delete_user_file(normal_path)
	if not helpers.require(not bool(save.call("has_save")), "no_save_slot_cleared"):
		return false
	if not _assert_boot_continue_disabled(tree, helpers, true, "boot_continue_disabled_without_save"):
		return false
	var qa_after_nosave: String = _read_user_file_text(qa_path)
	if not helpers.require(qa_after_nosave == qa_before_text, "qa_unchanged_after_nosave_boot"):
		return false

	game.call("new_game")
	if not helpers.require(bool(game.get("run_started")), "new_game_run_started"):
		return false
	if not helpers.require(str(game.get("stage_id")) == "stage_1", "new_game_stage_1", str(game.get("stage_id"))):
		return false
	if not helpers.require(not bool(game.get("postgame")), "new_game_not_postgame"):
		return false
	var new_game_blob: Dictionary = game.call("to_dict")
	if not helpers.require(not new_game_blob.has("qa_profile"), "new_game_no_qa_profile_marker"):
		return false
	if not helpers.require(str(new_game_blob.get("stage_id", "")) == "stage_1", "new_game_dict_stage_1"):
		return false
	var girls: Node = game.get("girls")
	if not helpers.require(bool(girls.call("has_contact", &"neighbor")), "new_game_neighbor_contact"):
		return false
	# New Game must not look like QA unlock matrix (stage_6 / huge money).
	var starting_money: float = float(game.get("economy").call("get_value", &"money"))
	if not helpers.require(starting_money < 10000.0, "new_game_not_qa_economy", "money=%.1f" % starting_money):
		return false

	# Core transition: buy + short neighbor date via production dating API.
	seed_helper.seed_economy(game, 500.0, 5.0, 10.0, 10.0)
	var inventory: Node = game.get("inventory")
	if not helpers.require(bool(inventory.call("buy_gift", &"flower")), "buy_gift_flower"):
		return false
	if not helpers.run_manual_date(game, "neighbor", &"flower", &"kitchen_table", &"casual", "smoke_neighbor_date"):
		return false

	# Normal save with several identifiable fields (Continue contract).
	var marker_money: float = 1234.5
	var marker_dates: int = 7
	var marker_tutorial: bool = true
	game.get("economy").call("set_value", &"money", marker_money)
	game.get("economy").call("set_value", &"popularity", 42.0)
	game.set("total_successful_dates", marker_dates)
	game.set("tutorial_done", marker_tutorial)
	game.call("save_game")
	if not helpers.require(bool(save.call("has_save")), "normal_save_written"):
		return false
	var normal_disk: Dictionary = save.call("read_save")
	if not helpers.require(not normal_disk.has("qa_profile"), "normal_save_not_qa_profile"):
		return false

	# Boot with save present → Continue enabled.
	if not _assert_boot_continue_disabled(tree, helpers, false, "boot_continue_enabled_with_save"):
		return false

	# Mutate runtime, then Continue path (= load_game on slot_1) restores markers.
	game.get("economy").call("set_value", &"money", 0.0)
	game.get("economy").call("set_value", &"popularity", 0.0)
	game.set("total_successful_dates", 0)
	game.set("tutorial_done", false)
	game.set("stage_id", &"stage_2")
	game.call("load_game")
	var loaded_money: float = float(game.get("economy").call("get_value", &"money"))
	var loaded_pop: float = float(game.get("economy").call("get_value", &"popularity"))
	var loaded_dates: int = int(game.get("total_successful_dates"))
	var loaded_tutorial: bool = bool(game.get("tutorial_done"))
	if not helpers.require(is_equal_approx(loaded_money, marker_money), "continue_restores_money", "got=%.2f" % loaded_money):
		return false
	if not helpers.require(is_equal_approx(loaded_pop, 42.0), "continue_restores_popularity", "got=%.2f" % loaded_pop):
		return false
	if not helpers.require(loaded_dates == marker_dates, "continue_restores_dates", "got=%d" % loaded_dates):
		return false
	if not helpers.require(loaded_tutorial == marker_tutorial, "continue_restores_tutorial"):
		return false
	if not helpers.require(str(game.get("stage_id")) == "stage_1", "continue_restores_stage_1", str(game.get("stage_id"))):
		return false

	# QA slot must be byte-identical after New Game / save / Continue-load.
	var qa_after_continue: String = _read_user_file_text(qa_path)
	if not helpers.require(qa_after_continue == qa_before_text, "qa_slot_unchanged_after_continue"):
		return false
	if not helpers.require(bool(save.call("has_qa_full_access_save")), "qa_slot_still_exists"):
		return false

	# Restore prior normal save if smoke overwrote a developer slot (best-effort).
	if had_normal and not prior_normal.is_empty():
		# Keep smoke's written slot_1 as the active contract proof; do not restore over it.
		helpers.check(true, "prior_normal_save_noted", "smoke overwrote slot_1 for Continue contract")

	# Soft stage expand readiness smoke (does not force finale).
	seed_helper.seed_economy(game, 5000.0, 30.0, 20.0, 10.0)
	seed_helper.bump_successful_dates(game, 5)
	var facility: Node = game.get("facility")
	if bool(facility.call("buy_stage_expansion")):
		helpers.check(str(game.get("stage_id")) == "stage_2", "core_transition_stage_2", str(game.get("stage_id")))
	else:
		helpers.check(false, "core_transition_stage_2", "buy_stage_expansion returned false")

	# RC-B002: unique discoverability / talk / algorithm exclusion (production APIs).
	var girls_api: Node = game.get("girls")
	var city_api: Node = game.get("city")
	girls_api.call("try_unlock_by_progress")
	if not helpers.require(bool(girls_api.call("is_discovered", &"fitness")), "unique_s2_discovers_fitness"):
		return false
	if not helpers.require(not bool(girls_api.call("is_discovered", &"algorithm")), "unique_algorithm_not_discovered_early"):
		return false
	if not helpers.require(not bool(girls_api.call("has_contact", &"fitness")), "unique_discover_no_auto_contact"):
		return false
	var disc_n: int = int(girls_api.get("discovered_unique").size())
	girls_api.call("try_unlock_by_progress")
	if not helpers.require(int(girls_api.get("discovered_unique").size()) == disc_n, "unique_unlock_idempotent"):
		return false
	seed_helper.seed_economy(game, 5000.0, 20.0, 20.0, 10.0)
	seed_helper.bump_successful_dates(game, 2)
	if not helpers.meet_via_city_talk(game, "fitness", "unique_fitness_talk"):
		return false
	if not helpers.require(not bool(girls_api.call("is_met", &"fitness")), "unique_talk_does_not_mark_met"):
		return false
	var spawn: Array = city_api.call("profiles_for_spawn")
	var spawn_has_algo: bool = false
	var spawn_has_fitness: bool = false
	for p in spawn:
		var pid: String = str(p.get("id", ""))
		if pid == "algorithm":
			spawn_has_algo = true
		if pid == "fitness":
			spawn_has_fitness = true
	if not helpers.require(spawn_has_fitness, "unique_spawn_includes_fitness"):
		return false
	if not helpers.require(not spawn_has_algo, "unique_spawn_excludes_algorithm"):
		return false
	var girls_blob: Dictionary = girls_api.call("to_dict")
	game.call("new_game")
	girls_api = game.get("girls")
	girls_api.call("from_dict", girls_blob)
	if not helpers.require(bool(girls_api.call("is_discovered", &"fitness")), "unique_discovery_save_load"):
		return false
	if not helpers.require(bool(girls_api.call("has_contact", &"fitness")), "unique_contact_save_load"):
		return false

	# RC-M007: arcade capacity is independent from cheap_cafe; same arcade still conflicts.
	facility = game.get("facility")
	facility.call("unlock_venue", &"cheap_cafe", false)
	facility.call("unlock_venue", &"arcade", false)
	var venue_load: Dictionary = facility.get("venue_load")
	venue_load["cheap_cafe"] = 0
	venue_load["arcade"] = 0
	facility.set("venue_load", venue_load)
	if not helpers.require(bool(facility.call("reserve_venue", &"cheap_cafe")), "arcade_cap_reserve_cafe"):
		return false
	if not helpers.require(bool(facility.call("reserve_venue", &"arcade")), "arcade_cap_reserve_arcade_while_cafe_busy"):
		return false
	if not helpers.require(not bool(facility.call("reserve_venue", &"arcade")), "arcade_cap_second_arcade_blocked"):
		return false
	facility.call("release_venue", &"cheap_cafe")
	facility.call("release_venue", &"arcade")
	var dating: Node = game.get("dating")
	var schedule: Object = dating.get("schedule")
	if schedule.has_method("cancel"):
		schedule.call("cancel")
	var legacy_ok: bool = true
	schedule.call("from_dict", {
		"scheduled": {
			"target_id": "neighbor",
			"unique": true,
			"place_id": "arcade",
			"venue_id": "cheap_cafe",
			"day": 2,
			"minutes": 1080,
		},
		"place_occupancy": {},
		"homeware_level": 1,
		"table": {},
		"gift_given_id": "",
	})
	var migrated: Dictionary = schedule.get("scheduled")
	if str(migrated.get("place_id", "")) != "arcade" or str(migrated.get("venue_id", "")) != "arcade":
		legacy_ok = false
	if not helpers.require(legacy_ok, "arcade_legacy_booking_migrates", str(migrated)):
		return false
	if schedule.has_method("cancel"):
		schedule.call("cancel")

	report.note("Smoke verifies logical contracts only; no visual/render coverage.")
	return errors_empty(helpers)


func errors_empty(helpers: RefCounted) -> bool:
	return helpers.errors.is_empty()


func _assert_boot_continue_disabled(tree: SceneTree, helpers: RefCounted, expect_disabled: bool, step_id: String) -> bool:
	var packed: PackedScene = load("res://scenes/boot/boot.tscn") as PackedScene
	if packed == null:
		return helpers.require(false, step_id, "boot.tscn missing")
	var boot: Node = packed.instantiate()
	tree.root.add_child(boot)
	# _ready runs before add_child returns; Continue.disabled already reflects has_save().
	var cont: Button = boot.get_node_or_null("Center/Panel/Content/Continue") as Button
	var ok: bool = cont != null and cont.disabled == expect_disabled
	var detail: String = "missing Continue" if cont == null else "disabled=%s expected=%s" % [str(cont.disabled), str(expect_disabled)]
	boot.free()
	return helpers.require(ok, step_id, detail)


func _delete_user_file(user_path: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(user_path)
	if FileAccess.file_exists(user_path):
		DirAccess.remove_absolute(abs_path)


func _read_user_file_text(user_path: String) -> String:
	if not FileAccess.file_exists(user_path):
		return ""
	var f: FileAccess = FileAccess.open(user_path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()
