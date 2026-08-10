class_name FinalDateController
extends Node
## Scene-local MODULE 21 final date sequence owner (not an autoload).


signal phase_changed(phase: FinalDateTypes.Phase)
signal attempt_started()
signal attempt_failed(reason: FinalDateTypes.FailureReason)
signal attempt_succeeded()
signal ending_dismissed()

const FINAL_DATE_UI_SCENE: String = "res://game/final_date/final_date_ui.tscn"

var attempt_active: bool = false
var phase: FinalDateTypes.Phase = FinalDateTypes.Phase.IDLE
var connection_score: int = 0
var used_characteristics: Dictionary = {}
var completed_characteristic_events: int = 0
var rival_1_won: bool = false
var rival_2_won: bool = false
var failure_reason: FinalDateTypes.FailureReason = FinalDateTypes.FailureReason.NONE
var success_applied: bool = false

var _player: Node = null
var _ui: FinalDateUI = null
var _target_actor: CharacterActor = null
var _rival_ceremonial: CharacterActor = null
var _rival_gravity: CharacterActor = null
var _active_checkpoint_id: StringName = &""
var _checkpoints: Dictionary = {}
var _pending_event_index: int = 0
var _awaiting_result_continue: bool = false
var _awaiting_rival_launch: bool = false
var _exhibition_pending: bool = false
var _test_auto_win_exhibition: bool = false
var _location_root: Node = null
var _gate_b_layer: int = 1
var _gate_c_layer: int = 1


func _ready() -> void:
	_location_root = _resolve_location_root()
	_ensure_ui()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
		gs.connect("state_reset", _on_state_reset)


func _exit_tree() -> void:
	if attempt_active:
		_discard_attempt_silent()


func set_test_auto_win_exhibition(enabled: bool) -> void:
	_test_auto_win_exhibition = enabled


func can_start_final_date() -> bool:
	if attempt_active:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if int(gs.call("get_stage")) != int(GameTypes.GameStage.FINALE):
		return false
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.FINAL_DATE)):
		return false
	if int(gs.call("get_world_reach")) < 100:
		return false
	if bool(gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)):
		return false
	var dating: Node = get_node_or_null("/root/DatingCore")
	if dating != null and bool(dating.call("is_date_active")):
		return false
	var runner: Node = get_node_or_null("/root/RivalCompetitionRunner")
	if runner != null and bool(runner.call("is_busy")):
		return false
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		return false
	var girl: GirlDefinition = db.call("get_girl", FinalDateTypes.GIRL_ID) as GirlDefinition
	return girl != null


func start_final_date(player: Node = null) -> bool:
	if not can_start_final_date():
		return false
	_player = player
	if _player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			_player = tree.get_first_node_in_group("player")
	_clear_attempt_state()
	var gs: Node = get_node("/root/GameState")
	gs.call("mark_girl_discovered", FinalDateTypes.GIRL_ID)
	gs.call("add_girl_contact", FinalDateTypes.GIRL_ID)
	attempt_active = true
	_spawn_actors()
	_ensure_checkpoints()
	_set_gates(false, false)
	_set_phase(FinalDateTypes.Phase.INTRO)
	attempt_started.emit()
	_show_intro()
	return true


func is_attempt_active() -> bool:
	return attempt_active


func get_phase() -> FinalDateTypes.Phase:
	return phase


func get_connection_score() -> int:
	return connection_score


func get_used_characteristic_count() -> int:
	return used_characteristics.size()


func did_rival_1_win() -> bool:
	return rival_1_won


func did_rival_2_win() -> bool:
	return rival_2_won


func get_failure_reason() -> FinalDateTypes.FailureReason:
	return failure_reason


func get_ui() -> FinalDateUI:
	return _ui


func get_target_actor() -> CharacterActor:
	return _target_actor


func is_checkpoint_active(checkpoint_id: StringName) -> bool:
	return attempt_active and _active_checkpoint_id == checkpoint_id


func notify_checkpoint(checkpoint_id: StringName) -> void:
	if not attempt_active:
		return
	if checkpoint_id != _active_checkpoint_id:
		return
	_active_checkpoint_id = &""
	match phase:
		FinalDateTypes.Phase.INTRO:
			_begin_event(1)
		FinalDateTypes.Phase.EVENT_1:
			pass
		FinalDateTypes.Phase.RIVAL_1_DANCE:
			_begin_rival_1()
		FinalDateTypes.Phase.EVENT_2:
			_begin_event(2)
		FinalDateTypes.Phase.MOVE_TO_FINAL_TABLE:
			_on_arrived_table_route()
		FinalDateTypes.Phase.RIVAL_2_SLAP:
			_begin_rival_2()
		FinalDateTypes.Phase.EVENT_3:
			_begin_event(3)
		FinalDateTypes.Phase.EVENT_4:
			_begin_event(4)
		_:
			pass


func select_event_option(option_id: StringName) -> bool:
	if not attempt_active or _pending_event_index <= 0:
		return false
	if _ui == null or _ui.get_mode() != "event":
		return false
	var kind: FinalDateTypes.EventOptionKind = _option_id_to_kind(option_id)
	var gs: Node = get_node("/root/GameState")
	if kind != FinalDateTypes.EventOptionKind.NEUTRAL:
		var level: int = int(gs.call("get_characteristic", FinalDateTypes.characteristic_for_kind(kind)))
		if level < FinalDateTypes.CHAR_LEVEL_REQUIRED:
			return false
		connection_score += 1
		used_characteristics[int(kind)] = true
	completed_characteristic_events += 1
	var result: String = FinalDateTypes.event_result_text(_pending_event_index, kind)
	var finished_index: int = _pending_event_index
	_pending_event_index = 0
	if result.strip_edges() != "":
		_awaiting_result_continue = true
		_enter_modal()
		_ui.show_plain("Последняя", result, "Далее")
		_ui.set_meta("after_event_index", finished_index)
	else:
		_close_ui_to_gameplay()
		_after_event(finished_index)
	return true


func retry_full_attempt() -> void:
	if not attempt_active and phase != FinalDateTypes.Phase.FAILURE:
		if can_start_final_date():
			start_final_date(_player)
		return
	_close_ui_to_gameplay()
	_clear_attempt_state()
	attempt_active = true
	_despawn_actors()
	_spawn_actors()
	_ensure_checkpoints()
	_set_gates(false, false)
	_teleport_player_to_start()
	_set_phase(FinalDateTypes.Phase.INTRO)
	attempt_started.emit()
	_show_intro()


func abort_attempt_to_gameplay() -> void:
	_close_ui_to_gameplay()
	_discard_attempt_silent()
	_restore_gameplay()


func dismiss_ending() -> void:
	if phase != FinalDateTypes.Phase.SUCCESS:
		return
	_close_ui_to_gameplay()
	attempt_active = false
	_active_checkpoint_id = &""
	_set_gates(true, true)
	_restore_gameplay()
	ending_dismissed.emit()


func build_event_choices(event_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gs: Node = get_node_or_null("/root/GameState")
	var kinds: Array[FinalDateTypes.EventOptionKind] = [
		FinalDateTypes.EventOptionKind.MUSCLE,
		FinalDateTypes.EventOptionKind.APPEARANCE,
		FinalDateTypes.EventOptionKind.CAPITAL,
		FinalDateTypes.EventOptionKind.AURA,
		FinalDateTypes.EventOptionKind.NEUTRAL,
	]
	for kind in kinds:
		var oid: StringName = _kind_to_option_id(kind)
		var enabled: bool = true
		var reason: String = ""
		if kind != FinalDateTypes.EventOptionKind.NEUTRAL:
			var level: int = 0
			if gs != null:
				level = int(gs.call("get_characteristic", FinalDateTypes.characteristic_for_kind(kind)))
			enabled = level >= FinalDateTypes.CHAR_LEVEL_REQUIRED
			if not enabled:
				reason = "%s %d" % [FinalDateTypes.char_label(kind), FinalDateTypes.CHAR_LEVEL_REQUIRED]
		var label: String = FinalDateTypes.event_option_text(event_index, kind)
		if kind != FinalDateTypes.EventOptionKind.NEUTRAL:
			label = "[%s] %s" % [FinalDateTypes.char_label(kind), label]
		else:
			label = "[Нейтрально] %s" % label
		out.append({"id": oid, "label": label, "enabled": enabled, "reason": reason, "kind": int(kind)})
	return out


func assess_final_score() -> Dictionary:
	var score: int = connection_score
	var variety: bool = used_characteristics.size() >= FinalDateTypes.VARIETY_DISTINCT_REQUIRED
	if variety:
		score += 1
	var passed: bool = (
		score >= FinalDateTypes.PASS_SCORE
		and rival_1_won
		and rival_2_won
	)
	return {
		"score": score,
		"base": connection_score,
		"variety": variety,
		"passed": passed,
	}


func _on_state_reset() -> void:
	_discard_attempt_silent()


func _show_intro() -> void:
	_enter_modal()
	_ui.show_plain(
		"Последняя",
		"Сигнал принят.\n\nПоследняя:\n«Ты дошёл лично. Хорошо. Пройдёмся — и поговорим по делу.»",
		"Далее",
	)


func _begin_event(event_index: int) -> void:
	match event_index:
		1:
			_set_phase(FinalDateTypes.Phase.EVENT_1)
		2:
			_set_phase(FinalDateTypes.Phase.EVENT_2)
		3:
			_set_phase(FinalDateTypes.Phase.EVENT_3)
		4:
			_set_phase(FinalDateTypes.Phase.EVENT_4)
	_pending_event_index = event_index
	_enter_modal()
	_ui.show_event_choices(FinalDateTypes.event_prompt(event_index), build_event_choices(event_index))


func _after_event(event_index: int) -> void:
	match event_index:
		1:
			_set_gates(true, false)
			_move_target_to(FinalDateTypes.MARKER_TARGET_ORBIT)
			_set_phase(FinalDateTypes.Phase.RIVAL_1_DANCE)
			_arm_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1, "Подойти к церемониальному самцу")
		2:
			_set_gates(true, true)
			_move_target_to(FinalDateTypes.MARKER_TARGET_TABLE)
			_set_phase(FinalDateTypes.Phase.MOVE_TO_FINAL_TABLE)
			_arm_checkpoint(FinalDateTypes.CHECKPOINT_MOVE_TABLE, "Идти к финальному столу")
		3:
			_set_phase(FinalDateTypes.Phase.EVENT_4)
			_arm_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_4, "Продолжить разговор")
		4:
			_run_final_assessment()
		_:
			pass


func _on_arrived_table_route() -> void:
	_set_phase(FinalDateTypes.Phase.RIVAL_2_SLAP)
	_arm_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_2, "Подойти к столу")


func _begin_rival_1() -> void:
	_awaiting_rival_launch = true
	_enter_modal()
	_ui.show_plain(
		"Церемониальный внеземной самец",
		"«По местному протоколу право продолжить прогулку подтверждается синхронным движением.»",
		"Начать DANCE",
	)


func _begin_rival_2() -> void:
	_awaiting_rival_launch = true
	_enter_modal()
	_ui.show_plain(
		"Самец гравитационного ранга",
		"«Я оспариваю локальное право занимать эту сторону стола.»",
		"Начать SLAP",
	)


func _launch_pending_rival() -> void:
	if not _awaiting_rival_launch:
		return
	_awaiting_rival_launch = false
	_close_ui_keep_attempt()
	if phase == FinalDateTypes.Phase.RIVAL_1_DANCE:
		_run_exhibition(
			FinalDateTypes.RIVAL_CEREMONIAL_ID,
			GameTypes.CompetitionType.DANCE,
			GameTypes.PlayerCharacteristic.APPEARANCE,
			5,
			_on_rival_1_result,
		)
	elif phase == FinalDateTypes.Phase.RIVAL_2_SLAP:
		_run_exhibition(
			FinalDateTypes.RIVAL_GRAVITY_ID,
			GameTypes.CompetitionType.SLAP,
			GameTypes.PlayerCharacteristic.MUSCLE,
			5,
			_on_rival_2_result,
		)


func _run_exhibition(
	rival_id: StringName,
	competition: GameTypes.CompetitionType,
	player_char: GameTypes.PlayerCharacteristic,
	rival_level: int,
	cb: Callable,
) -> void:
	var runner: Node = get_node_or_null("/root/RivalCompetitionRunner")
	var db: Node = get_node_or_null("/root/ContentDB")
	var gs: Node = get_node_or_null("/root/GameState")
	if runner == null or db == null or gs == null:
		_fail_attempt(FinalDateTypes.FailureReason.RIVAL_LOSS)
		return
	var def: RivalDefinition = db.call("get_rival", rival_id) as RivalDefinition
	if def == null:
		_fail_attempt(FinalDateTypes.FailureReason.RIVAL_LOSS)
		return
	var req := RivalCompetitionRequest.new()
	req.rival_id = rival_id
	req.competition_type = competition
	req.player_level = int(gs.call("get_characteristic", player_char))
	req.rival_level = rival_level
	req.initiator = GameTypes.RivalEncounterInitiator.RIVAL
	req.context = GameTypes.RivalEncounterContext.STORY
	_exhibition_pending = true
	var started: bool = bool(runner.call("run_exhibition_competition", req, def, cb))
	if not started:
		_exhibition_pending = false
		_fail_attempt(FinalDateTypes.FailureReason.RIVAL_LOSS)
		return
	if _test_auto_win_exhibition:
		call_deferred("_force_active_exhibition_win")


func _force_active_exhibition_win() -> void:
	var runner: Node = get_node_or_null("/root/RivalCompetitionRunner")
	if runner == null or not bool(runner.call("is_busy")):
		return
	var mg: CanvasLayer = runner.call("get_active_minigame") as CanvasLayer
	if mg == null or not mg.has_signal("match_finished"):
		return
	var result := RivalCompetitionResult.new()
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	result.debug_score_summary = "final_date_auto_win"
	mg.emit_signal("match_finished", result)


func _on_rival_1_result(result: RivalCompetitionResult) -> void:
	_exhibition_pending = false
	if result != null and result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		rival_1_won = true
		if _rival_ceremonial != null and is_instance_valid(_rival_ceremonial):
			_rival_ceremonial.set_character_visible(false)
		_set_phase(FinalDateTypes.Phase.EVENT_2)
		_arm_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_2, "Продолжить с Последней")
		_restore_gameplay()
	else:
		_fail_attempt(FinalDateTypes.FailureReason.RIVAL_LOSS)


func _on_rival_2_result(result: RivalCompetitionResult) -> void:
	_exhibition_pending = false
	if result != null and result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		rival_2_won = true
		if _rival_gravity != null and is_instance_valid(_rival_gravity):
			_rival_gravity.set_character_visible(false)
		_set_phase(FinalDateTypes.Phase.EVENT_3)
		_arm_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_3, "Сесть за финальный стол")
		_restore_gameplay()
	else:
		_fail_attempt(FinalDateTypes.FailureReason.RIVAL_LOSS)


func _run_final_assessment() -> void:
	_set_phase(FinalDateTypes.Phase.FINAL_ASSESSMENT)
	var assessment: Dictionary = assess_final_score()
	connection_score = int(assessment.get("score", connection_score))
	if bool(assessment.get("passed", false)):
		_apply_success_once()
		_set_phase(FinalDateTypes.Phase.SUCCESS)
		attempt_succeeded.emit()
		_enter_modal()
		_ui.show_success_dialogue()
	else:
		_fail_attempt(FinalDateTypes.FailureReason.CONNECTION)


func _apply_success_once() -> void:
	if success_applied:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if bool(gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)):
		success_applied = true
		return
	gs.call("set_girl_relationship", FinalDateTypes.GIRL_ID, 5)
	gs.call("mark_girl_conquered", FinalDateTypes.GIRL_ID)
	gs.call("add_experience", 1)
	success_applied = true


func _fail_attempt(reason: FinalDateTypes.FailureReason) -> void:
	failure_reason = reason
	_set_phase(FinalDateTypes.Phase.FAILURE)
	attempt_failed.emit(reason)
	_enter_modal()
	if reason == FinalDateTypes.FailureReason.RIVAL_LOSS:
		_ui.show_failure_rival()
	else:
		_ui.show_failure_connection()


func _on_ui_option(option_id: StringName) -> void:
	select_event_option(option_id)


func _on_ui_continue() -> void:
	if _awaiting_rival_launch:
		_launch_pending_rival()
		return
	if _awaiting_result_continue:
		_awaiting_result_continue = false
		var finished_index: int = int(_ui.get_meta("after_event_index", 0))
		_close_ui_to_gameplay()
		_after_event(finished_index)
		return
	if phase == FinalDateTypes.Phase.INTRO:
		_close_ui_to_gameplay()
		_arm_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1, "Подойти к Последней")
		return
	if phase == FinalDateTypes.Phase.SUCCESS and _ui.get_mode() == "success_dialogue":
		_ui.show_ending(_ending_summary())
		return


func _on_ui_retry() -> void:
	retry_full_attempt()


func _on_ui_return() -> void:
	abort_attempt_to_gameplay()


func _on_ui_ending_continue() -> void:
	dismiss_ending()


func _ending_summary() -> String:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return ""
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Покоренных сердец: %d" % int(gs.call("get_experience")))
	lines.append("Авторитет: %d" % int(gs.call("get_authority")))
	lines.append("Клонов: %d" % int(gs.call("get_total_clones")))
	lines.append("Охват Земли: %d" % int(gs.call("get_world_reach")))
	return "\n".join(lines)


func _set_phase(next: FinalDateTypes.Phase) -> void:
	phase = next
	phase_changed.emit(phase)


func _arm_checkpoint(checkpoint_id: StringName, prompt: String) -> void:
	_active_checkpoint_id = checkpoint_id
	var cp: FinalCheckpointInteractable = _checkpoints.get(checkpoint_id, null) as FinalCheckpointInteractable
	if cp != null:
		cp.prompt_action = prompt
		cp.visible = true


func _ensure_ui() -> void:
	if _ui != null and is_instance_valid(_ui):
		return
	var packed: PackedScene = load(FINAL_DATE_UI_SCENE) as PackedScene
	if packed == null:
		push_error("[FinalDate] UI scene missing")
		return
	_ui = packed.instantiate() as FinalDateUI
	if _ui == null:
		push_error("[FinalDate] UI scene type mismatch")
		return
	_ui.name = "FinalDateUI"
	add_child(_ui)
	if not _ui.option_selected.is_connected(_on_ui_option):
		_ui.option_selected.connect(_on_ui_option)
	if not _ui.continue_pressed.is_connected(_on_ui_continue):
		_ui.continue_pressed.connect(_on_ui_continue)
	if not _ui.retry_pressed.is_connected(_on_ui_retry):
		_ui.retry_pressed.connect(_on_ui_retry)
	if not _ui.return_pressed.is_connected(_on_ui_return):
		_ui.return_pressed.connect(_on_ui_return)
	if not _ui.ending_continue_pressed.is_connected(_on_ui_ending_continue):
		_ui.ending_continue_pressed.connect(_on_ui_ending_continue)


func _ensure_checkpoints() -> void:
	if not _checkpoints.is_empty():
		return
	var map: Dictionary = {
		FinalDateTypes.CHECKPOINT_EVENT_1: FinalDateTypes.MARKER_EVENT_1,
		FinalDateTypes.CHECKPOINT_RIVAL_1: FinalDateTypes.MARKER_RIVAL_1,
		FinalDateTypes.CHECKPOINT_EVENT_2: FinalDateTypes.MARKER_EVENT_2,
		FinalDateTypes.CHECKPOINT_MOVE_TABLE: FinalDateTypes.MARKER_WALK_C,
		FinalDateTypes.CHECKPOINT_RIVAL_2: FinalDateTypes.MARKER_RIVAL_2,
		FinalDateTypes.CHECKPOINT_EVENT_3: FinalDateTypes.MARKER_EVENT_3,
		FinalDateTypes.CHECKPOINT_EVENT_4: FinalDateTypes.MARKER_EVENT_4,
	}
	for cid in map.keys():
		var marker_name: StringName = map[cid] as StringName
		var marker: Node3D = _find_marker(marker_name)
		var cp := FinalCheckpointInteractable.new()
		cp.name = "FinalCheckpoint_%s" % String(cid)
		var host: Node = _location_root if _location_root != null else self
		host.add_child(cp)
		if marker != null:
			cp.global_position = marker.global_position
		cp.setup(self, cid as StringName, "Продолжить")
		cp.visible = false
		_checkpoints[cid] = cp


func _spawn_actors() -> void:
	_despawn_actors()
	var host: Node = _location_root if _location_root != null else self
	_target_actor = CharacterFactory.create(
		FinalDateTypes.APPEARANCE_PROFILE_ID,
		FinalDateTypes.GIRL_ID,
		host,
	)
	if _target_actor != null:
		_target_actor.display_name = "Последняя"
		_place_actor(_target_actor, FinalDateTypes.MARKER_TARGET_SIGNAL)
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		return
	var ceremonial: RivalDefinition = db.call("get_rival", FinalDateTypes.RIVAL_CEREMONIAL_ID) as RivalDefinition
	if ceremonial != null:
		_rival_ceremonial = CharacterFactory.create(
			ceremonial.appearance_profile_id,
			FinalDateTypes.RIVAL_CEREMONIAL_ID,
			host,
		)
		if _rival_ceremonial != null:
			_rival_ceremonial.display_name = ceremonial.display_name
			_place_actor(_rival_ceremonial, FinalDateTypes.MARKER_RIVAL_CEREMONIAL)
	var gravity: RivalDefinition = db.call("get_rival", FinalDateTypes.RIVAL_GRAVITY_ID) as RivalDefinition
	if gravity != null:
		_rival_gravity = CharacterFactory.create(
			gravity.appearance_profile_id,
			FinalDateTypes.RIVAL_GRAVITY_ID,
			host,
		)
		if _rival_gravity != null:
			_rival_gravity.display_name = gravity.display_name
			_place_actor(_rival_gravity, FinalDateTypes.MARKER_RIVAL_GRAVITY)


func _despawn_actors() -> void:
	if _target_actor != null and is_instance_valid(_target_actor):
		_target_actor.queue_free()
	_target_actor = null
	if _rival_ceremonial != null and is_instance_valid(_rival_ceremonial):
		_rival_ceremonial.queue_free()
	_rival_ceremonial = null
	if _rival_gravity != null and is_instance_valid(_rival_gravity):
		_rival_gravity.queue_free()
	_rival_gravity = null


func _place_actor(actor: CharacterActor, marker_name: StringName) -> void:
	var marker: Node3D = _find_marker(marker_name)
	if marker == null or actor == null:
		return
	actor.global_position = marker.global_position
	actor.set_character_visible(true)


func _move_target_to(marker_name: StringName) -> void:
	if _target_actor == null or not is_instance_valid(_target_actor):
		return
	_place_actor(_target_actor, marker_name)


func _set_gates(zone_b_open: bool, zone_c_open: bool) -> void:
	var gate_b: Node = _find_named(FinalDateTypes.GATE_ZONE_B)
	var gate_c: Node = _find_named(FinalDateTypes.GATE_ZONE_C)
	_apply_gate(gate_b, zone_b_open, true)
	_apply_gate(gate_c, zone_c_open, false)


func _apply_gate(gate: Node, open: bool, is_b: bool) -> void:
	if gate == null:
		return
	if gate is CollisionObject3D:
		var body: CollisionObject3D = gate as CollisionObject3D
		if open:
			if is_b:
				_gate_b_layer = body.collision_layer if body.collision_layer != 0 else _gate_b_layer
			else:
				_gate_c_layer = body.collision_layer if body.collision_layer != 0 else _gate_c_layer
			body.collision_layer = 0
		else:
			body.collision_layer = _gate_b_layer if is_b else _gate_c_layer
	gate.visible = not open


func _teleport_player_to_start() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var marker: Node3D = _find_marker(FinalDateTypes.MARKER_ATTEMPT_START)
	if marker == null:
		return
	if _player is Node3D:
		(_player as Node3D).global_position = marker.global_position


func _enter_modal() -> void:
	_ensure_ui()
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func _restore_gameplay() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")


func _close_ui_to_gameplay() -> void:
	if _ui != null:
		_ui.hide_ui()
	_restore_gameplay()


func _close_ui_keep_attempt() -> void:
	if _ui != null:
		_ui.hide_ui()


func _clear_attempt_state() -> void:
	connection_score = 0
	used_characteristics.clear()
	completed_characteristic_events = 0
	rival_1_won = false
	rival_2_won = false
	failure_reason = FinalDateTypes.FailureReason.NONE
	_pending_event_index = 0
	_awaiting_result_continue = false
	_awaiting_rival_launch = false
	_exhibition_pending = false
	_active_checkpoint_id = &""
	phase = FinalDateTypes.Phase.IDLE


func _discard_attempt_silent() -> void:
	attempt_active = false
	_clear_attempt_state()
	if _ui != null and is_instance_valid(_ui):
		_ui.hide_ui()
	_despawn_actors()
	for key in _checkpoints.keys():
		var cp: Node = _checkpoints[key] as Node
		if cp != null and is_instance_valid(cp):
			cp.queue_free()
	_checkpoints.clear()
	_set_gates(false, false)


func _resolve_location_root() -> Node:
	var n: Node = self
	while n != null:
		if n is WorldLocation or String(n.name) == "final_location":
			return n
		n = n.get_parent()
	var tree: SceneTree = get_tree()
	if tree != null:
		return tree.current_scene
	return self


func _find_marker(marker_name: StringName) -> Node3D:
	var n: Node = _find_named(marker_name)
	return n as Node3D


func _find_named(node_name: StringName) -> Node:
	var host: Node = _location_root if _location_root != null else self
	if host == null:
		return null
	var found: Node = host.find_child(String(node_name), true, false)
	if found != null:
		return found
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene.find_child(String(node_name), true, false)
	return null


func _kind_to_option_id(kind: FinalDateTypes.EventOptionKind) -> StringName:
	match kind:
		FinalDateTypes.EventOptionKind.MUSCLE:
			return &"muscle"
		FinalDateTypes.EventOptionKind.APPEARANCE:
			return &"appearance"
		FinalDateTypes.EventOptionKind.CAPITAL:
			return &"capital"
		FinalDateTypes.EventOptionKind.AURA:
			return &"aura"
		_:
			return &"neutral"


func _option_id_to_kind(option_id: StringName) -> FinalDateTypes.EventOptionKind:
	match String(option_id):
		"muscle":
			return FinalDateTypes.EventOptionKind.MUSCLE
		"appearance":
			return FinalDateTypes.EventOptionKind.APPEARANCE
		"capital":
			return FinalDateTypes.EventOptionKind.CAPITAL
		"aura":
			return FinalDateTypes.EventOptionKind.AURA
		_:
			return FinalDateTypes.EventOptionKind.NEUTRAL
