extends Node
## Reproducible MODULE 11 Story / Stage Framework tests (spec §§44–62).
## Run: res://game/story/test/story_test.tscn --quit-after 15000

const _GirlDiscoveryScript = preload("res://game/girls/girl_discovery.gd")


var _failed: int = 0
var _passed: int = 0
var _story: Node = null
var _gs: Node = null
var _gd: Node = null
var _rel: Node = null
var _re: Node = null
var _db: Node = null

var _completed_stages: Array[int] = []
var _started_stages: Array[int] = []
var _objective_count: int = 0
var _features_unlocked: Array[int] = []
var _signal_order: Array[String] = []


func _ready() -> void:
	_story = get_node("/root/Story")
	_gs = get_node("/root/GameState")
	_gd = get_node("/root/GirlDiscovery")
	_rel = get_node("/root/Relationships")
	_re = get_node("/root/RivalEncounters")
	_db = get_node("/root/ContentDB")
	await get_tree().process_frame
	_connect_signals()
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_11_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_11_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_11_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_11_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_11_TEST] FAIL: %s" % label)
		print("MODULE_11_TEST FAIL: %s" % label)


func _connect_signals() -> void:
	if _story.has_signal("stage_completed") and not _story.is_connected("stage_completed", _on_stage_completed):
		_story.connect("stage_completed", _on_stage_completed)
	if _story.has_signal("stage_started") and not _story.is_connected("stage_started", _on_stage_started):
		_story.connect("stage_started", _on_stage_started)
	if _story.has_signal("stage_objective_changed") and not _story.is_connected("stage_objective_changed", _on_objective):
		_story.connect("stage_objective_changed", _on_objective)
	if _story.has_signal("feature_unlocked") and not _story.is_connected("feature_unlocked", _on_feature):
		_story.connect("feature_unlocked", _on_feature)
	if _gs.has_signal("stage_changed") and not _gs.is_connected("stage_changed", _on_gs_stage):
		_gs.connect("stage_changed", _on_gs_stage)


func _on_stage_completed(stage: GameTypes.GameStage) -> void:
	_completed_stages.append(int(stage))
	_signal_order.append("stage_completed")


func _on_stage_started(stage: GameTypes.GameStage) -> void:
	_started_stages.append(int(stage))
	_signal_order.append("stage_started")


func _on_objective(_progress: StoryStageProgress) -> void:
	_objective_count += 1
	_signal_order.append("objective")


func _on_feature(feature: StoryTypes.StoryFeature) -> void:
	_features_unlocked.append(int(feature))


func _on_gs_stage(_new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	_signal_order.append("stage_changed")


func _reset_trackers() -> void:
	_completed_stages.clear()
	_started_stages.clear()
	_objective_count = 0
	_features_unlocked.clear()
	_signal_order.clear()


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_gd.call("force_clear_attempt")
	_gd.call("clear_content_overrides")
	_reset_trackers()


func _stage() -> int:
	return int(_gs.call("get_stage"))


func _feat(f: StoryTypes.StoryFeature) -> bool:
	return bool(_story.call("is_feature_unlocked", f))


func _girl_gate(gid: StringName) -> int:
	return int(_story.call("get_story_girl_gate", gid))


func _rival_gate(rid: StringName) -> int:
	return int(_story.call("get_story_rival_gate", rid))


func _emit_girl_completed(girl_id: StringName) -> void:
	_gs.call("mark_girl_conquered", girl_id)
	var result: RelationshipDateResult = RelationshipDateResult.new()
	result.ok = true
	result.girl_id = girl_id
	result.newly_conquered = true
	_rel.emit_signal("girl_completed", girl_id, result)


func _emit_rival_won(rival_id: StringName) -> void:
	_gs.call("mark_rival_defeated", rival_id)
	var result: RivalEncounterResult = RivalEncounterResult.new()
	result.rival_id = rival_id
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	_re.emit_signal("encounter_won", result)


func _register_story_girl_fixture(girl_id: StringName, required_xp: int = 0) -> void:
	var sit: DiscoverySituationDefinition = DiscoverySituationDefinition.new()
	sit.id = &"story_test_situation"
	sit.setup_text = "test"
	var approach: DiscoveryApproachDefinition = DiscoveryApproachDefinition.new()
	approach.id = &"story_test_approach"
	approach.label = "Talk"
	approach.outcome = DiscoveryApproachDefinition.DiscoveryApproachOutcome.SUCCESS
	approach.result_text = "ok"
	var approaches: Array[DiscoveryApproachDefinition] = [approach]
	sit.approaches = approaches
	_gd.call("register_discovery_situation", sit)
	var girl: GirlDefinition = GirlDefinition.new()
	girl.id = girl_id
	girl.display_name = "Story Test"
	girl.required_experience = required_xp
	girl.discovery_situation_id = sit.id
	var clues: Array[String] = ["c0", "c1"]
	girl.clue_notes = clues
	_gd.call("register_girl_definition", girl)


func _run_all() -> void:
	_test_reset()
	_test_catalog_exactness()
	_test_neighbor_completion()
	_test_stage1_mapping()
	_test_actress_gated()
	_test_rival_win_alone()
	_test_actress_completion()
	_test_girl_before_rival()
	_test_ordinary_ignored()
	_test_wrong_story_ids()
	_test_one_event_one_stage()
	_test_feature_unlock_sequence()
	_test_cumulative_features()
	_test_stage6_milestone()
	_test_finale_no_auto()
	_test_restore_features()
	_test_auth_xp_not_stage()
	_test_normal_gates_preserved()
	_test_no_mutation_leakage()
	_test_signal_order()
	_test_real_signal_integration()
	_reset()


func _test_reset() -> void:
	_reset()
	_ok(_stage() == int(GameTypes.GameStage.PROLOGUE), "44 stage PROLOGUE")
	_ok(not _feat(StoryTypes.StoryFeature.SOCIAL_ACCESS), "44 SOCIAL false")
	var prog: StoryStageProgress = _story.call("get_current_progress") as StoryStageProgress
	_ok(prog != null and String(prog.story_girl_id) == "", "44 no romantic prologue girl")
	_ok(prog != null and prog.objective_id == &"pick_up_card", "44 card objective")
	_ok(prog != null and prog.rival_required == false, "44 rival not required")


func _test_catalog_exactness() -> void:
	_reset()
	var stages: Array = _db.call("list_stages") as Array
	_ok(stages.size() == 8, "62 exactly 8 stages")
	var v: Dictionary = _db.call("validate_all") as Dictionary
	_ok(bool(v.get("ok", false)), "62 ContentDB validate_all ok")
	var s0: StoryStageDefinition = _db.call("get_stage", GameTypes.GameStage.PROLOGUE) as StoryStageDefinition
	_ok(
		s0 != null
		and s0.completion_mode == StoryTypes.StageCompletionMode.EXTERNAL_MILESTONE
		and s0.completion_flag_id == StoryIds.FLAG_TUTORIAL_DATE_COMPLETE,
		"62 prologue tutorial milestone",
	)
	var s1: StoryStageDefinition = _db.call("get_stage", GameTypes.GameStage.STAGE_1) as StoryStageDefinition
	_ok(s1 != null and s1.requires_story_rival and s1.story_rival_id == StoryIds.RIVAL_ACTRESS, "62 stage1 rival")
	var s6: StoryStageDefinition = _db.call("get_stage", GameTypes.GameStage.STAGE_6) as StoryStageDefinition
	_ok(
		s6 != null
		and s6.completion_mode == StoryTypes.StageCompletionMode.EXTERNAL_MILESTONE
		and String(s6.story_girl_id) == ""
		and String(s6.story_rival_id) == "",
		"62 stage6 external",
	)
	var fin: StoryStageDefinition = _db.call("get_stage", GameTypes.GameStage.FINALE) as StoryStageDefinition
	_ok(
		fin != null
		and fin.story_girl_id == StoryIds.GIRL_FINAL_TARGET
		and fin.completion_mode == StoryTypes.StageCompletionMode.NONE
		and fin.next_stage == GameTypes.GameStage.FINALE,
		"62 finale NONE",
	)


func _test_neighbor_completion() -> void:
	_reset()
	_reset_trackers()
	_gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "45 tutorial milestone advances")
	_ok(not bool(_gs.call("is_girl_conquered", StoryIds.GIRL_NEIGHBOR)), "45 Neighbor not conquered")
	_ok(_feat(StoryTypes.StoryFeature.SOCIAL_ACCESS), "45 SOCIAL true")
	_ok(not _feat(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS), "45 no PUBLIC yet")
	_ok(_features_unlocked.has(int(StoryTypes.StoryFeature.SOCIAL_ACCESS)), "45 feature signal")


func _test_stage1_mapping() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	var prog: StoryStageProgress = _story.call("get_current_progress") as StoryStageProgress
	_ok(prog.story_girl_id == StoryIds.GIRL_ACTRESS, "46 girl actress")
	_ok(prog.story_rival_id == StoryIds.RIVAL_ACTRESS, "46 rival actress")
	_ok(prog.rival_required, "46 rival required")


func _test_actress_gated() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_ok(
		_girl_gate(StoryIds.GIRL_ACTRESS) == int(StoryTypes.StoryGirlGate.RIVAL_REQUIRED),
		"47 gate RIVAL_REQUIRED",
	)
	_register_story_girl_fixture(StoryIds.GIRL_ACTRESS, 0)
	_gs.call("mark_girl_discovered", StoryIds.GIRL_ACTRESS)
	var clues_before: Array = _gs.call("get_known_girl_clue_indices", StoryIds.GIRL_ACTRESS) as Array
	var cd_before: int = int(_gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_ACTRESS))
	var begin: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_ACTRESS) as Dictionary
	_ok(not bool(begin.get("ok", true)), "47 begin blocked")
	_ok(begin.get("reason", &"") == _GirlDiscoveryScript.RESULT_STORY_RIVAL_REQUIRED, "47 STORY_RIVAL_REQUIRED")
	_ok(begin.get("reason", &"") != _GirlDiscoveryScript.RESULT_FAILURE, "47 not FAILURE")
	var clues_after: Array = _gs.call("get_known_girl_clue_indices", StoryIds.GIRL_ACTRESS) as Array
	_ok(clues_after.size() == clues_before.size(), "47 no clue increment")
	_ok(int(_gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_ACTRESS)) == cd_before, "47 no cooldown")


func _test_rival_win_alone() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_emit_rival_won(StoryIds.RIVAL_ACTRESS)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "48 stage remains STAGE_1")
	_ok(
		_girl_gate(StoryIds.GIRL_ACTRESS) == int(StoryTypes.StoryGirlGate.AVAILABLE),
		"48 girl AVAILABLE",
	)


func _test_actress_completion() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_ACTRESS)
	_ok(bool(_story.call("reconcile_current_stage")), "49 actress advances")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_2), "49 STAGE_2")
	_ok(_feat(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS), "49 PUBLIC true")


func _test_girl_before_rival() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_ACTRESS)
	_ok(not bool(_story.call("reconcile_current_stage")), "50 no advance without rival")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "50 still STAGE_1")
	_emit_rival_won(StoryIds.RIVAL_ACTRESS)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_2), "50 rival event advances")


func _test_ordinary_ignored() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_emit_rival_won(&"rival_test_ordinary")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "51 ordinary rival ignored")
	_emit_girl_completed(&"girl_test_ordinary")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "51 ordinary girl ignored")


func _test_wrong_story_ids() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_ok(
		_girl_gate(StoryIds.GIRL_PRESIDENT) == int(StoryTypes.StoryGirlGate.WRONG_STAGE),
		"52 girl_president WRONG_STAGE",
	)
	_ok(
		_rival_gate(StoryIds.RIVAL_PRESIDENT) == int(StoryTypes.StoryRivalGate.WRONG_STAGE),
		"52 rival_president WRONG_STAGE",
	)


func _test_one_event_one_stage() -> void:
	_reset()
	_gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "53 tutorial gives only STAGE_1")
	_gs.call("mark_girl_conquered", StoryIds.GIRL_ACTRESS)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_ok(bool(_story.call("reconcile_current_stage")), "53 later reconcile")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_2), "53 then STAGE_2")


func _test_feature_unlock_sequence() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_2)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MINE_BOSS)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MINE_BOSS)
	_story.call("reconcile_current_stage")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_3), "54 mine -> STAGE_3")
	_ok(_feat(StoryTypes.StoryFeature.SALARY_MINE), "54 SALARY_MINE")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MAGAZINE_EDITOR)
	_story.call("reconcile_current_stage")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_4) and _feat(StoryTypes.StoryFeature.MEDIA_ATTENTION), "54 MEDIA")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_SCIENTIST)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_SCIENTIST)
	_story.call("reconcile_current_stage")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_5) and _feat(StoryTypes.StoryFeature.LABORATORY), "54 LAB")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_PRESIDENT)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_PRESIDENT)
	_story.call("reconcile_current_stage")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_6) and _feat(StoryTypes.StoryFeature.WORLD_EXPANSION), "54 WORLD")


func _test_cumulative_features() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	_ok(_feat(StoryTypes.StoryFeature.SOCIAL_ACCESS), "55 SOCIAL")
	_ok(_feat(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS), "55 PUBLIC")
	_ok(_feat(StoryTypes.StoryFeature.SALARY_MINE), "55 SALARY")
	_ok(_feat(StoryTypes.StoryFeature.MEDIA_ATTENTION), "55 MEDIA")
	_ok(_feat(StoryTypes.StoryFeature.LABORATORY), "55 LAB")
	_ok(_feat(StoryTypes.StoryFeature.WORLD_EXPANSION), "55 WORLD")
	_ok(not _feat(StoryTypes.StoryFeature.FINAL_DATE), "55 FINAL false")


func _test_stage6_milestone() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	_ok(not bool(_story.call("reconcile_current_stage")), "56 entering STAGE_6 alone no advance")
	_ok(_stage() == int(GameTypes.GameStage.STAGE_6), "56 still STAGE_6")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_ok(not bool(_story.call("complete_world_expansion")), "56 wrong stage reject")
	_ok(not bool(_gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)), "56 flag not set")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	_ok(bool(_story.call("complete_world_expansion")), "56 first complete ok")
	_ok(bool(_gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)), "56 flag true")
	_ok(_stage() == int(GameTypes.GameStage.FINALE), "56 FINALE")
	_ok(_feat(StoryTypes.StoryFeature.FINAL_DATE), "56 FINAL_DATE")
	_ok(not bool(_story.call("complete_world_expansion")), "56 duplicate no advance")
	_ok(_stage() == int(GameTypes.GameStage.FINALE), "56 still FINALE")


func _test_finale_no_auto() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.FINALE)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_FINAL_TARGET)
	_ok(not bool(_story.call("reconcile_current_stage")), "57 finale no advance")
	_ok(_stage() == int(GameTypes.GameStage.FINALE), "57 remains FINALE")


func _test_restore_features() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_ok(_feat(StoryTypes.StoryFeature.LABORATORY), "58 LAB true")
	_ok(not _feat(StoryTypes.StoryFeature.WORLD_EXPANSION), "58 WORLD false")


func _test_auth_xp_not_stage() -> void:
	_reset()
	_gs.call("add_authority", 999)
	_gs.call("add_experience", 999)
	_ok(_stage() == int(GameTypes.GameStage.PROLOGUE), "59 still PROLOGUE")


func _test_normal_gates_preserved() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_ok(_girl_gate(StoryIds.GIRL_ACTRESS) == int(StoryTypes.StoryGirlGate.AVAILABLE), "60 story AVAILABLE")
	_register_story_girl_fixture(StoryIds.GIRL_ACTRESS, 5)
	_gs.call("mark_girl_discovered", StoryIds.GIRL_ACTRESS)
	var begin: Dictionary = _gd.call("begin_attempt", StoryIds.GIRL_ACTRESS) as Dictionary
	_ok(not bool(begin.get("ok", true)), "60 exp still gates")
	_ok(begin.get("reason", &"") == _GirlDiscoveryScript.RESULT_LOCKED_EXPERIENCE, "60 LOCKED_EXPERIENCE")
	_ok(
		_rival_gate(StoryIds.RIVAL_ACTRESS) == int(StoryTypes.StoryRivalGate.ALREADY_DEFEATED),
		"60 rival ALREADY_DEFEATED",
	)


func _test_no_mutation_leakage() -> void:
	var src: String = FileAccess.get_file_as_string("res://game/story/story.gd")
	_ok(not src.contains("add_girl_relationship"), "61 no add_girl_relationship")
	_ok(not src.contains("set_girl_relationship"), "61 no set_girl_relationship")
	_ok(not src.contains("mark_rival_defeated"), "61 no mark_rival_defeated")
	_ok(not src.contains("add_experience"), "61 no add_experience")
	_ok(not src.contains("add_authority"), "61 no add_authority")
	_ok(not src.contains("unlock_location"), "61 no unlock_location")
	_ok(not src.contains("func _process"), "61 no _process")
	var re_src: String = FileAccess.get_file_as_string("res://game/rivals/rival_encounters.gd")
	_ok(not re_src.contains("get_story_rival_gate"), "61 RivalEncounters no Story gate")
	_ok(not re_src.contains("/root/Story"), "61 RivalEncounters no Story node")


func _test_signal_order() -> void:
	_reset()
	_reset_trackers()
	_gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	var idx_completed: int = _signal_order.find("stage_completed")
	var idx_changed: int = _signal_order.find("stage_changed")
	var idx_started: int = _signal_order.find("stage_started")
	var idx_obj: int = _signal_order.find("objective")
	_ok(idx_completed >= 0 and idx_changed > idx_completed, "14 completed before changed")
	_ok(idx_started > idx_changed, "14 started after changed")
	_ok(idx_obj > idx_started, "14 objective after started")


func _test_real_signal_integration() -> void:
	_reset()
	_reset_trackers()
	_emit_girl_completed(StoryIds.GIRL_NEIGHBOR)
	_ok(_stage() == int(GameTypes.GameStage.PROLOGUE), "43 Neighbor heart cannot advance")
	_gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "43 tutorial flag advances")
	_emit_rival_won(StoryIds.RIVAL_ACTRESS)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_1), "43 rival alone no advance")
	_emit_girl_completed(StoryIds.GIRL_ACTRESS)
	_ok(_stage() == int(GameTypes.GameStage.STAGE_2), "43 actress completion via signal")
