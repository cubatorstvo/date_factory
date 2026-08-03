class_name EconomyAPI
extends Node
## Money, popularity, attention, scandal, legend integrity.

signal changed(resource_id: StringName, value: float)

var values: Dictionary = {}
var max_attention: float = 3.0
var income_mult: float = 1.0
var pop_mult: float = 1.0


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	var b: Dictionary = ContentDB.balance
	values = {
		&"money": float(b.get("start_money", 40)),
		&"popularity": 0.0,
		&"attention": float(b.get("start_attention", 3)),
		&"scandal": 0.0,
		&"legend": float(b.get("start_legend", 100)),
	}
	max_attention = float(b.get("max_attention_base", 3))
	income_mult = 1.0
	pop_mult = 1.0
	_emit_all()


func get_value(id: StringName) -> float:
	return float(values.get(id, 0.0))


func set_value(id: StringName, amount: float) -> void:
	if id == &"attention":
		amount = clampf(amount, 0.0, max_attention)
	elif id == &"scandal":
		amount = maxf(0.0, amount)
	elif id == &"legend":
		amount = clampf(amount, 0.0, 100.0)
	values[id] = amount
	changed.emit(id, amount)
	EventBus.resource_changed.emit(id, amount)


func add(id: StringName, amount: float, _reason: StringName = &"") -> void:
	if id == &"money" and amount > 0.0:
		amount *= income_mult
	elif id == &"popularity" and amount > 0.0:
		amount *= pop_mult
	set_value(id, get_value(id) + amount)


func damage_legend(amount: float, reason: StringName = &"legend") -> void:
	## Integrity hit. Does NOT automatically raise scandal.
	if amount <= 0.0:
		return
	var before: float = get_value(&"legend")
	add(&"legend", -amount, reason)
	var after: float = get_value(&"legend")
	if after < before:
		EventBus.toast("Целостность легенды: %.0f → %.0f (%s)" % [before, after, _legend_band_ru()], &"warn")


func repair_legend(amount: float, reason: StringName = &"legend") -> void:
	if amount <= 0.0:
		return
	add(&"legend", amount, reason)


func legend_band() -> String:
	var v: float = get_value(&"legend")
	if v >= 75.0:
		return "high"
	if v >= 45.0:
		return "mid"
	if v >= 20.0:
		return "low"
	return "crisis"


func _legend_band_ru() -> String:
	match legend_band():
		"high":
			return "высокая"
		"mid":
			return "средняя"
		"low":
			return "низкая"
		_:
			return "кризис"


func event_pressure_mult() -> float:
	## How often suspicion/crisis events should fire (1 = baseline).
	match legend_band():
		"high":
			return 0.55
		"mid":
			return 1.0
		"low":
			return 1.55
		_:
			return 2.2


func can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if get_value(StringName(str(k))) < float(costs[k]):
			return false
	return true


func try_spend(costs: Dictionary, reason: StringName = &"") -> bool:
	if not can_afford(costs):
		return false
	for k in costs.keys():
		add(StringName(str(k)), -float(costs[k]), reason)
	return true


func do_job() -> void:
	var pay := float(ContentDB.balance.get("job_pay", 25))
	add(&"money", pay, &"job")
	EventBus.toast("Смена закрыта: +%d$" % int(pay), &"money")


func to_dict() -> Dictionary:
	return {"values": values.duplicate(), "max_attention": max_attention, "income_mult": income_mult, "pop_mult": pop_mult}


func from_dict(data: Dictionary) -> void:
	values = data.get("values", values)
	if not values.has(&"legend") and not values.has("legend"):
		values[&"legend"] = 100.0
	max_attention = float(data.get("max_attention", max_attention))
	income_mult = float(data.get("income_mult", 1.0))
	pop_mult = float(data.get("pop_mult", 1.0))
	_emit_all()


func _emit_all() -> void:
	for k in values.keys():
		changed.emit(StringName(str(k)), float(values[k]))
		EventBus.resource_changed.emit(StringName(str(k)), float(values[k]))
