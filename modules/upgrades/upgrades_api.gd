class_name UpgradesAPI
extends Node
## Purchasable upgrades applying additive/multiplicative effects.

signal upgrades_changed

var owned: Array[StringName] = []
var effects: Dictionary = {}


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	owned.clear()
	effects.clear()
	upgrades_changed.emit()


func has(id: StringName) -> bool:
	return owned.has(id)


func has_effect(key: String) -> bool:
	return effects.has(key) and (typeof(effects[key]) == TYPE_BOOL and bool(effects[key]) or float(effects.get(key, 0)) != 0.0 or str(effects.get(key, "")) != "")


func effect_value(key: String, default: float = 0.0) -> float:
	if not effects.has(key):
		return default
	var v = effects[key]
	if typeof(v) == TYPE_BOOL:
		return 1.0 if v else default
	return float(v)


func gift_price_mult() -> float:
	var m := effect_value("gift_price_mult", 1.0)
	if m == 0.0:
		return 1.0
	return m


func available() -> Array:
	var out: Array = []
	for id in ContentDB.upgrades.keys():
		if owned.has(StringName(id)):
			continue
		var u: Dictionary = ContentDB.upgrades[id]
		if _stage_ok(str(u.get("unlock_stage", "stage_1"))):
			out.append(u)
	return out


func buy(id: StringName) -> bool:
	if owned.has(id):
		return false
	var u := ContentDB.upgrade(id)
	if u.is_empty() or not _stage_ok(str(u.get("unlock_stage", "stage_1"))):
		return false
	var cost := float(u.get("cost", 0))
	if not Game.economy.try_spend({"money": cost}, &"upgrade"):
		EventBus.toast("Недостаточно денег", &"warn")
		return false
	owned.append(id)
	_apply(u.get("effects", {}))
	upgrades_changed.emit()
	EventBus.toast("Улучшение: %s" % str(u.get("name", id)), &"upgrade")
	return true


func _apply(fx: Dictionary) -> void:
	for k in fx.keys():
		var key := str(k)
		var v = fx[k]
		if key == "unlock_outfit":
			var oid := StringName(str(v))
			if not Game.inventory.own_outfit(oid):
				Game.inventory.owned_outfits.append(oid)
				Game.inventory.inventory_changed.emit()
			continue
		if key.begins_with("unlock_outfit:"):
			var oid2 := StringName(key.trim_prefix("unlock_outfit:"))
			if not Game.inventory.own_outfit(oid2):
				Game.inventory.owned_outfits.append(oid2)
				Game.inventory.inventory_changed.emit()
			continue
		if key == "unlock_venue":
			Game.facility.unlock_venue(StringName(str(v)))
			continue
		if key.begins_with("venue_quality:"):
			# flat quality bump stored as effect
			effects[key] = float(effects.get(key, 0)) + float(v)
			continue
		if key == "mega_part":
			Game.facility.add_mega_part()
			continue
		if key == "max_attention":
			Game.economy.max_attention += float(v)
			Game.economy.add(&"attention", float(v), &"upgrade")
			effects[key] = float(effects.get(key, 0)) + float(v)
			continue
		if key == "gift_cap":
			Game.inventory.gift_cap += int(v)
			effects[key] = float(effects.get(key, 0)) + float(v)
			continue
		if key == "clone_slots":
			Game.clones.max_slots += int(v)
			effects[key] = float(effects.get(key, 0)) + float(v)
			continue
		if typeof(v) == TYPE_BOOL:
			effects[key] = bool(effects.get(key, false)) or bool(v)
		elif typeof(v) == TYPE_STRING:
			effects[key] = str(v)
		else:
			# multiplicative keys end with _mult
			if key.ends_with("_mult"):
				var cur := float(effects.get(key, 1.0))
				if not effects.has(key):
					cur = 1.0
				effects[key] = cur * float(v)
			else:
				effects[key] = float(effects.get(key, 0.0)) + float(v)


func _stage_ok(need: String) -> bool:
	var order := {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= int(order.get(need, 1))


func to_dict() -> Dictionary:
	var arr: Array = []
	for o in owned:
		arr.append(str(o))
	return {"owned": arr, "effects": effects.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	owned.clear()
	for o in data.get("owned", []):
		owned.append(StringName(str(o)))
	effects = data.get("effects", {})
	upgrades_changed.emit()
