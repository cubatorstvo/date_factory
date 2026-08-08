extends Node
## MODULE 22 Progression UI self-test — visibility, purchase path, costs unchanged.
## Headless: --path . --headless --quit-after 8000 res://ui/progression/test/progression_ui_self_test.tscn


var _failed: int = 0
var _passed: int = 0
var _ui: CanvasLayer = null
var _prog: Node = null
var _gs: Node = null


func _ready() -> void:
	_prog = get_node("/root/Progression")
	_gs = get_node("/root/GameState")
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		print("MODULE_22_PROGRESSION_UI_TEST: ALL PASS (%s)" % _passed)
	else:
		print("MODULE_22_PROGRESSION_UI_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_22_PROGRESSION_UI_TEST] FAIL: %s" % label)
		print("MODULE_22_PROGRESSION_UI_TEST FAIL: %s" % label)


func _run_all() -> void:
	_gs.call("reset_for_new_game")
	_test_costs_unchanged()
	_test_all_32_visible()
	_test_purchase_via_ui()
	_test_tab_headers()
	await _test_interactable_opens_selected_tab()
	_gs.call("reset_for_new_game")
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
		_ui = null


func _open_ui(ch: GameTypes.PlayerCharacteristic) -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
		_ui = null
	var script: Script = load("res://ui/progression/progression_ui.gd") as Script
	_ok(script != null, "progression_ui.gd loads")
	var layer := CanvasLayer.new()
	layer.set_script(script)
	add_child(layer)
	_ui = layer
	layer.call("open", null, Callable(), ch)


func _test_costs_unchanged() -> void:
	_gs.call("reset_for_new_game")
	var expected: Array[int] = [1, 3, 9, 27, 81]
	for i in range(expected.size()):
		var cost: int = int(_prog.call("get_next_perk_cost"))
		_ok(cost == expected[i], "cost[%s] == %s (got %s)" % [i, expected[i], cost])
		if i == 0:
			_gs.call("add_experience", 1)
			_ok(int(_prog.call("purchase_perk", PerkIds.MUSCLE_NO_WARMUP)) == 0, "seed buy for cost ladder")
		elif i == 1:
			_gs.call("add_experience", 10)
			_ok(int(_prog.call("purchase_perk", PerkIds.MUSCLE_TOUGH_CHEEK)) == 0, "seed buy 2")
		elif i == 2:
			_gs.call("add_experience", 100)
			_ok(int(_prog.call("purchase_perk", PerkIds.APPEARANCE_GOOD_PROFILE)) == 0, "seed buy 3")
		elif i == 3:
			_gs.call("add_experience", 1000)
			_ok(int(_prog.call("purchase_perk", PerkIds.CAPITAL_PAYABLE_INTENT)) == 0, "seed buy 4")
	_gs.call("reset_for_new_game")


func _test_all_32_visible() -> void:
	_gs.call("reset_for_new_game")
	var seen: Dictionary = {}
	for ch in [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]:
		_open_ui(ch)
		var ids: Array = _ui.call("get_visible_perk_ids") as Array
		_ok(ids.size() == 8, "tab %s shows 8 perks" % ch)
		for pid_variant in ids:
			var pid: StringName = pid_variant as StringName
			seen[String(pid)] = true
			var def: PerkDefinition = ContentDB.get_perk(pid)
			_ok(def != null, "visible perk exists %s" % String(pid))
			if def != null:
				_ok(def.display_name.strip_edges() != "", "display_name for %s" % String(pid))
				_ok(not String(pid) in def.display_name, "no raw id in name %s" % String(pid))
	_ok(seen.size() == 32, "all 32 perks visible across tabs (got %s)" % seen.size())


func _test_purchase_via_ui() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("add_experience", 1)
	_open_ui(GameTypes.PlayerCharacteristic.MUSCLE)
	var muscle_before: int = int(_gs.call("get_muscle"))
	var points_before: int = int(_gs.call("get_upgrade_points"))
	_ui.call("select_perk", PerkIds.MUSCLE_NO_WARMUP)
	_ui.call("purchase_selected")
	_ok(bool(_gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP)), "UI purchase owns perk")
	_ok(int(_gs.call("get_muscle")) == muscle_before + 1, "stat increments once via UI")
	_ok(int(_gs.call("get_upgrade_points")) == points_before - 1, "points spent via UI")
	_ok(int(_prog.call("get_next_perk_cost")) == 3, "next cost 3 after UI buy")
	# Duplicate click must not double-increment.
	_ui.call("select_perk", PerkIds.MUSCLE_NO_WARMUP)
	_ui.call("purchase_selected")
	_ok(int(_gs.call("get_muscle")) == muscle_before + 1, "no double stat on owned perk")


func _test_tab_headers() -> void:
	_open_ui(GameTypes.PlayerCharacteristic.AURA)
	var selected: int = int(_ui.call("get_selected_characteristic"))
	_ok(selected == int(GameTypes.PlayerCharacteristic.AURA), "opens on AURA tab")
	_ui.call("select_characteristic", GameTypes.PlayerCharacteristic.CAPITAL)
	selected = int(_ui.call("get_selected_characteristic"))
	_ok(selected == int(GameTypes.PlayerCharacteristic.CAPITAL), "tab switch to CAPITAL")
	var ids: Array = _ui.call("get_visible_perk_ids") as Array
	_ok(ids.size() == 8, "CAPITAL tab still 8 nodes")


func _test_interactable_opens_selected_tab() -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
		_ui = null
	var station := ProgressionInteractable.new()
	station.characteristic = GameTypes.PlayerCharacteristic.APPEARANCE
	station.prompt_text = "Внешность"
	add_child(station)
	station.call("_open_modal", null)
	await get_tree().process_frame
	var modal: CanvasLayer = station.get_node_or_null("ProgressionUI") as CanvasLayer
	_ok(modal != null, "interactable spawns ProgressionUI")
	if modal != null:
		var sel: int = int(modal.call("get_selected_characteristic"))
		_ok(sel == int(GameTypes.PlayerCharacteristic.APPEARANCE), "interactable opens APPEARANCE tab")
		modal.call("close")
	station.queue_free()
