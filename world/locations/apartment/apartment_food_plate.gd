extends Node3D
class_name ApartmentFoodPlate
## A reusable physical plate with a slot for the selected food visual.


func set_food(scene_path: String) -> bool:
	var food_anchor: Node3D = get_node_or_null("FoodAnchor") as Node3D
	if food_anchor == null or scene_path.is_empty():
		return false
	for child: Node in food_anchor.get_children():
		child.queue_free()
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("[ApartmentFoodPlate] food scene missing: %s" % scene_path)
		return false
	var instance: Node = packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		push_error("[ApartmentFoodPlate] food root is not Node3D: %s" % scene_path)
		return false
	food_anchor.add_child(instance)
	return true
