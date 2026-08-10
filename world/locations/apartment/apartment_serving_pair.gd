extends Node3D
class_name ApartmentServingPair
## Visual pair used both in the player's hands and on the dining table.

const FOOD_PLATE_SCENE: String = (
	"res://world/locations/apartment/apartment_food_plate.tscn"
)
const CARRIED_LEFT_POSITION: Vector3 = Vector3(-0.18, 0.0, 0.0)
const CARRIED_RIGHT_POSITION: Vector3 = Vector3(0.18, 0.0, 0.0)
const TABLE_LEFT_PLATE_POSITION: Vector3 = Vector3(-0.301, -0.048, -0.002)
const TABLE_RIGHT_PLATE_POSITION: Vector3 = Vector3(0.299, -0.048, -0.002)
const TABLE_LEFT_DRINK_POSITION: Vector3 = Vector3(-0.18, -0.048, 0.11)
const TABLE_RIGHT_DRINK_POSITION: Vector3 = Vector3(0.18, -0.048, -0.11)

var _category: StringName = &""


func configure(definition: Dictionary, carried: bool) -> bool:
	if definition.is_empty():
		return false
	_category = definition.get("category", &"")
	if not set_carried(carried):
		return false
	var left: Node3D = get_node_or_null("LeftServing") as Node3D
	var right: Node3D = get_node_or_null("RightServing") as Node3D
	if left == null or right == null:
		return false
	_clear_anchor(left)
	_clear_anchor(right)
	return (
		_build_serving(left, definition, _category)
		and _build_serving(right, definition, _category)
	)


func set_carried(carried: bool) -> bool:
	var left: Node3D = get_node_or_null("LeftServing") as Node3D
	var right: Node3D = get_node_or_null("RightServing") as Node3D
	if left == null or right == null or _category == &"":
		return false
	if carried:
		left.position = CARRIED_LEFT_POSITION
		right.position = CARRIED_RIGHT_POSITION
	elif _category == &"drink":
		left.position = TABLE_LEFT_DRINK_POSITION
		right.position = TABLE_RIGHT_DRINK_POSITION
	else:
		left.position = TABLE_LEFT_PLATE_POSITION
		right.position = TABLE_RIGHT_PLATE_POSITION
	rotation_degrees = Vector3.ZERO
	scale = Vector3(0.78, 0.78, 0.78) if carried else Vector3.ONE
	return true


func _build_serving(
	anchor: Node3D,
	definition: Dictionary,
	category: StringName,
) -> bool:
	if category == &"food":
		var plate: Node3D = _instantiate_scene(FOOD_PLATE_SCENE)
		if plate == null:
			return false
		anchor.add_child(plate)
		if not plate.has_method("set_food"):
			return false
		return bool(plate.call("set_food", str(definition.get("scene", ""))))
	var item_scene: String = str(definition.get("scene", ""))
	var item: Node3D = _instantiate_scene(item_scene)
	if item == null:
		return false
	anchor.add_child(item)
	return true


func _instantiate_scene(scene_path: String) -> Node3D:
	if scene_path.is_empty():
		return null
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("[ApartmentServingPair] scene missing: %s" % scene_path)
		return null
	var instance: Node = packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		push_error("[ApartmentServingPair] scene root is not Node3D: %s" % scene_path)
		return null
	return instance as Node3D


func _clear_anchor(anchor: Node3D) -> void:
	for child: Node in anchor.get_children():
		child.queue_free()
