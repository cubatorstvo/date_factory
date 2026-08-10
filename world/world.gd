extends Node
## Canonical World owner: location load/unload, access, travel (MODULE 12).
## Autoload name: World. Registered after Story.

signal location_loading(location_id: StringName)
signal location_changed(new_location_id: StringName, previous_location_id: StringName)
signal travel_rejected(target_location_id: StringName, reason: WorldTypes.WorldTravelResult)

const PLAYER_SCENE_PATH := "res://characters/player/player.tscn"
const PHONE_SCENE_PATH := "res://ui/phone/phone_journal.tscn"
const HUD_SCENE_PATH := "res://ui/hud/game_hud.tscn"
const PERSISTENT_UI_SCENE_PATH := "res://world/persistent_ui.tscn"
const HOST_NAME := "WorldHost"
const START_LOCATION := &"apartment"
const DEFAULT_SPAWN := &"spawn_default"
const MAX_POSE_WORLD_BOUND := 10000.0

const CANONICAL_IDS: Array[StringName] = [
	&"apartment",
	&"city_hub",
	&"cafe",
	&"gym",
	&"appearance_space",
	&"salary_mine",
	&"laboratory",
	&"production_area",
	&"final_location",
]

var current_location_id: StringName = &""

var _busy: bool = false
var _host: Node = null
var _location_root: Node3D = null
var _persistent_ui: CanvasLayer = null
var _player: PlayerController = null
var _phone: PhoneJournal = null
var _game_hud: GameHUD = null
var _current_location: WorldLocation = null
var _access_provider: Callable = Callable()
var _scene_path_overrides: Dictionary = {}
var _spawn_fallback_enabled: bool = true
var _signals_hooked: bool = false
var _auto_reset_on_state_reset: bool = false
var _defer_boot_travel: bool = false


func _ready() -> void:
	_hook_global_signals()
	DfLog.info("MODULE_12", "World ready")


func _hook_global_signals() -> void:
	if _signals_hooked:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	_signals_hooked = true


func boot_from_main() -> WorldTypes.WorldTravelResult:
	## F5 / current main boot. SaveSystem may call prepare_for_title() first to defer travel.
	ensure_host()
	if _defer_boot_travel:
		return WorldTypes.WorldTravelResult.SUCCESS
	_auto_reset_on_state_reset = true
	return reset_to_start()


func prepare_for_title() -> void:
	## Title menu path: host may exist, but do not auto-travel on GameState reset.
	_auto_reset_on_state_reset = false
	_defer_boot_travel = true


func begin_new_game_boot() -> WorldTypes.WorldTravelResult:
	## New Game from SaveSystem/title: apartment start + enable reset travel.
	_defer_boot_travel = false
	_auto_reset_on_state_reset = true
	ensure_host()
	return reset_to_start()


func suppress_auto_reset_on_state_reset(suppress: bool) -> void:
	_auto_reset_on_state_reset = not suppress


func set_auto_reset_on_state_reset_for_test(enabled: bool) -> void:
	_auto_reset_on_state_reset = enabled


func ensure_host() -> void:
	if _host != null and is_instance_valid(_host):
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		push_error("[World] no SceneTree for host")
		return
	var existing: Node = tree.root.get_node_or_null(HOST_NAME)
	if existing != null:
		_host = existing
	else:
		_host = Node.new()
		_host.name = HOST_NAME
		tree.root.add_child(_host)
	_location_root = _host.get_node_or_null("LocationRoot") as Node3D
	if _location_root == null:
		_location_root = Node3D.new()
		_location_root.name = "LocationRoot"
		_host.add_child(_location_root)
	_persistent_ui = _host.get_node_or_null("PersistentUI") as CanvasLayer
	if _persistent_ui == null:
		var packed_ui: PackedScene = load(PERSISTENT_UI_SCENE_PATH) as PackedScene
		if packed_ui != null:
			_persistent_ui = packed_ui.instantiate() as CanvasLayer
			if _persistent_ui != null:
				_host.add_child(_persistent_ui)
		else:
			push_error("[World] persistent UI scene missing")
	_ensure_player()
	_ensure_phone()
	_ensure_game_hud()


func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var existing: Node = _host.get_node_or_null("Player")
	if existing is PlayerController:
		_player = existing as PlayerController
		return
	var packed: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("[World] player scene missing")
		return
	var inst: Node = packed.instantiate()
	if not (inst is PlayerController):
		push_error("[World] player scene root is not PlayerController")
		inst.free()
		return
	_player = inst as PlayerController
	_player.name = "Player"
	_host.add_child(_player)


func _ensure_phone() -> void:
	if _phone != null and is_instance_valid(_phone):
		return
	var existing: Node = _persistent_ui.get_node_or_null("PhoneJournal")
	if existing is PhoneJournal:
		_phone = existing as PhoneJournal
		return
	var packed: PackedScene = load(PHONE_SCENE_PATH) as PackedScene
	if packed == null:
		push_warning("[World] PhoneJournal scene missing")
		return
	var inst: Node = packed.instantiate()
	if not (inst is PhoneJournal):
		push_warning("[World] PhoneJournal instantiate type mismatch")
		inst.free()
		return
	_phone = inst as PhoneJournal
	_phone.name = "PhoneJournal"
	_phone.add_to_group("phone_journal")
	_persistent_ui.add_child(_phone)


func _ensure_game_hud() -> void:
	if _persistent_ui == null:
		return
	if _game_hud != null and is_instance_valid(_game_hud):
		return
	var existing: Node = _persistent_ui.get_node_or_null("GameHUD")
	if existing is GameHUD:
		_game_hud = existing as GameHUD
		return
	var packed: PackedScene = load(HUD_SCENE_PATH) as PackedScene
	if packed == null:
		push_warning("[World] GameHUD scene missing")
		return
	var inst: Node = packed.instantiate()
	if not (inst is GameHUD):
		push_warning("[World] GameHUD instantiate type mismatch")
		inst.free()
		return
	_game_hud = inst as GameHUD
	_game_hud.name = "GameHUD"
	_persistent_ui.add_child(_game_hud)


func get_game_hud() -> GameHUD:
	return _game_hud


func get_player() -> PlayerController:
	return _player


func get_current_location() -> WorldLocation:
	return _current_location


func is_busy() -> bool:
	return _busy


func register_location(location: WorldLocation) -> void:
	if location == null:
		return
	if _current_location == location:
		return


func open_phone_journal(player: Node = null) -> bool:
	_ensure_phone()
	if _phone == null:
		push_error("[World] cannot open phone — PhoneJournal missing")
		return false
	var p: Node = player
	if p == null:
		p = _player
	_phone.open(p)
	return true


func get_phone_journal() -> PhoneJournal:
	return _phone


func set_access_provider_for_test(provider: Callable) -> void:
	_access_provider = provider


func clear_access_provider_for_test() -> void:
	_access_provider = Callable()


func set_scene_path_override_for_test(location_id: StringName, scene_path: String) -> void:
	if String(location_id) == "":
		return
	_scene_path_overrides[location_id] = scene_path


func clear_scene_path_overrides_for_test() -> void:
	_scene_path_overrides.clear()


func set_spawn_fallback_enabled_for_test(enabled: bool) -> void:
	_spawn_fallback_enabled = enabled


func get_required_feature(location_id: StringName) -> Variant:
	if location_id == &"apartment":
		return null
	if not _feature_map().has(location_id):
		return null
	return _feature_map()[location_id]


func _feature_map() -> Dictionary:
	return {
		&"city_hub": StoryTypes.StoryFeature.SOCIAL_ACCESS,
		&"cafe": StoryTypes.StoryFeature.SOCIAL_ACCESS,
		&"gym": StoryTypes.StoryFeature.SOCIAL_ACCESS,
		&"appearance_space": StoryTypes.StoryFeature.SOCIAL_ACCESS,
		&"salary_mine": StoryTypes.StoryFeature.SALARY_MINE,
		&"laboratory": StoryTypes.StoryFeature.LABORATORY,
		&"production_area": StoryTypes.StoryFeature.WORLD_EXPANSION,
		&"final_location": StoryTypes.StoryFeature.FINAL_DATE,
	}


func get_location_access(location_id: StringName) -> WorldAccessResult:
	var result := WorldAccessResult.new()
	result.location_id = location_id
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_stage"):
		result.current_stage = gs.call("get_stage") as GameTypes.GameStage
	if String(location_id) == "":
		result.status = WorldTypes.WorldAccessStatus.UNKNOWN_LOCATION
		result.message = "Пустой location id"
		return result
	if location_id == &"apartment":
		result.status = WorldTypes.WorldAccessStatus.AVAILABLE
		result.message = ""
		return result
	if not CANONICAL_IDS.has(location_id) and not _scene_path_overrides.has(location_id):
		result.status = WorldTypes.WorldAccessStatus.UNKNOWN_LOCATION
		result.message = "Неизвестная локация"
		return result
	if _access_provider.is_valid():
		var override_status: Variant = _access_provider.call(location_id)
		if override_status is WorldTypes.WorldAccessStatus:
			result.status = override_status as WorldTypes.WorldAccessStatus
			return result
		if override_status is bool:
			result.status = (
				WorldTypes.WorldAccessStatus.AVAILABLE
				if bool(override_status)
				else WorldTypes.WorldAccessStatus.LOCKED_STORY
			)
			return result
	var feature_v: Variant = get_required_feature(location_id)
	if feature_v != null:
		result.has_required_feature = true
		result.required_feature = feature_v as StoryTypes.StoryFeature
	var story: Node = get_node_or_null("/root/Story")
	if result.has_required_feature:
		if story == null or not story.has_method("is_feature_unlocked"):
			result.status = WorldTypes.WorldAccessStatus.LOCKED_STORY
			result.message = "Пока недоступно по сюжету"
			return result
		if not bool(story.call("is_feature_unlocked", result.required_feature)):
			result.status = WorldTypes.WorldAccessStatus.LOCKED_STORY
			result.message = "Пока недоступно по сюжету"
			return result
	var scene_path: String = _resolve_scene_path(location_id)
	if scene_path.strip_edges() == "" or not ResourceLoader.exists(scene_path):
		result.status = WorldTypes.WorldAccessStatus.SCENE_MISSING
		result.message = "Сцена локации отсутствует"
		return result
	result.status = WorldTypes.WorldAccessStatus.AVAILABLE
	result.message = ""
	return result


func is_location_available(location_id: StringName) -> bool:
	var access: WorldAccessResult = get_location_access(location_id)
	return access != null and access.is_available()


func _resolve_scene_path(location_id: StringName) -> String:
	if _scene_path_overrides.has(location_id):
		return String(_scene_path_overrides[location_id])
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null or not db.has_method("get_location"):
		return ""
	var def: LocationDefinition = db.call("get_location", location_id) as LocationDefinition
	if def == null:
		return ""
	return def.scene_path


func request_travel(
	target_location_id: StringName,
	target_spawn_id: StringName = DEFAULT_SPAWN,
) -> WorldTypes.WorldTravelResult:
	if _busy:
		travel_rejected.emit(target_location_id, WorldTypes.WorldTravelResult.BUSY)
		return WorldTypes.WorldTravelResult.BUSY
	_busy = true
	var result: WorldTypes.WorldTravelResult = _travel_impl(target_location_id, target_spawn_id)
	_busy = false
	if result != WorldTypes.WorldTravelResult.SUCCESS:
		travel_rejected.emit(target_location_id, result)
	return result


func _travel_impl(
	target_location_id: StringName,
	target_spawn_id: StringName,
) -> WorldTypes.WorldTravelResult:
	ensure_host()
	if _player == null or not is_instance_valid(_player):
		return WorldTypes.WorldTravelResult.NO_PLAYER
	if String(target_location_id) == "":
		return WorldTypes.WorldTravelResult.UNKNOWN_LOCATION
	if not CANONICAL_IDS.has(target_location_id) and not _scene_path_overrides.has(target_location_id):
		return WorldTypes.WorldTravelResult.UNKNOWN_LOCATION
	var access: WorldAccessResult = get_location_access(target_location_id)
	if access.status == WorldTypes.WorldAccessStatus.UNKNOWN_LOCATION:
		return WorldTypes.WorldTravelResult.UNKNOWN_LOCATION
	if access.status == WorldTypes.WorldAccessStatus.LOCKED_STORY:
		return WorldTypes.WorldTravelResult.LOCKED
	if access.status == WorldTypes.WorldAccessStatus.SCENE_MISSING:
		return WorldTypes.WorldTravelResult.SCENE_MISSING
	var scene_path: String = _resolve_scene_path(target_location_id)
	if scene_path.strip_edges() == "" or not ResourceLoader.exists(scene_path):
		return WorldTypes.WorldTravelResult.SCENE_MISSING
	location_loading.emit(target_location_id)
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return WorldTypes.WorldTravelResult.LOAD_FAILED
	var inst: Node = packed.instantiate()
	if not (inst is WorldLocation):
		inst.free()
		return WorldTypes.WorldTravelResult.LOAD_FAILED
	var target_loc: WorldLocation = inst as WorldLocation
	if target_loc.location_id != target_location_id:
		inst.free()
		return WorldTypes.WorldTravelResult.LOAD_FAILED
	# Resolve spawn on a temporary attach so Marker3D transforms are valid.
	var holder := Node3D.new()
	holder.name = "_WorldTravelValidate"
	_host.add_child(holder)
	holder.add_child(target_loc)
	var spawn: PlayerSpawnPoint = target_loc.get_player_spawn(target_spawn_id)
	var used_fallback: bool = false
	if spawn == null and _spawn_fallback_enabled and target_spawn_id != DEFAULT_SPAWN:
		spawn = target_loc.get_player_spawn(DEFAULT_SPAWN)
		used_fallback = spawn != null
		if used_fallback:
			push_warning("[World] spawn %s missing; fallback spawn_default" % String(target_spawn_id))
	if spawn == null:
		holder.remove_child(target_loc)
		target_loc.free()
		holder.free()
		return WorldTypes.WorldTravelResult.SPAWN_MISSING
	var spawn_xform: Transform3D = spawn.global_transform
	var previous_id: StringName = current_location_id
	var old_location: WorldLocation = _current_location
	var restore_mode: bool = false
	var prev_mode: PlayerController.ControlMode = PlayerController.ControlMode.GAMEPLAY
	if _player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY:
		prev_mode = PlayerController.ControlMode.GAMEPLAY
		_player.enter_modal_ui()
		restore_mode = true
	elif _player.get_control_mode() == PlayerController.ControlMode.MODAL_UI:
		prev_mode = PlayerController.ControlMode.MODAL_UI
	holder.remove_child(target_loc)
	holder.free()
	# Destructive swap only after target+spawn validated.
	if old_location != null and is_instance_valid(old_location):
		_location_root.remove_child(old_location)
		old_location.free()
	_current_location = null
	_location_root.add_child(target_loc)
	_current_location = target_loc
	current_location_id = target_location_id
	_place_player_at(spawn_xform)
	if restore_mode or prev_mode == PlayerController.ControlMode.GAMEPLAY:
		_player.enter_gameplay()
	_current_location.refresh_feature_gates()
	location_changed.emit(current_location_id, previous_id)
	return WorldTypes.WorldTravelResult.SUCCESS


func _place_player_at(xform: Transform3D) -> void:
	if _player == null:
		return
	_player.velocity = Vector3.ZERO
	var yaw: float = xform.basis.get_euler().y
	_player.global_transform = Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), xform.origin)
	_player.set("_pitch", 0.0)
	var pivot: Node3D = _player.get_node_or_null("CameraPivot") as Node3D
	if pivot != null:
		pivot.rotation.x = 0.0


func reset_to_start() -> WorldTypes.WorldTravelResult:
	ensure_host()
	if _busy:
		return WorldTypes.WorldTravelResult.BUSY
	# Force travel even if already apartment (reload spawn).
	var prev_busy: bool = _busy
	_busy = true
	var result: WorldTypes.WorldTravelResult = _travel_impl(START_LOCATION, DEFAULT_SPAWN)
	_busy = prev_busy
	if result != WorldTypes.WorldTravelResult.SUCCESS:
		travel_rejected.emit(START_LOCATION, result)
	return result


func export_world_save_state() -> Dictionary:
	var player_pose: Dictionary = {
		"position": [0.0, 0.0, 0.0],
		"yaw": 0.0,
		"pitch": 0.0,
	}
	if _player != null and is_instance_valid(_player) and _player.has_method("get_pose_dict"):
		player_pose = _player.get_pose_dict()
	return {
		"location_id": String(current_location_id),
		"player": player_pose,
	}


func restore_saved_location(location_id: StringName, player_pose: Dictionary) -> bool:
	## Call after GameState/Story restored. Access gates use restored story state.
	ensure_host()
	_defer_boot_travel = false
	_auto_reset_on_state_reset = true
	var target_id: StringName = location_id
	if String(target_id).strip_edges() == "":
		target_id = START_LOCATION
	var used_location_fallback: bool = false
	var travel: WorldTypes.WorldTravelResult = request_travel(target_id, DEFAULT_SPAWN)
	if travel != WorldTypes.WorldTravelResult.SUCCESS:
		used_location_fallback = true
		push_warning(
			"[World] restore location '%s' failed (%s); fallback apartment"
			% [String(target_id), WorldTypes.WorldTravelResult.find_key(travel)]
		)
		travel = request_travel(START_LOCATION, DEFAULT_SPAWN)
		if travel != WorldTypes.WorldTravelResult.SUCCESS:
			push_warning(
				"[World] apartment fallback also failed (%s)"
				% WorldTypes.WorldTravelResult.find_key(travel)
			)
			return false
	# Travel places at spawn; apply saved pose only when location matched and pose is safe.
	if not used_location_fallback and not player_pose.is_empty():
		if _is_saved_pose_safe(player_pose):
			if _player != null and is_instance_valid(_player) and _player.has_method("apply_pose_dict"):
				_player.apply_pose_dict(player_pose)
		else:
			push_warning("[World] saved player pose invalid; keeping spawn_default")
	notify_post_load_visuals()
	return true


func notify_post_load_visuals() -> void:
	## FirstClone/MODULE19 reconstruct-not-save: call after load when clones exist.
	var gs: Node = get_node_or_null("/root/GameState")
	var total_clones: int = 0
	if gs != null and gs.has_method("get_total_clones"):
		total_clones = int(gs.call("get_total_clones"))
	if total_clones < 1:
		return
	var fc: Node = get_node_or_null("/root/FirstClone")
	if fc != null and fc.has_method("reconstruct_representative"):
		fc.call("reconstruct_representative")
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("clone_visualization_controller"):
		if node != null and is_instance_valid(node) and node.has_method("refresh_from_counts"):
			node.call("refresh_from_counts")


func _is_saved_pose_safe(pose: Dictionary) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var pos_v: Variant = pose.get("position", null)
	var pos: Vector3 = Vector3.ZERO
	if pos_v is Vector3:
		pos = pos_v as Vector3
	elif pos_v is Array:
		var arr: Array = pos_v as Array
		if arr.size() < 3:
			return false
		pos = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	else:
		return false
	if not is_finite(pos.x) or not is_finite(pos.y) or not is_finite(pos.z):
		return false
	if pos.length() >= MAX_POSE_WORLD_BOUND:
		return false
	var yaw: float = float(pose.get("yaw", 0.0))
	var pitch: float = float(pose.get("pitch", 0.0))
	if not is_finite(yaw) or not is_finite(pitch):
		return false
	# Soft ground probe: reject void poses with no nearby floor; floor contact is OK.
	var world_3d: World3D = _player.get_world_3d()
	if world_3d == null:
		return true
	var space: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	if space == null:
		return true
	var from: Vector3 = pos + Vector3(0.0, 0.5, 0.0)
	var to: Vector3 = pos + Vector3(0.0, -8.0, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return false
	# Capsule embed probe: reject when both up and side micro-motions collide (inside geometry).
	var xform: Transform3D = Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), pos)
	var embed_up: bool = _player.test_move(xform, Vector3(0.0, 0.05, 0.0))
	var embed_side: bool = _player.test_move(xform, Vector3(0.05, 0.0, 0.0))
	if embed_up and embed_side:
		return false
	return true


func refresh_current_gates() -> void:
	if _current_location != null and is_instance_valid(_current_location):
		_current_location.refresh_feature_gates()


func validate_location_scene(location_id: StringName) -> Array[String]:
	var errors: Array[String] = []
	var path: String = _resolve_scene_path(location_id)
	if path.strip_edges() == "":
		errors.append("empty scene_path")
		return errors
	if not path.ends_with(".tscn"):
		errors.append("scene_path not .tscn")
	if not ResourceLoader.exists(path):
		errors.append("scene missing on disk")
		return errors
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		errors.append("PackedScene load failed")
		return errors
	var inst: Node = packed.instantiate()
	if not (inst is WorldLocation):
		errors.append("root is not WorldLocation")
		inst.free()
		return errors
	var loc: WorldLocation = inst as WorldLocation
	if loc.location_id != location_id:
		errors.append("location_id mismatch")
	var marker_errors: Array[String] = loc.validate_markers()
	for e in marker_errors:
		errors.append(e)
	inst.free()
	return errors


func _on_state_reset() -> void:
	if _auto_reset_on_state_reset and _host != null and is_instance_valid(_host):
		call_deferred("reset_to_start")


func _on_stage_changed(_new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	refresh_current_gates()


func _on_feature_unlocked(_feature: StoryTypes.StoryFeature) -> void:
	refresh_current_gates()
