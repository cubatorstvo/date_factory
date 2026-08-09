extends Node
## AP1-NPC presentation rules: city spawn exclusion, cafe cap, date clearance.
## Run: res://world/test/npc_presentation_rules_test.tscn --quit-after 30000

var _failed: int = 0
var _passed: int = 0
var _world: Node = null
var _gs: Node = null
var _dc: Node = null
var _db: Node = null


func _ready() -> void:
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	_dc = get_node("/root/DatingCore")
	_db = get_node("/root/ContentDB")
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		DfLog.info("AP1_NPC_TEST", "ALL PASS (%s)" % _passed)
		print("AP1_NPC_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("AP1_NPC_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("AP1_NPC_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[AP1_NPC_TEST] FAIL: %s" % label)
		print("AP1_NPC_TEST FAIL: %s" % label)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _run_all() -> void:
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	await get_tree().process_frame
	await _test_city_spawn_exclusion()
	await _test_cafe_ordinary_cap()
	await _test_cafe_date_clearance()


func _find_rules(loc: WorldLocation) -> NpcPresentationRules:
	if loc == null:
		return null
	var node: Node = loc.get_node_or_null("NpcSpawns/NpcPresentationRules")
	return node as NpcPresentationRules


func _test_city_spawn_exclusion() -> void:
	var travel: int = int(_world.call("request_travel", &"city_hub", &"spawn_default"))
	_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "city travel")
	await _settle()
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	_ok(loc != null, "city location")
	var rules: NpcPresentationRules = _find_rules(loc)
	_ok(rules != null, "city NpcPresentationRules attached")
	if rules == null or loc == null:
		return
	rules.apply_rules()
	await _settle()
	var errs: Array[String] = rules.validate_city_spawn_exclusion()
	_ok(errs.is_empty(), "city ordinary not visible within 2.5m (%s)" % ",".join(errs))
	# Synthetic probe: place ordinary GirlActor at spawn and require hide.
	var spawn: PlayerSpawnPoint = loc.get_player_spawn(&"spawn_default")
	_ok(spawn != null, "city spawn_default")
	if spawn == null:
		return
	var probe_marker := Marker3D.new()
	probe_marker.name = "npc_probe_near_spawn"
	var spawns: Node = loc.get_node_or_null("NpcSpawns")
	_ok(spawns != null, "city NpcSpawns")
	if spawns == null:
		return
	spawns.add_child(probe_marker)
	probe_marker.global_position = spawn.global_position
	var probe := GirlActor.new()
	probe.name = "GirlActor"
	probe.girl_id = &"girl_public_sculpture"
	probe_marker.add_child(probe)
	await _settle()
	rules.apply_rules()
	await _settle()
	var probe_hidden: bool = not rules.is_actor_presentation_visible(probe)
	_ok(probe_hidden, "city probe near spawn presentation-hidden")
	var errs2: Array[String] = rules.validate_city_spawn_exclusion()
	_ok(errs2.is_empty(), "city exclusion holds with probe (%s)" % ",".join(errs2))
	# Content id unchanged.
	_ok(probe.girl_id == &"girl_public_sculpture", "city probe content id unchanged")
	probe_marker.queue_free()
	await _settle()


func _test_cafe_ordinary_cap() -> void:
	var travel: int = int(_world.call("request_travel", &"cafe", &"spawn_default"))
	_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "cafe travel")
	await _settle()
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	_ok(loc != null, "cafe location")
	var rules: NpcPresentationRules = _find_rules(loc)
	_ok(rules != null, "cafe NpcPresentationRules attached")
	if rules == null:
		return
	rules.apply_rules()
	await _settle()
	var ordinary_n: int = rules.get_ordinary_actors().size()
	_ok(ordinary_n >= 5, "cafe has multiple ordinary NPCs (got %d)" % ordinary_n)
	var visible_n: int = rules.count_visible_ordinary()
	_ok(visible_n <= 4, "cafe ordinary visible <= 4 (got %d)" % visible_n)
	var errs: Array[String] = rules.validate_cafe_ordinary_cap()
	_ok(errs.is_empty(), "cafe cap validator (%s)" % ",".join(errs))
	# Markers / content ids preserved on hidden actors.
	var ids_ok: bool = true
	for actor in rules.get_ordinary_actors():
		if actor is GirlActor:
			# Empty or non-empty both fine; node must still exist under marker.
			if actor.get_parent() == null:
				ids_ok = false
		elif actor is RivalActor:
			if actor.get_parent() == null:
				ids_ok = false
	_ok(ids_ok, "cafe capped NPCs keep marker parents")


func _test_cafe_date_clearance() -> void:
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	if loc == null or String(loc.location_id) != "cafe":
		var travel: int = int(_world.call("request_travel", &"cafe", &"spawn_default"))
		_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "cafe travel for date")
		await _settle()
		loc = _world.call("get_current_location") as WorldLocation
	var rules: NpcPresentationRules = _find_rules(loc)
	_ok(rules != null, "cafe rules for date clearance")
	if rules == null or loc == null:
		return
	var venue: Node3D = loc.get_node_or_null("Interactables/DateVenue") as Node3D
	_ok(venue != null, "DateVenue present")
	if venue == null:
		return
	# Place a temporary ordinary rival on the date table, then activate a date.
	var probe_marker := Marker3D.new()
	probe_marker.name = "npc_probe_on_date_table"
	var spawns: Node = loc.get_node_or_null("NpcSpawns")
	spawns.add_child(probe_marker)
	probe_marker.global_position = venue.global_position
	var probe := RivalActor.new()
	probe.name = "RivalActor"
	probe.rival_id = &"rival_cafe_receipt"
	probe_marker.add_child(probe)
	await _settle()
	# Without date: may be capped/hidden already; with date must be hidden by clearance.
	DatingTestFixtures.register_all(_db)
	_gs.call("mark_girl_discovered", &"girl_test_dating_kind")
	_gs.call("add_girl_contact", &"girl_test_dating_kind")
	var req: DatingStartRequest = DatingTestFixtures.default_request(&"girl_test_dating_kind")
	req.location_id = &"cafe"
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	_ok(bool(start.get("ok", false)), "start_date ok for clearance test")
	_ok(bool(_dc.call("is_date_active")), "date active")
	rules.apply_rules()
	await _settle()
	var errs: Array[String] = rules.validate_cafe_date_clearance()
	_ok(errs.is_empty(), "date clearance validator (%s)" % ",".join(errs))
	_ok(not rules.is_actor_presentation_visible(probe), "probe on DateVenue hidden while date active")
	_ok(probe.rival_id == &"rival_cafe_receipt", "date probe rival_id unchanged")
	# End date → restore path should unhide probe unless still over cap.
	_dc.call("force_clear_session")
	await _settle()
	rules.apply_rules()
	await _settle()
	_ok(not bool(_dc.call("is_date_active")), "date cleared")
	var cap_errs: Array[String] = rules.validate_cafe_ordinary_cap()
	_ok(cap_errs.is_empty(), "cap still holds after date end (%s)" % ",".join(cap_errs))
	probe_marker.queue_free()
	await _settle()
