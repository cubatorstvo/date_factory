class_name ClonesAPI
extends Node
## Hero clones for automated dating.

signal clones_changed

var clones: Array = []
var max_slots: int = 0
var busy: Dictionary = {}


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	clones.clear()
	busy.clear()
	max_slots = 0


func can_create() -> bool:
	var effects: Dictionary = Game.girls.active_effects()
	if not Game.girls.is_met(&"scientist") and not bool(effects.get("unlock_clones", false)):
		return false
	return clones.size() < maxi(1, max_slots + int(Game.upgrades.effect_value("clone_slots")))


func create_clone() -> bool:
	if not Game.girls.is_met(&"scientist") and not bool(Game.girls.active_effects().get("unlock_clones", false)):
		EventBus.toast("Сначала познакомься с Учёной", &"warn")
		return false
	var slots := maxi(1, max_slots + int(Game.upgrades.effect_value("clone_slots")))
	if clones.size() >= slots:
		EventBus.toast("Нет свободных слотов клонов", &"warn")
		return false
	var cost := 150.0 * float(Game.girls.active_effects().get("clone_cost_mult", 1.0))
	if not Game.upgrades.has_effect("clone_instant"):
		if not Game.economy.try_spend({"money": cost}, &"clone"):
			EventBus.toast("Нужно %.0f$ на клона" % cost, &"warn")
			return false
	else:
		Game.economy.try_spend({"money": cost * 0.5}, &"clone")
	var id := "clone_%d" % (clones.size() + 1)
	var entry := {
		"id": id,
		"name": "Клон %s" % Game.names.next_name(),
		"quality": 1.0 + Game.upgrades.effect_value("clone_quality"),
		"reliability": 0.7,
		"fatigue": 0.0,
		"spec": "mass",
		"color": [randf() * 0.5 + 0.5, randf() * 0.5, randf() * 0.5],
	}
	clones.append(entry)
	clones_changed.emit()
	EventBus.toast("Создан %s" % str(entry["name"]), &"clone")
	if clones.size() == 1:
		Game.dating.raise_automation(2)
	return true


func available_count() -> int:
	var n := 0
	for c in clones:
		var id := str(c.get("id", ""))
		if not bool(busy.get(id, false)) and float(c.get("fatigue", 0)) < 0.9:
			n += 1
	return n


func assign_to_date() -> String:
	for c in clones:
		var id := str(c.get("id", ""))
		if bool(busy.get(id, false)):
			continue
		if float(c.get("fatigue", 0)) >= 0.9:
			continue
		busy[id] = true
		return id
	return "manager"


func finish_date(clone_id: String) -> void:
	busy[clone_id] = false
	for i in range(clones.size()):
		if str(clones[i].get("id", "")) == clone_id:
			var fat: float = 0.2 * Game.upgrades.effect_value("clone_fatigue_mult", 1.0)
			clones[i]["fatigue"] = minf(1.0, float(clones[i].get("fatigue", 0)) + fat)
			break
	clones_changed.emit()


func roll_error() -> StringName:
	var chance: float = 0.18 * Game.upgrades.effect_value("clone_error_mult", 1.0)
	chance *= float(Game.girls.active_effects().get("clone_error_mult", 1.0))
	if randf() > chance:
		return &""
	var errs := [&"wrong_gift", &"wrong_outfit", &"wrong_place", &"forgot_ending", &"argument"]
	return errs[randi() % errs.size()]


func tick_recover(delta: float) -> void:
	if not Game.staff.has_effect("clone_recover") and not Game.upgrades.has_effect("clone_fatigue_mult"):
		# still slowly recover
		pass
	var rate := 0.05 * delta
	if Game.staff.has_effect("clone_recover"):
		rate *= 2.0
	for i in range(clones.size()):
		clones[i]["fatigue"] = maxf(0.0, float(clones[i].get("fatigue", 0)) - rate)


func _process(delta: float) -> void:
	if Game.run_started:
		tick_recover(delta)


func to_dict() -> Dictionary:
	return {"clones": clones.duplicate(true), "max_slots": max_slots}


func from_dict(data: Dictionary) -> void:
	clones = data.get("clones", [])
	max_slots = int(data.get("max_slots", 0))
	busy.clear()
	clones_changed.emit()
