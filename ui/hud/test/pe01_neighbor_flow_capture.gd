extends Node
## Windowed capture: real Neighbor interact → НОМЕР ПОЛУЧЕН → HUD asserts + PNGs.


const OUT_DIR: String = "res://tmp/px_pass_01/evidence/PE01_fix2"
const USER_OUT_DIR: String = "user://pe01_fix2_capture"


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		_fail("World missing")
		_finish()
		return
	if world.has_method("set_auto_reset_on_state_reset_for_test"):
		world.call("set_auto_reset_on_state_reset_for_test", false)
	var boot: Variant = world.call("boot_from_main")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(int(boot) == int(WorldTypes.WorldTravelResult.SUCCESS), "boot apartment")
	var hud: GameHUD = world.call("get_game_hud") as GameHUD
	var player: PlayerController = world.call("get_player") as PlayerController
	_ok(hud != null and player != null, "hud+player")
	if hud == null or player == null:
		_finish()
		return
	# Fresh onboarding visible.
	await get_tree().process_frame
	await _capture("01_new_game_first_frame.png")
	var obj0: Label = _find_label(hud, "ObjectiveBody")
	_ok(obj0 != null and obj0.text == "Познакомься с соседкой.", "start objective meet Neighbor")
	var panel0: PanelContainer = _find_panel(hud, "TutorialPanel")
	_ok(panel0 != null and panel0.visible, "start controls card visible")

	var neighbor: Area3D = _find_neighbor()
	_ok(neighbor != null, "Neighbor actor present")
	if neighbor == null:
		_finish()
		return
	_face_target(player, neighbor)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Match C/D: player already moved/looked before Neighbor E.
	hud.set("_evidence_moved", true)
	hud.set("_evidence_looked", true)
	hud.call("_refresh_controls_card")
	await get_tree().process_frame
	player.enter_gameplay()
	var can: bool = bool(neighbor.call("can_interact", player))
	_ok(can, "Neighbor can_interact")
	if can:
		# Production order: teaching signal, then Interactable.interact (opens modal).
		player.interaction_succeeded.emit(neighbor)
		neighbor.call("interact", player)
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture("09_neighbor_dialogue.png")

	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	_ok(gd != null and bool(gd.call("has_active_attempt")), "discovery attempt active")
	var approach_id: StringName = _first_available_approach(gd)
	_ok(String(approach_id) != "", "available approach")
	if String(approach_id) != "":
		# Prefer pressing the real choice button (full actor banner path).
		var pressed: bool = _press_first_discovery_choice(neighbor)
		if not pressed:
			var result: Dictionary = gd.call("select_approach", approach_id) as Dictionary
			_ok(str(result.get("reason", "")) == "SUCCESS", "approach SUCCESS / number")
			_close_discovery_ui(neighbor)
		else:
			await get_tree().process_frame
			await get_tree().process_frame
			await _capture("09b_number_received_modal.png")
			_press_ok_banner(neighbor)
		if player.get_control_mode() != PlayerController.ControlMode.GAMEPLAY:
			player.enter_gameplay()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture("10_after_number_received.png")

	var gs: Node = get_node_or_null("/root/GameState")
	_ok(gs != null and bool(gs.call("has_girl_contact", StoryIds.GIRL_NEIGHBOR)), "contact granted")
	var obj1: Label = _find_label(hud, "ObjectiveBody")
	_ok(
		obj1 != null and obj1.text == "Следующее свидание: доступно",
		"objective after number (got %s)" % (obj1.text if obj1 else "null")
	)
	var panel1: PanelContainer = _find_panel(hud, "TutorialPanel")
	var lab1: Label = _find_label(panel1, "TutorialLabel") if panel1 != null else null
	var e_lingers: bool = lab1 != null and lab1.text.contains("E — взаимодействие")
	_ok(panel1 == null or not panel1.visible or not e_lingers, "E teaching cleared after interact")
	# If move/look not evidenced in this harness, force complete check via interact alone:
	# interact must at least remove the E line when card still showing partial teaching.
	if panel1 != null and panel1.visible and lab1 != null:
		_ok(not lab1.text.contains("E — взаимодействие"), "no generic E line after success")
	_finish()


func _first_available_approach(gd: Node) -> StringName:
	if gd == null:
		return &""
	var def: GirlDefinition = gd.call("get_girl_definition", StoryIds.GIRL_NEIGHBOR) as GirlDefinition
	if def == null:
		return &""
	var situation: DiscoverySituationDefinition = gd.call(
		"get_discovery_situation", def.discovery_situation_id
	) as DiscoverySituationDefinition
	if situation == null:
		return &""
	var gs: Node = get_node_or_null("/root/GameState")
	for approach in situation.approaches:
		if approach == null:
			continue
		if bool(gd.call("is_approach_available", approach, gs)):
			return approach.id as StringName
	if not situation.approaches.is_empty() and situation.approaches[0] != null:
		return situation.approaches[0].id as StringName
	return &""


func _press_first_discovery_choice(neighbor: Node) -> bool:
	var layer: Node = neighbor.get_node_or_null("DiscoveryChoiceUI")
	if layer == null:
		return false
	var buttons: Array[Button] = []
	_collect_buttons(layer, buttons)
	for btn in buttons:
		if btn == null or btn.disabled:
			continue
		if btn.text == "Отмена" or btn.text == "OK" or btn.text == "Закрыть":
			continue
		btn.pressed.emit()
		return true
	return false


func _press_ok_banner(neighbor: Node) -> void:
	var buttons: Array[Button] = []
	_collect_buttons(neighbor, buttons)
	for btn in buttons:
		if btn != null and btn.text == "OK":
			btn.pressed.emit()
			return
	_close_discovery_ui(neighbor)


func _collect_buttons(root: Node, out: Array[Button]) -> void:
	if root == null:
		return
	if root is Button:
		out.append(root as Button)
	for child in root.get_children():
		_collect_buttons(child, out)


func _close_discovery_ui(neighbor: Node) -> void:
	if neighbor == null:
		return
	for child in neighbor.get_children():
		if child is CanvasLayer:
			var n: String = String(child.name)
			if n.contains("Discovery") or n.contains("Result") or n.contains("Choice") or n.contains("Banner"):
				child.queue_free()
	# Also free anonymous result layers.
	for child2 in neighbor.get_children():
		if child2 is CanvasLayer and child2 != neighbor.get_node_or_null("FpsHud"):
			var layer: CanvasLayer = child2 as CanvasLayer
			if layer.layer >= 20:
				layer.queue_free()


func _find_neighbor() -> Area3D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		if n is Area3D and n.has_method("get_interaction_prompt"):
			var gid: Variant = n.get("girl_id")
			if gid != null and StringName(str(gid)) == StoryIds.GIRL_NEIGHBOR:
				return n as Area3D
		for c in n.get_children():
			stack.append(c)
	return null


func _face_target(player: PlayerController, target: Node3D) -> void:
	var from: Vector3 = player.global_position
	var to: Vector3 = target.global_position
	var flat: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	if flat.length_squared() < 0.0001:
		return
	# Stand a short distance in front.
	var dir: Vector3 = flat.normalized()
	player.global_position = to - dir * 1.35 + Vector3(0.0, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	player.look_at(Vector3(to.x, player.global_position.y, to.z), Vector3.UP)
	# Align camera pitch roughly level.
	var pivot: Node3D = player.get_node_or_null("CameraPivot") as Node3D
	if pivot != null:
		pivot.rotation.x = 0.0


func _capture(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_fail("viewport texture missing for %s" % filename)
		return
	var img: Image = tex.get_image()
	if img == null:
		_fail("image missing for %s" % filename)
		return
	var abs_out: String = ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, filename])
	var err: Error = img.save_png(abs_out)
	_ok(err == OK, "saved %s" % filename)
	print("CAPTURE %s err=%s" % [abs_out, error_string(err)])


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
		print("PE01_NEIGHBOR_FLOW_CAPTURE_PASSED passed=%d" % _passed)
	else:
		print("PE01_NEIGHBOR_FLOW_CAPTURE_FAILED failed=%d passed=%d" % [_failed, _passed])
	await get_tree().process_frame
	get_tree().quit(_failed)
