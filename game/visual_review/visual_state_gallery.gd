class_name VisualStateGallery
extends RefCounted
## Visual playtest gallery — critical UI + world composition + late-state fixtures.


var capture: ScreenshotCapture = null
var auditor: UiLayoutAuditor = null
var host: Node = null
var fixtures: GalleryFixtures = GalleryFixtures.new()
var stub_missing: Array[String] = []
var defects: Array = []
var shots: Array[String] = []
var control_rows: Array = []
var _helpers: FullGameIntegrationHelpers = null


func run() -> void:
	stub_missing.clear()
	defects.clear()
	shots.clear()
	control_rows.clear()
	await _capture_frontend()
	await _capture_apartment_phone_early()
	await _capture_critical_ui_shells_early()
	await _drive_and_capture_world()
	await _capture_late_ui()
	_finalize_stubs()
	if _helpers != null:
		_helpers.restore_runner()
		_helpers = null


func _shot(shot_id: String) -> bool:
	var tree: SceneTree = host.get_tree() if host != null else null
	if tree != null:
		fixtures.dismiss_accept_dialogs(tree.root)
		await tree.process_frame
	var path: String = await capture.capture(shot_id)
	if path.is_empty():
		stub_missing.append("%s (capture failed)" % shot_id)
		return false
	shots.append(path)
	return true


func _capture_frontend() -> void:
	var packed: PackedScene = load("res://ui/frontend/title_menu.tscn") as PackedScene
	var menu: TitleMenu = null
	if packed != null:
		menu = packed.instantiate() as TitleMenu
	if menu == null:
		stub_missing.append("000_main_menu (scene missing)")
		return
	host.add_child(menu)
	if menu.has_method("show_menu"):
		menu.show_menu()
	await _shot("000_main_menu")
	defects.append_array(auditor.audit_title_menu(menu))
	control_rows.append_array(auditor.control_snapshot(menu))

	var settings_scene: PackedScene = load("res://ui/frontend/settings_panel.tscn") as PackedScene
	var settings: SettingsPanel = settings_scene.instantiate() as SettingsPanel if settings_scene != null else null
	if settings == null:
		stub_missing.append("010_settings (scene missing)")
		menu.queue_free()
		return
	menu.add_child(settings)
	settings.open()
	await _shot("010_settings")
	defects.append_array(auditor.audit_visible_tree(settings))
	settings.close(false)
	settings.queue_free()
	await host.get_tree().process_frame

	var save_load_scene: PackedScene = load("res://ui/frontend/save_load_panel.tscn") as PackedScene
	var load_panel: SaveLoadPanel = save_load_scene.instantiate() as SaveLoadPanel if save_load_scene != null else null
	if load_panel == null:
		stub_missing.append("020_load (scene missing)")
		menu.queue_free()
		return
	menu.add_child(load_panel)
	load_panel.open_load()
	await _shot("020_load")
	defects.append_array(auditor.audit_visible_tree(load_panel))
	load_panel.close()
	load_panel.queue_free()
	await host.get_tree().process_frame

	var save_panel: SaveLoadPanel = save_load_scene.instantiate() as SaveLoadPanel if save_load_scene != null else null
	if save_panel == null:
		stub_missing.append("030_save (scene missing)")
		menu.queue_free()
		return
	menu.add_child(save_panel)
	if save_panel.has_method("open_save"):
		save_panel.open_save()
	else:
		save_panel.open_load()
	await _shot("030_save")
	defects.append_array(auditor.audit_visible_tree(save_panel))
	save_panel.close()
	save_panel.queue_free()
	await host.get_tree().process_frame

	var pause: PauseMenu = fixtures.open_pause_menu(menu)
	if pause != null:
		await _shot("040_pause")
		defects.append_array(auditor.audit_visible_tree(pause))
		fixtures.free_ui(pause)
	else:
		stub_missing.append("040_pause (open failed)")
	await host.get_tree().process_frame
	menu.queue_free()
	await host.get_tree().process_frame


func _capture_apartment_phone_early() -> void:
	var started: bool = fixtures.prepare_new_game_world()
	if not started:
		stub_missing.append("100_apartment_spawn (start_new_game failed)")
		return
	_helpers = fixtures.make_helpers(host)
	if _helpers != null:
		_helpers.boost_discovery_stats()
	await capture.settle()

	await _shot("100_apartment_spawn")
	var looks: Array = [
		[0.0, 0.0, "101_apartment_forward"],
		[180.0, 0.0, "102_apartment_back"],
		[90.0, 0.0, "103_apartment_left"],
		[-90.0, 0.0, "104_apartment_right"],
		[45.0, -15.0, "105_apartment_bed"],
		[-45.0, 5.0, "106_apartment_door"],
		[0.0, -25.0, "107_apartment_down"],
		[135.0, 10.0, "108_apartment_corner"],
		[-135.0, -5.0, "109_apartment_walls"],
	]
	for entry: Variant in looks:
		var row: Array = entry as Array
		var yaw: float = float(row[0])
		var pitch: float = float(row[1])
		var sid: String = str(row[2])
		if fixtures.look_player(yaw, pitch):
			await _shot(sid)
		else:
			stub_missing.append("%s (look_player failed)" % sid)
	fixtures.look_player(0.0, 0.0)

	var world: Node = fixtures.get_world()
	var hud: Node = null
	if world != null and world.has_method("get_game_hud"):
		hud = world.call("get_game_hud") as Node
	if hud != null:
		await _shot("110_hud")
		defects.append_array(auditor.audit_visible_tree(hud))
	else:
		stub_missing.append("110_hud (GameHUD missing)")

	var prog: CanvasLayer = fixtures.open_progression_ui(host)
	if prog != null:
		await _shot("050_progression")
		defects.append_array(auditor.audit_visible_tree(prog))
		fixtures.free_ui(prog)
	else:
		stub_missing.append("050_progression (open failed)")
	await host.get_tree().process_frame

	await _capture_phone_tabs([
		[PhoneJournal.PhoneTab.STATUS, "900_phone_status"],
		[PhoneJournal.PhoneTab.STORY, "910_phone_story"],
		[PhoneJournal.PhoneTab.GIRLS, "920_phone_girls"],
		[PhoneJournal.PhoneTab.MEDIA, "930_phone_media"],
		[PhoneJournal.PhoneTab.CLONES, "940_phone_clones"],
	])


func _capture_phone_tabs(tab_shots: Array) -> void:
	var phone: PhoneJournal = fixtures.open_phone()
	if phone == null:
		for entry: Variant in tab_shots:
			var pair: Array = entry as Array
			stub_missing.append("%s (phone open failed)" % str(pair[1]))
		return
	for entry2: Variant in tab_shots:
		var pair2: Array = entry2 as Array
		var tab: PhoneJournal.PhoneTab = pair2[0] as PhoneJournal.PhoneTab
		var shot_id: String = str(pair2[1])
		fixtures.set_phone_tab(phone, tab)
		await _shot(shot_id)
	defects.append_array(auditor.audit_visible_tree(phone))
	if phone.has_method("close"):
		phone.close()


func _capture_critical_ui_shells_early() -> void:
	var actor: GirlActor = fixtures.open_discovery_modal(host)
	if actor != null:
		await _shot("120_discovery")
		var choice: Node = host.get_tree().root.find_child("DiscoveryChoiceUI", true, false)
		if choice == null:
			choice = host.find_child("DiscoveryChoiceUI", true, false)
		if choice != null:
			defects.append_array(auditor.audit_visible_tree(choice))
		fixtures.free_ui(actor)
		var tree: SceneTree = host.get_tree()
		if tree != null:
			var gd: Node = tree.root.get_node_or_null("/root/GirlDiscovery")
			if gd != null and gd.has_method("force_clear_attempt"):
				gd.call("force_clear_attempt")
	else:
		stub_missing.append("120_discovery (GirlActor interact failed)")
	await host.get_tree().process_frame

	var dating: CanvasLayer = fixtures.try_open_dating_ui(host)
	if dating != null:
		await _shot("130_dating_choice")
		defects.append_array(auditor.audit_visible_tree(dating))
		fixtures.free_ui(dating)
		var tree2: SceneTree = host.get_tree()
		if tree2 != null:
			var dc: Node = tree2.root.get_node_or_null("/root/DatingCore")
			if dc != null and dc.has_method("force_clear_session"):
				dc.call("force_clear_session")
	else:
		stub_missing.append("130_dating_choice (needs contact; deferred)")


func _drive_and_capture_world() -> void:
	if _helpers == null:
		stub_missing.append("world drive (helpers missing)")
		return

	# Unlock social locations via neighbor conquer if still prologue.
	if _helpers.stage() == int(GameTypes.GameStage.PROLOGUE):
		_helpers.conquer_girl(StoryIds.GIRL_NEIGHBOR, "gallery_neighbor_unlock")

	await _travel_shot(&"city_hub", "200_city")
	fixtures.look_player(0.0, 0.0)
	await _shot("201_city_forward")
	fixtures.look_player(90.0, 0.0)
	await _shot("202_city_left")
	fixtures.look_player(-90.0, 0.0)
	await _shot("203_city_right")
	fixtures.look_player(180.0, 5.0)
	await _shot("204_city_back")

	await _travel_shot(&"cafe", "300_cafe")
	await _travel_shot(&"gym", "400_gym")
	await _travel_shot(&"appearance_space", "410_appearance")

	# Rival choose UI after stage1 unlock path.
	if _helpers.stage() < int(GameTypes.GameStage.STAGE_1):
		_helpers.conquer_girl(StoryIds.GIRL_NEIGHBOR, "gallery_neighbor_rival_gate")
	var rival_ui: RivalEncounterUI = fixtures.open_rival_choose(host)
	if rival_ui != null:
		await _shot("420_rival_choose")
		defects.append_array(auditor.audit_visible_tree(rival_ui))
		fixtures.free_ui(rival_ui)
		var re: Node = host.get_node_or_null("/root/RivalEncounters")
		if re != null and re.has_method("force_clear_session"):
			re.call("force_clear_session")
	else:
		stub_missing.append("420_rival_choose (encounter start failed)")

	for kind: String in ["slap", "dance", "sigma", "money"]:
		var mg: Node = fixtures.instance_minigame_shell(host, kind)
		var sid: String = "430_minigame_%s" % kind
		if mg != null:
			await _shot(sid)
			defects.append_array(auditor.audit_visible_tree(mg))
			fixtures.free_ui(mg)
		else:
			stub_missing.append("%s (instance failed)" % sid)
		await host.get_tree().process_frame

	# Continue story for mine/media/lab/production/final.
	if _helpers.stage() < int(GameTypes.GameStage.STAGE_4):
		# Neighbor may already be conquered — drive remaining ladder.
		if _helpers.stage() == int(GameTypes.GameStage.STAGE_1):
			_helpers.win_rival(StoryIds.RIVAL_ACTRESS, "gallery_actress_rival")
			_helpers.conquer_girl(StoryIds.GIRL_ACTRESS, "gallery_actress")
		if _helpers.stage() == int(GameTypes.GameStage.STAGE_2):
			_helpers.win_rival(StoryIds.RIVAL_MINE_BOSS, "gallery_mine_rival")
			_helpers.conquer_girl(StoryIds.GIRL_MINE_BOSS, "gallery_mine")
		if _helpers.stage() == int(GameTypes.GameStage.STAGE_3):
			_helpers.win_rival(StoryIds.RIVAL_MAGAZINE_EDITOR, "gallery_editor_rival")
			_helpers.conquer_girl(StoryIds.GIRL_MAGAZINE_EDITOR, "gallery_editor")
		if _helpers.stage() < int(GameTypes.GameStage.STAGE_4):
			fixtures.gallery_drive_to_stage4(_helpers)

	fixtures.dismiss_blocking_overlays(host)
	await _travel_shot(&"salary_mine", "500_mine")
	# Media studio is appearance_space photo session visually.
	await _travel_shot(&"appearance_space", "510_media_studio")

	if _helpers.stage() < int(GameTypes.GameStage.STAGE_5):
		fixtures.gallery_drive_media_lab(_helpers)
	fixtures.dismiss_blocking_overlays(host)
	await host.get_tree().process_frame
	await _travel_shot(&"laboratory", "600_lab")

	var clone_ui: CanvasLayer = fixtures.open_clone_terminal(host)
	if clone_ui != null:
		await _shot("610_clone_terminal")
		defects.append_array(auditor.audit_visible_tree(clone_ui))
		fixtures.free_ui(clone_ui)
	else:
		stub_missing.append("610_clone_terminal (open failed)")

	if _helpers.stage() < int(GameTypes.GameStage.FINALE):
		fixtures.gallery_drive_stage6_finale(_helpers)
	fixtures.dismiss_blocking_overlays(host)
	await host.get_tree().process_frame

	await _travel_shot(&"production_area", "700_production")
	var global_ui: CanvasLayer = fixtures.open_global_terminal(host)
	if global_ui != null:
		await _shot("710_global_terminal")
		defects.append_array(auditor.audit_visible_tree(global_ui))
		fixtures.free_ui(global_ui)
	else:
		stub_missing.append("710_global_terminal (open failed)")

	await _travel_shot(&"final_location", "800_final")

	# Dating UI after contact exists.
	var dating2: CanvasLayer = fixtures.try_open_dating_ui(host)
	if dating2 != null:
		await _shot("130_dating_choice")
		defects.append_array(auditor.audit_visible_tree(dating2))
		fixtures.free_ui(dating2)
		var dc2: Node = host.get_node_or_null("/root/DatingCore")
		if dc2 != null and dc2.has_method("force_clear_session"):
			dc2.call("force_clear_session")


func _travel_shot(location_id: StringName, shot_id: String) -> void:
	var ok: bool = fixtures.travel_if_available(location_id)
	if ok:
		await capture.settle()
		await _shot(shot_id)
	else:
		stub_missing.append("%s (travel locked/unavailable: %s)" % [shot_id, String(location_id)])


func _capture_late_ui() -> void:
	if _helpers == null:
		return
	# Mature Stage6 / Finale phone coverage.
	if _helpers.stage() >= int(GameTypes.GameStage.STAGE_6):
		fixtures.travel_if_available(&"apartment")
		await _capture_phone_tabs([
			[PhoneJournal.PhoneTab.STATUS, "900_phone_status_stage6"],
			[PhoneJournal.PhoneTab.STORY, "901_phone_story_stage6"],
			[PhoneJournal.PhoneTab.GIRLS, "902_phone_girls_stage6"],
			[PhoneJournal.PhoneTab.MEDIA, "903_phone_media_stage6"],
			[PhoneJournal.PhoneTab.CLONES, "904_phone_clones_stage6"],
			[PhoneJournal.PhoneTab.STATUS, "905_phone_status_mature"],
			[PhoneJournal.PhoneTab.CLONES, "906_phone_clones_mature"],
		])
	else:
		stub_missing.append("900-906 stage6 phone (stage < STAGE_6)")

	await _capture_final_date_shell()


func _capture_final_date_shell() -> void:
	if _helpers == null or _helpers.stage() != int(GameTypes.GameStage.FINALE):
		stub_missing.append("810_final_date (not FINALE)")
		return
	var final_root: Node3D = Node3D.new()
	final_root.name = "gallery_final_location"
	host.add_child(final_root)
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
		final_root.add_child(m)
		i += 1
	var gate_b: StaticBody3D = StaticBody3D.new()
	gate_b.name = "final_gate_zone_b"
	gate_b.collision_layer = 1
	final_root.add_child(gate_b)
	var gate_c: StaticBody3D = StaticBody3D.new()
	gate_c.name = "final_gate_zone_c"
	gate_c.collision_layer = 1
	final_root.add_child(gate_c)
	var controller: FinalDateController = FinalDateController.new()
	controller.name = "FinalDateController"
	final_root.add_child(controller)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	_helpers.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)
	controller.set_test_auto_win_exhibition(true)
	if not controller.can_start_final_date() or not controller.start_final_date(null):
		stub_missing.append("810_final_date (start failed)")
		final_root.queue_free()
		return
	var ui: FinalDateUI = controller.get_ui()
	if ui != null and ui.is_open():
		await _shot("810_final_date")
		defects.append_array(auditor.audit_visible_tree(ui))
		if ui.get_mode() == "intro" or ui.get_mode() == "plain":
			ui.press_continue()
	# Fast-forward key choices toward ending for one ending frame if practical.
	controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
	if controller.has_method("select_event_option"):
		controller.select_event_option(&"aura")
	var ui2: FinalDateUI = controller.get_ui()
	if ui2 != null and ui2.is_open():
		if ui2.get_mode() == "plain":
			ui2.press_continue()
		await _shot("820_ending_or_final_progress")
	if controller.is_attempt_active():
		controller.abort_attempt_to_gameplay()
	controller.set_test_auto_win_exhibition(false)
	final_root.queue_free()
	await host.get_tree().process_frame


func _finalize_stubs() -> void:
	var wanted: Array[String] = [
		"000_main_menu", "010_settings", "020_load", "030_save", "040_pause",
		"050_progression", "100_apartment_spawn", "110_hud",
		"200_city", "300_cafe", "400_gym", "410_appearance",
		"500_mine", "510_media_studio", "600_lab", "700_production", "800_final",
		"610_clone_terminal", "710_global_terminal",
		"900_phone_status", "910_phone_story",
	]
	for shot_id: String in wanted:
		var found: bool = false
		for existing: String in shots:
			if existing.contains(shot_id):
				found = true
				break
		if found:
			continue
		var already_stub: bool = false
		for s: String in stub_missing:
			if s.begins_with(shot_id):
				already_stub = true
				break
		if not already_stub:
			stub_missing.append("%s (unmet)" % shot_id)
