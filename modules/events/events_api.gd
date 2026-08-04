class_name EventsAPI
extends Node
## Narrative incidents. Only fire when the world state makes them make sense.

signal event_opened(event: Dictionary)
signal event_closed

var history: Array = []
var active: Dictionary = {}
var cooldown: float = 0.0
var seen: Dictionary = {}


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	history.clear()
	active.clear()
	cooldown = 25.0
	seen.clear()


func _process(delta: float) -> void:
	if not Game.run_started or not active.is_empty():
		return
	if _blocked_by_gameplay():
		return
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown <= 0.0 and _stage_num() >= 2 and randf() < 0.015 * Game.economy.event_pressure_mult():
		trigger_random()


func maybe_trigger_after_date(_result: Dictionary) -> void:
	if _stage_num() < 2:
		return
	if _blocked_by_gameplay():
		return
	if randf() < 0.22 * Game.economy.event_pressure_mult():
		trigger_random()


func trigger_random() -> void:
	if not active.is_empty():
		return
	if _blocked_by_gameplay():
		return
	var ids: Array = _eligible_ids()
	if ids.is_empty():
		cooldown = 12.0
		return
	# Prefer unseen events a bit.
	var pool: Array = []
	for id in ids:
		if int(seen.get(id, 0)) == 0:
			pool.append(id)
			pool.append(id)
		else:
			pool.append(id)
	var pick: String = str(pool[randi() % pool.size()])
	open_event(StringName(pick))


func open_runtime_event(ev: Dictionary) -> bool:
	## Ad-hoc consequence (e.g. skipped clone defect) — not from ContentDB catalog.
	if not active.is_empty():
		return false
	if _blocked_by_gameplay():
		return false
	if ev.is_empty():
		return false
	active = ev.duplicate(true)
	if not active.has("choices") or active.get("choices", []).is_empty():
		active["choices"] = [{"id": "ok", "label": "Понял", "scandal": 1.0, "legend": -3.0}]
	cooldown = 40.0
	var eid: String = str(active.get("id", "runtime"))
	seen[eid] = int(seen.get(eid, 0)) + 1
	EventBus.event_raised.emit(StringName(eid))
	event_opened.emit(active)
	return true


func open_event(id: StringName) -> void:
	var ev: Dictionary = ContentDB.event(id)
	if ev.is_empty():
		return
	if not _meets_requires(ev):
		return
	active = ev.duplicate(true)
	active["name"] = _personalize(str(active.get("name", id)))
	active["blurb"] = _personalize(str(active.get("blurb", "")))
	active["choices"] = _filter_choices(active.get("choices", []))
	if active["choices"].is_empty():
		active.clear()
		return
	cooldown = 50.0
	seen[str(id)] = int(seen.get(str(id), 0)) + 1
	EventBus.event_raised.emit(id)
	event_opened.emit(active)


func choose(choice_id: String) -> void:
	if active.is_empty():
		return
	var picked: Dictionary = {}
	for c in active.get("choices", []):
		if str(c.get("id", "")) == choice_id:
			picked = c
			break
	if picked.is_empty() and not active.get("choices", []).is_empty():
		picked = active["choices"][0]
	var money: float = float(picked.get("money", 0))
	var scandal: float = float(picked.get("scandal", 0))
	var pop: float = float(picked.get("popularity", 0))
	var legend_delta: float = float(picked.get("legend", 0))
	pop *= float(Game.girls.active_effects().get("event_pop_mult", 1.0))
	if money < 0.0:
		money *= Game.upgrades.effect_value("fine_mult", 1.0)
		if not Game.economy.try_spend({"money": absf(money)}, &"event"):
			money = 0.0
			scandal += 1.0
	elif money > 0.0:
		Game.economy.add(&"money", money, &"event")
	var gift_buy := StringName(str(picked.get("gift_id", "")))
	if gift_buy != &"":
		if Game.inventory.buy_gift(gift_buy):
			Game.quests.complete("s1_money")
		else:
			EventBus.toast("Не удалось купить подарок", &"warn")
	Game.economy.add(&"scandal", scandal, &"event")
	Game.economy.add(&"popularity", pop, &"event")
	if legend_delta < 0.0:
		Game.economy.damage_legend(absf(legend_delta), &"event")
	elif legend_delta > 0.0:
		Game.economy.repair_legend(legend_delta, &"event")
	history.append({"id": active.get("id", ""), "choice": choice_id})
	EventBus.toast("Событие: %s" % str(active.get("name", "")), &"event")
	var eid := str(active.get("id", ""))
	active.clear()
	event_closed.emit()
	if eid.begins_with("book_date_"):
		var day: int = int(picked.get("day", 1))
		var mins: int = int(picked.get("minutes", 0))
		var place_id: String = str(picked.get("place_id", eid.trim_prefix("book_date_")))
		var target_id: String = str(picked.get("target_id", ""))
		var unique: bool = bool(picked.get("unique", true))
		if target_id != "" and Game.dating.book_date(target_id, place_id, day, mins, unique):
			Game.quests.complete("s1_prepare")
	if Game.dating.has_method("apply_parallel_choice"):
		Game.dating.apply_parallel_choice(choice_id)


func _blocked_by_gameplay() -> bool:
	# Never stack over a live date / phone / pause / reveal / other event UI.
	if not Game.dating.active_manual.is_empty():
		return true
	var tree: SceneTree = get_tree()
	if tree == null:
		return true
	for group in ["pause_ui", "phone_ui", "date_ui", "reveal_ui", "finale_ui", "settings_ui", "shop_ui"]:
		var n: Node = tree.get_first_node_in_group(group)
		if n != null and bool(n.visible):
			return true
	return false


func _eligible_ids() -> Array:
	var out: Array = []
	for id in ContentDB.events.keys():
		var ev: Dictionary = ContentDB.event(StringName(str(id)))
		if _meets_requires(ev):
			out.append(str(id))
	return out


func _meets_requires(ev: Dictionary) -> bool:
	var req: Dictionary = ev.get("requires", {})
	var min_stage: int = int(req.get("min_stage", 2))
	if _stage_num() < min_stage:
		return false
	var clones_min: int = int(req.get("clones_min", 0))
	if clones_min > 0 and Game.clones.clones.size() < clones_min:
		return false
	if bool(req.get("needs_scientist", false)) and not Game.girls.is_met(&"scientist"):
		return false
	if bool(req.get("needs_staff", false)) and Game.staff.hired.is_empty():
		return false
	if bool(req.get("needs_automation", false)) and Game.dating.automation_level < 1:
		return false
	return true


func _personalize(text: String) -> String:
	var double_name: String = Game.names.peek_name()
	return text.replace("{double}", double_name).replace("{клон}", double_name)


func _filter_choices(choices: Array) -> Array:
	## Hide «send a double» options until doubles actually exist.
	var has_doubles: bool = Game.clones.clones.size() > 0
	var out: Array = []
	for c in choices:
		var cid: String = str(c.get("id", ""))
		var label: String = str(c.get("label", "")).to_lower()
		var needs_double: bool = cid in ["clone", "wait"] or label.find("дубл") >= 0
		if needs_double and not has_doubles:
			continue
		out.append(c)
	return out if not out.is_empty() else choices


func _stage_num() -> int:
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1))


func to_dict() -> Dictionary:
	return {"history": history.duplicate(), "seen": seen.duplicate(), "cooldown": cooldown}


func from_dict(data: Dictionary) -> void:
	history = data.get("history", [])
	seen = data.get("seen", {})
	cooldown = float(data.get("cooldown", 25))
	active.clear()
