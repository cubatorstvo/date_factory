## NOTE: class_name removed from handoff copy to avoid global class clash.
extends RefCounted
## City hub district unlock flags (Pass 1вЂ“4) + gate UI copy.

const MAIN_STREET := &"main_street"
const PARK_LEISURE := &"park_leisure"
const AGENCY_ROW := &"agency_row"


static func default_unlocked() -> Array[StringName]:
	var out: Array[StringName] = [MAIN_STREET]
	return out


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = [MAIN_STREET, PARK_LEISURE, AGENCY_ROW]
	return out


static func gated_ids() -> Array[StringName]:
	var out: Array[StringName] = [PARK_LEISURE, AGENCY_ROW]
	return out


static func info(id: StringName) -> Dictionary:
	## Catalog for DistrictGateUI: title, unlock requirements, contents list.
	match id:
		PARK_LEISURE:
			return {
				"id": PARK_LEISURE,
				"title": "РџР°СЂРє Рё РґРѕСЃСѓРі",
				"subtitle": "Р—Р°РєСЂС‹С‚С‹Р№ СЂР°Р№РѕРЅ Р·Р° РІРѕСЂРѕС‚Р°РјРё",
				"unlock_text": "РћС‚РєСЂРѕРµС‚СЃСЏ РїСЂРё СЂР°СЃС€РёСЂРµРЅРёРё РґРѕ СЃС‚Р°С‚СѓСЃР° 2\nРёР»Рё РїРѕСЃР»Рµ РѕС‚РєСЂС‹С‚РёСЏ РїР»РѕС‰Р°РґРєРё В«РџР°СЂРєВ» РІ С€С‚Р°Р±Рµ.",
				"contents": [
					"РџРёРєРЅРёРє / СЃРІРёРґР°РЅРёРµ РІ РїР°СЂРєРµ",
					"Р РµСЃС‚РѕСЂР°РЅ Сѓ РїР°СЂРєР°",
					"Р¤РёС‚РЅРµСЃ-Р·Р°Р»",
					"РљРЅРёР¶РЅС‹Р№",
					"РљРёРЅРѕС‚РµР°С‚СЂ",
					"РђСЂРєР°РґР° В«РџРµСЂРµРіСЂСѓР·В»",
				],
			}
		AGENCY_ROW:
			return {
				"id": AGENCY_ROW,
				"title": "Р СЏРґ Р°РіРµРЅС‚СЃС‚РІР°",
				"subtitle": "Р”РµР»РѕРІРѕР№ РєРІР°СЂС‚Р°Р» Р·Р° Р±Р°СЂСЊРµСЂРѕРј",
				"unlock_text": "РћС‚РєСЂРѕРµС‚СЃСЏ РїСЂРё СЂР°СЃС€РёСЂРµРЅРёРё РґРѕ СЃС‚Р°С‚СѓСЃР° 3\nРёР»Рё РїРѕСЃР»Рµ РѕС‚РєСЂС‹С‚РёСЏ РєРѕРјРЅР°С‚С‹ В«РђРіРµРЅС‚СЃС‚РІРѕВ» РІ С€С‚Р°Р±Рµ.",
				"contents": [
					"Р¤РѕС‚РѕСЃС‚СѓРґРёСЏ",
					"Р‘Р°СЂР±РµСЂ",
					"РћС„РёСЃ Р°РіРµРЅС‚СЃС‚РІР° / РґРѕСЃРєР° СЂР°СЃРїРёСЃР°РЅРёСЏ",
				],
			}
		MAIN_STREET:
			return {
				"id": MAIN_STREET,
				"title": "Р“Р»Р°РІРЅР°СЏ СѓР»РёС†Р°",
				"subtitle": "РЎС‚Р°СЂС‚РѕРІС‹Р№ СЂР°Р№РѕРЅ",
				"unlock_text": "Р”РѕСЃС‚СѓРїРµРЅ СЃ РЅР°С‡Р°Р»Р° РёРіСЂС‹.",
				"contents": [
					"РљР°С„Рµ Two Hearts",
					"РњР°РіР°Р·РёРЅС‹ (РѕРґРµР¶РґР°, РїРѕСЃСѓРґР°, РїРѕРґР°СЂРєРё)",
					"РЎРєР°РјРµР№РєРё Рё РїР»РѕС‰Р°РґСЊ",
					"Р’РѕСЂРѕС‚Р° РІ РїР°СЂРє",
				],
			}
		_:
			return {
				"id": id,
				"title": str(id),
				"subtitle": "",
				"unlock_text": "Р Р°Р№РѕРЅ РµС‰С‘ Р·Р°РєСЂС‹С‚.",
				"contents": [],
			}
