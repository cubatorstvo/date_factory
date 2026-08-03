class_name StaffAPI
extends Node
## Hireable staff with workplace effects.

signal staff_changed

var hired: Dictionary = {} ## role_id -> {name, level}


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	hired.clear()
	staff_changed.emit()


func has_effect(effect: String) -> bool:
	for role_id in hired.keys():
		var def: Dictionary = ContentDB.staff_roles.get(str(role_id), {})
		if str(def.get("effect", "")) == effect:
			return true
	return false


func can_hire(role_id: StringName) -> bool:
	if hired.has(str(role_id)):
		return false
	var def: Dictionary = ContentDB.staff_roles.get(str(role_id), {})
	if def.is_empty():
		return false
	return _stage_ok(str(def.get("stage", "stage_1")))


func hire(role_id: StringName) -> bool:
	if not can_hire(role_id):
		return false
	var def: Dictionary = ContentDB.staff_roles[str(role_id)]
	var cost := float(def.get("cost", 100)) * float(Game.girls.active_effects().get("staff_cost_mult", 1.0))
	if not Game.economy.try_spend({"money": cost}, &"hire"):
		EventBus.toast("Не хватает денег на найм", &"warn")
		return false
	hired[str(role_id)] = {
		"name": "%s %s" % [str(def.get("name", role_id)), Game.names.next_name()],
		"level": 1,
		"effect": str(def.get("effect", "")),
	}
	staff_changed.emit()
	EventBus.toast("Нанят: %s" % str(hired[str(role_id)]["name"]), &"staff")
	if str(def.get("effect", "")) == "auto_messages":
		Game.dating.raise_automation(1)
	if str(def.get("effect", "")) == "auto_assign_dates":
		Game.dating.raise_automation(3)
	return true


func _stage_ok(need: String) -> bool:
	var order := {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= int(order.get(need, 1))


func list_hired() -> Array:
	var out: Array = []
	for k in hired.keys():
		var e: Dictionary = hired[k].duplicate(true)
		e["role_id"] = k
		out.append(e)
	return out


func to_dict() -> Dictionary:
	return {"hired": hired.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	hired = data.get("hired", {})
	staff_changed.emit()
