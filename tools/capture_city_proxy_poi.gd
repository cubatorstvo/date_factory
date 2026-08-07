extends SceneTree
## City proxy POI smoke: main route → city → teleport near key POIs → screenshots.
## Godot_v4.7.1 --path . -s res://tools/capture_city_proxy_poi.gd

const ABS_OUT := "C:/Users/User/Documents/GodotProjects/date_factory/docs/city_proxy_poi/qa"
const MAIN_SCENE := "res://scenes/boot/main.tscn"
const LOG_PATH := "C:/Users/User/Documents/GodotProjects/date_factory/docs/city_proxy_poi/qa/CAPTURE_RAW.log"

var _log_file: FileAccess
var _player: CharacterBody3D
var _shot: int = 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ABS_OUT)
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	_log("CAPTURE_CITY_PROXY_POI START")
	call_deferred("_boot")


func _boot() -> void:
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		_fail("Game autoload missing")
		return
	var packed: PackedScene = load(MAIN_SCENE) as PackedScene
	if packed == null:
		_fail("Missing main scene")
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	_player = get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		_fail("Player missing")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _player.has_method("set"):
		_player.set("_date_lock", false)

	await _capture("01_boot_spawn.png", "spawn")
	## Direct travel — InteractionRouter class_name can fail under -s script mode.
	var world: Node = current_scene.find_child("ComplexWorld", true, false)
	if world == null:
		world = current_scene
	if world != null and world.has_method("travel_to"):
		world.call("travel_to", &"city", &"PlayerSpawn")
		_log("TRAVEL_TO city via ComplexWorld")
	else:
		await _goto_interact(&"go_outside")
	await _wait(2.0)
	await _capture("02_city_after_exit.png", "city after apartment exit")

	var city_visual: Node = null
	for n in root.find_children("CityVisual", "", true, false):
		city_visual = n
		break
	_log("CITY_VISUAL=%s loc=%s" % [
		str(city_visual != null),
		str(world.call("get_current_location") if world != null and world.has_method("get_current_location") else "?")
	])

	## CityVisual is offset; use Interactable global positions.
	var home: Interactable = _find_action(&"go_home")
	var cafe: Interactable = _find_action(&"sit_cafe")
	var flower: Interactable = _find_action(&"open_flower_shop")
	var gift: Interactable = _find_action(&"open_gift_shop")
	var jewelry: Interactable = _find_action(&"open_jewelry_shop")
	var clothing: Interactable = _find_action(&"open_clothing_shop")
	var net_job: Interactable = _find_action(&"city_cafe_job")
	var bench: Interactable = _find_action(&"city_rest")
	var gate: Interactable = _find_action(&"inspect_district_gate")

	_log("FOUND go_home=%s sit_cafe=%s flower=%s gift=%s jewelry=%s clothing=%s net=%s rest=%s gate=%s" % [
		str(home != null), str(cafe != null), str(flower != null), str(gift != null),
		str(jewelry != null), str(clothing != null), str(net_job != null), str(bench != null), str(gate != null)
	])

	if home == null or cafe == null or flower == null or gift == null:
		_fail("Critical Interactables missing in city")
		return

	await _approach(home, "03_player_home.png", "PlayerHome entrance")
	await _approach(cafe, "04_cafe_two_hearts.png", "Cafe Two Hearts")
	await _approach(flower, "05_retail_flower.png", "Flower tenant")
	await _approach(gift, "06_retail_gift.png", "Gift tenant")
	if jewelry != null:
		await _approach(jewelry, "07_fashion_jewelry.png", "Jewelry tenant")
	if clothing != null:
		await _approach(clothing, "08_fashion_clothing.png", "Clothing tenant")
	if net_job != null:
		await _approach(net_job, "09_internet_cafe.png", "InternetCafe")
	if bench != null:
		await _approach(bench, "10_main_bench.png", "MainBench")
	if gate != null:
		await _approach(gate, "11_district_gate.png", "Park/Agency gate probe")

	## Topdown-ish commercial street
	if cafe != null and flower != null:
		var mid: Vector3 = (cafe.global_position + flower.global_position) * 0.5
		_player.global_position = mid + Vector3(0.0, 0.05, 4.0)
		_face(mid + Vector3(0.0, 1.5, 0.0))
		await _wait(0.25)
		await _capture("12_street_pair_view.png", "street looking at cafe/retail")

	_log("CAPTURE DONE shots=%d errors=%d" % [_shot, _errors.size()])
	if _log_file != null:
		_log_file.close()
	quit(0 if _errors.is_empty() else 2)


func _approach(area: Interactable, filename: String, note: String) -> void:
	var target: Vector3 = area.global_position
	_player.global_position = target + Vector3(0.0, 0.05, 1.6)
	_face(target + Vector3(0.0, 1.2, 0.0))
	await _wait(0.3)
	_log("APPROACH %s at %s action=%s title=%s" % [note, str(target), str(area.action_id), str(area.display_name)])
	await _capture(filename, note)


func _find_action(action_id: StringName) -> Interactable:
	var nodes: Array = get_nodes_in_group("city_poi_interact")
	for n in nodes:
		if n is Interactable and (n as Interactable).action_id == action_id:
			return n as Interactable
	## Fallback: any Interactable in tree
	return _find_action_deep(root, action_id)


func _find_action_deep(node: Node, action_id: StringName) -> Interactable:
	if node is Interactable and (node as Interactable).action_id == action_id:
		return node as Interactable
	for c in node.get_children():
		var found: Interactable = _find_action_deep(c, action_id)
		if found != null:
			return found
	return null


func _goto_interact(action_id: StringName) -> void:
	var area: Interactable = _find_action_deep(root, action_id)
	if area == null:
		_log("WARN missing interact %s" % str(action_id))
		_errors.append("missing " + str(action_id))
		return
	_player.global_position = Vector3(area.global_position.x, 0.05, area.global_position.z + 0.85)
	if area.has_method("on_interact"):
		area.call("on_interact", _player)
		_log("INTERACT %s" % str(action_id))
	else:
		_errors.append("no on_interact " + str(action_id))
		_log("ERROR no on_interact %s" % str(action_id))
	await process_frame


func _face(world_target: Vector3) -> void:
	if _player == null:
		return
	var cam: Node3D = _player.get_node_or_null("CameraPivot") as Node3D
	if cam == null:
		cam = _player.get_node_or_null("Head") as Node3D
	var origin: Vector3 = _player.global_position + Vector3(0.0, 1.5, 0.0)
	if cam != null:
		origin = cam.global_position
		cam.look_at(world_target, Vector3.UP)
	_player.look_at(Vector3(world_target.x, _player.global_position.y, world_target.z), Vector3.UP)


func _capture(filename: String, note: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		_errors.append("null image " + filename)
		_log("SHOT_FAIL " + filename)
		return
	var path: String = ABS_OUT + "/" + filename
	var err: Error = img.save_png(path)
	_shot += 1
	_log("SHOT %s err=%s note=%s" % [path, str(err), note])


func _wait(sec: float) -> void:
	var t: float = 0.0
	while t < sec:
		await process_frame
		t += 1.0 / 60.0


func _log(msg: String) -> void:
	print(msg)
	if _log_file != null:
		_log_file.store_line(msg)


func _fail(msg: String) -> void:
	_errors.append(msg)
	_log("FAIL " + msg)
	if _log_file != null:
		_log_file.close()
	quit(1)
