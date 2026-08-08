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


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_fc = get_node("/root/FirstClone")
	_gd = get_node("/root/GirlDiscovery")
	_world = get_node("/root/World")
	_overload = get_node("/root/DatingOverload")
	_story = get_node("/root/Story")
	await get_tree().process_frame
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
	await _test_stage_anchor_overload_flag()
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
	_ok(not anchor_src.contains("func _process"), "StageActorAnchor no _process")


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
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "66 WORK mpm0")
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
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "66 DATING dpm0")


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
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "68 mpm0 after clone")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "68 dpm0 after clone")
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


func _test_story_prerequisite() -> void:
	_reset()
	_register_scientist_stub()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	var disc: Dictionary = _gd.call("discover_girl", &"girl_scientist") as Dictionary
	_ok(not bool(disc.get("ok", true)), "10 discover blocked")
	_ok(disc.get("reason", &"") == &"STORY_PREREQUISITE", "10 STORY_PREREQUISITE")
	_ok(not bool(_gs.call("is_girl_discovered", &"girl_scientist")), "10 no discovery side effect")
	var begin: Dictionary = _gd.call("begin_attempt", &"girl_scientist") as Dictionary
	_ok(not bool(begin.get("ok", true)), "10 begin blocked")
	_ok(begin.get("reason", &"") == &"STORY_PREREQUISITE", "10 begin STORY_PREREQUISITE")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_scientist")) == 0, "10 no cooldown")
	_gs.call("mark_dating_overload_problem_recognized")
	var disc2: Dictionary = _gd.call("discover_girl", &"girl_scientist") as Dictionary
	_ok(bool(disc2.get("ok", false)), "10 discover after recognition")


func _test_stage_anchor_overload_flag() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	var anchor: StageActorAnchor = StageActorAnchor.new()
	anchor.name = "TestScientistAnchor"
	anchor.actor_kind = StageActorAnchor.ActorKind.GIRL
	anchor.content_id = &"girl_neighbor"
	anchor.story_stage = GameTypes.GameStage.STAGE_4
	anchor.requires_overload_recognized = true
	add_child(anchor)
	await get_tree().process_frame
	_ok(anchor.get_child_count() == 0, "anchor hidden before recognition")
	_gs.call("mark_dating_overload_problem_recognized")
	# Emit if DatingOverload tracks recognition already set without signal.
	if _overload.has_signal("problem_recognized"):
		# Force refresh if signal already consumed.
		anchor.call("_refresh_spawn")
	await get_tree().process_frame
	_ok(anchor.get_child_count() >= 1, "anchor spawns after recognition")
	anchor.queue_free()


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
	# §52: after total_clones>=1 → counts visible, no rates.
	_ok(bool(_gs.call("set_clone_counts", 1, 1, 0)), "phone seed WORK counts")
	phone.open(null)
	_ok(phone.has_clone_section_visible(), "phone clone section visible")
	var stats: String = phone.get_clone_stats_text()
	_ok(stats.contains("Всего: 1"), "phone clone total1")
	_ok(stats.contains("На работе: 1"), "phone clone working1")
	_ok(stats.contains("На свиданиях: 0"), "phone clone dating0")
	_ok(stats.contains("Свободных: 0"), "phone clone free0")
	_ok(not stats.contains("мин"), "phone no rate emphasis")
	var story_done: String = phone.get_story_text()
	_ok(story_done.contains("Первый клон создан."), "phone story after clone")
	_ok(not story_done.contains("Президент"), "phone no President objective")
	phone.close()
	phone.queue_free()


func _test_boundaries_overload_cap() -> void:
	_seed_lab_ready()
	var backlog_before: int = int(_overload.call("get_backlog_count"))
	_fc.call("complete_calibration_for_test")
	_fc.call("assign_work")
	_ok(int(_overload.call("get_backlog_count")) == backlog_before, "68 backlog unchanged")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "68 lab unlocked")
	_ok(not ResourceLoader.exists("res://data/content/girls/girl_president.tres"), "68 President absent")
