extends Node
## MODULE 19 CloneVisualizationController self-test.
## Run: res://game/clone_visualization/test/clone_visualization_test.tscn


const MAX_ACTORS: int = 27
const MASS_INTERVAL_FASTER: float = 0.75
const LABEL_PRODUCTION_READY: String = "КЛОН ГОТОВ"
const DATE_SCENE_LABELS: Array[String] = [
	"ИДЁТ СВИДАНИЕ",
	"КЛОН ОБЪЯСНЯЕТ СВОЮ СИСТЕМУ",
	"НЕОЖИДАННО УСПЕШНО",
	"ОБА СДЕЛАЛИ ВИД, ЧТО ТАК И БЫЛО",
]

var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _ci: Node = null
var _fc: Node = null
var _ctrl: Node = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_ci = get_node("/root/CloneIncremental")
	_fc = get_node("/root/FirstClone")
	_ctrl = get_node_or_null("CloneVisualizationController")
	if _ctrl == null:
		var ctrl_script: Script = load("res://game/clone_visualization/clone_visualization_controller.gd") as Script
		_ctrl = Node3D.new()
		_ctrl.set_script(ctrl_script)
		_ctrl.name = "CloneVisualizationController"
		add_child(_ctrl)
	await get_tree().process_frame
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	await _run_all()
	if _failed == 0:
		print("MODULE_19_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_19_TEST PASS: %s" % label)
	else:
		print("MODULE_19_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_19_TEST] FAIL: %s" % label)
		print("MODULE_19_TEST FAIL: %s" % label)


func _c(method: StringName, args: Array = []) -> Variant:
	return _ctrl.callv(method, args)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	await get_tree().process_frame
	_c(&"refresh_from_counts")
	await get_tree().process_frame


func _set_clones(total: int, working: int, dating: int) -> void:
	_gs.call("set_clone_counts", total, working, dating)
	_c(&"refresh_from_counts")
	await get_tree().process_frame


func _run_all() -> void:
	await _test_zero_counts()
	await _test_dating_scaling()
	await _test_room_close_order()
	await _test_work_scaling()
	await _test_free_scaling()
	await _test_external_math()
	await _test_actor_budget()
	await _test_scene_cycle_no_mutation()
	await _test_work_tween_no_money()
	await _test_mass_no_mutation()
	await _test_production_feedback()
	await _test_first_clone_suppress()
	await _test_reset_clears()
	await _test_no_gamestate_mutation_api()


func _test_zero_counts() -> void:
	await _reset()
	_ok(int(_c(&"get_visible_dating")) == 0, "zero dating rooms")
	_ok(int(_c(&"get_visible_work")) == 0, "zero work actors")
	_ok(int(_c(&"get_visible_free")) == 0, "zero free actors")
	_ok(int(_c(&"get_external_total")) == 0, "zero external")
	_ok(not bool(_c(&"is_room_active", [1])), "slot01 inactive at zero")


func _test_dating_scaling() -> void:
	await _reset()
	var cases: Array = [
		[0, 0, 0],
		[1, 1, 0],
		[5, 5, 0],
		[10, 10, 0],
		[11, 10, 1],
		[100, 10, 90],
	]
	for c in cases:
		var dating: int = int(c[0])
		var expect_vis: int = int(c[1])
		var expect_ext: int = int(c[2])
		await _set_clones(dating, 0, dating)
		_ok(int(_c(&"get_visible_dating")) == expect_vis, "dating%d visible=%d" % [dating, expect_vis])
		_ok(int(_c(&"get_external_dating")) == expect_ext, "dating%d external=%d" % [dating, expect_ext])
		for slot in range(1, 11):
			var should: bool = slot <= expect_vis
			_ok(bool(_c(&"is_room_active", [slot])) == should, "dating%d slot%02d active=%s" % [dating, slot, should])
		if dating >= 1:
			var room: Node = _c(&"get_room", [1]) as Node
			var clone_actor: Node = null
			var girl_actor: Node = null
			if room != null and room.has_method("get_clone_actor"):
				clone_actor = room.call("get_clone_actor") as Node
			if room != null and room.has_method("get_girl_actor"):
				girl_actor = room.call("get_girl_actor") as Node
			_ok(room != null and clone_actor != null, "dating%d slot01 has clone" % dating)
			_ok(room != null and girl_actor != null, "dating%d slot01 has anon girl" % dating)
			if girl_actor != null and girl_actor.has_method("get_character_actor"):
				var girl_char: Node = girl_actor.call("get_character_actor") as Node
				var girl_script_path: String = ""
				if girl_char != null and girl_char.get_script() != null:
					girl_script_path = String((girl_char.get_script() as Script).resource_path)
				_ok(
					girl_char != null and not girl_script_path.ends_with("girl_actor.gd"),
					"dating%d girl is not GirlActor" % dating
				)


func _test_room_close_order() -> void:
	await _reset()
	await _set_clones(7, 0, 7)
	for slot in range(1, 8):
		_ok(bool(_c(&"is_room_active", [slot])), "close-order open slot%02d" % slot)
	await _set_clones(3, 0, 3)
	for slot in range(1, 4):
		_ok(bool(_c(&"is_room_active", [slot])), "close-order keep slot%02d" % slot)
	for slot in range(4, 8):
		_ok(not bool(_c(&"is_room_active", [slot])), "close-order close slot%02d" % slot)


func _test_work_scaling() -> void:
	await _reset()
	var cases: Array = [
		[0, 0, 0],
		[1, 1, 0],
		[3, 3, 0],
		[4, 3, 1],
		[100, 3, 97],
	]
	for c in cases:
		var working: int = int(c[0])
		var total: int = working
		await _set_clones(total, working, 0)
		_ok(int(_c(&"get_visible_work")) == int(c[1]), "work%d visible=%d" % [working, int(c[1])])
		_ok(int(_c(&"get_external_work")) == int(c[2]), "work%d external=%d" % [working, int(c[2])])


func _test_free_scaling() -> void:
	await _reset()
	var cases: Array = [
		[0, 0, 0],
		[1, 1, 0],
		[2, 2, 0],
		[3, 2, 1],
	]
	for c in cases:
		var free_n: int = int(c[0])
		await _set_clones(free_n, 0, 0)
		_ok(int(_c(&"get_visible_free")) == int(c[1]), "free%d visible=%d" % [free_n, int(c[1])])
		_ok(int(_c(&"get_external_free")) == int(c[2]), "free%d external=%d" % [free_n, int(c[2])])


func _test_external_math() -> void:
	await _reset()
	await _set_clones(20, 5, 12)
	_ok(int(_c(&"get_visible_dating")) == 10, "external map dating visible 10")
	_ok(int(_c(&"get_visible_work")) == 3, "external map work visible 3")
	_ok(int(_c(&"get_visible_free")) == 2, "external map free visible 2")
	_ok(int(_c(&"get_external_dating")) == 2, "external dating 2")
	_ok(int(_c(&"get_external_work")) == 2, "external work 2")
	_ok(int(_c(&"get_external_free")) == 1, "external free 1")
	_ok(int(_c(&"get_external_total")) == 5, "external total 5")
	var ext_label: String = str(_c(&"get_external_label_text"))
	_ok(ext_label.contains("ВНЕШНИЕ ПЛОЩАДКИ"), "external label title")
	_ok(ext_label.contains("Работа: 2"), "external label work breakdown")
	_ok(ext_label.contains("Свидания: 2"), "external label dating breakdown")
	_ok(ext_label.contains("Ожидают: 1"), "external label free breakdown")
	_ok(not ext_label.contains("ВНЕШНИЙ ПОТОК"), "external label not old total-only prefix")


func _test_actor_budget() -> void:
	await _reset()
	await _set_clones(10000, 4000, 5000)
	await get_tree().process_frame
	var actors: int = int(_c(&"count_presentation_character_actors"))
	_ok(actors <= MAX_ACTORS, "actor budget <=27 got=%d" % actors)
	_c(&"advance_mass_flow_for_test")
	await get_tree().create_timer(0.05).timeout
	_c(&"advance_mass_flow_for_test")
	await get_tree().create_timer(0.05).timeout
	var actors2: int = int(_c(&"count_presentation_character_actors"))
	_ok(actors2 <= MAX_ACTORS, "actor budget with mass <=27 got=%d" % actors2)
	_ok(is_equal_approx(float(_c(&"get_mass_interval")), MASS_INTERVAL_FASTER), "mass interval faster at huge external")


func _test_scene_cycle_no_mutation() -> void:
	await _reset()
	await _set_clones(5, 0, 5)
	var money0: int = int(_gs.call("get_money"))
	var xp0: int = int(_gs.call("get_experience"))
	var total0: int = int(_gs.call("get_total_clones"))
	var dating0: int = int(_gs.call("get_clones_dating"))
	var cycle0: int = int(_c(&"get_global_scene_cycle"))
	_c(&"advance_date_scenes_for_test", [8])
	await get_tree().process_frame
	_ok(int(_c(&"get_global_scene_cycle")) == cycle0 + 8, "scene cycle advanced")
	var scene1: int = int(_c(&"get_room_scene_index", [1]))
	var expect1: int = (int(_c(&"get_global_scene_cycle")) + 1) % 4
	_ok(scene1 == expect1, "slot01 scene offset")
	var room: Node = _c(&"get_room", [1]) as Node
	var status: String = ""
	if room != null and room.has_method("get_status_text"):
		status = str(room.call("get_status_text"))
	_ok(status == DATE_SCENE_LABELS[scene1], "slot01 caption")
	_ok(int(_gs.call("get_money")) == money0, "cycle money unchanged")
	_ok(int(_gs.call("get_experience")) == xp0, "cycle xp unchanged")
	_ok(int(_gs.call("get_total_clones")) == total0, "cycle total unchanged")
	_ok(int(_gs.call("get_clones_dating")) == dating0, "cycle dating unchanged")


func _test_work_tween_no_money() -> void:
	await _reset()
	await _set_clones(3, 3, 0)
	var money0: int = int(_gs.call("get_money"))
	_c(&"advance_work_departure_for_test")
	await get_tree().create_timer(0.2).timeout
	_ok(int(_gs.call("get_money")) == money0, "work tween money unchanged")


func _test_mass_no_mutation() -> void:
	await _reset()
	await _set_clones(30, 8, 17)
	var total0: int = int(_gs.call("get_total_clones"))
	var working0: int = int(_gs.call("get_clones_working"))
	var dating0: int = int(_gs.call("get_clones_dating"))
	_c(&"advance_mass_flow_for_test")
	await get_tree().create_timer(0.2).timeout
	_ok(int(_gs.call("get_total_clones")) == total0, "mass total unchanged")
	_ok(int(_gs.call("get_clones_working")) == working0, "mass working unchanged")
	_ok(int(_gs.call("get_clones_dating")) == dating0, "mass dating unchanged")


func _test_production_feedback() -> void:
	await _reset()
	await _set_clones(1, 1, 0)
	var before: int = int(_c(&"get_visible_work"))
	_ci.emit_signal("clone_produced", 2)
	await get_tree().process_frame
	_ok(
		bool(_c(&"is_production_feedback_active"))
		or str(_c(&"get_production_feedback_text")) == LABEL_PRODUCTION_READY,
		"production feedback shown"
	)
	_ok(int(_c(&"get_visible_work")) == before, "production pulse does not local-increment")
	_ok(int(_gs.call("get_total_clones")) == 1, "production pulse GameState total unchanged")


func _test_first_clone_suppress() -> void:
	await _reset()
	var world: Node = get_node_or_null("/root/World")
	if world != null:
		world.set("current_location_id", &"laboratory")
	await _set_clones(1, 1, 0)
	_fc.call("reconstruct_representative")
	await get_tree().process_frame
	var rep: Node = _fc.call("get_representative_actor") as Node
	_ok(rep == null or not is_instance_valid(rep), "FirstClone suppressed with controller")
	var saved_parent: Node = _ctrl.get_parent()
	saved_parent.remove_child(_ctrl)
	await get_tree().process_frame
	_fc.call("reconstruct_representative")
	await get_tree().process_frame
	var rep2: Node = _fc.call("get_representative_actor") as Node
	_ok(rep2 != null and is_instance_valid(rep2), "FirstClone fallback without controller")
	saved_parent.add_child(_ctrl)
	_c(&"ensure_active")
	await get_tree().process_frame
	_fc.call("reconstruct_representative")
	await get_tree().process_frame
	var rep3: Node = _fc.call("get_representative_actor") as Node
	_ok(rep3 == null or not is_instance_valid(rep3), "FirstClone re-suppressed after controller return")


func _test_reset_clears() -> void:
	await _set_clones(12, 3, 8)
	_ok(int(_c(&"get_visible_dating")) > 0, "pre-reset has dating")
	_gs.call("reset_for_new_game")
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	await get_tree().process_frame
	_c(&"refresh_from_counts")
	await get_tree().process_frame
	_ok(int(_c(&"get_visible_dating")) == 0, "reset clears dating")
	_ok(int(_c(&"get_visible_work")) == 0, "reset clears work")
	_ok(int(_c(&"get_visible_free")) == 0, "reset clears free")
	_ok(int(_c(&"get_external_total")) == 0, "reset clears external")


func _test_no_gamestate_mutation_api() -> void:
	var paths: Array[String] = [
		"res://game/clone_visualization/clone_visualization_controller.gd",
		"res://game/clone_visualization/dating_room_visual.gd",
		"res://game/clone_visualization/clone_visual_actor.gd",
		"res://game/clone_visualization/clone_visualization_types.gd",
	]
	var banned: Array[String] = [
		"set_clone_counts",
		"add_money",
		"add_experience",
		"set_late_rates",
		"fulfill",
	]
	var clean: bool = true
	for path in paths:
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			clean = false
			continue
		var text: String = f.get_as_text()
		f.close()
		for token in banned:
			if text.contains(token):
				clean = false
				push_error("[MODULE_19_TEST] banned token %s in %s" % [token, path])
	_ok(clean, "viz scripts never call GameState mutators")
