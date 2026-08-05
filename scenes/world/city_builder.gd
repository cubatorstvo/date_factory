class_name CityBuilder
extends RefCounted
## Creates the city district root and marker-driven nav data from stage-4 manifest.
## No legacy greybox geometry, Label3D, or duplicate interactables.


const MANIFEST_PATH := "res://tools/date_factory_city_stage4_build_manifest.json"
const CITY_VISUAL_OFFSET := Vector3(-30.0, 0.0, 0.0)

## Spot keys that belong to locked districts until unlock.
const PARK_SPOTS := ["park", "gym_front", "bookstore", "cinema", "arcade", "night_bar"]
const AGENCY_SPOTS := ["bus_stop", "agency"]


static func build(parent: Node3D, add_interact: Callable, box: Callable, label: Callable) -> Dictionary:
	## Returns {root, spots, waypoints, waypoint_districts, spot_districts}.
	## add_interact / box / label are retained for API compatibility but unused.
	var _unused_add: Callable = add_interact
	var _unused_box: Callable = box
	var _unused_label: Callable = label

	var city := Node3D.new()
	city.name = "CityDistrict"
	parent.add_child(city)

	var nav: Dictionary = _load_nav_from_manifest()
	return {
		"root": city,
		"spots": nav.get("spots", {}),
		"waypoints": nav.get("waypoints", []),
		"waypoint_districts": nav.get("waypoint_districts", []),
		"spot_districts": nav.get("spot_districts", {}),
	}


static func _load_nav_from_manifest() -> Dictionary:
	var spots: Dictionary = {}
	var waypoints: Array = []
	var waypoint_districts: Array = []
	var spot_districts: Dictionary = {}

	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("CityBuilder: missing stage4 manifest %s" % MANIFEST_PATH)
		return {"spots": spots, "waypoints": waypoints, "waypoint_districts": waypoint_districts, "spot_districts": spot_districts}

	var txt: String = FileAccess.get_file_as_string(MANIFEST_PATH)
	var data_v: Variant = JSON.parse_string(txt)
	if typeof(data_v) != TYPE_DICTIONARY:
		push_warning("CityBuilder: invalid stage4 manifest JSON")
		return {"spots": spots, "waypoints": waypoints, "waypoint_districts": waypoint_districts, "spot_districts": spot_districts}
	var data: Dictionary = data_v as Dictionary
	var nav: Dictionary = data.get("npc_navigation_data", {}) as Dictionary

	var wp_list: Array = nav.get("waypoints", []) as Array
	for wp_v in wp_list:
		var wp_a: Array = wp_v as Array
		var local := Vector3(float(wp_a[0]), float(wp_a[1]), float(wp_a[2]))
		waypoints.append(local + CITY_VISUAL_OFFSET)
		waypoint_districts.append(_district_for_local(local))

	var spots_raw: Dictionary = nav.get("spots", {}) as Dictionary
	for key_v in spots_raw.keys():
		var key: String = str(key_v)
		var arr_out: Array = []
		var arr_in: Array = spots_raw[key] as Array
		for p_v in arr_in:
			var p_a: Array = p_v as Array
			var local := Vector3(float(p_a[0]), float(p_a[1]), float(p_a[2]))
			arr_out.append(local + CITY_VISUAL_OFFSET)
		spots[key] = arr_out
		spot_districts[key] = _district_for_spot_key(key)

	return {
		"spots": spots,
		"waypoints": waypoints,
		"waypoint_districts": waypoint_districts,
		"spot_districts": spot_districts,
	}


static func _district_for_spot_key(key: String) -> String:
	if PARK_SPOTS.has(key):
		return "park_leisure"
	if AGENCY_SPOTS.has(key):
		return "agency_row"
	return "main_street"


static func _district_for_local(local: Vector3) -> String:
	## Heuristic matching stage-4 gate layout in city.tscn local space.
	if local.z >= 7.5 and local.x > -22.0:
		return "park_leisure"
	if local.z >= 12.0 and local.x <= -6.0:
		return "park_leisure"
	if local.x <= -7.5:
		return "agency_row"
	return "main_street"
