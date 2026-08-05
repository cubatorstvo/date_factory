class_name ReleaseTestHelpers
extends RefCounted
## Shared helpers for release smoke/full suites (production API wrappers).


var report: RefCounted
var seed_helper: RefCounted
var errors: PackedStringArray = PackedStringArray()
var hard_failed: bool = false


func setup(report_obj: RefCounted, seed_obj: RefCounted) -> void:
	report = report_obj
	seed_helper = seed_obj
	errors.clear()
	hard_failed = false


func game_node(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("Game")


func require(cond: bool, step_id: String, detail: String = "") -> bool:
	if hard_failed:
		return false
	report.record_step(step_id, cond, detail)
	if not cond:
		errors.append("%s%s" % [step_id, (": " + detail) if not detail.is_empty() else ""])
		hard_failed = true
		push_error("RELEASE_TEST_FAIL step=%s detail=%s" % [step_id, detail])
		return false
	print("RELEASE_TEST_STEP_OK %s%s" % [step_id, (" — " + detail) if not detail.is_empty() else ""])
	return true


func check(cond: bool, step_id: String, detail: String = "") -> bool:
	## Soft check: records failure but continues (smoke soft assertions).
	report.record_step(step_id, cond, detail)
	if not cond:
		errors.append("%s%s" % [step_id, (": " + detail) if not detail.is_empty() else ""])
		push_error("RELEASE_TEST_CHECK_FAIL step=%s detail=%s" % [step_id, detail])
		return false
	print("RELEASE_TEST_STEP_OK %s%s" % [step_id, (" — " + detail) if not detail.is_empty() else ""])
	return true


func critical_scene_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://scenes/boot/boot.tscn",
		"res://scenes/boot/main.tscn",
		"res://scenes/world/complex.tscn",
		"res://scenes/world/vertical_slice/apartment.tscn",
		"res://scenes/world/city/city.tscn",
		"res://scenes/world/vertical_slice/restaurant.tscn",
		"res://scenes/art/lab/Clone_Lab_Base.tscn",
		"res://scenes/dating/date_stage.gd",
		"res://autoload/game.tscn",
		"res://scenes/ui/phone_ui.tscn",
		"res://scenes/ui/date_ui.tscn",
		"res://scenes/ui/hud.tscn",
	])


func assert_critical_resources_loadable() -> bool:
	## Existence + PackedScene/Script load catches missing deps that ResourceLoader.exists alone misses.
	var missing: PackedStringArray = PackedStringArray()
	var unloadable: PackedStringArray = PackedStringArray()
	for p in critical_scene_paths():
		if not ResourceLoader.exists(p):
			missing.append(p)
			continue
		if p.ends_with(".tscn") or p.ends_with(".scn"):
			var packed: PackedScene = load(p) as PackedScene
			if packed == null:
				unloadable.append(p)
		elif p.ends_with(".gd"):
			var script: GDScript = load(p) as GDScript
			if script == null:
				unloadable.append(p)
	if not missing.is_empty():
		return require(false, "critical_resources_exist", ",".join(missing))
	if not unloadable.is_empty():
		return require(false, "critical_resources_loadable", ",".join(unloadable))
	return require(true, "critical_resources_loadable", "count=%d" % critical_scene_paths().size())


func assert_modules(game: Node) -> bool:
	var names: PackedStringArray = PackedStringArray([
		"economy", "inventory", "girls", "dating", "facility", "clones",
		"staff", "upgrades", "events", "quests", "names", "save", "city",
		"crises", "trait_influence", "time",
	])
	for n in names:
		if game.get(n) == null:
			return require(false, "api_module_%s" % n, "missing")
	return require(true, "api_modules_present", "count=%d" % names.size())


func run_manual_date(game: Node, target_id: String, gift_id: StringName, venue_id: StringName, outfit_id: StringName, step_prefix: String) -> bool:
	if hard_failed:
		return false
	seed_helper.ensure_attention(game, 10.0)
	var dating: Node = game.get("dating")
	var girls: Node = game.get("girls")
	var inventory: Node = game.get("inventory")
	if dating == null or girls == null:
		return require(false, "%s_apis" % step_prefix, "dating/girls missing")
	if gift_id != &"" and int(inventory.call("gift_count", gift_id)) < 1:
		if not bool(inventory.call("buy_gift", gift_id)):
			return require(false, "%s_buy_gift" % step_prefix, str(gift_id))
	dating.call("set_prep", target_id, gift_id, venue_id, outfit_id)
	if not bool(dating.call("start_manual", target_id, true)):
		return require(false, "%s_start_manual" % step_prefix, target_id)
	for _i in range(6):
		var active: Dictionary = dating.get("active_manual")
		if active.is_empty():
			break
		if bool(active.get("phases_done", false)):
			break
		var opts: Array = active.get("options", [])
		if opts.is_empty():
			break
		dating.call("choose_manual", str(opts[0].get("id", "")))
	# Optional mid-date gift if inventory has one and API allows.
	if bool(dating.call("can_give_date_gift")) and gift_id != &"":
		dating.call("give_date_gift", gift_id)
	if not dating.get("active_manual").is_empty():
		dating.call("finish_manual")
	if not bool(girls.call("is_met", StringName(target_id))):
		return require(false, "%s_met_via_date" % step_prefix, "expected is_met after production start_manual")
	return require(true, "%s_complete" % step_prefix, target_id)


func meet_via_city_talk(game: Node, girl_id: String, step_id: String) -> bool:
	if hard_failed:
		return false
	var city: Node = game.get("city")
	var girls: Node = game.get("girls")
	if city == null or girls == null:
		return require(false, step_id, "city/girls missing")
	if bool(girls.call("has_contact", StringName(girl_id))):
		return require(true, step_id, "already_contact")
	if not bool(city.call("is_worthy", girl_id)):
		return require(false, step_id, "not_worthy popularity/dates/stage")
	var talk_result: Dictionary = city.call("talk", girl_id)
	if not bool(talk_result.get("ok", false)):
		return require(false, step_id, "talk_rejected line=%s" % str(talk_result.get("line", "")))
	if not bool(girls.call("has_contact", StringName(girl_id))):
		return require(false, step_id, "talk ok but contact missing")
	return require(true, step_id, "contact_via_city.talk")


func _stage_order(stage_id: String) -> int:
	return int(ContentDB.stage(StringName(stage_id)).get("order", 0))


func expand_to_stage(game: Node, target_stage: String, step_id: String) -> bool:
	if hard_failed:
		return false
	var facility: Node = game.get("facility")
	var economy: Node = game.get("economy")
	if facility == null or economy == null:
		return require(false, step_id, "facility/economy missing")
	if _stage_order(str(game.get("stage_id"))) >= _stage_order(target_stage):
		return require(true, step_id, "already>=%s (at %s)" % [target_stage, str(game.get("stage_id"))])
	var guard: int = 0
	while _stage_order(str(game.get("stage_id"))) < _stage_order(target_stage) and guard < 8:
		guard += 1
		var st: Dictionary = ContentDB.stage(StringName(str(game.get("stage_id"))))
		var next: String = str(st.get("unlock_next", ""))
		if next.is_empty():
			break
		var need_pop: float = float(ContentDB.balance.get("stage_popularity", {}).get(next, 0))
		if float(economy.call("get_value", &"popularity")) < need_pop:
			economy.call("set_value", &"popularity", need_pop + 1.0)
		var cost: float = float(st.get("next_cost", 0))
		if float(economy.call("get_value", &"money")) < cost:
			economy.call("add", &"money", cost + 100.0, &"release_test_seed")
		if not bool(facility.call("buy_stage_expansion")):
			return require(false, step_id, "buy_stage_expansion failed at %s -> %s" % [str(game.get("stage_id")), next])
	if _stage_order(str(game.get("stage_id"))) < _stage_order(target_stage):
		return require(false, step_id, "ended at %s want %s" % [str(game.get("stage_id")), target_stage])
	return require(true, step_id, "reached %s (at %s)" % [target_stage, str(game.get("stage_id"))])
