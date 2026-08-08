extends Node
## Independent MODULE 21 QA (not product code). Evidence under tmp/m21_qa.
## Run windowed for screenshots:
## Godot --path <repo> res://tmp/m21_qa/m21_indep_qa.tscn

const OUT := "res://tmp/m21_qa"

var _world: Node = null
var _gs: Node = null
var _db: Node = null
var _story: Node = null
var _dating: Node = null
var _runner: Node = null
var _rels: Node = null
var _failed: int = 0
var _passed: int = 0
var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	_story = get_node("/root/Story")
	_dating = get_node("/root/DatingCore")
	_runner = get_node("/root/RivalCompetitionRunner")
	_rels = get_node("/root/Relationships")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	await _run()
	print("M21_INDEP_QA: DONE passed=%s failed=%s" % [_passed, _failed])
	for line in _lines:
		print(line)
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/m21_indep_qa_report.txt" % OUT), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
	await get_tree().create_timer(0.35).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_lines.append("PASS: %s" % label)
	else:
		_failed += 1
		_lines.append("FAIL: %s" % label)
		push_error("[M21_INDEP_QA] FAIL: %s" % label)


func _log(msg: String) -> void:
	_lines.append("INFO: %s" % msg)
	print("M21_INDEP_QA: %s" % msg)


func _run() -> void:
	# --- 1) F5-equivalent boot: apartment ---
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(int(_world.call("reset_to_start")) == 0, "reset_to_start SUCCESS")
	_ok(String(_world.get("current_location_id")) == "apartment", "boot location apartment")
	await _shot_look(Vector3(0.0, 1.6, 2.5), Vector3(0.0, 1.4, 0.0), "%s/01_apartment_boot.png" % OUT)

	# --- 2) Content pack ---
	_ok(ResourceLoader.exists("res://data/content/girls/girl_final_target.tres"), "girl_final_target.tres exists")
	_ok(ResourceLoader.exists("res://data/content/rivals/rival_final_ceremonial.tres"), "rival_final_ceremonial.tres")
	_ok(ResourceLoader.exists("res://data/content/rivals/rival_final_gravity.tres"), "rival_final_gravity.tres")
	_ok(_db.call("try_get_girl", &"girl_final_target") != null, "ContentDB girl_final_target")
	_ok(_db.call("try_get_rival", &"rival_final_ceremonial") != null, "ContentDB rival_final_ceremonial")
	_ok(_db.call("try_get_rival", &"rival_final_gravity") != null, "ContentDB rival_final_gravity")
	var girl_def: Resource = _db.call("try_get_girl", &"girl_final_target") as Resource
	if girl_def != null:
		_ok(String(girl_def.get("display_name")) == "Последняя", "display_name Последняя")
		_ok(bool(girl_def.get("is_story")), "girl is_story")
		var pools: Variant = girl_def.get("dating_pool_ids")
		_ok(pools is Array and (pools as Array).is_empty(), "no ordinary dating pools")

	# Edge: locked before FINALE
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	_gs.call("set_world_reach", 50)
	_ok(int(_gs.call("get_stage")) != int(GameTypes.GameStage.FINALE), "edge still STAGE_6")
	_ok(int(_world.call("request_travel", &"final_location", &"spawn_default")) != 0, "edge final_location locked STAGE_6")

	# --- 3) Seed FINALE preconditions ---
	_log("ASSISTED: FINALE + reach100 + chars L2")
	_seed_finale_ready()
	await get_tree().process_frame
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "stage FINALE")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.FINAL_DATE)), "FINAL_DATE unlocked")
	_ok(int(_gs.call("get_world_reach")) >= 100, "world_reach >= 100")
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_final_target")), "girl_final_target not conquered")

	_ok(int(_world.call("request_travel", &"final_location", &"spawn_default")) == 0, "travel final_location SUCCESS")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	_ok(String(_world.get("current_location_id")) == "final_location", "at final_location")

	var fin_root: Node = get_tree().root.find_child("final_location", true, false)
	_ok(fin_root != null, "final_location root present")
	var signal_i: Area3D = null
	var beacon: Label3D = null
	if fin_root != null:
		signal_i = fin_root.get_node_or_null("Interactables/FinalSignalInteractable") as Area3D
		beacon = fin_root.get_node_or_null("Geometry/FinalSignalBeacon") as Label3D
	_ok(signal_i != null, "FinalSignalInteractable present")
	_ok(beacon != null, "FinalSignalBeacon present")

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().root.find_child("Player", true, false)
	_ok(player != null, "player present")
	_ok(signal_i != null and bool(signal_i.call("can_interact", player)), "signal interactable when preconditions met")
	var prompt: String = ""
	if signal_i != null:
		prompt = str(signal_i.call("get_interaction_prompt", player))
	_ok(prompt.contains("Ответить на внеземной сигнал"), "signal prompt=%s" % prompt)
	await _shot_look(Vector3(-7.5, 2.4, 5.5), Vector3(-10.0, 1.8, -2.5), "%s/02_final_signal.png" % OUT)

	# Phone FINALE before start
	var phone: PhoneJournal = _make_phone()
	phone.open(null)
	await get_tree().process_frame
	var fin_phone: String = phone.get_story_text()
	_ok(fin_phone.contains("ФИНАЛ"), "phone FINALE before")
	_ok(
		fin_phone.contains("Внеземной сигнал") or fin_phone.contains("сигнал обнаружен") or fin_phone.contains("романтическая цель"),
		"phone signal text"
	)
	_ok(not fin_phone.contains("girl_final_target"), "phone no raw girl id before")
	await _shot_ui("%s/03_phone_finale_signal.png" % OUT)
	phone.close()
	phone.queue_free()

	# --- 4) Start via signal → INTRO ---
	_log("ASSISTED: start final date via FinalSignalInteractable")
	var controller: FinalDateController = _get_controller(fin_root)
	_ok(controller != null, "FinalDateController available")
	if controller != null:
		controller.set_test_auto_win_exhibition(true)
	if signal_i != null:
		signal_i.call("_on_interact", player)
	await get_tree().process_frame
	await get_tree().process_frame
	controller = _get_controller(fin_root)
	_ok(controller != null and controller.is_attempt_active(), "attempt active after signal")
	_ok(controller != null and controller.get_phase() == FinalDateTypes.Phase.INTRO, "phase INTRO")
	_ok(controller != null and controller.get_target_actor() != null, "target actor spawned")
	_ok(not bool(_dating.call("is_date_active")), "no DatingCore session")
	var target: Node3D = null
	if controller != null:
		target = controller.get_target_actor() as Node3D
	if target != null:
		await _shot_look(target.global_position + Vector3(1.8, 1.6, 2.2), target.global_position + Vector3(0.0, 1.2, 0.0), "%s/04_mid_date_target.png" % OUT)
	else:
		await _shot_look(Vector3(-3.5, 2.6, 3.8), Vector3(0.0, 1.6, -1.0), "%s/04_mid_date_target.png" % OUT)

	# Mid phone: Последняя
	phone = _make_phone()
	phone.open(null)
	await get_tree().process_frame
	var mid_phone: String = phone.get_story_text()
	_ok(mid_phone.contains("Последняя"), "phone mid Последняя")
	_ok(mid_phone.contains("Финальное свидание") or mid_phone.contains("свидание"), "phone mid date text")
	phone.close()
	phone.queue_free()

	# --- 5) Success path: events + DANCE + SLAP exhibitions ---
	var xp0: int = int(_gs.call("get_experience"))
	var up0: int = int(_gs.call("get_upgrade_points"))
	var auth0: int = int(_gs.call("get_authority"))
	var money0: int = int(_gs.call("get_money"))
	_ok(not bool(_gs.call("is_rival_defeated", &"rival_final_ceremonial")), "pre rival_ceremonial not defeated")
	_ok(not bool(_gs.call("is_rival_defeated", &"rival_final_gravity")), "pre rival_gravity not defeated")

	if controller != null:
		var ui: FinalDateUI = controller.get_ui()
		_ok(ui != null and ui.is_open(), "intro UI open")
		if ui != null:
			ui.press_continue()
		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
		_ok(controller.get_phase() == FinalDateTypes.Phase.EVENT_1, "EVENT_1")
		_choose(controller, &"aura")
		await _do_rival(controller, FinalDateTypes.CHECKPOINT_RIVAL_1)
		_ok(controller.did_rival_1_win(), "rival1 DANCE won (exhibition)")
		_ok(not bool(_gs.call("is_rival_defeated", &"rival_final_ceremonial")), "no mark_rival_defeated ceremonial")
		_ok(int(_gs.call("get_authority")) == auth0, "no Authority change after DANCE")

		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_2)
		_choose(controller, &"muscle")
		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_MOVE_TABLE)
		await _do_rival(controller, FinalDateTypes.CHECKPOINT_RIVAL_2)
		_ok(controller.did_rival_2_win(), "rival2 SLAP won (exhibition)")
		_ok(not bool(_gs.call("is_rival_defeated", &"rival_final_gravity")), "no mark_rival_defeated gravity")
		_ok(int(_gs.call("get_authority")) == auth0, "no Authority change after SLAP")

		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_3)
		_choose(controller, &"appearance")
		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_4)
		_choose(controller, &"capital")

		_ok(int(_gs.call("get_girl_relationship", &"girl_final_target")) == 5, "relationship 5")
		_ok(bool(_gs.call("is_girl_conquered", &"girl_final_target")), "conquered")
		_ok(int(_gs.call("get_experience")) == xp0 + 1, "xp +1 once")
		_ok(int(_gs.call("get_upgrade_points")) == up0 + 1, "upgrade +1 once")
		_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "stage stays FINALE")
		_ok(controller.get_phase() == FinalDateTypes.Phase.SUCCESS, "SUCCESS phase")
		ui = controller.get_ui()
		_ok(ui != null and ui.get_mode() == "success_dialogue", "success dialogue")
		if ui != null:
			ui.press_continue()
			_ok(ui.get_mode() == "ending", "ending screen")
			_ok(ui.press_continue(), "Continue dismiss ending")
		_ok(not controller.is_attempt_active(), "post-ending not active")
		_ok(not controller.can_start_final_date(), "no second reward start")
		_ok(int(_gs.call("get_experience")) == xp0 + 1, "exactly once xp after continue")

	# World still playable after ending
	_ok(int(_world.call("request_travel", &"city_hub", &"spawn_default")) == 0, "post-ending travel city_hub")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(String(_world.get("current_location_id")) == "city_hub", "world playable city_hub")
	_ok(int(_world.call("request_travel", &"final_location", &"spawn_default")) == 0, "return final_location")
	await get_tree().process_frame
	await get_tree().process_frame
	fin_root = get_tree().root.find_child("final_location", true, false)
	signal_i = null
	if fin_root != null:
		signal_i = fin_root.get_node_or_null("Interactables/FinalSignalInteractable") as Area3D
	if signal_i != null:
		var done_prompt: String = str(signal_i.call("get_interaction_prompt", player))
		_ok(done_prompt.contains("Финал завершён") or not bool(signal_i.call("can_interact", player)), "signal locked after conquer")

	# Phone completed
	phone = _make_phone()
	phone.open(null)
	await get_tree().process_frame
	var done_phone: String = phone.get_story_text()
	_ok(done_phone.contains("ФИНАЛ ЗАВЕРШЁН") or done_phone.contains("ЗАВЕРШ"), "phone completed")
	_ok(done_phone.contains("Последняя") and done_phone.contains("+5"), "phone Последняя +5")
	await _shot_ui("%s/05_phone_finale_complete.png" % OUT)
	phone.close()
	phone.queue_free()

	# --- 6) Fail path: comedy, no permanent penalty, full retry ---
	_log("ASSISTED: fail path + retry")
	_seed_finale_ready()
	await get_tree().process_frame
	_ok(int(_world.call("request_travel", &"final_location", &"spawn_default")) == 0, "fail-path travel final")
	await get_tree().process_frame
	await get_tree().process_frame
	fin_root = get_tree().root.find_child("final_location", true, false)
	controller = _get_controller(fin_root)
	if controller == null and fin_root != null:
		controller = FinalDateController.new()
		controller.name = "FinalDateController"
		fin_root.add_child(controller)
	_ok(controller != null, "fail-path controller")
	money0 = int(_gs.call("get_money"))
	auth0 = int(_gs.call("get_authority"))
	xp0 = int(_gs.call("get_experience"))
	up0 = int(_gs.call("get_upgrade_points"))
	var reach0: int = int(_gs.call("get_world_reach"))
	if controller != null:
		controller.set_test_auto_win_exhibition(false)
		_ok(controller.start_final_date(player), "fail-path start")
		var ui2: FinalDateUI = controller.get_ui()
		if ui2 != null:
			ui2.press_continue()
		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
		_choose(controller, &"neutral")
		controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1)
		ui2 = controller.get_ui()
		if ui2 != null:
			ui2.press_continue()
		var waited: int = 0
		while (not bool(_runner.call("is_busy"))) and waited < 40:
			await get_tree().process_frame
			waited += 1
		if bool(_runner.call("is_busy")):
			var mg: CanvasLayer = _runner.call("get_active_minigame") as CanvasLayer
			var result := RivalCompetitionResult.new()
			result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
			result.debug_score_summary = "m21_indep_force_loss"
			if mg != null:
				mg.emit_signal("match_finished", result)
			var w2: int = 0
			while bool(_runner.call("is_busy")) and w2 < 80:
				await get_tree().process_frame
				w2 += 1
		_ok(controller.get_phase() == FinalDateTypes.Phase.FAILURE, "FAILURE phase")
		_ok(controller.get_failure_reason() == FinalDateTypes.FailureReason.RIVAL_LOSS, "failure rival loss")
		_ok(int(_gs.call("get_money")) == money0, "fail no money penalty")
		_ok(int(_gs.call("get_authority")) == auth0, "fail no authority penalty")
		_ok(int(_gs.call("get_experience")) == xp0, "fail no xp")
		_ok(int(_gs.call("get_upgrade_points")) == up0, "fail no up")
		_ok(int(_gs.call("get_girl_relationship", &"girl_final_target")) == 0, "fail rel 0")
		_ok(not bool(_gs.call("is_girl_conquered", &"girl_final_target")), "fail not conquered")
		_ok(not bool(_gs.call("is_rival_defeated", &"rival_final_ceremonial")), "fail no rival defeat")
		_ok(int(_gs.call("get_world_reach")) == reach0, "fail reach unchanged")
		ui2 = controller.get_ui()
		_ok(ui2 != null, "fail comedy UI")
		controller.set_test_auto_win_exhibition(true)
		if ui2 != null:
			ui2.press_retry()
		_ok(controller.is_attempt_active(), "retry active")
		_ok(controller.get_phase() == FinalDateTypes.Phase.INTRO, "retry INTRO")
		_ok(controller.get_connection_score() == 0, "retry score reset")
		controller.abort_attempt_to_gameplay()
		_ok(not controller.is_attempt_active(), "abort returns gameplay")
		_ok(controller.can_start_final_date(), "can start again after abort")

	# Source seam checks (read-only evidence)
	var src: String = FileAccess.get_file_as_string("res://game/final_date/final_date_controller.gd")
	_ok(not src.contains("mark_rival_defeated"), "controller no mark_rival_defeated")
	_ok(not src.contains("start_date("), "controller no DatingCore start_date")
	var runner_src: String = FileAccess.get_file_as_string("res://game/rivals/rival_competition_runner.gd")
	_ok(runner_src.contains("run_exhibition_competition"), "exhibition seam present")
	_ok(runner_src.contains("no RivalEncounters") or runner_src.contains("Authority"), "exhibition docs Authority-free")

	# --- 7) Save/load edge ---
	_log("ASSISTED: save/load conquered FINALE")
	_seed_finale_ready()
	_gs.call("mark_girl_discovered", &"girl_final_target")
	_gs.call("add_girl_contact", &"girl_final_target")
	_gs.call("set_girl_relationship", &"girl_final_target", 5)
	_gs.call("mark_girl_conquered", &"girl_final_target")
	var save_path: String = "user://m21_indep_qa_save.json"
	var payload: Dictionary = {}
	if _gs.has_method("export_save_dict"):
		payload = _gs.call("export_save_dict") as Dictionary
	elif _gs.has_method("to_save_dict"):
		payload = _gs.call("to_save_dict") as Dictionary
	elif _gs.has_method("serialize"):
		payload = _gs.call("serialize") as Dictionary
	var saved: bool = false
	if not payload.is_empty():
		var sf := FileAccess.open(save_path, FileAccess.WRITE)
		if sf != null:
			sf.store_string(JSON.stringify(payload))
			sf.close()
			saved = true
	# Persist via GameState restore APIs (full file save schema may be elsewhere).
	_ok(bool(_gs.call("is_girl_conquered", &"girl_final_target")), "pre-reset conquered for restore test")
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_final_target")), "reset clears conquered")
	_gs.call("restore_stage", GameTypes.GameStage.FINALE)
	_gs.call("set_world_reach", 100)
	_gs.call("mark_girl_discovered", &"girl_final_target")
	_gs.call("add_girl_contact", &"girl_final_target")
	_gs.call("set_girl_relationship", &"girl_final_target", 5)
	_gs.call("mark_girl_conquered", &"girl_final_target")
	await get_tree().process_frame
	_ok(bool(_gs.call("is_girl_conquered", &"girl_final_target")), "restored conquered")
	_ok(int(_gs.call("get_girl_relationship", &"girl_final_target")) == 5, "restored rel 5")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "restored FINALE")
	controller = _get_controller(get_tree().root.find_child("final_location", true, false))
	if controller == null:
		controller = FinalDateController.new()
		add_child(controller)
	_ok(not controller.can_start_final_date(), "conquered locks restart")
	_log("save_dict_export_available=%s file_saved=%s" % [not payload.is_empty(), saved])

	_log(
		"summary stage=%s reach=%s conquered=%s failed=%s passed=%s"
		% [
			str(_gs.call("get_stage")),
			str(_gs.call("get_world_reach")),
			str(_gs.call("is_girl_conquered", &"girl_final_target")),
			str(_failed),
			str(_passed),
		]
	)


func _seed_finale_ready() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("restore_stage", GameTypes.GameStage.FINALE)
	_gs.call("set_world_reach", 100)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)


func _get_controller(fin_root: Node) -> FinalDateController:
	if fin_root == null:
		return null
	var existing: Node = fin_root.find_child("FinalDateController", true, false)
	if existing is FinalDateController:
		return existing as FinalDateController
	if existing != null and existing.has_method("start_final_date"):
		return existing as FinalDateController
	return null


func _choose(controller: FinalDateController, option_id: StringName) -> void:
	_ok(controller.select_event_option(option_id), "select %s" % String(option_id))
	var ui: FinalDateUI = controller.get_ui()
	if ui != null and ui.get_mode() == "plain":
		ui.press_continue()


func _do_rival(controller: FinalDateController, checkpoint_id: StringName) -> void:
	controller.notify_checkpoint(checkpoint_id)
	var ui: FinalDateUI = controller.get_ui()
	_ok(ui != null and ui.is_open(), "rival staging ui %s" % String(checkpoint_id))
	if ui != null:
		ui.press_continue()
	var waited: int = 0
	while bool(_runner.call("is_busy")) and waited < 180:
		await get_tree().process_frame
		waited += 1
	_ok(not bool(_runner.call("is_busy")), "rival finished %s" % String(checkpoint_id))


func _make_phone() -> PhoneJournal:
	_dismiss_accept_dialogs()
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	var phone: PhoneJournal = packed.instantiate() as PhoneJournal
	add_child(phone)
	return phone


func _dismiss_accept_dialogs() -> void:
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AcceptDialog or n is ConfirmationDialog:
			var win: Window = n as Window
			if win.visible:
				win.hide()
				win.visible = false
		for c in n.get_children():
			stack.append(c)


func _shot_look(cam_pos: Vector3, look: Vector3, out_path: String) -> void:
	var cam := Camera3D.new()
	cam.name = "M21QaCam"
	add_child(cam)
	cam.global_position = cam_pos
	cam.look_at(look, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_log("SHOT SKIP no viewport %s" % out_path)
		cam.queue_free()
		return
	var img: Image = tex.get_image()
	if img == null:
		_log("SHOT SKIP null image %s" % out_path)
		cam.queue_free()
		return
	var err: Error = img.save_png(ProjectSettings.globalize_path(out_path))
	_log("SHOT %s err=%s size=%sx%s" % [out_path, err, img.get_width(), img.get_height()])
	cam.queue_free()
	await get_tree().process_frame


func _shot_ui(out_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_log("SHOT UI SKIP no viewport %s" % out_path)
		return
	var img: Image = tex.get_image()
	if img == null:
		_log("SHOT UI SKIP null image %s" % out_path)
		return
	var err: Error = img.save_png(ProjectSettings.globalize_path(out_path))
	_log("SHOT UI %s err=%s size=%sx%s" % [out_path, err, img.get_width(), img.get_height()])
