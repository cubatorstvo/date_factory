extends Node
## MODULE 22 GameHUD smoke: one instance, resources, modal hide, travel no-dupe.


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
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
	var hud1: GameHUD = world.call("get_game_hud") as GameHUD
	_ok(hud1 != null, "get_game_hud non-null")
	var count1: int = _count_game_hud()
	_ok(count1 == 1, "exactly one GameHUD after boot (got %d)" % count1)
	var gs: Node = get_node("/root/GameState")
	gs.call("add_money", 12400)
	gs.call("add_authority", 3)
	gs.call("add_experience", 2)
	await get_tree().process_frame
	var money_lab: Label = hud1.get_node_or_null("ScaleRoot/GameplayRoot/ResourcePanel/VBoxContainer/MoneyLabel") as Label
	if money_lab == null:
		money_lab = _find_label(hud1, "MoneyLabel")
	var auth_lab: Label = _find_label(hud1, "AuthorityLabel")
	var xp_lab: Label = _find_label(hud1, "ExperienceLabel")
	var up_lab: Label = _find_label(hud1, "PointsLabel")
	_ok(money_lab != null and money_lab.text == "$ 12.4K", "money label compact (got %s)" % (money_lab.text if money_lab else "null"))
	_ok(auth_lab != null and auth_lab.text == "АВТОРИТЕТ 3", "authority label")
	_ok(xp_lab != null and xp_lab.text == "ОПЫТНОСТЬ 2", "experience label")
	_ok(up_lab != null and up_lab.text == "БАЛЛЫ 2", "points label")
	var gameplay_root: CanvasItem = hud1.get_node_or_null("ScaleRoot/GameplayRoot") as CanvasItem
	_ok(gameplay_root != null and gameplay_root.visible, "HUD visible in GAMEPLAY")
	var player: PlayerController = world.call("get_player") as PlayerController
	_ok(player != null, "player present")
	if player != null:
		player.enter_modal_ui()
		await get_tree().process_frame
		_ok(gameplay_root != null and not gameplay_root.visible, "HUD hidden in MODAL_UI")
		player.enter_gameplay()
		await get_tree().process_frame
		_ok(gameplay_root != null and gameplay_root.visible, "HUD visible again in GAMEPLAY")
	var travel: Variant = world.call("request_travel", &"apartment")
	await get_tree().process_frame
	var count2: int = _count_game_hud()
	_ok(count2 == 1, "exactly one GameHUD after travel (got %d)" % count2)
	var hud2: GameHUD = world.call("get_game_hud") as GameHUD
	_ok(hud1 == hud2 and is_instance_valid(hud1), "same GameHUD instance after travel")
	var phone: Node = world.call("get_phone_journal") as Node
	_ok(phone != null, "PhoneJournal still present")
	_finish()


func _count_game_hud() -> int:
	var n: int = 0
	var host: Node = get_tree().root.get_node_or_null("WorldHost")
	if host == null:
		return 0
	var ui: Node = host.get_node_or_null("PersistentUI")
	if ui == null:
		return 0
	for child in ui.get_children():
		if child is GameHUD or String(child.name) == "GameHUD":
			n += 1
	return n


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


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failed += 1
	push_error("[MODULE_22_HUD_SMOKE] FAIL: %s" % label)
	print("MODULE_22_HUD_SMOKE FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("MODULE_22_HUD_SMOKE: ALL PASS (%s)" % _passed)
	else:
		print("MODULE_22_HUD_SMOKE: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if _failed == 0 else 1)
