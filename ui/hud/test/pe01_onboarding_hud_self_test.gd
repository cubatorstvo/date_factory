extends Node
## PE01 onboarding: controls evidence, interact-clear, post-Neighbor objective.


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_test_tutorial_prompt()
	await _test_prompt_format_helpers()
	await _test_hud_boot_objective_and_controls()
	await _test_look_gate_after_presentation()
	await _test_interact_clear_and_post_contact_objective()
	await _finish()


func _test_tutorial_prompt() -> void:
	var tp := TutorialPrompt.new()
	tp.request(TutorialPrompt.PromptId.FIRST_MOVEMENT)
	var payload: Dictionary = tp.begin_next()
	_ok(bool(payload.get("evidence_based", false)), "FIRST_MOVEMENT evidence-based")
	_ok(float(payload.get("seconds", -1.0)) == 0.0, "FIRST_MOVEMENT no timeout")
	_ok(not tp.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT), "not seen until complete")
	var text: String = tp.controls_card_text(true, true, false)
	_ok(text == "E — взаимодействие", "progressive E-only teaching")
	tp.complete_active()
	_ok(tp.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT), "seen after complete")
	tp.request(TutorialPrompt.PromptId.FIRST_MOVEMENT)
	_ok(not tp.has_pending(), "seen blocks re-request")


func _test_prompt_format_helpers() -> void:
	var packed: PackedScene = load("res://characters/player/player.tscn") as PackedScene
	if packed == null:
		_fail("player.tscn missing")
		return
	var player: PlayerController = packed.instantiate() as PlayerController
	add_child(player)
	await get_tree().process_frame
	var formatted: String = str(player.call("_format_player_prompt", "[E] Осмотреть", null))
	_ok(formatted == "E — Осмотреть", "semantic prompt format (got %s)" % formatted)
	var debug_lab: Label = player.get_node_or_null("FpsHud/DebugLabel") as Label
	_ok(debug_lab != null and not debug_lab.visible and debug_lab.text == "", "debug overlay hidden")
	player.queue_free()


func _test_hud_boot_objective_and_controls() -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	# Isolate from leftover user:// tutorial_seen written by other PE01 runs.
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss != null and ss.has_method("set_tutorial_seen_ids"):
		ss.call("set_tutorial_seen_ids", [])
		if ss.has_method("save_settings"):
			ss.call("save_settings")
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		_fail("World missing")
		return
	if world.has_method("set_auto_reset_on_state_reset_for_test"):
		world.call("set_auto_reset_on_state_reset_for_test", false)
	var boot: Variant = world.call("boot_from_main")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(int(boot) == int(WorldTypes.WorldTravelResult.SUCCESS), "boot apartment")
	var hud: GameHUD = world.call("get_game_hud") as GameHUD
	_ok(hud != null, "GameHUD present")
	if hud == null:
		return
	var tp0: TutorialPrompt = hud.call("get_tutorial_prompt") as TutorialPrompt
	if tp0 != null:
		tp0.reset_runtime()
	hud.set("_evidence_moved", false)
	hud.set("_evidence_looked", false)
	hud.set("_evidence_interacted", false)
	hud.set("_tutorial_evidence_based", false)
	hud.call("_request_controls_onboarding")
	hud.call("_try_show_next_tutorial")
	await get_tree().process_frame
	await get_tree().process_frame
	var obj: Label = _find_label(hud, "ObjectiveBody")
	_ok(obj != null and obj.text == "Познакомься с соседкой.", "stage0 objective fallback")
	var title: Label = _find_label(hud, "ObjectiveTitle")
	_ok(title != null and title.text == "ЦЕЛЬ", "objective title")
	var panel: PanelContainer = _find_panel(hud, "TutorialPanel")
	_ok(panel != null and panel.visible, "controls card visible on fresh boot")
	if panel != null:
		_ok(panel.size.x >= 200.0 and panel.size.y >= 40.0, "controls card has on-screen size")
		var lab: Label = _find_label(panel, "TutorialLabel")
		_ok(lab != null and lab.text.contains("WASD"), "controls card teaches WASD")
		_ok(lab != null and lab.text.contains("Мышь"), "controls card teaches mouse")
		_ok(lab != null and lab.text.contains("E —"), "controls card teaches E")
		# First-frame guarantee: all three lines present together.
		_ok(
			lab != null
			and lab.text.contains("WASD")
			and lab.text.contains("Мышь")
			and lab.text.contains("E —"),
			"first-frame card has WASD+Мышь+E together"
		)


func _test_look_gate_after_presentation() -> void:
	var world: Node = get_node_or_null("/root/World")
	var hud: GameHUD = world.call("get_game_hud") as GameHUD if world != null else null
	var player: PlayerController = world.call("get_player") as PlayerController if world != null else null
	if hud == null or player == null:
		_fail("hud/player missing for look-gate proof")
		return
	player.enter_gameplay()
	hud.set_title_suppressed(false)
	# Fresh FIRST_MOVEMENT presentation (clear any in-flight active prompt).
	var tp: TutorialPrompt = hud.call("get_tutorial_prompt") as TutorialPrompt
	if tp != null:
		tp.reset_runtime()
	hud.set("_evidence_moved", false)
	hud.set("_evidence_looked", false)
	hud.set("_evidence_interacted", false)
	hud.set("_tutorial_evidence_based", false)
	hud.set("_look_evidence_armed", false)
	hud.set("_look_accum", 0.0)
	var panel_reset: PanelContainer = _find_panel(hud, "TutorialPanel")
	if panel_reset != null:
		panel_reset.visible = false
	hud.call("_request_controls_onboarding")
	hud.call("_try_show_next_tutorial")
	await get_tree().process_frame
	var panel: PanelContainer = _find_panel(hud, "TutorialPanel")
	var lab: Label = _find_label(panel, "TutorialLabel") if panel != null else null
	_ok(panel != null and panel.visible, "look-gate card visible")
	_ok(lab != null and lab.text.contains("Мышь"), "look gate start still shows Мышь")
	_ok(bool(hud.get("_tutorial_evidence_based")), "evidence-based card active")
	# Immediate post-New-Game style motion must NOT clear Мышь (pre-arm / warp).
	hud.call("_apply_look_relative", Vector2(200, 80))
	hud.call("_apply_look_relative", Vector2(20, 20))
	await get_tree().process_frame
	lab = _find_label(panel, "TutorialLabel") if panel != null else null
	_ok(lab != null and lab.text.contains("Мышь"), "Мышь survives capture warp before arm")
	# After presentation delay, meaningful look removes only the mouse line.
	hud.set("_look_arm_after_msec", 0)
	hud.call("_update_look_evidence_arm")
	_ok(bool(hud.get("_look_evidence_armed")), "look evidence armed after presentation")
	hud.call("_apply_look_relative", Vector2(30, 25))
	hud.call("_apply_look_relative", Vector2(20, 10))
	await get_tree().process_frame
	lab = _find_label(_find_panel(hud, "TutorialPanel"), "TutorialLabel")
	_ok(bool(hud.get("_evidence_looked")), "look evidence flagged after meaningful motion")
	_ok(lab != null and not lab.text.contains("Мышь"), "meaningful look clears only Мышь")
	_ok(lab != null and lab.text.contains("WASD") and lab.text.contains("E —"), "WASD+E remain after look")


func _test_interact_clear_and_post_contact_objective() -> void:
	var world: Node = get_node_or_null("/root/World")
	var hud: GameHUD = world.call("get_game_hud") as GameHUD if world != null else null
	var player: PlayerController = world.call("get_player") as PlayerController if world != null else null
	if hud == null or player == null:
		_fail("hud/player missing for interact/objective proof")
		return
	# Prove move+look+interact evidence clears card, including Neighbor modal race.
	hud.set("_evidence_moved", true)
	hud.set("_evidence_looked", true)
	hud.set("_tutorial_evidence_based", true)
	var panel: PanelContainer = _find_panel(hud, "TutorialPanel")
	_ok(panel != null and panel.visible, "controls card still showing before interact proof")
	# Emit teaching success before modal (matches player.gd order), then open modal UI.
	player.interaction_succeeded.emit(null)
	await get_tree().process_frame
	player.enter_modal_ui()
	await get_tree().process_frame
	player.enter_gameplay()
	await get_tree().process_frame
	await get_tree().process_frame
	panel = _find_panel(hud, "TutorialPanel")
	_ok(panel != null and not panel.visible, "controls card cleared after successful interact")
	var tp: TutorialPrompt = hud.call("get_tutorial_prompt") as TutorialPrompt
	_ok(tp != null and tp.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT), "FIRST_MOVEMENT marked seen")

	# Post-Neighbor objective from GameState contact (Phone-canonical next date line).
	var obj: Label = _find_label(hud, "ObjectiveBody")
	_ok(obj != null and obj.text == "Познакомься с соседкой.", "pre-contact objective still meet Neighbor")
	var gs: Node = get_node_or_null("/root/GameState")
	_ok(gs != null and gs.has_method("add_girl_contact"), "GameState contact API")
	if gs != null:
		gs.call("add_girl_contact", StoryIds.GIRL_NEIGHBOR)
	await get_tree().process_frame
	obj = _find_label(hud, "ObjectiveBody")
	_ok(
		obj != null and obj.text == "Следующее свидание: доступно",
		"post-contact objective is Phone next-date line (got %s)" % (obj.text if obj else "null")
	)
	_ok(
		obj != null and obj.text != "Познакомься с соседкой.",
		"post-contact objective left Stage-0 meet fallback"
	)


func _find_label(root: Node, node_name: String) -> Label:
	if root == null:
		return null
	if root.name == node_name and root is Label:
		return root as Label
	for child in root.get_children():
		var found: Label = _find_label(child, node_name)
		if found != null:
			return found
	return null


func _find_panel(root: Node, node_name: String) -> PanelContainer:
	if root == null:
		return null
	if root.name == node_name and root is PanelContainer:
		return root as PanelContainer
	for child in root.get_children():
		var found: PanelContainer = _find_panel(child, node_name)
		if found != null:
			return found
	return null


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failed += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("PE01_ONBOARDING_HUD_SELF_TEST_PASSED passed=%d" % _passed)
	else:
		print("PE01_ONBOARDING_HUD_SELF_TEST_FAILED failed=%d passed=%d" % [_failed, _passed])
	await get_tree().process_frame
	get_tree().quit(_failed)
