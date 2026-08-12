extends Node
## Focused state/core test for the morning tutorial prologue.

var _passed: int = 0
var _failed: int = 0
var _last_correction: String = ""


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await _run_all()
	await get_tree().process_frame
	await get_tree().process_frame
	print("MORNING_TUTORIAL_TEST passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	var gs: Node = get_node("/root/GameState")
	var story: Node = get_node("/root/Story")
	var world: Node = get_node("/root/World")
	var db: Node = get_node("/root/ContentDB")
	var dc: Node = get_node("/root/DatingCore")
	var relationships: Node = get_node("/root/Relationships")
	gs.call("reset_for_new_game")
	dc.call("force_clear_session")
	_ok(int(gs.call("get_money")) == 90, "new game starts with $90")
	var progress: StoryStageProgress = story.call("get_current_progress") as StoryStageProgress
	_ok(progress.objective_id == &"pick_up_card", "first objective is card pickup")
	var city_before: WorldAccessResult = world.call("get_location_access", &"city_hub") as WorldAccessResult
	_ok(city_before.status == WorldTypes.WorldAccessStatus.LOCKED_STORY, "city locked before card")
	gs.call("set_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED, true)
	progress = story.call("get_current_progress") as StoryStageProgress
	_ok(progress.objective_id == &"find_neighbor", "card advances to Neighbor objective")
	var city_after: WorldAccessResult = world.call("get_location_access", &"city_hub") as WorldAccessResult
	var cafe_after: WorldAccessResult = world.call("get_location_access", &"cafe") as WorldAccessResult
	_ok(city_after.status == WorldTypes.WorldAccessStatus.LOCKED_STORY, "city stays locked until SOCIAL_ACCESS")
	_ok(cafe_after.status == WorldTypes.WorldAccessStatus.LOCKED_STORY, "other social locations stay locked")
	gs.call("set_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE, true)
	gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_FOOD_READY, true)
	var snapshot: Dictionary = gs.call("export_save_state") as Dictionary
	gs.call("reset_for_new_game")
	_ok(not bool(gs.call("get_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED)), "reset clears card flag")
	_ok(bool(gs.call("restore_save_state", snapshot)), "mid-checklist save restores")
	_ok(bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_FOOD_READY)), "food checklist survives save")
	gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DRINK_READY, true)
	gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_OUTFIT_READY, true)
	progress = story.call("get_current_progress") as StoryStageProgress
	_ok(progress.objective_id == &"start_tutorial_date", "complete checklist unlocks tutorial table")
	var neighbor: GirlDefinition = db.call("get_girl", StoryIds.GIRL_NEIGHBOR) as GirlDefinition
	var actress: GirlDefinition = db.call("get_girl", StoryIds.GIRL_ACTRESS) as GirlDefinition
	_ok(neighbor != null and not neighbor.romance_available, "Neighbor is friend-only")
	_ok(actress != null and actress.required_experience == 3, "first real story girl needs three hearts")
	var availability: Dictionary = relationships.call(
		"get_date_availability",
		StoryIds.GIRL_NEIGHBOR,
	) as Dictionary
	_ok(
		availability.get("status", &"") == RelationshipTypes.AVAIL_NOT_ROMANCEABLE,
		"ordinary Neighbor dates are blocked",
	)
	if not dc.is_connected("tutorial_correction_presented", _on_correction):
		dc.connect("tutorial_correction_presented", _on_correction)
	var request := DatingStartRequest.new()
	request.girl_id = StoryIds.GIRL_NEIGHBOR
	request.location_id = &"apartment"
	request.greeting_ids = [&"dating_greeting_simple"]
	request.farewell_id = &"dating_farewell_early_common"
	request.forced_event_ids = NeighborTutorialCatalog.FORCED_EVENT_IDS.duplicate()
	request.tutorial_mode = true
	var start: Dictionary = dc.call("start_date", request) as Dictionary
	_ok(bool(start.get("ok", false)), "tutorial starts without romantic contact")
	if not bool(start.get("ok", false)):
		return
	var ui_packed: PackedScene = load("res://ui/dating/dating_ui.tscn") as PackedScene
	var ui: CanvasLayer = ui_packed.instantiate() as CanvasLayer
	add_child(ui)
	await get_tree().process_frame
	ui.call("open_for_active_date")
	var panel: PanelContainer = ui.get_node_or_null("Root/Panel") as PanelContainer
	var dim: ColorRect = ui.get_node_or_null("Root/Dim") as ColorRect
	var choices: VBoxContainer = ui.get_node_or_null(
		"Root/Panel/Margin/VBox/ChoiceScroll/Choices"
	) as VBoxContainer
	_ok(panel != null and panel.anchor_right <= 0.401, "dating panel leaves companion visible")
	_ok(dim != null and not dim.visible, "dating UI does not dim the world")
	_ok(choices != null and choices.get_child_count() == 1, "arrival exposes one compact action")
	var arrival_button: Button = choices.get_child(0) as Button
	_ok(arrival_button.text.begins_with("1 —"), "compact actions show number shortcuts")
	var advance_event: InputEventAction = InputEventAction.new()
	advance_event.action = &"interact"
	advance_event.pressed = true
	ui.call("_unhandled_input", advance_event)
	var session: DatingSession = dc.call("get_session") as DatingSession
	_ok(session.phase == DatingTypes.Phase.GREETING, "E advances compact arrival action")
	var first_choice: InputEventKey = InputEventKey.new()
	first_choice.keycode = KEY_1
	first_choice.pressed = true
	ui.call("_unhandled_input", first_choice)
	session = dc.call("get_session") as DatingSession
	_ok(session.phase == DatingTypes.Phase.CENTRAL_EVENT, "number shortcut selects greeting")
	ui.call("_unhandled_input", advance_event)
	session = dc.call("get_session") as DatingSession
	var selected_before_wheel: int = int(ui.get("_selected_choice_index"))
	var wheel_event: InputEventMouseButton = InputEventMouseButton.new()
	wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_event.pressed = true
	ui.call("_unhandled_input", wheel_event)
	_ok(int(ui.get("_selected_choice_index")) != selected_before_wheel, "wheel changes compact answer focus")
	var phase_before: DatingTypes.Phase = session.phase
	var money_before: int = int(gs.call("get_money"))
	var wrong: Dictionary = dc.call(
		"select_action",
		&"date_action_apartment_laminate_hopes",
	) as Dictionary
	session = dc.call("get_session") as DatingSession
	_ok(bool(wrong.get("tutorial_retry", false)), "wrong choice requests retry")
	_ok(session.phase == phase_before, "wrong choice keeps current phase")
	_ok(session.decision_records.is_empty(), "wrong choice creates no decision record")
	_ok(int(gs.call("get_money")) == money_before, "wrong choice spends no money")
	_ok(not _last_correction.is_empty(), "wrong choice has Neighbor explanation")
	dc.call("select_action", &"date_action_apartment_laminate_admit")
	dc.call("select_action", &"date_action_apartment_chair_give")
	dc.call("select_action", &"date_action_apartment_mug_simple")
	var finish: Dictionary = dc.call("select_action", &"date_action_farewell_walk") as Dictionary
	var result: DatingResult = finish.get("result") as DatingResult
	if result == null:
		session = dc.call("get_session") as DatingSession
		result = session.result
	_ok(result != null and result.tutorial_mode, "tutorial result is marked transient")
	_ok(result != null and result.date_delta == 5, "tutorial date finishes at +5")
	_ok(int(gs.call("get_experience")) == 0, "tutorial grants no conquered heart")
	_ok(int(gs.call("get_girl_relationship", StoryIds.GIRL_NEIGHBOR)) == 0, "Neighbor relationship stays zero")
	_ok(not bool(gs.call("is_girl_conquered", StoryIds.GIRL_NEIGHBOR)), "Neighbor is never conquered")
	dc.call("close_finished_date")
	ui.free()
	gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	await get_tree().process_frame
	_ok(int(gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_1), "tutorial completion advances to Stage 1")
	gs.call("add_girl_contact", StoryIds.GIRL_ACTRESS)
	var ordinary_request: DatingStartRequest = DatingStartRequest.new()
	ordinary_request.girl_id = StoryIds.GIRL_ACTRESS
	ordinary_request.location_id = actress.default_date_location_id
	ordinary_request.greeting_ids = actress.dating_greeting_ids.duplicate()
	ordinary_request.farewell_id = actress.dating_farewell_id
	var ordinary_start: Dictionary = dc.call("start_date", ordinary_request) as Dictionary
	_ok(bool(ordinary_start.get("ok", false)), "ordinary date starts after tutorial")
	if bool(ordinary_start.get("ok", false)):
		var ordinary_ui: CanvasLayer = ui_packed.instantiate() as CanvasLayer
		add_child(ordinary_ui)
		await get_tree().process_frame
		ordinary_ui.call("open_for_active_date")
		ordinary_ui.call("_unhandled_input", advance_event)
		var ordinary_session: DatingSession = dc.call("get_session") as DatingSession
		_ok(not ordinary_session.tutorial_mode, "ordinary compact date stays non-tutorial")
		_ok(ordinary_session.phase == DatingTypes.Phase.GREETING, "ordinary compact E advances arrival")
		ordinary_ui.free()
		dc.call("force_clear_session")
	_stop_test_audio()


func _stop_test_audio() -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio == null:
		return
	for child: Node in audio.find_children("*", "AudioStreamPlayer", true, false):
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player != null:
			player.stop()
			player.stream = null


func _on_correction(explanation: String) -> void:
	_last_correction = explanation


func _ok(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % label)
	else:
		_failed += 1
		push_error("FAIL: %s" % label)
