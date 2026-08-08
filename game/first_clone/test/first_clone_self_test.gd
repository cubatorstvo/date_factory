extends Node
## MODULE 17 First Clone core self-test (M17_A_CORE).
## Run: res://game/first_clone/test/first_clone_test.tscn --quit-after 40000


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _fc: Node = null
var _gd: Node = null
var _world: Node = null
var _overload: Node = null
var _story: Node = null
var _day: Node = null
var _rel: Node = null
var _date_id_seq: int = 17000


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_fc = get_node("/root/FirstClone")
	_gd = get_node("/root/GirlDiscovery")
	_world = get_node("/root/World")
	_overload = get_node("/root/DatingOverload")
	_story = get_node("/root/Story")
	_day = get_node("/root/GameDay")
	_rel = get_node("/root/Relationships")
	await get_tree().process_frame
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_17_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_17_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_17_TEST PASS: %s" % label)
	else:
		DfLog.error("MODULE_17_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_17_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_17_TEST] FAIL: %s" % label)
		print("MODULE_17_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	if _fc.has_method("set_instant_for_test"):
		_fc.call("set_instant_for_test", true)
	_gd.call("clear_content_overrides")
	_gd.call("force_clear_attempt")
	if _rel != null and _rel.has_method("clear_applied_date_ids"):
		_rel.call("clear_applied_date_ids")
	_world.set("current_location_id", &"apartment")


func _seed_lab_ready() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("mark_dating_overload_problem_recognized")
	_gs.call("mark_girl_conquered", &"girl_scientist")
	_world.set("current_location_id", &"laboratory")


func _ensure_lab_markers() -> void:
	var out_m: Marker3D = Marker3D.new()
	out_m.name = FirstCloneTypes.MARKER_OUTPUT
	out_m.position = Vector3(0, 0, 0)
	add_child(out_m)
	var work_m: Marker3D = Marker3D.new()
	work_m.name = FirstCloneTypes.MARKER_WORK
	work_m.position = Vector3(2, 0, 0)
	add_child(work_m)
	var date_m: Marker3D = Marker3D.new()
	date_m.name = FirstCloneTypes.MARKER_DATE
	date_m.position = Vector3(-2, 0, 0)
	add_child(date_m)


func _register_scientist_stub() -> void:
	var def: GirlDefinition = GirlDefinition.new()
	def.id = &"girl_scientist"
	def.display_name = "Учёная"
	def.required_experience = 4
	_gd.call("register_girl_definition", def)


func _run_all() -> void:
	# May await nested tests; caller must await this.
	_ensure_lab_markers()
	_test_autoload_order_and_no_process()
	_test_calibration_constants()
	_test_pointer_ping_pong()
	_test_miss_retries_same_pass()
	_test_success_advances_pass()
	await _test_abort_zero_clones()
	_test_preview_before_assignment()
	_test_work_commit()
	_test_dating_commit()
	_test_double_assign_blocked()
	_test_no_late_rates()
	_test_machine_gates()
	_test_representative_reconstruct()
	_test_story_prerequisite()
	await _test_scientist_production_wiring()
	_test_boundaries_overload_cap()
	_test_phone_story_and_clone_section()
	_reset()


func _test_autoload_order_and_no_process() -> void:
	_ok(_fc != null, "autoload FirstClone present")
	var src: String = FileAccess.get_file_as_string("res://game/first_clone/first_clone.gd")
	_ok(not src.contains("func _process"), "FirstClone no _process")
	_ok(not src.contains("set_late_rates(") and not src.contains("\"set_late_rates\""), "FirstClone never set_late_rates")
	var anchor_src: String = FileAccess.get_file_as_string("res://world/actors/stage_actor_anchor.gd")
	_ok(anchor_src.contains("requires_overload_recognized"), "StageActorAnchor export flag")
	_ok(anchor_src.contains("requires_first_clone_created"), "StageActorAnchor first-clone export")
	_ok(anchor_src.contains("clone_counts_changed"), "StageActorAnchor listens clone_counts_changed")
	_ok(anchor_src.contains("state_reset"), "StageActorAnchor listens state_reset")
	_ok(not anchor_src.contains("func _process"), "StageActorAnchor no _process")
	var girl_actor_src: String = FileAccess.get_file_as_string("res://game/girls/girl_actor.gd")
	_ok(girl_actor_src.contains("STORY_PREREQUISITE"), "GirlActor STORY_PREREQUISITE branch")
	_ok(
		girl_actor_src.contains("Сначала нужно понять, зачем тебе вообще второй ты."),
		"GirlActor Scientist prerequisite feedback",
	)
	_ok(
		girl_actor_src.contains("Сначала лаборатория должна доказать, что умеет производить больше одного тебя."),
		"GirlActor President prerequisite feedback",
	)
	var discovery_src: String = FileAccess.get_file_as_string("res://game/girls/girl_discovery.gd")
	var gate_idx: int = discovery_src.find("func _story_gate_block")
	var prereq_in_gate: int = discovery_src.find("_story_prerequisite_block", gate_idx)
	var story_gate_call: int = discovery_src.find("get_story_girl_gate", gate_idx)
	_ok(gate_idx >= 0 and prereq_in_gate >= 0 and story_gate_call >= 0, "FIX2 gate helpers present")
	_ok(prereq_in_gate < story_gate_call, "FIX2 prerequisite before get_story_girl_gate")
	var begin_idx: int = discovery_src.find("func begin_attempt")
	var begin_end: int = discovery_src.find("\nfunc ", begin_idx + 1)
	if begin_end < 0:
		begin_end = discovery_src.length()
	var begin_body: String = discovery_src.substr(begin_idx, begin_end - begin_idx)
	_ok(begin_body.contains("_story_gate_block"), "FIX2 begin_attempt uses _story_gate_block")
	_ok(not begin_body.contains("_story_prerequisite_block"), "FIX2 begin_attempt no early prerequisite")


func _test_calibration_constants() -> void:
	var body: Dictionary = {
		"target_center": FirstCloneTypes.BODY_CENTER,
		"target_width": FirstCloneTypes.BODY_WIDTH,
		"pointer_speed": FirstCloneTypes.BODY_SPEED,
	}
	var face: Dictionary = {
		"target_center": FirstCloneTypes.FACE_CENTER,
		"target_width": FirstCloneTypes.FACE_WIDTH,
		"pointer_speed": FirstCloneTypes.FACE_SPEED,
	}
	var conf: Dictionary = {
		"target_center": FirstCloneTypes.CONFIDENCE_CENTER,
		"target_width": FirstCloneTypes.CONFIDENCE_WIDTH,
		"pointer_speed": FirstCloneTypes.CONFIDENCE_SPEED,
	}
	_ok(is_equal_approx(float(body["target_center"]), 0.35), "65 BODY center .35")
	_ok(is_equal_approx(float(body["target_width"]), 0.28), "65 BODY width .28")
	_ok(is_equal_approx(float(body["pointer_speed"]), 0.55), "65 BODY speed .55")
	_ok(is_equal_approx(float(face["target_center"]), 0.62), "65 FACE center .62")
	_ok(is_equal_approx(float(face["target_width"]), 0.22), "65 FACE width .22")
	_ok(is_equal_approx(float(face["pointer_speed"]), 0.70), "65 FACE speed .70")
	_ok(is_equal_approx(float(conf["target_center"]), 0.48), "65 CONF center .48")
	_ok(is_equal_approx(float(conf["target_width"]), 0.16), "65 CONF width .16")
	_ok(is_equal_approx(float(conf["pointer_speed"]), 0.85), "65 CONF speed .85")
	var mg: CloneCalibrationMinigame = CloneCalibrationMinigame.new()
	add_child(mg)
	mg.start(null)
	var c0: Dictionary = mg.get_pass_constants(0)
	_ok(is_equal_approx(float(c0["target_center"]), 0.35), "65 minigame BODY constants")
	mg.abort_calibration()


func _test_pointer_ping_pong() -> void:
	var mg: CloneCalibrationMinigame = CloneCalibrationMinigame.new()
	add_child(mg)
	mg.start(null)
	mg.continue_intro()
	var min_p: float = 1.0
	var max_p: float = 0.0
	var saw_reflect: bool = false
	var in_range: bool = true
	var prev: float = mg.get_pointer()
	for _i in range(240):
		mg.tick_pointer(0.05)
		var p: float = mg.get_pointer()
		if p < 0.0 or p > 1.0:
			in_range = false
			break
		min_p = minf(min_p, p)
		max_p = maxf(max_p, p)
		if prev > 0.9 and p < prev:
			saw_reflect = true
		prev = p
	_ok(in_range, "65 pointer stays 0..1")
	_ok(min_p <= 0.05 and max_p >= 0.95, "65 pointer reaches ends")
	_ok(saw_reflect, "65 pointer reflects")
	mg.abort_calibration()


func _test_miss_retries_same_pass() -> void:
	var mg: CloneCalibrationMinigame = CloneCalibrationMinigame.new()
	add_child(mg)
	mg.start(null)
	mg.continue_intro()
	_ok(mg.get_pass_index() == 0, "65 start BODY")
	var hit: bool = mg.try_press_at(0.99)
	_ok(not hit, "65 miss false")
	_ok(mg.get_pass_index() == 0, "65 miss same pass")
	_ok(mg.is_in_miss_feedback(), "65 miss feedback")
	mg.abort_calibration()


func _test_success_advances_pass() -> void:
	var mg: CloneCalibrationMinigame = CloneCalibrationMinigame.new()
	add_child(mg)
	mg.start(null)
	mg.continue_intro()
	_ok(mg.force_hit_current_pass(), "65 BODY hit")
	# Advance feedback synchronously.
	mg.try_space()
	_ok(mg.get_pass_index() == 1, "65 next FACE")
	_ok(mg.force_hit_current_pass(), "65 FACE hit")
	mg.try_space()
	_ok(mg.get_pass_index() == 2, "65 next CONFIDENCE")
	mg.abort_calibration()


func _test_abort_zero_clones() -> void:
	_seed_lab_ready()
	_ok(bool(_fc.call("start_sequence", null)), "65 abort start ok")
	_fc.call("abort_sequence")
	await get_tree().process_frame
	_ok(int(_gs.call("get_total_clones")) == 0, "65 abort total0")
	_ok(int(_gs.call("get_clones_working")) == 0, "65 abort working0")
	_ok(int(_gs.call("get_clones_dating")) == 0, "65 abort dating0")
	_ok(not bool(_fc.call("is_sequence_active")), "65 abort inactive")


func _test_preview_before_assignment() -> void:
	_seed_lab_ready()
	_ok(bool(_fc.call("complete_calibration_for_test")), "66 calibration complete")
	_ok(bool(_fc.call("has_preview_actor")), "66 preview visible")
	_ok(int(_gs.call("get_total_clones")) == 0, "66 total still0")
	_ok(bool(_fc.call("is_awaiting_assignment")), "66 assignment shown")
	_fc.call("abort_sequence")


func _test_work_commit() -> void:
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_ok(bool(_fc.call("assign_work")), "66 WORK commit")
	_ok(int(_gs.call("get_total_clones")) == 1, "66 WORK total1")
	_ok(int(_gs.call("get_clones_working")) == 1, "66 WORK working1")
	_ok(int(_gs.call("get_clones_dating")) == 0, "66 WORK dating0")
	_ok(int(_gs.call("get_free_clones")) == 0, "66 WORK free0")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 20.0), "66 WORK mpm20")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "66 WORK dpm0")


func _test_dating_commit() -> void:
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_ok(bool(_fc.call("assign_dating")), "66 DATING commit")
	_ok(int(_gs.call("get_total_clones")) == 1, "66 DATING total1")
	_ok(int(_gs.call("get_clones_working")) == 0, "66 DATING working0")
	_ok(int(_gs.call("get_clones_dating")) == 1, "66 DATING dating1")
	_ok(int(_gs.call("get_free_clones")) == 0, "66 DATING free0")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "66 DATING mpm0")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.50), "66 DATING dpm0.5")


func _test_double_assign_blocked() -> void:
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_ok(bool(_fc.call("assign_work")), "66 first assign")
	_ok(not bool(_fc.call("assign_dating")), "66 double assign blocked")
	_ok(not bool(_fc.call("assign_work")), "66 second WORK blocked")
	_ok(int(_gs.call("get_total_clones")) == 1, "66 still total1")
	_ok(int(_gs.call("get_clones_working")) == 1, "66 still working1")
	var avail: int = int(_fc.call("get_machine_availability"))
	_ok(avail == int(FirstCloneTypes.MachineAvailability.ALREADY_CREATED), "66 machine unavailable")


func _test_no_late_rates() -> void:
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_fc.call("assign_work")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 20.0), "68 mpm20 via CloneIncremental")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "68 dpm0 after WORK")
	var src: String = FileAccess.get_file_as_string("res://game/first_clone/first_clone.gd")
	_ok(not src.contains("set_late_rates(") and not src.contains("\"set_late_rates\""), "68 no set_late_rates call")


func _test_machine_gates() -> void:
	_reset()
	_world.set("current_location_id", &"laboratory")
	var a0: int = int(_fc.call("get_machine_availability"))
	_ok(a0 == int(FirstCloneTypes.MachineAvailability.OVERLOAD_NOT_RECOGNIZED), "gate overload")
	_gs.call("mark_dating_overload_problem_recognized")
	var a1: int = int(_fc.call("get_machine_availability"))
	_ok(a1 == int(FirstCloneTypes.MachineAvailability.SCIENTIST_NOT_COMPLETED), "gate scientist")
	_gs.call("mark_girl_conquered", &"girl_scientist")
	var a2: int = int(_fc.call("get_machine_availability"))
	_ok(a2 == int(FirstCloneTypes.MachineAvailability.LAB_LOCKED), "gate lab locked at stage")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_world.set("current_location_id", &"apartment")
	var a3: int = int(_fc.call("get_machine_availability"))
	_ok(a3 == int(FirstCloneTypes.MachineAvailability.NOT_IN_LAB), "gate not in lab")
	_world.set("current_location_id", &"laboratory")
	var a4: int = int(_fc.call("get_machine_availability"))
	_ok(a4 == int(FirstCloneTypes.MachineAvailability.AVAILABLE), "gate available")


func _test_representative_reconstruct() -> void:
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_fc.call("assign_work")
	_fc.call("reconstruct_representative")
	var rep: FirstCloneActor = _fc.call("get_representative_actor") as FirstCloneActor
	_ok(rep != null and is_instance_valid(rep), "67 WORK representative")
	var work_marker: Node = find_child(FirstCloneTypes.MARKER_WORK, true, false)
	_ok(work_marker != null and rep.get_parent() == work_marker, "67 at work station")
	_fc.call("reconstruct_representative")
	var rep2: FirstCloneActor = _fc.call("get_representative_actor") as FirstCloneActor
	_ok(rep2 == rep, "67 no duplicate")
	_seed_lab_ready()
	_fc.call("complete_calibration_for_test")
	_fc.call("assign_dating")
	_fc.call("reconstruct_representative")
	var repd: FirstCloneActor = _fc.call("get_representative_actor") as FirstCloneActor
	var date_marker: Node = find_child(FirstCloneTypes.MARKER_DATE, true, false)
	_ok(repd != null and date_marker != null and repd.get_parent() == date_marker, "67 DATING at date station")


func _seed_stage4_overload_started(attention: int = 45, offers: int = 3) -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	_gs.call("add_experience", 4)
	_gs.call("mark_media_photo_session_completed")
	var candidates: Array[StringName] = [
		&"girl_appearance_flash",
		&"girl_public_sculpture",
		&"girl_cafe_receipt_notes",
		&"girl_gym_chalk",
	]
	for i in range(mini(offers, candidates.size())):
		var gid: StringName = candidates[i]
		_gs.call("add_girl_contact", gid)
		_gs.call("add_media_incoming_offer", gid)
	_gs.call("set_media_attention", attention)
	if attention >= 45 and offers >= 3 and _overload.has_method("_ensure_started_from_media"):
		_overload.call("_ensure_started_from_media")


func _make_overload_date_result(girl_id: StringName, delta: int = 0) -> DatingResult:
	var r: DatingResult = DatingResult.new()
	_date_id_seq += 1
	r.date_id = _date_id_seq
	r.girl_id = girl_id
	r.date_delta = delta
	var evs: Array[StringName] = [
		StringName("date_event_m17fix_%s_a" % _date_id_seq),
		StringName("date_event_m17fix_%s_b" % _date_id_seq),
		StringName("date_event_m17fix_%s_c" % _date_id_seq),
	]
	r.central_event_ids = evs
	return r


func _complete_overload_date(girl_id: StringName, delta: int = 0) -> RelationshipDateResult:
	_gs.call("set_girl_date_cooldown_days_remaining", girl_id, 0)
	return _rel.call("apply_date_result", _make_overload_date_result(girl_id, delta)) as RelationshipDateResult


func _drive_live_overload_recognition() -> void:
	# Same production path as dating_overload_self_test: start + advance + personal date.
	_day.call("advance_day")
	_day.call("advance_day")
	if not bool(_overload.call("is_problem_recognized")):
		_complete_overload_date(&"girl_public_sculpture", 0)
	if not bool(_overload.call("is_problem_recognized")):
		_complete_overload_date(&"girl_appearance_flash", 0)


func _test_story_prerequisite() -> void:
	# FIX2 mandatory: STAGE4 + problem=false + rival defeated → STORY_PREREQUISITE via story gate.
	_reset()
	_register_scientist_stub()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	_ok(not bool(_overload.call("is_problem_recognized")), "D problem unrecognized")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_SCIENTIST)
	var disc: Dictionary = _gd.call("discover_girl", StoryIds.GIRL_SCIENTIST) as Dictionary
	_ok(not bool(disc.get("ok", true)), "D discover blocked")
	_ok(disc.get("reason", &"") == &"STORY_PREREQUISITE", "D discover STORY_PREREQUISITE")
	_ok(not bool(_gs.call("is_girl_discovered", StoryIds.GIRL_SCIENTIST)), "D no discovery side effect")
	var begin: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_SCIENTIST) as Dictionary
	_ok(not bool(begin.get("ok", true)), "D begin blocked")
	_ok(begin.get("reason", &"") == &"STORY_PREREQUISITE", "D begin STORY_PREREQUISITE")
	_ok(int(_gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_SCIENTIST)) == 0, "D no cooldown")
	_ok(not bool(_gs.call("has_girl_contact", StoryIds.GIRL_SCIENTIST)), "D no contact")
	_ok(not bool(_gd.call("has_active_attempt")), "D no active attempt")
	# E — recognition then rival gate (STORY_RIVAL_REQUIRED, not prerequisite).
	_reset()
	_register_scientist_stub()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	_gs.call("mark_dating_overload_problem_recognized")
	var begin_e: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_SCIENTIST) as Dictionary
	_ok(not bool(begin_e.get("ok", true)), "E begin blocked")
	_ok(begin_e.get("reason", &"") == &"STORY_RIVAL_REQUIRED", "E STORY_RIVAL_REQUIRED")
	# F — recognized + rival defeated + XP4 → successful attempt start (past story gates).
	_gd.call("clear_content_overrides")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_SCIENTIST)
	if int(_gs.call("get_experience")) < 4:
		_gs.call("add_experience", 4 - int(_gs.call("get_experience")))
	_gd.call("force_clear_attempt")
	var begin_f: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_SCIENTIST) as Dictionary
	var reason_f: StringName = begin_f.get("reason", &"") as StringName
	_ok(reason_f != &"STORY_PREREQUISITE", "F not STORY_PREREQUISITE")
	_ok(reason_f != &"STORY_RIVAL_REQUIRED", "F not STORY_RIVAL_REQUIRED")
	_ok(reason_f != &"STORY_WRONG_STAGE", "F not STORY_WRONG_STAGE")
	_ok(bool(begin_f.get("ok", false)) and reason_f == &"SUCCESS", "F successful attempt start")
	_gd.call("force_clear_attempt")


func _test_scientist_production_wiring() -> void:
	# A — default false anchors still spawn on matching stage.
	_reset()
	var default_anchor: StageActorAnchor = StageActorAnchor.new()
	default_anchor.name = "TestDefaultNeighborAnchor"
	default_anchor.actor_kind = StageActorAnchor.ActorKind.GIRL
	default_anchor.content_id = &"girl_neighbor"
	default_anchor.story_stage = GameTypes.GameStage.PROLOGUE
	_ok(not default_anchor.requires_overload_recognized, "A default requires_overload_recognized false")
	add_child(default_anchor)
	await get_tree().process_frame
	_ok(default_anchor.get_child_count() >= 1, "A default false spawns on matching stage")
	default_anchor.queue_free()
	await get_tree().process_frame
	# B+C — scientist anchors empty before recognition; live spawn via problem_recognized.
	_seed_stage4_overload_started()
	_ok(bool(_overload.call("is_started")), "C overload started")
	var girl_anchor: StageActorAnchor = StageActorAnchor.new()
	girl_anchor.name = "TestScientistGirlAnchor"
	girl_anchor.actor_kind = StageActorAnchor.ActorKind.GIRL
	girl_anchor.content_id = StoryIds.GIRL_SCIENTIST
	girl_anchor.story_stage = GameTypes.GameStage.STAGE_4
	girl_anchor.requires_overload_recognized = true
	var rival_anchor: StageActorAnchor = StageActorAnchor.new()
	rival_anchor.name = "TestScientistRivalAnchor"
	rival_anchor.actor_kind = StageActorAnchor.ActorKind.RIVAL
	rival_anchor.content_id = StoryIds.RIVAL_SCIENTIST
	rival_anchor.story_stage = GameTypes.GameStage.STAGE_4
	rival_anchor.requires_overload_recognized = true
	add_child(girl_anchor)
	add_child(rival_anchor)
	await get_tree().process_frame
	_ok(girl_anchor.get_child_count() == 0, "B scientist girl empty unrecognized")
	_ok(rival_anchor.get_child_count() == 0, "B scientist rival empty unrecognized")
	_drive_live_overload_recognition()
	await get_tree().process_frame
	_ok(bool(_overload.call("is_problem_recognized")), "C problem recognized via DatingOverload path")
	# Critical: no manual _refresh_spawn — only signal-driven spawn.
	_ok(girl_anchor.get_child_count() >= 1, "C girl spawned without manual refresh")
	_ok(rival_anchor.get_child_count() >= 1, "C rival spawned without manual refresh")
	# state_reset clears spawned actors (reset does not emit stage_changed).
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(girl_anchor.get_child_count() == 0, "state_reset clears scientist girl")
	_ok(rival_anchor.get_child_count() == 0, "state_reset clears scientist rival")
	girl_anchor.queue_free()
	rival_anchor.queue_free()


func _test_phone_story_and_clone_section() -> void:
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	_ok(packed != null, "phone scene load")
	if packed == null:
		return
	var phone: PhoneJournal = packed.instantiate() as PhoneJournal
	_ok(phone != null, "phone instantiate")
	if phone == null:
		return
	add_child(phone)
	# §5: recognition before Scientist done → lab hunt.
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	_gs.call("mark_dating_overload_problem_recognized")
	phone.open(null)
	var story_hunt: String = phone.get_story_text()
	_ok(story_hunt.contains("Учёная"), "phone §5 title Учёная")
	_ok(story_hunt.contains("Найти Учёную у закрытой лаборатории."), "phone §5 hunt line")
	_ok(not phone.has_clone_section_visible(), "phone clone hidden before count")
	phone.close()
	# §24: Stage5 before clone → first clone handoff.
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("mark_girl_conquered", &"girl_scientist")
	phone.open(null)
	var story_lab: String = phone.get_story_text()
	_ok(story_lab.contains("Лаборатория открыта."), "phone §24 lab open")
	_ok(story_lab.contains("Создай первого клона."), "phone §24 create clone")
	_ok(not phone.has_clone_section_visible(), "phone clone still hidden")
	phone.close()
	# MODULE 18: after total_clones>=1 → counts + read-only rates.
	_ok(bool(_gs.call("set_clone_counts", 1, 1, 0)), "phone seed WORK counts")
	phone.open(null)
	_ok(phone.has_clone_section_visible(), "phone clone section visible")
	var stats: String = phone.get_clone_stats_text()
	_ok(stats.contains("Всего: 1"), "phone clone total1")
	_ok(stats.contains("Работают: 1"), "phone clone working1")
	_ok(stats.contains("На свиданиях: 0"), "phone clone dating0")
	_ok(stats.contains("Свободно: 0"), "phone clone free0")
	_ok(stats.contains("Денег/мин:"), "phone money rate label")
	_ok(stats.contains("Свиданий/мин:"), "phone dates rate label")
	var story_done: String = phone.get_story_text()
	# MODULE 20 §§57–59 — after first clone Phone switches to President hunt.
	_ok(story_done.contains("Президент"), "phone President title after clone")
	_ok(story_done.contains("Опытность:"), "phone President XP line")
	_ok(story_done.contains("Автоматические свидания расширяют твой земной статус."), "phone President XP hint")
	_ok(not story_done.contains("Автоматизация запущена."), "phone no M18 automation handoff")
	_gs.call("add_experience", 10)
	phone.refresh()
	var story_rival: String = phone.get_story_text()
	_ok(story_rival.contains("Президент инспектирует вход в производственную зону."), "phone §58 rival alive")
	_ok(story_rival.contains("Сначала разберись с её официальным ухажёром."), "phone §58 rival line")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_PRESIDENT)
	phone.refresh()
	var story_meet: String = phone.get_story_text()
	_ok(story_meet.contains("Познакомиться с Президентом у производственной зоны."), "phone §59 meet")
	phone.close()
	phone.queue_free()


func _test_boundaries_overload_cap() -> void:
	_seed_lab_ready()
	var backlog_before: int = int(_overload.call("get_backlog_count"))
	_fc.call("complete_calibration_for_test")
	_fc.call("assign_work")
	_ok(int(_overload.call("get_backlog_count")) == backlog_before, "68 backlog unchanged")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "68 lab unlocked")
	# MODULE 20: President content ships, but first-clone gate + story rival/XP still apply.
	_ok(ResourceLoader.exists("res://data/content/girls/girl_president.tres"), "68 President content present")
	var begin_p: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_PRESIDENT) as Dictionary
	var reason_p: StringName = begin_p.get("reason", &"") as StringName
	_ok(not bool(begin_p.get("ok", true)), "68 President begin blocked")
	_ok(
		reason_p == &"STORY_RIVAL_REQUIRED"
		or reason_p == &"LOCKED_EXPERIENCE"
		or reason_p == &"STORY_PREREQUISITE",
		"68 President not freely available",
	)
	_gd.call("force_clear_attempt")
	_ok(ResourceLoader.exists("res://data/content/girls/girl_final_target.tres"), "68 MODULE21 final target content")
