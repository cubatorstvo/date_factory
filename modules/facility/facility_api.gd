class_name FacilityAPI
extends Node
## Rooms, venues, stage unlocks, megamachine flags.

signal facility_changed

var unlocked_rooms: Array[StringName] = []
var unlocked_venues: Array[StringName] = []
var venue_load: Dictionary = {}
var flags: Dictionary = {}
var mega_parts: int = 0


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	unlocked_rooms.clear()
	unlocked_venues.clear()
	venue_load.clear()
	flags.clear()
	mega_parts = 0
	unlock_stage(&"stage_1", false)


func unlock_stage(stage_id: StringName, announce: bool = true) -> void:
	var st: Dictionary = ContentDB.stage(stage_id)
	for r in st.get("rooms", []):
		var rid := StringName(str(r))
		if not unlocked_rooms.has(rid):
			unlocked_rooms.append(rid)
		if rid == &"agency" and Game.city != null and Game.city.has_method("try_unlock_agency_row_from_progress"):
			Game.city.try_unlock_agency_row_from_progress()
	for v in st.get("venues", []):
		unlock_venue(StringName(str(v)), announce)
	if str(stage_id) == "stage_3" and Game.city != null and Game.city.has_method("try_unlock_agency_row_from_progress"):
		Game.city.try_unlock_agency_row_from_progress()
	facility_changed.emit()


func unlock_venue(id: StringName, announce: bool = true) -> void:
	if unlocked_venues.has(id):
		return
	unlocked_venues.append(id)
	venue_load[str(id)] = 0
	if id == &"park":
		if Game.city != null and Game.city.has_method("unlock_district"):
			Game.city.unlock_district(CityDistricts.PARK_LEISURE, false)
		## Arcade POI lives in park leisure — separate capacity from cheap_cafe.
		unlock_venue(&"arcade", false)
	if id == &"photo_studio" and Game.city != null and Game.city.has_method("unlock_district"):
		Game.city.unlock_district(CityDistricts.AGENCY_ROW, false)
	facility_changed.emit()
	if announce:
		EventBus.toast("Место открыто: %s" % str(ContentDB.venue(id).get("name", id)), &"facility")


func is_venue_unlocked(id: StringName) -> bool:
	return unlocked_venues.has(id)


func venue_used(id: StringName) -> int:
	return int(venue_load.get(str(id), 0))


func reserve_venue(id: StringName) -> bool:
	if not is_venue_unlocked(id):
		return false
	var cap := int(ContentDB.venue(id).get("capacity", 1)) + int(Game.upgrades.effect_value("global_capacity"))
	if venue_used(id) >= cap:
		return false
	venue_load[str(id)] = venue_used(id) + 1
	return true


func release_venue(id: StringName) -> void:
	venue_load[str(id)] = maxi(0, venue_used(id) - 1)


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value
	facility_changed.emit()


func add_mega_part() -> void:
	mega_parts += 1
	if mega_parts >= 3:
		set_flag("megamachine_ready", true)
		EventBus.toast("Мегамашина собрана!", &"story")
	facility_changed.emit()


func buy_stage_expansion() -> bool:
	var st: Dictionary = ContentDB.stage(Game.stage_id)
	var next := str(st.get("unlock_next", ""))
	if next.is_empty():
		return false
	var cost := float(st.get("next_cost", 0))
	var need_pop := float(ContentDB.balance.get("stage_popularity", {}).get(next, 0))
	if Game.economy.get_value(&"popularity") < need_pop:
		EventBus.toast("Нужно больше популярности (%.0f)" % need_pop, &"warn")
		return false
	var from_reserve := 0.0
	if Game.trait_influence != null and Game.trait_influence.expansion_reserve > 0.0:
		from_reserve = minf(cost, Game.trait_influence.expansion_reserve)
	var cash_need := cost - from_reserve
	if cash_need > 0.0 and not Game.economy.try_spend({"money": cash_need}, &"expand"):
		EventBus.toast("Не хватает денег на расширение", &"warn")
		return false
	if from_reserve > 0.0 and not Game.trait_influence.spend_expansion_reserve(from_reserve):
		# rollback cash if reserve failed (should be rare)
		if cash_need > 0.0:
			Game.economy.add(&"money", cash_need, &"expand_rollback")
		EventBus.toast("Резерв расширения недоступен", &"warn")
		return false
	if from_reserve > 0.0:
		EventBus.toast("Резерв расширения: −%.0f$" % from_reserve, &"info")
	Game.advance_stage(StringName(next))
	if str(next) == "stage_2" and Game.city != null and Game.city.has_method("unlock_district"):
		Game.city.unlock_district(CityDistricts.PARK_LEISURE, true)
	elif Game.city != null and Game.city.has_method("try_unlock_park_from_progress"):
		Game.city.try_unlock_park_from_progress()
	if str(next) == "stage_3" and Game.city != null and Game.city.has_method("unlock_district"):
		Game.city.unlock_district(CityDistricts.AGENCY_ROW, true)
	elif Game.city != null and Game.city.has_method("try_unlock_agency_row_from_progress"):
		Game.city.try_unlock_agency_row_from_progress()
	facility_changed.emit()
	return true


func check_stage_gates() -> void:
	Game.girls.try_unlock_by_progress()
	# soft hint when ready to expand
	var st: Dictionary = ContentDB.stage(Game.stage_id)
	var next := str(st.get("unlock_next", ""))
	if next.is_empty():
		return
	var need_pop := float(ContentDB.balance.get("stage_popularity", {}).get(next, 0))
	if Game.economy.get_value(&"popularity") >= need_pop and Game.economy.get_value(&"money") >= float(st.get("next_cost", 0)):
		EventBus.toast("Можно расширить комплекс!", &"info")


func room_unlocked(id: StringName) -> bool:
	return unlocked_rooms.has(id)


func to_dict() -> Dictionary:
	var rooms: Array = []
	var venues: Array = []
	for r in unlocked_rooms:
		rooms.append(str(r))
	for v in unlocked_venues:
		venues.append(str(v))
	return {
		"unlocked_rooms": rooms,
		"unlocked_venues": venues,
		"flags": flags.duplicate(),
		"mega_parts": mega_parts,
	}


func from_dict(data: Dictionary) -> void:
	unlocked_rooms.clear()
	unlocked_venues.clear()
	for r in data.get("unlocked_rooms", ["apartment"]):
		unlocked_rooms.append(StringName(str(r)))
	for v in data.get("unlocked_venues", ["kitchen_table"]):
		unlocked_venues.append(StringName(str(v)))
		venue_load[str(v)] = 0
	flags = data.get("flags", {})
	mega_parts = int(data.get("mega_parts", 0))
	facility_changed.emit()
