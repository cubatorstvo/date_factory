extends Node
## PE01 apartment physical/onboarding: spawn facing, clearance, furniture colliders, Neighbor.
## Run: res://world/test/apartment_onboarding_physics_test.tscn --quit-after 40000

const PLAYER_RADIUS: float = 0.32
const FORWARD_CLEAR_M: float = 1.5
const ESSENTIAL_COLLIDER_PATHS: Array[String] = [
	"Geometry/ApartmentArt/Objects/Bed/Physics",
	"Geometry/ApartmentArt/Colliders/NightStandBody",
	"Geometry/ApartmentArt/Objects/Wardrobe/Physics",
	"Geometry/ApartmentArt/Objects/DiningTable/Physics",
	"Geometry/ApartmentArt/Colliders/DiningChairNorthBody",
	"Geometry/ApartmentArt/Colliders/DiningChairSouthBody",
	"Geometry/ApartmentArt/Objects/Fridge/Physics",
	"Geometry/ApartmentArt/Colliders/OvenBody",
	"Geometry/ApartmentArt/Colliders/KitchenSinkBody",
	"Geometry/ApartmentArt/Colliders/KitchenDrawersBody",
	"Geometry/ApartmentArt/Objects/ExitDoor/Physics",
	"Geometry/ApartmentArt/Colliders/NeighborDoorBody",
]

var _failed: int = 0
var _passed: int = 0
var _world: Node = null
var _gs: Node = null


func _ready() -> void:
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		DfLog.info("PE01_APT_PHYS", "ALL PASS (%s)" % _passed)
		print("PE01_APT_PHYS: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("PE01_APT_PHYS", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("PE01_APT_PHYS: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[PE01_APT_PHYS] FAIL: %s" % label)
		print("PE01_APT_PHYS FAIL: %s" % label)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _run_all() -> void:
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	_gs.call("reset_for_new_game")
	await _settle()
	var travel: int = int(_world.call("request_travel", &"apartment", &"spawn_default"))
	_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "travel apartment")
	await _settle()
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	_ok(loc != null, "apartment location")
	if loc == null:
		return
	await _test_spawn_orientation_and_clearance(loc)
	await _test_furniture_colliders(loc)
	await _test_neighbor_anchor(loc)
	await _test_city_exit_story_lock(loc)
	await _test_early_interactables(loc)


func _test_spawn_orientation_and_clearance(loc: WorldLocation) -> void:
	var spawn: PlayerSpawnPoint = loc.get_player_spawn(&"spawn_default")
	_ok(spawn != null, "spawn_default present")
	if spawn == null:
		return
	var forward: Vector3 = -spawn.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		_ok(false, "spawn forward valid")
		return
	forward = forward.normalized()
	# Must face into room (+X), not into city exit door (-X).
	_ok(forward.x > 0.75, "spawn faces into room (+X), got %s" % forward)
	_ok(absf(forward.z) < 0.35, "spawn yaw mostly along +X, got %s" % forward)
	var origin: Vector3 = spawn.global_position + Vector3(0.0, 0.9, 0.0)
	var space: PhysicsDirectSpaceState3D = loc.get_world_3d().direct_space_state
	_ok(space != null, "physics space")
	if space == null:
		return
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + forward * FORWARD_CLEAR_M
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(query)
	_ok(hit.is_empty(), ">=1.5m forward clearance from spawn (hit=%s)" % str(hit.get("collider", "")))
	# Capsule must not start overlapping exit-door collider.
	var door_query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = 1.8
	door_query.shape = capsule
	door_query.transform = Transform3D(Basis.IDENTITY, spawn.global_position + Vector3(0.0, 0.9, 0.0))
	door_query.collision_mask = 1
	door_query.collide_with_areas = false
	door_query.collide_with_bodies = true
	var overlaps: Array = space.intersect_shape(door_query, 16)
	var overlap_names: PackedStringArray = PackedStringArray()
	for item in overlaps:
		var collider: Object = item.get("collider")
		if collider is Node:
			overlap_names.append((collider as Node).name)
	_ok(overlaps.is_empty(), "spawn capsule free of solids (%s)" % ",".join(overlap_names))


func _test_furniture_colliders(loc: WorldLocation) -> void:
	for collider_path in ESSENTIAL_COLLIDER_PATHS:
		var body: Node = loc.get_node_or_null(collider_path)
		_ok(body is StaticBody3D, "collider %s is StaticBody3D" % collider_path)
		if body == null:
			continue
		var shape_node: Node = body.get_node_or_null("Shape")
		_ok(shape_node is CollisionShape3D, "collider %s has Shape" % collider_path)
		if shape_node is CollisionShape3D:
			var cs: CollisionShape3D = shape_node as CollisionShape3D
			_ok(cs.shape is BoxShape3D, "collider %s uses BoxShape3D" % collider_path)


func _test_neighbor_anchor(loc: WorldLocation) -> void:
	var anchor: Node = loc.get_node_or_null("NpcSpawns/npc_girl_neighbor")
	_ok(anchor is StageActorAnchor, "npc_girl_neighbor StageActorAnchor")
	if not (anchor is StageActorAnchor):
		return
	var saa: StageActorAnchor = anchor as StageActorAnchor
	_ok(saa.content_id == &"girl_neighbor", "content_id=girl_neighbor")
	_ok(int(saa.story_stage) == int(GameTypes.GameStage.PROLOGUE), "Neighbor gated to PROLOGUE")
	await _settle()
	var spawned: Node = saa.get_node_or_null("Spawned_girl_neighbor")
	_ok(spawned != null, "Spawned_girl_neighbor present after New Game")
	if spawned is Node3D:
		var n3: Node3D = spawned as Node3D
		_ok(n3.visible, "Neighbor visible")
		# Neighbor must not be a physics blocker for the player capsule.
		var has_static: bool = false
		for child in n3.find_children("*", "StaticBody3D", true, false):
			has_static = true
			break
		_ok(not has_static, "Neighbor has no StaticBody3D blocker")


func _test_city_exit_story_lock(loc: WorldLocation) -> void:
	var exit_node: Node = loc.get_node_or_null(
		"Geometry/ApartmentArt/Objects/ExitDoor/Interaction"
	)
	_ok(exit_node is WorldTransition, "ToCity WorldTransition present")
	if not (exit_node is WorldTransition):
		return
	var door: WorldTransition = exit_node as WorldTransition
	door.refresh_access_prompt()
	var prompt: String = door.get_interaction_prompt(null)
	_ok(prompt.contains("Недоступно"), "city exit still story-locked on New Game (%s)" % prompt)
	_ok(door.target_location_id == &"city_hub", "ToCity target city_hub")


func _test_early_interactables(loc: WorldLocation) -> void:
	for path in [
		"Interactables/Phone",
		"Geometry/ApartmentArt/Objects/Bed/Interaction",
		"Geometry/ApartmentArt/Objects/Wardrobe/Interaction",
		"Geometry/ApartmentArt/Objects/Fridge/Interaction",
		"Geometry/ApartmentArt/Objects/Window/Interaction",
		"Geometry/ApartmentArt/Objects/ExitDoor/Interaction",
	]:
		var node: Node = loc.get_node_or_null(path)
		_ok(node is Area3D, "%s Area3D present" % path)
		if node is Area3D:
			_ok((node as Area3D).collision_layer == 4, "%s interaction layer 4" % path)
