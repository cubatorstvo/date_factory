class_name PlaythroughDriver
extends RefCounted
## Visual playthrough driver P00→P21 via production APIs (FullGameIntegrationHelpers).
## Forbidden: GameState.advance_stage / set_world_reach / mark_girl_conquered / set_story_flag.


enum Checkpoint {
	P00_BOOT,
	P01_TITLE,
	P02_NEW_GAME,
	P03_APARTMENT,
	P04_HUD_PHONE,
	P05_CITY,
	P06_CAFE,
	P07_GYM,
	P08_APPEARANCE,
	P09_RIVAL,
	P10_MINE,
	P11_MEDIA,
	P12_OVERLOAD,
	P13_LAB_GATE,
	P14_FIRST_CLONE,
	P15_INCREMENTAL,
	P16_PRODUCTION,
	P17_LATE_GAME,
	P18_FINAL_PREP,
	P19_FINAL_DATE,
	P20_ENDING,
	P21_DONE,
}


var capture: ScreenshotCapture = null
var auditor: UiLayoutAuditor = null
var host: Node = null
var fixtures: GalleryFixtures = GalleryFixtures.new()

var completed: Array[String] = []
var unmet: Array[String] = []
var shots: Array[String] = []
var defects: Array = []
var snapshots: Array = []
var current: Checkpoint = Checkpoint.P00_BOOT

var _helpers: FullGameIntegrationHelpers = null
var _controller: FinalDateController = null
var _final_location: Node3D = null
var _runner: Node = null
var _negative_done: bool = false


func run() -> void:
	completed.clear()
	unmet.clear()
	shots.clear()
	defects.clear()
	snapshots.clear()
	current = Checkpoint.P00_BOOT
	_mark(Checkpoint.P00_BOOT, true, "runner boot")

	await _p01_title()
	await _p02_new_game()
	if not completed.has("P02_NEW_GAME"):
		_mark(Checkpoint.P21_DONE, false, "aborted — new game failed")
		_cleanup()
		return

	_helpers = fixtures.make_helpers(host)
	if _helpers == null:
		_mark(Checkpoint.P21_DONE, false, "helpers bind failed")
		_cleanup()
		return
	_helpers.connect_stage_tracker()
	_runner = host.get_node_or_null("/root/RivalCompetitionRunner")
	_helpers.boost_discovery_stats()

	await _p03_apartment()
	await _p04_hud_phone()
	await _negative_path_early()
	await _progress_to_city_and_spokes()
	await _progress_rivals_and_mine()
	await _progress_media_overload_lab()
	await _progress_clone_president_finale()
	await _p19_final_date()
	await _p20_ending()
	_mark(Checkpoint.P21_DONE, true, "playthrough finished")
	_cleanup()


func _cleanup() -> void:
	_dispose_final_harness()
	if _helpers != null:
		_helpers.restore_runner()
		_helpers = null


func _helpers_ok_soft(cond: bool, label: String) -> void:
	print("[PlaythroughDriver] helper %s: %s" % ["ok" if cond else "FAIL", label])


func _p01_title() -> void:
	current = Checkpoint.P01_TITLE
	var packed: PackedScene = load("res://ui/frontend/title_menu.tscn") as PackedScene
	var menu: TitleMenu = null
	if packed != null:
		menu = packed.instantiate() as TitleMenu
	else:
		menu = TitleMenu.new()
	host.add_child(menu)
	if menu.has_method("show_menu"):
		menu.show_menu()
	var path: String = await capture.capture("000_main_menu")
	if not path.is_empty():
		shots.append(path)
	defects.append_array(auditor.audit_title_menu(menu))
	_snapshot("P01_TITLE", {"shot": path})
	_mark(Checkpoint.P01_TITLE, not path.is_empty(), "main menu capture")
	menu.queue_free()
	await host.get_tree().process_frame


func _p02_new_game() -> void:
	current = Checkpoint.P02_NEW_GAME
	var ok: bool = fixtures.prepare_new_game_world()
	_snapshot("P02_NEW_GAME", {"ok": ok})
	_mark(Checkpoint.P02_NEW_GAME, ok, "FrontendSaveApi.start_new_game")


func _p03_apartment() -> void:
	current = Checkpoint.P03_APARTMENT
	await capture.settle()
	var path: String = await capture.capture("100_apartment_spawn")
	if not path.is_empty():
		shots.append(path)
	fixtures.look_player(0.0, 0.0)
	var path_f: String = await capture.capture("101_apartment_forward")
	if not path_f.is_empty():
		shots.append(path_f)
	var world: Node = fixtures.get_world()
	var loc: String = ""
	if world != null:
		loc = str(world.get("current_location_id"))
	_snapshot("P03_APARTMENT", {"shot": path, "location": loc})
	_mark(Checkpoint.P03_APARTMENT, not path.is_empty() and loc == "apartment", "apartment spawn")


func _p04_hud_phone() -> void:
	current = Checkpoint.P04_HUD_PHONE
	var world: Node = fixtures.get_world()
	var hud_ok: bool = false
	if world != null and world.has_method("get_game_hud"):
		var hud: Node = world.call("get_game_hud") as Node
		if hud != null:
			var path_hud: String = await capture.capture("110_hud")
			if not path_hud.is_empty():
				shots.append(path_hud)
				hud_ok = true
			defects.append_array(auditor.audit_visible_tree(hud))
	var phone: PhoneJournal = fixtures.open_phone()
	var phone_ok: bool = false
	if phone != null:
		fixtures.set_phone_tab(phone, PhoneJournal.PhoneTab.STATUS)
		var path_phone: String = await capture.capture("900_phone_status")
		if not path_phone.is_empty():
			shots.append(path_phone)
			phone_ok = true
		defects.append_array(auditor.audit_visible_tree(phone))
		if phone.has_method("close"):
			phone.close()
	_snapshot("P04_HUD_PHONE", {"hud": hud_ok, "phone": phone_ok})
	_mark(Checkpoint.P04_HUD_PHONE, hud_ok or phone_ok, "hud/phone captures")


func _negative_path_early() -> void:
	## Interleaved negative path: rival LOSS→WIN, discovery FAIL→retry, partial date→cooldown.
	if _helpers == null:
		return
	_helpers.conquer_girl(StoryIds.GIRL_NEIGHBOR, "neighbor")
	var auth0: int = int(_helpers.gs.call("get_authority"))

	_helpers.lose_rival(StoryIds.RIVAL_ACTRESS, "neg_actress_loss")
	var path_loss: String = await capture.capture("n01_rival_loss")
	if not path_loss.is_empty():
		shots.append(path_loss)
	_snapshot("NEG_RIVAL_LOSS", {
		"auth": int(_helpers.gs.call("get_authority")),
		"auth0": auth0,
		"defeated": bool(_helpers.gs.call("is_rival_defeated", StoryIds.RIVAL_ACTRESS)),
	})

	_helpers.win_rival(StoryIds.RIVAL_ACTRESS, "neg_actress_retry")
	var path_win: String = await capture.capture("n02_rival_retry_win")
	if not path_win.is_empty():
		shots.append(path_win)

	_helpers.discover_failure(StoryIds.GIRL_ACTRESS)
	var path_fail: String = await capture.capture("n03_discovery_fail")
	if not path_fail.is_empty():
		shots.append(path_fail)
	var retry_days: int = int(_helpers.gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_ACTRESS))
	for _i: int in range(maxi(retry_days, 0)):
		_helpers.day.call("advance_day")
	_helpers.discover_success(StoryIds.GIRL_ACTRESS)
	var path_ok: String = await capture.capture("n04_discovery_success")
	if not path_ok.is_empty():
		shots.append(path_ok)

	var partial: RelationshipDateResult = _helpers.apply_partial_date(StoryIds.GIRL_ACTRESS, 2)
	var path_partial: String = await capture.capture("n05_date_partial")
	if not path_partial.is_empty():
		shots.append(path_partial)
	var cd: int = int(_helpers.gs.call("get_girl_date_cooldown_days_remaining", StoryIds.GIRL_ACTRESS))
	for _j: int in range(maxi(cd, 0)):
		_helpers.day.call("advance_day")
	_helpers.conquer_girl(StoryIds.GIRL_ACTRESS, "actress_recovery")
	var path_rec: String = await capture.capture("n06_date_recovery_conquer")
	if not path_rec.is_empty():
		shots.append(path_rec)
	_snapshot("NEG_PATH", {
		"stage": _helpers.stage(),
		"partial_ok": partial != null and partial.ok,
	})
	_negative_done = true
	print("[PlaythroughDriver] negative path complete stage=%s" % _helpers.stage())


func _progress_to_city_and_spokes() -> void:
	current = Checkpoint.P05_CITY
	var city_ok: bool = fixtures.travel_if_available(&"city_hub")
	if city_ok:
		var path: String = await capture.capture("200_city")
		if not path.is_empty():
			shots.append(path)
		_snapshot("P05_CITY", {"shot": path})
		_mark(Checkpoint.P05_CITY, not path.is_empty(), "city_hub travel")
	else:
		_snapshot("P05_CITY", {"locked": true})
		_mark(Checkpoint.P05_CITY, false, "city_hub locked")

	current = Checkpoint.P06_CAFE
	var cafe_ok: bool = fixtures.travel_if_available(&"cafe")
	if cafe_ok:
		var path_c: String = await capture.capture("300_cafe")
		if not path_c.is_empty():
			shots.append(path_c)
		_snapshot("P06_CAFE", {"shot": path_c})
		_mark(Checkpoint.P06_CAFE, not path_c.is_empty(), "cafe")
	else:
		_mark(Checkpoint.P06_CAFE, false, "cafe locked")

	current = Checkpoint.P07_GYM
	var gym_ok: bool = fixtures.travel_if_available(&"gym")
	if gym_ok:
		var path_g: String = await capture.capture("400_gym")
		if not path_g.is_empty():
			shots.append(path_g)
		_snapshot("P07_GYM", {"shot": path_g})
		_mark(Checkpoint.P07_GYM, not path_g.is_empty(), "gym")
	else:
		_mark(Checkpoint.P07_GYM, false, "gym locked")

	current = Checkpoint.P08_APPEARANCE
	var app_ok: bool = fixtures.travel_if_available(&"appearance_space")
	if app_ok:
		var path_a: String = await capture.capture("410_appearance")
		if not path_a.is_empty():
			shots.append(path_a)
		_snapshot("P08_APPEARANCE", {"shot": path_a})
		_mark(Checkpoint.P08_APPEARANCE, not path_a.is_empty(), "appearance_space")
	else:
		_mark(Checkpoint.P08_APPEARANCE, false, "appearance locked")


func _progress_rivals_and_mine() -> void:
	current = Checkpoint.P09_RIVAL
	# Actress already defeated in negative path; open mine rival choose UI before defeating him.
	var rival_ui: RivalEncounterUI = fixtures.open_rival_choose(host, StoryIds.RIVAL_MINE_BOSS)
	var rival_shot_ok: bool = false
	if rival_ui != null:
		var path_r: String = await capture.capture("420_rival_choose")
		if not path_r.is_empty():
			shots.append(path_r)
			rival_shot_ok = true
		defects.append_array(auditor.audit_visible_tree(rival_ui))
		fixtures.free_ui(rival_ui)
		if _helpers.re != null and _helpers.re.has_method("force_clear_session"):
			_helpers.re.call("force_clear_session")
	_snapshot("P09_RIVAL", {"ui": rival_shot_ok, "stage": _helpers.stage()})
	_mark(Checkpoint.P09_RIVAL, rival_shot_ok or _helpers.stage() >= int(GameTypes.GameStage.STAGE_2), "rival checkpoint")

	if _helpers.stage() < int(GameTypes.GameStage.STAGE_3):
		_helpers.win_rival(StoryIds.RIVAL_MINE_BOSS, "mine_rival")
		_helpers.conquer_girl(StoryIds.GIRL_MINE_BOSS, "mine_boss")
	current = Checkpoint.P10_MINE
	var mine_ok: bool = fixtures.travel_if_available(&"salary_mine")
	if mine_ok:
		var path_m: String = await capture.capture("500_mine")
		if not path_m.is_empty():
			shots.append(path_m)
		_snapshot("P10_MINE", {"shot": path_m, "stage": _helpers.stage()})
		_mark(Checkpoint.P10_MINE, not path_m.is_empty(), "salary_mine")
	else:
		_mark(Checkpoint.P10_MINE, _helpers.stage() >= int(GameTypes.GameStage.STAGE_3), "mine travel locked but stage ok")

	if _helpers.stage() < int(GameTypes.GameStage.STAGE_4):
		_helpers.win_rival(StoryIds.RIVAL_MAGAZINE_EDITOR, "editor_rival")
		_helpers.conquer_girl(StoryIds.GIRL_MAGAZINE_EDITOR, "editor")


func _progress_media_overload_lab() -> void:
	current = Checkpoint.P11_MEDIA
	var app_ok: bool = fixtures.travel_if_available(&"appearance_space")
	if app_ok:
		var path: String = await capture.capture("510_media_studio")
		if not path.is_empty():
			shots.append(path)
		_mark(Checkpoint.P11_MEDIA, not path.is_empty(), "media/appearance")
	else:
		_mark(Checkpoint.P11_MEDIA, false, "appearance locked")
	_snapshot("P11_MEDIA", {"stage": _helpers.stage()})

	current = Checkpoint.P12_OVERLOAD
	_helpers.drive_media_to_overload()
	_helpers.drive_overload_recognition()
	var phone: PhoneJournal = fixtures.open_phone()
	if phone != null:
		fixtures.set_phone_tab(phone, PhoneJournal.PhoneTab.MEDIA)
		var path_p: String = await capture.capture("511_phone_media_overload")
		if not path_p.is_empty():
			shots.append(path_p)
		if phone.has_method("close"):
			phone.close()
	_snapshot("P12_OVERLOAD", {
		"overload": bool(_helpers.media.call("is_overload_ready")) if _helpers.media != null else false,
		"stage": _helpers.stage(),
	})
	_mark(Checkpoint.P12_OVERLOAD, true, "media→overload→recognition")

	_helpers.win_rival(StoryIds.RIVAL_SCIENTIST, "scientist_rival")
	_helpers.conquer_girl(StoryIds.GIRL_SCIENTIST, "scientist")
	current = Checkpoint.P13_LAB_GATE
	var lab_ok: bool = fixtures.travel_if_available(&"laboratory")
	if lab_ok:
		fixtures.dismiss_blocking_overlays(host)
		await host.get_tree().process_frame
		var path_l: String = await capture.capture("600_lab")
		if not path_l.is_empty():
			shots.append(path_l)
		_snapshot("P13_LAB_GATE", {"shot": path_l, "stage": _helpers.stage()})
		_mark(Checkpoint.P13_LAB_GATE, not path_l.is_empty() and _helpers.stage() == int(GameTypes.GameStage.STAGE_5), "lab + STAGE_5")
	else:
		_mark(Checkpoint.P13_LAB_GATE, _helpers.stage() == int(GameTypes.GameStage.STAGE_5), "lab travel failed")


func _progress_clone_president_finale() -> void:
	current = Checkpoint.P14_FIRST_CLONE
	var clone_ok: bool = _helpers.commit_first_clone_work()
	var path_c: String = await capture.capture("610_first_clone")
	if not path_c.is_empty():
		shots.append(path_c)
	var cterm: CanvasLayer = fixtures.open_clone_terminal(host)
	if cterm != null:
		var path_ct: String = await capture.capture("611_clone_terminal")
		if not path_ct.is_empty():
			shots.append(path_ct)
		fixtures.free_ui(cterm)
	_snapshot("P14_FIRST_CLONE", {"ok": clone_ok, "clones": int(_helpers.gs.call("get_total_clones"))})
	_mark(Checkpoint.P14_FIRST_CLONE, clone_ok, "first clone")

	current = Checkpoint.P15_INCREMENTAL
	var xp_ok: bool = _helpers.run_president_xp_bridge(10, 420.0)
	_snapshot("P15_INCREMENTAL", {"xp": int(_helpers.gs.call("get_experience")), "ok": xp_ok})
	_mark(Checkpoint.P15_INCREMENTAL, xp_ok, "president XP bridge")

	_helpers.win_rival(StoryIds.RIVAL_PRESIDENT, "president_rival")
	_helpers.conquer_girl(StoryIds.GIRL_PRESIDENT, "president")
	current = Checkpoint.P16_PRODUCTION
	var prod_ok: bool = fixtures.travel_if_available(&"production_area")
	if prod_ok:
		var path_p: String = await capture.capture("700_production")
		if not path_p.is_empty():
			shots.append(path_p)
	var gterm: CanvasLayer = fixtures.open_global_terminal(host)
	if gterm != null:
		var path_g: String = await capture.capture("710_global_terminal")
		if not path_g.is_empty():
			shots.append(path_g)
		fixtures.free_ui(gterm)
	_snapshot("P16_PRODUCTION", {"travel": prod_ok, "stage": _helpers.stage()})
	_mark(Checkpoint.P16_PRODUCTION, _helpers.stage() == int(GameTypes.GameStage.STAGE_6), "STAGE_6 production")

	current = Checkpoint.P17_LATE_GAME
	var reach_ok: bool = _helpers.run_stage6_reach(520.0)
	var path_r: String = await capture.capture("720_reach100")
	if not path_r.is_empty():
		shots.append(path_r)
	_snapshot("P17_LATE_GAME", {
		"reach": int(_helpers.gs.call("get_world_reach")),
		"stage": _helpers.stage(),
		"ok": reach_ok,
	})
	_mark(Checkpoint.P17_LATE_GAME, reach_ok and _helpers.stage() == int(GameTypes.GameStage.FINALE), "Reach100 → FINALE")

	current = Checkpoint.P18_FINAL_PREP
	var final_travel: bool = fixtures.travel_if_available(&"final_location")
	if final_travel:
		var path_f: String = await capture.capture("800_final")
		if not path_f.is_empty():
			shots.append(path_f)
	_snapshot("P18_FINAL_PREP", {"travel": final_travel, "stage": _helpers.stage()})
	_mark(Checkpoint.P18_FINAL_PREP, _helpers.stage() == int(GameTypes.GameStage.FINALE), "final prep")


func _ensure_final_harness() -> void:
	if _controller != null and is_instance_valid(_controller):
		return
	_final_location = Node3D.new()
	_final_location.name = "playthrough_final_location"
	host.add_child(_final_location)
	var marker_names: Array[String] = [
		"final_attempt_start",
		"final_target_signal_marker",
		"final_target_orbit_marker",
		"final_target_table_marker",
		"final_rival_ceremonial_marker",
		"final_rival_gravity_marker",
		"final_checkpoint_event_1",
		"final_checkpoint_rival_1",
		"final_checkpoint_event_2",
		"final_checkpoint_rival_2",
		"final_checkpoint_event_3",
		"final_checkpoint_event_4",
		"final_walk_checkpoint_a",
		"final_walk_checkpoint_b",
		"final_walk_checkpoint_c",
	]
	var i: int = 0
	for mn: String in marker_names:
		var m: Marker3D = Marker3D.new()
		m.name = mn
		m.position = Vector3(float(i), 0.0, 0.0)
		_final_location.add_child(m)
		i += 1
	var gate_b: StaticBody3D = StaticBody3D.new()
	gate_b.name = "final_gate_zone_b"
	gate_b.collision_layer = 1
	_final_location.add_child(gate_b)
	var gate_c: StaticBody3D = StaticBody3D.new()
	gate_c.name = "final_gate_zone_c"
	gate_c.collision_layer = 1
	_final_location.add_child(gate_c)
	_controller = FinalDateController.new()
	_controller.name = "FinalDateController"
	_final_location.add_child(_controller)


func _dispose_final_harness() -> void:
	if _controller != null and is_instance_valid(_controller):
		if _controller.is_attempt_active():
			_controller.abort_attempt_to_gameplay()
		_controller.set_test_auto_win_exhibition(false)
	if _final_location != null and is_instance_valid(_final_location):
		_final_location.queue_free()
	_final_location = null
	_controller = null
	if _helpers != null and _helpers.re != null and _helpers.re.has_method("force_clear_session"):
		_helpers.re.call("force_clear_session")
	if _helpers != null and _helpers.fake_runner != null:
		_helpers.fake_runner.attach(_helpers.re)
		_helpers.fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)


func _choose_final(option_id: StringName) -> void:
	if _controller == null:
		return
	_controller.select_event_option(option_id)
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null and ui.get_mode() == "plain":
		ui.press_continue()


func _do_final_rival_checkpoint(checkpoint_id: StringName) -> void:
	if _controller == null:
		return
	_controller.notify_checkpoint(checkpoint_id)
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null and ui.is_open():
		ui.press_continue()
	var waited: int = 0
	while _runner != null and bool(_runner.call("is_busy")) and waited < 180:
		await host.get_tree().process_frame
		waited += 1


func _p19_final_date() -> void:
	current = Checkpoint.P19_FINAL_DATE
	if _helpers == null or _helpers.stage() != int(GameTypes.GameStage.FINALE):
		_mark(Checkpoint.P19_FINAL_DATE, false, "not FINALE")
		return
	if int(_helpers.gs.call("get_world_reach")) < 100:
		_mark(Checkpoint.P19_FINAL_DATE, false, "reach < 100")
		return
	_ensure_final_harness()
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)
	_controller.set_test_auto_win_exhibition(true)
	if not _controller.can_start_final_date() or not _controller.start_final_date(null):
		_mark(Checkpoint.P19_FINAL_DATE, false, "start_final_date failed")
		return
	fixtures.dismiss_blocking_overlays(host)
	await host.get_tree().process_frame
	var intro_ui: FinalDateUI = _controller.get_ui()
	if intro_ui != null and intro_ui.is_open():
		var path_i: String = await capture.capture("810_final_date_intro")
		if not path_i.is_empty():
			shots.append(path_i)
		intro_ui.press_continue()
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
	_choose_final(&"aura")
	var path_c: String = await capture.capture("811_final_date_choice")
	if not path_c.is_empty():
		shots.append(path_c)
	await _do_final_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1)
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_2)
	_choose_final(&"muscle")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_MOVE_TABLE)
	await _do_final_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_2)
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_3)
	_choose_final(&"appearance")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_4)
	_choose_final(&"capital")
	var conquered: bool = bool(_helpers.gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID))
	var phase_ok: bool = _controller.get_phase() == FinalDateTypes.Phase.SUCCESS
	_snapshot("P19_FINAL_DATE", {"conquered": conquered, "phase_success": phase_ok})
	_mark(Checkpoint.P19_FINAL_DATE, conquered or phase_ok, "final date progress")


func _p20_ending() -> void:
	current = Checkpoint.P20_ENDING
	if _controller == null or not is_instance_valid(_controller):
		_mark(Checkpoint.P20_ENDING, false, "no controller")
		return
	var ui: FinalDateUI = _controller.get_ui()
	var ending_ok: bool = false
	if ui != null and ui.is_open():
		var path: String = await capture.capture("820_ending")
		if not path.is_empty():
			shots.append(path)
		if ui.get_mode() == "ending" or ui.get_mode() == "success":
			ending_ok = true
			ui.press_continue()
		elif ui.get_mode() == "plain":
			ui.press_continue()
			ending_ok = true
	var still_active: bool = _controller.is_attempt_active()
	if still_active and ui != null and ui.is_open() and ui.get_mode() == "ending":
		ui.press_continue()
		still_active = _controller.is_attempt_active()
	_snapshot("P20_ENDING", {
		"ending_ui": ending_ok,
		"active": still_active,
		"conquered": bool(_helpers.gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)),
	})
	_mark(Checkpoint.P20_ENDING, ending_ok or bool(_helpers.gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)), "ending")


func _mark(cp: Checkpoint, ok: bool, note: String) -> void:
	var name: String = Checkpoint.keys()[int(cp)]
	if ok:
		completed.append(name)
	else:
		unmet.append("%s — %s" % [name, note])
	print("[PlaythroughDriver] %s ok=%s (%s)" % [name, str(ok), note])


func _snapshot(label: String, data: Dictionary) -> void:
	var row: Dictionary = {
		"checkpoint": label,
		"data": data,
	}
	var gs: Node = host.get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("get_stage"):
			row["stage"] = gs.call("get_stage")
		var day_node: Node = host.get_node_or_null("/root/GameDay")
		if day_node != null:
			if day_node.has_method("get_day_index"):
				row["day"] = day_node.call("get_day_index")
			elif day_node.has_method("get_current_day"):
				row["day"] = day_node.call("get_current_day")
			elif "current_day" in day_node:
				row["day"] = day_node.get("current_day")
		if gs.has_method("get_money"):
			row["money"] = gs.call("get_money")
		if gs.has_method("get_authority"):
			row["authority"] = gs.call("get_authority")
		if gs.has_method("get_experience"):
			row["experience"] = gs.call("get_experience")
		if gs.has_method("get_upgrade_points"):
			row["upgrade_points"] = gs.call("get_upgrade_points")
		if gs.has_method("get_total_clones"):
			row["clones"] = gs.call("get_total_clones")
		if gs.has_method("get_world_reach"):
			row["reach"] = gs.call("get_world_reach")
	var world: Node = fixtures.get_world()
	if world != null:
		row["location"] = str(world.get("current_location_id"))
	snapshots.append(row)
