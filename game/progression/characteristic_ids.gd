class_name CharacteristicIds
extends RefCounted

const MUSCLE: StringName = &"muscle"
const APPEARANCE: StringName = &"appearance"
const CAPITAL: StringName = &"capital"
const AURA: StringName = &"aura"

const DISPLAY_MUSCLE: String = "Мышца"
const DISPLAY_APPEARANCE: String = "Внешность"
const DISPLAY_CAPITAL: String = "Капитал"
const DISPLAY_AURA: String = "Аура"


static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append(MUSCLE)
	ids.append(APPEARANCE)
	ids.append(CAPITAL)
	ids.append(AURA)
	return ids


static func is_known(characteristic_id: StringName) -> bool:
	return all_ids().has(characteristic_id)


static func display_name(characteristic_id: StringName) -> String:
	match characteristic_id:
		MUSCLE:
			return DISPLAY_MUSCLE
		APPEARANCE:
			return DISPLAY_APPEARANCE
		CAPITAL:
			return DISPLAY_CAPITAL
		AURA:
			return DISPLAY_AURA
		_:
			return String(characteristic_id)
