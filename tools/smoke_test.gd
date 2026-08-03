extends SceneTree
## Headless smoke test via /root autoload nodes (no compile-time autoload ids).


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var game: Node = root.get_node_or_null("Game")
	var bus: Node = root.get_node_or_null("EventBus")
	if game == null:
		push_error("Game autoload missing at /root/Game")
		quit(1)
		return
	var errors: PackedStringArray = PackedStringArray()
	game.call("new_game")
	ContentDB.ensure_loaded()
	_assert(errors, ContentDB.gifts.size() >= 24, "gifts>=24")
	_assert(errors, ContentDB.outfits.size() >= 11, "outfits>=11")
	_assert(errors, ContentDB.venues.size() >= 10, "venues>=10")
	_assert(errors, ContentDB.girls.size() >= 12, "girls>=12")
	_assert(errors, ContentDB.upgrades.size() >= 80, "upgrades>=80")
	_assert(errors, ContentDB.events.size() >= 30, "events>=30")
	var inventory: Node = game.get("inventory")
	var dating: Node = game.get("dating")
	var girls: Node = game.get("girls")
	var economy: Node = game.get("economy")
	var facility: Node = game.get("facility")
	var clones: Node = game.get("clones")
	var staff: Node = game.get("staff")
	var upgrades: Node = game.get("upgrades")
	var save: Node = game.get("save")
	_assert(errors, bool(inventory.call("buy_gift", &"flower")), "buy flower")
	dating.call("set_prep", "neighbor", &"flower", &"kitchen_table", &"casual")
	_assert(errors, bool(dating.call("start_manual", "neighbor", true)), "start neighbor date")
	for _i in range(3):
		var active: Dictionary = dating.get("active_manual")
		if active.is_empty():
			break
		var opts: Array = active.get("options", [])
		if opts.is_empty():
			break
		dating.call("choose_manual", str(opts[0].get("id", "")))
	_assert(errors, bool(girls.call("is_met", &"neighbor")), "neighbor met")
	economy.call("add", &"money", 20000.0, &"test")
	economy.call("add", &"popularity", 500.0, &"test")
	game.set("total_successful_dates", 50)
	for sid in ["stage_2", "stage_3", "stage_4", "stage_5", "stage_6"]:
		game.call("advance_stage", StringName(sid))
		if sid in ["stage_2", "stage_4", "stage_6"]:
			game.call("save_game")
			_assert(errors, bool(save.call("has_save")), "save_%s" % sid)
			game.call("load_game")
			_assert(errors, str(game.get("stage_id")) == sid, "load_stage_%s" % sid)
	girls.call("try_unlock_by_progress")
	for gid in ContentDB.girls.keys():
		if gid == "algorithm":
			continue
		girls.call("mark_met", StringName(gid))
		girls.call("add_relation", StringName(gid), 100.0)
	staff.call("hire", &"messenger")
	clones.set("max_slots", 8)
	for _j in range(3):
		clones.call("create_clone")
		if not clones.get("pending").is_empty():
			clones.call("decide_acceptance", "approve")
	_assert(errors, clones.get("clones").size() >= 1, "clone created")
	upgrades.call("buy", &"final_megamachine_1")
	upgrades.call("buy", &"final_megamachine_2")
	upgrades.call("buy", &"final_megamachine_3")
	_assert(errors, bool(facility.call("has_flag", "megamachine_ready")), "megamachine")
	_assert(errors, bool(girls.call("unlock_algorithm_if_ready")), "algorithm unlock")
	inventory.call("_add_gift", &"romance_cert", 1)
	var owned: Array = inventory.get("owned_outfits")
	if not owned.has(&"final_absurd"):
		owned.append(&"final_absurd")
		inventory.set("owned_outfits", owned)
	dating.call("set_prep", "algorithm", &"romance_cert", &"orbital_hall", &"final_absurd")
	facility.call("unlock_venue", &"orbital_hall")
	_assert(errors, bool(dating.call("start_manual", "algorithm", true)), "start finale")
	for _k in range(3):
		var active2: Dictionary = dating.get("active_manual")
		if active2.is_empty():
			break
		var opts2: Array = active2.get("options", [])
		if opts2.is_empty():
			break
		dating.call("choose_manual", str(opts2[0].get("id", "")))
	game.call("start_postgame")
	_assert(errors, bool(game.get("postgame")), "postgame")
	game.call("save_game")
	_assert(errors, bool(save.call("has_save")), "save exists")
	game.call("load_game")
	_assert(errors, bool(game.get("postgame")), "load postgame")
	if bus:
		pass
	if errors.is_empty():
		print("SMOKE_OK gifts=%d upgrades=%d events=%d rooms=%d" % [
			ContentDB.gifts.size(), ContentDB.upgrades.size(), ContentDB.events.size(), ContentDB.rooms.size()
		])
		quit(0)
	else:
		for e in errors:
			push_error(e)
		print("SMOKE_FAIL ", errors)
		quit(1)


func _assert(errors: PackedStringArray, cond: bool, label: String) -> void:
	if not cond:
		errors.append(label)
