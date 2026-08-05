extends SceneTree
## Temporary headless proof for RC-UNIQUE-PROGRESSION-001. Deleted after run.
## Avoids compile-time DatePlaces/Game ids (same pattern as tools/smoke_test.gd).


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: PackedStringArray = PackedStringArray()
	await process_frame
	await process_frame
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	ContentDB.ensure_loaded()
	game.call("new_game")
	await process_frame

	var girls: Node = game.get("girls")
	var city: Node = game.get("city")
	var facility: Node = game.get("facility")
	var economy: Node = game.get("economy")
	var dating: Node = game.get("dating")
	var schedule: Object = dating.get("schedule")

	# --- stage_1: neighbor only ---
	girls.call("try_unlock_by_progress")
	_assert(errors, bool(girls.call("is_discovered", &"neighbor")), "s1 neighbor discovered")
	_assert(errors, not bool(girls.call("is_discovered", &"fitness")), "s1 fitness not discovered")
	_assert(errors, not bool(girls.call("is_met", &"fitness")), "s1 fitness not met")
	_assert(errors, not bool(girls.call("is_discovered", &"algorithm")), "s1 algorithm not discovered")

	# --- stage_2 ---
	_force_stage(game, facility, &"stage_2")
	girls.call("try_unlock_by_progress")
	for id in ["fitness", "goth", "streamer"]:
		_assert(errors, bool(girls.call("is_discovered", StringName(id))), "s2 discovered %s" % id)
		_assert(errors, not bool(girls.call("is_met", StringName(id))), "s2 not met %s" % id)
		_assert(errors, not bool(girls.call("has_contact", StringName(id))), "s2 no auto-contact %s" % id)

	# --- stage_3 ---
	_force_stage(game, facility, &"stage_3")
	girls.call("try_unlock_by_progress")
	for id in ["business", "fashionista", "chef", "scientist"]:
		_assert(errors, bool(girls.call("is_discovered", StringName(id))), "s3 discovered %s" % id)
		_assert(errors, not bool(girls.call("is_met", StringName(id))), "s3 not met %s" % id)

	# --- stage_4 / 5 / 6 ---
	_force_stage(game, facility, &"stage_4")
	girls.call("try_unlock_by_progress")
	_assert(errors, bool(girls.call("is_discovered", &"lawyer")), "s4 lawyer discovered")
	_assert(errors, not bool(girls.call("is_met", &"lawyer")), "s4 lawyer not met")

	_force_stage(game, facility, &"stage_5")
	girls.call("try_unlock_by_progress")
	_assert(errors, bool(girls.call("is_discovered", &"star")), "s5 star discovered")
	_assert(errors, bool(girls.call("is_discovered", &"alien")), "s5 alien discovered")
	_assert(errors, not bool(girls.call("is_discovered", &"algorithm")), "s5 algorithm still hidden")

	_force_stage(game, facility, &"stage_6")
	girls.call("try_unlock_by_progress")
	_assert(errors, not bool(girls.call("is_discovered", &"algorithm")), "s6 algorithm still finale-only")

	# --- city spawn ---
	city.call("try_unlock_park_from_progress")
	city.call("try_unlock_agency_row_from_progress")
	var spawn: Array = city.call("profiles_for_spawn")
	var spawn_ids: Dictionary = {}
	for p in spawn:
		spawn_ids[str(p.get("id", ""))] = true
	for id in ["fitness", "goth", "streamer", "business", "fashionista", "chef", "scientist", "lawyer", "star", "alien"]:
		_assert(errors, spawn_ids.has(id), "spawn has unique %s" % id)
	_assert(errors, not spawn_ids.has("algorithm"), "spawn excludes algorithm")
	_assert(errors, not spawn_ids.has("neighbor"), "spawn excludes neighbor")

	# --- talk path without mark_met ---
	economy.call("add", &"popularity", 500.0, &"test")
	economy.call("add", &"money", 500.0, &"test")
	game.set("total_successful_dates", 20)
	for id in ["business", "fashionista", "scientist", "lawyer", "star", "alien"]:
		_assert(errors, bool(city.call("is_worthy", id)), "worthy %s" % id)
		var talk_res: Dictionary = city.call("talk", id)
		_assert(errors, bool(talk_res.get("ok", false)), "talk ok %s" % id)
		_assert(errors, bool(girls.call("has_contact", StringName(id))), "contact after talk %s" % id)
		_assert(errors, not bool(girls.call("is_met", StringName(id))), "still unmet after talk %s" % id)

	# --- repeated unlock ---
	var disc: Array = girls.get("discovered_unique")
	var before_n: int = disc.size()
	girls.call("try_unlock_by_progress")
	girls.call("try_unlock_by_progress")
	disc = girls.get("discovered_unique")
	_assert(errors, disc.size() == before_n, "repeated unlock idempotent")

	# --- save/load ---
	var blob: Dictionary = girls.call("to_dict")
	var disc_saved: Array = blob.get("discovered_unique", [])
	_assert(errors, disc_saved.has("business"), "save discovered_unique has business")
	_assert(errors, not disc_saved.has("algorithm"), "save excludes algorithm")
	girls.call("from_dict", blob)
	_assert(errors, bool(girls.call("is_discovered", &"alien")), "load restores alien discovery")
	_assert(errors, not bool(girls.call("is_met", &"alien")), "load does not auto-met")

	# --- stage downgrade sticky + spawn gate ---
	_force_stage(game, facility, &"stage_2")
	girls.call("try_unlock_by_progress")
	_assert(errors, bool(girls.call("is_discovered", &"alien")), "downgrade keeps sticky alien discovery")
	var spawn2: Array = city.call("profiles_for_spawn")
	var spawn2_ids: Dictionary = {}
	for p2 in spawn2:
		spawn2_ids[str(p2.get("id", ""))] = true
	_assert(errors, spawn2_ids.has("fitness"), "s2 spawn fitness")
	_assert(errors, not spawn2_ids.has("alien"), "s2 spawn excludes alien by stage gate")

	# --- arcade venue via schedule.book (place_id stays arcade; venue_id=arcade) ---
	_force_stage(game, facility, &"stage_2")
	facility.call("unlock_venue", &"arcade", false)
	facility.call("unlock_venue", &"cheap_cafe", false)
	if schedule.has_method("clear"):
		schedule.call("clear")
	elif schedule.has_method("cancel"):
		schedule.call("cancel")
	else:
		schedule.set("scheduled", {})
	var booked: bool = bool(schedule.call("book", "business", "arcade", 2, 14 * 60, true))
	_assert(errors, booked, "book arcade place_id")
	var sched: Dictionary = schedule.get("scheduled")
	_assert(errors, str(sched.get("place_id", "")) == "arcade", "scheduled place_id=arcade")
	_assert(errors, str(sched.get("venue_id", "")) == "arcade", "scheduled venue_id=arcade")
	if schedule.has_method("clear"):
		schedule.call("clear")
	elif schedule.has_method("cancel"):
		schedule.call("cancel")
	else:
		schedule.set("scheduled", {})
	var booked_cafe: bool = bool(schedule.call("book", "business", "cafe", 2, 15 * 60, true))
	_assert(errors, booked_cafe, "book cafe")
	var sched_cafe: Dictionary = schedule.get("scheduled")
	_assert(errors, str(sched_cafe.get("venue_id", "")) == "cheap_cafe", "cafe venue_id=cheap_cafe")
	_assert(errors, str(sched.get("venue_id", "")) != str(sched_cafe.get("venue_id", "")), "arcade/cafe venues differ")

	# simultaneous reserve cafe + arcade; second arcade blocked
	var venue_load: Dictionary = facility.get("venue_load")
	venue_load["cheap_cafe"] = 0
	venue_load["arcade"] = 0
	facility.set("venue_load", venue_load)
	_assert(errors, bool(facility.call("reserve_venue", &"cheap_cafe")), "reserve cafe")
	_assert(errors, bool(facility.call("reserve_venue", &"arcade")), "reserve arcade while cafe busy")
	_assert(errors, not bool(facility.call("reserve_venue", &"arcade")), "second arcade reserve blocked")
	facility.call("release_venue", &"cheap_cafe")
	facility.call("release_venue", &"arcade")

	# cinema_room remains independent of arcade capacity
	facility.call("unlock_venue", &"cinema_room", false)
	venue_load = facility.get("venue_load")
	venue_load["arcade"] = 0
	venue_load["cinema_room"] = 0
	facility.set("venue_load", venue_load)
	_assert(errors, bool(facility.call("reserve_venue", &"arcade")), "reserve arcade alone")
	_assert(errors, bool(facility.call("reserve_venue", &"cinema_room")), "reserve cinema while arcade busy")
	facility.call("release_venue", &"arcade")
	facility.call("release_venue", &"cinema_room")

	if errors.is_empty():
		print("RC_UNIQUE_PROGRESSION_SMOKE_OK")
		quit(0)
	else:
		print("RC_UNIQUE_PROGRESSION_SMOKE_FAIL count=%d" % errors.size())
		for e in errors:
			print("FAIL: %s" % e)
		quit(1)


func _force_stage(game: Node, facility: Node, sid: StringName) -> void:
	game.set("stage_id", sid)
	facility.call("unlock_stage", sid, false)


func _assert(errors: PackedStringArray, cond: bool, label: String) -> void:
	if not cond:
		errors.append(label)
