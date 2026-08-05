class_name FullAccessQaProfile
extends RefCounted
## Deterministic full-access QA save for test/tools only.
## Not wired to shipping boot Continue / New Game / pause / quick save-load.
## Never writes user://save_slot_1.json — only the dedicated QA path.

const QA_PATH := "user://save_slot_qa_full_access.json"
const QA_PROFILE_ID := "full_access"
const QA_SCHEMA_VERSION := 1
const TOAST_MSG := "QA: все локации и POI открыты"

const _THEMED_APTS: Array[StringName] = [&"apt_cozy", &"apt_modern", &"apt_creative"]
const _STAGE_ORDER: Array[StringName] = [
	&"stage_1", &"stage_2", &"stage_3", &"stage_4", &"stage_5", &"stage_6",
]


## Build unlock matrix in live Game modules, then persist to QA_PATH.
static func regenerate_and_apply() -> Dictionary:
	_apply_unlock_matrix()
	var data: Dictionary = Game.to_dict()
	data["qa_profile"] = QA_PROFILE_ID
	data["qa_schema_version"] = QA_SCHEMA_VERSION
	if Game.save != null:
		Game.save.write_qa_full_access_save(data)
	else:
		_write_qa_file(data)
	print("[QA] full_access profile ready → %s" % QA_PATH)
	EventBus.toast(TOAST_MSG, &"info")
	return data


static func _apply_unlock_matrix() -> void:
	Game.new_game()
	Game.tutorial_done = true
	Game.postgame = false
	Game.total_successful_dates = 25
	Game.stage_id = &"stage_6"
	# Cumulative rooms/venues: unlock every stage pack so nothing is missed.
	for sid: StringName in _STAGE_ORDER:
		Game.facility.unlock_stage(sid, false)
	Game.quests.reset_for_stage(&"stage_6")
	# Economy high enough for all POI costs.
	Game.economy.max_attention = 10.0
	Game.economy.set_value(&"money", 100000.0)
	Game.economy.set_value(&"popularity", 500.0)
	Game.economy.set_value(&"attention", 10.0)
	Game.economy.set_value(&"legend", 80.0)
	Game.economy.set_value(&"scandal", 0.0)
	# City districts + dual-gate themed apartments.
	var city: CityAPI = Game.city as CityAPI
	if city != null:
		city.unlock_district(CityDistricts.MAIN_STREET, false)
		city.unlock_district(CityDistricts.PARK_LEISURE, false)
		city.unlock_district(CityDistricts.AGENCY_ROW, false)
		for apt_id: StringName in _THEMED_APTS:
			if not city.unlocked_apartments.has(apt_id):
				city.unlocked_apartments.append(apt_id)
			if not Game.facility.unlocked_rooms.has(apt_id):
				Game.facility.unlocked_rooms.append(apt_id)
		city.city_changed.emit()
	Game.facility.facility_changed.emit()
	# Scientist met → clone POI usable; grant slots without upgrade purchase.
	Game.girls.mark_met(&"scientist")
	if not Game.girls.has_contact(&"scientist"):
		Game.girls.add_contact(&"scientist")
	Game.clones.max_slots = 3
	Game.clones.pending.clear()
	Game.clones.deferred_hits.clear()
	Game.clones.busy.clear()
	# Clean inspection start: no overlays / deferred popups / active date.
	Game.events.reset()
	# Stamp interval so EventsAPI._process cannot roll a random popup on first frames.
	if Game.time != null:
		Game.events.last_random_event_abs_min = Game.time.absolute_minutes()
	else:
		Game.events.last_random_event_abs_min = 0
	Game.events.cooldown = 120.0
	Game.events.active.clear()
	if Game.crises != null:
		Game.crises.reset()
	Game.dating.reset()
	EventBus.stage_changed.emit(&"stage_6")


static func _write_qa_file(data: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(QA_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[QA] failed to write %s" % QA_PATH)
		EventBus.toast("QA: не удалось записать профиль", &"warn")
		return
	f.store_string(JSON.stringify(data, "\t"))
