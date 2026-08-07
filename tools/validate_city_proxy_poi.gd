extends SceneTree
func _initialize() -> void:
	var city_ps: PackedScene = load("res://scenes/world/city/city.tscn") as PackedScene
	if city_ps == null:
		print("VALIDATE_FAIL city_load")
		quit(1)
		return
	var city: Node = city_ps.instantiate()
	root.add_child(city)
	await process_frame
	await process_frame
	var pois: Node = city.get_node_or_null("POIs")
	var n: int = 0 if pois == null else pois.get_child_count()
	var acts: Dictionary = {}
	_collect(city, acts)
	print("VALIDATE_POI_COUNT=", n)
	print("VALIDATE_ACTION_COUNT=", acts.size())
	var keys: Array = acts.keys()
	keys.sort()
	print("VALIDATE_ACTIONS=", ",".join(PackedStringArray(keys)))
	var gates: Array = []
	_find_gates(city, gates)
	print("VALIDATE_GATES=", gates.size())
	var required: Array[String] = [
		"go_home","sit_cafe","open_flower_shop","open_gift_shop","open_jewelry_shop","open_clothing_shop",
		"open_homeware_shop","city_cafe_job","city_cafe_scroll","city_coffee","sit_restaurant","city_workout",
		"city_gym_pass","open_bookstore","sit_cinema","open_arcade","sit_arcade","city_bar_drink",
		"open_photo_studio","open_barber","open_agency_board","city_bus_info","city_buy_gift","city_rest",
		"city_park_fun","city_karaoke"
	]
	var missing: Array[String] = []
	for a in required:
		if not acts.has(a):
			missing.append(a)
	if missing.is_empty() and n == 20 and gates.size() >= 3:
		print("VALIDATE_OK")
		quit(0)
	else:
		print("VALIDATE_MISSING=", ",".join(PackedStringArray(missing)))
		quit(2)

func _collect(node: Node, acts: Dictionary) -> void:
	if node.get_script() != null and ("action_id" in node):
		var aid: String = str(node.get("action_id"))
		if aid != "" and aid != "inspect_district_gate":
			acts[aid] = true
	for c in node.get_children():
		_collect(c, acts)

func _find_gates(node: Node, out: Array) -> void:
	if node.is_in_group("district_gate"):
		out.append(node)
	for c in node.get_children():
		_find_gates(c, out)
