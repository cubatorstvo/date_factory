## NOTE: class_name removed from handoff copy to avoid global class clash.
extends RefCounted
## Static definitions for bookable date venues (home / cafe / park / restaurant).


static func places() -> Array:
	return [
		{
			"id": "home",
			"venue_id": "kitchen_table",
			"name": "РЈ СЃРµР±СЏ РґРѕРјР°",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.0,
			"tags": ["СѓСЋС‚РЅРѕ", "Р±РµСЃРїР»Р°С‚РЅРѕ", "С‚СЂРµР±СѓРµС‚ РїРѕРґРіРѕС‚РѕРІРєРё"],
			"blurb": "РџСЂРѕСЃС‚Р°СЏ РґРѕРјР°С€РЅСЏСЏ РІСЃС‚СЂРµС‡Р°. Р”РµС€С‘РІР°СЏ РїРѕСЃСѓРґР°, РѕР±С‹С‡РЅР°СЏ РµРґР° Рё РјРёРЅРёРјСѓРј С†РµСЂРµРјРѕРЅРёР№.",
		},
		{
			"id": "cafe",
			"venue_id": "cheap_cafe",
			"name": "РљР°С„Рµ В«Two HeartsВ»",
			"cost": 30,
			"requires_prep": false,
			"base_quality": 1.6,
			"tags": ["РЅРµС„РѕСЂРјР°Р»СЊРЅРѕ", "РєРѕС„Рµ", "Р±РµР· РїРѕРґРіРѕС‚РѕРІРєРё"],
			"blurb": "РЈР»РёС‡РЅРѕРµ РєР°С„Рµ РЅР° РіР»Р°РІРЅРѕР№. РќРµРґРѕСЂРѕРіРѕ, Р±РµР· РґРѕРјР°С€РЅРµРіРѕ prep вЂ” РїСЂРѕСЃС‚Рѕ РїСЂРёРґРё Рё СЃСЏРґСЊ.",
		},
		{
			"id": "park",
			"venue_id": "park",
			"name": "РџР°СЂРє Leisure",
			"cost": 0,
			"requires_prep": false,
			"base_quality": 1.8,
			"tags": weather_tags(),
			"blurb": "Р‘РµСЃРїР»Р°С‚РЅР°СЏ РїСЂРѕРіСѓР»РєР°: СѓС‚РєРё, РєРёРѕСЃРє Рё РїР»РµРґ. РћС‚РєСЂС‹РІР°РµС‚СЃСЏ СЃ РїР°СЂРєРѕРІС‹Рј СЂР°Р№РѕРЅРѕРј.",
		},
		{
			"id": "restaurant",
			"venue_id": "restaurant",
			"name": "Р РµСЃС‚РѕСЂР°РЅ В«Two HeartsВ»",
			"cost": 90,
			"requires_prep": false,
			"base_quality": 2.4,
			"tags": ["С„РѕСЂРјР°Р»СЊРЅРѕ", "РІС‹СЃРѕРєР°СЏ СЃРµСЂРІРёСЂРѕРІРєР°", "РґРѕСЂРѕРіРѕ"],
			"blurb": "Р”РѕСЂРѕРіРѕР№ Р·Р°Р» Сѓ РїР°СЂРєР°. Р‘СЂРѕРЅСЊ РїРѕСЃР»Рµ unlock РїР°СЂРєР° РёР»Рё venue restaurant.",
		},
		{
			"id": "cinema",
			"venue_id": "cinema_room",
			"name": "РљРёРЅРѕС‚РµР°С‚СЂ Leisure",
			"cost": 45,
			"requires_prep": false,
			"base_quality": 2.0,
			"tags": ["РјРµРґРёР°", "Р±РµР· РїРѕРґРіРѕС‚РѕРІРєРё", "РєРѕСЂРѕС‡Рµ РѕР±С‹С‡РЅРѕРіРѕ"],
			"blurb": "РЎРµР°РЅСЃ РЅР° РґРІРѕРёС…: Р¶Р°РЅСЂ в†’ СЂРµР°РєС†РёРё в†’ СЂР°Р·РіРѕРІРѕСЂ. РћС‚РєСЂС‹РІР°РµС‚СЃСЏ СЃ РїР°СЂРєРѕРј РёР»Рё stage_3.",
		},
		{
			"id": "arcade",
			"venue_id": "arcade",
			"name": "РђСЂРєР°РґР° В«РџРµСЂРµРіСЂСѓР·В»",
			"cost": 25,
			"requires_prep": false,
			"base_quality": 1.7,
			"tags": ["РёРіСЂР°", "РїР°СЂРЅС‹Р№ РјРёРЅРёРіРµР№Рј", "Р±РµР· РїРѕРґРіРѕС‚РѕРІРєРё"],
			"blurb": "РђРІС‚РѕРјР°С‚ В«РџР°СЂРЅС‹Р№ РїРµСЂРµРіСЂСѓР·В»: СЃРѕРІРјРµСЃС‚РЅС‹Р№ СЃС‡С‘С‚ Рё РјСЏРіРєРёР№ Р±РѕРЅРґ. РћС‚РґРµР»СЊРЅР°СЏ РІРјРµСЃС‚РёРјРѕСЃС‚СЊ (РЅРµ РєР°С„Рµ Рё РЅРµ РєРёРЅРѕ).",
		},
		{
			"id": "apt_cozy",
			"venue_id": "kitchen_table",
			"name": "РљРІР°СЂС‚РёСЂР° В«РЈСЋС‚В»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.3,
			"tags": ["СѓСЋС‚РЅРѕ", "С‚РµРјР°С‚РёС‡РµСЃРєР°СЏ", "РґРѕРј"],
			"blurb": "РўС‘РїР»Р°СЏ С‚РµРјР°С‚РёС‡РµСЃРєР°СЏ РєРІР°СЂС‚РёСЂР°. РћС‚РєСЂС‹РІР°РµС‚СЃСЏ РїРѕСЃР»Рµ РїРµСЂРІРѕРіРѕ РєР»РѕРЅР° РёР»Рё stage_4.",
		},
		{
			"id": "apt_modern",
			"venue_id": "kitchen_table",
			"name": "РљРІР°СЂС‚РёСЂР° В«РњРѕРґРµСЂРЅВ»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.5,
			"tags": ["СЃРѕРІСЂРµРјРµРЅРЅРѕ", "С‚РµРјР°С‚РёС‡РµСЃРєР°СЏ", "РґРѕРј"],
			"blurb": "РҐРѕР»РѕРґРЅС‹Р№ РјРёРЅРёРјР°Р»РёР·Рј. РћС‚РґРµР»СЊРЅС‹Р№ СЌС‚Р°Р¶ С‡РµСЂРµР· Р»РёС„С‚.",
		},
		{
			"id": "apt_creative",
			"venue_id": "kitchen_table",
			"name": "РљРІР°СЂС‚РёСЂР° В«РљСЂРµР°С‚РёРІВ»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.4,
			"tags": ["С‚РІРѕСЂС‡РµСЃРєРё", "С‚РµРјР°С‚РёС‡РµСЃРєР°СЏ", "РґРѕРј"],
			"blurb": "РЇСЂРєР°СЏ РјР°СЃС‚РµСЂСЃРєР°СЏ-РєРІР°СЂС‚РёСЂР° РґР»СЏ СЃРІРёРґР°РЅРёР№ Рё РЅР°Р·РЅР°С‡РµРЅРёСЏ Р°РіРµРЅС‚СЃС‚РІР°.",
		},
	]


static func place(id: String) -> Dictionary:
	for p in places():
		if str(p.get("id", "")) == id:
			return p
	return {}


static func homeware_label(level: int) -> String:
	match clampi(level, 1, 4):
		1:
			return "Р§С‚Рѕ Р±С‹Р»Рѕ РІ С€РєР°С„Сѓ"
		2:
			return "РќРѕСЂРјР°Р»СЊРЅС‹Р№ РЅР°Р±РѕСЂ"
		3:
			return "РџСЂРѕРґСѓРјР°РЅРЅР°СЏ СЃРµСЂРІРёСЂРѕРІРєР°"
		4:
			return "Р”РѕРјР°С€РЅРёР№ СЂРµСЃС‚РѕСЂР°РЅ"
		_:
			return "РџСЂРѕСЃС‚Р°СЏ РїРѕСЃСѓРґР°"


static func homeware_blurb(level: int) -> String:
	match clampi(level, 1, 4):
		1:
			return "Р Р°Р·РЅРѕРјР°СЃС‚РЅР°СЏ РґРµС€С‘РІР°СЏ РїРѕСЃСѓРґР°, РїСЂРѕСЃС‚С‹Рµ СЃС‚Р°РєР°РЅС‹."
		2:
			return "РћРґРёРЅР°РєРѕРІС‹Рµ С‚Р°СЂРµР»РєРё Рё СЃС‚РµРєР»СЏРЅРЅС‹Рµ СЃС‚Р°РєР°РЅС‹."
		3:
			return "РҐРѕСЂРѕС€РёРµ С‚Р°СЂРµР»РєРё, Р±РѕРєР°Р»С‹, СЃРєР°С‚РµСЂС‚СЊ."
		4:
			return "Р”РѕСЂРѕРіР°СЏ РїРѕСЃСѓРґР° Рё РєСЂР°СЃРёРІР°СЏ РєРѕРјРїРѕР·РёС†РёСЏ."
		_:
			return ""


static func home_quality(level: int, food_tier: int, drink_tier: int) -> float:
	var q := 0.6 + float(level) * 0.35
	q += float(food_tier) * 0.25
	q += float(drink_tier) * 0.15
	return q


static func food_options() -> Array:
	return [
		{"id": "simple_meal", "name": "РџСЂРѕСЃС‚Р°СЏ РґРѕРјР°С€РЅСЏСЏ РµРґР°", "tier": 1, "blurb": "РЎС‹С‚РЅРѕ Рё Р±РµР· РїСЂРµС‚РµРЅР·РёР№."},
		{"id": "snack_plate", "name": "Р—Р°РєСѓСЃРєРё", "tier": 1, "blurb": "Р›С‘РіРєР°СЏ С‚Р°СЂРµР»РєР° РЅР° РґРІРѕРёС…."},
		{"id": "nice_meal", "name": "РђРєРєСѓСЂР°С‚РЅРѕРµ Р±Р»СЋРґРѕ", "tier": 2, "blurb": "Р’С‹РіР»СЏРґРёС‚ Р·Р°Р±РѕС‚Р»РёРІРµРµ РѕР±С‹С‡РЅРѕРіРѕ СѓР¶РёРЅР°."},
		{"id": "dessert", "name": "Р”РѕРјР°С€РЅРёР№ РґРµСЃРµСЂС‚", "tier": 2, "blurb": "РЎР»Р°РґРєРёР№ Р¶РµСЃС‚ Р±РµР· СЂРµСЃС‚РѕСЂР°РЅР°."},
	]


static func drink_options() -> Array:
	return [
		{"id": "water", "name": "Р’РѕРґР°", "tier": 1, "blurb": "Р§РµСЃС‚РЅРѕ Рё Р±РµСЃРїР»Р°С‚РЅРѕ."},
		{"id": "juice", "name": "Р”РµС€С‘РІС‹Р№ СЃРѕРє", "tier": 2, "blurb": "РҐРѕС‚СЊ РєР°РєР°СЏ-С‚Рѕ С†РµСЂРµРјРѕРЅРёСЏ."},
		{"id": "wine", "name": "РќРµРґРѕСЂРѕРіРѕРµ РІРёРЅРѕ", "tier": 3, "blurb": "РџРѕРїС‹С‚РєР° СЃРґРµР»Р°С‚СЊ РІРµС‡РµСЂ РѕСЃРѕР±РµРЅРЅС‹Рј."},
	]


static func shop_catalog() -> Dictionary:
	return {
		"flower_shop": {
			"name": "Р¦РІРµС‚РѕС‡РЅС‹Р№",
			"kind": "gift",
			"items": ["flower", "bouquet"],
		},
		"jewelry_shop": {
			"name": "Р®РІРµР»РёСЂРЅС‹Р№",
			"kind": "gift",
			"items": ["bracelet", "gold_ring", "diamond"],
		},
		"gift_shop": {
			"name": "РџРѕРґР°СЂРєРё",
			"kind": "gift",
			"items": ["candy", "bear", "cake", "perfume"],
		},
		"clothing_shop": {
			"name": "РћРґРµР¶РґР°",
			"kind": "outfit",
			"items": ["casual", "cheap_formal", "sport"],
		},
		"homeware_shop": {
			"name": "Р”РѕРј Рё РїРѕСЃСѓРґР°",
			"kind": "homeware",
			"items": ["homeware_next"],
		},
		"bookstore": {
			"name": "РљРЅРёР¶РЅС‹Р№ Leisure",
			"kind": "gift",
			"items": ["paperback", "poetry_book", "rare_novel"],
		},
	}


static func clothing_shop_items() -> Array:
	## sport listed only after style unlock / ownership.
	var items: Array = []
	items.append("casual")
	items.append("cheap_formal")
	var sport_unlocked: bool = false
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.root.get_node_or_null("Game") if tree != null else null
	if game != null:
		var inv: Node = game.get("inventory") as Node
		if inv != null and inv.has_method("own_outfit") and bool(inv.call("own_outfit", &"sport")):
			sport_unlocked = true
		var ups: Node = game.get("upgrades") as Node
		if not sport_unlocked and ups != null:
			var owned: Variant = ups.get("owned")
			if owned is Array and (owned as Array).has(&"ward_style_sport"):
				sport_unlocked = true
	if sport_unlocked:
		items.append("sport")
	return items


static func is_restaurant_bookable() -> bool:
	## Expensive restaurant stays gated until venue or park district unlock.
	if Game == null or Game.facility == null:
		return false
	if Game.facility.is_venue_unlocked(&"restaurant"):
		return true
	return is_park_bookable()


static func is_park_bookable() -> bool:
	## Park date unlocks with park_leisure district (stage_2 / venue_park).
	if Game == null:
		return false
	if Game.city != null and Game.city.has_method("is_district_unlocked"):
		return bool(Game.city.call("is_district_unlocked", &"park_leisure"))
	if Game.facility != null:
		if Game.facility.is_venue_unlocked(&"park"):
			return true
		return Game.facility.has_flag("district_park_leisure")
	return false


static func is_leisure_unlocked() -> bool:
	## Gym / bookstore / cinema / arcade share park_leisure or stage_2+.
	if is_park_bookable():
		return true
	if Game == null:
		return false
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= 2


static func is_cinema_bookable() -> bool:
	if is_park_bookable():
		return true
	if Game == null:
		return false
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	if int(order.get(str(Game.stage_id), 1)) >= 3:
		return true
	if Game.facility != null and Game.facility.is_venue_unlocked(&"cinema_room"):
		return true
	return false


static func is_arcade_bookable() -> bool:
	## Own venue capacity `arcade` (never cheap_cafe / cinema_room). Leisure or explicit unlock.
	if Game == null:
		return false
	if is_leisure_unlocked():
		return true
	if Game.facility != null and Game.facility.is_venue_unlocked(&"arcade"):
		return true
	return false


static func normalize_venue_id(place_id: String, venue_id: String) -> String:
	## Keep place_id stable; remap legacy arcade capacity ids from older saves/bookings.
	if place_id == "arcade":
		if venue_id == "" or venue_id == "cheap_cafe" or venue_id == "cinema_room":
			return "arcade"
	var def: Dictionary = place(place_id)
	if venue_id == "" and not def.is_empty():
		return str(def.get("venue_id", "kitchen_table"))
	return venue_id if venue_id != "" else "kitchen_table"


static func is_themed_apartment_bookable(place_id: String) -> bool:
	if not place_id.begins_with("apt_"):
		return false
	if Game == null or Game.city == null:
		return false
	if Game.city.has_method("is_apartment_unlocked"):
		return bool(Game.city.call("is_apartment_unlocked", StringName(place_id)))
	return false


static func is_agency_row_unlocked() -> bool:
	## Photo studio / barber / agency board вЂ” stage_3 or agency room.
	if Game == null:
		return false
	if Game.city != null and Game.city.has_method("is_district_unlocked"):
		if bool(Game.city.call("is_district_unlocked", CityDistricts.AGENCY_ROW)):
			return true
	if Game.facility != null:
		if Game.facility.room_unlocked(&"agency"):
			return true
		return Game.facility.has_flag("district_agency_row")
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= 3


static func current_weather() -> String:
	## Lightweight mood tag for park dates (no full weather sim).
	if Game == null or Game.time == null:
		return "clear"
	var day: int = int(Game.time.day)
	var mins: int = int(Game.time.clock_minutes())
	var bucket: int = day * 17 + int(mins / 60.0)
	if bucket % 5 == 0:
		return "rain"
	if mins >= 12 * 60 and mins < 17 * 60:
		return "warm"
	return "clear"


static func weather_tags() -> Array:
	match current_weather():
		"rain":
			return ["РЅР° СѓР»РёС†Рµ", "Р±РµСЃРїР»Р°С‚РЅРѕ", "СЂРёСЃРє РґРѕР¶РґСЏ"]
		"warm":
			return ["РЅР° СѓР»РёС†Рµ", "Р±РµСЃРїР»Р°С‚РЅРѕ", "С‚РµРїР»Рѕ", "РјРѕСЂРѕР¶РµРЅРѕРµ"]
		_:
			return ["РЅР° СѓР»РёС†Рµ", "Р±РµСЃРїР»Р°С‚РЅРѕ", "Р±РµР· РїРѕРґРіРѕС‚РѕРІРєРё", "СѓС‚РєРё"]
