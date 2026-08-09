extends Node
## Windowed Title→New Game first-frame capture for PE01 mouse-line guarantee.


const OUT_DIR: String = "res://tmp/px_pass_01/evidence/PE01_fix3"


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss != null and ss.has_method("set_tutorial_seen_ids"):
		ss.call("set_tutorial_seen_ids", [])
		if ss.has_method("save_settings"):
			ss.call("save_settings")
	# Simulate Title → New Game: suppress, boot, then unsuppress + gameplay.
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		_fail("World missing")
		_finish()
		return
	if world.has_method("prepare_for_title"):
		world.call("prepare_for_title")
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	if world.has_method("set_auto_reset_on_state_reset_for_test"):
		world.call("set_auto_reset_on_state_reset_for_test", false)
	# Fresh new-game boot path.
	if world.has_method("begin_new_game_boot"):
		var travel: Variant = world.call("begin_new_game_boot")
		_ok(int(travel) == int(WorldTypes.WorldTravelResult.SUCCESS), "begin_new_game_boot")
	else:
		var boot: Variant = world.call("boot_from_main")
		_ok(int(boot) == int(WorldTypes.WorldTravelResult.SUCCESS), "boot_from_main")
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: GameHUD = world.call("get_game_hud") as GameHUD
	var player: PlayerController = world.call("get_player") as PlayerController
	_ok(hud != null and player != null, "hud+player")
	if hud == null or player == null:
		_finish()
		return
	hud.set_title_suppressed(true)
	await get_tree().process_frame
	# Transition artifacts: capture mouse + warp as New Game click would.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var warp := InputEventMouseMotion.new()
	warp.relative = Vector2(180, 40)
	hud.call("_unhandled_input", warp)
	hud.set_title_suppressed(false)
	player.enter_gameplay()
	hud.call("_request_controls_onboarding")
	hud.call("_try_show_next_tutorial")
	# More transition motion in the same frame window as first readable card.
	var jitter := InputEventMouseMotion.new()
	jitter.relative = Vector2(25, 15)
	hud.call("_unhandled_input", jitter)
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture("01_new_game_first_frame.png")
	var lab: Label = _find_label(_find_panel(hud, "TutorialPanel"), "TutorialLabel")
	_ok(lab != null and lab.text.contains("WASD"), "first frame WASD")
	_ok(lab != null and lab.text.contains("Мышь"), "first frame Мышь present")
	_ok(lab != null and lab.text.contains("E —"), "first frame E")
	_ok(
		lab != null
		and lab.text.contains("WASD")
		and lab.text.contains("Мышь")
		and lab.text.contains("E —"),
		"first frame has all three control lines"
	)
	_finish()


func _capture(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_fail("no viewport texture")
		return
	var img: Image = tex.get_image()
	if img == null:
		_fail("no image")
		return
	var path: String = ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, filename])
	var err: Error = img.save_png(path)
	_ok(err == OK, "saved %s" % filename)
	print("CAPTURE %s" % path)


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
		print("PE01_FIRST_FRAME_CAPTURE_PASSED passed=%d" % _passed)
	else:
		print("PE01_FIRST_FRAME_CAPTURE_FAILED failed=%d passed=%d" % [_failed, _passed])
	await get_tree().process_frame
	get_tree().quit(_failed)
